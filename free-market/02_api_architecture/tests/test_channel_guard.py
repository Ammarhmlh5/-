import pytest

from app.services.channel_guard import (
    channel_allowed,
    derive_default_integration_claims,
    normalize_integration_claims,
    require_any_channel_scope,
    require_channel_scope,
)


def test_channel_allowed_accepts_matching_scope():
    claims = {
        'integration_channel': 'ADMIN',
        'integration_scopes': ['admin:*', 'erpnext:*']
    }
    assert channel_allowed(claims, 'ADMIN', 'erpnext:sync_customer') is True


def test_channel_allowed_rejects_wrong_channel():
    claims = {
        'integration_channel': 'MARKET',
        'integration_scopes': ['market:*']
    }
    assert channel_allowed(claims, 'ADMIN', 'erpnext:sync_customer') is False


def test_require_channel_scope_raises_for_missing_scope():
    claims = {
        'integration_channel': 'ADMIN',
        'integration_scopes': ['admin:*']
    }
    with pytest.raises(PermissionError):
        require_channel_scope(claims, 'ADMIN', 'erpnext:sync_customer')


def test_normalize_integration_claims_defaults_channel_and_scopes():
    claims = {'integration_scopes': ['erpnext:*']}
    channel, scopes = normalize_integration_claims(claims)
    assert channel == 'ADMIN'
    assert 'erpnext:*' in scopes


def test_derive_default_integration_claims_uses_role_channel():
    channel, scopes = derive_default_integration_claims('operator', {'integration_scopes': ['shipping:*']})
    assert channel == 'SHIPPING'
    assert 'shipping:*' in scopes


def test_require_any_channel_scope_accepts_admin_or_shipping():
    claims = {'integration_channel': 'ADMIN', 'integration_scopes': ['customer:create']}
    require_any_channel_scope(claims, ('SHIPPING', 'ADMIN'), 'customer:create')
