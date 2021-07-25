use std::ops::Deref;

use chrono::{NaiveDateTime, NaiveTime};
use diesel::{
    result::{DatabaseErrorKind as DbError, Error as DieselError},
    QueryResult,
};
use rocket::{http::Status, request::FromParam, serde::json::Json};

pub mod action;
pub mod activity;
pub mod cardio;
pub mod diary_wod;
pub mod metcon;
pub mod movement;
pub mod platform;
pub mod strength;
pub mod user;

trait IntoJson<T> {
    fn into_json(self) -> Result<Json<T>, Status>;
}

impl<T> IntoJson<T> for QueryResult<T> {
    fn into_json(self) -> Result<Json<T>, Status> {
        self.map(Json).map_err(|diesel_error| match diesel_error {
            DieselError::NotFound => Status::NoContent,
            DieselError::DatabaseError(db_error, _db_error_info) => match db_error {
                DbError::UniqueViolation => Status::Conflict,
                DbError::ForeignKeyViolation => Status::Conflict,
                _ => Status::InternalServerError,
            },
            _ => Status::InternalServerError,
        })
    }
}

pub struct NaiveTimeWrapper(NaiveTime);
pub struct NaiveDateTimeWrapper(NaiveDateTime);

impl<'v> FromParam<'v> for NaiveTimeWrapper {
    type Error = &'v str;

    fn from_param(param: &'v str) -> Result<Self, Self::Error> {
        Ok(NaiveTimeWrapper(param.parse().map_err(|_| param)?))
    }
}

impl<'v> FromParam<'v> for NaiveDateTimeWrapper {
    type Error = &'v str;

    fn from_param(param: &'v str) -> Result<NaiveDateTimeWrapper, Self::Error> {
        Ok(NaiveDateTimeWrapper(param.parse().map_err(|_| param)?))
    }
}

impl Deref for NaiveTimeWrapper {
    type Target = NaiveTime;
    fn deref(&self) -> &NaiveTime {
        &self.0
    }
}

impl Deref for NaiveDateTimeWrapper {
    type Target = NaiveDateTime;
    fn deref(&self) -> &NaiveDateTime {
        &self.0
    }
}
