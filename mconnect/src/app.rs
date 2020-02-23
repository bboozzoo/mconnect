// The MIT License (MIT)
//
// Copyright (c) 2020 Maciek Borzecki <maciek.borzecki@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
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
