> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Code Migration Report: Orders Table Consolidation

## Executive Summary

The database has been consolidated to use the `transport_orders` model exclusively. The backend codebase contains artifacts from the old `orders` table that need updating or removal.

---

## Code Inventory

### Currently Using `orders` Table

#### 1. **Entity Model** (NEEDS UPDATE)

- **File:** `tms-backend/src/main/java/com/svtrucking/logistics/model/Order.java`
- **Status:** ⚠️ Still mapped to `@Table(name = "orders")`
- **Impact:** JPA entity is linked to dropped table
- **Action:** Migrate to `TransportOrder` entity or delete if unused

#### 2. **Repository Layer** (NEEDS UPDATE)

- **File:** `tms-backend/src/main/java/com/svtrucking/logistics/repository/OrderRepository.java`
- **Status:** ⚠️ Extends `JpaRepository<Order, Long>`
- **Methods:**
  - `findByStatus(OrderStatus status)`
  - `findByCustomerNameContainingIgnoreCase(String customerName, Pageable pageable)`
  - `findByStatus(OrderStatus status, Pageable pageable)`
  - `findByCustomerNameContainingIgnoreCaseAndStatus(String customerName, OrderStatus status, Pageable pageable)`
- **Impact:** Queries target dropped table
- **Action:** Migrate to `TransportOrderRepository` if needed, or deprecate

#### 3. **Service Layer** (NEEDS UPDATE)

- **File:** `tms-backend/src/main/java/com/svtrucking/logistics/service/OrderService.java`
- **Status:** ⚠️ Service still operational but using old entity
- **Methods:**
  - `getAllOrders(Pageable pageable)`
  - `getOrderById(Long orderId)`
  - `searchOrders(String customerName, OrderStatus status, Pageable pageable)`
  - `addOrder(Order order)`
  - `updateOrder(Long orderId, Order updatedOrder)`
  - `updateOrderStatus(Long orderId, OrderStatus status)`
- **Impact:** Runtime errors when called (table doesn't exist)
- **Action:** Deprecate or migrate to `TransportOrderService`

### Already Using `transport_orders` Table ✅

#### Controllers Using TransportOrderService (GOOD)

- `CustomerPublicController`
  - Uses `TransportOrderService`
  - Retrieves orders with `transportOrderService.findByCustomerId()`
  - Gets specific order: `transportOrderService.getOrderById(orderId)`

#### Service Layer ✅

- `TransportOrderService` - Already implemented and active

#### Repository Layer ✅

- `TransportOrderRepository` - Already implemented

---

## Migration Action Items

### PRIORITY 1: Delete Unused Classes (Safe)

Since the code is already using `TransportOrderService`, these can be safely removed:

```bash
rm tms-backend/src/main/java/com/svtrucking/logistics/model/Order.java
rm tms-backend/src/main/java/com/svtrucking/logistics/repository/OrderRepository.java
rm tms-backend/src/main/java/com/svtrucking/logistics/service/OrderService.java
```

**Verification:** Run tests to confirm no code depends on these classes

```bash
cd tms-backend
./mvnw test
```

### PRIORITY 2: Find Any Hidden References

Search for any remaining references to `Order` entity or `OrderService`:

```bash
# Search for Order entity imports
grep -r "import.*model.Order" tms-backend/src/

# Search for OrderService imports
grep -r "import.*service.OrderService" tms-backend/src/

# Search for OrderRepository imports
grep -r "import.*repository.OrderRepository" tms-backend/src/

# Search for usage in tests
grep -r "OrderRepository\|OrderService\|\.Order" tms-backend/src/test/

# Search in SQL files
find tms-backend -name "*.sql" -exec grep -l "orders" {} \;
```

### PRIORITY 3: Check Database Migrations

Verify Flyway migrations don't reference the dropped `orders` table:

```bash
# List all migration files
ls -la tms-backend/src/main/resources/db/migration/

# Search for orders table references
grep -r "orders" tms-backend/src/main/resources/db/migration/
```

**Expected:** After schema consolidation, `orders` table doesn't exist, so migrations should reflect this.

---

## Current Code Status

### ✅ GREEN (No Action Needed)

- `TransportOrderService` - Already migrated
- `TransportOrderRepository` - Already migrated
- `TransportOrder` entity - Using correct table
- `CustomerPublicController` - Already using new model

### 🟡 YELLOW (Review Recommended)

- `CustomerActivityService` - Line 92: Comment mentions "mock - should query from orders"
  - **Fix:** Update comment or implement with `transport_orders`

### 🔴 RED (Must Fix Before Deployment)

- `Order` entity (`@Table(name = "orders")`) - Table doesn't exist
- `OrderRepository` - Queries non-existent table
- `OrderService` - Runtime errors if called

---

## Schema Mapping for Reference

If ANY code needs to migrate from old to new structure:

| Old (orders)        | New (transport_orders)        | Notes                          |
| ------------------- | ----------------------------- | ------------------------------ |
| `id`                | `id`                          | Same                           |
| `order_number`      | `order_reference`             | Renamed column                 |
| `customer_name`     | `customer_id` (FK)            | Now references customers table |
| `pickup_address`    | `order_stops` (type='PICKUP') | Normalized                     |
| `delivery_address`  | `order_stops` (type='DROP')   | Normalized                     |
| `assigned_driver`   | `courier_assigned`            | Different column name          |
| `assigned_vehicle`  | Use `dispatch` table          | Moved to dispatch              |
| `status`            | `status`                      | Same enum values               |
| `created_at`        | `created_at`                  | Same                           |
| `proof_of_delivery` | `order_stops.proof_image_url` | Normalized                     |

---

## Testing Checklist

After removing old classes:

- [ ] Unit tests pass: `./mvnw test`
- [ ] Integration tests pass: `./mvnw verify`
- [ ] Backend compiles: `./mvnw clean package`
- [ ] No ImportError for `Order`, `OrderService`, `OrderRepository`
- [ ] Verify `TransportOrderService` still works
- [ ] Test API endpoints that use orders
- [ ] Check logs for any runtime errors referencing `orders` table

---

## Deployment Steps

### Step 1: Verify Database State

```sql
-- Confirm orders table is gone
SELECT COUNT(*) FROM information_schema.TABLES
WHERE TABLE_NAME='orders' AND TABLE_SCHEMA='svlogistics_tms_db';
-- Should return: 0
```

### Step 2: Clean Backend Code

```bash
cd tms-backend
rm src/main/java/com/svtrucking/logistics/model/Order.java
rm src/main/java/com/svtrucking/logistics/repository/OrderRepository.java
rm src/main/java/com/svtrucking/logistics/service/OrderService.java
```

### Step 3: Compile and Test

```bash
./mvnw clean package
```

### Step 4: Deploy

```bash
docker compose up --build
```

### Step 5: Verify

```bash
# Check logs for errors
docker logs svtms-backend

# Test API
curl http://localhost:8080/api/admin/dashboard
```

---

## Rollback Plan (If Issues Found)

If deployment fails:

1. **Restore database:**

   ```sql
   -- If you still have backups
   CREATE TABLE orders LIKE transport_orders;
   -- Re-populate from backups if needed
   ```

2. **Restore code:**

   ```bash
   git checkout HEAD -- tms-backend/
   ```

3. **Rebuild:**
   ```bash
   ./mvnw clean package
   docker compose up --build
   ```

---

## Files Generated

1. **CODE_MIGRATION_REPORT.md** - This report
2. **orders_consolidation_migration.sql** - Database migration script
3. **ORDERS_CONSOLIDATION_COMPLETE.md** - Database consolidation summary

---

## Next Steps

### Immediate (Today)

1. Search codebase for any hidden references to old classes
2. Run tests to verify nothing breaks
3. Remove old classes if tests pass

### Before Deployment (This Sprint)

1. Review changes in code review
2. Update documentation/API specs
3. Test in staging environment
4. Deploy to production

### After Deployment (Monitoring)

1. Monitor application logs for errors
2. Verify API endpoints still working
3. Confirm no runtime exceptions
4. Clean up backup tables after 24-48 hours

---

## Questions & Clarifications

**Q:** Can we keep `Order` class for backwards compatibility?  
**A:** Not recommended - it's mapped to a non-existent table and will cause runtime errors.

**Q:** Do we need to update the Angular frontend?  
**A:** Check if frontend references `/api/orders` endpoint. If so, verify it's mapped to TransportOrderService.

**Q:** Should we keep backup tables?  
**A:** Yes, for 24-48 hours. Delete after confirming no issues.
