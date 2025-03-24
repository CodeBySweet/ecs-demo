# Stage 1: Build the application
FROM python:3.9-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy only the requirements file first to optimize caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY app ./app
COPY quotes.json .
COPY app/static ./app/static
COPY app/templates ./app/templates

# Stage 2: Create the final lightweight image
FROM python:3.9-alpine

# Set the working directory
WORKDIR /app

# Copy only necessary files from the builder stage
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /app /app

# Create a non-root user and switch to it
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the application port
EXPOSE 5000

# Command to run the application
CMD ["python", "app/app.py"]