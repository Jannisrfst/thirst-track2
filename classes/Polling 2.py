import threading
from classes.PersistanceLayer import PersistanceLayer
from mail import Email


class Polling:
    """
    This class implements a polling mechanism that polls thhe database with the respective functrions
    """

    def __init__(self, email: Email, count: int = 5) -> None:
        """
        Initialize the Polling instance.

        Args:
            email: An instance of the Email class to send notifications.
            count: The threshold for low stock alert (default: 5)
        """
        self.email = email
        self.count = count

        self.pl = PersistanceLayer("0", 1)

    def pollingLoop(self) -> None:
        """
        This function runs a polling loop that checks for stock <= 5 once seconds.
        It can be used to simulate a long-running process that checks for a condition.
        """
        # checking condition for the sqlite database
        inventory = self.pl.getInventory()
        if inventory:
            # check if sqlite count of one of the barcodes is <= self.count
            for item in inventory:
                if item["count"] <= self.count:
                    print(
                        f"Low stock alert for barcode {item['barcode']}: {item['count']} left."
                    )
                    # here will be the invokation of send_email function of the Email class
                    message = f"Subject: Low Stock Alert\n\nLow stock alert for barcode {item['barcode']}: Only {item['count']} items left in stock."
                    self.email.send_email(message)

    def start_polling_thread(self):
        """Start the polling loop in a background daemon thread."""
        thread = threading.Thread(target=self.pollingLoop)
        thread.daemon = True
        thread.start()
        return thread


def run_polling(email_instance: Email):
    """Global function to run polling check - used by PersistanceLayer."""
    polling = Polling(email_instance)
    polling.pollingLoop()
