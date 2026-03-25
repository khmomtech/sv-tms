> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Customer Advanced Features - Quick Reference

## 🚀 Quick Start

### For Users
```
Quick View    → Click 👁️ icon or press Q (1 selected)
Recent List   → Click button (top-right) or press Ctrl+R
New Customer  → Press N
Edit Customer → Press E (1 selected)
Close Any     → Press Esc
```

### For Developers
```typescript
// Quick View
openQuickView(customer: Customer): void
closeQuickView(): void

// Recent Customers
loadRecentCustomers(): void
addToRecentCustomers(customer: Customer): void
toggleRecentSidebar(): void

// Keyboard
@HostListener('document:keydown', ['$event'])
handleKeyboardShortcuts(event: KeyboardEvent): void
```

---

## 📦 Components

### customer.component.ts
**New Properties**:
```typescript
quickViewCustomer: Customer | null = null;
showRecentSidebar = false;
recentCustomers: (Customer & { viewedAt?: Date })[] = [];
RECENT_CUSTOMERS_KEY = 'svtms.recent.customers.v1';
MAX_RECENT_CUSTOMERS = 10;
```

**New Methods** (8 total):
1. `openQuickView(customer)` - Show quick view modal
2. `closeQuickView()` - Hide quick view modal
3. `viewCustomerDetails(customer)` - Navigate to full view
4. `toggleRecentSidebar()` - Show/hide sidebar
5. `loadRecentCustomers()` - Load from localStorage
6. `addToRecentCustomers(customer)` - Add to history
7. `clearRecentCustomers()` - Clear all history
8. `timeAgo(date)` - Format relative time

**Lifecycle Changes**:
```typescript
ngOnInit(): void {
  this.loadRecentCustomers(); // NEW
  this.fetchCustomers();
}
```

---

### customer.component.html
**New Sections**:
1. **Header Enhancement** (lines ~4-40)
   - Keyboard shortcuts hint (desktop only)

2. **Quick View Modal** (lines ~1033-1225)
   - Backdrop with click-to-close
   - Customer info grid
   - Financial summary cards
   - Edit/View Full actions

3. **Recent Sidebar** (lines ~1227-1355)
   - Sliding sidebar (right edge)
   - Customer list with avatars
   - Time ago display
   - Clear all button

4. **Toggle Button** (lines ~1357-1380)
   - Fixed position (top-right)
   - Badge with count
   - Only shows when sidebar closed

---

### customer-view.component.ts
**Changes**:
```typescript
loadCustomer(id: number): void {
  // ... existing code
  if (this.customer) {
    this.addToRecentCustomers(this.customer); // NEW
  }
}

private addToRecentCustomers(customer: Customer): void {
  // Same logic as list component
}
```

---

## 🎨 UI Components

### Quick View Modal
```html
<!-- Structure -->
<div *ngIf="quickViewCustomer" class="fixed inset-0 z-50">
  <div class="backdrop" (click)="closeQuickView()">
    <div class="modal max-w-3xl" (click)="$event.stopPropagation()">
      <!-- Header: Gradient blue -->
      <!-- Content: Grid layout -->
      <!-- Footer: Actions + shortcuts -->
    </div>
  </div>
</div>
```

**Key Classes**:
- `fixed inset-0 z-50` - Full screen overlay
- `max-w-3xl` - Modal width (768px)
- `max-h-[90vh]` - Scroll if content too tall
- `bg-gradient-to-r from-blue-600 to-blue-700` - Header

---

### Recent Sidebar
```html
<!-- Structure -->
<div class="fixed top-0 right-0 h-full w-80 z-40"
     [ngClass]="showRecentSidebar ? 'translate-x-0' : 'translate-x-full'">
  <!-- Header -->
  <!-- Customer list -->
  <!-- Clear button -->
</div>

<!-- Toggle button (when closed) -->
<button *ngIf="!showRecentSidebar" class="fixed top-20 right-0">
  <span *ngIf="recentCustomers.length > 0" class="badge">
    {{ recentCustomers.length }}
  </span>
</button>
```

**Key Classes**:
- `translate-x-full` - Hidden (off-screen right)
- `translate-x-0` - Visible (on-screen)
- `transition-transform duration-300` - Smooth slide
- `w-80` - Sidebar width (320px)

---

## ⌨️ Keyboard Shortcuts

### Implementation
```typescript
@HostListener('document:keydown', ['$event'])
handleKeyboardShortcuts(event: KeyboardEvent): void {
  // 1. Check if typing in input
  const target = event.target as HTMLElement;
  if (target.tagName === 'INPUT' || ...) return;

  // 2. Check modal state
  if (event.key !== 'Escape' && this.isModalOpen) return;

  // 3. Handle shortcuts
  switch (event.key.toLowerCase()) {
    case 'n': this.openCustomerModal(); break;
    case 'e': /* edit if 1 selected */; break;
    case 'q': /* quick view if 1 selected */; break;
    case 'escape': /* close modals */; break;
  }
}
```

### Smart Features
- Disabled in input fields
- Disabled when modals open (except Esc)
- Requires selection for E/Q
- Priority closing (Quick View → Modal → Sidebar)

---

## 💾 LocalStorage

### Data Structure
```typescript
interface RecentCustomer extends Customer {
  viewedAt?: Date;
}

// Stored as JSON array
localStorage.setItem('svtms.recent.customers.v1', JSON.stringify([
  {
    id: 1,
    name: "John Doe",
    phone: "123-456-7890",
    email: "john@example.com",
    status: "ACTIVE",
    viewedAt: "2025-01-15T10:30:00Z"
  },
  // ... up to 10 customers
]));
```

### Operations
```typescript
// Load
loadRecentCustomers(): void {
  const stored = localStorage.getItem(RECENT_CUSTOMERS_KEY);
  this.recentCustomers = JSON.parse(stored);
}

// Add
addToRecentCustomers(customer: Customer): void {
  // 1. Remove if exists
  // 2. Add to front
  // 3. Trim to 10
  // 4. Save
  localStorage.setItem(RECENT_CUSTOMERS_KEY, JSON.stringify(recent));
}

// Clear
clearRecentCustomers(): void {
  localStorage.removeItem(RECENT_CUSTOMERS_KEY);
}
```

---

## 🧪 Testing

### Manual Test Cases
```bash
# Quick View
1. Click eye icon → Modal opens
2. Click backdrop → Modal closes
3. Press Esc → Modal closes
4. Click Edit → Edit modal opens
5. Click View Full → Navigates to details

# Recent Sidebar
1. Press Ctrl+R → Sidebar opens
2. Click toggle → Sidebar opens/closes
3. View customer → Added to recent
4. Click customer in recent → Navigates
5. Clear all → Confirms and clears

# Keyboard Shortcuts
1. Press N → New customer modal
2. Select 1, press E → Edit modal
3. Select 1, press Q → Quick view
4. Press Esc → Closes modal
5. Type in input → Shortcuts disabled
```

### Browser Checks
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Safari (iOS)
- [ ] Mobile Chrome (Android)

---

## 🐛 Common Issues

### Quick View Not Opening
```typescript
// Check property
console.log(this.quickViewCustomer); // Should be Customer object

// Check HTML
*ngIf="quickViewCustomer" // Must be truthy
```

### Recent Customers Not Persisting
```typescript
// Check localStorage
console.log(localStorage.getItem('svtms.recent.customers.v1'));

// Check browser
// Private mode? → localStorage disabled
// Storage full? → Try clearing other data
```

### Keyboard Shortcuts Not Working
```typescript
// Check focus
console.log(document.activeElement); // Should NOT be input

// Check modal state
console.log(this.isModalOpen); // Should be false

// Check event
@HostListener('document:keydown', ['$event'])
handleKeyboardShortcuts(event: KeyboardEvent): void {
  console.log(event.key); // Debug which key pressed
}
```

---

## 📊 Performance Tips

### Optimize Quick View
```typescript
// Use OnPush change detection (future)
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush
})

// Lazy load heavy components
*ngIf="quickViewCustomer" // Already doing this ✅
```

### Optimize Recent Sidebar
```typescript
// Limit to 10 customers ✅
MAX_RECENT_CUSTOMERS = 10;

// Use trackBy for *ngFor (future)
<div *ngFor="let customer of recentCustomers; trackBy: trackById">

trackById(index: number, customer: Customer): number {
  return customer.id!;
}
```

---

## 🔒 Security Notes

### LocalStorage Safety
```typescript
// Safe - No sensitive data stored
recentCustomers: Customer[] // Only public info

// ❌ Never store
password, token, creditCard, ssn

// Error handling
try {
  localStorage.setItem(key, value);
} catch (error) {
  console.error('Storage failed'); // Don't crash app
}
```

---

## 📝 Code Style

### Naming Conventions
```typescript
// Properties
quickViewCustomer    // Camel case
showRecentSidebar    // Boolean = show/is/has prefix
RECENT_CUSTOMERS_KEY // Constants = UPPER_SNAKE_CASE

// Methods
openQuickView()      // Action verb + noun
loadRecentCustomers() // load/save/delete/update
toggleRecentSidebar() // toggle for show/hide
```

### Comments
```typescript
// ============ Quick View Modal ============
// Group related methods with visual separator

// Add to recent customers
addToRecentCustomers(customer: Customer): void {
  // Brief description above method
}
```

---

## 🎯 Quick Wins

### Add Feature Flag
```typescript
// Enable/disable features per environment
featureFlags = {
  quickView: true,
  recentSidebar: true,
  keyboardShortcuts: true
};

// Use in template
*ngIf="featureFlags.quickView && quickViewCustomer"
```

### Add Analytics
```typescript
openQuickView(customer: Customer): void {
  this.quickViewCustomer = customer;
  
  // Track usage
  gtag('event', 'quick_view_opened', {
    customer_id: customer.id
  });
}
```

### Add Loading State
```typescript
isLoadingQuickView = false;

async openQuickView(customer: Customer): Promise<void> {
  this.isLoadingQuickView = true;
  
  // Fetch additional data if needed
  const fullData = await this.customerService.getFullDetails(customer.id);
  
  this.quickViewCustomer = fullData;
  this.isLoadingQuickView = false;
}
```

---

## 📚 Resources

### Related Files
- `customer.model.ts` - Customer type definition
- `customer.service.ts` - API calls
- `customer.component.css` - Additional styles

### Related Docs
- `CUSTOMER_ADVANCED_FEATURES.md` - Full documentation
- `CUSTOMER_ADVANCED_FEATURES_SUMMARY.md` - Implementation summary
- `ANGULAR_FRONTEND_COMPLETE_SUMMARY.md` - Overall Angular status

### External Docs
- [Angular Keyboard Events](https://angular.io/api/platform-browser/HostListener)
- [Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API)
- [Tailwind CSS](https://tailwindcss.com/docs)

---

**Last Updated**: 2025-01-XX  
**Version**: 1.0.0  
**Status**: Production Ready
