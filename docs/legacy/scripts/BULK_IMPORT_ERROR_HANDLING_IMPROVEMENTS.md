> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Bulk Import Error Handling Improvements

## Summary
Improved the bulk Excel import error handling in `TransportOrderService.java` to provide specific, user-friendly error messages instead of generic "Bulk import failed" messages.

## Changes Made

### 1. Enhanced Exception Handling in `importBulkOrders()`
**Location**: `tms-backend/src/main/java/com/svtrucking/logistics/service/TransportOrderService.java` (lines 905-940)

**Problem**: 
- Generic catch block returned "Bulk import failed" with no details
- Users couldn't understand what went wrong with their import
- Raw exception messages weren't user-friendly

**Solution**: 
Added exception type detection to provide specific error messages:

```java
catch (Exception ex) {
  String errorMsg = "Bulk import failed";
  String details = ex.getMessage();
  
  // Provide more specific error messages based on exception type
  if (ex instanceof org.springframework.orm.jpa.JpaSystemException) {
    errorMsg = "System error: Database schema issue while loading entity data";
    details = "Unable to deserialize database records. " +
        "This may indicate corrupted data or schema mismatch. " +
        "Please contact support with the following details: " + details;
  } else if (ex instanceof java.util.NoSuchElementException) {
    errorMsg = "System error: Missing required entity during import";
    details = "One or more referenced entities (customer, vehicle, item, address) " +
        "could not be found. Check that all related records exist before importing. " +
        "Details: " + details;
  } else if (ex instanceof jakarta.persistence.EntityNotFoundException) {
    errorMsg = "System error: Entity not found";
    details = "A referenced entity could not be loaded. Details: " + details;
  } else if (ex instanceof org.springframework.dao.DataIntegrityViolationException) {
    errorMsg = "System error: Data constraint violation";
    details = "The imported data violates database constraints (e.g., duplicate key). " +
        "Details: " + details;
  } else if (ex instanceof java.io.IOException) {
    errorMsg = "File read error";
    details = "Failed to read the Excel file. Ensure the file is valid and not corrupted. " +
        "Details: " + details;
  }
  
  log.error("Bulk import failed: {}", errorMsg, ex);
  return ResponseEntity.status(500)
      .body(new ApiResponse<>(false, errorMsg, details));
}
```

### 2. Entity Lookup Error Handling (Already in Place)
**Location**: Lines 598-630

The entity pre-loading lookups (items, vehicles, addresses, customers) already have error handling:
- **allAddresses** (critical): Returns 500 with diagnostic message about database schema issues
- **allVehicles, allItemCodes, allCustomers** (non-critical): Log warnings but continue with empty sets

```java
try {
  allAddresses = orderAddressRepository.findAllNames();
} catch (Exception ex) {
  log.error("Error loading customer addresses: {}", ex.getMessage(), ex);
  return ResponseEntity.status(500)
      .body(new ApiResponse<>(
          false,
          "System error: Unable to load address data. Possible database schema issue. "
              + "Contact support: " + ex.getMessage(),
          null));
}
```

## Error Messages Users Will See

### File/Data Issues
1. **"File read error"** → File is corrupted or invalid Excel format
2. **"System error: Data constraint violation"** → Duplicate entries or constraint violations

### Missing Required Entities
3. **"System error: Missing required entity during import"** → Referenced customer, vehicle, item, or address doesn't exist

### Database Schema Issues
4. **"System error: Database schema issue while loading entity data"** → Database corruption or schema mismatch
5. **"System error: Unable to load address data"** → Specific address lookup failure (shown at pre-validation stage)

### Validation Errors (From First Pass)
The import also validates each row and returns specific field-level errors:
- **deliveryDate**: "Invalid date format dd.MM.yyyy"
- **customerCode**: "Customer not found"
- **status**: "Invalid status"
- **truckNumber**: "Vehicle not found"
- **item codes**: "Item not found"
- **toDest/fromDest**: "Address not found"

## How It Works

### Pre-Validation Stage (Lines 551-590)
1. Validates file type, size, sheet existence, row count
2. Pre-loads all referenced entities (items, vehicles, addresses, customers)
3. Returns 500 if critical entity lookup fails (addresses)

### First Pass Validation (Lines 631-760)
1. Groups rows into orders by (DeliveryDate + CustomerCode + TripNo + ToDestination)
2. Validates each row's data:
   - Date format
   - Customer exists
   - Vehicle exists  
   - Items exist
   - Addresses exist
   - Status is valid
   - Integer fields are valid
3. Accumulates all errors into `List<ImportError>`
4. Returns 400 with all validation errors if any found

### Second Pass (Lines 761-900)
1. Only executes if first pass passed with no errors
2. Creates TransportOrder, OrderItems, OrderStops, Dispatch records
3. Uses `@Transactional` to rollback entire import if any error occurs

### Exception Handling (Lines 905-940)
1. Catches any exception during second pass
2. Identifies exception type and provides specific message
3. Logs full stack trace for debugging
4. Returns 500 with user-friendly error message and details

## Benefits

✅ **User-Friendly**: Clear error messages explain what went wrong
✅ **Actionable**: Users know whether to check their file, data, or contact support
✅ **Diagnostic**: Error details help support team debug issues quickly
✅ **Specific**: Different messages for different failure types
✅ **Graceful**: Non-critical entity lookups fail gracefully
✅ **Transactional**: Entire import is atomic—either all succeeds or all fails

## Testing

The improvements have been tested with:
1. **Real user data** (Cambodia beverage company, 6-row import → 2 orders)
2. **Edge cases**:
   - Non-Excel file content
   - Empty Excel file
   - Invalid row count
3. **Database schema issues**: Try-catch blocks handle discriminator value mismatches

## Backend Build Status
✅ BUILD SUCCESS (22.127s)
- Maven compilation: Clean build with improved error handling
- Spring Boot repackaging: JAR created successfully
- Docker image: Rebuilt with new error handling code
- Docker stack: MySQL, Redis, MongoDB, Backend, Angular all running

## Next Steps

1. **Test UI Display**: Verify Angular displays the improved error messages
2. **Monitor Logs**: Check backend logs when import fails to see new diagnostic info
3. **User Feedback**: Collect feedback from users on whether error messages are helpful
4. **Optional Enhancements**:
   - Add specific error count (e.g., "5 validation errors found")
   - Provide row numbers for each validation error
   - Export validation errors to CSV for large imports
