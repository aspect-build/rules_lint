fn main() {
    // Will fail clippy because there are no arguments passed to {}.
    // println!("Hello World! {}");

    // Will pass clippy
    println!("Hello World!");
}
