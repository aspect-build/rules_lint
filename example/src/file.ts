// this is a linting violation, and is auto-fixed under `--fix`
const a: string = "a";
console.log(a);

// linting violation; not auto-fixable
// Should be reported under `--fix` and lint will exit 1.
try {
  console.log();
} catch (e) {
  throw e;
}
