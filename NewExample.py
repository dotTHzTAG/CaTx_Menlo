from scancontrolclient import ScanControlClient

import base64
import numpy as np


# Scan options
# address="10.0.2.74"      # set IP address of system to use
address="localhost"         # use this instead of IP address if running code directly on machine
averages = [20,40,50,80]           # number of averages to perform, ex: [10000, 5000, 3000, ..., 2, 1]

tData = []
EData = []
i=0

#%%
def getPulse(data):
    global i, averages, tData, EData
    numAvg = ScanControl.currentAverages
    ScanControl.setDesiredAverages(averages[i])
    if numAvg == averages[i] :
        tAxis=np.asarray(np.frombuffer(base64.b64decode(ScanControl.timeAxis), dtype=np.float64)) # import time axis (x-axis)
        E1=data['amplitude'][0] # import E-field data (time)
        EData.append(E1) # save raw data for export
        tData.append(tAxis)
        ScanControl.resetAveraging()
        i=i+1
        print(str(i)+' of '+str(len(averages))+' measured.')
    if len(EData)==len(averages): 
        ScanControl.stop()
        client.loop.stop()
        # client.disconnect()
        print("Measurements done!")
        


#%%

client = ScanControlClient()
client.connect(host=address)
ScanControl = client.scancontrol
client.loop.run_until_complete(ScanControl.start())
ScanControl.pulseReady.connect(getPulse)
client.loop.run_forever()


