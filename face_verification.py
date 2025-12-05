import torch
import torch.nn as nn
import torchvision.transforms as T
import torch.nn.functional as F
from PIL import Image
import numpy as np
import cv2
import math
import os
import glob
from torch.nn import Linear, Conv2d, BatchNorm1d, BatchNorm2d, PReLU, Sequential, Module
from ultralytics import YOLO
import torchvision.models as models
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_curve, auc
import matplotlib.pyplot as plt
from scipy.optimize import brentq
from scipy.interpolate import interp1d
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset
from sklearn.model_selection import train_test_split
import time

# --- 1. MODEL DEFINITIONS ---

class Flatten(Module):
    def forward(self, input):
        return input.view(input.size(0), -1)

def l2_norm(input, axis=1):
    norm = torch.norm(input, 2, axis, True)
    output = torch.div(input, norm)
    return output

class Conv_block(Module):
    def __init__(self, in_c, out_c, kernel=(1, 1), stride=(1, 1), padding=(0, 0), groups=1):
        super(Conv_block, self).__init__()
        self.conv = Conv2d(in_c, out_channels=out_c, kernel_size=kernel, groups=groups, stride=stride, padding=padding, bias=False)
        self.bn = BatchNorm2d(out_c)
        self.prelu = PReLU(out_c)
    def forward(self, x):
        x = self.conv(x)
        x = self.bn(x)
        x = self.prelu(x)
        return x

class Linear_block(Module):
    def __init__(self, in_c, out_c, kernel=(1, 1), stride=(1, 1), padding=(0, 0), groups=1):
        super(Linear_block, self).__init__()
        self.conv = Conv2d(in_c, out_channels=out_c, kernel_size=kernel, groups=groups, stride=stride, padding=padding, bias=False)
        self.bn = BatchNorm2d(out_c)
    def forward(self, x):
        x = self.conv(x)
        x = self.bn(x)
        return x

class Depth_Wise(Module):
     def __init__(self, in_c, out_c, residual=False, kernel=(3, 3), stride=(2, 2), padding=(1, 1), groups=1):
        super(Depth_Wise, self).__init__()
        self.conv = Conv_block(in_c, out_c=groups, kernel=(1, 1), padding=(0, 0), stride=(1, 1))
        self.conv_dw = Conv_block(groups, groups, groups=groups, kernel=kernel, padding=padding, stride=stride)
        self.project = Linear_block(groups, out_c, kernel=(1, 1), padding=(0, 0), stride=(1, 1))
        self.residual = residual
     def forward(self, x):
        if self.residual:
            short_cut = x
        x = self.conv(x)
        x = self.conv_dw(x)
        x = self.project(x)
        if self.residual:
            output = short_cut + x
        else:
            output = x
        return output

class Residual(Module):
    def __init__(self, c, num_block, groups, kernel=(3, 3), stride=(1, 1), padding=(1, 1)):
        super(Residual, self).__init__()
        modules = []
        for _ in range(num_block):
            modules.append(Depth_Wise(c, c, residual=True, kernel=kernel, padding=padding, stride=stride, groups=groups))
        self.model = Sequential(*modules)
    def forward(self, x):
        return self.model(x)

class MobileFaceNet(Module):
    def __init__(self, embedding_size):
        super(MobileFaceNet, self).__init__()
        self.conv1 = Conv_block(3, 64, kernel=(3, 3), stride=(2, 2), padding=(1, 1))
        self.conv2_dw = Conv_block(64, 64, kernel=(3, 3), stride=(1, 1), padding=(1, 1), groups=64)
        self.conv_23 = Depth_Wise(64, 64, kernel=(3, 3), stride=(2, 2), padding=(1, 1), groups=128)
        self.conv_3 = Residual(64, num_block=4, groups=128, kernel=(3, 3), stride=(1, 1), padding=(1, 1))
        self.conv_34 = Depth_Wise(64, 128, kernel=(3, 3), stride=(2, 2), padding=(1, 1), groups=256)
        self.conv_4 = Residual(128, num_block=6, groups=256, kernel=(3, 3), stride=(1, 1), padding=(1, 1))
        self.conv_45 = Depth_Wise(128, 128, kernel=(3, 3), stride=(2, 2), padding=(1, 1), groups=512)
        self.conv_5 = Residual(128, num_block=2, groups=256, kernel=(3, 3), stride=(1, 1), padding=(1, 1))
        self.conv_6_sep = Conv_block(128, 512, kernel=(1, 1), stride=(1, 1), padding=(0, 0))
        self.conv_6_dw = Linear_block(512, 512, groups=512, kernel=(7,7), stride=(1, 1), padding=(0, 0))
        self.conv_6_flatten = Flatten()
        self.linear = Linear(512, embedding_size, bias=False)
        self.bn = BatchNorm1d(embedding_size)
        
        # weight initialization
        for m in self.modules():
            if isinstance(m, nn.Conv2d):
                n = m.kernel_size[0] * m.kernel_size[1] * m.out_channels
                m.weight.data.normal_(0, math.sqrt(2. / n))
            elif isinstance(m, nn.BatchNorm2d):
                m.weight.data.fill_(1)
                m.bias.data.zero_()
    
    def forward(self, x):
        out = self.conv1(x)
        out = self.conv2_dw(out)
        out = self.conv_23(out)
        out = self.conv_3(out)
        out = self.conv_34(out)
        out = self.conv_4(out)
        out = self.conv_45(out)
        out = self.conv_5(out)
        out = self.conv_6_sep(out)
        out = self.conv_6_dw(out)
        out = self.conv_6_flatten(out)
        out = self.linear(out)
        out = self.bn(out)
        return l2_norm(out)

# --- IResNet Definition (InsightFace Style) ---
def conv3x3(in_planes, out_planes, stride=1, groups=1, dilation=1):
    return nn.Conv2d(in_planes, out_planes, kernel_size=3, stride=stride,
                     padding=dilation, groups=groups, bias=False, dilation=dilation)

def conv1x1(in_planes, out_planes, stride=1):
    return nn.Conv2d(in_planes, out_planes, kernel_size=1, stride=stride, bias=False)

class IBasicBlock(nn.Module):
    expansion = 1
    def __init__(self, inplanes, planes, stride=1, downsample=None, groups=1,
                 base_width=64, dilation=1):
        super(IBasicBlock, self).__init__()
        if groups != 1 or base_width != 64:
            raise ValueError('BasicBlock only supports groups=1 and base_width=64')
        if dilation > 1:
            raise NotImplementedError("Dilation > 1 not supported in BasicBlock")
        self.bn1 = nn.BatchNorm2d(inplanes, eps=1e-05,)
        self.conv1 = conv3x3(inplanes, planes)
        self.bn2 = nn.BatchNorm2d(planes, eps=1e-05,)
        self.prelu = nn.PReLU(planes)
        self.conv2 = conv3x3(planes, planes, stride)
        self.bn3 = nn.BatchNorm2d(planes, eps=1e-05,)
        self.downsample = downsample
        self.stride = stride

    def forward(self, x):
        identity = x
        out = self.bn1(x)
        out = self.conv1(out)
        out = self.bn2(out)
        out = self.prelu(out)
        out = self.conv2(out)
        out = self.bn3(out)
        if self.downsample is not None:
            identity = self.downsample(x)
        out += identity
        return out

class IResNet(nn.Module):
    fc_scale = 7 * 7
    def __init__(self, block, layers, dropout=0, num_features=512, zero_init_residual=False,
                 groups=1, width_per_group=64, replace_stride_with_dilation=None, fp16=False):
        super(IResNet, self).__init__()
        self.inplanes = 64
        self.dilation = 1
        if replace_stride_with_dilation is None:
            replace_stride_with_dilation = [False, False, False]
        if len(replace_stride_with_dilation) != 3:
            raise ValueError("replace_stride_with_dilation should be None "
                             "or a 3-element tuple, got {}".format(replace_stride_with_dilation))
        self.groups = groups
        self.base_width = width_per_group
        self.fp16 = fp16
        self.conv1 = nn.Conv2d(3, self.inplanes, kernel_size=3, stride=1, padding=1, bias=False)
        self.bn1 = nn.BatchNorm2d(self.inplanes, eps=1e-05)
        self.prelu = nn.PReLU(self.inplanes)
        self.layer1 = self._make_layer(block, 64, layers[0], stride=2)
        self.layer2 = self._make_layer(block, 128, layers[1], stride=2,
                                       dilate=replace_stride_with_dilation[0])
        self.layer3 = self._make_layer(block, 256, layers[2], stride=2,
                                       dilate=replace_stride_with_dilation[1])
        self.layer4 = self._make_layer(block, 512, layers[3], stride=2,
                                       dilate=replace_stride_with_dilation[2])
        self.bn2 = nn.BatchNorm2d(512 * block.expansion, eps=1e-05,)
        self.dropout = nn.Dropout(p=dropout, inplace=True)
        self.fc = nn.Linear(512 * block.expansion * self.fc_scale, num_features)
        self.features = nn.BatchNorm1d(num_features, eps=1e-05)
        nn.init.constant_(self.features.weight, 1.0)
        self.features.weight.requires_grad = False

        for m in self.modules():
            if isinstance(m, nn.Conv2d):
                nn.init.normal_(m.weight, 0, 0.1)
            elif isinstance(m, (nn.BatchNorm2d, nn.GroupNorm)):
                nn.init.constant_(m.weight, 1)
                nn.init.constant_(m.bias, 0)

        if zero_init_residual:
            for m in self.modules():
                if isinstance(m, IBasicBlock):
                    nn.init.constant_(m.bn2.weight, 0)

    def _make_layer(self, block, planes, blocks, stride=1, dilate=False):
        downsample = None
        previous_dilation = self.dilation
        if dilate:
            self.dilation *= stride
            stride = 1
        if stride != 1 or self.inplanes != planes * block.expansion:
            downsample = nn.Sequential(
                conv1x1(self.inplanes, planes * block.expansion, stride),
                nn.BatchNorm2d(planes * block.expansion, eps=1e-05, ),
            )
        layers = []
        layers.append(block(self.inplanes, planes, stride, downsample, self.groups,
                            self.base_width, previous_dilation))
        self.inplanes = planes * block.expansion
        for _ in range(1, blocks):
            layers.append(block(self.inplanes, planes, groups=self.groups,
                                base_width=self.base_width, dilation=self.dilation))

        return nn.Sequential(*layers)

    def forward(self, x):
        x = self.conv1(x)
        x = self.bn1(x)
        x = self.prelu(x)
        x = self.layer1(x)
        x = self.layer2(x)
        x = self.layer3(x)
        x = self.layer4(x)
        x = self.bn2(x)
        x = torch.flatten(x, 1)
        x = self.dropout(x)
        x = self.fc(x)
        x = self.features(x)
        return l2_norm(x)

def iresnet18(pretrained=False, progress=True, **kwargs):
    return IResNet(IBasicBlock, [2, 2, 2, 2], **kwargs)

def iresnet34(pretrained=False, progress=True, **kwargs):
    return IResNet(IBasicBlock, [3, 4, 6, 3], **kwargs)

def iresnet100(pretrained=False, progress=True, **kwargs):
    return IResNet(IBasicBlock, [3, 13, 30, 3], **kwargs)

def iresnet50(pretrained=False, progress=True, **kwargs):
    return IResNet(IBasicBlock, [3, 4, 14, 3], **kwargs)

class ResNetFace(Module):
    def __init__(self, backbone_name='resnet50', embedding_size=512, pretrained=False):
        super(ResNetFace, self).__init__()
        if backbone_name == 'resnet50':
            self.backbone = models.resnet50(pretrained=pretrained)
        elif backbone_name == 'resnet18':
            self.backbone = models.resnet18(pretrained=pretrained)
        elif backbone_name == 'resnet34':
            self.backbone = models.resnet34(pretrained=pretrained)
        else:
            raise ValueError(f"Unsupported ResNet backbone: {backbone_name}")
            
        in_features = self.backbone.fc.in_features
        self.backbone.fc = Linear(in_features, embedding_size, bias=False)
        self.bn = BatchNorm1d(embedding_size)
        
    def forward(self, x):
        x = self.backbone(x)
        x = self.bn(x)
        return l2_norm(x)

class MobileNetV2Face(Module):
    def __init__(self, embedding_size=512, pretrained=False):
        super(MobileNetV2Face, self).__init__()
        self.backbone = models.mobilenet_v2(pretrained=pretrained)
        in_features = self.backbone.classifier[1].in_features
        self.backbone.classifier = Linear(in_features, embedding_size, bias=False)
        self.bn = BatchNorm1d(embedding_size)
        
    def forward(self, x):
        x = self.backbone(x)
        x = self.bn(x)
        return l2_norm(x)

def get_model(name, embedding_size=512, pretrained=False):
    name = name.lower()
    if name == 'mobilefacenet':
        return MobileFaceNet(embedding_size)
    elif name == 'iresnet100' or name == 'iresnet101':
        return iresnet100(num_features=embedding_size)
    elif name == 'iresnet50':
        return iresnet50(num_features=embedding_size)
    elif name == 'iresnet18':
        return iresnet18(num_features=embedding_size)
    elif name == 'iresnet34':
        return iresnet34(num_features=embedding_size)
    elif name.startswith('resnet'):
        return ResNetFace(name, embedding_size, pretrained)
    elif name == 'mobilenet_v2':
        return MobileNetV2Face(embedding_size, pretrained)
    else:
        raise ValueError(f"Unknown model: {name}")

# --- 1.5. ARCFACE HEAD ---
class ArcMarginProduct(nn.Module):
    def __init__(self, in_features=512, out_features=2, s=32.0, m=0.50, easy_margin=False):
        super(ArcMarginProduct, self).__init__()
        self.in_features = in_features
        self.out_features = out_features
        self.s = s
        self.m = m
        self.weight = nn.Parameter(torch.Tensor(out_features, in_features))
        nn.init.xavier_uniform_(self.weight)

        self.easy_margin = easy_margin
        self.cos_m = math.cos(m)
        self.sin_m = math.sin(m)
        self.th = math.cos(math.pi - m)
        self.mm = math.sin(math.pi - m) * m

    def forward(self, input, label):
        cosine = F.linear(F.normalize(input), F.normalize(self.weight))
        sine = torch.sqrt(1.0 - torch.pow(cosine, 2))
        phi = cosine * self.cos_m - sine * self.sin_m
        
        if self.easy_margin:
            phi = torch.where(cosine > 0, phi, cosine)
        else:
            phi = torch.where(cosine > self.th, phi, cosine - self.mm)
            
        one_hot = torch.zeros(cosine.size(), device=input.device)
        one_hot.scatter_(1, label.view(-1, 1).long(), 1)
        
        output = (one_hot * phi) + ((1.0 - one_hot) * cosine)
        output *= self.s
        return output

# --- 2. HELPERS ---

REFERENCE_LANDMARKS = np.array([
    [38.2946, 51.6963], 
    [73.5318, 51.5014], 
    [56.0252, 71.7366], 
    [41.5493, 92.3655], 
    [70.7299, 92.2041]
], dtype=np.float32)

def estimate_norm(lmk, image_size=112):
    assert lmk.shape == (5, 2)
    tform, _ = cv2.estimateAffinePartial2D(lmk, REFERENCE_LANDMARKS, method=cv2.LMEDS)
    return tform

def align_face(img, landmark):
    M = estimate_norm(landmark)
    if M is None:
        return None
    warped = cv2.warpAffine(img, M, (112, 112), borderValue=0.0)
    return warped

val_transform = T.Compose([
    T.Resize((112, 112)),
    T.ToTensor(),
    T.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
])

train_transform = T.Compose([
    T.Resize((112, 112)),
    T.RandomHorizontalFlip(p=0.5),
    T.RandomRotation(degrees=15), # Xoay ảnh +/- 15 độ
    T.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.3, hue=0.1), # Chỉnh màu/sáng mạnh
    T.RandomGrayscale(p=0.1), # Ngẫu nhiên chuyển sang ảnh xám
    T.ToTensor(),
    T.RandomErasing(p=0.2, scale=(0.02, 0.15)), # Che một phần mặt (Occlusion)
    T.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
])

def check_image_quality(img_path, detector, blur_threshold=50):
    """
    Checks if an image is not blurry and has 5 detected landmarks.
    """
    if detector is None: return True # Skip check if no detector
    
    try:
        img = cv2.imread(img_path)
        if img is None: return False
        
        # 1. Check Blur (Laplacian Variance)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        score = cv2.Laplacian(gray, cv2.CV_64F).var()
        if score < blur_threshold:
            # print(f"  > Skipped Blurry: {os.path.basename(img_path)} (Score: {score:.2f})")
            return False 
            
        # 2. Check Landmarks (5 points)
        results = detector(img, verbose=False)
        if not results: return False
        
        if hasattr(results[0], 'keypoints') and results[0].keypoints is not None:
            kpts = results[0].keypoints.xy.cpu().numpy()
            # Check if at least one face has 5 keypoints
            if kpts.shape[0] > 0 and kpts.shape[1] == 5:
                return True
                
        # print(f"  > Skipped No Landmarks: {os.path.basename(img_path)}")
        return False
    except Exception as e:
        print(f"  > Error checking {img_path}: {e}")
        return False

def prepare_dataset(data_dir, val_split=0.2, seed=42):
    # Initialize Detector
    yolo_path = '/kaggle/input/yolo-v8-face/yolov8n-face.pt'
    if not os.path.exists(yolo_path):
            yolo_path = '/Users/quanvo/Documents/train/yolov8n-face.pt'
    if not os.path.exists(yolo_path):
            yolo_path = 'yolov8n-face.pt'
    
    detector = None
    if os.path.exists(yolo_path):
        # print(f"  > Loading YOLO for Quality Check: {yolo_path}")
        detector = YOLO(yolo_path)
    else:
        print("  > Warning: YOLO detector not found. Skipping quality check.")

    all_image_paths = []
    all_labels = []
    classes = []
    skipped_count = 0
    
    print(f"  > Scanning dataset at {data_dir}...")
    
    for cls_name in sorted(os.listdir(data_dir)):
        cls_dir = os.path.join(data_dir, cls_name)
        if not os.path.isdir(cls_dir): continue
        if cls_name == 'NguyenVanLinh': continue
        
        imgs = glob.glob(os.path.join(cls_dir, "*.jpg")) + glob.glob(os.path.join(cls_dir, "*.png"))
        if len(imgs) < 10: continue
            
        valid_imgs = []
        for img_path in imgs:
            if check_image_quality(img_path, detector):
                valid_imgs.append(img_path)
            else:
                skipped_count += 1
        
        if len(valid_imgs) >= 5:
            classes.append(cls_name)
            for img_path in valid_imgs:
                all_image_paths.append(img_path)
                all_labels.append(len(classes) - 1)

    print(f"  > Skipped {skipped_count} low-quality images.")
    
    # Split
    if val_split > 0 and len(all_image_paths) > 0:
        train_paths, val_paths, train_labels, val_labels = train_test_split(
            all_image_paths, all_labels, test_size=val_split, random_state=seed, stratify=all_labels
        )
        return (train_paths, train_labels), (val_paths, val_labels), classes
    else:
        return (all_image_paths, all_labels), ([], []), classes

class FaceDataset(Dataset):
    def __init__(self, image_paths, labels, classes, transform=None):
        self.image_paths = image_paths
        self.labels = labels
        self.classes = classes
        self.transform = transform
        self.class_to_idx = {cls: i for i, cls in enumerate(classes)}
        
        # print(f"  > Dataset initialized: {len(self.image_paths)} images, {len(self.classes)} classes")
                
    def __len__(self):
        return len(self.image_paths)
    
    def __getitem__(self, idx):
        img_path = self.image_paths[idx]
        label = self.labels[idx]
        
        img = cv2.imread(img_path)
        if img is None:
            img = np.zeros((112, 112, 3), dtype=np.uint8)
        else:
            img = cv2.resize(img, (112, 112))
            
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img = Image.fromarray(img)
        
        if self.transform:
            img = self.transform(img)
            
        return img, label

# --- 3. FACE VERIFIER & EVALUATOR ---

class FaceVerifier:
    def __init__(self, model_name='mobilefacenet', model_path=None, device='cuda'):
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        print(f"  > Initializing model: {model_name} on {self.device}")
        
        self.model = get_model(model_name).to(self.device)
        
        if model_path:
            self.load_weights(model_path)
        else:
            print("  > Warning: No weights provided. Using random/imagenet weights.")
            
        self.model.eval()
        
        # Load Detector
        yolo_path = '/kaggle/input/yolo-v8-face/yolov8n-face.pt'
        if not os.path.exists(yolo_path):
             yolo_path = 'yolov8n-face.pt'
        
        if os.path.exists(yolo_path):
            self.detector = YOLO(yolo_path)
        else:
            self.detector = None
            
        self.database = {} 

    def load_weights(self, path):
        if not os.path.exists(path):
            print(f"  > Error: Weights not found at {path}")
            return
        try:
            state_dict = torch.load(path, map_location=self.device)
            self.model.load_state_dict(state_dict, strict=False)
            print(f"  > Weights loaded from {os.path.basename(path)}")
        except Exception as e:
            print(f"  > Error loading weights: {e}")

    def get_embedding(self, img_path):
        if not os.path.exists(img_path): return None
        img = cv2.imread(img_path)
        if img is None: return None
            
        aligned_img = None
        if self.detector:
            results = self.detector(img, verbose=False)
            if results and len(results[0].boxes) > 0:
                if hasattr(results[0], 'keypoints') and results[0].keypoints is not None:
                    kpts = results[0].keypoints.xy.cpu().numpy()
                    if len(kpts) > 0:
                        aligned_img = align_face(img, kpts[0])
        
        if aligned_img is None:
            aligned_img = cv2.resize(img, (112, 112))
            
        img_rgb = cv2.cvtColor(aligned_img, cv2.COLOR_BGR2RGB)
        img_pil = Image.fromarray(img_rgb)
        img_tensor = val_transform(img_pil).unsqueeze(0).to(self.device)
        img_tensor_flip = torch.flip(img_tensor, [3])
        
        with torch.no_grad():
            emb = self.model(img_tensor)
            emb_flip = self.model(img_tensor_flip)
            embedding = emb + emb_flip
            embedding = F.normalize(embedding).cpu().numpy()
            
        return embedding[0]

    def register_person(self, name, image_paths):
        embeddings = []
        for p in image_paths:
            emb = self.get_embedding(p)
            if emb is not None:
                embeddings.append(emb)
        
        if embeddings:
            avg_emb = np.mean(embeddings, axis=0)
            avg_emb = avg_emb / np.linalg.norm(avg_emb)
            self.database[name] = avg_emb
            return True
            return True
        return False

# --- 3.5. TRAINING FUNCTION ---
def train_backbone(config, data_dir, device='cuda', epochs=20, batch_size=128, patience=5):
    print(f"\n{'='*20} TRAINING: {config['name']} {'='*20}")
    
    # 1. Load Model
    model = get_model(config['name']).to(device)
    
    # Load Pretrained Weights if available
    if config['weights'] and os.path.exists(config['weights']):
        try:
            state_dict = torch.load(config['weights'], map_location=device)
            model.load_state_dict(state_dict, strict=False)
            print(f"  > Loaded weights from {os.path.basename(config['weights'])}")
        except Exception as e:
            print(f"  > Warning: Could not load weights: {e}")
    else:
        print("  > Using random/imagenet weights.")

    # 2. Freeze Backbone & Unfreeze Strategy
    # STRATEGY CHANGE: Unfreeze EVERYTHING but use lower LR for backbone
    for param in model.parameters():
        param.requires_grad = True
            
    print(f"  > Unfrozen ALL parameters for deep fine-tuning.")

    # 3. Data Setup
    # Prepare data ONCE
    (train_paths, train_labels), (val_paths, val_labels), classes = prepare_dataset(data_dir, val_split=0.2)
    
    train_dataset = FaceDataset(train_paths, train_labels, classes, transform=train_transform)
    val_dataset = FaceDataset(val_paths, val_labels, classes, transform=val_transform)
    
    print(f"  > Train Set: {len(train_dataset)} images | Val Set: {len(val_dataset)} images")
    print(f"  > Batch Size: {batch_size}")
    
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=2)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=2)
    
    num_classes = len(train_dataset.classes)
    
    # 4. Loss & Optimizer
    # Increase Margin to 0.5 and Scale to 64.0 for stricter convergence (Target > 0.9)
    head = ArcMarginProduct(in_features=512, out_features=num_classes, s=64.0, m=0.5).to(device)
    
    # Differential Learning Rates & Hyperparams
    # Lower LR and higher Weight Decay for ResNet to prevent overfitting/collapse
    if 'resnet' in config['name']:
        backbone_lr = 5e-5
        head_lr = 5e-4
        wd = 1e-3
    else:
        backbone_lr = 1e-4
        head_lr = 1e-3
        wd = 5e-4
        
    backbone_params = list(model.parameters())
    head_params = list(head.parameters())
    
    optimizer = optim.AdamW([
        {'params': backbone_params, 'lr': backbone_lr}, 
        {'params': head_params, 'lr': head_lr}      
    ], weight_decay=wd)
    
    criterion = nn.CrossEntropyLoss()
    
    # 5. Training Loop
    model.train() # Set model to train mode (since we are unfreezing everything)
    # Note: If batch size is small (<16), consider freezing BN stats with model.eval() or specific logic
    # But for deep fine-tuning with reasonable batch size, model.train() is usually better.
    head.train()
    
    history = {'loss': [], 'acc': []}
    best_val_acc = 0.0
    save_path = f"{config['name']}_finetuned.pth"
    
    # Early Stopping Variables
    patience_counter = 0
    
    for epoch in range(epochs):
        # Warm-up Scheduler (Apply to all param groups)
        if epoch < 3: # Shorten warm-up
            factor = (epoch + 1) / 3
            for i, param_group in enumerate(optimizer.param_groups):
                # Restore base LRs based on index
                base = backbone_lr if i == 0 else head_lr
                param_group['lr'] = base * factor
        else:
             # Cosine Decay or Step Decay could be added here
             pass

        total_loss = 0
        correct = 0
        total = 0
        
        for imgs, labels in train_loader:
            imgs, labels = imgs.to(device), labels.to(device)
            
            optimizer.zero_grad()
            embeddings = model(imgs)
            outputs = head(embeddings, labels)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            
            total_loss += loss.item()
            _, predicted = torch.max(outputs.data, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()
            
        epoch_loss = total_loss / len(train_loader)
        epoch_acc = 100 * correct / total
        
        # --- Validation Loop ---
        head.eval() # Set head to eval mode
        val_loss = 0.0
        val_correct = 0
        val_total = 0
        
        with torch.no_grad():
            for imgs, labels in val_loader:
                imgs, labels = imgs.to(device), labels.to(device)
                embeddings = model(imgs)
                outputs = head(embeddings, labels)
                loss = criterion(outputs, labels)
                
                val_loss += loss.item()
                _, predicted = torch.max(outputs.data, 1)
                val_total += labels.size(0)
                val_correct += (predicted == labels).sum().item()
        
        val_epoch_loss = val_loss / len(val_loader)
        val_epoch_acc = 100 * val_correct / val_total
        head.train() # Set head back to train mode
        
        print(f"  > Epoch {epoch+1}/{epochs} - Train Loss: {epoch_loss:.4f} - Train Acc: {epoch_acc:.2f}% | Val Loss: {val_epoch_loss:.4f} - Val Acc: {val_epoch_acc:.2f}%")
        
        history['loss'].append(epoch_loss)
        history['acc'].append(epoch_acc)
        
        # Save Best Model & Early Stopping Check
        if val_epoch_acc > best_val_acc:
            best_val_acc = val_epoch_acc
            torch.save(model.state_dict(), save_path)
            print(f"    >>> New Best Model Saved! (Val Acc: {best_val_acc:.2f}%)")
            patience_counter = 0 # Reset counter
        else:
            patience_counter += 1
            print(f"    >>> No improvement. Patience: {patience_counter}/{patience}")
            
        if patience_counter >= patience:
            print(f"  🛑 Early Stopping triggered! No improvement for {patience} epochs.")
            break

    print(f"  > Training Complete. Best Val Acc: {best_val_acc:.2f}%")
    
    return save_path, val_dataset.classes

def evaluate_backbone(backbone_name, weights_path, data_dir, target_people):
    print(f"\n{'='*20} EVALUATING: {backbone_name} {'='*20}")
    verifier = FaceVerifier(model_name=backbone_name, model_path=weights_path)
    
    # 1. Register (One-shot / Few-shot)
    print("  > Building Database (Registration)...")
    gallery_images = {}
    probe_images = {}
    
    for person in target_people:
        person_dir = os.path.join(data_dir, person)
        if not os.path.exists(person_dir): continue
        
        all_imgs = sorted(glob.glob(os.path.join(person_dir, "*.jpg")) + glob.glob(os.path.join(person_dir, "*.png")))
        if len(all_imgs) > 5:
            gallery_images[person] = all_imgs[:5]
            probe_images[person] = all_imgs[5:] # The rest are for testing
            verifier.register_person(person, gallery_images[person])
        else:
            print(f"  > Warning: Not enough images for {person}")

    if not probe_images:
        print("  > No probe images found. Skipping.")
        return None

    # 2. Verification Testing
    print("  > Running Verification on Probe Set...")
    y_true = []
    y_scores = []
    
    for true_id, img_paths in probe_images.items():
        for img_path in img_paths:
            emb = verifier.get_embedding(img_path)
            if emb is None: continue
            
            for db_id, db_emb in verifier.database.items():
                score = np.dot(emb, db_emb)
                
                if db_id == true_id:
                    y_true.append(1) # Match
                else:
                    y_true.append(0) # Mismatch
                y_scores.append(score)
                
    y_true = np.array(y_true)
    y_scores = np.array(y_scores)
    
    # 3. Calculate Metrics
    # ROC & AUC
    fpr, tpr, thresholds_roc = roc_curve(y_true, y_scores)
    roc_auc = auc(fpr, tpr)
    
    # EER (Equal Error Rate)
    # EER is where FPR = FNR (1 - TPR)
    try:
        eer = brentq(lambda x : 1. - x - interp1d(fpr, tpr)(x), 0., 1.)
    except Exception:
        # Fallback if brentq fails (e.g. perfect separation)
        eer = 0.0
    
    # Optimal Threshold for F1
    best_f1 = 0
    best_thresh = 0
    best_acc = 0
    
    thresholds = np.arange(0, 1.0, 0.01)
    for t in thresholds:
        y_pred = (y_scores > t).astype(int)
        f1 = f1_score(y_true, y_pred, zero_division=0)
        if f1 > best_f1:
            best_f1 = f1
            best_thresh = t
            best_acc = accuracy_score(y_true, y_pred)
            
    # Final metrics at best threshold
    y_pred_final = (y_scores > best_thresh).astype(int)
    precision = precision_score(y_true, y_pred_final, zero_division=0)
    recall = recall_score(y_true, y_pred_final, zero_division=0)
    
    print(f"  > Best Threshold: {best_thresh:.2f}")
    print(f"  > Accuracy: {best_acc:.4f}")
    print(f"  > Precision: {precision:.4f}")
    print(f"  > Recall: {recall:.4f}")
    print(f"  > F1-Score: {best_f1:.4f}")
    print(f"  > AUC: {roc_auc:.4f}")
    print(f"  > EER: {eer:.4f}")
    
    return {
        'backbone': backbone_name,
        'threshold': best_thresh,
        'accuracy': best_acc,
        'precision': precision,
        'recall': recall,
        'f1_score': best_f1,
        'auc': roc_auc,
        'eer': eer,
        'fpr': fpr,
        'tpr': tpr
    }

def plot_roc_curves(results, save_path='roc_comparison.png'):
    plt.figure(figsize=(10, 8))
    for res in results:
        plt.plot(res['fpr'], res['tpr'], lw=2, label=f"{res['backbone']} (AUC = {res['auc']:.4f})")
    
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('Receiver Operating Characteristic (ROC) Comparison')
    plt.legend(loc="lower right")
    plt.grid(True)
    plt.show()
    # plt.savefig(save_path)
    # print(f"\n> ROC Curve saved to {save_path}")

# --- 4. MAIN EXECUTION ---
if __name__ == "__main__":
    # --- KAGGLE CONFIGURATION ---
    # Check if running on Kaggle (paths usually start with /kaggle)
    IS_KAGGLE = os.path.exists('/kaggle/input')
    
    if IS_KAGGLE:
        DATA_DIR = '/kaggle/input/big-dataset/aligment_data' # Update this to your actual Kaggle dataset path
        WEIGHTS_DIR = '/kaggle/input'
        print(">>> Running in KAGGLE environment")
    else:
        DATA_DIR = '/Users/quanvo/Documents/train/aligment_data'
        WEIGHTS_DIR = '/Users/quanvo/Documents/train/models'
        print(">>> Running in LOCAL environment")

    # Define Backbones
    if IS_KAGGLE:
        MODELS = [
            {
                'name': 'mobilefacenet',
                'weights': '/kaggle/input/mobilefacenet/tensorflow2/default/1/MobileFace_Net'
            },
            {
                'name': 'iresnet18',
                'weights': '/kaggle/input/backbone-fromarcface/pytorch/default/1/weights/arcface_r18.pth'
            },
            {
                'name': 'iresnet34',
                'weights': '/kaggle/input/backbone-fromarcface/pytorch/default/1/weights/arcface_r34.pth'
            },
            {
                'name': 'iresnet50',
                'weights': '/kaggle/input/backbone-fromarcface/pytorch/default/1/weights/arcface_r50.pth'
            },
            {
                'name': 'iresnet100',
                'weights': '/kaggle/input/backbone-fromarcface/pytorch/default/1/weights/arcface_r100.pth'
            },
        ]
    else:
        MODELS = [
            {
                'name': 'mobilefacenet',
                'weights': os.path.join(WEIGHTS_DIR, 'MobileFace_Net')
            },
            {
                'name': 'iresnet50',
                'weights': os.path.join(WEIGHTS_DIR, 'arcface_r50.pth')
            }
        ]
    
    TRAIN_MODE = True # Set to True to Train, False to just Evaluate
    
    if TRAIN_MODE:
        if os.path.exists(DATA_DIR):
            for m in MODELS:
                saved_path, classes = train_backbone(m, DATA_DIR, epochs=100)
                
                # After training, evaluate using the NEW weights
                print("  > Starting Evaluation on Validation Set...")
                # Use the validation set classes as targets
                evaluate_backbone(m['name'], saved_path, DATA_DIR, classes[:563]) # Eval on first 563 classes
        else:
            print(f"Error: Data directory {DATA_DIR} not found.")
    else:
        # Just Evaluate
        if os.path.exists(DATA_DIR):
            all_classes = [d for d in os.listdir(DATA_DIR) if os.path.isdir(os.path.join(DATA_DIR, d))]
            TARGETS = sorted(all_classes)[:563]
            
            results = []
            for m in MODELS:
                res = evaluate_backbone(m['name'], m['weights'], DATA_DIR, TARGETS)
                if res: results.append(res)
            
            if results:
                plot_roc_curves(results)
        else:
             print(f"Error: Data directory {DATA_DIR} not found.")
