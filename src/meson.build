subdir('ui')

global_conf = configuration_data()
global_conf.set_quoted('APP_ID', application_id)
global_conf.set_quoted('PKGDATADIR', pkgdatadir)
global_conf.set_quoted('PROFILE', profile)
global_conf.set_quoted('VERSION', version + version_suffix)
global_conf.set_quoted('GETTEXT_PACKAGE', gettext_package)
global_conf.set_quoted('LOCALEDIR', localedir)
global_conf.set('TG_API_ID', tg_api_id)
global_conf.set_quoted('TG_API_HASH', tg_api_hash)
config = configure_file(
  input: 'config.rs.in',
  output: 'cfg.rs',
  configuration: global_conf
)
# Copy the config.rs output to the source directory.
run_command(
  'cp',
  meson.project_build_root() / 'src' / 'cfg.rs',
  meson.project_source_root() / 'src' / 'cfg.rs',
  check: true
)

cargo_options = [ '--manifest-path', meson.project_source_root() / 'Cargo.toml' ]
cargo_options += [ '--target-dir', meson.project_build_root() / 'src' ]
cargo_options += [ '--no-default-features' ]
cargo_options += [ '--features', 'meson' ]

if get_option('profile') == 'default'
  cargo_options += [ '--release' ]
  rust_target = 'release'
  message('Building in release mode')
else
  rust_target = 'debug'
  message('Building in debug mode')
endif

cargo_env = [ 'CARGO_HOME=' + meson.project_build_root() / 'cargo-home' ]

custom_target(
  'cargo-build',
  build_by_default: true,
  build_always_stale: true,
  output: meson.project_name(),
  console: true,
  install: true,
  install_dir: bindir,
  depends: resources,
  command: [
    'env',
    cargo_env,
    cargo, 'build',
    cargo_options,
    '&&',
    'cp', 'src' / rust_target / meson.project_name(), '@OUTPUT@',
  ]
)

cargo = find_program('cargo', required: true)
cargo_target_dir = meson.project_build_root() / 'target'
cargo_home = meson.project_build_root() / 'cargo-home'
manifest_path = meson.project_source_root() / 'Cargo.toml'
test (
  'clippy',
  cargo,
  args: [
    'clippy',
    '--manifest-path=@0@'.format(manifest_path),
    '--target-dir=@0@'.format(cargo_target_dir),
    '--',
    '-D',
    'warnings',
  ],
  env: [
    'CARGO_HOME=@0@'.format(cargo_home),
    'PATH=/app/bin:/usr/bin:/usr/lib/sdk/llvm16/bin:/usr/lib/sdk/rust-stable/bin',
  ],
  timeout: 300, # Give cargo more time
)
