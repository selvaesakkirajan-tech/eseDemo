from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)

def test_sum_query_params():
    r = client.get("/sum", params={"a": 2, "b": 3})
    assert r.status_code == 200
    assert r.json()["sum"] == 5

def test_sum_expr():
    r = client.get("/sum", params={"expr": "10+15"})
    assert r.status_code == 200
    assert r.json()["sum"] == 25