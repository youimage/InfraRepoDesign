FROM node:18-alpine

WORKDIR /app

# Install global packages
RUN npm install -g nodemon

# Copy package files first for better caching
COPY package*.json ./
RUN npm install || npm init -y && npm install express pg dotenv

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1000 appuser && adduser -u 1000 -G appuser -s /bin/sh -D appuser
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 3000

CMD ["npm", "run", "dev"]