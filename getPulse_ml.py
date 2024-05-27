from scancontrolclient import ScanControlClient
import time
import base64
import csv
import numpy as np
from datetime import datetime
from astropy.io import ascii
from astropy.table import Table

# address="10.0.2.74"       # set IP address of system to use
address="localhost"         # use this instead of IP address if running code directly on machine

# Scan options
measurement_average = 100
measurement_time = 6  # measurement period in seconds
measurement_count = 5 # total measurement count
count_mode = False

print('measurement_average =',str(int(measurement_average)))

if count_mode:
    print('Measurement mode: Count with '+ str(int(measurement_count))+' count(s)')
else:
    print('Measurement mode: Time with ' + str("{:.3f}".format(measurement_time))+'second(s)')
    
vecData = []
EData = []
i=1
avgReset = False
measurement_table = Table()
FileName = 'measurements.csv'



#%%
def getPulse(data):
    global i, measurement_average, measurement_time, measurement_count, measurement_table
    global tData, EData, start_time, count_mode, avgReset, current_rate,vecData
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
                    
                ms = round(time.time()*1000) # measurement time in milliseconds
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
                    f_prog.write(progress_message + "\n")
                    f_prog.flush()
                i=i+1
            else:
                ScanControl.resetAveraging()
                ScanControl.stop()
                client.loop.stop()   
                print(str(i-1)+" measurements done!")                         
                with open('progress.txt','w') as f:
                    progress_message = "Measurement done!"
                    f.write(progress_message + "\n")
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
                    progress_message = "Measurement done!"
                    f.write(progress_message + "\n")
                    f.flush()
                print(str(i-1)+ " measurements done!")

#%%

client = ScanControlClient()
client.connect(host=address)
ScanControl = client.scancontrol
ScanControl.resetAveraging()
client.loop.run_until_complete(ScanControl.start())
ScanControl.pulseReady.connect(getPulse)
client.loop.run_forever()