"""Celery entry points for background integration work."""
import os

from celery import Celery

from .main import app
from .workers.erpnext_outbox import drain_outbox


celery_app = Celery(
    'shipping_system',
    broker=os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0'),
    backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/1'),
)
celery_app.conf.beat_schedule = {
    'drain-erpnext-outbox-every-minute': {
        'task': 'shipping.drain_erpnext_outbox',
        'schedule': 60.0,
    },
}


@celery_app.task(name='shipping.drain_erpnext_outbox')
def drain_erpnext_outbox(limit=20):
    """Drain ready financial commands from the local outbox."""
    with app.app_context():
        return drain_outbox(limit=limit)