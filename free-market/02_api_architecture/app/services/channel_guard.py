"""Central authorization guard for ERPNext integration channels."""

from __future__ import annotations

from typing import Iterable


CHANNEL_SCOPE_MAP = {
    'ADMIN': {'admin:*', 'erpnext:*', 'customer:*', 'shipment:*', 'invoice:*', 'payment:*'},
    'MARKET': {'market:*', 'supplier:*', 'customer:*', 'order:*', 'invoice:*'},
    'SHIPPING': {'shipping:*', 'customer:*', 'shipment:*', 'invoice:*', 'payment:*'},
}


def _normalize_scopes(scopes: Iterable[str] | None) -> set[str]:
    if not scopes:
        return set()
    return {str(scope).strip().lower() for scope in scopes if str(scope).strip()}


def derive_channel_from_role(role: str | None) -> str:
    """Infer the default integration channel from the user's role."""
    mapping = {
        'admin': 'ADMIN',
        'manager': 'ADMIN',
        'operator': 'SHIPPING',
        'viewer': 'SHIPPING'
    }
    return mapping.get((role or 'operator').lower(), 'ADMIN')


def infer_channel_from_scopes(scopes: Iterable[str] | None) -> str:
    """Infer the most relevant channel when no explicit channel is present."""
    scope_values = [str(scope).strip().lower() for scope in (scopes or []) if str(scope).strip()]
    if not scope_values:
        return 'ADMIN'
    if any(scope.startswith('admin:') or scope.startswith('erpnext:') for scope in scope_values):
        return 'ADMIN'
    if any(scope.startswith('market:') or scope.startswith('supplier:') for scope in scope_values):
        return 'MARKET'
    if any(scope.startswith('shipping:') or scope.startswith('customer:') or scope.startswith('shipment:') or scope.startswith('invoice:') or scope.startswith('payment:') for scope in scope_values):
        return 'SHIPPING'
    return 'ADMIN'


def derive_default_integration_claims(role: str | None, permissions: dict | None = None) -> tuple[str, list[str]]:
    """Build a safe channel + scopes set from the user's role and stored permissions."""
    permission_map = permissions or {}
    explicit_channel = permission_map.get('integration_channel')
    inferred_channel = infer_channel_from_scopes(permission_map.get('integration_scopes')) if not explicit_channel else str(explicit_channel).upper()
    channel = str(explicit_channel or derive_channel_from_role(role) if not explicit_channel else explicit_channel).upper()
    if not explicit_channel:
        channel = inferred_channel
    raw_scopes = permission_map.get('integration_scopes') or []
    if isinstance(raw_scopes, str):
        raw_scopes = [raw_scopes]
    scopes = [str(scope).strip() for scope in raw_scopes if str(scope).strip()]
    if not scopes:
        if channel == 'ADMIN':
            scopes = ['admin:*', 'erpnext:*', 'customer:*', 'shipment:*', 'invoice:*', 'payment:*']
        else:
            scopes = ['shipping:*', 'customer:*', 'shipment:*', 'invoice:*', 'payment:*']
    return channel, scopes


def normalize_integration_claims(claims: dict) -> tuple[str, list[str]]:
    """Normalize channel and scopes for JWT-based authorization."""
    explicit_channel = claims.get('integration_channel')
    raw_scopes = claims.get('integration_scopes') or []
    if isinstance(raw_scopes, str):
        raw_scopes = [raw_scopes]
    scopes = _normalize_scopes(raw_scopes)

    if explicit_channel:
        channel = str(explicit_channel).upper()
    else:
        channel = infer_channel_from_scopes(scopes) if scopes else derive_channel_from_role(claims.get('role'))

    if not scopes:
        if channel == 'ADMIN':
            scopes = {'admin:*', 'erpnext:*'}
        elif channel == 'MARKET':
            scopes = {'market:*', 'supplier:*'}
        else:
            scopes = {'shipping:*', 'customer:*', 'shipment:*', 'invoice:*', 'payment:*'}
    return channel, sorted(scopes)


def _matches_scope(scope: str, required: str) -> bool:
    scope = scope.lower()
    required = required.lower()
    if scope == required:
        return True
    if scope.endswith(':*') and required.startswith(scope[:-2] + ':'):
        return True
    if required.endswith(':*') and scope.startswith(required[:-2] + ':'):
        return True
    return False


def channel_allowed(claims: dict, required_channel: str, operation: str) -> bool:
    """Return True only when the caller has the correct channel and a matching scope for the requested operation."""
    if not claims:
        return False

    channel, scopes = normalize_integration_claims(claims)
    if channel != str(required_channel).upper():
        return False

    if not scopes:
        return False

    # The channel must match, and the scope must match the actual operation being requested.
    # A broad scope from a different resource family (for example admin:* for erpnext:sync_customer)
    # must not be treated as valid authorization for this operation.
    return any(_matches_scope(scope, op) for scope in scopes for op in (operation, '*'))


def require_channel_scope(claims: dict, required_channel: str, operation: str) -> None:
    """Raise PermissionError if caller cannot use the required channel/operation."""
    if not channel_allowed(claims, required_channel, operation):
        raise PermissionError(
            f"Channel {required_channel} is not allowed to perform {operation}."
        )


def require_any_channel_scope(claims: dict, required_channels: tuple[str, ...], operation: str) -> None:
    """Require the operation scope from any one of the permitted channels."""
    if not any(channel_allowed(claims, channel, operation) for channel in required_channels):
        channels = ', '.join(required_channels)
        raise PermissionError(f"Channels {channels} are not allowed to perform {operation}.")
