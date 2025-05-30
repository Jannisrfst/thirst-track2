from typing import List
from classes.Bottle import Bottle

class Fridge:
    def __init__(self, content: List[Bottle], volume: int) -> None:
        """
        Initialize a Fridge instance.
        
        Args:
            content: List of Bottle objects in the fridge
            volume: Number of bottles that can fit in the fridge
        """
        self._content: List[Bottle] = content
        self._volume: int = volume
        
    @property
    def content(self) -> List[Bottle]:
        """Get the list of bottles in the fridge."""
        return self._content
    
    @content.setter
    def content(self, content: List[Bottle]) -> None:
        """Set the list of bottles in the fridge."""
        self._content = content
    
    @property
    def volume(self) -> int:
        """Get the maximum number of bottles the fridge can hold."""
        return self._volume
    
    @volume.setter
    def volume(self, volume: int) -> None:
        """Set the maximum number of bottles the fridge can hold."""
        self._volume = volume
    
    def add_bottle(self, bottle: Bottle) -> None:
        """
        Add a bottle to the fridge.
        
        Args:
            bottle: The bottle to add
        
        Raises:
            ValueError: If the fridge is full
        """
        if len(self._content) >= self._volume:
            raise ValueError("Fridge is full")
        self._content.append(bottle)
