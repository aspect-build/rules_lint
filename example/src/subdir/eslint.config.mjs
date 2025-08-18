// Demonstrate override for a subdirectory.
// Note that unlike eslint 8 and earlier, it does not resolve to a configuration file
// in a parent folder of the files being checked; instead it only looks in the working
// directory.
// https://eslint.org/docs/latest/use/configure/migration-guide#glob-based-configs
// @ts-check
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(eslint.configs.recommended, {
  files: ["**/*.ts"],
  extends: [
    ...tseslint.configs.recommendedTypeChecked,
    ...tseslint.configs.stylisticTypeChecked,
  ],
  rules: {
    "no-debugger": "off",
    "@typescript-eslint/no-redundant-type-constituents": "error",
    "sort-imports": "warn",
  },
  languageOptions: {
    parserOptions: {
      // indicates to find the closest tsconfig.json for each source file
      project: true,
    },
  },
});
