use std::{env, fs, process::Command, thread, time::Duration as StdDuration};

use chrono::{Duration, Local};
use reqwest::Client;
use serde::Deserialize;
use thirtyfour::prelude::*;
use tokio;

use sport_log_ap_utils::{delete_events, get_events, setup};
use sport_log_types::{ActionProviderId, NewAction, NewActionProvider, NewPlatform, PlatformId};

const NAME: &str = "wodify-login";
const DESCRIPTION: &str =
    "Wodify Login can reserve spots in classes. The action names correspond to the class types.";
const PLATFORM_NAME: &str = "wodify";

#[derive(Deserialize)]
struct Config {
    password: String,
    base_url: String,
}

impl Config {
    fn get() -> Self {
        toml::from_str(&fs::read_to_string("config.toml").unwrap()).unwrap()
    }
}

#[tokio::main]
async fn main() {
    match &env::args().collect::<Vec<_>>()[1..] {
        [] => login().await.unwrap(),
        [option] if option == "--setup" => {
            let config = Config::get();

            let platform = NewPlatform {
                name: PLATFORM_NAME.to_owned(),
            };

            let action_provider = NewActionProvider {
                name: NAME.to_owned(),
                password: config.password.clone(),
                platform_id: PlatformId(0), // TODO use generated id from platform
                description: Some(DESCRIPTION.to_owned()),
            };

            let actions = vec![
                NewAction {
                    name: "CrossFit".to_owned(),
                    action_provider_id: ActionProviderId(0), // TODO use generated id from action provider
                    description: Some("Reserve a spot in a CrossFit class.".to_owned()),
                    create_before: 168,
                    delete_after: 0,
                },
                NewAction {
                    name: "Weightlifting".to_owned(),
                    action_provider_id: ActionProviderId(0), // TODO use generated id from action provider
                    description: Some("Reserve a spot in a Weightlifting class.".to_owned()),
                    create_before: 168,
                    delete_after: 0,
                },
                NewAction {
                    name: "Open Fridge".to_owned(),
                    action_provider_id: ActionProviderId(0), // TODO use generated id from action provider
                    description: Some("Reserve a spot in a Open Fridge class.".to_owned()),
                    create_before: 168,
                    delete_after: 0,
                },
            ];

            setup(
                &config.base_url,
                NAME,
                &config.password,
                PLATFORM_NAME,
                platform,
                action_provider,
                actions,
            )
            .await;
        }
        [option] if ["help", "-h", "--help"].contains(&option.as_str()) => help(),
        _ => wrong_use(),
    }
}

fn help() {
    println!(
        "Wodify Login Action Provider\n\n\

        USAGE:\n\
        sport-log-action-provider-wodify-login [OPTIONS]\n\n\

        OPTIONS:\n\
        -h, --help\tprint this help page\n\
        --setup\t\tcreate own actions"
    );
}

fn wrong_use() {
    println!("no such options");
}

async fn login() -> WebDriverResult<()> {
    let config = Config::get();

    let client = Client::new();

    let exec_action_events = get_events(
        &client,
        &config.base_url,
        NAME,
        &config.password,
        Duration::hours(0),
        Duration::days(1) + Duration::minutes(1),
    )
    .await;
    println!("executable action events: {}\n", exec_action_events.len());

    if exec_action_events.is_empty() {
        return Ok(());
    }

    let mut webdriver = Command::new("../geckodriver").spawn().unwrap();

    let caps = DesiredCapabilities::firefox();
    let driver = WebDriver::new_with_timeout(
        "http://localhost:4444/",
        &caps,
        Some(StdDuration::from_secs(5)),
    )
    .await?;

    let mut delete_action_event_ids = vec![];
    // TODO execute in parallel
    for exec_action_event in exec_action_events {
        println!("{:#?}", exec_action_event);

        let time = exec_action_event.datetime.format("%-H:%M").to_string();
        let date = exec_action_event.datetime.format("%m/%d/%Y").to_string();
        println!("time: {:?}", time);
        println!("date: {:?}", date);
        println!("{:?}", exec_action_event.action_name);

        driver.delete_all_cookies().await?;
        driver
            .get("https://app.wodify.com/Schedule/CalendarListView.aspx")
            .await?;

        thread::sleep(StdDuration::from_secs(3));

        driver
            .find_element(By::Id("Input_UserName"))
            .await?
            .send_keys(&exec_action_event.username)
            .await?;
        driver
            .find_element(By::Id("Input_Password"))
            .await?
            .send_keys(&exec_action_event.password)
            .await?;
        driver
            .find_element(By::ClassName("signin-btn"))
            .await?
            .click()
            .await?;
        thread::sleep(StdDuration::from_secs(2));

        if let Err(_) = driver
            .find_element(By::Id("AthleteTheme_wt6_block_wt9_wtLogoutLink"))
            .await
        {
            println!("login failed");
            continue;
        }
        println!("login successful");

        while Local::now().naive_local() < exec_action_event.datetime - Duration::days(1) {
            thread::sleep(StdDuration::from_millis(100));
        }
        println!("ready");

        'event_loop: while Local::now().naive_local() < exec_action_event.datetime
        // - Duration::days(1) + Duration::minutes(1) // TODO
        {
            driver.refresh().await?; // TODO can this be removed?
            println!("searching");

            let rows = driver
                .find_elements(By::XPath("//table[@class='TableRecords']/tbody/tr"))
                .await?;
            println!("rows: {:?}", rows.len());

            let mut row_number = rows.len();
            for (i, row) in rows.iter().enumerate() {
                if let Ok(day) = row
                    .find_element(By::XPath("./td[1]/span[contains(@class, \"h3\")]"))
                    .await
                {
                    if day.inner_html().await?.contains(&date) {
                        println!("day found");
                        row_number = i;
                        break;
                    }
                }
            }
            println!("row number: {:?}", row_number);

            for row in &rows[row_number + 1..] {
                if let Ok(label) = row.find_element(By::XPath("./td[1]/div/span")).await {
                    let title = label.get_attribute("title").await?.unwrap();
                    println!("title: {:?}", title);
                    if title.contains(&exec_action_event.action_name) && title.contains(&time) {
                        println!("entry found");
                        //row.find_element(By::XPath("./td[3]/div/a"))
                        row.find_element(By::XPath("./td[3]/div"))
                            .await?
                            .click()
                            .await?;
                        println!("reserved");
                        thread::sleep(StdDuration::from_secs(2)); // TODO remove

                        delete_action_event_ids.push(exec_action_event.action_event_id);
                        break 'event_loop;
                    }
                }
            }
        }
    }
    println!("delete event ids: {:?}", delete_action_event_ids);
    if !delete_action_event_ids.is_empty() {
        delete_events(
            &client,
            &config.base_url,
            NAME,
            &config.password,
            &delete_action_event_ids,
        )
        .await;
    }

    println!("closing browser");
    driver.quit().await?;

    println!("terminating webdriver");
    let _ = webdriver.kill();

    Ok(())
}
