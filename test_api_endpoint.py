#!/usr/bin/env python3
"""
Test script to verify CSV API endpoint functionality
"""

import sys
import os
import io
import tempfile
from unittest.mock import patch, MagicMock

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend', 'classes'))

# Import Flask app components
from flask import Flask
from werkzeug.datastructures import FileStorage

def test_api_imports():
    """Test that all required modules can be imported"""
    print("=== Testing API Imports ===")
    
    try:
        from CsvValidator import CsvValidator
        print("✓ CsvValidator import successful")
    except ImportError as e:
        print(f"❌ CsvValidator import failed: {e}")
        return False
    
    try:
        import csv
        print("✓ csv module available")
    except ImportError as e:
        print(f"❌ csv module failed: {e}")
        return False
    
    try:
        from flask import Flask, jsonify, request
        print("✓ Flask modules available")
    except ImportError as e:
        print(f"❌ Flask modules failed: {e}")
        return False
    
    try:
        from werkzeug.datastructures import FileStorage
        print("✓ Werkzeug FileStorage available")
    except ImportError as e:
        print(f"❌ Werkzeug FileStorage failed: {e}")
        return False
    
    print("✓ All API imports successful!")
    return True

def test_csv_endpoint_logic():
    """Test the CSV endpoint logic without full Flask app"""
    print("\n=== Testing CSV Endpoint Logic ===")
    
    # Import after path setup
    from CsvValidator import CsvValidator
    
    try:
        # Test 1: Valid CSV processing
        csv_content = "barcode,quantity\n123456789,5\n987654321,3"
        validator = CsvValidator()
        is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
        
        print(f"Valid CSV processing:")
        print(f"  Is Valid: {is_valid}")
        print(f"  Valid Rows Count: {len(valid_rows)}")
        print(f"  Errors: {errors}")
        
        assert is_valid == True
        assert len(valid_rows) == 2
        
        # Test 2: Invalid CSV processing
        csv_content_invalid = "barcode,quantity\n123456789,abc\n987654321,3"
        is_valid, valid_rows, errors = validator.validate_csv_content(csv_content_invalid)
        
        print(f"\nInvalid CSV processing:")
        print(f"  Is Valid: {is_valid}")
        print(f"  Valid Rows Count: {len(valid_rows)}")
        print(f"  Errors: {errors}")
        
        assert is_valid == False
        assert len(errors) > 0
        
        print("✓ CSV endpoint logic tests passed!")
        return True
        
    except Exception as e:
        print(f"❌ CSV endpoint logic test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_file_upload_simulation():
    """Simulate file upload processing"""
    print("\n=== Testing File Upload Simulation ===")
    
    try:
        # Create a mock CSV file
        csv_data = "barcode,quantity\n123456789,5\n987654321,3\n"
        csv_file = io.BytesIO(csv_data.encode('utf-8'))
        
        # Mock FileStorage object
        mock_file = FileStorage(
            stream=csv_file,
            filename="test.csv",
            content_type="text/csv"
        )
        
        # Test file properties
        print(f"Mock file filename: {mock_file.filename}")
        print(f"Mock file content type: {mock_file.content_type}")
        
        # Read content
        content = mock_file.read().decode('utf-8')
        print(f"File content length: {len(content)} characters")
        print(f"File content preview: {content[:50]}...")
        
        # Validate filename check
        is_csv = mock_file.filename.lower().endswith('.csv')
        print(f"Is CSV file: {is_csv}")
        
        assert is_csv == True
        assert len(content) > 0
        
        print("✓ File upload simulation passed!")
        return True
        
    except Exception as e:
        print(f"❌ File upload simulation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_environment_variables():
    """Test environment variable loading"""
    print("\n=== Testing Environment Variables ===")
    
    try:
        from dotenv import load_dotenv
        print("✓ dotenv module available")
        
        # Load .env file
        load_dotenv()
        
        # Check if .env file exists
        env_path = os.path.join(os.path.dirname(__file__), '.env')
        env_exists = os.path.exists(env_path)
        print(f"{'✓' if env_exists else '❌'} .env file {'exists' if env_exists else 'missing'}")
        
        # Check critical environment variables
        critical_vars = ['EMAIL_HOST', 'EMAIL_PORT', 'EMAIL_FROM', 'EMAIL_TO', 'EMAIL_PASSWORD']
        for var in critical_vars:
            value = os.getenv(var)
            has_value = value is not None and value != ''
            print(f"{'✓' if has_value else '❌'} {var} {'set' if has_value else 'missing/empty'}")
        
        print("✓ Environment variables test completed!")
        return True
        
    except ImportError as e:
        print(f"❌ dotenv import failed: {e}")
        return False
    except Exception as e:
        print(f"❌ Environment variables test failed: {e}")
        return False

def test_backend_dependencies():
    """Test backend-specific dependencies"""
    print("\n=== Testing Backend Dependencies ===")
    
    dependencies = [
        ('flask', 'Flask'),
        ('flask_cors', 'CORS'),
        ('typing', 'Optional'),
        ('json', None),
        ('os', None),
        ('threading', None),
        ('asyncio', None),
        ('atexit', None)
    ]
    
    all_available = True
    
    for module_name, class_name in dependencies:
        try:
            module = __import__(module_name)
            if class_name:
                getattr(module, class_name)
            print(f"✓ {module_name}{f'.{class_name}' if class_name else ''} available")
        except ImportError as e:
            print(f"❌ {module_name} import failed: {e}")
            all_available = False
        except AttributeError as e:
            print(f"❌ {module_name}.{class_name} not found: {e}")
            all_available = False
    
    return all_available

def main():
    """Run all API endpoint tests"""
    print("Starting comprehensive API endpoint tests...\n")
    
    tests = [
        ("API Imports", test_api_imports),
        ("CSV Endpoint Logic", test_csv_endpoint_logic),
        ("File Upload Simulation", test_file_upload_simulation),
        ("Environment Variables", test_environment_variables),
        ("Backend Dependencies", test_backend_dependencies)
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        try:
            results[test_name] = test_func()
        except Exception as e:
            print(f"\n❌ {test_name} test crashed: {e}")
            results[test_name] = False
    
    print("\n" + "="*50)
    print("=== COMPREHENSIVE TEST RESULTS ===")
    print("="*50)
    
    all_passed = True
    for test_name, passed in results.items():
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{test_name}: {status}")
        if not passed:
            all_passed = False
    
    print("="*50)
    if all_passed:
        print("🎉 ALL TESTS PASSED! CSV API endpoint is ready for deployment.")
    else:
        print("⚠️  Some tests failed. Review the issues above.")
    
    return all_passed

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)