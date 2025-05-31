"use client";
import React from 'react';
import { useBarcode } from '../context/BarcodeContext';


export const ProductDetails = () => {
  const { activeBarcode } = useBarcode();
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
    </section>
  );
};
