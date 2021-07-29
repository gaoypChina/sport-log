#[cfg(feature = "full")]
use diesel_derive_enum::DbEnum;
#[cfg(feature = "full")]
use rocket::http::Status;
use serde::{Deserialize, Serialize};

#[cfg(feature = "full")]
use sport_log_types_derive::{
    Create, CreateMultiple, Delete, FromI32, FromSql, GetAll, GetById, ToSql, Update, VerifyForAdminWithoutDb,
    VerifyIdForAdmin, VerifyIdForUserUnchecked,
};

use crate::types::UserId;
#[cfg(feature = "full")]
use crate::{
    schema::{eorm, movement},
    types::{
        AuthenticatedUser, GetById, Unverified, UnverifiedId, User, VerifyForUserWithDb,
        VerifyForUserWithoutDb, VerifyIdForUser,
    },
};

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum MovementCategory {
    Cardio,
    Strength,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(feature = "full", derive(DbEnum))]
pub enum MovementUnit {
    Reps,
    Cal,
    Meter,
    Km,
    Yard,
    Foot,
    Mile,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForAdmin,
        VerifyIdForUserUnchecked
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct MovementId(pub i32);

#[cfg(feature = "full")]
impl VerifyIdForUser<MovementId> for UnverifiedId<MovementId> {
    fn verify(self, auth: &AuthenticatedUser, conn: &PgConnection) -> Result<MovementId, Status> {
        let movement =
            Movement::get_by_id(self.0, conn).map_err(|_| rocket::http::Status::Forbidden)?;
        if movement.user_id == Some(**auth) {
            Ok(self.0)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }
}

#[cfg(feature = "full")]
impl UnverifiedId<MovementId> {
    pub fn verify_if_owned(
        self,
        auth: &AuthenticatedUser,
        conn: &PgConnection,
    ) -> Result<MovementId, Status> {
        let movement =
            Movement::get_by_id(self.0, conn).map_err(|_| rocket::http::Status::Forbidden)?;
        if movement.user_id.is_none() || movement.user_id == Some(**auth) {
            Ok(self.0)
        } else {
            Err(rocket::http::Status::Forbidden)
        }
    }
}

/// [Movement]
///
/// Movements can be predefined (`user_id` is [None]) or can be user-defined (`user_id` contains the id of the user).
///
/// `category` decides whether the Movement can be used in Cardio or Strength Sessions. For Metcons the category does not matter.
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create, CreateMultiple,
        GetById,
        GetAll,
        Update,
        Delete,
        VerifyForAdminWithoutDb
    )
)]
#[cfg_attr(feature = "full", table_name = "movement")]
#[cfg_attr(feature = "full", belongs_to(User))]
pub struct Movement {
    pub id: MovementId,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub user_id: Option<UserId>,
    pub name: String,
    #[cfg_attr(features = "full", changeset_options(treat_none_as_null = "true"))]
    pub description: Option<String>,
    pub category: MovementCategory,
}

#[cfg(feature = "full")]
impl VerifyForUserWithDb<Movement> for Unverified<Movement> {
    fn verify(self, auth: &AuthenticatedUser, conn: &PgConnection) -> Result<Movement, Status> {
        let movement = self.0.into_inner();
        if movement.user_id == Some(**auth)
            && Movement::get_by_id(movement.id, conn)
                .map_err(|_| Status::InternalServerError)?
                .user_id
                == Some(**auth)
        {
            Ok(movement)
        } else {
            Err(Status::Forbidden)
        }
    }
}

/// Please refer to [Movement].
#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "movement")]
pub struct NewMovement {
    pub user_id: Option<UserId>,
    pub name: String,
    pub description: Option<String>,
    pub category: MovementCategory,
}

#[cfg(feature = "full")]
impl VerifyForUserWithoutDb<NewMovement> for Unverified<NewMovement> {
    fn verify(self, auth: &AuthenticatedUser) -> Result<NewMovement, Status> {
        let movement = self.0.into_inner();
        if movement.user_id == Some(**auth) {
            Ok(movement)
        } else {
            Err(Status::Forbidden)
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, Eq, PartialEq)]
#[cfg_attr(
    feature = "full",
    derive(
        Hash,
        FromSqlRow,
        AsExpression,
        FromI32,
        ToSql,
        FromSql,
        VerifyIdForAdmin
    )
)]
#[cfg_attr(feature = "full", sql_type = "diesel::sql_types::Integer")]
pub struct EormId(pub i32);

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(
    feature = "full",
    derive(
        Associations,
        Identifiable,
        Queryable,
        AsChangeset,
        Create, CreateMultiple,
        GetById,
        GetAll,
        Update,
        Delete,
    )
)]
#[cfg_attr(feature = "full", table_name = "eorm")]
pub struct Eorm {
    pub id: EormId,
    pub reps: i32,
    pub percentage: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(feature = "full", derive(Insertable))]
#[cfg_attr(feature = "full", table_name = "eorm")]
pub struct NewEorm {
    pub reps: i32,
    pub percentage: f32,
}
