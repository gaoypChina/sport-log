use chrono::NaiveDateTime;
use diesel::{prelude::*, PgConnection, QueryResult};

use crate::{
    schema::{cardio_session, diary, metcon_session, strength_session, wod},
    types::{Activity, CardioSession, Diary, MetconSession, StrengthSession, UserId, Wod},
};

impl Activity {
    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: NaiveDateTime,
        end: NaiveDateTime,
        conn: &PgConnection,
    ) -> QueryResult<Vec<Self>> {
        let mut activities = vec![];

        activities.extend(
            diary::table
                .filter(diary::columns::user_id.ge(user_id))
                .filter(diary::columns::date.ge(start.date()))
                .filter(diary::columns::date.le(end.date()))
                .get_results::<Diary>(conn)?
                .into_iter()
                .map(|diary| (diary.date.and_hms(0, 0, 0), Activity::Diary(diary))),
        );

        activities.extend(
            wod::table
                .filter(wod::columns::user_id.ge(user_id))
                .filter(wod::columns::date.ge(start.date()))
                .filter(wod::columns::date.le(end.date()))
                .get_results::<Wod>(conn)?
                .into_iter()
                .map(|wod| (wod.date.and_hms(0, 0, 0), Activity::Wod(wod))),
        );

        activities.extend(
            strength_session::table
                .filter(strength_session::columns::user_id.ge(user_id))
                .filter(strength_session::columns::datetime.ge(start))
                .filter(strength_session::columns::datetime.le(end))
                .get_results::<StrengthSession>(conn)?
                .into_iter()
                .map(|strength_session| {
                    (
                        strength_session.datetime,
                        Activity::StrengthSession(strength_session),
                    )
                }),
        );

        activities.extend(
            metcon_session::table
                .filter(metcon_session::columns::user_id.ge(user_id))
                .filter(metcon_session::columns::datetime.ge(start))
                .filter(metcon_session::columns::datetime.le(end))
                .get_results::<MetconSession>(conn)?
                .into_iter()
                .map(|metcon_session| {
                    (
                        metcon_session.datetime,
                        Activity::MetconSession(metcon_session),
                    )
                }),
        );

        activities.extend(
            cardio_session::table
                .filter(cardio_session::columns::user_id.ge(user_id))
                .filter(cardio_session::columns::datetime.ge(start))
                .filter(cardio_session::columns::datetime.le(end))
                .get_results::<CardioSession>(conn)?
                .into_iter()
                .map(|cardio_session| {
                    (
                        cardio_session.datetime,
                        Activity::CardioSession(cardio_session),
                    )
                }),
        );

        activities.sort_by(|a, b| b.0.cmp(&a.0));

        let activities = activities
            .into_iter()
            .map(|(_, activity)| activity)
            .collect();

        Ok(activities)
    }
}
