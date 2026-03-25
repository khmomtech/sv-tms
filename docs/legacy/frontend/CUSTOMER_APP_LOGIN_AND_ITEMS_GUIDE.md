> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 👤 Customer App - Login Account & Items Guide

## 🔐 Customer App Login

### How Customer Accounts Work

Customer app login accounts are created through the **Admin UI** or **Backend API**, then linked to customer records.

#### Step 1: Create Customer in Admin UI
1. Navigate to **Admin UI** → **Customers** → **+ New Customer**
2. Fill in customer details:
   - **Customer Code** (unique): e.g., `CUST001`, `ABC_CO_LTD`
   - **Name**: e.g., `ABC Trading Company`, `John Smith`
   - **Type**: `COMPANY` or `INDIVIDUAL`
   - **Email**: e.g., `info@abc-trading.com`
   - **Phone**: e.g., `+855-12-345-678`
   - **Address**: Delivery address
   - **Status**: `ACTIVE` or `INACTIVE`
   - **Credit Limit**: e.g., `100,000.00` (USD)
   - **Payment Terms**: `DUE_ON_RECEIPT`, `NET_30`, `NET_60`, etc.
   - **Currency**: `USD`
3. Click **Save**

#### Step 2: Create Login Account for Customer
1. In the customer list or customer detail page, click **Create Account** button
2. Fill in:
   - **Username**: User login identifier (e.g., `abc_trader`, `john_smith`)
   - **Email**: Login email (auto-filled from customer email, can change)
   - **Password**: Strong password (min 8 chars, mixed case, numbers/symbols)
3. Click **Create**
4. Backend creates a `User` record with `CUSTOMER` role and links to the customer

---

## 📱 Using Customer App with Test Account

### Test Login Credentials

You have multiple ways to test the customer app:

#### Option 1: Create a Test Customer (Recommended)

```bash
# 1. Start backend & admin UI
docker compose -f docker-compose.dev.yml up --build

# 2. Open Admin UI: http://localhost:4200
# 3. Go to: Customers → + New Customer
# Fill in:
#   - Customer Code: TEST_CUST_001
#   - Name: Test Customer Company
#   - Type: COMPANY
#   - Email: testcustomer@example.com
#   - Phone: +855-87-654-321
#   - Status: ACTIVE
#   - Credit Limit: 50000.00
#   - Payment Terms: NET_30
#   - Currency: USD
# 4. Click Save

# 5. In customer detail, click "Create Account":
#   - Username: testcustomer
#   - Email: testcustomer@example.com
#   - Password: TestPass@2024
# 6. Click Create

# 7. Now use these credentials in customer app:
#   Username: testcustomer
#   Password: TestPass@2024
```

#### Option 2: Via Backend API (cURL)

```bash
# Create customer
curl -X POST http://localhost:8080/api/admin/customers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -d '{
    "customerCode": "TEST_002",
    "customerName": "Demo Transport Ltd",
    "type": "COMPANY",
    "email": "demo@transco.com",
    "phone": "+855-99-123-456",
    "address": "123 Main St, Phnom Penh",
    "status": "ACTIVE",
    "creditLimit": 75000,
    "paymentTerms": "NET_60",
    "currency": "USD"
  }'

# Response includes customer id (e.g., "id": 123)

# Create login account for customer (id=123)
curl -X POST http://localhost:8080/api/admin/customers/123/account \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -d '{
    "username": "demo_transport",
    "email": "demo@transco.com",
    "password": "Demo@Pass123"
  }'

# Now use in customer app:
#   Username: demo_transport
#   Password: Demo@Pass123
```

#### Option 3: Seed from Database

If you have data migration files ready:

```bash
cd data/import

# Use customer import template
# Edit customers_import.csv with test data

# Import to database
mysql -u root -p svlogistics_tms < migration_customers.sql

# Then in Admin UI, create accounts for imported customers
```

---

## 📦 Items in the System

### What Are Items?

**Items** are cargo/goods that are transported in orders. They represent individual units of freight.

### Item Properties

```sql
-- Item Model (tms-backend/src/main/java/com/svtrucking/logistics/model/Item.java)
- item_code (unique): Identifier like "ITEM001", "BOX_A1"
- item_name: English name, e.g., "Fragile Glass Boxes"
- item_name_kh: Khmer name for multilingual support
- item_type: ELECTRONICS, FURNITURE, DOCUMENT, FOOD, etc. (enum ItemType)
- size: Dimensions, e.g., "30x20x10cm"
- weight: Weight, e.g., "5kg"
- unit: Measurement unit, e.g., "pieces", "boxes", "pallets"
- quantity: Number of items
- pallets: Pallet information
- pallet_type: Standard, Euro, Asia, Custom
- status: 1=Active, 0=Inactive
- sort_order: Display order
```

### Item Types Enum

```java
enum ItemType {
  ELECTRONICS,      // Electronic devices, gadgets
  FURNITURE,        // Chairs, tables, cabinets
  DOCUMENT,         // Papers, files, books
  FOOD,             // Perishables, groceries
  MACHINERY,        // Industrial equipment
  TEXTILE,          // Fabrics, clothing
  GLASS,            // Glassware, fragile items
  CHEMICAL,         // Hazardous materials
  AUTOMOTIVE,       // Car parts, vehicles
  RETAIL_GOODS,     // General retail merchandise
  OTHER             // Miscellaneous
}
```

---

## 🛍️ Viewing Items in Customer App

### Customer App Item Access

The customer app allows customers to:

1. **View their own orders** - GET `/api/customer/{customerId}/orders`
2. **See items in each order** - Items are included in TransportOrderDto
3. **Track delivery status** - Real-time updates on order progress

### Sample Item Data

Here's example item data linked to a customer order:

```json
{
  "id": 1,
  "itemCode": "ITEM001",
  "itemName": "Laptops (Dell XPS 13)",
  "itemNameKh": "ឡាប់ទॐប់",
  "itemType": "ELECTRONICS",
  "size": "30x20x2cm",
  "weight": "1.5kg",
  "unit": "pieces",
  "quantity": 10,
  "pallets": "1",
  "palletType": "Standard",
  "status": 1,
  "sortOrder": 1
}
```

### Backend Items Endpoint

**GET** `/api/items` - List all items (Admin UI)

```bash
curl -X GET http://localhost:8080/api/items \
  -H "Authorization: Bearer <TOKEN>"
```

**Response:**
```json
{
  "success": true,
  "message": "Items fetched",
  "data": [
    {
      "id": 1,
      "itemCode": "ITEM001",
      "itemName": "Laptops",
      "itemType": "ELECTRONICS",
      ...
    },
    {
      "id": 2,
      "itemCode": "ITEM002",
      "itemName": "Office Furniture",
      "itemType": "FURNITURE",
      ...
    }
  ]
}
```

---

## 📋 Sample Test Data

### Create Test Items (via Backend)

```bash
# Item 1: Electronics
curl -X POST http://localhost:8080/api/items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -d '{
    "itemCode": "ITEM001",
    "itemName": "Computer Monitors",
    "itemNameKh": "អេក្រង់គណនា",
    "itemType": "ELECTRONICS",
    "size": "50x30x5cm",
    "weight": "5kg",
    "unit": "pieces",
    "quantity": 20,
    "palletType": "Standard",
    "status": 1
  }'

# Item 2: Furniture
curl -X POST http://localhost:8080/api/items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -d '{
    "itemCode": "ITEM002",
    "itemName": "Office Chairs",
    "itemNameKh": "ក្រោះការិយាល័យ",
    "itemType": "FURNITURE",
    "size": "60x60x80cm",
    "weight": "10kg",
    "unit": "pieces",
    "quantity": 50,
    "palletType": "Standard",
    "status": 1
  }'

# Item 3: Documents
curl -X POST http://localhost:8080/api/items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -d '{
    "itemCode": "ITEM003",
    "itemName": "Contract Documents Package",
    "itemNameKh": "កញ្ចប់ឯកសារកិច្ចសន្យា",
    "itemType": "DOCUMENT",
    "size": "25x15x5cm",
    "weight": "1kg",
    "unit": "boxes",
    "quantity": 10,
    "palletType": "Standard",
    "status": 1
  }'
```

### Create Test Order with Items

```bash
# 1. First, create/get customer (e.g., id=123)
# 2. Create transport order

curl -X POST http://localhost:8080/api/transport-orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -d '{
    "customerId": 123,
    "originAddress": "123 Main St, Phnom Penh",
    "destinationAddress": "456 King St, Sihanoukville",
    "status": "PENDING",
    "items": [
      {
        "itemId": 1,
        "quantity": 5
      },
      {
        "itemId": 2,
        "quantity": 10
      }
    ]
  }'
```

---

## 🔄 Complete Workflow: From Customer Creation to Order Tracking

### Step-by-Step Flow

```
1. ADMIN CREATES CUSTOMER
   ├─ Admin UI → Customers → + New
   ├─ Fill: Code, Name, Type, Email, Phone, etc.
   └─ Save → Customer created (e.g., id=123)

2. ADMIN CREATES LOGIN ACCOUNT
   ├─ Customer Detail → Create Account
   ├─ Username: abc_company
   ├─ Email: abc@company.com
   ├─ Password: StrongPass@123
   └─ Save → User account linked to customer

3. CUSTOMER LOGS INTO APP
   ├─ Open Customer App
   ├─ Enter: Username "abc_company"
   ├─ Enter: Password "StrongPass@123"
   ├─ Login → Redirect to Orders Dashboard
   └─ Session: Token stored in FlutterSecureStorage

4. CUSTOMER VIEWS ORDERS
   ├─ App calls: GET /api/customer/123/orders
   ├─ Backend returns list of TransportOrderDto
   ├─ Each order includes:
   │  ├─ Order ID, status, origin, destination
   │  └─ Items array with quantities and types
   └─ Display orders in ListView

5. CUSTOMER VIEWS ORDER DETAIL
   ├─ Tap order → Call GET /api/customer/123/orders/{orderId}
   ├─ Shows:
   │  ├─ Full order info
   │  ├─ Items breakdown (what, how much, status)
   │  ├─ Pickup address
   │  ├─ Delivery address
   │  └─ Real-time tracking (if available)
   └─ WebSocket updates on status changes

6. REAL-TIME UPDATES
   ├─ Customer connected to WebSocket
   ├─ Driver app broadcasts status updates
   ├─ Customer receives live notifications
   └─ Order status updates automatically
```

---

## 📊 API Endpoints for Customer App

### Authentication
- **POST** `/api/auth/login` - Login with username/password
- **POST** `/api/auth/refresh` - Refresh access token
- **POST** `/api/auth/logout` - Logout

### Orders & Items
- **GET** `/api/customer/{customerId}/orders` - List customer's orders
- **GET** `/api/customer/{customerId}/orders/{orderId}` - Get order detail
- **GET** `/api/customer/{customerId}/addresses` - Get delivery addresses

### WebSocket
- **WS** `/ws?token={token}` - Connect to real-time updates
- **Subscribe**: `/user/queue/notifications` - Order status updates

---

## 🧪 Testing Customer App Locally

### Setup

```bash
# Terminal 1: Start backend
cd tms-backend
./mvnw spring-boot:run

# Terminal 2: Start MySQL & Redis (if using docker)
docker compose up -d mysql redis

# Terminal 3: Run customer app on Android emulator
cd tms_customer_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --flavor dev

# Or iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:8080 --flavor dev
```

### Test Flow

```bash
# 1. Create customer & account via cURL (see above)

# 2. In Customer App:
#    - Open app
#    - Enter username: testcustomer
#    - Enter password: TestPass@2024
#    - Tap Login
#    - See: Orders page with items

# 3. Verify backend logs show:
#    [INFO] Login successful for user: testcustomer
#    [INFO] WebSocket connected: user=123
#    [DEBUG] Orders fetched for customer: 123
```

---

## 📝 CSV Template for Bulk Customer Import

Use this to import multiple customers at once:

```csv
customer_code,name,type,email,phone,address,status,credit_limit,payment_terms,currency,lifecycle_stage
CUST001,ABC Trading Co,COMPANY,abc@company.com,+855-1-234567,123 Main St,ACTIVE,100000.00,NET_30,USD,CUSTOMER
CUST002,John Smith Import,INDIVIDUAL,john@example.com,+855-87-654321,456 King St,ACTIVE,50000.00,NET_15,USD,CUSTOMER
CUST003,Fresh Foods Ltd,COMPANY,sales@freshfoods.com,+855-12-345678,789 Market Ave,ACTIVE,75000.00,NET_60,USD,CUSTOMER
CUST004,Tech Supplies Inc,COMPANY,orders@techsupply.com,+855-11-111111,321 Tech Park,ACTIVE,200000.00,DUE_ON_RECEIPT,USD,PROSPECT
```

Then import:

```bash
cd data/import
# Edit customers_import.csv with your data
mysql -u root -p svlogistics_tms < migration_customers.sql
```

---

## 🔐 Security Notes

### Password Requirements
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number or special character
- Example: `MyPassword@123`

### Access Control
- Customer can only see **their own orders**
- Admin/Dispatcher can see all orders
- WebSocket connection requires valid JWT token
- All API calls include Bearer token in Authorization header

### Token Storage
- **Android**: FlutterSecureStorage (encrypted on disk)
- **iOS**: Keychain (system secure storage)
- Tokens auto-refreshed when expired
- Logout clears all stored credentials

---

## 🆘 Troubleshooting

### Customer App Won't Login

**Problem**: `Connection refused` or `No route to host`

**Solution**:
- Android emulator: Use `10.0.2.2:8080` not `localhost`
- iOS simulator: Use `localhost:8080`
- Check backend is running: `curl http://localhost:8080/health`

### Login Error: "Invalid credentials"

**Problem**: Username or password incorrect

**Solution**:
- Verify customer account was created in Admin UI
- Check username is correct (case-sensitive)
- Reset password via Admin UI if forgotten

### Orders Not Showing in App

**Problem**: Empty orders list after login

**Solution**:
- Check if customer has any orders in database
- In Admin UI, create test order for customer
- Verify customer ID matches in database: 
  ```sql
  SELECT id, customer_code, user_id FROM customers WHERE customer_code='TEST_CUST_001';
  ```

### WebSocket Not Connecting

**Problem**: Real-time updates not working

**Solution**:
- Backend logs should show: `WebSocket client connected`
- Check firewall allows WebSocket (port 8080)
- Token might be expired, try logout/login again

---

## ✅ Quick Checklist

- [ ] Backend running on `localhost:8080`
- [ ] MySQL has `svlogistics_tms` database
- [ ] Customer created in Admin UI with status=ACTIVE
- [ ] Login account created for customer
- [ ] Customer app has correct API_BASE_URL
- [ ] Test login with customer credentials
- [ ] Orders visible in app (or create test orders)
- [ ] Real-time updates working (check WebSocket in browser DevTools)

---

## 📚 Related Documentation

- [COMPLETE_IMPORT_GUIDE.md](./data/import/COMPLETE_IMPORT_GUIDE.md) - Customer import tools
- [tms_customer_app/.github/copilot-instructions.md](./tms_customer_app/.github/copilot-instructions.md) - Customer app architecture
- [tms-backend/.github/copilot-instructions.md](./tms-backend/.github/copilot-instructions.md) - Backend API details
- Backend OpenAPI: http://localhost:8080/v3/api-docs

---

**Last Updated**: 2026-01-22  
**Status**: ✅ Production Ready
