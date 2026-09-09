"""
Main Application - نقطة الدخول الرئيسية لنظام الشحن
Flask Application Factory
"""
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Initialize extensions (single instances shared with app/models)
from .database import db, migrate
jwt = JWTManager()


def create_app(config_name='development'):
    """Application Factory - إنشاء التطبيق"""
    
    app = Flask(__name__)
    
    # Load configuration
    from .config import get_config
    config = get_config()
    app.config.from_object(config)
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    CORS(app, resources={r"/api/*": {"origins": app.config['CORS_ORIGINS']}})
    
    # Production and Docker use the versioned SQL schema. Opt in explicitly for local prototyping.
    if app.config.get('AUTO_CREATE_TABLES') and not app.config.get('TESTING'):
        with app.app_context():
            db.create_all()
    
    # Register Blueprints
    from .routes.auth import bp as auth_bp
    from .routes.branches import bp as branches_bp
    from .routes.warehouses import bp as warehouses_bp
    from .routes.customers import bp as customers_bp
    from .routes.shipments import bp as shipments_bp
    from .routes.containers import bp as containers_bp
    from .routes.tracking import bp as tracking_bp
    from .routes.invoices import bp as invoices_bp
    from .routes.payments import bp as payments_bp
    from .routes.erpnext import bp as erpnext_bp
    from .routes.ports import bp as ports_bp
    from .routes.shipping_lines import bp as shipping_lines_bp
    from .routes.integration_credentials import bp as integration_credentials_bp
    
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(branches_bp, url_prefix='/api/branches')
    app.register_blueprint(warehouses_bp, url_prefix='/api/warehouses')
    app.register_blueprint(customers_bp, url_prefix='/api/customers')
    app.register_blueprint(shipments_bp, url_prefix='/api/shipments')
    app.register_blueprint(containers_bp, url_prefix='/api/containers')
    app.register_blueprint(tracking_bp, url_prefix='/api/tracking')
    app.register_blueprint(invoices_bp, url_prefix='/api/invoices')
    app.register_blueprint(payments_bp, url_prefix='/api/payments')
    app.register_blueprint(erpnext_bp, url_prefix='/api/erpnext')
    app.register_blueprint(ports_bp, url_prefix='/api/ports')
    app.register_blueprint(shipping_lines_bp, url_prefix='/api/shipping-lines')
    app.register_blueprint(integration_credentials_bp, url_prefix='/api/admin/integration')
    
    # Health check
    @app.route('/health')
    def health():
        return jsonify({
            'status': 'healthy',
            'app': app.config['APP_NAME'],
            'version': app.config['APP_VERSION']
        })
    
    # Root endpoint
    @app.route('/')
    def index():
        return jsonify({
            'message': 'نظام الشحن API - Shipping System API',
            'status': 'working',
            'version': app.config['APP_VERSION'],
            'endpoints': {
                'auth': '/api/auth',
                'branches': '/api/branches',
                'customers': '/api/customers',
                'shipments': '/api/shipments',
                'containers': '/api/containers',
                'tracking': '/api/tracking',
                'invoices': '/api/invoices',
                'payments': '/api/payments',
                'erpnext': '/api/erpnext'
            }
        })
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Not found', 'message': str(error)}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Internal server error', 'message': str(error)}), 500
    
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return jsonify({
            'error': 'Token expired',
            'message': 'The token has expired. Please login again.'
        }), 401
    
    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return jsonify({
            'error': 'Invalid token',
            'message': 'Invalid token. Please provide a valid token.'
        }), 401
    
    @jwt.unauthorized_loader
    def missing_token_callback(error):
        return jsonify({
            'error': 'Authorization required',
            'message': 'Request does not contain an access token.'
        }), 401
    
    return app


# Create app instance
app = create_app()


if __name__ == '__main__':
    app.run(
        host=app.config['HOST'],
        port=app.config['PORT'],
        debug=app.config['DEBUG']
    )