# Cannery

The self-hosted firearm tracker website.

* Easy to Use: Cannery lets you easily keep an eye on your ammo levels before
  and after range day
* Secure: Self-host your own instance, or use an instance from someone you
  trust. Your data stays with you, period
* Simple: Access from any internet-capable device

# Features

- Create containers to store your ammunition, and tag them with custom tags
- Add ammunition types to Cannery, and then ammunition groups to your containers
- Stage groups of ammo for range day and record your ammo usage
- Invitations via invite tokens or public registration

# Installation

1. Install [Docker Compose](https://docs.docker.com/compose/install/) or alternatively [Docker Desktop](https://docs.docker.com/desktop/) on your machine.
1. Copy the example [docker-compose.yml](https://gitea.bubbletea.dev/shibao/cannery/src/branch/stable/docker-compose.yml). into your local machine where you want.
   Bind mounts are created in the same directory by default.
1. Set the configuration variables in `docker-compose.yml`. You'll need to run
   `docker run -it shibaobun/cannery /app/priv/random.sh` to generate a new
   secret key base.
1. Use `docker-compose up` or `docker-compose up -d` to start the container!

The first created user will be created as an admin.

## Reverse proxy

Finally, reverse proxy to port `4000` of the container. If you're using a reverse proxy in another docker container, you can reverse proxy to `http://cannery:4000`. Otherwise, you'll need to modify the `docker-compose.yml` to bind the port to your local machine.

For instance, instead of
```
expose:
  - "4000"
```

use
```
ports:
  - "127.0.0.1:4000:4000"
```
and reverse proxy to `http://localhost:4000`.

# Configuration

You can use the following environment variables to configure Cannery in
[docker-compose.yml](https://gitea.bubbletea.dev/shibao/cannery/src/branch/stable/docker-compose.yml).

- `HOST`: External url to generate links with. Must be set with your hosted
  domain name! I.e. `cannery.mywebsite.tld`
- `PORT`: Internal port to bind to. Defaults to `4000`. Must be reverse proxied!
- `DATABASE_URL`: Controls the database url to connect to. Defaults to
  `ecto://postgres:postgres@cannery-db/cannery`.
- `ECTO_IPV6`: If set to `true`, Ecto should use ipv6 to connect to PostgreSQL.
  Defaults to `false`.
- `POOL_SIZE`: Controls the pool size to use with PostgreSQL. Defaults to `10`.
- `SECRET_KEY_BASE`: Secret key base used to sign cookies. Must be generated
  with `docker run -it shibaobun/cannery mix phx.gen.secret` and set for server to start.
- `REGISTRATION`: Controls if user sign-up should be invite only or set to
  public. Set to `public` to enable public registration. Defaults to `invite`.
- `LOCALE`: Sets a custom locale. Defaults to `en_US`.
- `SMTP_HOST`: The url for your SMTP email provider. Must be set
- `SMTP_PORT`: The port for your SMTP relay. Defaults to `587`.
- `SMTP_USERNAME`: The username for your SMTP relay. Must be set!
- `SMTP_PASSWORD`: The password for your SMTP relay. Must be set!
- `SMTP_SSL`: Set to `true` to enable SSL for emails. Defaults to `false`.
- `EMAIL_FROM`: Sets the sender email in sent emails. Defaults to
  `no-reply@HOST` where `HOST` was previously defined.
- `EMAIL_NAME`: Sets the sender name in sent emails. Defaults to "Cannery".

# Contribution

Contributions are greatly appreciated, no ability to code needed! You can browse
the [Contribution
Guide](https://gitea.bubbletea.dev/shibao/cannery/src/branch/stable/CONTRIBUTING.md)
to learn more.

I can be contacted at [shibao@bubbletea.dev](mailto:shibao@bubbletea.dev), or on
the fediverse at
[@shibao@misskey.bubbletea.dev](https://misskey.bubbletea.dev/@shibao). Thank
you!

# License

Cannery is licensed under AGPLv3 or later. A copy of the latest version of the
license can be found at
[LICENSE.md](https://gitea.bubbletea.dev/shibao/cannery/src/branch/stable/LICENSE.md).

---

[![Build
Status](https://drone.bubbletea.dev/api/badges/shibao/cannery/status.svg?ref=refs/heads/dev)](https://drone.bubbletea.dev/shibao/cannery)
[![translation
status](https://weblate.bubbletea.dev/widgets/cannery/-/svg-badge.svg)](https://weblate.bubbletea.dev/engage/cannery/)
