import { useState, useEffect } from 'react';

export const useProductData = (barcode) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [productData, setProductData] = useState(null);
  
  useEffect(() => {
    if (!barcode) {
      setProductData(null);
      return;
    }
    
    const fetchData = async () => {
      setLoading(true);
      setError(null);
      
      try {
        const response = await fetch(`https://world.openfoodfacts.org/api/v2/product/${barcode}.json`);
        
        if (!response.ok) {
          throw new Error(`API error: ${response.status}`);
        }
        
        const data = await response.json();
        
        if (data.status === 1) {
          // Extract only the fields we need
          const { product_name, brands, quantity } = data.product;
          setProductData({ 
            product_name, 
            brands, 
            quantity 
          });
        } else {
          throw new Error('Product not found');
        }
      } catch (err) {
        console.error('Error fetching product data:', err);
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, [barcode]);
  
  return { loading, error, productData };
};
