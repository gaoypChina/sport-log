use chrono::{DateTime, Utc};
use diesel::{PgConnection, QueryResult};

use crate::{
    Activity, CardioSessionDescription, Diary, GetByUser, MetconSessionDescription,
    StrengthSessionDescription, UserId, Wod,
};

impl Activity {
    fn join_and_order(
        diarys: Vec<Diary>,
        wods: Vec<Wod>,
        strength_session_descriptions: Vec<StrengthSessionDescription>,
        metcon_session_descriptions: Vec<MetconSessionDescription>,
        cardio_session_descriptions: Vec<CardioSessionDescription>,
    ) -> Vec<Self> {
        let mut activities = vec![];

        activities.extend(diarys.into_iter().map(|diary| {
            (
                DateTime::from_utc(diary.date.and_hms_opt(0, 0, 0).unwrap(), Utc),
                Activity::Diary(diary),
            )
        }));

        activities.extend(wods.into_iter().map(|wod| {
            (
                DateTime::from_utc(wod.date.and_hms_opt(0, 0, 0).unwrap(), Utc),
                Activity::Wod(wod),
            )
        }));

        activities.extend(strength_session_descriptions.into_iter().map(
            |strength_session_description| {
                (
                    strength_session_description.strength_session.datetime,
                    Activity::StrengthSession(strength_session_description),
                )
            },
        ));

        activities.extend(metcon_session_descriptions.into_iter().map(
            |metcon_session_description| {
                (
                    metcon_session_description.metcon_session.datetime,
                    Activity::MetconSession(metcon_session_description),
                )
            },
        ));

        activities.extend(cardio_session_descriptions.into_iter().map(
            |cardio_session_description| {
                (
                    cardio_session_description.cardio_session.datetime,
                    Activity::CardioSession(cardio_session_description),
                )
            },
        ));

        activities.sort_by(|a, b| b.0.cmp(&a.0));

        activities
            .into_iter()
            .map(|(_, activity)| activity)
            .collect()
    }

    pub fn get_ordered_by_user_and_timespan(
        user_id: UserId,
        start: DateTime<Utc>,
        end: DateTime<Utc>,
        db: &mut PgConnection,
    ) -> QueryResult<Vec<Self>> {
        Ok(Self::join_and_order(
            Diary::get_ordered_by_user_and_timespan(user_id, start, end, db)?,
            Wod::get_ordered_by_user_and_timespan(user_id, start, end, db)?,
            StrengthSessionDescription::get_ordered_by_user_and_timespan(user_id, start, end, db)?,
            MetconSessionDescription::get_ordered_by_user_and_timespan(user_id, start, end, db)?,
            CardioSessionDescription::get_ordered_by_user_and_timespan(user_id, start, end, db)?,
        ))
    }
}

impl GetByUser for Activity {
    fn get_by_user(user_id: UserId, db: &mut PgConnection) -> QueryResult<Vec<Self>> {
        Ok(Self::join_and_order(
            Diary::get_by_user(user_id, db)?,
            Wod::get_by_user(user_id, db)?,
            StrengthSessionDescription::get_by_user(user_id, db)?,
            MetconSessionDescription::get_by_user(user_id, db)?,
            CardioSessionDescription::get_by_user(user_id, db)?,
        ))
    }
}
