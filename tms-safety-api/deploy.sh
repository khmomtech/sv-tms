#!/bin/bash

echo "==> Stopping previous containers..."
docker-compose -f docker-compose.prod.yml down

echo "==> Building new tms-safety-api image..."
docker-compose -f docker-compose.prod.yml build

echo "==> Starting tms-safety-api container..."
docker-compose -f docker-compose.prod.yml up -d

echo "==> Deployment Completed!"
