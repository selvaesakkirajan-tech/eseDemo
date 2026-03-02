import os
import pytest

# Set dummy Cosmos DB env vars before any test imports main.py
# The actual CosmosClient is mocked in each test so these values are never used
os.environ.setdefault("COSMOS_ENDPOINT", "https://test-cosmos.documents.azure.com:443/")
os.environ.setdefault("COSMOS_KEY",      "dGVzdC1rZXktZm9yLXVuaXQtdGVzdHM=")
os.environ.setdefault("COSMOS_DATABASE",  "apidb")
os.environ.setdefault("COSMOS_CONTAINER", "users")
