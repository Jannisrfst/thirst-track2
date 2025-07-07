import smtplib
from classes.PersistanceLayer import PersistanceLayer
from typing import List, Dict


class Email:
    def __init__(
        self, host: str, port: int, from_email: str, to_email: str, password: str
    ):
        self._host = "smtp.gmail.com"
        self._port = 587
        self._from_email = "jannis.reufsteck1@gmail.com"
        self._to_email = "jannis.reufsteck1@gmail.com"
        self._password = "trnb etzz kexu vvay"

    def get_inventory(self) -> List[Dict[str, int]]:
        """
        Retrieve the current inventory from the database.
        Returns: List of Dictionaires with barcode and count

        """
        persistance = PersistanceLayer(
            "", 0
        )  # Empty barcode and 0 amount for inventory retrieval
        return persistance.getInventory()

    def create_email(self) -> str:
        """
        Send an email with the current inventory.
        """
        inventory = self.get_inventory()
        if not inventory:
            print("No inventory data available.")
            return "no data available"

        message = "Current Inventory:\n"
        for item in inventory:
            message += f"Barcode: {item['barcode']}, Count: {item['count']}\n"

        return message

    def send_email(self, message):
        server = smtplib.SMTP(self._host, self._port)
        server.starttls()
        server.login(self._from_email, self._password)
        server.sendmail(self._from_email, self._to_email, message)
        server.quit()
