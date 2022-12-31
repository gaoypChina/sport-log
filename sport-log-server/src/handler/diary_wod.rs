use axum::{extract::Query, http::StatusCode, Json};
use sport_log_types::{
    AuthUserOrAP, Create, DbConn, Diary, DiaryId, GetById, GetByUser, UnverifiedId, Update,
    VerifyForUserOrAPWithDb, VerifyForUserOrAPWithoutDb, VerifyIdForUserOrAP,
    VerifyMultipleForUserOrAPWithDb, VerifyMultipleForUserOrAPWithoutDb, Wod, WodId,
};

use crate::handler::{HandlerResult, IdOption, UnverifiedSingleOrVec};

pub async fn create_wods(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(wods): Json<UnverifiedSingleOrVec<Wod>>,
) -> HandlerResult<StatusCode> {
    match wods {
        UnverifiedSingleOrVec::Single(wod) => {
            let wod = wod.verify_user_ap_without_db(auth)?;
            Wod::create(wod, &mut db)
        }
        UnverifiedSingleOrVec::Vec(wods) => {
            let wods = wods.verify_user_ap_without_db(auth)?;
            Wod::create_multiple(wods, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

//#[get("/wod/timespan/<start_datetime>/<end_datetime>")]
//pub async fn get_ordered_wods_by_timespan(
//auth: AuthUserOrAP,
//Path(start_datetime): Path<DateTime<Utc>>,
//Path(end_datetime): Path<DateTime<Utc>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<Wod>>> {
//Wod::get_ordered_by_user_and_timespan(*auth, start_datetime, end_datetime, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn get_wods(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<WodId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Wod>>> {
    match id {
        Some(id) => {
            let wod_id = id.verify_user_ap(auth, &mut db)?;
            Wod::get_by_id(wod_id, &mut db).map(|w| vec![w])
        }
        None => Wod::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn update_wods(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(wods): Json<UnverifiedSingleOrVec<Wod>>,
) -> HandlerResult<StatusCode> {
    match wods {
        UnverifiedSingleOrVec::Single(wod) => {
            let wod = wod.verify_user_ap(auth, &mut db)?;
            Wod::update(wod, &mut db)
        }
        UnverifiedSingleOrVec::Vec(wods) => {
            let wods = wods.verify_user_ap(auth, &mut db)?;
            Wod::update_multiple(wods, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_diaries(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(diaries): Json<UnverifiedSingleOrVec<Diary>>,
) -> HandlerResult<StatusCode> {
    match diaries {
        UnverifiedSingleOrVec::Single(diary) => {
            let diary = diary.verify_user_ap_without_db(auth)?;
            Diary::create(diary, &mut db)
        }
        UnverifiedSingleOrVec::Vec(diaries) => {
            let diaries = diaries.verify_user_ap_without_db(auth)?;
            Diary::create_multiple(diaries, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_diaries(
    auth: AuthUserOrAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<DiaryId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Diary>>> {
    match id {
        Some(id) => {
            let diary_id = id.verify_user_ap(auth, &mut db)?;
            Diary::get_by_id(diary_id, &mut db).map(|d| vec![d])
        }
        None => Diary::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

//#[get("/diary/timespan/<start_datetime>/<end_datetime>")]
//pub async fn get_ordered_diarys_by_timespan(
//auth: AuthUserOrAP,
//Path(start_datetime): Path<DateTime<Utc>>,
//Path(end_datetime): Path<DateTime<Utc>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<Diary>>> {
//Diary::get_ordered_by_user_and_timespan(*auth, start_datetime, end_datetime, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn update_diaries(
    auth: AuthUserOrAP,
    mut db: DbConn,
    Json(diaries): Json<UnverifiedSingleOrVec<Diary>>,
) -> HandlerResult<StatusCode> {
    match diaries {
        UnverifiedSingleOrVec::Single(diary) => {
            let diary = diary.verify_user_ap(auth, &mut db)?;
            Diary::update(diary, &mut db)
        }
        UnverifiedSingleOrVec::Vec(diaries) => {
            let diaries = diaries.verify_user_ap(auth, &mut db)?;
            Diary::update_multiple(diaries, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}
