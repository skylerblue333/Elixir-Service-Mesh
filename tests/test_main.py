from fastapi.testclient import TestClient

from src.main import ServiceRegistry, app


def test_registry_round_robin() -> None:
    registry = ServiceRegistry()
    registry.register("chat", "http://chat-a:8000")
    registry.register("chat", "http://chat-b:8000")
    assert registry.select("chat").url == "http://chat-a:8000"
    assert registry.select("chat").url == "http://chat-b:8000"
    assert registry.select("chat").url == "http://chat-a:8000"


def test_duplicate_registration_is_idempotent() -> None:
    registry = ServiceRegistry()
    first = registry.register("jobs", "https://jobs.example.com")
    second = registry.register("jobs", "https://jobs.example.com")
    assert first == second
    assert len(registry.list_instances("jobs")) == 1


def test_http_health_and_registry_flow() -> None:
    with TestClient(app) as client:
        assert client.get("/health").json()["status"] == "ok"
        registered = client.post(
            "/api/v1/instances",
            json={"service": "feed", "url": "https://feed.example.com"},
        )
        assert registered.status_code == 201
        selected = client.get("/api/v1/services/feed/select")
        assert selected.status_code == 200
        assert selected.json()["instance"]["url"] == "https://feed.example.com"


def test_invalid_url_is_rejected() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/instances", json={"service": "feed", "url": "file:///tmp/x"}
        )
        assert response.status_code == 422


def test_unknown_service_is_404() -> None:
    with TestClient(app) as client:
        assert client.get("/api/v1/services/not-registered/select").status_code == 404
