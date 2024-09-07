package main

import (
	"fmt"
)

const (
	w = "world"
)

func main() {
	hello   := fmt.Sprintf("Hello %s\n", w)
	fmt.Printf(hello)
}
