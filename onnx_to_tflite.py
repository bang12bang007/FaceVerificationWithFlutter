import onnx
from onnx_tf.backend import prepare
import tensorflow as tf
import os

def convert_onnx_to_tflite(model_name, onnx_path, output_dir):
    print(f"\n{'='*20} Converting {model_name} ONNX to TFLite {'='*20}")
    
    # 1. Convert ONNX to TensorFlow (SavedModel)
    tf_path = os.path.join(output_dir, f"{model_name}_tf")
    try:
        print("  Loading ONNX model...")
        onnx_model = onnx.load(onnx_path)
        print("  Preparing TF representation (this may take a while)...")
        tf_rep = prepare(onnx_model)
        print("  Exporting to TF SavedModel...")
        tf_rep.export_graph(tf_path)
        print(f"  [OK] Exported TF SavedModel to {tf_path}")
    except Exception as e:
        print(f"  [ERROR] Failed to convert to TF: {e}")
        return

    # 2. Convert TensorFlow to TFLite
    tflite_path = os.path.join(output_dir, f"{model_name}.tflite")
    try:
        print("  Converting SavedModel to TFLite...")
        converter = tf.lite.TFLiteConverter.from_saved_model(tf_path)
        tflite_model = converter.convert()

        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        
        print(f"  [SUCCESS] Saved TFLite model to {tflite_path}")
    except Exception as e:
        print(f"  [ERROR] Failed to convert to TFLite: {e}")

if __name__ == "__main__":
    MODELS_DIR = '/Users/quanvo/Documents/train/models'
    
    # List of (model_name, onnx_filename)
    conversions = [
        ('mobilefacenet', 'mobilefacenet.onnx'),
        ('mobilenet_v2', 'mobilenet_v2.onnx'),
        # Add iresnet50 if it exists later
    ]
    
    for name, filename in conversions:
        onnx_full_path = os.path.join(MODELS_DIR, filename)
        if os.path.exists(onnx_full_path):
            convert_onnx_to_tflite(name, onnx_full_path, MODELS_DIR)
        else:
            print(f"ONNX file not found: {onnx_full_path}")
