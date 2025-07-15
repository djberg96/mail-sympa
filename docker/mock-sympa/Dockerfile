FROM python:3.9-slim

WORKDIR /app

# Install required Python packages
RUN pip install flask

# Copy the mock server
COPY docker/mock-sympa/simple_mock_server.py /app/
COPY docker/mock-sympa/start.sh /app/

RUN chmod +x /app/start.sh

EXPOSE 8080

CMD ["/app/start.sh"]
