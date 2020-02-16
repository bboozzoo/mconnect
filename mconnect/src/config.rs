use std::io;
use std::path::Path;

use glib;

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
                println!("user config not found, using defaults");
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
