// Minimal Angular test bootstrap for Karma
import 'zone.js/testing';
import { getTestBed } from '@angular/core/testing';
import { BrowserDynamicTestingModule, platformBrowserDynamicTesting, } from '@angular/platform-browser-dynamic/testing';
getTestBed().initTestEnvironment(BrowserDynamicTestingModule, platformBrowserDynamicTesting());
// Optional: re-export commonly used test helpers
export { fakeAsync, tick, flush } from '@angular/core/testing';
