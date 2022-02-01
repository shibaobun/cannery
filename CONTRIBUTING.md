# Contribution Guide

Thanks for contributing to Cannery! Please read over the style tips to help make
contributing to Cannery (hopefully) as great of an experience as you found it!

## Tips

- In order to cut down on code verbosity and readability, please try to use
  inline `do:` blocks for short functions and make your aliases as short as
  possible without introducing ambiguity.
  - I.e. since there's only one `Changeset` in the app, please alias
    `Changeset.t(Type.t())` instead of using `Ecto.Changeset.t(Long.Type.t())`
- Use pipelines when possible. If a function only calls a single method, a
  pipeline isn't strictly necessary but still encouraged for future
  modification.
- Please add typespecs to your functions! Even your private functions may be
  used by others later down the line, and typespecs will be able to help
  document your code just a little bit better, and improve the debugging
  process.
  - Typespec arguments can be named like `@spec function(arg_name :: type()) ::
    return_type()`. Please use these for generic types, such as `map()` when the
    input data isn't immediately obvious.
- When making new models, please take inspiration from the existing models in
  regards to layout of sections, typespec design, and formatting.
- With Elixir convention, for methods that raise on error please name them like
  `function_that_raises!()`, and functions that return a boolean like
  `function_that_returns_boolean?()`. For other methods, it's encouraged to use
  status tuples for other functions like `{:ok, result}` or `{:error,
  reason_or_changeset}` instead of just returning `result` or `nil` for easy
  pattern matching.
- Before submitting a PR, please make sure all tests are passing using `mix test`.

And as always, thank you!

# Features

- Created using the [Phoenix Framework](https://www.phoenixframework.org)
- User Registration/Sign in via [`phx_gen_auth`](https://hexdocs.pm/phx_gen_auth/).
- `Dockerfile` and example `docker-compose.yml`
- Automatic migrations in `MIX_ENV=prod` or Docker image
- JS linting with [standard.js](https://standardjs.com), HEEx linting with
  [heex_formatter](https://github.com/feliperenan/heex_formatter)

# Instructions

1. Clone the repo
1. Install the elixir and erlang binaries. I recommend using [asdf version
   manager](https://asdf-vm.com/guide/getting-started.html#_1-install-dependencies),
   which will use the `.tool-versions` file to install the correct versions of
   Erlang, Elixir and npm for this project!
1. Run `mix deps.get` and `mix compile` to fetch all dependencies
1. Run `mix setup` to initialize your database.
1. Run `mix phx.server` to start the development server.

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
- `PORT`: Internal port to bind to. Defaults to `80` and attempts to bind to
  `0.0.0.0`. Must be reverse proxied!
- `DATABASE_URL`: Controls the database url to connect to. Defaults to
  `ecto://postgres:postgres@cannery-db/cannery`.
- `ECTO_IPV6`: Controls if Ecto should use ipv6 to connect to PostgreSQL.
  Defaults to `false`.
- `POOL_SIZE`: Controls the pool size to use with PostgreSQL. Defaults to `10`.
- `SECRET_KEY_BASE`: Secret key base used to sign cookies. Must be generated
  with `mix phx.gen.secret` and set for server to start.
- `REGISTRATION`: Controls if user sign-up should be invite only or set to public. Set to `public` to enable public registration. Defaults to `invite`.
