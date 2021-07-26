use chrono::NaiveDateTime;
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::cardio_session,
    types::{
        CardioSession, CardioSessionDescription, CardioSessionId, GetById, GetByUser, Movement,
        Route, UserId,
    },
};

impl CardioSession {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: NaiveDateTime,
        end: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        cardio_session::table
            .filter(cardio_session::columns::user_id.ge(user_id))
            .filter(cardio_session::columns::datetime.ge(start))
            .filter(cardio_session::columns::datetime.le(end))
            .order_by(cardio_session::columns::datetime)
            .get_results(conn)
    }
}

impl GetById for CardioSessionDescription {
    type Id = CardioSessionId;

    // TODO add endpoint
    fn get_by_id(cardio_session_id: Self::Id, conn: &PgConnection) -> QueryResult<Self> {
        let cardio_session = CardioSession::get_by_id(cardio_session_id, conn)?;
        CardioSessionDescription::from_session(cardio_session, conn)
    }
}

impl GetByUser for CardioSessionDescription {
    // TODO add endpoint
    fn get_by_user(user_id: UserId, conn: &PgConnection) -> QueryResult<Vec<Self>> {
        let cardio_sessions = CardioSession::get_by_user(user_id, conn)?;
        CardioSessionDescription::from_sessions(cardio_sessions, conn)
    }
}

impl CardioSessionDescription {
    fn from_session(cardio_session: CardioSession, conn: &PgConnection) -> QueryResult<Self> {
        let route = match cardio_session.route_id {
            Some(route_id) => Some(Route::get_by_id(route_id, conn)?),
            None => None,
        };
        let movement = Movement::get_by_id(cardio_session.movement_id, conn)?;
        Ok(CardioSessionDescription {
            cardio_session,
            route,
            movement,
        })
    }

    fn from_sessions(
        cardio_sessions: Vec<CardioSession>,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let mut routes = vec![];
        for cardio_session in &cardio_sessions {
            routes.push(match cardio_session.route_id {
                Some(route_id) => Some(Route::get_by_id(route_id, conn)?),
                None => None,
            });
        }
        let mut movements = vec![];
        for cardio_session in &cardio_sessions {
            movements.push(Movement::get_by_id(cardio_session.movement_id, conn)?);
        }
        Ok(cardio_sessions
            .into_iter()
            .zip(routes)
            .zip(movements)
            .map(
                |((cardio_session, route), movement)| CardioSessionDescription {
                    cardio_session,
                    route,
                    movement,
                },
            )
            .collect())
    }

    // TODO add endpoint
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: NaiveDateTime,
        end: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let cardio_sessions =
            CardioSession::get_ordered_by_user_and_timespan(user_id, start, end, conn)?;
        CardioSessionDescription::from_sessions(cardio_sessions, conn)
    }
}
