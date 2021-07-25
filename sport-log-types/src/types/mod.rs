#[cfg(feature = "full")]
use diesel::PgConnection;
use diesel::QueryResult;
#[cfg(feature = "full")]
use rocket::{
    data::{self, FromData},
    outcome::Outcome,
    serde::json::Json,
    Data, Request,
};
#[cfg(feature = "full")]
use serde::Deserialize;

mod action;
mod activity;
#[cfg(feature = "full")]
mod admin;
#[cfg(feature = "full")]
mod auth;
mod cardio;
#[cfg(feature = "full")]
mod config;
#[cfg(feature = "full")]
mod db;
mod diary_wod;
mod metcon;
mod movement;
mod platform;
mod sharing;
mod strength;
mod user;

pub use action::*;
pub use activity::*;
#[cfg(feature = "full")]
pub use admin::*;
#[cfg(feature = "full")]
pub use auth::*;
pub use cardio::*;
#[cfg(feature = "full")]
pub use config::*;
#[cfg(feature = "full")]
pub use db::*;
pub use diary_wod::*;
pub use metcon::*;
pub use movement::*;
pub use platform::*;
pub use sharing::*;
pub use strength::*;
pub use user::*;

#[cfg(feature = "full")]
pub struct Unverified<T>(Json<T>);

#[cfg(feature = "full")]
#[rocket::async_trait]
impl<'r, T: Deserialize<'r>> FromData<'r> for Unverified<T> {
    type Error = ();

    async fn from_data(req: &'r Request<'_>, data: Data<'r>) -> data::Outcome<'r, Self> {
        Outcome::Success(Self(Json::<T>::from_data(req, data).await.unwrap()))
    }
}

pub trait FromI32 {
    fn from_i32(value: i32) -> Self;
}

#[cfg(feature = "full")]
pub struct UnverifiedId<I>(I);

#[cfg(feature = "full")]
impl<'v, I: FromI32> rocket::request::FromParam<'v> for UnverifiedId<I> {
    type Error = &'v str;

    fn from_param(param: &'v str) -> Result<Self, Self::Error> {
        Ok(Self(I::from_i32(i32::from_param(param)?)))
    }
}

#[cfg(feature = "full")]
pub trait Create {
    type New;

    fn create(entity: Self::New, conn: &PgConnection) -> QueryResult<Self>
    where
        Self: Sized;
}

#[cfg(feature = "full")]
pub trait GetById {
    type Id;

    fn get_by_id(entity: Self::Id, conn: &PgConnection) -> QueryResult<Self>
    where
        Self: Sized;
}

#[cfg(feature = "full")]
pub trait GetByUser {
    fn get_by_user(entity: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

#[cfg(feature = "full")]
pub trait GetAll {
    fn get_all(conn: &PgConnection) -> QueryResult<Vec<Self>>
    where
        Self: Sized;
}

#[cfg(feature = "full")]
pub trait Update {
    fn update(entity: Self, conn: &PgConnection) -> QueryResult<Self>
    where
        Self: Sized;
}

#[cfg(feature = "full")]
pub trait Delete {
    type Id;

    fn delete(entity: Self::Id, conn: &PgConnection) -> QueryResult<usize>;
}
