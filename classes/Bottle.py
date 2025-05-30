from classes.MaterialType import MaterialType
from classes.PersistanceLayer import PersistanceLayer
import re
from typing import Optional

class Bottle:
    def __init__(self, barcode: PersistanceLayer, volume: Optional[int] = None, 
                 material: Optional[MaterialType] = None) -> None:
        """
        Initialize a Bottle instance.
        
        Args:
            barcode: The PersistanceLayer instance containing the barcode
            volume: The volume of the bottle in milliliters (optional)
            material: The material type of the bottle (optional)
        """
        self._barcode: PersistanceLayer = barcode
        self._volume: int = 500  # Default volume
        self._material: MaterialType = MaterialType.GLAS  # Default material

        if volume is None:
            api_volume = barcode.volume
            if api_volume:
                match = re.search(r'(\d+)', api_volume)
                if match:
                    self._volume = int(match.group(1))
        else:
            self._volume = volume

        if material is not None:
            self._material = material
        else:
            # Use default material if none provided
            self._material = MaterialType.GLAS

    @property  
    def volume(self) -> int:
        """Get the bottle's volume in milliliters."""
        return self._volume
    
    @volume.setter
    def volume(self, volume: int) -> None:
        """Set the bottle's volume."""
        self._volume = volume
      
    @property  
    def barcode(self) -> PersistanceLayer:
        """Get the bottle's barcode."""
        return self._barcode
    
    @barcode.setter
    def barcode(self, barcode: PersistanceLayer) -> None:
        """Set the bottle's barcode."""
        self._barcode = barcode
    
    @property   
    def material(self) -> MaterialType:
        """Get the bottle's material type."""
        return self._material
    
    @material.setter
    def material(self, material: MaterialType) -> None:
        """Set the bottle's material type."""
        if material in MaterialType.__members__.values():
            self._material = material 
        else:
            raise ValueError(f"Invalid material type: {material}")