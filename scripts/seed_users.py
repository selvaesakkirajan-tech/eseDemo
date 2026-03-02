"""
seed_users.py - Seeds initial users into Cosmos DB users container.

Usage:
    pip install azure-cosmos passlib[bcrypt]
    
    # Set env vars first:
    set COSMOS_ENDPOINT=https://<account>.documents.azure.com:443/
    set COSMOS_KEY=<primary-key>
    
    python scripts/seed_users.py

Users seeded:
    admin  / Admin@123
    kani   / 123
    sai    / 123
    san    / 123
"""

import os
import sys
from datetime import datetime, UTC
from passlib.context import CryptContext
from azure.cosmos import CosmosClient, exceptions as cosmos_exceptions

# ── Config ────────────────────────────────────────────────────────────────────
COSMOS_ENDPOINT  = os.environ.get("COSMOS_ENDPOINT", "")
COSMOS_KEY       = os.environ.get("COSMOS_KEY", "")
COSMOS_DATABASE  = os.environ.get("COSMOS_DATABASE",  "apidb")
COSMOS_CONTAINER = os.environ.get("COSMOS_CONTAINER", "users")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ── Users to seed ─────────────────────────────────────────────────────────────
# Passwords are hashed with bcrypt - plain text is NEVER stored
USERS = [
    {"username": "admin", "password": "Admin@123"},
    {"username": "kani",  "password": "123"},
    {"username": "sai",   "password": "123"},
    {"username": "san",   "password": "123"},
]


def build_user_doc(username: str, password: str) -> dict:
    return {
        "id":            username,
        "username":      username,
        "password_hash": pwd_context.hash(password),   # bcrypt encrypted
        "active":        True,
        "created_at":    datetime.now(UTC).isoformat(),
    }


def main():
    if not COSMOS_ENDPOINT or not COSMOS_KEY:
        print("ERROR: Set COSMOS_ENDPOINT and COSMOS_KEY environment variables first.")
        print("  set COSMOS_ENDPOINT=https://<account>.documents.azure.com:443/")
        print("  set COSMOS_KEY=<primary-key>")
        sys.exit(1)

    print(f"Connecting to Cosmos DB: {COSMOS_ENDPOINT}")
    client    = CosmosClient(COSMOS_ENDPOINT, credential=COSMOS_KEY)
    database  = client.get_database_client(COSMOS_DATABASE)
    container = database.get_container_client(COSMOS_CONTAINER)

    print(f"Seeding {len(USERS)} users into '{COSMOS_DATABASE}/{COSMOS_CONTAINER}'...\n")

    for user in USERS:
        doc = build_user_doc(user["username"], user["password"])
        try:
            container.upsert_item(doc)   # upsert = insert or update if exists
            print(f"  [OK] {doc['username']}  (password stored as bcrypt hash)")
        except cosmos_exceptions.CosmosHttpResponseError as e:
            print(f"  [FAIL] {doc['username']}: {e.message}")

    print("\nDone. Plain-text passwords are NOT stored anywhere.")
    print("Verify in Azure Portal → Cosmos DB → Data Explorer → apidb → users")


if __name__ == "__main__":
    main()
