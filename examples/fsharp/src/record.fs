module Record

// FSharpLint reports two violations in this file:
//   FL0039 RecordFieldNames: `name` should be PascalCase, as configured in /fsharplint.json
//   FL0065 Hints: `not true` can be simplified to `false`
// Run it outside Bazel, from the example root, to see the same result:
//   dotnet tool install --tool-path .tools dotnet-fsharplint --version 0.27.0
//   .tools/dotnet-fsharplint lint src/record.fs
type Person = { name: string }

let isDisabled = not true
