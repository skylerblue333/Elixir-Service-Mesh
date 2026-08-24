from __future__ import annotations

import logging
import time
from dataclasses import dataclass
from threading import RLock
from urllib.parse import urlparse

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, field_validator

LOGGER = logging.getLogger("sky-service-registry")
MAX_SERVICES = 500
MAX_INSTANCES_PER_SERVICE = 100


class InstanceRequest(BaseModel):
    service: str = Field(min_length=1, max_length=80, pattern=r"^[A-Za-z0-9._-]+$")
    url: str = Field(min_length=1, max_length=500)

    @field_validator("url")
    @classmethod
    def validate_url(cls, value: str) -> str:
        parsed = urlparse(value)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ValueError("url must be an absolute http(s) URL")
        return value.rstrip("/")


@dataclass(frozen=True)
class Instance:
    url: str
    registered_at: int


class ServiceRegistry:
    """Thread-safe in-memory registry with deterministic round-robin selection."""

    def __init__(self) -> None:
        self._services: dict[str, list[Instance]] = {}
        self._cursor: dict[str, int] = {}
        self._lock = RLock()

    def register(self, service: str, url: str) -> Instance:
        with self._lock:
            if service not in self._services and len(self._services) >= MAX_SERVICES:
                raise ValueError("service registry capacity reached")
            instances = self._services.setdefault(service, [])
            if any(instance.url == url for instance in instances):
                return next(instance for instance in instances if instance.url == url)
            if len(instances) >= MAX_INSTANCES_PER_SERVICE:
                raise ValueError("service instance capacity reached")
            instance = Instance(url=url, registered_at=int(time.time()))
            instances.append(instance)
            return instance

    def select(self, service: str) -> Instance:
        with self._lock:
            instances = self._services.get(service, [])
            if not instances:
                raise KeyError(service)
            cursor = self._cursor.get(service, 0) % len(instances)
            self._cursor[service] = cursor + 1
            return instances[cursor]

    def list_instances(self, service: str) -> tuple[Instance, ...]:
        with self._lock:
            return tuple(self._services.get(service, []))


registry = ServiceRegistry()
app = FastAPI(title="Sky Service Registry", version="0.1.0")


@app.get("/health")
def health() -> dict[str, object]:
    return {"status": "ok", "service": "sky-service-registry"}


@app.get("/ready")
def ready() -> dict[str, bool]:
    return {"ready": True}


@app.post("/api/v1/instances", status_code=201)
def register_instance(request: InstanceRequest) -> dict[str, object]:
    try:
        instance = registry.register(request.service, request.url)
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    LOGGER.info("instance_registered service=%s", request.service)
    return {"service": request.service, "instance": instance.__dict__}


@app.get("/api/v1/services/{service}/instances")
def list_instances(service: str) -> dict[str, object]:
    return {"service": service, "instances": [item.__dict__ for item in registry.list_instances(service)]}


@app.get("/api/v1/services/{service}/select")
def select_instance(service: str) -> dict[str, object]:
    try:
        instance = registry.select(service)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="service has no registered instances") from exc
    return {"service": service, "instance": instance.__dict__}
