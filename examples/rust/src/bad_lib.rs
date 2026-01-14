fn bad() {
    // Will fail clippy because of the missing comma
    let _missing_comma = &[
        -1, -2, -3 // <= no comma here
        -4, -5, -6
    ];

}

