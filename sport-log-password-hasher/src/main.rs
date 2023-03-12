//! The sport-log-password-hasher can hash passwords and verify if a password matches a password hash.
//!
//! The hashing method is the same as the one used in [`sport-log-server`](../sport_log_server/index.html).
//!
//! # Usage
//!
//! sport-log-password-hasher \[OPTIONS\]
//!
//! ### OPTIONS
//!
//! #### generate hash:
//! -g `password`
//!
//! #### verify password:
//! -v `hash` `password`

use std::env;

use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Algorithm, Argon2, Params, Version,
};
use rand_core::OsRng;

fn main() {
    let args: Vec<_> = env::args().collect();

    match &args[1..] {
        [mode, password] if mode == "-g" => {
            let salt = SaltString::generate(&mut OsRng);
            let password_hash = build_hasher()
                .hash_password(password.as_bytes(), &salt)
                .unwrap()
                .to_string();

            println!("{password_hash}");
        }
        [mode, hash, password] if mode == "-v" => {
            let hash = PasswordHash::new(hash.as_str()).unwrap();
            if build_hasher()
                .verify_password(password.as_bytes(), &hash)
                .is_ok()
            {
                println!("password matches hash");
            } else {
                println!("password does not match hash");
            }
        }
        _ => {
            println!(
                "sport-log-password-hasher\n\n\
                OPTIONS:\n\
                -g <password>\t\tgenerate hash\n\
                -v <hash> <password>\tverify password"
            );
        }
    }
}

pub fn build_hasher() -> Argon2<'static> {
    Argon2::new(
        Algorithm::Argon2id,
        Version::V0x13,
        Params::new(4096, 3, 1, Some(32)).unwrap(),
    )
}
