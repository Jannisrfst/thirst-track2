"use client";
import React, { useState } from 'react';

export const BarcodeScanner = () => {
  const [barcode, setBarcode] = useState('');
  const [quantity, setQuantity] = useState('1');
  const [status, setStatus] = useState({ message: '', isError: false });

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!barcode) {
      setStatus({ message: 'Please enter a barcode', isError: true });
      return;
    }

    try {
      const response = await fetch('http://localhost:5001/api/add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          barcode,
          quantity
        })
      });
      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.message || 'Failed to add entries');
      }

      setStatus({ message: result.message, isError: false });
      setBarcode('');
      setQuantity('1');
    } catch (error) {
      setStatus({ message: error.message, isError: true });
    }
  };

  return (
    <section className="scannerSection">
      <h2 className="sectionTitle">Enter Barcode</h2>
      <form onSubmit={handleSubmit}>
        <div className="formGroup">
          <label className="inputLabel">Barcode</label>
          <input 
            type="text" 
            className="barcodeInput" 
            value={barcode}
            onChange={(e) => setBarcode(e.target.value)}
            required
          />
        </div>
        <div className="formGroup">
          <label className="inputLabel">Quantity</label>
          <input 
            type="number" 
            className="quantityInput" 
            min="1" 
            value={quantity}
            onChange={(e) => setQuantity(e.target.value)}
            required
          />
        </div>
        <button type="submit" className="enterButton">Enter</button>
        {status.message && (
          <div className={`statusMessage ${status.isError ? 'error' : 'success'}`}>
            {status.message}
          </div>
        )}
      </form>
    </section>
  );
};
