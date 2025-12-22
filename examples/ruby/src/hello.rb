# Demo file showing RuboCop violations

# Unused variable (will be caught by RuboCop)
unused_variable = "not used"

# Line too long - this is a demonstration of a line that exceeds the maximum line length configured in .rubocop.yml
def example_method_with_very_long_line
  puts "This is an example of a line that is intentionally too long and should be flagged by RuboCop for exceeding the maximum line length"
end

# Missing frozen string literal comment (if configured)
class ExampleClass
  def initialize(name)
    @name = name
  end

  # Method with trailing whitespace and inconsistent indentation
  def greet
      puts "Hello, #{@name}!"
  end

  # Double negation (style issue)
  def active?
    !!@active
  end
end

# Prefer single quotes over double quotes for static strings
message = "Hello world"

# Trailing comma missing in multi-line array
numbers = [
  1,
  2,
  3
]

puts ExampleClass.new("World").greet
