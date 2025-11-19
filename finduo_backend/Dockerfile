FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Hacer el script ejecutable
RUN chmod +x start.sh

# Railway inyecta PORT automáticamente
# Usamos el script start.sh para manejarlo correctamente
CMD ["./start.sh"]
