#!/bin/bash

# USB Barcode Scanner Setup Script
# This script configures USB barcode scanner access and permissions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== USB Barcode Scanner Setup ===${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run with sudo privileges"
    exit 1
fi

# Install required packages for input device handling
print_status "Installing input device packages..."
apt update
apt install -y python3-evdev udev

# Add pi user to input group for device access
print_status "Adding pi user to input group..."
usermod -a -G input pi

# Create udev rules for barcode scanner
print_status "Creating udev rules for barcode scanner..."

cat > /etc/udev/rules.d/99-barcode-scanner.rules << 'EOF'
# Barcode Scanner udev rules
# This allows the pi user to access input devices

# Generic USB HID devices (most barcode scanners)
SUBSYSTEM=="input", GROUP="input", MODE="0664"
KERNEL=="event*", SUBSYSTEM=="input", GROUP="input", MODE="0664"

# Specific barcode scanner vendors (add more as needed)
# Honeywell scanners
ATTRS{idVendor}=="0c2e", SUBSYSTEM=="input", GROUP="input", MODE="0664", TAG+="uaccess"

# Symbol/Zebra scanners
ATTRS{idVendor}=="05e0", SUBSYSTEM=="input", GROUP="input", MODE="0664", TAG+="uaccess"

# Datalogic scanners
ATTRS{idVendor}=="05f9", SUBSYSTEM=="input", GROUP="input", MODE="0664", TAG+="uaccess"

# Code scanners
ATTRS{idVendor}=="1eab", SUBSYSTEM=="input", GROUP="input", MODE="0664", TAG+="uaccess"

# Generic USB keyboard-like devices (many scanners emulate keyboards)
ATTRS{bInterfaceClass}=="03", ATTRS{bInterfaceSubClass}=="01", ATTRS{bInterfaceProtocol}=="01", GROUP="input", MODE="0664", TAG+="uaccess"
EOF

# Reload udev rules
print_status "Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger

# Create scanner detection script
print_status "Creating scanner detection script..."

cat > /home/pi/thirst-track2/deployment/scripts/detect-scanner.sh << 'EOF'
#!/bin/bash

# Barcode Scanner Detection Script
# This script helps identify connected barcode scanners

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Barcode Scanner Detection ===${NC}"
echo ""

# Check for input devices
echo -e "${YELLOW}Available input devices:${NC}"
if ls /dev/input/event* > /dev/null 2>&1; then
    for device in /dev/input/event*; do
        if [ -r "$device" ]; then
            echo -e "  ${GREEN}✓${NC} $device (readable)"
        else
            echo -e "  ${RED}✗${NC} $device (not readable)"
        fi
    done
else
    echo "  No input devices found"
fi

echo ""

# Check USB devices
echo -e "${YELLOW}USB devices:${NC}"
if command -v lsusb > /dev/null; then
    lsusb | while read line; do
        # Check for common barcode scanner keywords
        if echo "$line" | grep -i -E "(scanner|barcode|honeywell|symbol|zebra|datalogic|code)" > /dev/null; then
            echo -e "  ${GREEN}Scanner detected:${NC} $line"
        else
            echo "  $line"
        fi
    done
else
    echo "  lsusb not available"
fi

echo ""

# Check input device details
echo -e "${YELLOW}Input device details:${NC}"
if command -v python3 > /dev/null; then
    python3 << 'PYTHON_EOF'
import evdev
import os

try:
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    
    if not devices:
        print("  No input devices found")
    else:
        for device in devices:
            print(f"  Device: {device.path}")
            print(f"    Name: {device.name}")
            print(f"    Vendor: {hex(device.info.vendor) if device.info.vendor else 'Unknown'}")
            print(f"    Product: {hex(device.info.product) if device.info.product else 'Unknown'}")
            
            # Check if device has key capabilities (like a keyboard/scanner)
            caps = device.capabilities()
            if evdev.ecodes.EV_KEY in caps:
                print(f"    Type: Keyboard-like device (likely scanner)")
            else:
                print(f"    Type: Other input device")
            
            # Check permissions
            try:
                with open(device.path, 'rb'):
                    print(f"    Access: ✓ Readable by current user")
            except PermissionError:
                print(f"    Access: ✗ Permission denied")
            except:
                print(f"    Access: ? Unknown")
            
            print()

except ImportError:
    print("  python3-evdev not installed")
except Exception as e:
    print(f"  Error: {e}")
PYTHON_EOF
else
    echo "  Python3 not available"
fi

echo ""

# Test scanner functionality
echo -e "${YELLOW}Scanner test:${NC}"
echo "To test your barcode scanner:"
echo "1. Make sure it's plugged in and powered on"
echo "2. Run: python3 /home/pi/thirst-track2/deployment/scripts/test-scanner.py"
echo "3. Scan a barcode when prompted"
echo ""

# Show current configuration
echo -e "${YELLOW}Current configuration:${NC}"
if [ -f "/home/pi/thirst-track2/.env" ]; then
    SCANNER_DEVICE=$(grep SCANNER_DEVICE_PATH /home/pi/thirst-track2/.env | cut -d'=' -f2)
    echo "  Configured device: $SCANNER_DEVICE"
    
    if [ -e "$SCANNER_DEVICE" ]; then
        echo -e "  Device status: ${GREEN}✓ Available${NC}"
    else
        echo -e "  Device status: ${RED}✗ Not found${NC}"
    fi
else
    echo "  No configuration file found"
fi
EOF

chmod +x /home/pi/thirst-track2/deployment/scripts/detect-scanner.sh

# Create scanner test script
print_status "Creating scanner test script..."

cat > /home/pi/thirst-track2/deployment/scripts/test-scanner.py << 'EOF'
#!/usr/bin/env python3

"""
Barcode Scanner Test Script
This script tests barcode scanner functionality
"""

import evdev
import sys
import time
import select
from typing import Optional

def find_scanner_device() -> Optional[str]:
    """Find the most likely barcode scanner device"""
    devices = evdev.list_devices()
    
    for device_path in devices:
        try:
            device = evdev.InputDevice(device_path)
            
            # Check if device has keyboard capabilities
            caps = device.capabilities()
            if evdev.ecodes.EV_KEY in caps:
                # Check if it's likely a scanner (has number keys)
                keys = caps[evdev.ecodes.EV_KEY]
                number_keys = [evdev.ecodes.KEY_0, evdev.ecodes.KEY_1, evdev.ecodes.KEY_2]
                
                if any(key in keys for key in number_keys):
                    print(f"Found potential scanner: {device.name} ({device_path})")
                    return device_path
                    
        except (OSError, PermissionError):
            continue
    
    return None

def test_scanner(device_path: str = None):
    """Test barcode scanner input"""
    
    if not device_path:
        device_path = find_scanner_device()
        
    if not device_path:
        print("No suitable input device found!")
        print("Available devices:")
        for path in evdev.list_devices():
            try:
                device = evdev.InputDevice(path)
                print(f"  {path}: {device.name}")
            except:
                pass
        return False
    
    try:
        device = evdev.InputDevice(device_path)
        print(f"Testing scanner: {device.name}")
        print(f"Device path: {device_path}")
        print("\nPlease scan a barcode (press Ctrl+C to exit)...")
        print("Waiting for input...\n")
        
        scanned_data = ""
        
        for event in device.read_loop():
            if event.type == evdev.ecodes.EV_KEY:
                key_event = evdev.categorize(event)
                
                if key_event.keystate == evdev.KeyEvent.key_down:
                    key_code = key_event.keycode
                    
                    # Handle number keys
                    if key_code.startswith('KEY_') and key_code[4:].isdigit():
                        digit = key_code[4:]
                        scanned_data += digit
                        print(f"Scanned digit: {digit}")
                    
                    # Handle Enter key (end of barcode)
                    elif key_code == 'KEY_ENTER':
                        if scanned_data:
                            print(f"\n✓ Complete barcode scanned: {scanned_data}")
                            print(f"Length: {len(scanned_data)} characters")
                            
                            # Test with application
                            print("\nTesting with application...")
                            test_with_app(scanned_data)
                            
                            scanned_data = ""
                            print("\nReady for next scan...")
                        else:
                            print("Enter pressed but no data scanned")
                    
                    # Handle other keys
                    elif key_code in ['KEY_LEFTSHIFT', 'KEY_RIGHTSHIFT']:
                        pass  # Ignore shift keys
                    else:
                        print(f"Other key: {key_code}")
        
    except PermissionError:
        print(f"Permission denied accessing {device_path}")
        print("Try running with sudo or check udev rules")
        return False
    except KeyboardInterrupt:
        print("\nTest interrupted by user")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_with_app(barcode: str):
    """Test barcode with the application"""
    try:
        import requests
        
        # Test API endpoint
        url = "http://localhost:5001/api/decrement"
        data = {"barcode": barcode, "quantity": 1}
        
        response = requests.post(url, json=data, timeout=5)
        
        if response.status_code == 200:
            print("✓ Successfully sent to application")
        else:
            print(f"✗ Application returned error: {response.status_code}")
            
    except ImportError:
        print("requests module not available for app testing")
    except Exception as e:
        print(f"✗ Error testing with application: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        device_path = sys.argv[1]
    else:
        device_path = None
    
    test_scanner(device_path)
EOF

chmod +x /home/pi/thirst-track2/deployment/scripts/test-scanner.py

# Create scanner configuration helper
print_status "Creating scanner configuration helper..."

cat > /home/pi/thirst-track2/deployment/scripts/configure-scanner.sh << 'EOF'
#!/bin/bash

# Scanner Configuration Helper
# This script helps configure the barcode scanner device path

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Scanner Configuration Helper ===${NC}"
echo ""

# Detect available devices
echo -e "${YELLOW}Detecting input devices...${NC}"
./deployment/scripts/detect-scanner.sh

echo ""
echo -e "${YELLOW}Configuration:${NC}"

# Get current configuration
if [ -f ".env" ]; then
    CURRENT_DEVICE=$(grep SCANNER_DEVICE_PATH .env | cut -d'=' -f2)
    echo "Current device: $CURRENT_DEVICE"
else
    echo "No configuration file found"
    CURRENT_DEVICE="/dev/input/event0"
fi

echo ""
echo "Available event devices:"
ls -la /dev/input/event* 2>/dev/null | while read line; do
    echo "  $line"
done

echo ""
read -p "Enter scanner device path (or press Enter for $CURRENT_DEVICE): " NEW_DEVICE

if [ -z "$NEW_DEVICE" ]; then
    NEW_DEVICE="$CURRENT_DEVICE"
fi

# Update configuration
if [ -f ".env" ]; then
    sed -i "s|SCANNER_DEVICE_PATH=.*|SCANNER_DEVICE_PATH=$NEW_DEVICE|" .env
    echo "Updated .env file with device: $NEW_DEVICE"
else
    echo "SCANNER_DEVICE_PATH=$NEW_DEVICE" >> .env
    echo "Created .env file with device: $NEW_DEVICE"
fi

echo ""
echo "Testing scanner with new configuration..."
python3 deployment/scripts/test-scanner.py "$NEW_DEVICE"
EOF

chmod +x /home/pi/thirst-track2/deployment/scripts/configure-scanner.sh

# Set proper ownership
chown -R pi:pi /home/pi/thirst-track2/deployment/scripts/

print_status "USB barcode scanner setup completed!"
echo ""
echo -e "${YELLOW}Scanner Setup Summary:${NC}"
echo "✓ Input device permissions configured"
echo "✓ udev rules created for scanner access"
echo "✓ Scanner detection script created"
echo "✓ Scanner test script created"
echo "✓ Configuration helper created"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Connect your USB barcode scanner"
echo "2. Run: /home/pi/thirst-track2/deployment/scripts/detect-scanner.sh"
echo "3. Test scanner: /home/pi/thirst-track2/deployment/scripts/test-scanner.py"
echo "4. Configure device: /home/pi/thirst-track2/deployment/scripts/configure-scanner.sh"
echo ""
echo -e "${YELLOW}Note:${NC} You may need to reboot for udev rules to take full effect"
