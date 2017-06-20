import serial
import time
import csv
import sys
import base64,struct
import json
import random
import subprocess,shlex
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
        i=0
        while True:
            line = ser.readline().strip()

            #for some reason NULL bytes slip in, this next line removes them
            line = ''.join([c for c in line if c != "\0"])
            if 'START' in line:
                str_data=base64.b64decode(ser.readline().strip())
                continue
            if 'COMMENT' in line:
                sys.stderr.write("Info: %s\n"%line)
                continue
            if 'END' in line:
                break;
            if 'OVERFLOW' in line:
                raise RuntimeError("Device ran out of memory, sound too long\n")
                sys.stderr.write("Error: Overflow\n")
                break;
            if 'checksum' in line:
                checksum = int(line[len("checksum = "):],16)


    data = [struct.unpack_from("<hh",str_data,offset) for offset in xrange(0,len(str_data),4)]
    total=0
    for l,r in data:
        total+=l+r
    if (total & 0xFFFFFFFF) != checksum :
        raise RuntimeError("Checksum's do not match")
    return data



def get_params():
    try:
        word_list = json.load(open('words.json'))['data']
    except IOError:
        subprocess.check_output(['wget','https://www.randomlists.com/data/words.json'])
        word_list = json.load(open('words.json'))['data']
    voices=['en',
            'en-us',
            'en-wm',
            'en-rp',
            'en-wi']

    words=([random.choice(word_list)]*4)+["Vectorblox"] #20% chance of vectorblox
    return {"word":random.choice(words),
            "voice":random.choice(voices),
            "speed":random.randint(100,200),
            "pitch":random.randint(30,70)}


if __name__ == '__main__':

    params=get_params()
    file_name="{word}_{voice}_s{speed}_p{pitch}.wav".format(**params)
    espeak_cmd='espeak -v {voice}  -p {pitch} -s {speed} "{word}"'.format(**params)

    data=get_sound_data(lambda : (sys.stderr.write("Word = {}\n".format(params['word'])),subprocess.check_output(shlex.split(espeak_cmd))))


    csv_writer=csv.writer(sys.stdout)
    csv_writer.writerow(("left","right"))
    for i in data:
        csv_writer.writerow(i)
    sys.stderr.write("Done\n")
