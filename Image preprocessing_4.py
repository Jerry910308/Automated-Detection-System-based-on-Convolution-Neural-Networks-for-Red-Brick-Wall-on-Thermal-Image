import cv2
import numpy as np

image = cv2.imread(path)
height, width = image.shape[:2]
rotation_angle = np.random.uniform(-10, 10)
center = (width // 2, height // 2)
rotation_matrix = cv2.getRotationMatrix2D(center, rotation_angle, 1.0)
rotated_image = cv2.warpAffine(image, rotation_matrix, (width, height))
cv2.imwrite(path,  rotated_image .astype(np.uint8))
