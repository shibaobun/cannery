# Cannery is a personal ammo manager that adjusts to your own needs.

* Easy to Use: Cannery lets you easily keep an eye on your ammo levels before and after range day
* Secure: Self-host your own instance, or use an instance from someone you trust.
* Simple: Access from any internet-capable device

# Features

- User Registration/Sign in via `phx_gen_auth`
- `Dockerfile` and example `docker-compose.yml`
- Automatic migrations in `MIX_ENV=prod` or Docker image
- JS linting with [standard.js](https://standardjs.com), HEEx linting with
  [heex_formatter](https://github.com/feliperenan/heex_formatter)
- Customizable invite tokens or public registration via `REGISTRATION`
  environment variable.

# Installation

1. Install [Docker Compose](https://docs.docker.com/compose/install/) or alternatively [Docker Desktop](https://docs.docker.com/desktop/) on your machine.
1. Copy the example `docker-compose.yml` into your local machine where you want

# Local Development

1. Clone the repo
2. Run `mix setup`
3. Run `mix phx.server` to start the development server

# Configuration

For development, I recommend setting environment variables with [direnv](https://direnv.net).

## `MIX_ENV=dev`

In `dev` mode, Cannery will listen for these environment variables on compile.

- `HOST`: External url to generate links with. Set these especially if you're
  behind a reverse proxy. Defaults to `localhost`.
- `PORT`: External port for urls. Defaults to `443`.
- `DATABASE_URL`: Controls the database url to connect to. Defaults to
  `ecto://postgres:postgres@localhost/cannery_dev`.
- `REGISTRATION`: Controls if user sign-up should be invite only or set to public. Set to `public` to enable public registration. Defaults to `invite`.

## `MIX_ENV=prod`

In `prod` mode (or in the Docker container), Cannery will listen for these environment variables at runtime.

- `HOST`: External url to generate links with. Set these especially if you're
  behind a reverse proxy. Defaults to `localhost`.
- `PORT`: Internal port to bind to. Defaults to `4000` and attempts to bind to
  `0.0.0.0`. Must be reverse proxied!
- `DATABASE_URL`: Controls the database url to connect to. Defaults to
  `ecto://postgres:postgres@cannery-db/cannery`.
- `ECTO_IPV6`: Controls if Ecto should use ipv6 to connect to PostgreSQL.
  Defaults to `false`.
- `POOL_SIZE`: Controls the pool size to use with PostgreSQL. Defaults to `10`.
- `SECRET_KEY_BASE`: Secret key base used to sign cookies. Must be generated
  with `mix phx.gen.secret` and set for server to start.
- `REGISTRATION`: Controls if user sign-up should be invite only or set to public. Set to `public` to enable public registration. Defaults to `invite`.

---

[![Build
Status](https://drone.bubbletea.dev/api/badges/shibao/cannery/status.svg?ref=refs/heads/dev)](https://drone.bubbletea.dev/shibao/cannery)
