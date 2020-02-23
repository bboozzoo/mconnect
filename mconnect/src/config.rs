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
use std::io;
use std::path::Path;

use glib;
use log;

pub const NAME: &'static str = "mconnect.conf";

pub struct Config {
    kf: glib::KeyFile,
}

pub fn load_from_path<T: AsRef<Path>>(path: T) -> Result<Config, String> {
    let kf = glib::KeyFile::new();
    let c = Config { kf: kf };

    if let Err(err) = c.kf.load_from_file(path, glib::KeyFileFlags::KEEP_COMMENTS) {
        match err.kind::<glib::FileError>() {
            Some(glib::FileError::Noent) => {
                log::warn!("user config not found, using defaults");
                Ok(c)
            }
            _ => Err(err.to_string()),
        }
    } else {
        Ok(c)
    }
}

#[cfg(test)]
mod tests {
    use std::io::Write;
    use tempfile::NamedTempFile;

    #[test]
    fn simple_load() {
        let mut tmpf = NamedTempFile::new().expect("cannot create a temp file");
        writeln!(tmpf, "").expect("write failed");
        let res = super::load_from_path(tmpf.path());
        assert!(res.is_ok());
    }

    #[test]
    fn not_found_not_error() {
        let res = super::load_from_path("does-not-exist");
        assert!(res.is_ok());
    }

    #[test]
    fn bad_format() {
        let mut tmp = NamedTempFile::new().expect("cannot create a temp file");
        writeln!(tmp, "bad-format").expect("write failed");
        let res = super::load_from_path(tmp.path());
        assert!(res.is_err());
    }
}
