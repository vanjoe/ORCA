import numpy as np
import cv2
import base64
import serial
import sys

scale=10

ss=serial.Serial(sys.argv[1],baudrate=115200)

while(True):
    ln=ss.readline()[:-1]
    img_rows=32
    img_cols = 64
    header="P6\n{} {}\n255\n".format(img_cols,img_rows)
    if "base64:" in ln :
        ln=ln[len("base64:"):]
        try:
            data=header+base64.decodestring(ln)
        except base64.binascii.Error:
            sys.stderr.write("Python Error: Bad base64 string\n")
            continue
        with open("pythontmp.ppm","w") as tmp_file:
            tmp_file.write(data)
            tmp_file.flush();
        cvimage = cv2.imread('pythontmp.ppm')

        cvimage=cv2.resize(cvimage,(img_cols*scale,img_rows*scale),interpolation=cv2.INTER_NEAREST)
        cvimage0=cv2.extractChannel(cvimage,0)
        cvimage1=cv2.extractChannel(cvimage,1)
        cvimage2=cv2.extractChannel(cvimage,2)

        #cv2.imshow('f0:blu',cvimage0)
        #cv2.imshow('f1:grn',cvimage1)
        #cv2.imshow('f2:red',cvimage2)
        cv2.imshow('rgb0',cvimage)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    else:
        print ln
