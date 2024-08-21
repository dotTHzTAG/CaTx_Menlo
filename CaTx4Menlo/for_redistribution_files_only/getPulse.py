from scancontrolclient import ScanControlClient
import time
import base64
import csv
import numpy as np
import argparse
from datetime import datetime, timedelta

# address="10.0.2.74"       # set IP address of system to use
address="localhost"         # use this instead of IP address if running code directly on machine
waveform_average = 1
measurement_duration = 0
measurement_count = 1
interval_time = 0  # Default interval time is zero, meaning no delay

# create the argument parser
parser = argparse.ArgumentParser(description='average, mode, number(time or count), number(time)')

# add arguments
parser.add_argument('--average', type=int, help='waveform_average')

# Create a mutually exclusive group for 'time' and 'count'
group = parser.add_mutually_exclusive_group()
group.add_argument('--time', type=int, help='time in seconds')
group.add_argument('--count', type=int, help='number of counts')
parser.add_argument('--interval', type=int, help='interval time in seconds')
args = parser.parse_args()

# Scan options
if args.average is not None:
    waveform_average = args.average

if args.time is not None:
    measurement_duration = args.time

if args.count is not None:
    measurement_count = args.count

if args.interval is not None:
    interval_time = args.interval

print('waveform_average =', str(int(waveform_average)))
print('interval time =', str(int(interval_time)))

if measurement_duration == 0:
    count_mode = True
    print('Count mode with ' + str(int(measurement_count)) + ' count(s)')
else:
    count_mode = False
    print('Time mode with ' + str("{:.3f}".format(measurement_duration)) + ' second(s)')

vecData = []
avgReset = False
statusFile = 'progress.txt'
measurementFile = 'measurements.csv'
i = 1

def getPulse(data):
    global i, waveform_average, measurement_duration, measurement_count, timeAxis, next_measurement_time
    global tData, EData, start_time, count_mode, avgReset, current_rate, vecData, interval_time
    ScanControl.setDesiredAverages(waveform_average)
    numAvg = ScanControl.currentAverages
    current_rate = ScanControl.rate

    if numAvg < waveform_average or 1 == waveform_average:
        avgReset = True

    if numAvg == waveform_average and avgReset:
        avgReset = False        

        if count_mode:
            if i <= measurement_count:                
                if i == 1:
                    write_status(f"Current_rate = {current_rate}")
                    next_measurement_time = datetime.now() + timedelta(seconds=interval_time)
                    timeAxis = np.asarray(np.frombuffer(base64.b64decode(ScanControl.timeAxis), dtype=np.float64))  # import time axis (x-axis)
                    timeAxis = np.insert(timeAxis, 0, 0)
                    vecData = timeAxis
                    with open(measurementFile, 'w', newline='') as f_meas:
                        writer = csv.writer(f_meas)
                        writer.writerow(vecData)

                ms = round(time.time() * 1000) / 1000  # measurement time in milliseconds
                eAmp = data['amplitude'][0]  # import E-field data
                eAmp = np.insert(eAmp, 0, ms)
                vecData = eAmp                

                with open(measurementFile, 'a', newline='') as f_meas:
                    writer = csv.writer(f_meas)
                    writer.writerow(vecData)
                    
                # Wait until the next measurement time
                while datetime.now() < next_measurement_time:
                    time.sleep(0.01)  # Sleep in small increments to reduce CPU usage
                    
                ScanControl.resetAveraging()
                write_status(f"Progress: {i} of {measurement_count} counts")
                i = i + 1
                next_measurement_time = datetime.now() + timedelta(seconds=interval_time)

            if i > measurement_count:
                ScanControl.setDesiredAverages(1)
                ScanControl.stop()
                client.loop.stop()
                write_status(f"{i - 1} measurements done!")

        else:  # time_mode
            if i == 1:
                write_status(f"Current_rate = {current_rate}")
                next_measurement_time = datetime.now() + timedelta(seconds=interval_time)
                start_time = datetime.now()
                timeAxis = np.asarray(np.frombuffer(base64.b64decode(ScanControl.timeAxis), dtype=np.float64))  # import time axis (x-axis)
                timeAxis = np.insert(timeAxis, 0, 0)
                vecData = timeAxis
                with open(measurementFile, 'w', newline='') as f_meas:
                    writer = csv.writer(f_meas)
                    writer.writerow(vecData)

            total_seconds = (datetime.now() - start_time).total_seconds()
            total_seconds = round(total_seconds * 1000) / 1000

            if total_seconds <= measurement_duration:
                ms = round(time.time() * 1000) / 1000  # measurement time in milliseconds
                eAmp = data['amplitude'][0]  # import E-field data
                eAmp = np.insert(eAmp, 0, ms)
                vecData = eAmp

                with open(measurementFile, 'a', newline='') as f_meas:
                    writer = csv.writer(f_meas)
                    writer.writerow(vecData)
                    
                # Wait until the next measurement time
                while datetime.now() < next_measurement_time:
                    time.sleep(0.01)  # Sleep in small increments to reduce CPU usage
                    
                ScanControl.resetAveraging()
                write_status(f"Progress: # {i}, {total_seconds} of {measurement_duration} seconds")
                i = i + 1
                next_measurement_time = datetime.now() + timedelta(seconds=interval_time) 

            else:
                ScanControl.setDesiredAverages(1)
                ScanControl.stop()
                client.loop.stop()
                write_status(f"{i - 1} measurements done!")

def write_status(msg):
    print(msg)
    with open(statusFile, 'w') as f:
        f.write(msg)
        f.flush()

client = ScanControlClient()
client.connect(host=address)
ScanControl = client.scancontrol
write_status("Python script runs")
ScanControl.resetAveraging()
client.loop.run_until_complete(ScanControl.start())
ScanControl.pulseReady.connect(getPulse)
client.loop.run_forever()