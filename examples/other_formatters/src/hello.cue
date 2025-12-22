// Intentionally poorly formatted CUE file
package hello

#Person: {
	name:   string
	age:    int
	email?: string
}

people: [...#Person] & [
	{name: "Alice", age: 30},
	{name: "Bob", age: 25, email: "bob@example.com"},
]
