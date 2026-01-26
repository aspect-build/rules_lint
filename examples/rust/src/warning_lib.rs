pub fn _warning() {
    // Will emit a clippy warning because we could just write println!("Hello World").
    println!("{}", "Hello World");

    // Almost complete range
    // https://rust-lang.github.io/rust-clippy/stable/index.html#almost_complete_range
    let _ = 'a'..'z';

    // Nested warnings:
    // - Bool assert comparisons: https://rust-lang.github.io/rust-clippy/stable/index.html#bool_assert_comparison
    // - Format in format args: https://rust-lang.github.io/rust-clippy/stable/index.html#format_in_format_args
    assert_eq!(format!("{}", format!("{}", "hello")).is_empty(), false);
}