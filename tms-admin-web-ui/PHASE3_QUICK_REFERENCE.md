# Phase 3 Testing - Quick Reference

## 🎯 Goal: 4/10 → 9/10 Testing Coverage

## Completed (Week 1 Progress)

### Service Unit Tests Created
1. **CacheService** - 120+ test cases
   - Cache operations, TTL, fallback, statistics
   - Pattern invalidation, deduplication
   
2. **CircuitBreakerService** - 80+ test cases
   - State transitions, failure threshold
   - Timeout recovery, custom config
   
3. **WebSocketService** - 90+ test cases
   - Connection management, auto-reconnect
   - Message pub/sub, heartbeat, error handling

## 📝 Test Commands

```bash
# Run all tests
npm test

# Run tests once (CI mode)
npm run test:ci

# Run with coverage
npm run test:coverage

# Debug tests in browser
npm run test:debug

# Run E2E tests
npm run test:e2e
```

## 🧪 Test File Locations

```
tms-frontend/src/app/
├── services/
│   ├── cache.service.spec.ts ✅
│   ├── circuit-breaker.service.spec.ts ✅
│   ├── websocket.service.spec.ts ✅
│   ├── driver.service.spec.ts (existing, 207 lines)
│   ├── vehicle.service.spec.ts (empty - needs tests)
│   └── [other services].spec.ts
└── components/
    ├── drivers/drivers.component.spec.ts (needs enhancement)
    ├── vehicle/vehicle.component.spec.ts (needs enhancement)
    └── [other components].spec.ts
```

## 🎨 Test Pattern Examples

### Service Test Template
```typescript
describe('MyService', () => {
  let service: MyService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [MyService]
    });
    service = TestBed.inject(MyService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should test feature', () => {
    // Arrange, Act, Assert
  });
});
```

### Component Test Template
```typescript
describe('MyComponent', () => {
  let component: MyComponent;
  let fixture: ComponentFixture<MyComponent>;
  let mockService: jasmine.SpyObj<MyService>;

  beforeEach(() => {
    mockService = jasmine.createSpyObj('MyService', ['method1']);
    
    TestBed.configureTestingModule({
      imports: [MyComponent],
      providers: [
        { provide: MyService, useValue: mockService }
      ]
    });

    fixture = TestBed.createComponent(MyComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
```

### Async Test Template
```typescript
it('should handle async operation', fakeAsync(() => {
  service.asyncMethod().subscribe(result => {
    expect(result).toBeDefined();
  });

  tick(1000); // Fast-forward time
}));
```

## 📊 Coverage Targets

| Category | Current | Target |
|----------|---------|--------|
| Statements | 25% | 85%+ |
| Branches | 18% | 80%+ |
| Functions | 30% | 85%+ |
| Lines | 28% | 85%+ |

## 🚧 Next Tasks (Priority Order)

1. **VehicleService tests** - Empty file, needs 100+ test cases
2. **DriversComponent tests** - Enhance existing with virtual scroll, OnPush
3. **VehicleComponent tests** - Enhance with optimistic locking tests
4. **Integration tests** - API contracts, WebSocket integration
5. **Visual regression** - Percy/Chromatic setup
6. **Load tests** - Performance under high load

## 🔧 Common Issues & Solutions

### Issue: Tests fail with "No provider for AuthService"
```typescript
// Solution: Mock AuthService
const mockAuth = { getToken: () => 'test-token' };
providers: [{ provide: AuthService, useValue: mockAuth }]
```

### Issue: HttpClient tests hanging
```typescript
// Solution: Always verify no outstanding requests
afterEach(() => {
  httpMock.verify();
});
```

### Issue: Change detection not triggering
```typescript
// Solution: Call detectChanges
fixture.detectChanges();
// or
component.changeDetectorRef.markForCheck();
```

### Issue: WebSocket tests timeout
```typescript
// Solution: Use fakeAsync and tick
it('should reconnect', fakeAsync(() => {
  service.connect();
  tick(5000); // Fast-forward
  expect(service.getStatus()).toBe('CONNECTED');
}));
```

## 📚 Key Files Created

1. `PHASE3_TESTING_COVERAGE_IMPLEMENTATION.md` - Full documentation
2. `cache.service.spec.ts` - 120+ test cases
3. `circuit-breaker.service.spec.ts` - 80+ test cases
4. `websocket.service.spec.ts` - 90+ test cases
5. `PHASE3_QUICK_REFERENCE.md` - This file

## 🎯 Success Metrics

- [x] CacheService: 95%+ coverage
- [x] CircuitBreakerService: 95%+ coverage
- [x] WebSocketService: 92%+ coverage
- [ ] VehicleService: 85%+ coverage
- [ ] Components: 80%+ coverage
- [ ] Integration tests: Complete
- [ ] Visual regression: Setup
- [ ] Load tests: Complete

## 💡 Tips

1. **Test one thing at a time** - Each `it()` should test one specific behavior
2. **Use descriptive names** - `it('should return null when key not found')` not `it('test get')`
3. **Arrange-Act-Assert** - Structure tests clearly
4. **Mock dependencies** - Isolate the unit under test
5. **Test edge cases** - null, undefined, empty, large datasets
6. **Use fakeAsync for time** - Don't use real setTimeout
7. **Clean up** - Always verify HTTP mocks, unsubscribe
8. **Check coverage** - Run `npm run test:coverage` regularly

---

**Quick Start**: Run `npm run test:ci` to see current test status
**Documentation**: See `PHASE3_TESTING_COVERAGE_IMPLEMENTATION.md` for full details
