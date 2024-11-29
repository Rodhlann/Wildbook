import globals from "globals";
import pluginJs from "@eslint/js";
import pluginReactConfig from "eslint-plugin-react/configs/recommended.js";
import babelParser from "@babel/eslint-parser";
import reactHooks from "eslint-plugin-react-hooks";
import jestPlugin from "eslint-plugin-jest";
import importPlugin from "eslint-plugin-import";

export default [
  // Base configurations
  pluginJs.configs.recommended,
  pluginReactConfig,

  // Global React configuration
  {
    files: ["**/*.{js,mjs,cjs,jsx}"],
    plugins: {
      "react-hooks": reactHooks,
      import: importPlugin,
    },
    languageOptions: {
      globals: {
        ...globals.browser,
        process: "readonly",
      },
      parser: babelParser,
      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
    settings: {
      react: {
        version: "detect",
      },
      "import/resolver": {
        node: {
          extensions: [".js", ".jsx"],
        },
      },
    },
    rules: {
      // Consolidated and simplified rule configuration
      semi: ["error", "always"],
      "no-unused-vars": [
        "error",
        {
          vars: "all",
          args: "after-used",
          ignoreRestSiblings: false,
          varsIgnorePattern: "^_",
          argsIgnorePattern: "^_",
          caughtErrors: "all",
          caughtErrorsIgnorePattern: "^_",
        },
      ],
      "no-console": "warn",

      // React-specific rules with more controlled disabling
      "react/prop-types": "off",
      "react/jsx-no-bind": "off",
      "react/jsx-filename-extension": "off",
      "react/jsx-props-no-spreading": "off",
      "react/style-prop-object": ["error", { allow: ["FormattedNumber"] }],

      // Import plugin rules
      "import/prefer-default-export": "off",

      // Relaxed formatting and style rules
      curly: "off",
      indent: "off",
      camelcase: "off",
      "space-before-function-paren": "off",
      "operator-linebreak": "off",
      "object-curly-newline": "off",
      "arrow-parens": "off",

      // Potential error prevention
      "no-param-reassign": "warn",
      "no-mixed-operators": "off",
      "no-else-return": "off",
    },
  },

  // Configuration files
  {
    files: ["**/babel.config.js", "**/jest.config.js", "**/*.config.js"],
    languageOptions: {
      globals: {
        ...globals.node,
        require: "readonly",
        module: "readonly",
        __dirname: "readonly",
        process: "readonly",
      },
    },
  },

  // Node.js scripts
  {
    files: ["**/*.{js,cjs}", "**/scripts/**/*.js"],
    languageOptions: {
      globals: {
        ...globals.node,
      },
    },
  },

  // Jest test files
  {
    files: ["**/*.test.js"],
    plugins: {
      jest: jestPlugin,
    },
    languageOptions: {
      globals: jestPlugin.environments.globals.globals,
    },
    rules: {
      ...jestPlugin.configs.recommended.rules,
    },
  },
];
