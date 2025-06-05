"use client";
import React from 'react';
import { useBarcode } from '../context/BarcodeContext';
import { useProductData } from '../hooks/useProductData';
import '../styles/productDetails.css';


export const ProductDetails = () => {
  const { activeBarcode } = useBarcode();
  const { loading, error, productData } = useProductData(activeBarcode);
  return (
    <section className="productSection">
      <h2 className="sectionTitle">Product Details</h2>
      <div className="barcodeContainer">
        <img
          src="https://cdn.builder.io/api/v1/image/assets/TEMP/1d6592fbefe011c82041b7e1cc359e1bbfe20506"
          alt="Barcode"
          className="barcodeImage"
        />
        <div className="barcodeNumber">{activeBarcode || '123456789012'}</div>
      </div>

      {loading ? (
        <div className="loadingContainer" aria-live="polite">
          <p>Loading product information...</p>
        </div>
      ) : error ? (
        <div className="errorContainer" role="alert">
          <p className="errorMessage">{error}</p>
        </div>
      ) : productData ? (
        <div className="productInfoContainer">
          <div className="infoItem">
            <span className="infoLabel">Name</span>
            <span className="infoValue">{productData.product_name || 'Unknown'}</span>
          </div>
          <div className="infoItem">
            <span className="infoLabel">Brand</span>
            <span className="infoValue">{productData.brands || 'Unknown'}</span>
          </div>
          <div className="infoItem">
            <span className="infoLabel">Quantity</span>
            <span className="infoValue">{productData.quantity || 'Unknown'}</span>
          </div>
        </div>
      ) : activeBarcode ? (
        <div className="noDataContainer">
          <p>Select a product from the inventory or scan a new item.</p>
        </div>
      ) : null}
    </section>
  );
};
