#!/usr/bin/env python3
"""
Edge AI Inference Pipeline
Preprocesses input image frames and runs classification inference using a trained 
Keras/TensorFlow model optimized for edge device deployment environments.
"""

import sys
import os
import numpy as np
from keras.models import load_model
from PIL import Image, ImageOps

def main():
    # Ensure an image path argument was passed
    if len(sys.argv) < 2:
        print("Error: Missing input image path.")
        print("Usage: python3 inference.py <path_to_image>")
        sys.argv[0]
        sys.exit(1)

    img_path = sys.argv[1]

    if not os.path.exists(img_path):
        print(f"Error: Image file '{img_path}' does not exist.")
        sys.exit(1)

    # 1. Load the trained inference model
    # Good practice to check if model asset exists
    model_path = 'keras_model.h5'
    if not os.path.exists(model_path):
        print(f"Error: Model file '{model_path}' not found in runtime directory.")
        sys.exit(1)
        
    model = load_model(model_path)

    # 2. Allocate memory array mapping the expected Tensor input shape
    # Batch size = 1, Dimensions = 224x224, Channels = 3 (RGB)
    input_shape = (1, 224, 224, 3)
    data = np.ndarray(shape=input_shape, dtype=np.float32)

    # 3. Image Preprocessing Pipeline
    image = Image.open(img_path)
    target_size = (224, 224)
    
    # Modernized Pillow Resampling: Image.ANTIALIAS was removed in Pillow 10.0.0.
    # Replaced with Image.Resampling.LANCZOS for modern compatibility.
    resample_method = getattr(Image, 'ANTIALIAS', getattr(Image, 'LANCZOS', 1))
    image = ImageOps.fit(image, target_size, resample=resample_method)

    # Convert the processed image into a structured numpy array
    image_array = np.asarray(image)
    
    # 4. Standard Model Input Normalization (Map pixel values from [0, 255] to [-1, 1])
    normalized_image_array = (image_array.astype(np.float32) / 127.0) - 1
    data[0] = normalized_image_array

    # 5. Execute Core Inference Pipeline
    prediction = model.predict(data, verbose=0) # verbose=0 keeps the CLI clean
    predicted_index = np.argmax(prediction)

    # 6. Interpret Classification Outputs
    # Abstracted labels array mapping out generalized enterprise tracking locations
    labels = [
        "Primary_Zone_Alpha", 
        "Primary_Zone_Beta", 
        "Management_Office", 
        "Secured_Vault_Antechamber", 
        "Secured_Vault_Internal", 
        "External_Perimeter_Entrance", 
        "Secondary_Context_Camera"
    ]
    
    # Output metrics to terminal console
    print(f"Raw Softmax Probability Array: {prediction}")
    print(f"Predicted Class Index: {predicted_index}")
    print(f"Classified Environment Label: {labels[predicted_index]}")

if __name__ == '__main__':
    main()
