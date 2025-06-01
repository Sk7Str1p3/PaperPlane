use std::env;
use std::fs;

pub(crate) fn build(
    app_id: &String,
    pkgdata_dir: &String,
    profile: &String,
    version: &String,
    gettext_package: &String,
    locale_dir: &String,
    api_id: &i32,
    api_hash: &String,
) {
    let contents = fs::read_to_string("src/config.rs.in")
        .unwrap()
        .replace("@APP_ID@", &format!("\"{app_id}\""))
        .replace("@GETTEXT_PACKAGE@", &format!("\"{gettext_package}\""))
        .replace("@LOCALEDIR@", &format!("\"{locale_dir}\""))
        .replace("@PKGDATADIR@", &format!("\"{pkgdata_dir}\""))
        .replace("@PROFILE@", &format!("\"{profile}\""))
        .replace("@TG_API_HASH@", &format!("\"{api_hash}\""))
        .replace("@TG_API_ID@", &format!("{api_id}"))
        .replace("@VERSION@", &format!("\"{version}\""));
    fs::write(
        format!("{}/cfg.rs", env::var("OUT_DIR").unwrap()),
        contents.trim(),
    )
    .unwrap()
}
