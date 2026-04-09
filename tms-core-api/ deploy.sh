#!/bin/bash

echo "==> Stopping previous containers..."
docker-compose -f docker-compose.prod.yml down

echo "==> Building new driver-app image..."
docker-compose -f docker-compose.prod.yml build

echo "==> Starting driver-app container..."
docker-compose -f docker-compose.prod.yml up -d

echo "==> Deployment Completed!"