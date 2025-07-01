/**
 * Test script to verify frontend component imports work correctly
 */

const fs = require('fs');
const path = require('path');

function checkFileExists(filePath) {
    const fullPath = path.join(__dirname, filePath);
    const exists = fs.existsSync(fullPath);
    console.log(`${exists ? '✓' : '❌'} ${filePath} ${exists ? 'exists' : 'missing'}`);
    return exists;
}

function checkImports() {
    console.log('=== Checking Frontend Component Files ===');
    
    // Check main files
    const files = [
        'frontend/src/App.jsx',
        'frontend/src/components/CsvUploader.jsx',
        'frontend/src/components/CsvUploader.css',
        'frontend/src/components/BarcodeEntries.jsx',
        'frontend/src/components/InventoryList.jsx',
        'frontend/src/components/Header.jsx',
        'frontend/src/components/ProductDetails.jsx',
        'frontend/src/context/BarcodeContext.jsx'
    ];
    
    let allExist = true;
    files.forEach(file => {
        if (!checkFileExists(file)) {
            allExist = false;
        }
    });
    
    return allExist;
}

function checkAppJsxImports() {
    console.log('\n=== Checking App.jsx Import Statements ===');
    
    const appPath = path.join(__dirname, 'frontend/src/App.jsx');
    if (!fs.existsSync(appPath)) {
        console.log('❌ App.jsx not found');
        return false;
    }
    
    const content = fs.readFileSync(appPath, 'utf8');
    
    const requiredImports = [
        "import { CsvUploader } from './components/CsvUploader'",
        "import { BarcodeScanner } from './components/BarcodeEntries'",
        "import { InventoryList } from './components/InventoryList'",
        "import { BarcodeProvider } from './context/BarcodeContext'"
    ];
    
    let allImportsFound = true;
    requiredImports.forEach(importStatement => {
        const found = content.includes(importStatement);
        console.log(`${found ? '✓' : '❌'} ${importStatement} ${found ? 'found' : 'missing'}`);
        if (!found) allImportsFound = false;
    });
    
    // Check if CsvUploader is used in JSX
    const csvUploaderUsed = content.includes('<CsvUploader />');
    console.log(`${csvUploaderUsed ? '✓' : '❌'} <CsvUploader /> ${csvUploaderUsed ? 'found in JSX' : 'missing from JSX'}`);
    
    return allImportsFound && csvUploaderUsed;
}

function checkCsvUploaderImports() {
    console.log('\n=== Checking CsvUploader.jsx Dependencies ===');
    
    const csvPath = path.join(__dirname, 'frontend/src/components/CsvUploader.jsx');
    if (!fs.existsSync(csvPath)) {
        console.log('❌ CsvUploader.jsx not found');
        return false;
    }
    
    const content = fs.readFileSync(csvPath, 'utf8');
    
    const requiredImports = [
        'import React',
        'import { useBarcode } from "../context/BarcodeContext"',
        'import "./CsvUploader.css"'
    ];
    
    let allImportsFound = true;
    requiredImports.forEach(importStatement => {
        const found = content.includes(importStatement);
        console.log(`${found ? '✓' : '❌'} ${importStatement} ${found ? 'found' : 'missing'}`);
        if (!found) allImportsFound = false;
    });
    
    return allImportsFound;
}

function main() {
    console.log('Starting frontend import verification...\n');
    
    const filesExist = checkImports();
    const appImports = checkAppJsxImports();
    const csvImports = checkCsvUploaderImports();
    
    const allGood = filesExist && appImports && csvImports;
    
    console.log('\n=== Summary ===');
    console.log(`Files exist: ${filesExist ? '✓' : '❌'}`);
    console.log(`App.jsx imports: ${appImports ? '✓' : '❌'}`);
    console.log(`CsvUploader imports: ${csvImports ? '✓' : '❌'}`);
    console.log(`\nOverall result: ${allGood ? '✅ All checks passed!' : '❌ Some checks failed'}`);
    
    return allGood;
}

if (require.main === module) {
    const success = main();
    process.exit(success ? 0 : 1);
}