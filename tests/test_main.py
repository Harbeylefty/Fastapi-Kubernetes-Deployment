import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

# check if the /health endpoint is working and returns a healthy status
def test_health_endpoint():
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

# check if the /metrics endpoint is available and exposing prometheus metrics
def test_metrics_endpoint():
    """Test metrics endpoint."""
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text

# check if the /test endpoint returns the list of items as expected. 
def test_get_items():
    """Test getting all items."""
    response = client.get("/items")
    assert response.status_code == 200
    assert "items" in response.json()

# confirm that a new item can be created via the /items endpoint. 
def test_create_item():
    """Test creating a new item."""
    item_data = {"name": "Test Item", "description": "Test Description"}
    response = client.post("/items", json=item_data)
    assert response.status_code == 200
    assert response.json()["message"] == "Item created" 