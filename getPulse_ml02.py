from scancontrolclient import ScanControlClient
#import time
import base64
import numpy as np
from datetime import datetime
#from astropy.io import ascii
#from astropy.table import Table


# address="10.0.2.74"       # set IP address of system to use
address="localhost"         # use this instead of IP address if running code directly on machine

# Scan options
#averages = [20,40,50,80]   # number of averages to perform, ex: [10000, 5000, 3000, ..., 2, 1]
#measurement_average = 100
#measurement_time = 15  # measurement period in seconds
#measurement_count = 5 # total measurement count
#count_mode = False

print('measurement_average =',str(int(measurement_average)))

if count_mode:
    print('Measurement mode: Count with '+ str(int(measurement_count))+' count(s)')
else:
    print('Measurement mode: Time with ' + str("{:.3f}".format(measurement_time))+'second(s)')
    
tData = []
EData = []
i=1
avgReset = False

#%%
def getPulse(data):
    global i, measurement_average, measurement_time, measurement_count
    global tData, EData, start_time, count_mode, avgReset, current_rate
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
                tAxis=np.asarray(np.frombuffer(base64.b64decode(ScanControl.timeAxis), dtype=np.float64)) # import time axis (x-axis)
                E1=data['amplitude'][0] # import E-field data (time)
                EData.append(E1) # save raw data for export
                tData.append(tAxis)
                ScanControl.resetAveraging()
                print(str(i)+' of '+str(measurement_count)+' measured.')
                i=i+1
            else:
                ScanControl.resetAveraging()
                ScanControl.stop()
                client.loop.stop()                            
                print("Measurements done!")
        else: # time_mode
            if i==1:
                start_time = datetime.now()
            
            total_seconds = (datetime.now()-start_time).total_seconds()    
            if  total_seconds <= measurement_time:
                tAxis=np.asarray(np.frombuffer(base64.b64decode(ScanControl.timeAxis), dtype=np.float64)) # import time axis (x-axis)
                E1=data['amplitude'][0] # import E-field data (time)
                EData.append(E1) # save raw data for export
                tData.append(tAxis)
                ScanControl.resetAveraging()
                print(str(total_seconds)+' of '+str(measurement_time)+' seconds')
                i=i+1                
            else:
                ScanControl.resetAveraging()
                ScanControl.stop()
                client.loop.stop()          
                print(str(i)+ " measurements done!")

#%%

client = ScanControlClient()
client.connect(host=address)
ScanControl = client.scancontrol
ScanControl.resetAveraging()
client.loop.run_until_complete(ScanControl.start())
ScanControl.pulseReady.connect(getPulse)
client.loop.run_forever()
output = [tData, EData]