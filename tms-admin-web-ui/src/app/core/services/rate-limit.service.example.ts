// /**
//  * Example: Using RateLimitService in components
//  *
//  * This demonstrates how to apply debouncing and throttling to search inputs
//  * and API calls throughout the application.
//  */

// // In any component with search functionality:

// import { Component, OnInit } from '@angular/core';
// import { FormControl } from '@angular/forms';
// import { switchMap } from 'rxjs/operators';
// import { RateLimitService } from '@app/core/services/rate-limit.service';

// @Component({
//   selector: 'app-example-search',
//   template: `
//     <input [formControl]="searchControl" placeholder="Search..." />
//   `
// })
// export class ExampleSearchComponent implements OnInit {
//   searchControl = new FormControl('');

//   constructor(
//     private rateLimitService: RateLimitService,
//     private apiService: YourApiService
//   ) {}

//   ngOnInit() {
//     // Apply debouncing to search input
//     this.searchControl.valueChanges
//       .pipe(
//         this.rateLimitService.debounceSearch(300), // Wait 300ms after user stops typing
//         switchMap(query => this.apiService.search(query))
//       )
//       .subscribe(results => {
//         // Handle results
//       });
//   }
// }

// // For API calls that need throttling:
// import { Subject } from 'rxjs';

// @Component({...})
// export class ExampleApiComponent {
//   private refreshSubject = new Subject<void>();

//   constructor(private rateLimitService: RateLimitService) {}

//   ngOnInit() {
//     // Throttle refresh button clicks to prevent API spam
//     this.refreshSubject
//       .pipe(
//         this.rateLimitService.throttleApi(2000), // Max 1 call per 2 seconds
//         switchMap(() => this.apiService.getData())
//       )
//       .subscribe(data => {
//         // Handle data
//       });
//   }

//   onRefreshClick() {
//     this.refreshSubject.next();
//   }
// }

// // For complex scenarios (both debounce and throttle):
// @Component({...})
// export class ComplexSearchComponent {
//   searchControl = new FormControl('');

//   constructor(private rateLimitService: RateLimitService) {}

//   ngOnInit() {
//     this.searchControl.valueChanges
//       .pipe(
//         // Wait for user to stop typing AND limit rate
//         this.rateLimitService.debounceAndThrottle(300, 1000),
//         switchMap(query => this.apiService.complexSearch(query))
//       )
//       .subscribe(results => {
//         // Handle results
//       });
//   }
// }
