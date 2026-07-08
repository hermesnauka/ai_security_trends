//! Offline utility to generate an Argon2id PHC hash for ADMIN_PASSWORD_HASH.
//! Usage: cargo run --bin hash_password -- '<plaintext password>'

use argon2::{
    Argon2,
    password_hash::{PasswordHasher, SaltString, rand_core::OsRng},
};

fn main() {
    let password = std::env::args()
        .nth(1)
        .expect("usage: hash_password <plaintext password>");

    let salt = SaltString::generate(&mut OsRng);
    let hash = Argon2::default()
        .hash_password(password.as_bytes(), &salt)
        .expect("failed to hash password")
        .to_string();

    println!("{hash}");
}
