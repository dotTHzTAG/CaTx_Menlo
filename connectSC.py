from scancontrolclient import ScanControlClient

address="localhost"         # use this instead of IP address if running code directly on machine

client = ScanControlClient()
client.connect(host=address)
status = client.scancontrol.status
