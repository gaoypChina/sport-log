use std::ops::Deref;

use chrono::{NaiveDateTime, NaiveTime};
use rocket::{http::RawStr, request::FromParam};

use super::*;
use crate::model::{
    Action, ActionEvent, ActionEventId, ActionId, ActionProviderId, ActionRule, ActionRuleId,
    ExecutableActionEvent, NewAction, NewActionEvent, NewActionRule, UserId,
};

#[post("/action", format = "application/json", data = "<action>")]
pub fn create_action(action: Json<NewAction>, conn: Db) -> Result<Json<Action>, Status> {
    to_json(Action::create(action.into_inner(), &conn))
}

#[get("/action/<action_id>")]
pub fn get_action(action_id: ActionId, conn: Db) -> Result<Json<Action>, Status> {
    to_json(Action::get_by_id(action_id, &conn))
}

#[get("/action/platform/<action_provider_id>")]
pub fn get_actions_by_platform(
    action_provider_id: ActionProviderId,
    conn: Db,
) -> Result<Json<Vec<Action>>, Status> {
    to_json(Action::get_by_action_provider(action_provider_id, &conn))
}

#[delete("/action/<action_id>")]
pub fn delete_action(action_id: ActionId, conn: Db) -> Result<Status, Status> {
    Action::delete(action_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}

#[post("/action_rule", format = "application/json", data = "<action_rule>")]
pub fn create_action_rule(
    action_rule: Json<NewActionRule>,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    to_json(ActionRule::create(action_rule.into_inner(), &conn))
}

#[get("/action_rule/<action_rule_id>")]
pub fn get_action_rule(action_rule_id: ActionRuleId, conn: Db) -> Result<Json<ActionRule>, Status> {
    to_json(ActionRule::get_by_id(action_rule_id, &conn))
}

#[get("/action_rule/user/<user_id>")]
pub fn get_action_rules_by_user(
    user_id: UserId,
    conn: Db,
) -> Result<Json<Vec<ActionRule>>, Status> {
    to_json(ActionRule::get_by_user(user_id, &conn))
}

//#[get("/action_rule/platform/<platform_id>")]
//pub fn get_action_rules_by_platform(
//platform_id: PlatformId,
//conn: Db,
//) -> Result<Json<Vec<ActionRule>>, Status> {
//to_json(ActionRule::get_by_platform(platform_id, &conn))
//}

//#[get("/action_rule/user/<user_id>/platform/<platform_id>")]
//pub fn get_action_rules_by_user_and_platform(
//user_id: UserId,
//platform_id: PlatformId,
//conn: Db,
//) -> Result<Json<Vec<ActionRule>>, Status> {
//to_json(ActionRule::get_by_user_and_platform(
//user_id,
//platform_id,
//&conn,
//))
//}

#[put("/action_rule", format = "application/json", data = "<action_rule>")]
pub fn update_action_rule(
    action_rule: Json<ActionRule>,
    conn: Db,
) -> Result<Json<ActionRule>, Status> {
    to_json(ActionRule::update(action_rule.into_inner(), &conn))
}

#[delete("/action_rule/<action_rule_id>")]
pub fn delete_action_rule(action_rule_id: ActionRuleId, conn: Db) -> Result<Status, Status> {
    ActionRule::delete(action_rule_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}

#[post("/action_event", format = "application/json", data = "<action_event>")]
pub fn create_action_event(
    action_event: Json<NewActionEvent>,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    to_json(ActionEvent::create(action_event.into_inner(), &conn))
}

#[get("/action_event/<action_event_id>")]
pub fn get_action_event(
    action_event_id: ActionEventId,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    to_json(ActionEvent::get_by_id(action_event_id, &conn))
}

#[get("/action_event/user/<user_id>")]
pub fn get_action_events_by_user(
    user_id: UserId,
    conn: Db,
) -> Result<Json<Vec<ActionEvent>>, Status> {
    to_json(ActionEvent::get_by_user(user_id, &conn))
}

//#[get("/action_event/platform/<platform_id>", rank = 1)]
//pub fn get_action_events_by_platform(
//platform_id: PlatformId,
//conn: Db,
//) -> Result<Json<Vec<ActionEvent>>, Status> {
//to_json(ActionEvent::get_by_platform(platform_id, &conn))
//}

//#[get("/action_event/platform/<platform_name>", rank = 2)]
//pub fn get_action_events_by_platform_name(
//platform_name: String,
//conn: Db,
//) -> Result<Json<Vec<ActionEvent>>, Status> {
//to_json(ActionEvent::get_by_platform_name(platform_name, &conn))
//}

//#[get("/action_event/user/<user_id>/platform/<platform_id>")]
//pub fn get_action_events_by_user_and_platform(
//user_id: UserId,
//platform_id: PlatformId,
//conn: Db,
//) -> Result<Json<Vec<ActionEvent>>, Status> {
//to_json(ActionEvent::get_by_user_and_platform(
//user_id,
//platform_id,
//&conn,
//))
//}

#[put("/action_event", format = "application/json", data = "<action_event>")]
pub fn update_action_event(
    action_event: Json<ActionEvent>,
    conn: Db,
) -> Result<Json<ActionEvent>, Status> {
    to_json(ActionEvent::update(action_event.into_inner(), &conn))
}

#[delete("/action_event/<action_event_id>")]
pub fn delete_action_event(action_event_id: ActionEventId, conn: Db) -> Result<Status, Status> {
    ActionEvent::delete(action_event_id, &conn)
        .map(|_| Status::NoContent)
        .map_err(|_| Status::InternalServerError)
}

#[get("/executable_action_event/platform/<action_provider_name>")]
pub fn get_executable_action_events_by_action_provider_name(
    action_provider_name: String,
    conn: Db,
) -> Result<Json<Vec<ExecutableActionEvent>>, Status> {
    to_json(ExecutableActionEvent::get_by_action_provider_name(
        action_provider_name,
        &conn,
    ))
}

#[get("/executable_action_event/platform/<action_provider_name>/timerange/<start_time>/<end_time>")]
pub fn get_executable_action_events_by_action_provider_name_and_timerange(
    action_provider_name: String,
    start_time: NaiveDateTimeWrapper,
    end_time: NaiveDateTimeWrapper,
    conn: Db,
) -> Result<Json<Vec<ExecutableActionEvent>>, Status> {
    to_json(
        ExecutableActionEvent::get_by_action_provider_name_and_timerange(
            action_provider_name,
            *start_time,
            *end_time,
            &conn,
        ),
    )
}

pub struct NaiveTimeWrapper(NaiveTime);
pub struct NaiveDateTimeWrapper(NaiveDateTime);

impl<'v> FromParam<'v> for NaiveTimeWrapper {
    type Error = &'v RawStr;

    fn from_param(param: &'v RawStr) -> Result<Self, Self::Error> {
        Ok(NaiveTimeWrapper(param.parse().map_err(|_| param)?))
    }
}

impl<'v> FromParam<'v> for NaiveDateTimeWrapper {
    type Error = &'v RawStr;

    fn from_param(param: &'v RawStr) -> Result<NaiveDateTimeWrapper, Self::Error> {
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
