from evdev import list_devices, InputDevice

devices = [InputDevice(dev) for dev in list_devices()]
for dev in devices:
    print(f"{dev.path}: {dev.name}")