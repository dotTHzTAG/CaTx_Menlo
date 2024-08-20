from scancontrolclient import ScanControlClient, ScanControlStatus
import asyncio

# Address to connect to
# address = "10.0.2.74"  # Set IP address of the system to use
address = "localhost"  # Use this instead of IP address if running code directly on the machine
statusFile = 'status.txt'

def write_status(msg):
    print(msg)
    with open(statusFile, 'w') as f:
        f.write(msg)
        f.flush()

async def get_status():
    client = ScanControlClient()
    client.connect(host=address)
    ScanControl = client.scancontrol

    # Wait for the connection and initialization
    await asyncio.sleep(2)  # Adjust the sleep duration if needed for your setup

    # Retrieve the current status of ScanControl
    current_status = ScanControl.status

    # Convert the status to a human-readable format
    status_name = ScanControlStatus(current_status).name

    # Write the status to the file
    write_status(f"ScanControl Status: {status_name}")

if __name__ == "__main__":
    asyncio.run(get_status())