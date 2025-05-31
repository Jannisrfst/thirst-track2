import React, { useEffect, useState } from 'react';
import { useBarcode } from '../context/BarcodeContext';

export const InventoryList = () => {
  const [inventory, setInventory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [hoveredRow, setHoveredRow] = useState(null);
  const [selectedItem, setSelectedItem] = useState(null);
  const { setActiveBarcode } = useBarcode();

  useEffect(() => {
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

    fetchInventory();
    
    // Refresh inventory data every 30 seconds
    const intervalId = setInterval(fetchInventory, 30000);
    
    // Clean up interval on component unmount
    return () => clearInterval(intervalId);
  }, []);

  const styles = {
    container: {
      padding: '20px',
      backgroundColor: '#f9f9f9',
      borderRadius: '8px',
      boxShadow: '0 2px 4px rgba(0,0,0,0.05)',
      margin: '20px 0'
    },
    title: {
      fontSize: '1.5rem',
      marginBottom: '20px',
      color: '#333',
      fontWeight: '500'
    },
    header: {
      display: 'grid',
      gridTemplateColumns: '3fr 1fr',
      padding: '15px 20px',
      backgroundColor: '#f0f0f0',
      borderRadius: '6px',
      marginBottom: '10px',
      fontWeight: 'bold',
      color: '#555'
    },
    row: {
      display: 'grid',
      gridTemplateColumns: '3fr 1fr',
      padding: '15px 20px',
      marginBottom: '8px',
      backgroundColor: 'white',
      borderRadius: '6px',
      borderLeft: '4px solid #ddd',
      transition: 'all 0.2s ease'
    },
    rowHover: {
      borderLeft: '4px solid #4a90e2',
      boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
    },
    rowSelected: {
      borderLeft: '4px solid #2e7d32',
      backgroundColor: '#f0f7ff',
      boxShadow: '0 2px 8px rgba(0,0,0,0.15)'
    },
    cell: {
      fontSize: '1rem',
      display: 'flex',
      alignItems: 'center'
    },
    count: {
      fontWeight: '500',
      color: '#4a90e2',
      fontSize: '1.1rem'
    },
    empty: {
      padding: '30px 20px',
      textAlign: 'center',
      color: '#888',
      backgroundColor: 'white',
      borderRadius: '6px',
      fontSize: '1.1rem'
    },
    loading: {
      padding: '30px 20px',
      textAlign: 'center',
      color: '#666',
      backgroundColor: 'white',
      borderRadius: '6px'
    },
    error: {
      padding: '20px',
      textAlign: 'center',
      color: '#d9534f',
      backgroundColor: '#fdf7f7',
      borderRadius: '6px',
      border: '1px solid #f4cecd'
    },
    detailsPanel: {
      marginTop: '20px',
      padding: '15px',
      backgroundColor: 'white',
      borderRadius: '6px',
      border: '1px solid #e0e0e0',
      boxShadow: '0 2px 4px rgba(0,0,0,0.05)'
    },
    detailsTitle: {
      fontSize: '1.2rem',
      marginBottom: '15px',
      fontWeight: '500',
      color: '#333'
    },
    detailsRow: {
      display: 'grid',
      gridTemplateColumns: '1fr 2fr',
      padding: '8px 0',
      borderBottom: '1px solid #f0f0f0'
    },
    detailsLabel: {
      fontWeight: '500',
      color: '#666'
    },
    detailsValue: {
      color: '#333'
    },
    actionButtons: {
      marginTop: '15px',
      display: 'flex',
      gap: '10px'
    },
    button: {
      padding: '8px 15px',
      border: 'none',
      borderRadius: '4px',
      cursor: 'pointer',
      fontWeight: '500',
      transition: 'all 0.2s ease'
    },
    editButton: {
      backgroundColor: '#4a90e2',
      color: 'white',
    },
    closeButton: {
      backgroundColor: '#f0f0f0',
      color: '#555',
    }
  };
  
  if (loading && inventory.length === 0) {
    return (
      <section style={styles.container}>
        <h2 style={styles.title}>Inventory</h2>
        <div style={styles.loading}>
          <div style={{marginBottom: '15px'}}>Loading inventory data...</div>
          <div style={{width: '40px', height: '40px', margin: '0 auto', border: '3px solid #f3f3f3', borderTop: '3px solid #4a90e2', borderRadius: '50%', animation: 'spin 1s linear infinite'}}></div>
          <style>{`
            @keyframes spin {
              0% { transform: rotate(0deg); }
              100% { transform: rotate(360deg); }
            }
          `}</style>
        </div>
      </section>
    );
  }

  if (error && inventory.length === 0) {
    return (
      <section style={styles.container}>
        <h2 style={styles.title}>Inventory</h2>
        <div style={styles.error}>
          <div style={{marginBottom: '10px', fontWeight: '500'}}>Error Loading Inventory</div>
          <div>{error}</div>
        </div>
      </section>
    );
  }

  return (
    <section style={styles.container}>
      <h2 style={styles.title}>Inventory</h2>
      
      {inventory.length > 0 && (
        <div style={styles.header}>
          <div>Barcode</div>
          <div>Quantity</div>
        </div>
      )}
      
      <div>
        {inventory.length > 0 ? (
          inventory.map((item, index) => (
            <div 
              key={index} 
              style={{
                ...styles.row,
                ...(hoveredRow === index ? styles.rowHover : {}),
                ...(selectedItem === item ? styles.rowSelected : {})
              }}
              onMouseEnter={() => setHoveredRow(index)}
              onMouseLeave={() => setHoveredRow(null)}
              onClick={() => {
                const newSelectedItem = selectedItem === item ? null : item;
                setSelectedItem(newSelectedItem);
                setActiveBarcode(newSelectedItem ? newSelectedItem.barcode : '');
              }}
            >
              <div style={styles.cell}>{item.barcode}</div>
              <div style={{...styles.cell, ...styles.count}}>{item.count}</div>
            </div>
          ))
        ) : (
          <div style={styles.empty}>No items in inventory</div>
        )}
      </div>

      {selectedItem && (
        <div style={styles.detailsPanel}>
          <h3 style={styles.detailsTitle}>Item Details</h3>
          <div style={styles.detailsRow}>
            <span style={styles.detailsLabel}>Barcode:</span>
            <span style={styles.detailsValue}>{selectedItem.barcode}</span>
          </div>
          <div style={styles.detailsRow}>
            <span style={styles.detailsLabel}>Quantity:</span>
            <span style={styles.detailsValue}>{selectedItem.count}</span>
          </div>
          <div style={styles.actionButtons}>
            <button 
              style={{...styles.button, ...styles.editButton}}
              onClick={() => {
                // You can implement edit functionality here
                console.log('Edit item:', selectedItem);
                // For now, just log the action
                alert(`Edit functionality for barcode ${selectedItem.barcode}`);
              }}
            >
              Edit
            </button>
            <button 
              style={{...styles.button, ...styles.closeButton}}
              onClick={() => setSelectedItem(null)}
            >
              Close
            </button>
          </div>
        </div>
      )}
    </section>
  );
};
