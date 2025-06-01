use std::env;
use std::path::Path;
use std::process::Command;

pub(crate) fn build(gettext_name: &String) {
    let in_dir = Path::new("po");
    let mut out_dir = env::var("OUT_DIR").unwrap();
    out_dir.push_str("/locales");

    for locale in std::fs::read_dir(in_dir).unwrap() {
        let path = locale.unwrap().path();
        if path.extension().map_or(false, |ex| ex == "po") {
            let lang = path.file_stem().unwrap().to_str().unwrap();
            let mo_path = Path::new(&out_dir)
                .join(lang)
                .join("LC_MESSAGES")
                .join(format!("{gettext_name}.mo"));
            std::fs::create_dir_all(mo_path.parent().unwrap()).unwrap();

            let status = Command::new("msgfmt")
                .arg("--check")
                .arg("--output-file")
                .arg(&mo_path)
                .arg(&path)
                .status()
                .expect("Failed to run msgfmt");

            if !status.success() {
                panic!("Failed to compile {} to MO", path.display());
            }

            println!("cargo:rerun-if-changed={}", path.display());
        }
    }
}
