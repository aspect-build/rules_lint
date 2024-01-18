# Filter languages we understand
with_entries(select(.key | IN(
    "C++",
    "CSS",
    "Markdown",
    "Go",
    "HCL",
    "HTML",
    "Java",
    "JavaScript",
    "Jsonnet",
    "JSON",
    "Kotlin",
    "Protocol Buffer",
    "Python",
    "Scala",
    "Shell",
    "SQL",
    "Starlark",
    "Swift",
    "TSX",
    "TypeScript"
)))

# Convert values to filenames and extensions with star prefix
| with_entries(.value = (
    .value.filenames + (.value.extensions | map("*" + .))
))

# Render each language as a line in a Bash case statement, e.g.
# 'Jsonnet') patterns=('*.jsonnet' '*.libsonnet') ;;
| to_entries | map(    
  "'" + .key + "') patterns=(" + (.value | map("'" + . + "'") | join(" ")) + ") ;;"
)

# Suitable for --raw-output
|.[]