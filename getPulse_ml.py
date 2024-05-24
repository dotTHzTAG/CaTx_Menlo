from scancontrolclient import ScanControlClient
import time
import base64
import numpy as np

# Scan options
# address="10.0.2.74"      # set IP address of system to use
address="localhost"         # use this instead of IP address if running code directly on machine
averages = [50,50,50,1]           # number of averages to perform, ex: [10000, 5000, 3000, ..., 2, 1]
#averages = [2]


tData = []
EData = []
i=0
avgReset = False

#%%
def getPulse(data):
    global i, averages, tData, EData, avgReset
    numAvg = ScanControl.currentAverages
    current_status = ScanControl.status
    ScanControl.setDesiredAverages(averages[i])
    print('current_status = '+str(current_status)+'::'+'current_average = ' + str(numAvg))
    
    if numAvg < averages[i] or 1 == averages[i]:
        avgReset = True
    
    if numAvg == averages[i] and avgReset:
        avgReset = False
        tAxis=np.asarray(np.frombuffer(base64.b64decode(ScanControl.timeAxis), dtype=np.float64)) # import time axis (x-axis)
        E1=data['amplitude'][0] # import E-field data (time)
        EData.append(E1) # save raw data for export
        tData.append(tAxis)
        i=i+1
        print(str(i)+' of '+str(len(averages))+' measured.')
        ScanControl.resetAveraging()
        numAvg = ScanControl.currentAverages
        current_status = ScanControl.status
        print('current_status = '+str(current_status)+'::'+'current_average = ' + str(numAvg))
       
        
    if len(EData)==len(averages): 
        ScanControl.stop()
        client.loop.stop()
        print("Measurements done!")
        


#%%

client = ScanControlClient()
client.connect(host=address)
ScanControl = client.scancontrol
ScanControl.resetAveraging()
client.loop.run_until_complete(ScanControl.start())
ScanControl.pulseReady.connect(getPulse)
client.loop.run_forever()
output = [tData, EData]