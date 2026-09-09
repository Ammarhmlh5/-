"""
Currency - محرك تحويل العملات وسعر الصرف (CNY -> USD)
"""
from datetime import date
from decimal import Decimal, InvalidOperation

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_config
from ..models import FxRate

config = get_config()


def get_fx_rate(db: Session, base: str = "CNY", quote: str = "USD") -> Decimal:
    """Latest cached daily FX rate for base->quote."""
    today = date.today().isoformat()
    row = db.execute(
        select(FxRate)
        .where(FxRate.base_currency == base, FxRate.quote_currency == quote)
        .order_by(FxRate.effective_date.desc())
        .limit(1)
    ).scalars().first()
    if row is not None:
        return row.rate
    return Decimal(str(config.DEFAULT_FX_CNY_TO_USD))


def set_fx_rate(db: Session, rate, base: str = "CNY", quote: str = "USD",
                effective_date: str | None = None, source: str = "manual") -> FxRate:
    effective_date = effective_date or date.today().isoformat()
    existing = db.execute(
        select(FxRate).where(
            FxRate.base_currency == base,
            FxRate.quote_currency == quote,
            FxRate.effective_date == effective_date,
        )
    ).scalars().first()
    if existing:
        existing.rate = rate
        existing.source = source
        return existing
    fx = FxRate(
        base_currency=base,
        quote_currency=quote,
        rate=rate,
        effective_date=effective_date,
        source=source,
    )
    db.add(fx)
    return fx


def compute_unit_rate_usd(factory_price_cny, handling_fee_usd, fx_rate) -> Decimal:
    """unit_rate_usd = factory_price_cny * fx_rate + handling_fee_usd"""
    try:
        price = Decimal(str(factory_price_cny))
        fee = Decimal(str(handling_fee_usd))
        fx = Decimal(str(fx_rate))
        return (price * fx + fee).quantize(Decimal("0.01"))
    except (InvalidOperation, ValueError):
        raise ValueError("Invalid pricing inputs")
