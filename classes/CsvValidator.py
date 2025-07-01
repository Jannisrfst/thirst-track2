import csv
from typing import List, Dict, Any, Tuple
from io import StringIO


class CsvValidator:
    def __init__(self) -> None:
        """Initialize CSV validator with validation rules."""
        self.max_barcode_length = 13
        self.required_columns = ["quantity", "barcode"]

    def validate_csv_content(
        self, csv_content: str
    ) -> Tuple[bool, List[Dict[str, Any]], List[str]]:
        """
        Validate CSV content against required format and rules.

        Args:
            csv_content: Raw CSV content as string

        Returns:
            Tuple containing:
            - bool: True if valid, False if invalid
            - List[Dict[str, Any]]: List of valid rows with quantity and barcode
            - List[str]: List of error messages
        """
        errors = []
        valid_rows = []

        try:
            csv_file = StringIO(csv_content.strip())
            reader = csv.DictReader(csv_file)

            # Check if required columns exist
            if not reader.fieldnames:
                errors.append("CSV file is empty or has no headers")
                return False, [], errors

            # Normalize column names (remove quotes and whitespace)
            normalized_fieldnames = [
                field.strip().strip("\"'") for field in reader.fieldnames
            ]

            # Check if required columns are present
            missing_columns = []
            for required_col in self.required_columns:
                if required_col not in normalized_fieldnames:
                    missing_columns.append(required_col)

            if missing_columns:
                errors.append(f"Missing required columns: {', '.join(missing_columns)}")
                return False, [], errors

            # Check for extra columns
            extra_columns = [
                col for col in normalized_fieldnames if col not in self.required_columns
            ]
            if extra_columns:
                errors.append(
                    f"Unexpected columns found: {', '.join(extra_columns)}. Only 'quantity' and 'barcode' are allowed."
                )
                return False, [], errors

            # Validate each row
            row_number = 1
            for row in reader:
                row_number += 1
                row_errors = []

                # Normalize row keys
                normalized_row = {}
                for key, value in row.items():
                    normalized_key = key.strip().strip("\"'")
                    normalized_row[normalized_key] = value.strip() if value else ""

                # Validate quantity
                quantity_str = normalized_row.get("quantity", "")
                if not quantity_str:
                    row_errors.append(f"Row {row_number}: quantity is required")
                else:
                    try:
                        quantity = int(quantity_str)
                        if quantity <= 0:
                            row_errors.append(
                                f"Row {row_number}: quantity must be greater than 0"
                            )
                    except ValueError:
                        row_errors.append(
                            f"Row {row_number}: quantity must be a valid integer"
                        )

                # Validate barcode
                barcode = normalized_row.get("barcode", "")
                if not barcode:
                    row_errors.append(f"Row {row_number}: barcode is required")
                elif len(barcode) > self.max_barcode_length:
                    row_errors.append(
                        f"Row {row_number}: barcode cannot be longer than {self.max_barcode_length} characters"
                    )

                # If row has errors, add them to the main error list
                if row_errors:
                    errors.extend(row_errors)
                else:
                    # Row is valid, add to valid_rows
                    valid_rows.append(
                        {"quantity": int(quantity_str), "barcode": barcode}
                    )

            # Check if we have any valid rows
            if not valid_rows and not errors:
                errors.append("CSV file contains no data rows")

            return len(errors) == 0, valid_rows, errors

        except csv.Error as e:
            errors.append(f"CSV parsing error: {str(e)}")
            return False, [], errors
        except Exception as e:
            errors.append(f"Unexpected error during validation: {str(e)}")
            return False, [], errors
