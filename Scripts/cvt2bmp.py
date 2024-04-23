import cv2

# 读取图像
image = cv2.imread("test.png")

# 缩放图像
resized_image = cv2.resize(image, (960, 540))

# 保存缩放后的图像为BMP格式
cv2.imwrite("test.bmp", resized_image)
