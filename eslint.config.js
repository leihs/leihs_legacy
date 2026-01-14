import prettierRecommended from 'eslint-plugin-prettier/recommended'
import react from 'eslint-plugin-react'
import globals from 'globals'

export default [
  {
    files: ['app/javascript/**/*.js'],
    languageOptions: {
      ecmaVersion: 2016,
      sourceType: 'module',
      parserOptions: {
        ecmaFeatures: {
          jsx: true
        }
      },
      globals: {
        ...globals.browser,
        ...globals.commonjs,
        ...globals.es2015
      }
    },
    plugins: {
      react
    },
    rules: {
      ...react.configs.recommended.rules,
      'react/prop-types': 'off'
    },
    settings: {
      react: {
        version: 'detect'
      }
    }
  },
  prettierRecommended
]
