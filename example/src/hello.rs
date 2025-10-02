fn main() {
    // Will fail clippy because we could just write println!("Hello World").
    println!("{}", "Hello World");

    // Will pass clippy
    // println!("Hello World!");
}
