fn main() {
    // Will emit a clippy warning because we could just write println!("Hello World").
    println!("{}", "Hello World");

    // Will fail clippy because of the missing comma
    let _missing_comma = &[
        -1, -2, -3 // <= no comma here
        -4, -5, -6
    ];

}