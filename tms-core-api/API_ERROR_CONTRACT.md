# API Error Contract for Vehicle Endpoints

## Error Response Structure
All error responses from vehicle-related endpoints follow this structure:

```json
{
  "success": false,
  "message": "<Human-readable error message>",
  "code": "<ERROR_CODE>",
  "data": null,
  "errors": <field or system errors, optional>,
  "timestamp": "<ISO8601>",
  "requestId": "<UUID>"
}
```

## Common Error Codes
| Code                      | HTTP Status      | Description                                 |
|---------------------------|------------------|---------------------------------------------|
| DUPLICATE_LICENSE_PLATE   | 409 Conflict     | License plate already exists                |
| INVALID_VEHICLE_DATA      | 400 Bad Request  | Validation failed for one or more fields    |
| VEHICLE_NOT_FOUND         | 404 Not Found    | Vehicle does not exist                      |
| UNKNOWN_ERROR             | 400/500          | Unhandled or unexpected error               |

## Example: Duplicate License Plate
```json
{
  "success": false,
  "message": "Vehicle with license plate 'ABC123' already exists!",
  "code": "DUPLICATE_LICENSE_PLATE",
  "data": null,
  "errors": null,
  "timestamp": "2026-02-09T09:00:00Z",
  "requestId": "b1e2c3d4-5678-90ab-cdef-1234567890ab"
}
```

## Frontend Mapping
- The frontend checks the `code` field to map errors to specific fields (e.g., highlights `licensePlate` for `DUPLICATE_LICENSE_PLATE`).
- General errors are shown as alerts; field errors are shown inline.

## Versioning
- This contract is valid as of 2026-02-09. Any changes must be reflected here and in the OpenAPI spec.

---
For questions, contact the backend or frontend lead.
