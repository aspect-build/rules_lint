package src

import (
	// keep-sorted start
	"fmt"
	"os"
	"strings"
	// keep-sorted end
)

// Example demonstrates keep-sorted markers.
// The imports above are marked to be kept in sorted order.
// If you add a new import like "net/http", keep-sorted will ensure
// it's placed in the correct alphabetical position.
func Example() {
	fmt.Println(strings.Join(os.Args, " "))
}
