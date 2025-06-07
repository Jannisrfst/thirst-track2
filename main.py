from flask import Flask, jsonify, Blueprint, request
from flask_cors import CORS
from edev import getKeycodeAsync, extractDigitsFromKeycodes, releaseDeviceAsync
from queue import Queue
from classes.PersistanceLayer import PersistanceLayer
from classes.MaterialType import MaterialType
from classes.Bottle import Bottle
from classes.User import User
import threading
import atexit
import asyncio
from typing import Optional, List, Dict, Any
from mail import Email

app = Flask(__name__)

# Configure CORS to allow all origins during development
CORS(app, supports_credentials=True, origins="*", allow_headers=["Content-Type"])

# Create a Blueprint for API routes
api_bp = Blueprint("api", __name__, url_prefix="/api")


@api_bp.route("/add", methods=["POST"])
def add_entries():
    try:
        data = request.get_json()
        barcode = data.get("barcode")
        quantity = data.get("quantity")

        if barcode is None or quantity is None:
            return jsonify(
                {"status": "error", "message": "Barcode and quantity required"}
            ), 400

        # Create a PersistanceLayer instance
        persistance = PersistanceLayer(barcode, int(quantity))

        # Insert 'quantity' rows
        for i in range(int(quantity)):
            persistance.addToSql()

        return jsonify(
            {
                "status": "success",
                "message": f"Added {quantity} entries with barcode {barcode}",
            }
        ), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@api_bp.route("/entries")
def inventory():
    try:
        # Using a generic PersistanceLayer instance to retrieve inventory data
        persistance = PersistanceLayer(
            "", 0
        )  # Empty barcode and 0 amount for inventory retrieval
        result = persistance.getInventory()

        return jsonify({"status": "success", "data": result}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


# Register the Blueprint with the app
app.register_blueprint(api_bp)


# Print initial entries for debugging (using PersistanceLayer)
def print_initial_entries():
    try:
        persistance = PersistanceLayer("", 0)
        con = persistance._getConnection()
        cur = con.cursor()
        cur.execute("SELECT * FROM Entries")
        print(cur.fetchall())
        con.close()
    except Exception as e:
        print(f"Error printing initial entries: {e}")


# Execute initial query in thread-safe way
print_initial_entries()

# Flag to control scanner processing
scanner_running: bool = False


async def keyboardInputHandler() -> None:
    global scanner_running
    loop = asyncio.get_event_loop()

    command: str = ""

    while command.strip().lower() != "start":
        command = await loop.run_in_executor(None, input, "> ")

    print("\nStarting scanner processing...")
    scanner_running = True

    while True:
        command = await loop.run_in_executor(None, input, "Command> ")

        if command.lower() == "start":
            scanner_running = True
            print("Scanner started")


async def scannerProcessing() -> None:
    global scanner_running
    user = User(1)

    while True:
        if scanner_running:
            try:
                persistenceObj: Optional[PersistanceLayer] = await user.scanAsync()
                if persistenceObj and persistenceObj.barcode:
                    persistenceObj.decrementFromSql()
                    print(f"scanned asynchron {persistenceObj.barcode}")
            except Exception as e:
                print(f"Error {e}")
                await asyncio.sleep(1)
        else:
            await asyncio.sleep(0.1)


async def mainAsyncLoop() -> None:
    # Start both tasks
    keyboard_task = asyncio.create_task(keyboardInputHandler())
    scanner_task = asyncio.create_task(scannerProcessing())

    # Wait for both tasks
    await asyncio.gather(keyboard_task, scanner_task)


def asyncioLoop() -> None:
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(mainAsyncLoop())
    loop.close()


# Start the asyncio thread
asyncThread = threading.Thread(target=asyncioLoop, daemon=True)
asyncThread.start()


@atexit.register
def cleanup() -> None:
    # We need a synchronous version since atexit doesn't support async
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        loop.run_until_complete(releaseDeviceAsync())
    finally:
        loop.close()


def decrementByNumber(number: int) -> None:
    # Create a PersistanceLayer instance with the barcode number
    persistance = PersistanceLayer(str(number))
    persistance.decrementFromSql()


def send_mail():
    mail = Email(
        "smtp.gmail.com",
        587,
        "jannis.reufsteck1@gmail.com",
        "jannis.reufsteck1@gmail.com",
        "cijy tpmv wigq yplb",
    )
    mail.send_email(mail.create_email())


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5001)
