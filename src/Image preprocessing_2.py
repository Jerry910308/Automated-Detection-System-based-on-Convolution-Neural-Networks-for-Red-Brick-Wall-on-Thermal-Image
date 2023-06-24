from PIL import Image
import pylab as pl

def black_area(x1,y1,x2,y2,image_name):
    black_area_image=image_name
    for x in range(x1,x2+1):
        for y in range(y1,y2+1):
            black_area_image.putpixel((x,y),(0,0,0))
 
    return black_area_image

image=Image.open(path)
image=image.resize((940,705))
Aim = black_area(0,0,310,79,image)
Bim = black_area(827,0,939,65,Aim)
Cim = black_area(0,648,143,704,Bim)
Dim = black_area(824,636,939,704,Cim)
Eim = black_area(915,65,939,637,Dim)
Eim.save(path)
