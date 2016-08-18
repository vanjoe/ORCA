import math
import random

FREQUENCY1 = 200 # Hz
OFFSET1 = 0
FREQUENCY2 = 77
OFFSET2 = -23
FREQUENCY3 = 131
OFFSET3 = 11

SAMPLE_RATE = 48e3 # Hz
DISTANCE = 100 # mm
SPEED_OF_SOUND  = 343e3 # mm/s
SAMPLE_DIFFERENCE = (DISTANCE*SAMPLE_RATE/SPEED_OF_SOUND)

sample_l = []
sample_r = []

def get_sample(i):
  signal1 = math.sin(2*math.pi*FREQUENCY1*(i+OFFSET1)/SAMPLE_RATE)
  signal2 = math.sin(2*math.pi*FREQUENCY2*(i+OFFSET2)/SAMPLE_RATE)
  signal3 = math.sin(2*math.pi*FREQUENCY3*(i+OFFSET3)/SAMPLE_RATE)
  signal_sum = (signal1+signal2+signal3) * 32767 / 3
  return int(signal_sum)

# Forward facing sound (no delay)
for i in range(0, 128):
  sample_l.append(get_sample(i))
  sample_r.append(get_sample(i))

# Left facing sound (right microphone is delayed)
for i in range(128, 256):
  sample_l.append(get_sample(i))
  sample_r.append(get_sample(i - SAMPLE_DIFFERENCE))

# Right facing sound (left microphone is delayed)
for i in range(256, 384):
  sample_l.append(get_sample(i - SAMPLE_DIFFERENCE))
  sample_r.append(get_sample(i))


f = open('samples.c', 'w')
f.write('#include "samples.h"\n\n')

f.write('int samples_l[NUM_SAMPLES] = {\n\t')
for i in range(0, 384):
  f.write('{:d}'.format(sample_l[i]));
  if (i != 383):
    f.write(',\n\t')
  else:
    f.write('\n};')

f.write('\n\n')


f.write('int samples_r[NUM_SAMPLES] = {\n\t')
for i in range(0, 384):
  f.write('{:d}'.format(sample_r[i]));
  if (i != 383):
    f.write(',\n\t')
  else:
    f.write('\n};')


f.close()


vector1 = sample_l
vector2 = sample_r

for i in range(0, 13):
  vector1.insert(0, random.randrange(-32768, 32767, 1))
  vector2.insert(0, random.randrange(-32768, 32767, 1))

power_front = 0
power_left = 0
power_right = 0
for i in range(0, 128):
  power_front += vector1[i+13]*vector2[i+13]
  power_left += vector1[i+13]*vector2[i]
  power_right += vector1[i]*vector2[i+13]
 
print power_front 
print power_left
print power_right


power_front = 0
power_left = 0
power_right = 0
for i in range(128, 256):
  power_front += vector1[i+13]*vector2[i+13]
  power_left += vector1[i+13]*vector2[i]
  power_right += vector2[i]*vector2[i+13]

print power_front
print power_left
print power_right
  
power_front = 0
power_left = 0
power_right = 0
for i in range(256, 384):
  power_front += vector1[i+13]*vector2[i+13]
  power_left += vector1[i+13]*vector2[i]
  power_right += vector2[i]*vector2[i+13]

print power_front
print power_left
print power_right

