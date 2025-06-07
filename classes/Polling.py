import threading
import time
from PersistanceLayer import PersistanceLayer
from mail import Email

pl = PersistanceLayer("0", 1)

# Create Email instance with the same configuration as jonas-email.py
email_service = Email(
    "smtp.gmail.com",
    587,
    "jannis.reufsteck1@gmail.com",
    "jonas.heck@abs-gmbh.de",
    "cijy tpmv wigq yplb",
)


def pollingLoop() -> None:
    """
    This function runs a polling loop that checks for stock <= 5 every 60 seconds.
    It can be used to simulate a long-running process that checks for a condition.
    """
    while True:
        # checking condition for the sqlite database
        inventory = pl.getInventory()
        if inventory:
            # check if sqlite count of one of the barcodes is <= 5
            for item in inventory:
                if item["count"] <= 5:
                    print(
                        f"Low stock alert for barcode {item['barcode']}: {item['count']} left."
                    )
                    # here will be the invokation of send_email function of the Email class
                    message = f"Subject: Low Stock Alert\n\nLow stock alert for barcode {item['barcode']}: Only {item['count']} items left in stock."
                    email_service.send_email(message)

        time.sleep(60)


thread = threading.Thread(target=pollingLoop)
thread.daemon = True
thread.start()
