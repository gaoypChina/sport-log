use chrono::{NaiveDate, NaiveDateTime};
use serde::{Deserialize, Serialize};

use sport_log_server_derive::{
    Create, Delete, GetAll, GetById, InnerIntFromSql, InnerIntToSql, Update, VerifyForUserWithDb,
    VerifyForUserWithoutDb,
};

use crate::{
    model::UserId,
    schema::{diary, wod},
};

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct DiaryId(pub i32);

#[derive(
    Queryable, AsChangeset, Serialize, Deserialize, Debug, Create, GetById, GetAll, Update, Delete,
)]
#[table_name = "diary"]
pub struct Diary {
    pub id: DiaryId,
    pub user_id: UserId,
    pub date: NaiveDate,
    pub bodyweight: Option<f32>,
    pub comments: Option<String>,
}

#[derive(Insertable, Serialize, Deserialize)]
#[table_name = "diary"]
pub struct NewDiary {
    pub user_id: UserId,
    pub date: NaiveDate,
    pub bodyweight: Option<f32>,
    pub comments: Option<String>,
}

#[derive(
    FromSqlRow,
    AsExpression,
    Serialize,
    Deserialize,
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    InnerIntToSql,
    InnerIntFromSql,
)]
#[sql_type = "diesel::sql_types::Integer"]
pub struct WodId(pub i32);

#[derive(
    Queryable,
    AsChangeset,
    Serialize,
    Deserialize,
    Debug,
    Create,
    GetById,
    GetAll,
    Update,
    Delete,
    VerifyForUserWithDb,
)]
#[table_name = "wod"]
pub struct Wod {
    pub id: WodId,
    pub user_id: UserId,
    pub date: NaiveDate,
    pub description: Option<String>,
}

#[derive(Insertable, Serialize, Deserialize, VerifyForUserWithoutDb)]
#[table_name = "wod"]
pub struct NewWod {
    pub user_id: UserId,
    pub date: NaiveDate,
    pub description: Option<String>,
}
