// A simple test file to verify clippy works with rust_test targets
#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        // Intentionally trigger a clippy warning
        let x = vec![1, 2, 3];
        let _len = x.len();
        if _len == 0 {
            println!("empty");
        }
        assert_eq!(2 + 2, 4);
    }
}
