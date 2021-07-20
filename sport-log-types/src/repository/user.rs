use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use diesel::{prelude::*, result::Error};
use rand_core::OsRng;

use crate::{
    schema::user,
    types::{NewUser, User, UserId},
};

impl User {
    pub fn create(mut user: NewUser, conn: &PgConnection) -> QueryResult<User> {
        let salt = SaltString::generate(&mut OsRng);
        let argon2 = Argon2::default();
        let password_hash = argon2
            .hash_password_simple(user.password.as_bytes(), salt.as_ref())
            .unwrap()
            .to_string();

        user.password = password_hash;

        diesel::insert_into(user::table)
            .values(user)
            .get_result(conn)
    }

    pub fn update(mut user: User, conn: &PgConnection) -> QueryResult<User> {
        let salt = SaltString::generate(&mut OsRng);
        let argon2 = Argon2::default();
        let password_hash = argon2
            .hash_password_simple(user.password.as_bytes(), salt.as_ref())
            .unwrap()
            .to_string();

        user.password = password_hash;

        diesel::update(user::table.find(user.id))
            .set(user)
            .get_result(conn)
    }

    pub fn authenticate(
        username: &str,
        password: &str,
        conn: &PgConnection,
    ) -> QueryResult<UserId> {
        let (user_id, password_hash): (UserId, String) = user::table
            .filter(user::columns::username.eq(username))
            .select((user::columns::id, user::columns::password))
            .get_result(conn)?;

        let password_hash = PasswordHash::new(password_hash.as_str()).unwrap();
        if Argon2::default()
            .verify_password(password.as_bytes(), &password_hash)
            .is_ok()
        {
            Ok(user_id)
        } else {
            Err(Error::NotFound)
        }
    }
}
