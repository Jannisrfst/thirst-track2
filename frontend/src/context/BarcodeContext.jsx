import React, { createContext, useContext, useState } from 'react';

const BarcodeContext = createContext();

export const BarcodeProvider = ({ children }) => {
  const [activeBarcode, setActiveBarcode] = useState('');
  
  return (
    <BarcodeContext.Provider value={{ activeBarcode, setActiveBarcode }}>
      {children}
    </BarcodeContext.Provider>
  );
};

export const useBarcode = () => useContext(BarcodeContext);
