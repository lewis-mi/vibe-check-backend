# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Copy the dependencies file and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app's source code
COPY . .

# Get the port from the environment (Cloud Run sets this)
ENV PORT 8080

# Command to run the app using gunicorn (the production server)
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app