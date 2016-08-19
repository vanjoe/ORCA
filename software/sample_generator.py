import math
import random
import serial
import matplotlib.pyplot as plt
import numpy as np

sample_l = []
sample_r = []

REAL_DATA = False 

FREQUENCY1 = 200 # Hz
OFFSET1 = 0
FREQUENCY2 = 77
OFFSET2 = -23
FREQUENCY3 = 131
OFFSET3 = 11

SAMPLE_RATE = 7800 # Hz
DISTANCE = 140 # mm
SPEED_OF_SOUND  = 343e3 # mm/s
SAMPLE_DIFFERENCE = int(DISTANCE*SAMPLE_RATE/SPEED_OF_SOUND)
WINDOW_SIZE = 64 

print SAMPLE_DIFFERENCE
print '\n'

if REAL_DATA:
  with serial.Serial('/dev/ttyUSB0', 115200, timeout = 1) as ser:
    while True:
      line = ser.readline().strip()
      if '\x04' in line:
        break
      sample_l.append(line)
      line = ser.readline().strip()
      if '\x04' in line:
        break
      sample_r.append(line)

    
else:
# Generate and sum 3 signals together.
  def get_sample(i):
    if (i % 7 == 2):
      return 1
    elif (i % 7 == 5):
      return 2
    else:
      return 0
#    signal1 = math.sin(2*math.pi*FREQUENCY1*(i+OFFSET1)/SAMPLE_RATE)
#    signal2 = math.sin(2*math.pi*FREQUENCY2*(i+OFFSET2)/SAMPLE_RATE)
#    signal3 = math.sin(2*math.pi*FREQUENCY3*(i+OFFSET3)/SAMPLE_RATE)
#    signal_sum = (signal1+signal2+signal3) * 32767 / 3
#    return int(signal_sum)


# Forward facing sound (no delay).
  for i in range(0, WINDOW_SIZE):
    sample_l.append(get_sample(i))
    sample_r.append(get_sample(i))

# Left facing sound (right microphone is delayed).
  for i in range(WINDOW_SIZE, 2*WINDOW_SIZE):
    sample_l.append(get_sample(i))
    sample_r.append(get_sample(i - SAMPLE_DIFFERENCE))

# Right facing sound (left microphone is delayed).
  for i in range(2*WINDOW_SIZE, 3*WINDOW_SIZE):
    sample_l.append(get_sample(i - SAMPLE_DIFFERENCE))
    sample_r.append(get_sample(i))

# Format samples for C file.
f = open('samples.c', 'w')
f.write('#include "samples.h"\n\n')

f.write('int samples_l[NUM_SAMPLES] = {\n\t')
for i in range(0, 3*WINDOW_SIZE):
  f.write('{:d}'.format(sample_l[i]));
  if (i != 3*WINDOW_SIZE-1):
    f.write(',\n\t')
  else:
    f.write('\n};')

f.write('\n\n')


f.write('int samples_r[NUM_SAMPLES] = {\n\t')
for i in range(0, 3*WINDOW_SIZE):
  f.write('{:d}'.format(sample_r[i]));
  if (i != 3*WINDOW_SIZE-1):
    f.write(',\n\t')
  else:
    f.write('\n};')

f.close()


vector1 = sample_l
vector2 = sample_r

# Insert buffer of zeroes to handle delayed samples before 
# sine wave starts.
for i in range(0, SAMPLE_DIFFERENCE):
  vector1.insert(0, 0)
  vector2.insert(0, 0)

power_front = 0
power_left = 0
power_right = 0
for i in range(0, WINDOW_SIZE):
  temp = vector1[i+SAMPLE_DIFFERENCE]+vector2[i+SAMPLE_DIFFERENCE]
  print '{} {} {} {}'.format(i, temp, vector1[i+SAMPLE_DIFFERENCE], vector2[i+SAMPLE_DIFFERENCE])
  power_front += temp*temp
print '\n'
for i in range(0, WINDOW_SIZE):
  temp = vector1[i]+vector2[i+SAMPLE_DIFFERENCE]
  print '{} {} {} {}'.format(i, temp, vector1[i], vector2[i+SAMPLE_DIFFERENCE])
  power_left += temp*temp
print '\n'
for i in range(0, WINDOW_SIZE):
  temp = vector1[i+SAMPLE_DIFFERENCE]+vector2[i]
  print '{} {} {} {}'.format(i, temp, vector1[i+SAMPLE_DIFFERENCE], vector2[i])
  power_right += temp*temp
print '\n'

print power_front
print power_left
print power_right
print max(power_front, power_left, power_right)
print '\n'

power_front = 0
power_left = 0
power_right = 0
for i in range(WINDOW_SIZE, 2*WINDOW_SIZE):
  temp = vector1[i+SAMPLE_DIFFERENCE]+vector2[i+SAMPLE_DIFFERENCE]
  power_front += temp*temp
for i in range(WINDOW_SIZE, 2*WINDOW_SIZE):
  temp = vector1[i]+vector2[i+SAMPLE_DIFFERENCE]
  power_left += temp*temp
for i in range(WINDOW_SIZE, 2*WINDOW_SIZE):
  temp = vector1[i+SAMPLE_DIFFERENCE]+vector2[i]
  power_right += temp*temp

print power_front
print power_left
print power_right
print max(power_front, power_left, power_right)
print '\n'
  
power_front = 0
power_left = 0
power_right = 0
for i in range(2*WINDOW_SIZE, 3*WINDOW_SIZE):
  temp = vector1[i+SAMPLE_DIFFERENCE]+vector2[i+SAMPLE_DIFFERENCE]
  power_front += temp*temp
for i in range(2*WINDOW_SIZE, 3*WINDOW_SIZE):
  temp = vector1[i]+vector2[i+SAMPLE_DIFFERENCE]
  power_left += temp*temp
for i in range(2*WINDOW_SIZE, 3*WINDOW_SIZE):
  temp = vector1[i+SAMPLE_DIFFERENCE]+vector2[i]
  power_right += temp*temp

print power_front
print power_left
print power_right
print max(power_front, power_left, power_right)
print '\n'
