use meson_next as meson;
use std::collections::HashMap;
use std::env;
use std::path::PathBuf;

// This code calls meson to build project
fn main() {
    // Because this code works like this:
    //
    // cargo build => build.rs => meson => cargo build => build.rs
    //
    // we must prevent build from launching more than one time
    // or this would lead to infinite compilation
    let lever = "isBuildStarted";
    if env::var(lever).unwrap_or(0.to_string()) == "1" {
        println!("Build is already startred! Exiting");
        return;
    }
    env::set_var(lever, "1");

    let build_path = PathBuf::from(env::var("OUT_DIR").unwrap()).join("build");
    let build_path = build_path.to_str().unwrap();

    let mut options = HashMap::new();
    options.insert("tg_api_id", "22303002");
    options.insert("tg_api_hash","3cc0969992690f032197e6609b296599");

    let config = meson::Config::new().options(options);

    meson::build(".", build_path, config);
}
