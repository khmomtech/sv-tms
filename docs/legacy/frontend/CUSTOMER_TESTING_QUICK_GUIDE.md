> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Customer Production Features - Quick Testing Guide

## Prerequisites

```bash
# 1. Ensure backend is running
curl http://localhost:8080/actuator/health

# 2. Get admin token
export TOKEN=$(curl -s http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.data.token')

echo "Token: $TOKEN"
```

---

## Test 1: Duplicate Detection (2 min)

### 1.1 Create Unique Customer
```bash
curl -X POST http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerCode": "UNIQUE001",
    "customerName": "Unique Test Company",
    "type": "COMPANY",
    "email": "unique@test.com",
    "phone": "+855111111111",
    "address": "123 Test St",
    "status": "ACTIVE"
  }'
```

**Expected**: `201 Created` with customer ID

### 1.2 Attempt Duplicate Code
```bash
curl -X POST http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerCode": "UNIQUE001",
    "customerName": "Different Company",
    "type": "COMPANY"
  }'
```

**Expected**: `400 Bad Request` with message like:
```json
{
  "status": 400,
  "message": "Duplicate customer found for field 'customerCode': UNIQUE001"
}
```

### 1.3 Attempt Duplicate Phone
```bash
curl -X POST http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerCode": "UNIQUE002",
    "customerName": "Another Company",
    "type": "COMPANY",
    "phone": "+855111111111"
  }'
```

**Expected**: `400 Bad Request` - duplicate phone detected

### 1.4 Attempt Duplicate Email
```bash
curl -X POST http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerCode": "UNIQUE003",
    "customerName": "Yet Another Company",
    "type": "COMPANY",
    "email": "unique@test.com"
  }'
```

**Expected**: `400 Bad Request` - duplicate email detected

**Pass Criteria**: All duplicates rejected with clear error messages

---

## Test 2: Soft Delete (3 min)

### 2.1 Create Test Customer
```bash
CUSTOMER_ID=$(curl -s -X POST http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerCode": "DELETE001",
    "customerName": "Will Be Deleted",
    "type": "COMPANY"
  }' | jq -r '.data.id')

echo "Created customer ID: $CUSTOMER_ID"
```

### 2.2 Verify Customer Exists
```bash
curl -X GET http://localhost:8080/api/admin/customers/$CUSTOMER_ID \
  -H "Authorization: Bearer $TOKEN"
```

**Expected**: Customer details returned

### 2.3 Delete Customer (Soft Delete)
```bash
curl -X DELETE http://localhost:8080/api/admin/customers/$CUSTOMER_ID \
  -H "Authorization: Bearer $TOKEN"
```

**Expected**: `200 OK` or `204 No Content`

### 2.4 Verify Not in List
```bash
curl -X GET "http://localhost:8080/api/admin/customers?page=0&size=100" \
  -H "Authorization: Bearer $TOKEN" | jq '.data.content[] | select(.id == '$CUSTOMER_ID')'
```

**Expected**: Empty output (customer not in active list)

### 2.5 Verify in Database (Still Exists)
```bash
docker exec svtms-mysql mysql -uroot -proot svlogistics_tms_db \
  -e "SELECT id, customer_code, deleted_at, deleted_by FROM customers WHERE id = $CUSTOMER_ID;"
```

**Expected**:
```
+----+--------------+---------------------+------------+
| id | customer_code| deleted_at          | deleted_by |
+----+--------------+---------------------+------------+
| XX | DELETE001    | 2025-12-10 10:15:23 | admin      |
+----+--------------+---------------------+------------+
```

**Pass Criteria**: 
- Customer not in API list
- Customer exists in database with deleted_at timestamp
- deleted_by = "admin"

---

## Test 3: Financial Fields (2 min)

### 3.1 Create Customer with Financial Data
```bash
FIN_ID=$(curl -s -X POST http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerCode": "FIN001",
    "customerName": "Financial Test Company",
    "type": "COMPANY",
    "creditLimit": 50000.00,
    "paymentTerms": "NET_30",
    "currency": "USD",
    "currentBalance": 15000.50,
    "lifecycleStage": "CUSTOMER",
    "segment": "VIP"
  }' | jq -r '.data.id')

echo "Created customer ID: $FIN_ID"
```

### 3.2 Fetch and Verify Fields
```bash
curl -s -X GET http://localhost:8080/api/admin/customers/$FIN_ID \
  -H "Authorization: Bearer $TOKEN" | jq '{
    creditLimit: .data.creditLimit,
    paymentTerms: .data.paymentTerms,
    currency: .data.currency,
    currentBalance: .data.currentBalance,
    lifecycleStage: .data.lifecycleStage,
    segment: .data.segment
  }'
```

**Expected Output**:
```json
{
  "creditLimit": 50000.00,
  "paymentTerms": "NET_30",
  "currency": "USD",
  "currentBalance": 15000.50,
  "lifecycleStage": "CUSTOMER",
  "segment": "VIP"
}
```

### 3.3 Update Financial Fields
```bash
curl -X PUT http://localhost:8080/api/admin/customers/$FIN_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "creditLimit": 75000.00,
    "currentBalance": 20000.00,
    "lifecycleStage": "AT_RISK"
  }'
```

### 3.4 Verify Update
```bash
curl -s -X GET http://localhost:8080/api/admin/customers/$FIN_ID \
  -H "Authorization: Bearer $TOKEN" | jq '{
    creditLimit: .data.creditLimit,
    currentBalance: .data.currentBalance,
    lifecycleStage: .data.lifecycleStage
  }'
```

**Expected**:
```json
{
  "creditLimit": 75000.00,
  "currentBalance": 20000.00,
  "lifecycleStage": "AT_RISK"
}
```

**Pass Criteria**: All financial fields stored and retrieved correctly

---

## Test 4: Audit Trail (3 min)

### 4.1 Create Customer (Generate CREATE Audit)
```bash
AUDIT_ID=$(curl -s -X POST http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerCode": "AUDIT001",
    "customerName": "Audit Test Company",
    "type": "COMPANY"
  }' | jq -r '.data.id')

echo "Created customer ID: $AUDIT_ID"
```

### 4.2 Update Customer (Generate UPDATE Audit)
```bash
curl -X PUT http://localhost:8080/api/admin/customers/$AUDIT_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerName": "Updated Audit Company",
    "lifecycleStage": "QUALIFIED"
  }'
```

### 4.3 Delete Customer (Generate DELETE Audit)
```bash
curl -X DELETE http://localhost:8080/api/admin/customers/$AUDIT_ID \
  -H "Authorization: Bearer $TOKEN"
```

### 4.4 Query Audit Trail
```bash
docker exec svtms-mysql mysql -uroot -proot svlogistics_tms_db \
  -e "SELECT customer_id, action, changed_by, changed_at, notes 
      FROM customer_audit 
      WHERE customer_id = $AUDIT_ID 
      ORDER BY changed_at DESC;"
```

**Expected Output**:
```
+-------------+--------+------------+---------------------+----------------------+
| customer_id | action | changed_by | changed_at          | notes                |
+-------------+--------+------------+---------------------+----------------------+
| XX          | DELETE | admin      | 2025-12-10 10:20:30 | Customer soft deleted|
| XX          | UPDATE | admin      | 2025-12-10 10:20:15 | Customer updated     |
| XX          | CREATE | admin      | 2025-12-10 10:20:00 | Customer created     |
+-------------+--------+------------+---------------------+----------------------+
```

**Pass Criteria**: 
- 3 audit records created (CREATE, UPDATE, DELETE)
- changed_by = "admin"
- Timestamps in correct chronological order

---

## Test 5: Lifecycle Stages (2 min)

### 5.1 Create Customer with Lifecycle Stage
```bash
curl -X POST http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerCode": "LIFECYCLE001",
    "customerName": "Lifecycle Test",
    "type": "COMPANY",
    "lifecycleStage": "LEAD"
  }'
```

### 5.2 Progress Through Stages
```bash
# LEAD → PROSPECT
curl -X PUT http://localhost:8080/api/admin/customers/$LIFECYCLE_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"lifecycleStage": "PROSPECT"}'

# PROSPECT → QUALIFIED
curl -X PUT http://localhost:8080/api/admin/customers/$LIFECYCLE_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"lifecycleStage": "QUALIFIED"}'

# QUALIFIED → CUSTOMER
curl -X PUT http://localhost:8080/api/admin/customers/$LIFECYCLE_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"lifecycleStage": "CUSTOMER"}'
```

### 5.3 Query Lifecycle Distribution
```bash
docker exec svtms-mysql mysql -uroot -proot svlogistics_tms_db \
  -e "SELECT lifecycle_stage, COUNT(*) as count 
      FROM customers 
      WHERE deleted_at IS NULL 
      GROUP BY lifecycle_stage;"
```

**Expected**:
```
+-----------------+-------+
| lifecycle_stage | count |
+-----------------+-------+
| LEAD            | 5     |
| PROSPECT        | 12    |
| QUALIFIED       | 8     |
| CUSTOMER        | 45    |
| AT_RISK         | 3     |
| DORMANT         | 2     |
+-----------------+-------+
```

**Pass Criteria**: Lifecycle stages stored and aggregated correctly

---

## Test 6: Performance Check (1 min)

### 6.1 Duplicate Detection Speed
```bash
time curl -X POST http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"customerCode": "UNIQUE001", "customerName": "Dup", "type": "COMPANY"}'
```

**Expected**: Response time < 100ms (duplicate detection optimized)

### 6.2 List Active Customers Speed
```bash
time curl -X GET "http://localhost:8080/api/admin/customers?page=0&size=20" \
  -H "Authorization: Bearer $TOKEN" > /dev/null
```

**Expected**: Response time < 200ms (with indexes)

---

## Full Automated Test Script

Save as `test-customer-improvements.sh`:

```bash
#!/bin/bash

# Customer Production Features - Automated Test Suite

BASE_URL="http://localhost:8080"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "=== Customer Production Features Test Suite ==="
echo ""

# Get token
echo "1. Authenticating..."
TOKEN=$(curl -s $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.data.token')

if [ "$TOKEN" == "null" ]; then
  echo -e "${RED}✗ Authentication failed${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Authentication successful${NC}"
echo ""

# Test 1: Duplicate Detection
echo "2. Testing duplicate detection..."
ID1=$(curl -s -X POST $BASE_URL/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"customerCode":"TEST001","customerName":"Test","type":"COMPANY","phone":"+855999999999","email":"test@dup.com"}' \
  | jq -r '.data.id')

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE_URL/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"customerCode":"TEST001","customerName":"Test2","type":"COMPANY"}')

if [ "$HTTP_CODE" == "400" ]; then
  echo -e "${GREEN}✓ Duplicate code detection working${NC}"
else
  echo -e "${RED}✗ Duplicate code detection failed (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Test 2: Soft Delete
echo "3. Testing soft delete..."
curl -s -X DELETE $BASE_URL/api/admin/customers/$ID1 \
  -H "Authorization: Bearer $TOKEN" > /dev/null

IN_DB=$(docker exec svtms-mysql mysql -uroot -proot svlogistics_tms_db \
  -se "SELECT COUNT(*) FROM customers WHERE id = $ID1 AND deleted_at IS NOT NULL;")

if [ "$IN_DB" == "1" ]; then
  echo -e "${GREEN}✓ Soft delete working (record preserved in DB)${NC}"
else
  echo -e "${RED}✗ Soft delete failed${NC}"
fi
echo ""

# Test 3: Financial Fields
echo "4. Testing financial fields..."
FIN_ID=$(curl -s -X POST $BASE_URL/api/admin/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"customerCode":"FIN001","customerName":"Fin","type":"COMPANY","creditLimit":50000,"paymentTerms":"NET_30"}' \
  | jq -r '.data.id')

CREDIT=$(curl -s -X GET $BASE_URL/api/admin/customers/$FIN_ID \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data.creditLimit')

if [ "$CREDIT" == "50000" ] || [ "$CREDIT" == "50000.0" ] || [ "$CREDIT" == "50000.00" ]; then
  echo -e "${GREEN}✓ Financial fields working${NC}"
else
  echo -e "${RED}✗ Financial fields failed (creditLimit = $CREDIT)${NC}"
fi
echo ""

# Test 4: Audit Trail
echo "5. Testing audit trail..."
AUDIT_COUNT=$(docker exec svtms-mysql mysql -uroot -proot svlogistics_tms_db \
  -se "SELECT COUNT(*) FROM customer_audit WHERE customer_id = $FIN_ID;")

if [ "$AUDIT_COUNT" -ge "1" ]; then
  echo -e "${GREEN}✓ Audit trail working ($AUDIT_COUNT records)${NC}"
else
  echo -e "${RED}✗ Audit trail failed${NC}"
fi
echo ""

echo "=== Test Suite Complete ==="
```

Make executable and run:
```bash
chmod +x test-customer-improvements.sh
./test-customer-improvements.sh
```

---

## Success Indicators

**All Tests Pass When**:
1. Duplicate detection returns 400 errors with clear messages
2. Soft-deleted customers not in API lists but exist in database
3. Financial fields stored and retrieved accurately
4. Audit trail records all CREATE, UPDATE, DELETE operations
5. Lifecycle stages transition correctly
6. Performance remains under 200ms for typical operations

---

## Troubleshooting

### Issue: Token Authentication Fails

**Check**:
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' -v
```

**Fix**: Verify backend is running and admin account exists

### Issue: Duplicate Detection Not Working

**Check database constraints**:
```bash
docker exec svtms-mysql mysql -uroot -proot svlogistics_tms_db \
  -e "SHOW INDEX FROM customers WHERE Key_name LIKE 'idx_%';"
```

**Expected**: Unique indexes on customer_code, phone, email

### Issue: Audit Trail Empty

**Check table exists**:
```bash
docker exec svtms-mysql mysql -uroot -proot svlogistics_tms_db \
  -e "SHOW TABLES LIKE 'customer_audit';"
```

**Check service logs**:
```bash
tail -f backend.log | grep -i audit
```

---

**Quick Test Time**: ~10 minutes total  
**Automated Test Time**: ~30 seconds  
**Prerequisites**: Backend running, MySQL accessible, jq installed
