import math
import random
import serial
import matplotlib.pyplot as plt
import numpy as np

fir = [
  89,
  166,
  246,
  271,
  199,
  28,
  -190,
  -361,
  -383,
  -211,
  110,
  438,
  592,
  441,
  -5,
  -569,
  -964,
  -927,
  -369,
  528,
  1350,
  1615,
  1017,
  -363,
  -1995,
  -3045,
  -2690,
  -486,
  3373,
  8032,
  12223,
  14701,
  14701,
  12223,
  8032,
  3373,
  -486,
  -2690,
  -3045,
  -1995,
  -363,
  1017,
  1615,
  1350,
  528,
  -369,
  -927,
  -964,
  -569,
  -5,
  441,
  592,
  438,
  110,
  -211,
  -383,
  -361,
  -190,
  28,
  199,
  271,
  246,
  166,
  89]

sample_l = []
sample_r = []

REAL_DATA = False 

FREQUENCY1 = 200 # Hz
OFFSET1 = 0
FREQUENCY2 = 1200 
OFFSET2 = -17
FREQUENCY3 = 1400
OFFSET3 = 29

SAMPLE_RATE = 8000 # Hz
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
#    if (i % 7 == 2):
#      return 1
#    elif (i % 7 == 5):
#      return 2
#    else:
#      return 0
#    signal1 = math.sin(2*math.pi*FREQUENCY1*(i+OFFSET1)/SAMPLE_RATE)
#    signal2 = math.sin(2*math.pi*FREQUENCY2*(i+OFFSET2)/SAMPLE_RATE)
#    signal3 = math.sin(2*math.pi*FREQUENCY3*(i+OFFSET3)/SAMPLE_RATE)
#    signal_sum = (signal1+signal2+signal3) * 32767 / 3
#    return int(signal_sum)
    return int(math.sin(2*math.pi*FREQUENCY1*(i+OFFSET1)/SAMPLE_RATE)*12000)


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


# Apply FIR filter
temp_l = []
temp_r = []
vector1 = []
vector2 = []

for i in range(0, 3 * WINDOW_SIZE):
  temp_l.append(0)
  temp_r.append(0)
  
sample_count = 0;
for i in range(0, 3 * WINDOW_SIZE):
  temp_l = temp_l[1:]
  temp_r = temp_r[1:]
  temp_l.append(sample_l[sample_count])
  temp_r.append(sample_r[sample_count])
  sample_count += 1
 
  fir_acc_l = 0
  fir_acc_r = 0 
  for j in range(0, WINDOW_SIZE):
    fir_acc_l += temp_l[j] * fir[j];
    fir_acc_r += temp_r[j] * fir[j]; 

  vector1.append(fir_acc_l)
  vector2.append(fir_acc_r)

print vector1
print '\n'
print vector2
print '\n'

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
