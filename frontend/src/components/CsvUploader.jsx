"use client";
import React, { useState } from "react";
import { useBarcode } from "../context/BarcodeContext";
import "./CsvUploader.css";

export const CsvUploader = () => {
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [status, setStatus] = useState({ message: "", isError: false });
  const [results, setResults] = useState(null);
  const { refreshInventory } = useBarcode();

  const handleFileSelect = (e) => {
    const selectedFile = e.target.files[0];
    if (selectedFile) {
      if (!selectedFile.name.endsWith('.csv')) {
        setStatus({ message: "Please select a CSV file", isError: true });
        return;
      }
      setFile(selectedFile);
      setStatus({ message: "", isError: false });
      setResults(null);
    }
  };

  const handleUpload = async (e) => {
    e.preventDefault();
    
    if (!file) {
      setStatus({ message: "Please select a CSV file first", isError: true });
      return;
    }

    setUploading(true);
    setStatus({ message: "", isError: false });
    setResults(null);

    try {
      const formData = new FormData();
      formData.append('file', file);

      const response = await fetch('/api/add-csv', {
        method: 'POST',
        body: formData,
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.message || 'Upload failed');
      }

      // Success
      setStatus({ 
        message: result.message, 
        isError: false 
      });
      setResults(result);
      setFile(null);
      
      // Reset file input
      const fileInput = document.getElementById('csv-file-input');
      if (fileInput) fileInput.value = '';
      
      // Refresh inventory if available
      if (refreshInventory) {
        refreshInventory();
      }

    } catch (error) {
      setStatus({ message: error.message, isError: true });
      
      // Handle validation errors
      if (error.message.includes('CSV validation failed')) {
        try {
          const errorResponse = await error.response?.json();
          if (errorResponse?.errors) {
            setResults({ errors: errorResponse.errors });
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
    } finally {
      setUploading(false);
    }
  };

  const handleReset = () => {
    setFile(null);
    setStatus({ message: "", isError: false });
    setResults(null);
    const fileInput = document.getElementById('csv-file-input');
    if (fileInput) fileInput.value = '';
  };

  return (
    <section className="csv-uploader-section">
      <h2 className="csv-uploader-title">CSV Bulk Upload</h2>
      <form className="csv-uploader-form" onSubmit={handleUpload}>
        <div className="form-group">
          <label className="form-label">Select CSV File</label>
          <input
            id="csv-file-input"
            type="file"
            accept=".csv"
            className="form-input file-input"
            onChange={handleFileSelect}
            disabled={uploading}
          />
          <small className="file-hint">
            CSV format: columns "barcode" and "quantity" required
          </small>
        </div>

        {file && (
          <div className="file-info">
            <span className="file-name">{file.name}</span>
            <span className="file-size">({(file.size / 1024).toFixed(1)} KB)</span>
          </div>
        )}

        <div className="button-group">
          <button
            type="submit"
            className="submit-button upload-button"
            disabled={!file || uploading}
          >
            {uploading ? "Uploading..." : "Upload CSV"}
          </button>
          <button
            type="button"
            className="submit-button reset-button"
            onClick={handleReset}
            disabled={uploading}
          >
            Reset
          </button>
        </div>

        {status.message && (
          <div className={`status-message ${status.isError ? "error" : "success"}`}>
            {status.message}
          </div>
        )}

        {results && (
          <div className="results-section">
            {results.errors && (
              <div className="validation-errors">
                <h4>Validation Errors:</h4>
                <ul>
                  {results.errors.map((error, index) => (
                    <li key={index} className="error-item">{error}</li>
                  ))}
                </ul>
              </div>
            )}
            
            {results.failed_entries && (
              <div className="failed-entries">
                <h4>Failed Entries:</h4>
                <ul>
                  {results.failed_entries.map((entry, index) => (
                    <li key={index} className="error-item">
                      Barcode: {entry.barcode}, Quantity: {entry.quantity} - {entry.error}
                    </li>
                  ))}
                </ul>
              </div>
            )}
            
            {results.success_count > 0 && (
              <div className="success-summary">
                <p>✓ Successfully processed {results.success_count} entries</p>
              </div>
            )}
          </div>
        )}
      </form>
    </section>
  );
};