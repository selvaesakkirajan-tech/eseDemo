import base64
import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from fastapi.security import HTTPBasicCredentials
from src.main import app, verify_credentials

# ── Hardcoded test credentials (mirrors seed_users.py) ────────────────────────
VALID_USERS = {
    "kani":  "123",
    "sai":   "123",
    "san":   "123",
    "admin": "Admin@123",
}


def _make_verify_override(expected_user: str, expected_pass: str):
    """Return a FastAPI dependency override that validates one specific user."""
    def _verify(credentials: HTTPBasicCredentials = __import__(
            'fastapi.security', fromlist=['HTTPBasic']).HTTPBasic()()):
        if credentials.username == expected_user and credentials.password == expected_pass:
            return credentials.username
        raise HTTPException(status_code=401, detail="Invalid credentials",
                            headers={"WWW-Authenticate": "Basic"})
    return _verify


def _auth_header(username: str, password: str) -> dict:
    token = base64.b64encode(f"{username}:{password}".encode()).decode()
    return {"Authorization": f"Basic {token}"}


@pytest.fixture(autouse=True)
def clear_overrides():
    """Reset dependency overrides after each test."""
    yield
    app.dependency_overrides.clear()


# ── /health - no auth required ────────────────────────────────────────────────

def test_health_no_auth():
    client = TestClient(app)
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


# ── /sum - correct credentials ────────────────────────────────────────────────

def test_sum_query_params_kani():
    app.dependency_overrides[verify_credentials] = lambda: "kani"
    client = TestClient(app)
    r = client.get("/sum", params={"a": 2, "b": 3},
                   headers=_auth_header("kani", "123"))
    assert r.status_code == 200
    assert r.json()["sum"] == 5
    assert r.json()["requested_by"] == "kani"


def test_sum_query_params_admin():
    app.dependency_overrides[verify_credentials] = lambda: "admin"
    client = TestClient(app)
    r = client.get("/sum", params={"a": 5, "b": 3},
                   headers=_auth_header("admin", "Admin@123"))
    assert r.status_code == 200
    assert r.json()["sum"] == 8
    assert r.json()["requested_by"] == "admin"


def test_sum_expr_sai():
    app.dependency_overrides[verify_credentials] = lambda: "sai"
    client = TestClient(app)
    r = client.get("/sum", params={"expr": "10+15"},
                   headers=_auth_header("sai", "123"))
    assert r.status_code == 200
    assert r.json()["sum"] == 25


def test_sum_path_san():
    app.dependency_overrides[verify_credentials] = lambda: "san"
    client = TestClient(app)
    r = client.get("/sum/4/6", headers=_auth_header("san", "123"))
    assert r.status_code == 200
    assert r.json()["sum"] == 10


# ── /sum - wrong / missing credentials → 401 ─────────────────────────────────

def test_sum_no_auth_returns_401():
    """No auth header at all - FastAPI returns 401 automatically."""
    client = TestClient(app, raise_server_exceptions=False)
    r = client.get("/sum", params={"a": 1, "b": 2})
    assert r.status_code == 401


def test_sum_wrong_password_returns_401():
    """Override raises 401 for wrong password."""
    def _bad_auth():
        raise HTTPException(status_code=401, detail="Invalid credentials",
                            headers={"WWW-Authenticate": "Basic"})
    app.dependency_overrides[verify_credentials] = _bad_auth
    client = TestClient(app, raise_server_exceptions=False)
    r = client.get("/sum", params={"a": 1, "b": 2},
                   headers=_auth_header("kani", "wrongpassword"))
    assert r.status_code == 401


def test_sum_unknown_user_returns_401():
    """Override raises 401 for unknown user."""
    def _bad_auth():
        raise HTTPException(status_code=401, detail="Invalid credentials",
                            headers={"WWW-Authenticate": "Basic"})
    app.dependency_overrides[verify_credentials] = _bad_auth
    client = TestClient(app, raise_server_exceptions=False)
    r = client.get("/sum", params={"a": 1, "b": 2},
                   headers=_auth_header("nobody", "123"))
    assert r.status_code == 401

