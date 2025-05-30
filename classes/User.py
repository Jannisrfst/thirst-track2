from edev import extractDigitsFromKeycodes, buildString, getKeycodeAsync
from classes.PersistanceLayer import PersistanceLayer
from typing import Optional

class User:
    def __init__(self, id: int) -> None:
        """
        Initialize a User instance.
        
        Args:
            id: The user's unique identifier
        """
        self.id: int = id
        
    def scan(self) -> Optional[PersistanceLayer]:
        """
        Synchronously scan for barcode input.
        
        Returns:
            Optional[PersistanceLayer]: A PersistanceLayer instance with the scanned barcode,
            or None if no valid barcode was scanned
        """
        keycodes = getKeycodeAsync()
        list_array_of_values = extractDigitsFromKeycodes(keycodes)
        barcode_string = buildString(list_array_of_values)   
        # Only return a barcode object if we have an actual barcode
        if barcode_string.strip():  
            return PersistanceLayer(barcode_string)
        else:
            return None
        
    async def scanAsync(self) -> Optional[PersistanceLayer]:
        """
        Asynchronously scan for barcode input.
        
        Returns:
            Optional[PersistanceLayer]: A PersistanceLayer instance with the scanned barcode,
            or None if no valid barcode was scanned
        """
        print("scanning for inputs async")
        keycodes = await getKeycodeAsync()
        listArrayOfValues = extractDigitsFromKeycodes(keycodes)
        barcodeString = buildString(listArrayOfValues) 
        
        print("finished scanning for inputs async")  
        if len(barcodeString) == 0:  
            return PersistanceLayer(barcodeString)
        print("Leerer Barcode scanning again")
        return None
