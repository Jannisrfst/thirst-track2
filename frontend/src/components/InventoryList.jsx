import React, { useEffect, useState } from 'react';

export const InventoryList = () => {
  const [inventory, setInventory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [hoveredRow, setHoveredRow] = useState(null);

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
                ...(hoveredRow === index ? styles.rowHover : {})
              }}
              onMouseEnter={() => setHoveredRow(index)}
              onMouseLeave={() => setHoveredRow(null)}
            >
              <div style={styles.cell}>{item.barcode}</div>
              <div style={{...styles.cell, ...styles.count}}>{item.count}</div>
            </div>
          ))
        ) : (
          <div style={styles.empty}>No items in inventory</div>
        )}
      </div>
    </section>
  );
};
