"use client";
import React, { useState } from 'react';
import { useBarcode } from '../context/BarcodeContext';
import './BarcodeEntries.css';

export const BarcodeScanner = () => {
  const [barcode, setBarcode] = useState('');
  const [quantity, setQuantity] = useState('1');
  const [status, setStatus] = useState({ message: '', isError: false });
  const [loading, setLoading] = useState(false);
  const { setActiveBarcode } = useBarcode();

  const handleApiCall = async (endpoint, successMessage) => {
    if (!barcode) {
      setStatus({ message: 'Please enter a barcode', isError: true });
      return;
    }

    setLoading(true);
    setStatus({ message: '', isError: false });

    try {
      const response = await fetch(`http://localhost:5001/api/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          barcode,
          quantity: parseInt(quantity)
        })
      });
      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.message || `Failed to ${endpoint} entries`);
      }

      setStatus({ message: result.message || successMessage, isError: false });
      setActiveBarcode(barcode); // Share barcode with other components
      setBarcode('');
      setQuantity('1');
    } catch (error) {
      setStatus({ message: error.message, isError: true });
    } finally {
      setLoading(false);
    }
  };

  const handleAdd = (e) => {
    e.preventDefault();
    handleApiCall('add', 'Items added successfully');
  };

  const handleRemove = (e) => {
    e.preventDefault();
    handleApiCall('decrement', 'Items removed successfully');
  };

  return (
    <section className="scanner-section">
      <h2 className="scanner-title">Barcode Scanner</h2>
      <form className="scanner-form">
        <div className="form-group">
          <label className="form-label">Barcode</label>
          <input 
            type="text" 
            className="form-input" 
            value={barcode}
            onChange={(e) => setBarcode(e.target.value)}
            placeholder="Enter or scan barcode"
            disabled={loading}
            required
          />
        </div>
        <div className="form-group">
          <label className="form-label">Quantity</label>
          <input 
            type="number" 
            className="form-input quantity-input" 
            min="1" 
            value={quantity}
            onChange={(e) => setQuantity(e.target.value)}
            disabled={loading}
            required
          />
        </div>
        <div className="button-group">
          <button 
            type="button" 
            className="submit-button add-button" 
            onClick={handleAdd}
            disabled={loading}
          >
            {loading ? 'Processing...' : 'Add to Inventory'}
          </button>
          <button 
            type="button" 
            className="submit-button remove-button" 
            onClick={handleRemove}
            disabled={loading}
          >
            {loading ? 'Processing...' : 'Remove from Inventory'}
          </button>
        </div>
        {status.message && (
          <div className={`status-message ${status.isError ? 'error' : 'success'}`}>
            {status.message}
          </div>
        )}
      </form>
    </section>
  );
};
