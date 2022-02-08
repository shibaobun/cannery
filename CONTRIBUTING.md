# Contribution Guide

Thanks for contributing to Cannery! Please read over the style tips to help make
contributing to Cannery (hopefully) as great of an experience as you found it!

## Translations needed!

[![translation
status](https://weblate.bubbletea.dev/widgets/cannery/-/287x66-black.png)](https://weblate.bubbletea.dev/engage/cannery)

If you're multilingual, this project can use your translations! Visit
[weblate](https://weblate.bubbletea.dev/engage/cannery/) for more information.

## Style Tips

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
  - Please define all typespecs for a function together in one place, instead of
    each function.
- When making new models, please take inspiration from the existing models in
  regards to layout of sections, typespec design, and formatting.
- With Elixir convention, for methods that raise on error please name them like
  `function_that_raises!()`, and functions that return a boolean like
  `function_that_returns_boolean?()`. For other methods, it's encouraged to use
  status tuples for other functions like `{:ok, result}` or `{:error,
  reason_or_changeset}` instead of just returning `result` or `nil` for easy
  pattern matching.
- When adding text, please use `gettext` macros to enable things to be
  translated in the future. After adding `gettext` macros, run `mix format` in
  order to add your new text strings to the files in `priv/gettext`.
- Before submitting a PR, please make sure all tests are passing using `mix test`.

And as always, thank you!

# Technical Information

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

For development, I recommend setting environment variables with
[direnv](https://direnv.net).

By default, Cannery will always bind to all external IPv4 and IPv6 addresses in
`dev` and `prod` mode, respectively. If you would like to use different values,
they will need to be overridden in `config/dev.exs` and `config/runtime.exs` for
`dev` and `prod` modes, respectively.

## `MIX_ENV=dev`

In `dev` mode, Cannery will listen for these environment variables at runtime.

- `HOST`: External url to generate links with. Set this especially if you're
  behind a reverse proxy. Defaults to `localhost`. External URLs will always be
  generated with `https://` and port `443`.
- `PORT`: Internal port to bind to. Defaults to `4000`.
- `DATABASE_URL`: Controls the database url to connect to. Defaults to
  `ecto://postgres:postgres@localhost/cannery_dev`.
- `ECTO_IPV6`: Controls if Ecto should use IPv6 to connect to PostgreSQL.
  Defaults to `false`.
- `POOL_SIZE`: Controls the pool size to use with PostgreSQL. Defaults to `10`.
- `REGISTRATION`: Controls if user sign-up should be invite only or set to public. Set to `public` to enable public registration. Defaults to `invite`.
- `LOCALE`: Sets a custom locale. Defaults to `en_US`.

## `MIX_ENV=test`

In `test` mode (or in the Docker container), Cannery will listen for the same environment variables as dev mode, but also include the following at runtime:

- `TEST_DATABASE_URL`: REPLACES `DATABASE_URL`. Controls the database url to
  connect to. Defaults to `ecto://postgres:postgres@localhost/cannery_test`.
- `MIX_TEST_PARTITION`: Only used if `TEST_DATABASE_URL` is not specified.
  Appended to the default database url if you would like to partition your test
  databases. Defaults to not set.

## `MIX_ENV=prod`

In `prod` mode (or in the Docker container), Cannery will listen for the same environment variables as dev mode, but also include the following at runtime:

- `SECRET_KEY_BASE`: Secret key base used to sign cookies. Must be generated
  with `docker run -it shibaobun/cannery mix phx.gen.secret` and set for server to start.
