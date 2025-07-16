FROM ruby:3.3-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy Gemfile and install Ruby dependencies
COPY docker/mock-sympa/Gemfile /app/
RUN bundle install

# Copy the mock server
COPY docker/mock-sympa/mock_server.rb /app/
COPY docker/mock-sympa/start.sh /app/

RUN chmod +x /app/start.sh

EXPOSE 8080

CMD ["/app/start.sh"]
