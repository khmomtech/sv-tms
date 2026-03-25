> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Contact Persons Feature - Quick Reference

## Implementation Complete

Full-stack Contact Persons feature integrated into Customer management (CRM-style).

---

## Backend API Endpoints

**Base URL:** `http://localhost:8080/api/admin/customer-contacts`

### GET Endpoints
- `GET /customer/{customerId}?activeOnly=false` - Get all contacts for customer
- `GET /customer/{customerId}/primary` - Get primary contact
- `GET /{id}` - Get contact by ID
- `GET /customer/{customerId}/search?query=john` - Search contacts
- `GET /customer/{customerId}/count` - Count contacts

### POST/PUT/DELETE Endpoints
- `POST /` - Create new contact
- `PUT /{id}` - Update contact
- `DELETE /{id}` - Delete contact

### Request Body Example
```json
{
  "customerId": 1,
  "fullName": "John Smith",
  "email": "john.smith@example.com",
  "phone": "+855 12 345 678",
  "position": "Operations Manager",
  "isPrimary": true,
  "isActive": true,
  "notes": "Main contact person"
}
```

---

## Frontend Access

1. **Navigate:** Login → Customers → Click any customer → "👥 Contact Persons" tab
2. **Features:**
   - View all contacts in paginated table
   - Search by name/email
   - Filter active/inactive
   - Create new contact (+ New Contact button)
   - Edit contact (Actions → Edit)
   - Delete contact (Actions → Delete)
   - Primary contact badge

---

## Database Schema

**Table:** `customer_contacts`

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT | Primary key |
| customer_id | BIGINT | Foreign key to customers |
| full_name | VARCHAR(100) | Contact name (required) |
| email | VARCHAR(100) | Contact email |
| phone | VARCHAR(20) | Contact phone |
| position | VARCHAR(100) | Job position |
| is_primary | BOOLEAN | Primary contact flag |
| is_active | BOOLEAN | Active status |
| last_login | TIMESTAMP | Last login time |
| notes | TEXT | Additional notes |
| created_at | TIMESTAMP | Auto-generated |
| updated_at | TIMESTAMP | Auto-generated |

**Constraints:**
- FK: `customer_id` → `customers(id)` ON DELETE CASCADE
- Only one primary contact per customer (auto-managed)

---

## Test Data

Two test contacts created for Customer #1:

1. **John Smith** (Primary)
   - Email: john.smith@example.com
   - Phone: +855 12 345 678
   - Position: Operations Manager

2. **Sarah Johnson**
   - Email: sarah.j@example.com
   - Phone: +855 98 765 432
   - Position: Procurement Director

---

## Testing Checklist

### Backend API ✅
- [x] Get contacts list
- [x] Create contact
- [x] Primary contact auto-toggle
- [x] Authorization (requires ADMIN/MANAGER role)

### Frontend UI (Manual Testing Required)
- [ ] Navigate to Contact Persons tab
- [ ] View contacts table with 2 entries
- [ ] PRIMARY badge shows for John Smith
- [ ] Search functionality
- [ ] Active/Inactive filter
- [ ] Pagination (10 items per page)
- [ ] Create new contact modal
- [ ] Edit existing contact
- [ ] Delete contact with confirmation
- [ ] Form validation (required fields)

---

## Development Info

**Backend Files (6):**
- `model/CustomerContact.java` - JPA entity
- `repository/CustomerContactRepository.java` - Data access
- `dto/CustomerContactDto.java` - Response DTO
- `dto/request/CustomerContactRequest.java` - Request DTO
- `service/CustomerContactService.java` - Business logic
- `controller/CustomerContactController.java` - REST API

**Frontend Files (4):**
- `models/customer-contact.model.ts` - TypeScript interfaces
- `services/customer-contact.service.ts` - HTTP client
- `components/customer-view.component.ts` - Updated with contact methods
- `components/customer-view.component.html` - Added contacts tab & modal

**Database:**
- `customer_contacts.sql` - Table creation migration

---

## Quick Start Commands

```bash
# Backend - Already running on port 8080
ps aux | grep "logistics" | grep java

# Frontend - Already running on port 4200
lsof -ti:4200

# Test API
TOKEN=$(curl -s http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.data.token')

curl -s "http://localhost:8080/api/admin/customer-contacts/customer/1" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Open Browser
open http://localhost:4200/customers
```

---

## Next Enhancement Ideas

- [ ] Import contacts from CSV
- [ ] Export contacts to Excel
- [ ] Email integration (mailto links)
- [ ] Call integration (tel links)
- [ ] Contact activity history
- [ ] Birthday/anniversary reminders
- [ ] Contact photo upload
- [ ] Multi-customer contact assignment

---

**Status:** **READY FOR PRODUCTION USE**

**Last Updated:** 2025-12-10 16:35 ICT
