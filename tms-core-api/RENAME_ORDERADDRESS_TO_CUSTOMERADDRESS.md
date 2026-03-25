Rename plan: OrderAddress -> CustomerAddress
=========================================

Summary
-------
The database table has been migrated from `order_addresses` -> `customer_addresses` (see
`src/main/resources/db/migration/V20260121__rename_order_addresses_to_customer_addresses.sql`). The Java symbol
`OrderAddress` still exists and maps to `customer_addresses` via `@Table(name = "customer_addresses")`.

Recommended safe refactor steps
--------------------------------
1. Rename Java symbols and filenames:
   - `OrderAddress` -> `CustomerAddress` (file: `model/CustomerAddress.java`)
   - `OrderAddressDto` -> `CustomerAddressDto`
   - `OrderAddressRepository` -> `CustomerAddressRepository`
   - `OrderAddressService` -> `CustomerAddressService`
   - `OrderAddressExcelService` -> `CustomerAddressExcelService`
   - controller/mapper/test symbols accordingly
2. Run annotation-processor rebuild:

```bash
./mvnw clean package
```

3. Run unit/integration tests and fix any compile issues.
4. Regenerate OpenAPI spec and update frontend/mobile clients.

Notes / Risks
------------
- This is a cross-cutting rename; run the full test suite.
- Keep field/JSON property names unchanged to avoid breaking API consumers.

If you want me to perform the automated rename and compile, reply `do refactor` and I'll proceed.
