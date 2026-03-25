# Angular 19 inject() Pattern - Quick Reference

**Last Updated:** November 28, 2025  
**Project:** SV-TMS Frontend  
**Angular Version:** 19

---

## 🎯 Quick Decision Guide

### When to Use inject()

**USE inject() in these cases:**
- New services you create
- Services with circular dependencies (e.g., AdminNotificationService)
- Standalone components (recommended)
- When you want better tree-shaking
- When migrating to Angular 19+ patterns

❌ **Constructor injection still works for:**
- Simple components with 1-2 dependencies
- Legacy code that's working fine
- When team is not yet familiar with inject()

---

## 📋 Cheat Sheet

### Service Pattern

```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class MyService {
  // Declare dependencies as class properties
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  
  // Optional: Use constructor for initialization logic only
  constructor() {
    this.init();
  }
  
  private init(): void {
    // Your init logic here
  }
}
```

### Component Pattern

```typescript
import { Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { MyService } from './services/my.service';

@Component({
  selector: 'app-my-component',
  standalone: true,
  templateUrl: './my.component.html'
})
export class MyComponent implements OnInit {
  // Declare dependencies
  private router = inject(Router);
  private myService = inject(MyService);
  
  ngOnInit(): void {
    // Use dependencies here
    this.myService.loadData();
  }
}
```

---

## 🔄 Migration Steps

### Step 1: Add inject import
```typescript
// Add to your imports
import { inject } from '@angular/core';
```

### Step 2: Move dependencies out of constructor
```typescript
// BEFORE
constructor(
  private http: HttpClient,
  private auth: AuthService
) {}

// AFTER
private http = inject(HttpClient);
private auth = inject(AuthService);

constructor() {}  // Can be removed if empty
```

### Step 3: Update imports (remove `type`)
```typescript
// BEFORE
import type { AuthService } from './auth.service';

// AFTER
import { AuthService } from './auth.service';
```

---

## ⚠️ Common Mistakes

### ❌ Mistake 1: Using inject() in constructor
```typescript
// ❌ WRONG
constructor() {
  private http = inject(HttpClient); // Error!
}

// CORRECT
private http = inject(HttpClient); // At class level
constructor() {}
```

### ❌ Mistake 2: Mixing patterns
```typescript
// ❌ WRONG - Don't mix!
private router = inject(Router);

constructor(private http: HttpClient) {}

// CORRECT - Use one pattern consistently
private router = inject(Router);
private http = inject(HttpClient);
```

### ❌ Mistake 3: Forgetting to import inject
```typescript
// ❌ WRONG
import { Injectable } from '@angular/core';
private http = inject(HttpClient); // ReferenceError!

// CORRECT
import { Injectable, inject } from '@angular/core';
private http = inject(HttpClient);
```

---

## 🎨 Code Examples

### Example 1: Simple Service
```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  
  getUsers() {
    return this.http.get('/api/users');
  }
}
```

### Example 2: Service with Multiple Dependencies
```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AuthService } from './auth.service';
import { LoggerService } from './logger.service';

@Injectable({ providedIn: 'root' })
export class DataService {
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private logger = inject(LoggerService);
  
  getData() {
    const token = this.auth.getToken();
    this.logger.log('Fetching data...');
    return this.http.get('/api/data', {
      headers: { Authorization: `Bearer ${token}` }
    });
  }
}
```

### Example 3: Component with Services
```typescript
import { Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { FormBuilder, FormGroup } from '@angular/forms';
import { UserService } from './services/user.service';

@Component({
  selector: 'app-user-form',
  standalone: true,
  templateUrl: './user-form.component.html'
})
export class UserFormComponent implements OnInit {
  private router = inject(Router);
  private fb = inject(FormBuilder);
  private userService = inject(UserService);
  
  form!: FormGroup;
  
  ngOnInit(): void {
    this.form = this.fb.group({
      username: [''],
      email: ['']
    });
  }
  
  onSubmit(): void {
    this.userService.createUser(this.form.value).subscribe(() => {
      this.router.navigate(['/users']);
    });
  }
}
```

---

## 🔍 Troubleshooting

### Problem: "inject() must be called from an injection context"

**Solution:** Move inject() call to class property level
```typescript
// ❌ WRONG
ngOnInit() {
  this.service = inject(MyService); // Error!
}

// CORRECT
private service = inject(MyService); // At class level
```

### Problem: Circular dependency still occurs

**Solution:** Check that ALL services in the chain use inject()
```typescript
// If A depends on B, and B depends on A:
// Both A and B must use inject() pattern
```

### Problem: TypeScript error "inject is not defined"

**Solution:** Import inject from @angular/core
```typescript
import { inject } from '@angular/core';
```

---

## 📊 Benefits Summary

| Benefit | Description |
|---------|-------------|
| **Breaks Circular Dependencies** | Lazy resolution prevents circular ref errors |
| **Better Tree Shaking** | Unused dependencies can be removed in production |
| **Cleaner Code** | No long constructor parameter lists |
| **Type Safety** | Full TypeScript support and inference |
| **Future Proof** | Aligned with Angular 19+ direction |
| **Easier Testing** | Simpler to mock in unit tests |

---

## 🚀 Team Guidelines

### For New Code
1. Always use `inject()` pattern for services
2. Use `inject()` for standalone components
3. Keep constructor empty or minimal

### For Existing Code
1. 🔄 Migrate when touching the file anyway
2. 🔄 Prioritize services with circular dependencies
3. 🔄 Don't rush - migrate gradually

### Code Review Checklist
- [ ] Uses `inject()` instead of constructor injection
- [ ] Imported `inject` from '@angular/core'
- [ ] Removed `type` from service imports
- [ ] Dependencies declared as class properties
- [ ] Constructor is empty or only has init logic

---

## 📚 Learn More

- [Angular inject() API](https://angular.dev/api/core/inject)
- [Dependency Injection Guide](https://angular.dev/guide/di)
- [Standalone Components](https://angular.dev/guide/components/standalone)
- [Migration Guide](https://angular.dev/guide/update)

---

## 🆘 Need Help?

1. Check this guide first
2. Look at fixed examples:
   - `admin-notification.service.ts`
   - `header.component.ts`
   - `sidebar.component.ts`
3. Ask team lead if still stuck
4. Reference Angular docs: https://angular.dev

---

**Quick Copy-Paste Template:**
```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({ providedIn: 'root' })
export class MyService {
  private http = inject(HttpClient);
  
  // Your methods here
}
```

---

**Last Updated:** November 28, 2025  
**Status:** Active Pattern  
**Mandatory:** For new code  
**Optional:** For existing code
