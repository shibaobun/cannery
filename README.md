# Cannery is a personal ammo manager that adjusts to your own needs.

* Easy to Use: Cannery lets you easily keep an eye on your ammo levels before and after range day
* Secure: Self-host your own instance, or use an instance from someone you trust.
* Simple: Access from any internet-capable device

# Features

- Create containers to store your ammunition, and tag them with custom tags
- Add ammunition types to Cannery, and then ammunition to your containers
- Customizable invite tokens or public registration via the `REGISTRATION`
  environment variable.

# Installation

1. Install [Docker Compose](https://docs.docker.com/compose/install/) or alternatively [Docker Desktop](https://docs.docker.com/desktop/) on your machine.
1. Copy the example `docker-compose.yml` into your local machine where you want.
   Bind mounts are created in the same directory by default.
1. Use `docker-compose up` or `docker-compose up -d` to start the container.

## Reverse proxy

Finally, reverse proxy to port `80` of the container. If you're using a reverse proxy in another docker container, you can reverse proxy to `http://cannery:80`. Otherwise, you'll need to modify the `docker-compose.yml` to bind the port to your local machine.

For instance, instead of
```
expose:
  - "80"
```

use
```
ports:
  - "127.0.0.1:80:80"
```
and reverse proxy to `http://localhost:80`.

# Configuration

You can use the following environment variables to configure Cannery in
`docker-compose.yml`.

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
  with `docker exec -it cannery mix phx.gen.secret` and set for server to start.
- `REGISTRATION`: Controls if user sign-up should be invite only or set to public. Set to `public` to enable public registration. Defaults to `invite`.

# Contribution

Contributions are greatly appreciated! You can browse the [Contribution Guide](CONTRIBUTING.md) to learn more.

I can be contacted at [shibao@bubbletea.dev](mailto:shibao@bubbletea.dev), or on
the fediverse at [@shibao@misskey.bubbletea.dev](https://misskey.bubbletea.dev/@shibao). Thank you!

--

[![Build
Status](https://drone.bubbletea.dev/api/badges/shibao/cannery/status.svg?ref=refs/heads/dev)](https://drone.bubbletea.dev/shibao/cannery)
