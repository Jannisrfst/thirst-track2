import requests
from typing import Optional, List, Dict, Any
import psycopg2


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
        self._db_path: str = "thirst-track"
        self._host: str = "192.168.1.208"
        self._user: str = "postgres"
        self._password: str = "2437"
        self._port: str = "5432"

    def _getConnection(self) -> psycopg2.extensions.connection:
        """Get the connection object to Postgresql"""
        return psycopg2.connect(
            database=self._db_path,
            user=self._user,
            password=self._password,
            host=self._host,
            port=self._port,
        )

    def addToSql(self, email_instance=None) -> None:
        """Add the barcode to the database."""
        con = self._getConnection()
        cur = con.cursor()
        cur.execute("INSERT INTO entries (barcode) VALUES(%s)", (self._barcode,))
        con.commit()

        if email_instance:
            self._trigger_polling(email_instance)

    def decrementFromSql(self, email_instance=None) -> None:
        """Decrement the count of this barcode in the database."""
        con = self._getConnection()
        cur = con.cursor()

        cur.execute("SELECT COUNT(*) FROM entries WHERE barcode = %s", (self._barcode,))
        current_count = cur.fetchone()[0]

        if current_count < self._amount:
            raise ValueError(
                f"Cannot decrement {self._amount} items. Only {current_count} available."
            )

        # Delete the specified number of entries using rowid
        cur.execute(
            """
            DELETE FROM entries WHERE id IN (
                SELECT id FROM entries WHERE barcode= %s LIMIT %s
            )
        """,
            (self._barcode, self._amount),
        )
        con.commit()

        if email_instance:
            self._trigger_polling(email_instance)

    def _trigger_polling(self, email_instance) -> None:
        """Trigger polling check after database changes."""
        from classes.Polling import run_polling

        run_polling(email_instance)

    def getInventory(self) -> List[Dict[str, Any]]:
        """Retrieve the current inventory with barcode counts.

        Returns:
            List[Dict[str, Any]]: A list of dicts with barcode and count
        """
        con = None
        try:
            con = self._getConnection()
            cur = con.cursor()

            # Get count of each barcode
            cur.execute("""
                SELECT barcode, COUNT(*) as count
                FROM entries
                GROUP BY barcode
                ORDER BY count DESC
            """)
            result = cur.fetchall()

            # Convert to list of dicts
            return [{"barcode": row[0], "count": row[1]} for row in result]
        except Exception as e:
            # Log the error if needed
            print(f"Error retrieving inventory: {str(e)}")
            raise
        finally:
            if con:
                con.close()

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
        url = (
            f"https://world.openfoodfacts.net/api/v2/product/"
            f"{self.barcode}?field=quantity"
        )
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            return data.get("product", {}).get("quantity", None)
        return None
