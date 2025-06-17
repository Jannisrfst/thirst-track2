import React, { useEffect, useState } from 'react';
import { useBarcode } from '../context/BarcodeContext';
import './InventoryList.css';

export const InventoryList = () => {
  const [inventory, setInventory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [hoveredRow, setHoveredRow] = useState(null);
  const [selectedItem, setSelectedItem] = useState(null);
  const [message, setMessage] = useState(null);
  const [decrementLoading, setDecrementLoading] = useState(false);
  const { setActiveBarcode } = useBarcode();

  const fetchInventory = async () => {
    try {
      setLoading(true);
      const response = await fetch('http://localhost:5001/api/entries');
      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }
      const data = await response.json();
      
      if (data.status === 'success' && Array.isArray(data.data)) {
        setInventory(data.data);
      } else {
        throw new Error('Invalid data format received from API');
      }
    } catch (err) {
      console.error('Error fetching inventory:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const decrementItem = async (barcode, quantity = 1) => {
    try {
      setDecrementLoading(true);
      setMessage(null);
      
      const response = await fetch('http://localhost:5001/api/decrement', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          barcode: barcode,
          quantity: quantity
        })
      });

      const data = await response.json();

      if (response.ok && data.status === 'success') {
        setMessage({ type: 'success', text: data.message });
        // Refresh inventory after successful decrement
        await fetchInventory();
        // Close the details panel
        setSelectedItem(null);
      } else {
        throw new Error(data.message || 'Failed to decrement item');
      }
    } catch (err) {
      console.error('Error decrementing item:', err);
      setMessage({ type: 'error', text: err.message });
    } finally {
      setDecrementLoading(false);
    }
  };

  useEffect(() => {
    fetchInventory();
    
    // Refresh inventory data every 30 seconds
    const intervalId = setInterval(fetchInventory, 30000);
    
    // Clean up interval on component unmount
    return () => clearInterval(intervalId);
  }, []);

  
  if (loading && inventory.length === 0) {
    return (
      <section className="inventory-container">
        <h2 className="inventory-title">Inventory</h2>
        <div className="inventory-loading">
          <div style={{marginBottom: '15px'}}>Loading inventory data...</div>
          <div className="inventory-spinner"></div>
        </div>
      </section>
    );
  }

  if (error && inventory.length === 0) {
    return (
      <section className="inventory-container">
        <h2 className="inventory-title">Inventory</h2>
        <div className="inventory-error">
          <div style={{marginBottom: '10px', fontWeight: '500'}}>Error Loading Inventory</div>
          <div>{error}</div>
        </div>
      </section>
    );
  }

  return (
    <section className="inventory-container">
      <h2 className="inventory-title">Inventory</h2>
      
      {inventory.length > 0 && (
        <div className="inventory-header">
          <div>Barcode</div>
          <div>Quantity</div>
        </div>
      )}
      
      <div>
        {inventory.length > 0 ? (
          inventory.map((item, index) => (
            <div 
              key={index} 
              className={`inventory-row ${
                selectedItem === item ? 'selected' : ''
              }`}
              onMouseEnter={() => setHoveredRow(index)}
              onMouseLeave={() => setHoveredRow(null)}
              onClick={() => {
                const newSelectedItem = selectedItem === item ? null : item;
                setSelectedItem(newSelectedItem);
                setActiveBarcode(newSelectedItem ? newSelectedItem.barcode : '');
              }}
            >
              <div className="inventory-cell">{item.barcode}</div>
              <div className="inventory-cell inventory-count">{item.count}</div>
            </div>
          ))
        ) : (
          <div className="inventory-empty">No items in inventory</div>
        )}
      </div>

      {selectedItem && (
        <div className="inventory-details-panel">
          <h3 className="inventory-details-title">Item Details</h3>
          
          {message && (
            <div className={`inventory-message ${
              message.type === 'success' ? 'success' : 'error'
            }`}>
              {message.text}
            </div>
          )}
          
          <div className="inventory-details-row">
            <span className="inventory-details-label">Barcode:</span>
            <span className="inventory-details-value">{selectedItem.barcode}</span>
          </div>
          <div className="inventory-details-row">
            <span className="inventory-details-label">Quantity:</span>
            <span className="inventory-details-value">{selectedItem.count}</span>
          </div>
          <div className="inventory-action-buttons">
            <button 
              className="inventory-button inventory-edit-button"
              onClick={() => decrementItem(selectedItem.barcode)}
              disabled={decrementLoading}
            >
              {decrementLoading ? 'Decrementing...' : 'Decrement'}
            </button>
            <button 
              className="inventory-button inventory-close-button"
              onClick={() => {
                setSelectedItem(null);
                setMessage(null);
              }}
            >
              Close
            </button>
          </div>
        </div>
      )}
    </section>
  );
};
