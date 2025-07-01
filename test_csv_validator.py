#!/usr/bin/env python3
"""
Comprehensive test suite for CSV validator functionality
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend', 'classes'))

from CsvValidator import CsvValidator

def test_valid_csv():
    """Test CSV validator with valid data"""
    print("=== Testing CSV Validator with Valid Data ===")
    
    validator = CsvValidator()
    
    # Test 1: Basic valid CSV
    csv_content = """barcode,quantity
123456789,5
987654321,3
111222333,10"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"Valid CSV Test:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == True, "Valid CSV should pass validation"
    assert len(valid_rows) == 3, "Should have 3 valid rows"
    assert len(errors) == 0, "Should have no errors"
    
    # Test 2: CSV with quoted fields
    csv_content_quoted = '"barcode","quantity"\n"123456789","5"\n"987654321","3"'
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content_quoted)
    
    print(f"\nQuoted CSV Test:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == True, "Quoted CSV should pass validation"
    assert len(valid_rows) == 2, "Should have 2 valid rows"
    
    print("✓ Valid CSV tests passed!")
    return True

def test_missing_columns():
    """Test CSV validator with missing required columns"""
    print("\n=== Testing CSV Validator with Missing Columns ===")
    
    validator = CsvValidator()
    
    # Test 1: Missing barcode column
    csv_content = """quantity,description
5,Some item
3,Another item"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"Missing barcode column:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "CSV missing barcode should fail"
    assert "barcode" in str(errors), "Error should mention missing barcode"
    
    # Test 2: Missing quantity column
    csv_content = """barcode,description
123456789,Some item
987654321,Another item"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"\nMissing quantity column:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "CSV missing quantity should fail"
    assert "quantity" in str(errors), "Error should mention missing quantity"
    
    # Test 3: Extra columns
    csv_content = """barcode,quantity,description
123456789,5,Some item
987654321,3,Another item"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"\nExtra columns:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "CSV with extra columns should fail"
    assert "Unexpected columns" in str(errors), "Error should mention unexpected columns"
    
    print("✓ Missing columns tests passed!")
    return True

def test_invalid_quantities():
    """Test CSV validator with invalid quantity values"""
    print("\n=== Testing CSV Validator with Invalid Quantities ===")
    
    validator = CsvValidator()
    
    # Test 1: Non-numeric quantity
    csv_content = """barcode,quantity
123456789,abc
987654321,3"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"Non-numeric quantity:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "Non-numeric quantity should fail"
    assert "valid integer" in str(errors), "Error should mention valid integer"
    
    # Test 2: Zero quantity
    csv_content = """barcode,quantity
123456789,0
987654321,3"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"\nZero quantity:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "Zero quantity should fail"
    assert "greater than 0" in str(errors), "Error should mention greater than 0"
    
    # Test 3: Negative quantity
    csv_content = """barcode,quantity
123456789,-5
987654321,3"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"\nNegative quantity:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "Negative quantity should fail"
    assert "greater than 0" in str(errors), "Error should mention greater than 0"
    
    # Test 4: Empty quantity
    csv_content = """barcode,quantity
123456789,
987654321,3"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"\nEmpty quantity:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "Empty quantity should fail"
    assert "required" in str(errors), "Error should mention required"
    
    print("✓ Invalid quantities tests passed!")
    return True

def test_invalid_barcodes():
    """Test CSV validator with invalid barcode values"""
    print("\n=== Testing CSV Validator with Invalid Barcodes ===")
    
    validator = CsvValidator()
    
    # Test 1: Empty barcode
    csv_content = """barcode,quantity
,5
987654321,3"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"Empty barcode:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "Empty barcode should fail"
    assert "barcode is required" in str(errors), "Error should mention barcode required"
    
    # Test 2: Too long barcode (>13 characters)
    csv_content = """barcode,quantity
12345678901234,5
987654321,3"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"\nToo long barcode:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "Too long barcode should fail"
    assert "cannot be longer than 13" in str(errors), "Error should mention length limit"
    
    # Test 3: Valid edge case - exactly 13 characters
    csv_content = """barcode,quantity
1234567890123,5
987654321,3"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"\n13-character barcode:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == True, "13-character barcode should pass"
    assert len(valid_rows) == 2, "Should have 2 valid rows"
    
    print("✓ Invalid barcodes tests passed!")
    return True

def test_edge_cases():
    """Test CSV validator with edge cases"""
    print("\n=== Testing CSV Validator with Edge Cases ===")
    
    validator = CsvValidator()
    
    # Test 1: Empty CSV
    csv_content = ""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"Empty CSV:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "Empty CSV should fail"
    
    # Test 2: Headers only
    csv_content = "barcode,quantity"
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"\nHeaders only:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == False, "Headers only should fail"
    assert "no data rows" in str(errors), "Error should mention no data rows"
    
    # Test 3: Whitespace in values
    csv_content = """barcode,quantity
  123456789  ,  5  
987654321,3"""
    
    is_valid, valid_rows, errors = validator.validate_csv_content(csv_content)
    
    print(f"\nWhitespace in values:")
    print(f"  Is Valid: {is_valid}")
    print(f"  Valid Rows: {valid_rows}")
    print(f"  Errors: {errors}")
    
    assert is_valid == True, "Whitespace should be trimmed"
    assert valid_rows[0]['barcode'] == '123456789', "Barcode should be trimmed"
    assert valid_rows[0]['quantity'] == 5, "Quantity should be parsed correctly"
    
    print("✓ Edge cases tests passed!")
    return True

def main():
    """Run all CSV validator tests"""
    print("Starting comprehensive CSV validator tests...")
    
    try:
        test_valid_csv()
        test_missing_columns()
        test_invalid_quantities()
        test_invalid_barcodes()
        test_edge_cases()
        
        print("\n🎉 All CSV validator tests passed successfully!")
        return True
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)