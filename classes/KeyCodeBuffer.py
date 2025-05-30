import asyncio
from typing import List

class KeyCodeBuffer:
    def __init__(self) -> None:
        """
        Initialize a KeyCodeBuffer instance.
        
        This class is used to buffer keycodes from input devices.
        """
        self._keycodes: List[str] = []
        self._event = asyncio.Event()
    
    def addKeycode(self, keycode: str) -> None:
        """
        Add a keycode to the buffer.
        
        Args:
            keycode: The keycode string to add
        """
        self._keycodes.append(keycode)
    
    def clearKeycodes(self) -> None:
        """Clear all keycodes from the buffer."""
        self._keycodes.clear()
    
    def hasData(self) -> bool:
        """Check if there are any keycodes in the buffer."""
        return len(self._keycodes) > 0
    
    def getKeycodes(self) -> List[str]:
        """Get the current list of buffered keycodes."""
        return self._keycodes