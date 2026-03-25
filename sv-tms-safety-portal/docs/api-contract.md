# API Contract (expected endpoints)

Base URL: `API_BASE_URL` environmental variable

Auth

- POST /auth/login -> { token, refreshToken?, user, roles }
- POST /auth/refresh -> { token }
- GET /auth/me -> user

Safety

- GET /safety/categories
- POST /safety/categories
- PUT /safety/categories/{id}
- DELETE /safety/categories/{id}

- GET /safety/items
- POST /safety/items
- PUT /safety/items/{id}
- DELETE /safety/items/{id}

- GET /safety/checks
- GET /safety/checks/{checkId}
- GET /safety/checks/{checkId}/pdf
- GET /safety/checks/export

- GET /safety/issues
- GET /safety/issues/{issueId}
- PUT /safety/issues/{issueId}

- GET /safety/vehicles/status
- GET /safety/vehicles/{vehicleId}/history
- PUT /safety/vehicles/{vehicleId}/block
- PUT /safety/vehicles/{vehicleId}/unblock

Overrides

- GET /safety/overrides
- POST /safety/overrides
- PUT /safety/overrides/{overrideId}/revoke

Uploads

- POST /files/upload (multipart) -> { url }

Maintenance (optional)

- POST /maintenance/requests

Notes: implement an adapter layer `ApiService` so endpoints can be remapped if backend differs.
