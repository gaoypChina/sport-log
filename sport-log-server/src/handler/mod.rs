use chrono::{DateTime, Utc};
use serde::Deserialize;

use crate::db::Unverified;
pub use crate::error::*;

mod account;
mod action;
//mod activity;
mod cardio;
mod diary_wod;
mod garbage_collection;
mod metcon;
mod movement;
mod platform;
mod strength;
//mod training_plan;
mod user;

pub use account::*;
pub use action::*;
//pub use activity::*;
pub use cardio::*;
pub use diary_wod::*;
pub use garbage_collection::*;
pub use metcon::*;
pub use movement::*;
pub use platform::*;
pub use strength::*;
//pub use training_plan::*;
pub use user::*;

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum UnverifiedSingleOrVec<T> {
    Single(Unverified<T>),
    Vec(Unverified<Vec<T>>),
}

#[derive(Debug, Deserialize)]
pub struct IdOption<T> {
    #[serde(default = "none")]
    pub id: Option<T>,
}

#[derive(Debug, Deserialize)]
pub struct TimeSpanOption {
    #[serde(default = "none")]
    pub start: Option<DateTime<Utc>>,
    #[serde(default = "none")]
    pub end: Option<DateTime<Utc>>,
}

fn none<T>() -> Option<T> {
    None
}
