import sqlite3
import requests
from typing import Optional

class PersistanceLayer:
    def __init__(self, barcode: str, amount: int = 1) -> None:
        """
        Initialize a PersistanceLayer instance.
        
        Args:
            barcode: The barcode string to track
            amount: The number of items with this barcode (default: 1)
        """
        self._barcode: str = barcode
        self._amount: int = amount
        self._db_path: str = '/home/jannisreufsteck/thirst-track/getraenke.sqlite3'
                
    def _getConnection(self) -> sqlite3.Connection:
        """Get a connection to the SQLite database."""
        return sqlite3.connect(self._db_path)

    def addToSql(self) -> None:
        """Add the barcode to the database."""
        con = self._getConnection()
        cur = con.cursor()
        cur.execute("INSERT INTO Entries (number) VALUES(?)", (self._barcode,))
        con.commit()
    
    def decrementFromSql(self) -> None:
        """Decrement the count of this barcode in the database."""
        con = self._getConnection()
        cur = con.cursor()
        cur.execute("DELETE FROM Entries WHERE number = ? LIMIT ?", (self._barcode, self._amount))
        con.commit()

    @property
    def amount(self) -> int:
        """Get the current amount."""
        return self._amount
    
    @amount.setter
    def amount(self, value: int) -> None:
        """Set the amount."""
        self._amount = value
    
    @property
    def barcode(self) -> str:
        """Get the barcode."""
        return self._barcode
    
    @barcode.setter
    def barcode(self, barcode: str) -> None:
        """Set the barcode."""
        self._barcode = barcode
    
    @property
    def volume(self) -> Optional[str]:
        """
        Get the volume information from OpenFoodFacts API.
        
        Returns:
            Optional[str]: The volume information if available, None otherwise
        """
        response = requests.get(f"https://world.openfoodfacts.net/api/v2/product/{self.barcode}?field=quantity")
        if response.status_code == 200:
            data = response.json()
            return data.get('product', {}).get('quantity', None)
        return None