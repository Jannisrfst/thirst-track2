from flask import Flask, jsonify, Blueprint, request
from flask_cors import CORS
from edev import releaseDeviceAsync
from classes.PersistanceLayer import PersistanceLayer
from classes.User import User
import threading
import atexit
import asyncio
from typing import Optional
from mail import Email
import requests
import json

app = Flask(__name__)

# Enable CORS, important to change after development
CORS(app, supports_credentials=True, origins="*", allow_headers=["Content-Type"])

# Blueprint api routing /api
api_bp = Blueprint("api", __name__, url_prefix="/api")
email = Email(
    host="smtp.gmail.com",
    port=587,
    from_email="jannis.reufsteck1@gmail.com",
    to_email="jannis.reufsteck1@gmail.com",
    password="cijy tpmv wigq yplb",
)


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
            persistance.addToSql(email)

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


@api_bp.route("/decrement", methods=["POST"])
def decrement_entries():
    try:
        data = request.get_json()
        barcode = data.get("barcode")
        quantity = data.get("quantity", 1)  # Default to 1 if not provided

        if barcode is None:
            return jsonify({"status": "error", "message": "Barcode is required"}), 400

        # Create a PersistanceLayer instance
        persistance = PersistanceLayer(barcode, int(quantity))

        # Decrement the specified quantity
        persistance.decrementFromSql(email)

        return jsonify(
            {
                "status": "success",
                "message": f"Decremented {quantity} entries with barcode {barcode}",
            }
        ), 200
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


async def scannerProcessing() -> None:
    user = User(1)
    print("Scanner processing started automatically...")

    while True:
        try:
            persistenceObj: Optional[PersistanceLayer] = await user.scanAsync()
            if persistenceObj and persistenceObj.barcode:
                # Use API endpoint for consistency with web UI
                await makeDecrementApiCall(persistenceObj.barcode, 1)
                print(f"Scanned and decremented via API: {persistenceObj.barcode}")
        except Exception as e:
            print(f"Scanner error: {e}")
            await asyncio.sleep(1)


async def makeDecrementApiCall(barcode: str, quantity: int) -> None:
    """Make HTTP POST request to /api/decrement endpoint"""
    try:
        payload = {"barcode": barcode, "quantity": quantity}

        response = requests.post(
            "http://localhost:5001/api/decrement",
            headers={"Content-Type": "application/json"},
            json=payload,
            timeout=5,
        )

        if response.status_code == 200:
            result = response.json()
            print(f"API decrement success: {result.get('message', 'Unknown response')}")
        else:
            print(f"API decrement failed: {response.status_code} - {response.text}")

    except requests.exceptions.RequestException as e:
        print(f"API request error: {e}")
    except Exception as e:
        print(f"Unexpected error in API call: {e}")


async def mainAsyncLoop() -> None:
    # Start scanner processing task only
    scanner_task = asyncio.create_task(scannerProcessing())

    # Wait for scanner task
    await scanner_task


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
    persistance.decrementFromSql(email)


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
