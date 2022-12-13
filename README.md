# honk-puma

## Installation

add `gem 'honk-puma'`

### How to use:

`bundle exec honk-puma`

### Configuration

This gem reads the following env variables and configures puma with them:

- `PORT` - The port to bind to, defaults to 3000 if not specified.
- `PUMA_MAX_WORKERS` - The number of workers to run at once.
  - `WEB_CONCURRENCY` - Fallback for `PUMA_MAX_WORKERS`
  - defaults to `3`
- `PUMA_DISABLE_NAKAYOSHI_FORK` - By-default the "nakayoshi_fork" method is enabled to reduce memory footprint. Set this = `1` to disable that.
  - Disabled automatically in development mode.
- `PUMA_ENABLE_FORK_WORKER_MODE` - Enables a more efficient worker forking method. This is not enabled by-default. Set = `1` to enable.
  - This can cause some apps to not function correctly.
  - This can also cause problems with the Nakayoshi Forking method.
  - Enabling will disable app preloading.
- `PUMA_RESTART_WORKERS_AFTER_REQUESTS` - a number of requests to do and then the worker will be culled and restarted.
  - Only used if Fork-Worker mode is enabled.
  - Default is 500 if not specified when fork-worker mode is enabled.
- `PUMA_RESTART_WORKERS_AFTER_REQUESTS_JITTER` - adds a small amount of randomness to the restart workers request count
  - Only used if Fork-Worker mode is enabled.
  - Default is 0
  - Set to a number of requests to "jitter" the main value by.
- `RAILS_ENV` - if `development`, most fancy features are disabled:
  - app preloading is disabled
  - fork-worker mode is never enabled
  - nakayoshi fork mode is never enabled
