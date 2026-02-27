from fastapi import FastAPI, HTTPException, Query
from typing import Optional

app = FastAPI(title="eseDemo API")

@app.get("/sum")
def sum_query(a: Optional[float] = Query(None), b: Optional[float] = Query(None), expr: Optional[str] = None):
    if expr:
        try:
            tokens = expr.replace(' ', '').split('+')
            if len(tokens) != 2:
                raise ValueError("Use format a+b")
            a_val, b_val = float(tokens[0]), float(tokens[1])
            return {"sum": a_val + b_val}
        except Exception as ex:
            raise HTTPException(status_code=400, detail=f"Invalid expr: {ex}")
    if a is None or b is None:
        raise HTTPException(status_code=400, detail="Provide a and b or expr")
    return {"sum": a + b}

@app.get("/sum/{a}/{b}")
def sum_path(a: float, b: float):
    return {"sum": a + b}