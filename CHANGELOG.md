# Changelog

## [Unreleased] - 2025-05-17

### Added
- Added CORS support to enable cross-origin requests from the React frontend
- Created API Blueprint with `/api` prefix for better route organization
- Added JSON response format for API endpoints
- Added new API endpoints:
  - `GET /api/entries` - Fetch all entries
  - `POST /api/add/<number>` - Add a new entry
  - `GET /api/populate` - Render population template
- Created Product Requirements Document (PRD) outlining project scope and features
- Added development server host configuration for better local development
- Included allowedHosts configuration in webpack for both localhost and 127.0.0.1
- Created new frontend directory structure for React implementation
- Added `frontend/package.json` with React 16.14.0 and necessary build dependencies
- Added `frontend/webpack.config.js` for build configuration
- Added `frontend/index.html` as the main HTML template
- Added `frontend/src/index.jsx` as the React entry point
- Added basic CSS styling structure in `frontend/src/styles/`

### Changed
- Reorganized Flask routes to use Blueprint pattern
- Updated API responses to return JSON format
- Updated webpack dev server configuration for improved local development experience
- Enhanced browser compatibility with explicit host and port settings
- Improved development server error handling and logging
- Switched from Vite to Webpack for better ARM compatibility
- Downgraded React to v16.14.0 for better Raspberry Pi support
- Updated React rendering to use React 16 compatible syntax
- Modified build tooling to use more ARM-friendly versions:
  - webpack@4.44.2
  - babel-loader@8.2.2
  - @babel/core@7.12.10
  - @babel/preset-react@7.12.10
- Converted CSS modules to standard CSS for better compatibility
- Updated component imports to use direct CSS classes instead of CSS modules

### Fixed
- Resolved development server accessibility issues on local network
- Fixed browser preview functionality to work with localhost:3000
- Addressed port conflict issues with better process management
- Resolved npm installation issues by disabling IPv6 and using npmmirror.com registry
- Fixed ReactDOM client import for React 16 compatibility
- Corrected CSS module import paths and class name references

### Technical Details
- Added `flask-cors` package for handling CORS headers
- API endpoints now follow RESTful conventions under `/api` prefix
- Frontend build setup uses Webpack instead of Vite due to ARM compatibility issues
- Development server configured to run on port 3000
- API proxy configured to forward requests to Flask backend on port 5000
- Babel configured for React JSX transformation

### Installation Notes
- Node.js v18.19.0 and npm v9.2.0 installed on Raspberry Pi
- Using npmmirror.com registry for reliable package installation
- IPv6 disabled to prevent network timeouts during installation
- Development server accessible via http://localhost:3000
- Install new dependency: `pip install flask-cors`

### Pending
- Remove Flask HTML templates
- Test all components with new CSS structure
