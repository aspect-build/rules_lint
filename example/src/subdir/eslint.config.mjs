import base from "../../eslint.config.mjs";

console.warn(base);

export default [
  ...base,
  {
    rules: {
      "no-debugger": "off",
    },
  },
];
