// Flat ESLint config (ESLint v9+) for Angular + TypeScript
import tsParser from '@typescript-eslint/parser';
import tsPlugin from '@typescript-eslint/eslint-plugin';
import importPlugin from 'eslint-plugin-import';

export default [
  {
    files: ['**/*.ts'],
    ignores: ['dist/**'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        project: ['./tsconfig.json', './tsconfig.app.json'],
        sourceType: 'module'
      }
    },
    plugins: {
      '@typescript-eslint': tsPlugin,
      import: importPlugin
    },
    rules: {
      '@typescript-eslint/consistent-type-imports': ['warn', { prefer: 'type-imports' }],
      'import/order': ['warn', {
        groups: ['builtin','external','internal','parent','sibling','index'],
        'newlines-between': 'always',
        alphabetize: { order: 'asc', caseInsensitive: true }
      }],
      'no-restricted-imports': ['warn', { patterns: ['src/app/components/*'] }]
      , 'rxjs/no-sharereplay': 'off'
    }
  },
  // Template linting (Angular-specific) can be added once @angular-eslint flat-config is installed.
  // Template files not linted until Angular template flat config integrated.
];
