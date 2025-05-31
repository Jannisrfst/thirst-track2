import React from 'react';
import './styles/style.css';
import { ThirstTrackHeader } from './components/Header';
import { BarcodeScanner } from './components/BarcodeEntries';
import { InventoryList } from './components/InventoryList';
import { ProductDetails } from './components/ProductDetails';
import { BarcodeProvider } from './context/BarcodeContext';

function App() {
  return (
    <BarcodeProvider>
      <main className="container">
        <div className="mainContent">
        <ThirstTrackHeader />
        <div className="panelsContainer">
          <section className="leftPanel">
            <BarcodeScanner />
            <InventoryList />
          </section>
          <section className="rightPanel">
            <ProductDetails />
          </section>
        </div>
        </div>
      </main>
    </BarcodeProvider>
  );
}

export default App;
