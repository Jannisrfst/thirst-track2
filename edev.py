from evdev import InputDevice, categorize, ecodes
import asyncio
from typing import Optional, List


DEVICE_PATH = "/dev/input/event4"
dev: Optional[InputDevice] = None


async def initializeDeviceAsync() -> InputDevice:
    """Async version of initialize_device"""
    global dev
    if dev is None:
        dev = InputDevice(DEVICE_PATH)
        print(dev)
    return dev


async def releaseDeviceAsync() -> None:
    """Async version of release_device"""
    global dev
    if dev is not None:
        dev.close()
        dev = None


async def getKeycodeAsync() -> list[str]:
    """Async version of get_keycode"""
    global dev
    if dev is None:
        await initializeDeviceAsync()
    print("waiting for event")
    keycodeList: List[str] = []
    async for event in dev.async_read_loop():
        print(
            f"Received event: type={event.type}, code={event.code}, value={event.value}"
        )
        if event.type == ecodes.EV_KEY:
            categorizedEvent = categorize(
                event
            )  # categorizes events based on types such as: EV_KEY, EV_REL, EV_ABS, EV_MSC, EV_LED, EV_SND, EV_REP, EV_FF, EV_PWR, EV_FF_STATUS, EV_MAX
            if event.value == 0:  # Key release
                keycodeList.append(categorizedEvent.keycode)
            if "KEY_ENTER" in str(categorizedEvent.keycode) and event.value == 0:
                break

    return keycodeList


def extractDigitsFromKeycodes(keycodes: List[str]) -> List[int]:
    list_array_of_values: List[int] = []
    for keycode in keycodes:
        digits = "".join(filter(str.isdigit, str(keycode)))
        if digits:
            list_array_of_values.append(int(digits))
    return list_array_of_values


def buildString(list_array_of_values: List[int]) -> str:
    return "".join(str(value) for value in list_array_of_values)


if __name__ == "__main__":
    keycodes = asyncio.run(getKeycodeAsync())
    list_array_of_values = extractDigitsFromKeycodes(keycodes)
    print(list_array_of_values)
