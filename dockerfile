# Use a small Python base
FROM python:3.11-slim

# Prevent Python from writing .pyc files and buffering stdout
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create app dir
WORKDIR /app

# Install OS deps (build tools for some Py wheels), then clean
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker layer caching
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY . /app

# Cloud Run expects the server to listen on $PORT (default 8080)
ENV PORT=8080

# Use gunicorn to serve Flask app named "app" from app.py
# If your main file or app variable is named differently, adjust "app:app"
CMD exec gunicorn --bind 0.0.0.0:${PORT} --workers 2 --threads 4 --timeout 120 app:app
