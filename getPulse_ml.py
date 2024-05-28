from scancontrolclient import ScanControlClient
import time
import base64
import csv
import numpy as np
import argparse
from datetime import datetime

# address="10.0.2.74"       # set IP address of system to use
address="localhost"         # use this instead of IP address if running code directly on machine
waveform_average = 1
measurement_time = 0
measurement_count = 1

# create the argument parser
parser = argparse.ArgumentParser(description = 'average, mode, number(time or count)')

# add arguments
parser.add_argument('--average', type = int, help = 'waveform_average')

# Create a mutually exclusive group for 'time' and 'count'
group = parser.add_mutually_exclusive_group()
group.add_argument('--time', type=int, help='time in seconds')
group.add_argument('--count', type=int, help='number of counts')
args = parser.parse_args()

# Scan options
if args.average is not None:
    waveform_average = args.average
    
if args.time is not None:
    measurement_time = args.time
    
if args.count is not None:
    measurement_count = args.count

print('waveform_average =',str(int(waveform_average)))

if measurement_time == 0:
    count_mode = True
    print('Count mode with '+ str(int(measurement_count))+' count(s)')
else:
    count_mode = False
    print('Time mode with ' + str("{:.3f}".format(measurement_time))+'second(s)')
    
vecData = []
avgReset = False
FileName = 'measurements.csv'
i=1

#%%
def getPulse(data):
    global i, waveform_average, measurement_time, measurement_count
    global tData, EData, start_time, count_mode, avgReset, current_rate, vecData
    ScanControl.setDesiredAverages(waveform_average)
    numAvg = ScanControl.currentAverages
    current_rate = ScanControl.rate
    
    if numAvg < waveform_average or 1 == waveform_average:
        avgReset = True
    
    if numAvg == waveform_average and avgReset:
        avgReset = False
#        print('current_rate =  ' +  str(current_rate))
        
        if count_mode:
            if i<=measurement_count:
                if i == 1:
                    timeAxis=np.asarray(np.frombuffer(base64.b64decode(ScanControl.timeAxis), dtype=np.float64)) # import time axis (x-axis)
                    timeAxis = np.insert(timeAxis,0,0)
                    vecData = timeAxis
                    with open(FileName,'w', newline='') as f_meas:
                        writer = csv.writer(f_meas)
                        writer.writerow(vecData)
                    
                ms = round(time.time()*1000)/1000 # measurement time in milliseconds
                eAmp = data['amplitude'][0] # import E-field data (column title: milliseconds)
                eAmp = np.insert(eAmp,0,ms)
                vecData = eAmp
                with open(FileName,'a', newline='') as f_meas:
                    writer = csv.writer(f_meas)
                    writer.writerow(vecData)
                ScanControl.resetAveraging()
                print(str(i)+' of '+str(measurement_count)+' measured.')
                with open('progress.txt','w') as f_prog:
                    progress_message = f"Progress: {i} of {measurement_count} counts"
                    f_prog.write(progress_message)
                    f_prog.flush()
                i=i+1
            else:
                #ScanControl.resetAveraging()
                ScanControl.stop()
                client.loop.stop()   
                print(f"{i-1} measurements done!")                         
                with open('progress.txt','w') as f:
                    progress_message = f"{i-1} measurements done!"
                    f.write(progress_message)
                    f.flush()
        else: # time_mode
            if i==1:
                start_time = datetime.now()
                timeAxis=np.asarray(np.frombuffer(base64.b64decode(ScanControl.timeAxis), dtype=np.float64)) # import time axis (x-axis)
                timeAxis = np.insert(timeAxis,0,0)
                vecData = timeAxis
                with open(FileName,'w', newline='') as f_meas:
                    writer = csv.writer(f_meas)
                    writer.writerow(vecData)
            
            total_seconds = (datetime.now()-start_time).total_seconds()    
            if  total_seconds <= measurement_time:
                ms = round(time.time()*1000) # measurement time in milliseconds
                eAmp = data['amplitude'][0] # import E-field data (column title: milliseconds)
                eAmp = np.insert(eAmp,0,ms)
                vecData = eAmp
                
                with open(FileName,'a', newline='') as f_meas:
                    writer = csv.writer(f_meas)
                    writer.writerow(vecData)
                ScanControl.resetAveraging()
                print(str(total_seconds)+' of '+str(measurement_time)+' seconds')
                with open('progress.txt','w') as f_prog:
                    progress_message = f"Progress: {i} of {measurement_time} seconds"
                    f_prog.write(progress_message + "\n")
                    f_prog.flush()
                i=i+1                
            else:
                #ScanControl.resetAveraging()
                ScanControl.stop()
                client.loop.stop()          
                with open('progress.txt','w') as f:
                    progress_message = f"{i-1} measurements done!"
                    f.write(progress_message)
                    f.flush()
                print(f"{i-1} measurements done!")

#%%

client = ScanControlClient()
client.connect(host=address)
ScanControl = client.scancontrol
ScanControl.resetAveraging()
client.loop.run_until_complete(ScanControl.start())
ScanControl.pulseReady.connect(getPulse)
client.loop.run_forever()