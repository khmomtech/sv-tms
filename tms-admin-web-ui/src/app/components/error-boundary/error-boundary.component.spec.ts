import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { By } from '@angular/platform-browser';

import { ErrorBoundaryComponent } from './error-boundary.component';

// Test component that throws errors
@Component({
  template: `<div>{{ throwError() }}</div>`,
  standalone: true,
})
class ThrowingComponent {
  shouldThrow = true;

  throwError(): string {
    if (this.shouldThrow) {
      throw new Error('Test error');
    }
    return 'Success';
  }
}

// Test component that works normally
@Component({
  template: `<div>Normal content</div>`,
  standalone: true,
})
class NormalComponent {}

describe('ErrorBoundaryComponent', () => {
  let component: ErrorBoundaryComponent;
  let fixture: ComponentFixture<ErrorBoundaryComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ErrorBoundaryComponent, CommonModule],
    }).compileComponents();

    fixture = TestBed.createComponent(ErrorBoundaryComponent);
    component = fixture.componentInstance;
  });

  describe('Component Initialization', () => {
    it('should create', () => {
      expect(component).toBeTruthy();
    });

    it('should start with no error', () => {
      expect(component.hasError).toBe(false);
      expect(component.error).toBeNull();
    });

    it('should generate unique error ID', () => {
      component.ngOnInit();

      expect(component.errorId).toBeDefined();
      expect(component.errorId.length).toBeGreaterThan(0);
    });

    it('should set error timestamp on init', () => {
      component.ngOnInit();

      expect(component.errorTimestamp).toBeDefined();
      expect(component.errorTimestamp).toBeInstanceOf(Date);
    });
  });

  describe('Error Catching', () => {
    it('should catch synchronous errors', () => {
      const error = new Error('Sync error');

      component.handleError(error);

      expect(component.hasError).toBe(true);
      expect(component.error).toBe(error);
    });

    it('should catch async errors', (done) => {
      const error = new Error('Async error');

      setTimeout(() => {
        component.handleError(error);

        expect(component.hasError).toBe(true);
        expect(component.error).toBe(error);
        done();
      }, 10);
    });

    it('should store error message', () => {
      const error = new Error('Test error message');

      component.handleError(error);

      expect(component.error?.message).toBe('Test error message');
    });

    it('should store error stack trace', () => {
      const error = new Error('Test error');

      component.handleError(error);

      expect(component.error?.stack).toBeDefined();
    });

    it('should update error timestamp when error occurs', () => {
      const beforeTime = new Date();

      component.handleError(new Error('Test'));

      expect(component.errorTimestamp.getTime()).toBeGreaterThanOrEqual(beforeTime.getTime());
    });

    it('should handle null error gracefully', () => {
      component.handleError(null as any);

      expect(component.hasError).toBe(true);
      expect(component.error).toBeNull();
    });

    it('should handle string errors', () => {
      component.handleError('String error' as any);

      expect(component.hasError).toBe(true);
    });

    it('should handle error objects without stack', () => {
      const simpleError = { message: 'Simple error' };

      component.handleError(simpleError as any);

      expect(component.hasError).toBe(true);
    });
  });

  describe('Error Display', () => {
    beforeEach(() => {
      component.handleError(new Error('Display test error'));
      fixture.detectChanges();
    });

    it('should show error UI when error occurs', () => {
      const compiled = fixture.nativeElement;
      const errorUI = compiled.querySelector('.error-boundary');

      expect(errorUI).toBeTruthy();
    });

    it('should display error message', () => {
      const compiled = fixture.nativeElement;
      const errorMessage = compiled.textContent;

      expect(errorMessage).toContain(component.errorMessage);
    });

    it('should display error ID', () => {
      const compiled = fixture.nativeElement;
      const errorText = compiled.textContent;

      expect(errorText).toContain(component.errorId);
    });

    it('should display error timestamp', () => {
      const compiled = fixture.nativeElement;
      const errorText = compiled.textContent;

      expect(errorText).toContain('Occurred at:');
    });

    it('should hide technical details by default', () => {
      const compiled = fixture.nativeElement;
      const techDetails = compiled.querySelector('.technical-details');

      expect(component.showTechnicalDetails).toBe(false);
    });

    it('should show technical details when toggled', () => {
      component.toggleTechnicalDetails();
      fixture.detectChanges();

      expect(component.showTechnicalDetails).toBe(true);
    });

    it('should display stack trace in technical details', () => {
      component.toggleTechnicalDetails();
      fixture.detectChanges();

      const compiled = fixture.nativeElement;
      const stackTrace = compiled.textContent;

      expect(stackTrace).toContain('Stack Trace');
    });
  });

  describe('Retry Functionality', () => {
    it('should clear error on retry', () => {
      component.handleError(new Error('Test'));
      component.retry();

      expect(component.hasError).toBe(false);
      expect(component.error).toBeNull();
    });

    it('should increment retry count', () => {
      component.handleError(new Error('Test'));

      expect(component.retryCount).toBe(0);

      component.retry();

      expect(component.retryCount).toBe(1);
    });

    it('should allow multiple retries', () => {
      component.handleError(new Error('Test'));
      component.retry();
      component.handleError(new Error('Test again'));
      component.retry();

      expect(component.retryCount).toBe(2);
    });

    it('should reset error state on retry', () => {
      component.handleError(new Error('Test'));
      component.showTechnicalDetails = true;

      component.retry();

      expect(component.showTechnicalDetails).toBe(false);
    });

    it('should emit retry event', () => {
      spyOn(component.retryAttempt, 'emit');

      component.retry();

      expect(component.retryAttempt.emit).toHaveBeenCalled();
    });
  });

  describe('Reload Functionality', () => {
    it('should delegate reload to the page reload handler', () => {
      const reloadSpy = spyOn<any>(component, 'reloadPage').and.stub();

      component.reload();

      expect(reloadSpy).toHaveBeenCalled();
    });
  });

  describe('Content Projection', () => {
    it('should project child content when no error', () => {
      @Component({
        template: `
          <app-error-boundary>
            <div class="child-content">Child content</div>
          </app-error-boundary>
        `,
        standalone: true,
        imports: [ErrorBoundaryComponent],
      })
      class TestHostComponent {}

      const hostFixture = TestBed.createComponent(TestHostComponent);
      hostFixture.detectChanges();

      const content = hostFixture.nativeElement.querySelector('.child-content');
      expect(content).toBeTruthy();
      expect(content.textContent).toContain('Child content');
    });

    it('should hide child content when error occurs', () => {
      @Component({
        template: `
          <app-error-boundary>
            <div class="child-content">Child content</div>
          </app-error-boundary>
        `,
        standalone: true,
        imports: [ErrorBoundaryComponent],
      })
      class TestHostComponent {}

      const hostFixture = TestBed.createComponent(TestHostComponent);
      const errorBoundary = hostFixture.debugElement.query(
        By.directive(ErrorBoundaryComponent),
      ).componentInstance;

      errorBoundary.handleError(new Error('Test'));
      hostFixture.detectChanges();

      const content = hostFixture.nativeElement.querySelector('.child-content');
      expect(content).toBeFalsy();
    });
  });

  describe('UI Actions', () => {
    beforeEach(() => {
      component.handleError(new Error('Test error'));
      fixture.detectChanges();
    });

    it('should have retry button', () => {
      const compiled = fixture.nativeElement;
      const retryButton = compiled.querySelector('[data-test="retry-button"]');

      expect(retryButton).toBeTruthy();
    });

    it('should have reload button', () => {
      const compiled = fixture.nativeElement;
      const reloadButton = compiled.querySelector('[data-test="reload-button"]');

      expect(reloadButton).toBeTruthy();
    });

    it('should have technical details toggle', () => {
      const compiled = fixture.nativeElement;
      const toggleButton = compiled.querySelector('[data-test="toggle-details"]');

      expect(toggleButton).toBeTruthy();
    });

    it('should call retry when retry button clicked', () => {
      spyOn(component, 'retry');

      const retryButton = fixture.debugElement.query(By.css('[data-test="retry-button"]'));
      retryButton.nativeElement.click();

      expect(component.retry).toHaveBeenCalled();
    });

    it('should call reload when reload button clicked', () => {
      spyOn(component, 'reload');

      const reloadButton = fixture.debugElement.query(By.css('[data-test="reload-button"]'));
      reloadButton.nativeElement.click();

      expect(component.reload).toHaveBeenCalled();
    });
  });

  describe('Error Formatting', () => {
    it('should format error timestamp correctly', () => {
      component.handleError(new Error('Test'));

      const formatted = component.getFormattedTimestamp();

      expect(formatted).toMatch(/\d{1,2}:\d{2}:\d{2}/);
    });

    it('should display user-friendly error message', () => {
      component.handleError(new Error('Cannot read property of undefined'));
      fixture.detectChanges();

      const compiled = fixture.nativeElement;
      const errorText = compiled.textContent;

      expect(errorText).toContain('We encountered an unexpected error');
    });

    it('should sanitize error messages', () => {
      const maliciousError = new Error('<script>alert("xss")</script>');
      component.handleError(maliciousError);
      fixture.detectChanges();

      const compiled = fixture.nativeElement;
      const errorText = compiled.innerHTML;

      expect(errorText).not.toContain('<script>');
    });
  });

  describe('Error Metadata', () => {
    it('should track error occurrence count', () => {
      expect(component.errorCount).toBe(0);

      component.handleError(new Error('Error 1'));
      expect(component.errorCount).toBe(1);

      component.retry();
      component.handleError(new Error('Error 2'));
      expect(component.errorCount).toBe(2);
    });

    it('should store last error for debugging', () => {
      const error1 = new Error('First error');
      const error2 = new Error('Second error');

      component.handleError(error1);
      component.handleError(error2);

      expect(component.error).toBe(error2);
    });
  });
});
