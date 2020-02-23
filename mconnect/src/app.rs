use std::path::PathBuf;

use glib;

use super::config;

extern crate kdeconnect;

fn user_config_path() -> Result<PathBuf, String> {
    let user_config_dir = glib::get_user_config_dir()
        .ok_or("cannot obtain user config directory")?;

    let mut config_path = PathBuf::new();

    config_path.push(user_config_dir);
    config_path.push(config::NAME);
    println!("user config dir: {}", config_path.as_path().display());
    Ok(config_path)
}

pub fn run() -> Result<(), String> {
    let config_path = user_config_path()
        .or_else(|e| return Err(format!("cannot obtain user config path: {}", e)))?;

    let c = config::load_from_path(config_path);

    kdeconnect::bang();
    Ok(())
}
