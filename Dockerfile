FROM python:3.12-slim

WORKDIR /app

# Copiar requirements.txt desde finduo_backend
COPY finduo_backend/requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar todo el contenido de finduo_backend
COPY finduo_backend/ .

# Hacer el script ejecutable
RUN chmod +x start.sh

# Railway inyecta PORT automáticamente
# Usamos el script start.sh para manejarlo correctamente
CMD ["./start.sh"]

