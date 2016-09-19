import serial
import time
import csv
import sys

def get_sound_data(func):
    with  serial.Serial('/dev/ttyUSB0', 115200, timeout=1) as ser:
        sys.stderr.write("Waiting (clearing serial buffer)\n")
        while len(ser.read(1)) ==1:
            pass

        sys.stderr.write("Recording\n")
        ser.write('1');
        func()
        ser.write('2')
        sys.stderr.write("Receiving Data\n")
        data=[]
        i=0
        while True:
            line = ser.readline().strip()

            #for some reason NULL bytes slip in, this next line removes them
            line = ''.join([c for c in line if c != "\0"])
            if 'START' in line:
                continue
            if 'END' in line:
                break;
            if 'OVERFLOW' in line:
                sys.stderr.write("Error: Overflow\n")
                break;

            try:
                left,right,checksum= [int(a) for a in line.split()]

                if left + right !=checksum:
                    sys.stderr.write("sample %d: %d + %d != %d \n" %(i, left,right,checksum))
                    break
            except Exception as e:
                sys.stderr.write("line = '%s'"% (line))
                raise e
            data.append((left,right))
            i+=1
    return data


if __name__ == '__main__':
    data=get_sound_data(lambda : time.sleep(1))

    csv_writer=csv.writer(sys.stdout)
    csv_writer.writerow(("left","right"))
    for i in data:
        csv_writer.writerow(i)
    sys.stderr.write("Done\n")
