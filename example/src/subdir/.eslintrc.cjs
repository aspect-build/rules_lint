/* eslint-env node */
const base = require("../../.eslintrc.cjs");
base["rules"] = {   "no-debugger": 0, "no-console": 1 };
module.exports = base;
