import globals from "globals";


export default {
  extends: ["eslint:recommended", "plugin:react/recommended"],
  env: {
    browser: true
  },
  globals: Object.assign({}, globals.browser),
  rules: {
    "react/prop-types": 0
  }
};
