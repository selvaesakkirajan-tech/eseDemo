import os
import secrets
from fastapi import FastAPI, HTTPException, Query, Depends
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from typing import Optional
from azure.cosmos import CosmosClient, exceptions as cosmos_exceptions
from passlib.context import CryptContext

app = FastAPI(title="eseDemo API")
security = HTTPBasic()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Cosmos DB connection (set via environment variables)
COSMOS_ENDPOINT = os.environ.get("COSMOS_ENDPOINT", "")
COSMOS_KEY      = os.environ.get("COSMOS_KEY", "")
COSMOS_DATABASE = os.environ.get("COSMOS_DATABASE", "apidb")
COSMOS_CONTAINER = os.environ.get("COSMOS_CONTAINER", "users")


def get_cosmos_client():
    if not COSMOS_ENDPOINT or not COSMOS_KEY:
        raise HTTPException(status_code=503, detail="Database not configured")
    return CosmosClient(COSMOS_ENDPOINT, credential=COSMOS_KEY)


def verify_credentials(credentials: HTTPBasicCredentials = Depends(security)):
    """Verify username/password against Cosmos DB users container."""
    try:
        client = get_cosmos_client()
        database = client.get_database_client(COSMOS_DATABASE)
        container = database.get_container_client(COSMOS_CONTAINER)

        # Query for user by username
        query = "SELECT * FROM c WHERE c.username = @username"
        params = [{"name": "@username", "value": credentials.username}]
        items = list(container.query_items(query=query, parameters=params, enable_cross_partition_query=True))

        if not items:
            raise HTTPException(status_code=401, detail="Invalid credentials",
                                headers={"WWW-Authenticate": "Basic"})

        user = items[0]

        # Constant-time bcrypt verify (prevents timing attacks)
        if not pwd_context.verify(credentials.password, user["password_hash"]):
            raise HTTPException(status_code=401, detail="Invalid credentials",
                                headers={"WWW-Authenticate": "Basic"})

        if not user.get("active", True):
            raise HTTPException(status_code=403, detail="Account disabled",
                                headers={"WWW-Authenticate": "Basic"})

        return credentials.username

    except HTTPException:
        raise
    except cosmos_exceptions.CosmosHttpResponseError as e:
        raise HTTPException(status_code=503, detail=f"Database error: {e.message}")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/")
def root():
    return {"status": "ok", "message": "eseDemo API"}


@app.get("/sum")
def sum_query(
    a: Optional[float] = Query(None),
    b: Optional[float] = Query(None),
    expr: Optional[str] = None,
    username: str = Depends(verify_credentials)
):
    if expr:
        try:
            tokens = expr.replace(' ', '').split('+')
            if len(tokens) != 2:
                raise ValueError("Use format a+b")
            a_val, b_val = float(tokens[0]), float(tokens[1])
            return {"sum": a_val + b_val, "requested_by": username}
        except Exception as ex:
            raise HTTPException(status_code=400, detail=f"Invalid expr: {ex}")
    if a is None or b is None:
        raise HTTPException(status_code=400, detail="Provide a and b or expr")
    return {"sum": a + b, "requested_by": username}


@app.get("/sum/{a}/{b}")
def sum_path(
    a: float,
    b: float,
    username: str = Depends(verify_credentials)
):
    return {"sum": a + b, "requested_by": username}
