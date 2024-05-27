from scancontrolclient import ScanControlClient
import time
import base64
import csv
import numpy as np
import argparse
from datetime import datetime


# address="10.0.2.74"       # set IP address of system to use
address="localhost"         # use this instead of IP address if running code directly on machine

# create the argument parser
parser = argparse.ArgumentParser(description = 'average, time, count, count_mode')

# add arguments
parser.add_argument('average', type = int, help = 'measurement_average')
parser.add_argument('time', type = int, help = 'measurement_time (seconds)')
parser.add_argument('count', type = int, help = 'measurement_count')
parser.add_argument('mode', type =int, help = 'count_mode (0 or 1)')
args = parser.parse_args()

# Scan options
measurement_average = args.average
measurement_time = args.time  # measurement period in seconds
measurement_count = args.count # total measurement count
count_mode = args.mode # Ture for count_mode

print('measurement_average =',str(int(measurement_average)))

if count_mode > 0:
    print('Measurement mode: Count with '+ str(int(measurement_count))+' count(s)')
else:
    print('Measurement mode: Time with ' + str("{:.3f}".format(measurement_time))+'second(s)')
    
vecData = []
i=1
avgReset = False
FileName = 'measurements.csv'

#%%
def getPulse(data):
    global i, measurement_average, measurement_time, measurement_count
    global tData, EData, start_time, count_mode, avgReset, current_rate, vecData
    ScanControl.setDesiredAverages(measurement_average)
    numAvg = ScanControl.currentAverages
    current_rate = ScanControl.rate
    
    if numAvg < measurement_average or 1 == measurement_average:
        avgReset = True
    
    if numAvg == measurement_average and avgReset:
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
                ScanControl.resetAveraging()
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
                ScanControl.resetAveraging()
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