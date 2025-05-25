use meson_next as meson;
use std::{collections::HashMap, env, path::PathBuf };

fn main() {
    let build_path = PathBuf::from(env::var("OUT_DIR").unwrap()).join("build");
    let build_path = build_path.to_str().unwrap();

    let mut options = HashMap::new();
    options.insert("tg_api_id", "22303002");
    options.insert("tg_api_hash","3cc0969992690f032197e6609b296599");

    let config = meson::Config::new().options(options);

    meson::build(".", build_path, config);
}
