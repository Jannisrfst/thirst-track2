#!/usr/bin/env python3
"""
WSGI entry point for production deployment
This file is used by Gunicorn to serve the Flask application
"""

import os
import sys
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Add the project directory to Python path
project_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_dir)

# Import the Flask application
from main import app

# Configure for production
app.config['ENV'] = 'production'
app.config['DEBUG'] = False
app.config['TESTING'] = False

# Security configurations
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'fallback-secret-key-change-me')
app.config['MAX_CONTENT_LENGTH'] = int(os.getenv('MAX_CONTENT_LENGTH', 16 * 1024 * 1024))  # 16MB

# CORS configuration for production
allowed_origins = os.getenv('CORS_ORIGINS', '*').split(',')
if allowed_origins == ['*']:
    # In production, you might want to restrict this to specific domains
    # For a local kiosk system, '*' is acceptable
    pass

# Logging configuration
import logging
from logging.handlers import RotatingFileHandler

if not app.debug:
    # Create logs directory if it doesn't exist
    if not os.path.exists('logs'):
        os.mkdir('logs')
    
    # Set up file logging
    file_handler = RotatingFileHandler('logs/thirst-track.log', maxBytes=10240000, backupCount=10)
    file_handler.setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
    ))
    file_handler.setLevel(logging.INFO)
    app.logger.addHandler(file_handler)
    
    app.logger.setLevel(logging.INFO)
    app.logger.info('Thirst Track startup')

# Application factory pattern for better testing and deployment
def create_app():
    """Application factory function"""
    return app

if __name__ == "__main__":
    # This should not be used in production, but kept for development
    app.run(debug=False, host="0.0.0.0", port=5001)
