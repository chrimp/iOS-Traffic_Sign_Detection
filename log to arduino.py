import os
import re
import time
import serial

arduino = serial.Serial('/dev/cu.usbserial-14240', baudrate=9600)
time.sleep(1)

while True:
    Right = Right1 = Right2 = Left = Left1 = Left2 = 0
    log = os.popen('gtimeout 0.04 idevicesyslog -n | grep BreakfastFinder').read()
    annoR = [r'\bRight\b', 'Right_1', 'Right_2']
    annoL = [r'\bLeft\b', 'Left_1', 'Left_2']
    right_re = re.compile('|'.join(annoR))
    left_re = re.compile('|'.join(annoL))
    right_gath = right_re.findall(log)
    left_gath = left_re.findall(log)
    print(right_gath)
    print(left_gath)
    for i in right_gath:
        if i == 'Right': Right += 1
        elif i == 'Right_1': Right1 += 1
        elif i == 'Right_2': Right2 += 2
    for i in left_gath:
        if i == 'Left': Left += 1
        elif i == 'Left_1': Left1 += 1
        elif i == 'Left_2': Left2 += 1
    Left_SUM = Left + Left1 + Left2
    Right_SUM = Right + Right1 + Right2
    if Right != 0 and Right1 != 0 and Right2 != 0 and Left != 0 and Left1 != 0 and Left2 != 0:
        if Left_SUM > Right_SUM:
            print("Left_on_SUM")
            arduino.write('Left'.encode())
        else:
            print("Right_on_SUM")
            arduino.write('Right'.encode())
    elif Right != 0 and Right1 != 0 and Right2 != 0:
        print("Right_on_Triple")
        arduino.write('Right'.encode())
    elif Left != 0 and Left1 != 0 and Left2 != 0:
        print("Left_on_Triple")
        arduino.write('Left'.encode())
    else:
        RL = [Right, Right1, Right2]
        RI = 0
        LL = [Left, Left1, Left2]
        LI = 0
        for i in RL:
            if i != 0:
                RI += 1
        for i in LL:
            if i != 0:
                LI += 1
        if LI == RI:
            if Right_SUM > Left_SUM:
                print("Right_on_sec_SUM")
                arduino.write('Right'.encode())
            elif Right_SUM < Left_SUM:
                print("Left_on_sec_SUM")
                arduino.write('Left'.encode())
        elif LI == 2:
            print("Left_on_sec_Double")
            arduino.write('Left'.encode())
        elif RI == 2:
            print("Right_on_sec_Double")
            arduino.write('Right'.encode())
        else:
            pass
    time.sleep(1)
    print(arduino.read_all())
