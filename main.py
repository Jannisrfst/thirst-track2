from flask import Flask, jsonify, Blueprint, request
from flask_cors import CORS
from edev import getKeycodeAsync, extractDigitsFromKeycodes, releaseDeviceAsync
from queue import Queue
from classes.PersistanceLayer import PersistanceLayer
from classes.MaterialType import MaterialType
from classes.Bottle import Bottle
from classes.User import User
import threading
import sqlite3
import atexit
import time
import asyncio
from typing import Optional

app = Flask(__name__)

# Configure CORS to only allow requests from the React frontend
CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:3000"],  
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type"],
        "supports_credentials": True
    }
})

# Create a Blueprint for API routes
api_bp = Blueprint('api', __name__, url_prefix='/api')

@api_bp.route("/add", methods=["POST"])
def add_entries():
    try:
        data = request.get_json()
        barcode = data.get("barcode")
        quantity = data.get("quantity")

        if barcode is None or quantity is None:
            return jsonify({"status": "error", "message": "Barcode and quantity required"}), 400

        # Insert 'quantity' rows
        for i in range(int(quantity)):
            cur.execute("INSERT INTO Entries (number) VALUES(?)", (barcode,))
        con.commit()

        return jsonify({
            "status": "success",
            "message": f"Added {quantity} entries with barcode {barcode}"
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@api_bp.route("/entries")
def entries():
    try:
        cur.execute("SELECT * FROM Entries")
        return jsonify({
            "status": "success",
            "data": cur.fetchall()
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

# Register the Blueprint with the app
app.register_blueprint(api_bp)

con = sqlite3.connect('/home/jannisreufsteck/thirst-track/getraenke.sqlite3')
cur = con.cursor()
cur.execute("SELECT * FROM Entries")
print(cur.fetchall())

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
    cur.execute("DELETE FROM Entries WHERE number = ? LIMIT 1", (number,))
    con.commit()

if __name__ == "__main__":
    app.run(debug=True)
