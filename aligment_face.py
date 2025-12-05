import cv2
import numpy as np
from ultralytics import YOLO
import matplotlib.pyplot as plt
import os

# ============================================
# 1) TẢI MODEL YOLOV8-FACE
# ============================================
if os.path.exists("/kaggle/"):
    model_path = "/kaggle/input/yolo-v8-face/yolov8n-face.pt"
else:
    model_path = "/Users/quanvo/Documents/train/yolov8n-face.pt"

print(f"➡️ Loading model: {model_path}")
try:
    model = YOLO(model_path)
except Exception as e:
    print(f"❌ Lỗi load model: {e}")
    exit()

# ============================================
# 2) KIỂM TRA MODEL CÓ HỖ TRỢ 5 KEYPOINTS KHÔNG
# ============================================
try:
    if hasattr(model.model, 'kpt_shape'):
        print(f"🔍 kpt_shape: {model.model.kpt_shape}")
    else:
        print("❌ Model không có kpt_shape → KHÔNG CÓ 5 KEYPOINTS (Chỉ detect box).")
except:
    pass

print(f"🔍 Model task: {model.task}")


# ============================================
# 3) ARC-FACE LANDMARK TEMPLATE
# ============================================
arcface_ref = np.array([
    [38.2946, 51.6963],
    [73.5318, 51.5014],
    [56.0252, 71.7366],
    [41.5493, 92.3655],
    [70.7299, 92.2041]
], dtype=np.float32)

# ============================================
# 4) ALIGN FACE (nếu có keypoints)
# ============================================
def align_face(image, landmarks):
    src = np.array(landmarks, dtype=np.float32)
    M = cv2.estimateAffinePartial2D(src, arcface_ref, method=cv2.LMEDS)[0]
    face = cv2.warpAffine(image, M, (112, 112))
    return face

# ============================================
# 5) PROCESS DATASET
# ============================================
def process_dataset(input_root, output_root, model):
    print(f"🚀 Bắt đầu xử lý dataset từ: {input_root}")
    print(f"📂 Lưu kết quả tại: {output_root}")
    
    count_saved = 0
    count_skipped = 0
    
    # Duyệt qua tất cả các thư mục và file
    for root, dirs, files in os.walk(input_root):
        for file in files:
            if file.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp', '.webp')):
                img_path = os.path.join(root, file)
                
                # Tạo đường dẫn lưu file giữ nguyên cấu trúc thư mục
                relative_path = os.path.relpath(img_path, input_root)
                save_path = os.path.join(output_root, relative_path)
                
                # Tạo thư mục cha nếu chưa có
                os.makedirs(os.path.dirname(save_path), exist_ok=True)
                
                try:
                    image = cv2.imread(img_path)
                    if image is None:
                        # print(f"⚠️ Không đọc được ảnh: {img_path}")
                        continue
                        
                    # Inference (verbose=False để đỡ spam log)
                    results = model(image, verbose=False)[0]
                    
                    saved = False
                    
                    # Kiểm tra keypoints
                    if hasattr(results, 'keypoints') and results.keypoints is not None:
                        kpts = results.keypoints.xy.cpu().numpy()
                        
                        # Chỉ xử lý nếu tìm thấy ít nhất 1 khuôn mặt có đủ 5 keypoints
                        if kpts.shape[0] > 0 and kpts.shape[1] == 5:
                            # Lấy khuôn mặt đầu tiên (thường là khuôn mặt chính/to nhất)
                            face_aligned = align_face(image, kpts[0])
                            
                            # Lưu ảnh đã align
                            cv2.imwrite(save_path, face_aligned)
                            saved = True
                            count_saved += 1
                    
                    if not saved:
                        count_skipped += 1
                        # print(f"⏩ Bỏ qua (không đủ landmarks): {img_path}")
                        
                except Exception as e:
                    print(f"❌ Lỗi khi xử lý {img_path}: {e}")

    print(f"✅ Hoàn tất! Đã lưu: {count_saved} ảnh.")
    print(f"⏩ Đã bỏ qua: {count_skipped} ảnh (không tìm thấy 5 landmarks).")

# ============================================
# MAIN
# ============================================
if __name__ == "__main__":
    # Cấu hình đường dẫn
    if os.path.exists("/kaggle/"):
        # Môi trường Kaggle
        INPUT_DIR = "/kaggle/input/my-dataset-name" # ⚠️ CẦN SỬA: Đường dẫn dataset trên Kaggle
        OUTPUT_DIR = "/kaggle/working/aligned_dataset"
    elif os.path.exists("/content/"):
        # Môi trường Google Colab
        INPUT_DIR = "/content/drive/MyDrive/my_dataset" # ⚠️ CẦN SỬA: Đường dẫn dataset trên Colab
        OUTPUT_DIR = "/content/aligned_dataset"
    else:
        # Môi trường Local (Mac của bạn)
        INPUT_DIR = "/Users/quanvo/Documents/train/archive/Selfies ID Images dataset"
        OUTPUT_DIR = "/Users/quanvo/Documents/train/aligned_dataset"

    print(f"ℹ️ Môi trường phát hiện: {'Kaggle' if os.path.exists('/kaggle/') else 'Colab' if os.path.exists('/content/') else 'Local'}")
    
    if os.path.exists(INPUT_DIR):
        process_dataset(INPUT_DIR, OUTPUT_DIR, model)
    else:
        print(f"❌ Không tìm thấy thư mục input: {INPUT_DIR}")
        print("👉 Vui lòng sửa biến INPUT_DIR trong code để trỏ đúng đến thư mục dataset của bạn.")
