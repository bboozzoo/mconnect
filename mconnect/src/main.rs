mod app;
mod config;

fn main() {
    std::process::exit(match app::run() {
        Ok(_) => 0,
        Err(err) => {
            eprintln!("error: {}", err);
            1
        }
    });
}
