#!/usr/bin/env bash
set -euo pipefail

# Usage: ./infra/build-backend.sh [image-tag]
# Builds the backend jar with the Maven wrapper and builds a Docker image.

TAG=${1:-latest}
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/tms-backend"
IMAGE_NAME="sv-tms/backend:${TAG}"

echo "Building backend in ${BACKEND_DIR}"
cd "$BACKEND_DIR"

if [ ! -x ./mvnw ]; then
  echo "Maven wrapper not executable, setting +x"
  chmod +x ./mvnw || true
fi

./mvnw clean package -DskipTests

echo "Building Docker image ${IMAGE_NAME}"
# Assume Dockerfile exists in tms-backend root
docker build -t "$IMAGE_NAME" .

echo "Built ${IMAGE_NAME}"

echo "Done. To push: docker tag ${IMAGE_NAME} <registry>/${IMAGE_NAME} && docker push <registry>/${IMAGE_NAME}"
