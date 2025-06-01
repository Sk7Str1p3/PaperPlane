#[cfg(feature = "meson")]
include!("cfg.rs");

#[cfg(feature = "build")]
include!(concat!(env!("OUT_DIR"), "/cfg.rs"));
