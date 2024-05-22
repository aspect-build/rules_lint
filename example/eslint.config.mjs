// @ts-check

import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  {
    files: ["src/**/*.ts"],
    extends: [
      ...tseslint.configs.recommendedTypeChecked,
      ...tseslint.configs.stylisticTypeChecked,
    ],
    languageOptions: {
      parserOptions: {
        // indicates to find the closest tsconfig.json for each source file
        project: true,
      },
    },
  },
  // Demonstrate override for a subdirectory.
  // Note that unlike eslint 8 and earlier, it does not resolve to a configuration file
  // in a parent folder of the files being checked; instead it only looks in the working
  // directory.
  // https://eslint.org/docs/latest/use/configure/migration-guide#glob-based-configs
  {
    files: ["src/subdir/**"],
    rules: {
      "no-debugger": "off",
      "@typescript-eslint/no-redundant-type-constituents": "error",
      "sort-imports": "warn",
    },
  }
);
