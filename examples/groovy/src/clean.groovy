/**
 * A clean Groovy file that passes all lint checks.
 */
class CleanExample {
    String name

    CleanExample(String name) {
        this.name = name
    }

    String greet() {
        return "Hello, ${name}!"
    }

    static void main(String[] args) {
        def example = new CleanExample("World")
        println example.greet()
    }
}
