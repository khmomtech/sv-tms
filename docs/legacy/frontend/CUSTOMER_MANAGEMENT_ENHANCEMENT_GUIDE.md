> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Customer Management Enhancement - Complete Implementation Guide

## 🎯 Overview

This implementation transforms the TMS customer management system to enterprise-level capabilities matching **Salesforce**, **HubSpot**, and **Gainsight** best practices.

### Key Features Implemented:
1. **Activity Timeline** (Salesforce-style) - Complete interaction history
2. **Customer Segmentation** (HubSpot-style) - Tag-based organization  
3. **Health Scoring** (Gainsight-style) - 0-100 automated scoring
4. **Advanced Analytics** - 15+ business metrics and insights

---

## 📦 Files Created/Modified

### **Backend (Java Spring Boot)**

#### New Files (10):
1. `ActivityType.java` - Enum with 11 activity types
2. `CustomerActivity.java` - JPA entity with JSON metadata
3. `CustomerActivityRepository.java` - Data access with pagination
4. `CustomerActivityDto.java` - API transfer object
5. `CustomerInsightsDto.java` - Analytics data structure
6. `CustomerHealthScoreDto.java` - Health scoring DTO
7. `CustomerActivityService.java` - Business logic (180 lines)
8. `CustomerActivityController.java` - REST endpoints (5 endpoints)
9. `V341__create_customer_activities.sql` - Database migration
10. (Modified) `Customer.java` - Added tags, segment, healthScore fields

#### Migration File Content:
```sql
-- Creates customer_activities table with:
--   - JSON metadata column for flexible data
--   - Indexes on customer_id + created_at
--   - Foreign key cascade delete
--
-- Enhances customers table with:
--   - tags (JSON array)
--   - customer_segment (VARCHAR(20))
--   - health_score (INT 0-100)
--   - first_order_date, last_order_date
```

### **Frontend (Angular 18 + TypeScript)**

#### New Files (2):
1. `customer-activity.model.ts` (65 lines) - TypeScript interfaces
2. `customer-activity.service.ts` (139 lines) - API client with 10 methods

#### Modified Files (3):
1. `customer.model.ts` - Added tags[], customerSegment, healthScore
2. `customer.component.ts` (+230 lines) - Tag management, segment filtering
3. `customer-view.component.ts` (+200 lines) - Activity timeline, insights sidebar
4. `customer-view.component.html` (+150 lines) - Timeline UI, activity modal

---

## 🔌 API Endpoints

### Customer Activity Controller

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/admin/customers/{id}/activities` | Get paginated timeline | ADMIN, DISPATCHER |
| POST | `/api/admin/customers/{id}/activities` | Create activity | ADMIN, DISPATCHER |
| DELETE | `/api/admin/customers/{id}/activities/{activityId}` | Delete activity | ADMIN, DISPATCHER |
| GET | `/api/admin/customers/{id}/health-score` | Get health score (0-100) | ADMIN, DISPATCHER |
| GET | `/api/admin/customers/{id}/insights` | Get analytics | ADMIN, DISPATCHER |

### Request/Response Examples

#### Create Activity:
```json
POST /api/admin/customers/123/activities
{
  "type": "CALL",
  "title": "Follow-up on pending shipment",
  "description": "Discussed delivery timeline with customer",
  "metadata": {
    "duration": 15,
    "outcome": "SCHEDULED",
    "nextAction": "Send confirmation email"
  }
}
```

#### Health Score Response:
```json
{
  "customerId": 123,
  "score": 78,
  "status": "GOOD",
  "factors": {
    "orderFrequency": 85,
    "revenueGrowth": 72,
    "paymentPunctuality": 100,
    "engagementLevel": 65,
    "recency": 90
  },
  "lastCalculated": "2025-01-09T10:30:00",
  "recommendations": [
    "Revenue potential - suggest upselling opportunities"
  ]
}
```

---

## 💡 Health Score Algorithm

### Calculation Formula (Weighted Average):

```
Total Score = (orderFrequency × 0.25) + 
              (revenueGrowth × 0.25) + 
              (paymentPunctuality × 0.20) + 
              (engagementLevel × 0.15) + 
              (recency × 0.15)
```

### Factor Scoring:

**Order Frequency (25% weight):**
- 100 = 50+ orders
- 80 = 25-49 orders
- 60 = 10-24 orders
- 40 = 5-9 orders
- 20 = 1-4 orders

**Revenue Growth (25% weight):**
- 100 = $100K+ total revenue
- 80 = $50K-$99K
- 60 = $20K-$49K
- 40 = $10K-$19K
- 20 = <$10K

**Payment Punctuality (20% weight):**
- Currently defaults to 100 (implement with payment records)

**Engagement Level (15% weight):**
- 100 = 20+ activities
- 80 = 10-19 activities
- 60 = 5-9 activities
- 40 = 2-4 activities
- 20 = 1 activity

**Recency (15% weight):**
- 100 = Order in last 7 days
- 80 = Last 8-30 days
- 60 = Last 31-60 days
- 40 = Last 61-90 days
- 20 = 90+ days

### Status Mapping:
- **EXCELLENT** (80-100) - Green indicator
- **GOOD** (60-79) - Blue indicator
- **FAIR** (40-59) - Yellow indicator
- **POOR** (20-39) - Orange indicator
- **AT_RISK** (0-19) - Red indicator

---

## 🏗️ Database Schema

### customer_activities Table:
```sql
CREATE TABLE customer_activities (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT NOT NULL,
  type VARCHAR(50) NOT NULL,           -- ActivityType enum
  title VARCHAR(255) NOT NULL,
  description TEXT,
  metadata JSON,                       -- Flexible additional data
  related_entity_id BIGINT,           -- Link to order/case/etc
  related_entity_type VARCHAR(50),
  created_by VARCHAR(100),
  created_by_name VARCHAR(100),
  created_at DATETIME NOT NULL,
  updated_at DATETIME,
  
  INDEX idx_customer_created (customer_id, created_at DESC),
  INDEX idx_activity_type (type),
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
```

### customers Table Enhancements:
```sql
ALTER TABLE customers ADD COLUMN (
  tags JSON,                    -- ["VIP", "Wholesale", "Premium"]
  customer_segment VARCHAR(20), -- VIP|REGULAR|HIGH_VALUE|AT_RISK|NEW|DORMANT
  health_score INT,            -- 0-100
  first_order_date DATE,
  last_order_date DATE
);
```

---

## 🎨 UI Components

### Activity Timeline Features:
- **11 Activity Types**: NOTE, CALL, EMAIL, MEETING, ORDER_CREATED, ORDER_UPDATED, ORDER_DELIVERED, PAYMENT, ISSUE, STATUS_CHANGE, ACCOUNT_CREATED
- **Emoji Icons** per type (📝, 📞, 📧, 👥, 📦, 💰, ⚠️)
- **Relative Timestamps** ("5m ago", "2h ago", "3d ago")
- **Pagination** (20 items per page)
- **Quick Actions**: Delete with confirmation
- **Modal Form**: Add NOTE, CALL, EMAIL, MEETING activities

### Customer Segmentation:
- **6 Predefined Segments** with color coding:
  - VIP (purple)
  - HIGH_VALUE (green)
  - REGULAR (blue)
  - AT_RISK (red)
  - NEW (yellow)
  - DORMANT (gray)
- **Tag Management**: Add/remove tags, bulk operations
- **Filter by Segment**: Multi-select dropdown
- **Filter by Tags**: Multi-select with "+" add new tag

### Insights Sidebar:
- **Health Score Card**: 0-100 score with status badge
- **Factor Breakdown**: 5 metrics with individual scores
- **Revenue Metrics**: Lifetime value, monthly revenue, growth %
- **Order Metrics**: Total orders, avg order value, frequency
- **Recommendations**: Auto-generated action items based on score

---

## 🧪 Testing Guide

### 1. Backend Testing

#### Run Migration:
```bash
cd tms-backend
./mvnw flyway:migrate
```

#### Test Endpoints:
```bash
# Get activities (paginated)
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8080/api/admin/customers/1/activities?page=0&size=20"

# Create NOTE activity
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"type":"NOTE","title":"Test note","description":"Test"}' \
  "http://localhost:8080/api/admin/customers/1/activities"

# Get health score
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8080/api/admin/customers/1/health-score"

# Get insights
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8080/api/admin/customers/1/insights"
```

### 2. Frontend Testing

#### Start Dev Server:
```bash
cd tms-frontend
npm run start
```

#### Test Activity Timeline:
1. Navigate to Customers → Click customer
2. Click "Timeline" tab
3. Click "+ Add Activity" button
4. Select type (NOTE, CALL, EMAIL, MEETING)
5. Enter title and description
6. Click "Save Activity"
7. Verify activity appears in timeline
8. Test pagination if > 20 activities
9. Test delete with confirmation dialog

#### Test Tag Management:
1. On customers list, click "Tags" filter dropdown
2. Select multiple tags
3. Verify customer list filters correctly
4. Test "Add new tag" functionality
5. Click "Manage Tags" on a customer row
6. Add/remove tags in modal
7. Click "Save" and verify update

#### Test Segmentation:
1. Click "Segments" filter dropdown
2. Select segments (VIP, HIGH_VALUE, etc.)
3. Verify color-coded badges appear
4. Test multi-segment filtering
5. Verify badge colors match segment type

#### Test Health Score:
1. Click customer to view details
2. Observe health score badge in header
3. Click insights/health score sidebar (if implemented)
4. Verify score calculation matches backend
5. Check factor breakdown (5 metrics)
6. Review recommendations list

### 3. Integration Testing

#### End-to-End Workflow:
```
1. Create customer
2. Create order for customer (triggers ORDER_CREATED activity auto)
3. Manually add CALL activity
4. Add EMAIL activity with meeting notes
5. Add MEETING activity
6. Verify timeline shows all 4 activities chronologically
7. Check health score increases with engagement
8. Tag customer as "VIP"
9. Assign segment "HIGH_VALUE"
10. Export customer data (verify tags/activities included)
```

---

## 🚀 Deployment Checklist

### Pre-Deployment:
- [ ] Run backend build: `./mvnw clean package`
- [ ] Run frontend build: `npm run build`
- [ ] Test database migration on staging DB
- [ ] Verify all API endpoints with Postman/Swagger
- [ ] Test pagination with 100+ activities
- [ ] Check CORS/auth headers

### Post-Deployment:
- [ ] Verify migration V341 executed successfully
- [ ] Check customer_activities table created
- [ ] Verify indexes on customer_id+created_at
- [ ] Test activity creation from UI
- [ ] Test health score calculation accuracy
- [ ] Monitor backend logs for errors
- [ ] Verify WebSocket still works (if using)

---

## 📊 Performance Considerations

### Database Indexes:
```sql
-- Already created in migration
CREATE INDEX idx_customer_created ON customer_activities (customer_id, created_at DESC);
CREATE INDEX idx_activity_type ON customer_activities (type);
CREATE INDEX idx_customer_segment ON customers (customer_segment);
CREATE INDEX idx_customer_health_score ON customers (health_score);
```

### Pagination Best Practices:
- Default page size: 20 activities
- Use keyset pagination for 1000+ activities
- Cache health scores for 15 minutes (TTL)

### Query Optimization:
- Activity timeline: Uses indexed query on customer_id + created_at
- Health score: Calculated on-demand, consider caching
- Insights: Aggregate queries should use covering indexes

---

## 🔮 Future Enhancements

### Phase 2 (Recommended):
1. **Auto-Activity Creation**:
   - ORDER_CREATED on new order
   - PAYMENT on payment received
   - STATUS_CHANGE on order updates

2. **Email/Call Integration**:
   - Click-to-call from activity
   - Email template integration
   - Automatic EMAIL activity on send

3. **Activity Search/Filter**:
   - Filter by activity type
   - Full-text search in descriptions
   - Date range picker

4. **Advanced Analytics**:
   - Customer comparison tool
   - Revenue forecasting
   - Churn prediction

5. **Real-time Updates**:
   - WebSocket notifications for new activities
   - Live health score updates

6. **Bulk Operations**:
   - Bulk tag assignment
   - Bulk activity creation
   - CSV export of timeline

---

## 📝 Code Examples

### Creating Activity from Order Service:
```java
@Service
public class TransportOrderService {
    @Autowired
    private CustomerActivityService activityService;

    public TransportOrder createOrder(TransportOrderDto dto) {
        TransportOrder order = // ... create order
        
        // Auto-create activity
        activityService.logOrderActivity(
            order.getCustomer().getId(),
            order.getId(),
            ActivityType.ORDER_CREATED,
            "New order #" + order.getOrderNumber() + " created"
        );
        
        return order;
    }
}
```

### Frontend: Loading Timeline:
```typescript
loadActivities(): void {
  if (!this.customer) return;
  
  this.activityService.getActivities(this.customer.id, 0, 100).subscribe({
    next: (res) => {
      this.activities = res.content || [];
      this.paginateActivities();
    },
    error: (err) => console.error('Failed to load activities', err),
  });
}
```

---

## 🐛 Troubleshooting

### Common Issues:

**1. Migration Fails - "Table already exists"**
```sql
-- Check if table exists
SHOW TABLES LIKE 'customer_activities';

-- If exists, version script or drop table
DROP TABLE IF EXISTS customer_activities;
```

**2. Health Score Always 0**
```java
// Check customer has orders and revenue data
SELECT id, total_orders, total_revenue, last_order_date 
FROM customers 
WHERE id = 123;
```

**3. Activities Not Loading**
- Check browser console for CORS errors
- Verify JWT token includes ADMIN or DISPATCHER role
- Check backend logs for exceptions
- Verify customer_id exists in database

**4. Tags Not Saving**
```sql
-- Check column type supports JSON
SHOW COLUMNS FROM customers LIKE 'tags';

-- Should be JSON or TEXT type
-- If VARCHAR, alter to JSON
ALTER TABLE customers MODIFY COLUMN tags JSON;
```

---

## 📚 Related Documentation

- [DAILY_TMS_HANDBOOK.md](../DAILY_TMS_HANDBOOK.md) - Daily operations guide
- [API_STRUCTURE_REVIEW_AND_IMPROVEMENTS.md](../API_STRUCTURE_REVIEW_AND_IMPROVEMENTS.md) - API patterns
- [ANGULAR_DEVELOPMENT_GUIDE.md](../ANGULAR_DEVELOPMENT_GUIDE.md) - Frontend standards

---

## Success Metrics

After deployment, track:

1. **Adoption Rate**: % of users adding activities weekly
2. **Engagement**: Average activities per customer
3. **Health Score Distribution**: % in each status tier
4. **Tag Usage**: Most common tags
5. **Segment Distribution**: Customer breakdown by segment
6. **Feature Usage**: Timeline views vs. insights sidebar
7. **Performance**: Activity load time (target < 200ms)

---

## 🎓 Training Resources

### For Admins/Dispatchers:
- **Activity Timeline**: Log every customer interaction for complete history
- **Health Scores**: Monitor at-risk customers (score < 40) weekly
- **Tags**: Use for categorization, campaigns, and quick filtering
- **Segments**: Assign based on order volume and revenue patterns
- **Insights**: Review monthly to identify upsell opportunities

### Best Practices:
- Add NOTE after every customer call
- Log MEETING with action items in description
- Tag customers based on industry, size, or special requirements
- Review AT_RISK customers daily
- Use activity timeline for customer handoffs

---

## 📞 Support

For issues or questions:
1. Check error logs: `tms-backend/logs/application.log`
2. Review browser console for frontend errors
3. Verify database migration status: `SELECT * FROM flyway_schema_history`
4. Contact development team with error details

---

**Implementation Date**: 2025-01-09  
**Version**: 1.0.0  
**Status**: Complete - Ready for Testing
