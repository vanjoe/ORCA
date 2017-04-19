import numpy as np
import cv2
import base64
import serial
import sys
import time
scale=10

ss=serial.Serial(sys.argv[1],baudrate=115200)

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

        cvimage = np.array(data,dtype=np.uint8).reshape(img_rows,img_cols,3)
        check=cvimage[30][0][0] != 0

        #set last two rows as green or red
        cvimage[30:,:,0] = 0
        cvimage[30:,:,1] = 255 if check else 0
        cvimage[30:,:,2] = 0 if check else 255

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
        if filename:
            print("saving: {}".format(filename))
            cv2.imwrite(filename,cvimage)
    elif "scores:" == ln[:len("scores:")]:
        ln=ln[len("scores:"):]
        catagories=["air", "auto", "bird", "cat", "person", "dog", "frog", "horse", "ship", "truck"]
        scores=zip(catagories,[int(s) for s in ln.split()])

        max_score= max(scores,key=lambda x :x[1])
        for c,s in scores:
            sys.stdout.write("{}\t{}".format(c,s))
            if c== max_score[0]:
                sys.stdout.write("   <==\n")
            else:
                sys.stdout.write("\n")
        print("")
    else:
        print ln
        pass
