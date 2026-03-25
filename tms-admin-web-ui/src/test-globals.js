// Global shims for Karma tests (plain script, not module)
// Some dependencies (e.g., sockjs-client) expect `global` to exist.
window.global = window;
