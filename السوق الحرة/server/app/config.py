"""
Configuration - إعدادات السوق الحرة (Marketplace)
"""
import os
from datetime import timedelta

from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base Configuration"""

    # App
    APP_NAME = os.getenv('APP_NAME', 'Free Market')
    APP_VERSION = os.getenv('APP_VERSION', '1.0.0')
    DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'
    APP_ENV = os.getenv('APP_ENV', 'development')

    # Database
    DATABASE_URL = os.getenv(
        'DATABASE_URL',
        'postgresql+psycopg://market_user:marketpass2026@localhost:5433/shipping_marketplace'
    )

    # JWT
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-secret-key-change-in-production')
    JWT_ALGORITHM = os.getenv('JWT_ALGORITHM', 'HS256')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(
        minutes=int(os.getenv('ACCESS_TOKEN_EXPIRE_MINUTES', '1440'))
    )

    # FX
    DEFAULT_FX_CNY_TO_USD = float(os.getenv('DEFAULT_FX_CNY_TO_USD', '0.14'))

    # Integration
    MARKET_ERP_KEY = os.getenv('MARKET_ERP_KEY', '')
    MARKET_ERP_SECRET = os.getenv('MARKET_ERP_SECRET', '')
    ERPNEXT_URL = os.getenv('ERPNEXT_URL', 'http://localhost:8080')
    ERPNEXT_WEBHOOK_SECRET = os.getenv('ERPNEXT_WEBHOOK_SECRET', '')
    OP03_GATEWAY_URL = os.getenv('OP03_GATEWAY_URL', 'http://localhost:8080')

    # CORS
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*').split(',')

    # Server
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', '8000'))

    # Celery
    CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')
    CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/1')


class DevelopmentConfig(Config):
    DEBUG = True


class ProductionConfig(Config):
    DEBUG = False


class TestingConfig(Config):
    DEBUG = False
    DATABASE_URL = os.getenv(
        'TEST_DATABASE_URL',
        'postgresql+psycopg://market_user:marketpass2026@localhost:5433/shipping_marketplace_test'
    )


config_by_name = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig,
}


def get_config(env: str | None = None):
    env = env or os.getenv('APP_ENV', 'development')
    return config_by_name.get(env, DevelopmentConfig)
