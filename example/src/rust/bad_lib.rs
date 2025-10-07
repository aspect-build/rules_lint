fn bad() {
    // Will fail clippy because we could just write println!("Hello World").
    println!("{}", "Hello World");
}