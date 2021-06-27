use diesel::QueryResult;
use rocket::http::Status;
use rocket_contrib::json::Json;

use crate::{model::*, repository as repo, Db};

pub mod account;
pub mod platform_credentials;

fn to_json<T>(query_result: QueryResult<T>) -> Result<Json<T>, Status> {
    query_result
        .map(Json)
        .map_err(|_| Status::InternalServerError)
}
