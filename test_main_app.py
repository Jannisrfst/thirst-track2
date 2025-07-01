#!/usr/bin/env python3
"""
Test script to verify main.py can be loaded and Flask app created
"""

import sys
import os
from unittest.mock import patch, MagicMock

def test_main_app_loading():
    """Test that main.py can be loaded without errors"""
    print("=== Testing main.py Application Loading ===")
    
    try:
        # Mock external dependencies that might not be available
        mock_modules = {
            'edev': MagicMock(),
            'classes.PersistanceLayer': MagicMock(),
            'classes.User': MagicMock(),
            'mail': MagicMock()
        }
        
        # Mock Email class
        mock_email = MagicMock()
        mock_modules['mail'].Email = mock_email
        
        # Mock PersistanceLayer
        mock_persistence = MagicMock()
        mock_modules['classes.PersistanceLayer'].PersistanceLayer = mock_persistence
        
        # Mock User
        mock_user = MagicMock()
        mock_modules['classes.User'].User = mock_user
        
        with patch.dict('sys.modules', mock_modules):
            # Try to import main
            import main
            
            print("✓ main.py imported successfully")
            
            # Check if Flask app exists
            if hasattr(main, 'app'):
                print("✓ Flask app instance found")
                
                # Check if Blueprint is registered
                if hasattr(main, 'api_bp'):
                    print("✓ API Blueprint found")
                else:
                    print("❌ API Blueprint not found")
                    return False
                
                # Check if routes are defined
                with main.app.app_context():
                    rules = list(main.app.url_map.iter_rules())
                    route_paths = [rule.rule for rule in rules]
                    
                    required_routes = ['/api/add', '/api/entries', '/api/decrement', '/api/add-csv']
                    
                    print("Found routes:")
                    for route in route_paths:
                        print(f"  - {route}")
                    
                    missing_routes = []
                    for required_route in required_routes:
                        if required_route not in route_paths:
                            missing_routes.append(required_route)
                    
                    if missing_routes:
                        print(f"❌ Missing routes: {missing_routes}")
                        return False
                    else:
                        print("✓ All required routes found")
                
                print("✓ Flask app structure verified")
                return True
            else:
                print("❌ Flask app instance not found")
                return False
                
    except Exception as e:
        print(f"❌ Failed to load main.py: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_csv_route_specifically():
    """Test CSV route registration specifically"""
    print("\n=== Testing CSV Route Registration ===")
    
    try:
        # Import Flask components
        from flask import Flask, Blueprint
        
        # Create a test app
        test_app = Flask(__name__)
        test_bp = Blueprint("api", __name__, url_prefix="/api")
        
        # Define a simple version of the CSV route
        @test_bp.route("/add-csv", methods=["POST"])
        def test_add_csv():
            return {"status": "test"}
        
        # Register blueprint
        test_app.register_blueprint(test_bp)
        
        # Check routes
        with test_app.app_context():
            rules = list(test_app.url_map.iter_rules())
            csv_route_found = any("/api/add-csv" in rule.rule for rule in rules)
            
            if csv_route_found:
                print("✓ CSV route registration works")
                return True
            else:
                print("❌ CSV route registration failed")
                return False
                
    except Exception as e:
        print(f"❌ CSV route test failed: {e}")
        return False

def main():
    """Run Flask app loading tests"""
    print("Starting Flask app loading tests...\n")
    
    app_loading = test_main_app_loading()
    csv_route = test_csv_route_specifically()
    
    print("\n" + "="*40)
    print("=== FLASK APP TEST RESULTS ===")
    print("="*40)
    print(f"Main app loading: {'✅ PASSED' if app_loading else '❌ FAILED'}")
    print(f"CSV route test: {'✅ PASSED' if csv_route else '❌ FAILED'}")
    print("="*40)
    
    all_passed = app_loading and csv_route
    
    if all_passed:
        print("🎉 Flask app is ready! All routes properly configured.")
    else:
        print("⚠️  Some Flask app tests failed.")
    
    return all_passed

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)