---
name: write-test
description: QA — generate tests for a feature, bug fix, or endpoint
---

Write tests for: $ARGUMENTS

Steps:
1. Read the relevant source file(s) to understand the code under test.
2. Identify the test type needed:
   - Java service/repository → JUnit 5 + Mockito unit test, or `@SpringBootTest` integration test
   - Java controller → `@WebMvcTest` with MockMvc
   - Angular component → Karma/Jasmine with `TestBed`
   - Angular service → Karma/Jasmine with `HttpClientTestingModule`
   - Flutter widget → `testWidgets` with `WidgetTester`
   - Flutter service → `flutter_test` unit test with mocked HTTP
3. Write tests covering:
   - Happy path (expected input → expected output)
   - Edge cases (empty, null, boundary values)
   - Error cases (invalid input, service failure, 404, 401)
4. Follow naming convention:
   - Java: `methodName_condition_expectedResult()`
   - Angular/Flutter: `'should {expected behavior} when {condition}'`
5. Run the tests after writing them and confirm they pass.
   - Java: `./mvnw -pl {module} test`
   - Angular: `npm run test:ci`
   - Flutter: `flutter test`
6. Report: tests written, results, any failures and why.
