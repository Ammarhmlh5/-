"""
Main - نقطة الدخول لخادم السوق الحرة (FastAPI)
"""
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from . import database
from .config import get_config
from .deps import AuthError
from .routes import (
    api_keys,
    auth,
    catalog,
    integration_status,
    orders,
    suppliers,
    tenant_users,
    webhooks,
)
from .security import hash_password
from .models import MarketOperator

config = get_config()


@asynccontextmanager
async def lifespan(app: FastAPI):
    database.create_all(app.state.engine)
    _bootstrap(db_engine=app.state.engine)
    yield


def _bootstrap(db_engine=None):
    """Seed a default market admin so the server is immediately usable."""
    from sqlalchemy import select
    Session = app.state.session_factory
    with Session() as db:
        if db.execute(select(MarketOperator).where(
                MarketOperator.username == "admin")).scalars().first() is None:
            db.add(MarketOperator(
                username="admin",
                email="admin@market.local",
                password_hash=hash_password("Admin123!"),
                full_name="Market Administrator",
                role="ADMIN",
            ))
            db.commit()


def create_app() -> FastAPI:
    engine, session_factory = database.init_db()
    app = FastAPI(
        title="السوق الحرة — Free Market API",
        version=config.APP_VERSION,
        lifespan=lifespan,
    )
    app.state.engine = engine
    app.state.session_factory = session_factory
    app.add_middleware(
        CORSMiddleware,
        allow_origins=config.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(auth.router, prefix="/api/market")
    app.include_router(suppliers.router, prefix="/api/market")
    app.include_router(tenant_users.router, prefix="/api/market")
    app.include_router(catalog.router, prefix="/api/market")
    app.include_router(orders.router, prefix="/api/market")
    app.include_router(api_keys.router, prefix="/api/market")
    app.include_router(integration_status.router, prefix="/api/market")
    app.include_router(webhooks.router, prefix="/api/market")

    @app.get("/health")
    def health():
        return {"status": "healthy", "app": config.APP_NAME, "version": config.APP_VERSION}

    @app.get("/")
    def index():
        return {"message": "السوق الحرة API", "status": "working"}

    return app


app = create_app()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG,
    )
