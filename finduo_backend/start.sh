#!/bin/bash
# Script de inicio para Railway
# Lee la variable PORT y ejecuta uvicorn

PORT=${PORT:-8000}
exec uvicorn app.main:app --host 0.0.0.0 --port $PORT

