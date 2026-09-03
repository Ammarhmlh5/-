"""
Database - اتصال قاعدة البيانات وإعداد SQLAlchemy
"""
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

# Initialize extensions
db = SQLAlchemy()
migrate = Migrate()


def init_db(app):
    """Initialize database with Flask app"""
    db.init_app(app)
    migrate.init_app(app, db)
    
    # Create tables if they don't exist
    with app.app_context():
        db.create_all()
    
    return db


def save_to_db(obj):
    """Save object to database"""
    db.session.add(obj)
    db.session.commit()
    return obj


def delete_from_db(obj):
    """Delete object from database"""
    db.session.delete(obj)
    db.session.commit()


def rollback():
    """Rollback current transaction"""
    db.session.rollback()


# Query helpers
def get_one_or_404(model, id):
    """Get one item or raise 404"""
    from flask import abort
    item = db.session.get(model, id)
    if not item:
        abort(404, description=f"{model.__name__} not found")
    return item


def get_all(model, **filters):
    """Get all items with optional filters"""
    query = model.query
    for key, value in filters.items():
        if hasattr(model, key):
            query = query.filter(getattr(model, key) == value)
    return query.all()


def paginate(query, page=1, per_page=20):
    """Paginate query results"""
    return db.paginate(query, page=page, per_page=per_page, error_out=False)