"""
Models - نماذج قاعدة البيانات
"""
from datetime import datetime
from ..database import db
import uuid
from sqlalchemy.dialects.postgresql import UUID as PostgreSQLUUID


class Branch(db.Model):
    """الفروع - Branches (مكتب الصين، مكتب اليمن)"""
    __tablename__ = 'branches'
    
    id = db.Column(PostgreSQLUUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    code = db.Column(db.String(10), unique=True, nullable=False)
    country = db.Column(db.String(50), nullable=False)
    cost_center_id = db.Column(db.String(100))
    warehouse_id = db.Column(db.String(100))
    address = db.Column(db.Text)
    phone = db.Column(db.String(20))
    email = db.Column(db.String(100))
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    warehouses = db.relationship('Warehouse', backref='branch', lazy='dynamic')
    shipments = db.relationship('Shipment', backref='branch', lazy='dynamic')
    users = db.relationship('User', backref='branch', lazy='dynamic')
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'code': self.code,
            'country': self.country,
            'cost_center_id': self.cost_center_id,
            'warehouse_id': self.warehouse_id,
            'address': self.address,
            'phone': self.phone,
            'email': self.email,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class Warehouse(db.Model):
    """المستودعات - Warehouses"""
    __tablename__ = 'warehouses'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    branch_id = db.Column(db.String(36), db.ForeignKey('branches.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    erpnext_warehouse_id = db.Column(db.String(100))
    parent_warehouse_id = db.Column(db.String(36), db.ForeignKey('warehouses.id'))
    location = db.Column(db.String(100))
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Self-referential relationship
    children = db.relationship('Warehouse', backref=db.backref('parent', remote_side=[id]))
    
    def to_dict(self):
        return {
            'id': self.id,
            'branch_id': self.branch_id,
            'name': self.name,
            'erpnext_warehouse_id': self.erpnext_warehouse_id,
            'parent_warehouse_id': self.parent_warehouse_id,
            'location': self.location,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class Customer(db.Model):
    """العملاء - Customers"""
    __tablename__ = 'customers'
    
    id = db.Column(PostgreSQLUUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    erpnext_customer_id = db.Column(db.String(100), unique=True)
    erpnext_sync_status = db.Column(db.String(20), nullable=False, default='PENDING')
    erpnext_sync_error = db.Column(db.Text)
    erpnext_synced_at = db.Column(db.DateTime)
    name = db.Column(db.String(200), nullable=False)
    name_ar = db.Column(db.String(200))
    name_en = db.Column(db.String(200))
    phone = db.Column(db.String(20))
    email = db.Column(db.String(100))
    address = db.Column(db.Text)
    address_ar = db.Column(db.Text)
    country = db.Column(db.String(50))
    city = db.Column(db.String(50))
    tax_number = db.Column(db.String(50))
    credit_limit = db.Column(db.Numeric(15,2), default=0)
    branch_id = db.Column(PostgreSQLUUID(as_uuid=False), db.ForeignKey('branches.id'))
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    shipments = db.relationship('Shipment', backref='customer', lazy='dynamic')
    invoices = db.relationship('Invoice', backref='customer', lazy='dynamic')
    payments = db.relationship('Payment', backref='customer', lazy='dynamic')
    integration_credentials = db.relationship(
        'CustomerIntegrationCredential', backref='customer',
        lazy='dynamic', cascade='all, delete-orphan'
    )
    
    def to_dict(self):
        return {
            'id': self.id,
            'erpnext_customer_id': self.erpnext_customer_id,
            'erpnext_sync_status': self.erpnext_sync_status,
            'erpnext_sync_error': self.erpnext_sync_error,
            'erpnext_synced_at': self.erpnext_synced_at.isoformat() if self.erpnext_synced_at else None,
            'name': self.name,
            'name_ar': self.name_ar,
            'name_en': self.name_en,
            'phone': self.phone,
            'email': self.email,
            'address': self.address,
            'address_ar': self.address_ar,
            'country': self.country,
            'city': self.city,
            'tax_number': self.tax_number,
            'credit_limit': float(self.credit_limit) if self.credit_limit else 0,
            'branch_id': self.branch_id,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class CustomerIntegrationCredential(db.Model):
    """مفتاح تشغيل العميل المحلي؛ لا يمنح وصولًا مباشرًا إلى ERPNext."""
    __tablename__ = 'customer_integration_credentials'

    id = db.Column(PostgreSQLUUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    customer_id = db.Column(PostgreSQLUUID(as_uuid=False), db.ForeignKey('customers.id'), nullable=False)
    key_fingerprint = db.Column(db.String(64), unique=True, nullable=False)
    key_hash = db.Column(db.String(128), nullable=False)
    scopes = db.Column(db.JSON, nullable=False, default=list)
    status = db.Column(db.String(20), nullable=False, default='ACTIVE')
    expires_at = db.Column(db.DateTime)
    last_used_at = db.Column(db.DateTime)
    revoked_at = db.Column(db.DateTime)
    created_by = db.Column(PostgreSQLUUID(as_uuid=False))
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'customer_id': self.customer_id,
            'key_fingerprint': self.key_fingerprint,
            'scopes': self.scopes or [],
            'status': self.status,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'last_used_at': self.last_used_at.isoformat() if self.last_used_at else None,
            'revoked_at': self.revoked_at.isoformat() if self.revoked_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class Shipment(db.Model):
    """الشحنات - Shipments"""
    __tablename__ = 'shipments'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    shipment_number = db.Column(db.String(50), unique=True, nullable=False)
    branch_id = db.Column(db.String(36), db.ForeignKey('branches.id'), nullable=False)
    customer_id = db.Column(db.String(36), db.ForeignKey('customers.id'), nullable=False)
    erpnext_sales_invoice_id = db.Column(db.String(100))
    
    # Container Info (kept in sync with 01_database_setup/create_tables.sql)
    container_number = db.Column(db.String(50))
    container_count = db.Column(db.Integer, default=1)
    
    # Status: pending, loaded, in_transit, customs, delivered, cancelled
    status = db.Column(db.String(30), default='pending')
    
    # Shipping Details
    origin_port = db.Column(db.String(100))
    destination_port = db.Column(db.String(100))
    vessel_name = db.Column(db.String(200))
    voyage_number = db.Column(db.String(50))
    
    # Dates
    order_date = db.Column(db.Date)
    departure_date = db.Column(db.DateTime)
    expected_arrival = db.Column(db.DateTime)
    actual_arrival = db.Column(db.DateTime)
    delivery_date = db.Column(db.DateTime)
    
    # Financial
    total_cost = db.Column(db.Numeric(15,2), default=0)
    selling_price = db.Column(db.Numeric(15,2), default=0)
    currency = db.Column(db.String(3), default='USD')
    
    # Notes
    description = db.Column(db.Text)
    notes = db.Column(db.Text)
    
    created_by = db.Column(db.String(36))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    containers = db.relationship('Container', backref='shipment', lazy='dynamic', cascade='all, delete-orphan')
    items = db.relationship('ShipmentItem', backref='shipment', lazy='dynamic', cascade='all, delete-orphan')
    invoices = db.relationship('Invoice', backref='shipment', lazy='dynamic')
    tracking_events = db.relationship('TrackingEvent', backref='shipment', lazy='dynamic')
    
    def to_dict(self):
        return {
            'id': self.id,
            'shipment_number': self.shipment_number,
            'branch_id': self.branch_id,
            'customer_id': self.customer_id,
            'erpnext_sales_invoice_id': self.erpnext_sales_invoice_id,
            'container_number': self.container_number,
            'container_count': self.container_count,
            'status': self.status,
            'origin_port': self.origin_port,
            'destination_port': self.destination_port,
            'vessel_name': self.vessel_name,
            'voyage_number': self.voyage_number,
            'order_date': self.order_date.isoformat() if self.order_date else None,
            'departure_date': self.departure_date.isoformat() if self.departure_date else None,
            'expected_arrival': self.expected_arrival.isoformat() if self.expected_arrival else None,
            'actual_arrival': self.actual_arrival.isoformat() if self.actual_arrival else None,
            'delivery_date': self.delivery_date.isoformat() if self.delivery_date else None,
            'total_cost': float(self.total_cost) if self.total_cost else 0,
            'selling_price': float(self.selling_price) if self.selling_price else 0,
            'currency': self.currency,
            'description': self.description,
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class Container(db.Model):
    """الحاويات - Containers"""
    __tablename__ = 'containers'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    shipment_id = db.Column(db.String(36), db.ForeignKey('shipments.id'), nullable=False)
    container_number = db.Column(db.String(50), nullable=False)
    container_type = db.Column(db.String(20), nullable=False)  # 20GP, 40GP, 40HC, 45HC
    seal_number = db.Column(db.String(50))
    weight = db.Column(db.Numeric(10,2))
    volume = db.Column(db.Numeric(10,3))
    package_count = db.Column(db.Integer, default=0)
    description = db.Column(db.Text)
    status = db.Column(db.String(30), default='loading')
    tracking_data = db.Column(db.JSON)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Unique constraint
    __table_args__ = (db.UniqueConstraint('shipment_id', 'container_number', name='uq_container_shipment'),)
    
    # Relationships
    tracking_events = db.relationship('TrackingEvent', backref='container', lazy='dynamic', cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'shipment_id': self.shipment_id,
            'container_number': self.container_number,
            'container_type': self.container_type,
            'seal_number': self.seal_number,
            'weight': float(self.weight) if self.weight else None,
            'volume': float(self.volume) if self.volume else None,
            'package_count': self.package_count,
            'description': self.description,
            'status': self.status,
            'tracking_data': self.tracking_data,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class TrackingEvent(db.Model):
    """أحداث التتبع - Tracking Events"""
    __tablename__ = 'tracking_events'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    container_id = db.Column(db.String(36), db.ForeignKey('containers.id'), nullable=False)
    shipment_id = db.Column(db.String(36), db.ForeignKey('shipments.id'))
    
    event_type = db.Column(db.String(50), nullable=False)  # departure, in_transit, arrival, customs, delivery
    event_date = db.Column(db.DateTime, nullable=False)
    location = db.Column(db.String(200))
    port_code = db.Column(db.String(10))
    country = db.Column(db.String(50))
    description = db.Column(db.Text)
    source = db.Column(db.String(20), default='manual')  # manual, api
    reference_number = db.Column(db.String(100))
    
    latitude = db.Column(db.Numeric(10,8))
    longitude = db.Column(db.Numeric(11,8))
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'container_id': self.container_id,
            'shipment_id': self.shipment_id,
            'event_type': self.event_type,
            'event_date': self.event_date.isoformat() if self.event_date else None,
            'location': self.location,
            'port_code': self.port_code,
            'country': self.country,
            'description': self.description,
            'source': self.source,
            'reference_number': self.reference_number,
            'latitude': float(self.latitude) if self.latitude else None,
            'longitude': float(self.longitude) if self.longitude else None,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class Invoice(db.Model):
    """الفواتير - Invoices"""
    __tablename__ = 'invoices'
    
    id = db.Column(PostgreSQLUUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    shipment_id = db.Column(PostgreSQLUUID(as_uuid=False), db.ForeignKey('shipments.id'))
    erpnext_invoice_id = db.Column(db.String(100), unique=True)
    invoice_type = db.Column(db.String(20), nullable=False)  # sales, purchase
    invoice_number = db.Column(db.String(50))
    invoice_date = db.Column(db.Date)
    
    customer_id = db.Column(PostgreSQLUUID(as_uuid=False), db.ForeignKey('customers.id'))
    supplier_id = db.Column(db.String(100))
    
    amount = db.Column(db.Numeric(15,2), nullable=False)
    tax_amount = db.Column(db.Numeric(15,2), default=0)
    discount_amount = db.Column(db.Numeric(15,2), default=0)
    total_amount = db.Column(db.Numeric(15,2), nullable=False)
    currency = db.Column(db.String(3), default='USD')
    
    # Status: draft, submitted, paid, cancelled
    status = db.Column(db.String(20), default='draft')
    cost_center_id = db.Column(db.String(100))
    warehouse_id = db.Column(db.String(100))
    
    due_date = db.Column(db.Date)
    paid_amount = db.Column(db.Numeric(15,2), default=0)
    
    notes = db.Column(db.Text)
    erpnext_link = db.Column(db.String(200))
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    payments = db.relationship('Payment', backref='invoice', lazy='dynamic')
    
    def to_dict(self):
        return {
            'id': self.id,
            'shipment_id': self.shipment_id,
            'erpnext_invoice_id': self.erpnext_invoice_id,
            'invoice_type': self.invoice_type,
            'invoice_number': self.invoice_number,
            'invoice_date': self.invoice_date.isoformat() if self.invoice_date else None,
            'customer_id': self.customer_id,
            'supplier_id': self.supplier_id,
            'amount': float(self.amount) if self.amount else 0,
            'tax_amount': float(self.tax_amount) if self.tax_amount else 0,
            'discount_amount': float(self.discount_amount) if self.discount_amount else 0,
            'total_amount': float(self.total_amount) if self.total_amount else 0,
            'currency': self.currency,
            'status': self.status,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'paid_amount': float(self.paid_amount) if self.paid_amount else 0,
            'erpnext_link': self.erpnext_link,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class Payment(db.Model):
    """المدفوعات - Payments"""
    __tablename__ = 'payments'
    
    id = db.Column(PostgreSQLUUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    invoice_id = db.Column(PostgreSQLUUID(as_uuid=False), db.ForeignKey('invoices.id'))
    erpnext_payment_id = db.Column(db.String(100), unique=True)
    erpnext_sync_status = db.Column(db.String(20), nullable=False, default='PENDING')
    erpnext_sync_error = db.Column(db.Text)
    erpnext_synced_at = db.Column(db.DateTime)
    
    payment_type = db.Column(db.String(20), nullable=False)  # received, made
    payment_number = db.Column(db.String(50))
    payment_date = db.Column(db.Date, nullable=False)
    
    customer_id = db.Column(PostgreSQLUUID(as_uuid=False), db.ForeignKey('customers.id'))
    supplier_id = db.Column(db.String(100))
    branch_id = db.Column(PostgreSQLUUID(as_uuid=False), db.ForeignKey('branches.id'))
    
    amount = db.Column(db.Numeric(15,2), nullable=False)
    currency = db.Column(db.String(3), default='USD')
    exchange_rate = db.Column(db.Numeric(10,4), default=1)
    
    payment_method = db.Column(db.String(30))  # cash, bank_transfer, credit_card
    reference_number = db.Column(db.String(100))
    
    # Status: pending, completed, failed
    status = db.Column(db.String(20), default='pending')
    
    notes = db.Column(db.Text)
    erpnext_link = db.Column(db.String(200))
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'invoice_id': self.invoice_id,
            'erpnext_payment_id': self.erpnext_payment_id,
            'erpnext_sync_status': self.erpnext_sync_status,
            'erpnext_sync_error': self.erpnext_sync_error,
            'erpnext_synced_at': self.erpnext_synced_at.isoformat() if self.erpnext_synced_at else None,
            'payment_type': self.payment_type,
            'payment_number': self.payment_number,
            'payment_date': self.payment_date.isoformat() if self.payment_date else None,
            'customer_id': self.customer_id,
            'supplier_id': self.supplier_id,
            'branch_id': self.branch_id,
            'amount': float(self.amount) if self.amount else 0,
            'currency': self.currency,
            'exchange_rate': float(self.exchange_rate) if self.exchange_rate else 1,
            'payment_method': self.payment_method,
            'reference_number': self.reference_number,
            'status': self.status,
            'notes': self.notes,
            'erpnext_link': self.erpnext_link,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class User(db.Model):
    """المستخدمين - Users"""
    __tablename__ = 'users'
    
    id = db.Column(PostgreSQLUUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    
    full_name = db.Column(db.String(100))
    full_name_ar = db.Column(db.String(100))
    phone = db.Column(db.String(20))
    
    branch_id = db.Column(PostgreSQLUUID(as_uuid=False), db.ForeignKey('branches.id'))
    role = db.Column(db.String(20), default='operator')  # admin, manager, operator, viewer
    
    permissions = db.Column(db.JSON, default={})
    
    is_active = db.Column(db.Boolean, default=True)
    last_login = db.Column(db.DateTime)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'full_name': self.full_name,
            'full_name_ar': self.full_name_ar,
            'phone': self.phone,
            'branch_id': self.branch_id,
            'role': self.role,
            'permissions': self.permissions,
            'is_active': self.is_active,
            'last_login': self.last_login.isoformat() if self.last_login else None,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class ShipmentItem(db.Model):
    """بنود الشحنات - Shipment Items"""
    __tablename__ = 'shipments_items'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    shipment_id = db.Column(db.String(36), db.ForeignKey('shipments.id'), nullable=False)
    
    item_name = db.Column(db.String(200), nullable=False)
    item_name_ar = db.Column(db.String(200))
    item_code = db.Column(db.String(50))
    quantity = db.Column(db.Numeric(10,2), nullable=False)
    unit = db.Column(db.String(20))
    unit_price = db.Column(db.Numeric(15,2))
    total_price = db.Column(db.Numeric(15,2))
    
    weight = db.Column(db.Numeric(10,2))
    volume = db.Column(db.Numeric(10,3))
    
    description = db.Column(db.Text)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'shipment_id': self.shipment_id,
            'item_name': self.item_name,
            'item_name_ar': self.item_name_ar,
            'item_code': self.item_code,
            'quantity': float(self.quantity) if self.quantity else 0,
            'unit': self.unit,
            'unit_price': float(self.unit_price) if self.unit_price else 0,
            'total_price': float(self.total_price) if self.total_price else 0,
            'weight': float(self.weight) if self.weight else None,
            'volume': float(self.volume) if self.volume else None,
            'description': self.description
        }


class ShippingLine(db.Model):
    """شركات الشحن - Shipping Lines"""
    __tablename__ = 'shipping_lines'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    name_ar = db.Column(db.String(100))
    code = db.Column(db.String(20), unique=True)
    api_endpoint = db.Column(db.String(200))
    tracking_url_template = db.Column(db.String(300))
    is_active = db.Column(db.Boolean, default=True)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'name_ar': self.name_ar,
            'code': self.code,
            'api_endpoint': self.api_endpoint,
            'tracking_url_template': self.tracking_url_template,
            'is_active': self.is_active,
            'notes': self.notes
        }


class Port(db.Model):
    """الموانئ - Ports"""
    __tablename__ = 'ports'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    name_ar = db.Column(db.String(100))
    code = db.Column(db.String(10), unique=True)
    country = db.Column(db.String(50), nullable=False)
    city = db.Column(db.String(50))
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'name_ar': self.name_ar,
            'code': self.code,
            'country': self.country,
            'city': self.city,
            'is_active': self.is_active
        }


class AuditLog(db.Model):
    """سجل المراجعة - Audit Logs"""
    __tablename__ = 'audit_logs'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'))
    action = db.Column(db.String(50), nullable=False)
    table_name = db.Column(db.String(50))
    record_id = db.Column(db.String(36))
    old_values = db.Column(db.JSON)
    new_values = db.Column(db.JSON)
    ip_address = db.Column(db.String(45))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    user = db.relationship('User', backref='audit_logs')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'action': self.action,
            'table_name': self.table_name,
            'record_id': self.record_id,
            'old_values': self.old_values,
            'new_values': self.new_values,
            'ip_address': self.ip_address,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class IntegrationChannel(db.Model):
    """قنوات التكامل الرئيسية مع ERPNext"""
    __tablename__ = 'integration_channels'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    channel_code = db.Column(db.String(20), unique=True, nullable=False)
    target_system = db.Column(db.String(30), nullable=False, default='ERPNEXT')
    status = db.Column(db.String(20), nullable=False, default='ACTIVE')
    current_credential_id = db.Column(db.String(36))
    previous_credential_id = db.Column(db.String(36))
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'channel_code': self.channel_code,
            'target_system': self.target_system,
            'status': self.status,
            'current_credential_id': self.current_credential_id,
            'previous_credential_id': self.previous_credential_id,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class IntegrationCredential(db.Model):
    """بيانات تعريف اعتماد التكامل دون تخزين السر"""
    __tablename__ = 'integration_credentials'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    channel_id = db.Column(db.String(36), db.ForeignKey('integration_channels.id'), nullable=False)
    owner_type = db.Column(db.String(30), nullable=False, default='SYSTEM')
    owner_id = db.Column(db.String(36))
    secret_ref = db.Column(db.String(300), nullable=False)
    key_fingerprint = db.Column(db.String(64), unique=True, nullable=False)
    secret_hash = db.Column(db.String(128), nullable=False)
    status = db.Column(db.String(20), nullable=False, default='ACTIVE')
    scopes = db.Column(db.JSON, nullable=False, default=list)
    environment = db.Column(db.String(20), nullable=False, default='development')
    created_by = db.Column(db.String(36), nullable=False)
    expires_at = db.Column(db.DateTime)
    activated_at = db.Column(db.DateTime)
    revoked_by = db.Column(db.String(36))
    revoked_at = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    channel = db.relationship('IntegrationChannel', backref='credentials')

    def to_dict(self):
        return {
            'id': self.id,
            'channel': self.channel.channel_code if self.channel else None,
            'owner_type': self.owner_type,
            'owner_id': self.owner_id,
            'secret_ref': self.secret_ref,
            'key_fingerprint': self.key_fingerprint,
            'status': self.status,
            'scopes': self.scopes,
            'environment': self.environment,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'activated_at': self.activated_at.isoformat() if self.activated_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class IntegrationKeyEvent(db.Model):
    """سجل غير قابل للتعديل لدورة حياة مفاتيح التكامل"""
    __tablename__ = 'integration_key_events'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    credential_id = db.Column(db.String(36), db.ForeignKey('integration_credentials.id'))
    channel_code = db.Column(db.String(20), nullable=False)
    actor_id = db.Column(db.String(36))
    action = db.Column(db.String(40), nullable=False)
    request_id = db.Column(db.String(36), nullable=False)
    result = db.Column(db.String(20), nullable=False)
    reason_code = db.Column(db.String(80))
    source_ip = db.Column(db.String(45))
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'credential_id': self.credential_id,
            'channel_code': self.channel_code,
            'actor_id': self.actor_id,
            'action': self.action,
            'request_id': self.request_id,
            'result': self.result,
            'reason_code': self.reason_code,
            'source_ip': self.source_ip,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class IntegrationWebhookEvent(db.Model):
    """سجل أحداث ERPNext الواردة دون تخزين الحمولة الحساسة."""
    __tablename__ = 'integration_webhook_events'

    id = db.Column(
        PostgreSQLUUID(as_uuid=False),
        primary_key=True,
        default=lambda: str(uuid.uuid4())
    )
    request_id = db.Column(db.String(100), nullable=False, unique=True)
    event = db.Column(db.String(100), nullable=False)
    payload_hash = db.Column(db.String(64), nullable=False)
    result = db.Column(db.String(20), nullable=False, default='ACCEPTED')
    source_ip = db.Column(db.String(45))
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)