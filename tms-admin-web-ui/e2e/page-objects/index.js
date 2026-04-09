/**
 * Page Object Model for Login Page
 */
export class LoginPage {
    constructor(page) {
        this.page = page;
    }
    // Locators
    get usernameInput() {
        return this.page.locator('input[name="username"], input[type="text"], input[formcontrolname="username"]').first();
    }
    get passwordInput() {
        return this.page.locator('input[name="password"], input[type="password"], input[formcontrolname="password"]').first();
    }
    get loginButton() {
        return this.page.locator('button[type="submit"], button:has-text("Login"), button:has-text("Sign in")').first();
    }
    get errorMessage() {
        return this.page.locator('.error, .alert-danger, .mat-error, [role="alert"]').first();
    }
    // Actions
    async goto() {
        await this.page.goto('/login');
        await this.page.waitForLoadState('networkidle');
    }
    async login(username, password) {
        await this.usernameInput.fill(username);
        await this.passwordInput.fill(password);
        await this.loginButton.click();
        await this.page.waitForLoadState('networkidle');
    }
    async getErrorText() {
        return await this.errorMessage.textContent();
    }
    async isOnLoginPage() {
        const url = this.page.url();
        return url.includes('/login');
    }
}
/**
 * Page Object Model for Dashboard Page
 */
export class DashboardPage {
    constructor(page) {
        this.page = page;
    }
    // Locators
    get header() {
        return this.page.locator('app-header, header');
    }
    get sidebar() {
        return this.page.locator('aside[role="navigation"], app-sidebar, .sidebar');
    }
    get metricCards() {
        return this.page.locator('[data-testid="metric-card"], .metric-card, .dashboard-card');
    }
    get userMenu() {
        return this.page.locator('[data-testid="user-menu"], .user-menu, button[aria-label*="user" i]').first();
    }
    get logoutButton() {
        return this.page.locator('button:has-text("Logout"), button:has-text("Sign out"), [data-testid="logout"]').first();
    }
    // Actions
    async goto() {
        await this.page.goto('/dashboard');
        await this.page.waitForLoadState('networkidle');
    }
    async getMetricValue(metricName) {
        const card = this.page.locator(`[data-testid="${metricName}"], .metric-card:has-text("${metricName}")`).first();
        const value = await card.locator('.value, .metric-value, h2, h3').first().textContent();
        return value?.trim() || '';
    }
    async navigateToSection(sectionName) {
        const menuItem = this.sidebar.locator(`a:has-text("${sectionName}"), button:has-text("${sectionName}")`).first();
        await menuItem.click();
        await this.page.waitForLoadState('networkidle');
    }
    async logout() {
        await this.userMenu.click();
        await this.page.waitForTimeout(500);
        await this.logoutButton.click();
        await this.page.waitForLoadState('networkidle');
    }
    async isOnDashboard() {
        const url = this.page.url();
        return url.includes('/dashboard');
    }
}
/**
 * Page Object Model for Driver Management Page
 */
export class DriverManagementPage {
    constructor(page) {
        this.page = page;
    }
    // Locators
    get addButton() {
        return this.page.locator('button:has-text("Add"), button:has-text("Create"), button:has-text("New Driver")').first();
    }
    get searchInput() {
        return this.page.locator('input[placeholder*="search" i], input[type="search"], [data-testid="driver-search"]').first();
    }
    get table() {
        return this.page.locator('table, mat-table, [data-testid="driver-list"]');
    }
    get tableRows() {
        return this.page.locator('table tbody tr, mat-table mat-row, [data-testid="driver-row"]');
    }
    get modal() {
        return this.page.locator('[role="dialog"], .modal, mat-dialog-container, [data-testid="driver-modal"]');
    }
    get formNameInput() {
        return this.page.locator('input[name="name"], input[formcontrolname="name"], input[formcontrolname="firstName"]').first();
    }
    get formEmailInput() {
        return this.page.locator('input[type="email"], input[name="email"], input[formcontrolname="email"]').first();
    }
    get formPhoneInput() {
        return this.page.locator('input[type="tel"], input[name="phone"], input[formcontrolname="phone"]').first();
    }
    get formSubmitButton() {
        return this.page.locator('button[type="submit"], button:has-text("Save"), button:has-text("Submit")').first();
    }
    get formCancelButton() {
        return this.page.locator('button:has-text("Cancel"), button[aria-label="Close"]').first();
    }
    get deleteButton() {
        return this.page.locator('button:has-text("Delete"), button[aria-label*="delete" i]').first();
    }
    get confirmDeleteButton() {
        return this.page.locator('button:has-text("Confirm"), button:has-text("Yes"), button:has-text("Delete")').last();
    }
    // Actions
    async goto() {
        await this.page.goto('/drivers');
        await this.page.waitForLoadState('networkidle');
    }
    async clickAddDriver() {
        await this.addButton.click();
        await this.page.waitForTimeout(1000);
    }
    async searchDriver(query) {
        await this.searchInput.fill(query);
        await this.page.waitForTimeout(1000);
    }
    async getRowCount() {
        return await this.tableRows.count();
    }
    async clickRow(index) {
        await this.tableRows.nth(index).click();
        await this.page.waitForTimeout(1000);
    }
    async fillDriverForm(data) {
        if (data.name) {
            await this.formNameInput.fill(data.name);
        }
        if (data.email) {
            await this.formEmailInput.fill(data.email);
        }
        if (data.phone) {
            await this.formPhoneInput.fill(data.phone);
        }
    }
    async submitForm() {
        await this.formSubmitButton.click();
        await this.page.waitForLoadState('networkidle');
        await this.page.waitForTimeout(1000);
    }
    async cancelForm() {
        await this.formCancelButton.click();
        await this.page.waitForTimeout(500);
    }
    async deleteDriver() {
        await this.deleteButton.click();
        await this.page.waitForTimeout(500);
        await this.confirmDeleteButton.click();
        await this.page.waitForLoadState('networkidle');
    }
}
/**
 * Page Object Model for Vehicle Management Page
 */
export class VehicleManagementPage {
    constructor(page) {
        this.page = page;
    }
    // Locators
    get addButton() {
        return this.page.locator('button:has-text("Add"), button:has-text("Create"), button:has-text("New Vehicle")').first();
    }
    get searchInput() {
        return this.page.locator('input[placeholder*="search" i], input[type="search"]').first();
    }
    get table() {
        return this.page.locator('table, mat-table, [data-testid="vehicle-list"]');
    }
    get tableRows() {
        return this.page.locator('table tbody tr, mat-table mat-row, [data-testid="vehicle-row"]');
    }
    get filterDropdown() {
        return this.page.locator('select, mat-select, [data-testid="vehicle-filter"]').first();
    }
    get pagination() {
        return this.page.locator('.pagination, mat-paginator, [data-testid="pagination"]').first();
    }
    get nextPageButton() {
        return this.page.locator('button:has-text("Next"), button[aria-label*="next" i]').last();
    }
    get prevPageButton() {
        return this.page.locator('button:has-text("Previous"), button[aria-label*="previous" i]').first();
    }
    // Actions
    async goto() {
        await this.page.goto('/vehicles');
        await this.page.waitForLoadState('networkidle');
    }
    async clickAddVehicle() {
        await this.addButton.click();
        await this.page.waitForTimeout(1000);
    }
    async searchVehicle(query) {
        await this.searchInput.fill(query);
        await this.page.waitForTimeout(1000);
    }
    async getRowCount() {
        return await this.tableRows.count();
    }
    async goToNextPage() {
        await this.nextPageButton.click();
        await this.page.waitForTimeout(1000);
    }
    async goToPreviousPage() {
        await this.prevPageButton.click();
        await this.page.waitForTimeout(1000);
    }
    async filterByStatus(status) {
        await this.filterDropdown.click();
        await this.page.locator(`option:has-text("${status}"), mat-option:has-text("${status}")`).click();
        await this.page.waitForTimeout(1000);
    }
}
/**
 * Page Object Model for Transport Order Page
 */
export class TransportOrderPage {
    constructor(page) {
        this.page = page;
    }
    // Locators
    get addButton() {
        return this.page.locator('button:has-text("Add"), button:has-text("Create"), button:has-text("New Order")').first();
    }
    get table() {
        return this.page.locator('table, mat-table, [data-testid="order-list"]');
    }
    get tableRows() {
        return this.page.locator('table tbody tr, mat-table mat-row, [data-testid="order-row"]');
    }
    get statusFilter() {
        return this.page.locator('select[name="status"], mat-select[formcontrolname="status"]').first();
    }
    get dateRangePicker() {
        return this.page.locator('input[type="date"], mat-datepicker-toggle').first();
    }
    // Actions
    async goto() {
        await this.page.goto('/transport-orders');
        await this.page.waitForLoadState('networkidle');
    }
    async clickAddOrder() {
        await this.addButton.click();
        await this.page.waitForTimeout(1000);
    }
    async filterByStatus(status) {
        await this.statusFilter.click();
        await this.page.locator(`option:has-text("${status}"), mat-option:has-text("${status}")`).click();
        await this.page.waitForTimeout(1000);
    }
    async getRowCount() {
        return await this.tableRows.count();
    }
    async clickRow(index) {
        await this.tableRows.nth(index).click();
        await this.page.waitForTimeout(1000);
    }
}
