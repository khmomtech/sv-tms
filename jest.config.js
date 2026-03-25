/**
 * Jest Configuration for Dispatch Lifecycle Tests
 * 
 * Usage:
 *   npm install --save-dev jest @types/jest ts-jest axios
 *   npm test -- dispatch-lifecycle
 * 
 * Environment:
 *   API_BASE_URL=http://localhost:8080 npm test
 */

module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/docs/testing'],
  testMatch: ['**/*.test.ts'],
  moduleFileExtensions: ['ts', 'js', 'json'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
  ],
  globals: {
    'ts-jest': {
      tsconfig: {
        esModuleInterop: true,
        allowSyntheticDefaultImports: true,
      },
    },
  },
  setupFilesAfterEnv: ['<rootDir>/docs/testing/test-setup.ts'],
  testTimeout: 30000,
  verbose: true,
};
