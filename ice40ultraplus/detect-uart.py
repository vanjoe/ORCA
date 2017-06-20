import numpy as np
import cv2
import base64
import serial
import sys
import time
scale=10

ss=serial.Serial(sys.argv[1],baudrate=115200)
is_face=False
filename=None
while(True):
    ln=ss.readline()[:-1]
    img_rows=32
    img_cols = 32

    if "base64:" == ln[:len("base64:")] :
        ln=ln[len("base64:"):]
        try:
            data=[ord(c) for c in base64.decodestring(ln)]
        except base64.binascii.Error:
            sys.stderr.write("Python Error: Bad base64 string\n")
            continue
        try:
            cvimage = np.array(data,dtype=np.uint8)
            cvimage = cvimage.reshape(img_rows,img_cols,3)
        except ValueError:
            sys.stderr.write("Python Error: Numpy conversion error\n")
            continue

        bigimage=cv2.resize(cvimage,(img_cols*scale,img_rows*scale),interpolation=cv2.INTER_NEAREST)

        cv2.imshow('Cam',bigimage)
        filename=None
        key=cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        if key == ord('f'):
            filename="face_{}.png".format(int(time.time()*10))
        if key == ord('n'):
            filename="notface_{}.png".format(int(time.time()*10))

    else:
        print(ln)
        if "Face Score =" in ln:
            score = int(ln.split()[-1])
            if filename:
                filename="s_{}_".format(score)+filename
                print("saving: {}".format(filename))
                cv2.imwrite(filename,cvimage)
