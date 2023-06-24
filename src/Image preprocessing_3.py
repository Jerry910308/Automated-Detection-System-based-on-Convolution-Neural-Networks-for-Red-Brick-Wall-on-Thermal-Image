import numpy as np
import cv2
import os
from PIL import Image
import pylab as pl

image=Image.open(path)
im=Image.resize((940,705))
norm=im.size
ax=0;ay=0
reducex=0;reducey=0
t=0

time_x=4  #決定分割邊次數 2=1/4 3=1/9...
time_y=3  #決定分割邊次數 2=1/4 3=1/9...

sx=round(norm[0]/time_x)
sy=round(norm[1]/time_y)


c=Image.new('RGB',(sx, sy), (0, 0, 0))
d=Image.new('RGB',(sx, sy), (0, 0, 0))
bx=ax+sx
by=ay+sy
for jy in range(0,time_y):
    for jx in range(0,time_x):
        for i in range(ax,bx):
            for k in range(ay,by):

                a=im.getpixel((i,k))
                c.putpixel((i-reducex,k-reducey),(a[0],a[1],a[2]))
               
        reducex=bx
        ax=ax+sx
        bx=ax+sx
        
        c.save(path+str(t)+".png")
        t=t+1
    reducey=by
    ax=0;bx=ax+sx
    reducex=0
    ay=ay+sy
    by=ay+sy
