import React from 'react';


export const InventoryList = () => {
  return (
    <section>
      <h2 className="sectionTitle">Inventory</h2>
      <div className="inventoryHeader">
        <div className="columnName">Name</div>
        <div className="columnPrice">Price</div>
        <div className="columnStock">Stock</div>
      </div>
      <div>
        {[1, 2, 3].map((index) => (
          <div key={index} className="inventoryRow">
            <div className="rowCell" />
            <div className="rowCell" />
            <div className="rowCell" />
          </div>
        ))}
      </div>
    </section>
  );
};
