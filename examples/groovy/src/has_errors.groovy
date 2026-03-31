/**
 * A Groovy file with lint errors for testing.
 * The unused import below should be flagged and is auto-fixable.
 */

// Unused import - lint error, can be auto-fixed by using --fix
import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

class HasErrors {
    String name

    HasErrors(String name) {
        this.name = name
    }

    String greet() {
        def unusedVar = "this is unused"  // Unused variable - lint error
        return "Hello, ${name}!"
    }
}
