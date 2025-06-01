use std::env;
use std::process::Command;

pub(crate) fn build(app_id: &String, base_id: &String /*,gettext_package: &String*/) {
    let status = Command::new("msgfmt")
        .arg("--desktop")
        .args(["-d", "po"])
        .args(["-D", "po"])
        .args(["--template", &format!("data/{base_id}.desktop.in.in")])
        .args([
            "-o",
            &(env::var("OUT_DIR").unwrap() + &format!("/{app_id}.desktop")),
        ])
        .status()
        .expect("Failed to run msgfmt");

    if !status.success() {
        panic!("Failed to compile write desktop file!");
    }
}
