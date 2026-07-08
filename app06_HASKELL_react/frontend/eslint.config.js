import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import tseslint from '@typescript-eslint/eslint-plugin'
import tsParser from '@typescript-eslint/parser'

export default [
  {
    // vite.config.js / vite.config.d.ts are tsc -b's emitted output for
    // vite.config.ts (tsconfig.node.json is composite, so it must emit) --
    // generated duplicates, not hand-written source. Don't lint them.
    ignores: ['dist', 'node_modules', 'vite.config.js', 'vite.config.d.ts'],
  },
  js.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: globals.browser,
      parser: tsParser,
      parserOptions: {
        ecmaFeatures: { jsx: true },
      },
    },
    plugins: {
      '@typescript-eslint': tseslint,
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...tseslint.configs.recommended.rules,
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': 'warn',
      // TypeScript already checks this; @types/react's ambient UMD global
      // (`React.FormEvent` used as a type with no value import) is a false
      // positive under the base JS rule -- typescript-eslint's own docs
      // recommend disabling it for .ts/.tsx files.
      'no-undef': 'off',
    },
  },
  {
    files: ['vite.config.ts'],
    languageOptions: {
      globals: globals.node,
    },
  },
]
