/* eslint-env node */
const base = require("../../.eslintrc.cjs");
base["rules"] = {
    "no-debugger": 0,
    "@typescript-eslint/no-redundant-type-constituents": "error",
    "sort-imports": "error"
};
base["parserOptions"] = {
    project: "./src/subdir/tsconfig.json"
};
module.exports = base;
