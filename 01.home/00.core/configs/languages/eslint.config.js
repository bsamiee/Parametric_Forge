// Title         : eslint.config.js
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : 01.home/00.core/configs/languages/eslint.config.js
// ----------------------------------------------------------------------------
// ESLint flat config with TypeScript support

import js from '@eslint/js';
import typescript from 'typescript-eslint';
import prettier from 'eslint-config-prettier';

export default [
    js.configs.recommended,
    ...typescript.configs.recommended,
    ...typescript.configs.stylistic,
    prettier,

    // Global ignores
    {
        ignores: [
            '**/node_modules/**',
            '**/dist/**',
            '**/build/**',
            '**/.next/**',
            '**/.cache/**',
            '**/coverage/**',
            '**/*.min.js',
            '**/*.config.js',
            '**/*.config.ts',
        ],
    },

    // Custom rules for all files
    {
        files: ['**/*.{js,jsx,ts,tsx}'],
        languageOptions: {
            ecmaVersion: 2022,
            sourceType: 'module',
            globals: {
                console: 'readonly',
                process: 'readonly',
                Buffer: 'readonly',
                __dirname: 'readonly',
                __filename: 'readonly',
            },
        },
        rules: {
            'no-console': ['warn', { allow: ['warn', 'error'] }],
            'no-debugger': 'error',
            'no-unused-vars': 'off',
            '@typescript-eslint/no-unused-vars': [
                'error',
                {
                    argsIgnorePattern: '^_',
                    varsIgnorePattern: '^_',
                },
            ],
            '@typescript-eslint/no-explicit-any': 'warn',
            '@typescript-eslint/explicit-function-return-type': 'off',
            '@typescript-eslint/explicit-module-boundary-types': 'off',
            'prefer-const': 'error',
            'no-var': 'error',
            'object-shorthand': 'error',
            'prefer-template': 'error',
            'prefer-destructuring': [
                'error',
                {
                    array: true,
                    object: true,
                },
            ],
            'no-async-promise-executor': 'error',
            'require-await': 'error',
            'sort-imports': [
                'error',
                {
                    ignoreCase: true,
                    ignoreDeclarationSort: true,
                },
            ],
        },
    },

    // Test file overrides
    {
        files: ['**/*.test.{js,ts}', '**/*.spec.{js,ts}'],
        rules: {
            '@typescript-eslint/no-explicit-any': 'off',
            'no-console': 'off',
        },
    },
];
