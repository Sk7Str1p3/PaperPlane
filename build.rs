//
// I wish this script was async so build would be much faster...
//
use duct::cmd;
use std::collections::HashMap;
use std::env;
use std::io::ErrorKind::NotFound;
use std::process::Command;

#[path = "data/build.rs"]
mod data;
#[path = "po/build.rs"]
mod locales;
#[path = "src/build.rs"]
mod src;
#[path = "src/ui/build.rs"]
mod ui;

#[cfg(feature = "build")]
fn main() {
    println!("Checking if all required dependencies are installed");
    check_deps();
    let mut profile = env::var("paper_PROFILE").unwrap_or_default();

    let base_id = "app.drey.PaperPlane".to_string();
    let mut app_id = base_id.clone();

    let mut version = "0.1.0-beta.5".to_string();

    if profile == "development" {
        profile = "Devel".to_string();
        app_id += profile.as_str();
        let rev_list = cmd!("git", "rev-list", "HEAD")
            .pipe(cmd!("tail", "-n", "1"))
            .read()
            .unwrap_or_default();
        let rev_parse = cmd!("git", "rev-parse", "--short", "HEAD")
            .read()
            .unwrap_or_default();

        let vsc_tag = if rev_list.is_empty() && rev_parse.is_empty() {
            "-devel"
        } else {
            &format!("-{rev_list}.{rev_parse}")
        };
        version += vsc_tag;
    }

    let name = "paper-plane".to_string();

    let share_dir = match env::var("out") {
        Ok(env) => format!("{env}/share"),
        Err(_) => "/usr/local/share".to_string(),
    };
    let locale_dir = format!("{share_dir}/locale");
    let pkgdata_dir = format!("{share_dir}/{name}");

    let api_id: i32 = env::var("paper_API_ID")
        .unwrap_or("17349".to_string())
        .as_str()
        .parse()
        .unwrap();
    let api_hash =
        env::var("paper_API_HASH").unwrap_or("344583e45741c457fe1862106095a5eb".to_string());

    src::build(
        &app_id,
        &pkgdata_dir,
        &profile,
        &version,
        &name,
        &locale_dir,
        &api_id,
        &api_hash,
    );
    data::build(&app_id, &base_id /*,&name*/);
    locales::build(&name);
}

#[cfg(feature = "meson")]
fn main() {
    println!("Building with meson, exiting!")
}

fn check_deps() {
    let libraries = HashMap::from([
        ("glib-2.0", "2.72"),
        ("gio-2.0", "2.72"),
        ("gtk4", "4.12"),
        ("libadwaita-1", "1.4"),
        ("shumate-1.0", "1"),
        ("tdjson", "1.8.19"),
    ]);
    let binaries = HashMap::from([
        ("glib-compile-resources", true),
        ("glib-compile-schemas", true),
        ("desktop-file-validate", false),
        ("appstream-util", false),
        ("msgfmt", true),
        ("cargo", true), // lol
    ]);

    for lib in libraries {
        let (name, version) = lib;
        match pkg_config::Config::new()
            .atleast_version(version)
            .probe(name)
        {
            Ok(_) => (),
            Err(err) => panic!("{err}"),
        };
    }
    for bin in binaries {
        let (name, req) = bin;
        match Command::new(name).spawn() {
            Ok(_) => println!("Found: {name}, required: {req}"),
            Err(e) => {
                if let NotFound = e.kind() {
                    match req {
                        false => println!("Optional dependency {name} not found, skipping."),
                        true => panic!("Dependency {name} is not found! Exiting"),
                    }
                }
            }
        };
    }
}
