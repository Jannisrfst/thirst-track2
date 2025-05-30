# MOCKED barcode scanning logic for API development on macOS.
# No hardware or evdev dependencies. All functions return safe dummy values.
import asyncio
from typing import List

async def initializeDeviceAsync():
    # No-op for mac
    return None

async def releaseDeviceAsync() -> None:
    # No-op for mac
    pass

async def getKeycodeAsync() -> List[str]:
    # Return a dummy barcode sequence for development
    return ["KEY_1", "KEY_2", "KEY_3", "KEY_ENTER"]

def extractDigitsFromKeycodes(keycodes: List[str]) -> List[int]:
    list_array_of_values: List[int] = []
    for keycode in keycodes:
        digits = ''.join(filter(str.isdigit, str(keycode)))
        if digits:
            list_array_of_values.append(int(digits))
    return list_array_of_values


def buildString(list_array_of_values: List[int]) -> str:
    return ''.join(str(value) for value in list_array_of_values)

if __name__ == "__main__":
    keycodes = asyncio.run(getKeycodeAsync())
    list_array_of_values = extractDigitsFromKeycodes(keycodes)
    print(list_array_of_values)

