from typing import Optional

class Barcodescanner:
    def __init__(self, mac_adress: str, connected: bool, bezeichnung: str, 
                 fw_version: Optional[str] = None) -> None:
        """
        Initialize a Barcodescanner instance.
        
        Args:
            mac_adress: The MAC address of the scanner
            connected: Whether the scanner is connected
            bezeichnung: Description/label of the scanner
            fw_version: Firmware version of the scanner (optional)
        """
        self._mac_address: str = mac_adress
        self._connected: bool = connected
        self._bezeichnung: str = bezeichnung
        self._fw_version: Optional[str] = fw_version
    
    @property
    def mac_address(self) -> str:
        """Get the scanner's MAC address."""
        return self._mac_address
    
    @property
    def connected(self) -> bool:
        """Check if the scanner is connected."""
        return self._connected
    
    @property
    def bezeichnung(self) -> str:
        """Get the scanner's description."""
        return self._bezeichnung
    
    @property
    def fw_version(self) -> Optional[str]:
        """Get the scanner's firmware version."""
        return self._fw_version
    
    @mac_address.setter
    def mac_address(self, value: str) -> None:
        """Set the scanner's MAC address."""
        self._mac_address = value
    
    @connected.setter
    def connected(self, value: bool) -> None:
        """Set the scanner's connection status."""
        self._connected = value
    
    @bezeichnung.setter
    def bezeichnung(self, value: str) -> None:
        """Set the scanner's description."""
        self._bezeichnung = value
    
    @fw_version.setter
    def fw_version(self, value: Optional[str]) -> None:
        """Set the scanner's firmware version."""
        self._fw_version = value
