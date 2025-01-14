# OpenFn/Lightning (alpha) [![CircleCI](https://circleci.com/gh/OpenFn/Lightning/tree/main.svg?style=svg&circle-token=085c00fd6662e9a36012810fb7cf1f09f3604bc6)](https://circleci.com/gh/OpenFn/Lightning/tree/main) [![codecov](https://codecov.io/gh/OpenFn/Lightning/branch/main/graph/badge.svg?token=FfDMxdGL3a)](https://codecov.io/gh/OpenFn/Lightning) ![Docker Pulls](https://img.shields.io/docker/pulls/openfn/lightning)

A tool to help governments and social-sector organizations automate key business
processes and integrate critical systems, so they spend less time managing data
and more time focusing on their work.

Use OpenFn Lightning to visually build, execute and manage workflows.

- The latest version of the OpenFn technology - first launched in 2014, now
  tried and tested by NGOs in over 40 countries
- Fully open source (no premium features or community edition, you get the same
  product whether using SaaS or self-hosted)
- Recognised as a Digital Public Good by the
  [DPGA](https://digitalpublicgoods.net/) and a Global Good for Health by
  [Digital Square](https://digitalsquare.org/digital-health-global-goods)

![Screenshot 2023-03-15 at 13 01 13](https://user-images.githubusercontent.com/36554605/225275565-99c94f3b-3057-4185-9086-58015c28e77f.png)

Explore our [demo app](https://demo.openfn.org/) with username:
`demo@openfn.org`, password: `welcome123`, or read through the
[features](#features) section to view screenshots of the app.

## Table of contents

- [Features](#features)
- [Getting started](#getting-started)
  - [Run Lightning via Docker](#run-via-docker)
  - [Deploy Lightning on Docker or Kubernetes](#deploy-on-external-infrastructure)
  - [Run Lightning on your local machine (contributors)](#contribute-to-this-project)
  - [Troubleshooting](#troubleshooting)
- [Generate the documentation](#generating-documentation)
- [Security and standards](#security-and-standards)

## Features

Plan and build workflows using Lightning's visual interface to quickly define
when, where and what you want your automation to do.

![demo_screenshot](https://user-images.githubusercontent.com/36554605/223549338-3e7016b3-658f-4c7f-ab10-5784f9bbea95.png)

Monitor all workflow activity in one place.
![Screenshot 2023-03-21 at 10 07 37](https://user-images.githubusercontent.com/36554605/226538515-f8b97950-80b9-4e5e-a5f4-7406c20ed37a.png)

- Filter and search runs to identify issues that need addressing and follow how
  a specific request has been processed
- Configure alerts to be notified on run failures
- Receive a project digest for a daily/weekly/monthly summary of your project
  activity

Manage users and access by project
![Screenshot 2023-03-21 at 10 09 03](https://user-images.githubusercontent.com/36554605/226538682-e7f43407-2363-41eb-bee8-73307e7f3cf3.png)

## Getting Started

- If you only want to [_**RUN**_](#run-via-docker) Lightning on your own server,
  we recommend using Docker.
- If you want to [_**DEPLOY**_](#deploy-on-external-infrastructure) Lightning,
  we recommend Docker builds and Kubernetes.
- If you want to [_**CONTRIBUTE**_](#contribute-to-this-project) to the project,
  we recommend setting up Elixir on your local machine.

## **Run** via Docker

1. Install the latest version of
   [Docker](https://docs.docker.com/engine/install/)
2. Clone [this repo](https://github.com/OpenFn/Lightning) using git
3. Copy the `.env.example` file to `.env`
4. Run `docker compose run --rm web mix ecto.migrate`

By default the application will be running at
[localhost:4000](http://localhost:4000/).

You can then rebuild and run with `docker compose build` and
`docker compose up`. See ["Problems with Docker"](#problems-with-docker) for
additional troubleshooting help. Note that you can also create your own
`docker-compose.yml` file, configuring a postgres database and using a
[pre-built image](https://hub.docker.com/repository/docker/openfn/lightning)
from Dockerhub.

## **Deploy** on external infrastructure

See [Deployment](DEPLOYMENT.md) for more detailed information.

## **Benchmarking**

We are using [k6](https://k6.io/) to benchmark Lightning. Under `benchmarking`
folder you can find a script for benchmarking Webhook Workflows.

See [Benchmarking](benchmarking/BENCHMARKING.md) for more detailed information.

## **Contribute** to this project

First, thanks for being here! You're contributing to a digital public good that
will always be free and open source and aimed at serving innovative NGOs,
governments, and social impact organizations the world over! You rock. ❤️

FYI, Lightning is built in [Elixir](https://elixir-lang.org/), harnessing the
[Phoenix Framework](https://www.phoenixframework.org/). Currently, the only
unbundled dependency is a [PostgreSQL](https://www.postgresql.org/) database.

### Set up your environment

If you have push access to this repository (are you an authorized maintainer?)
then you'll be able to make changes and push them to a feature branch before
submitting a pull request. If you're new to OpenFn, you'll need to
[**make a fork**](https://github.com/OpenFn/Lightning/fork) and push your
changes there.

Once you're ready to submit a pull request, you can click the "compare across
forks" link on GitHub's
[pull request](https://github.com/OpenFn/Lightning/compare) interface and then
open one for review.

#### Clone the repo and optionally set ENVs

```sh
git clone git@github.com:OpenFn/Lightning.git # or from YOUR fork!
cd Lightning
cp .env.example .env # and adjust as necessary!
```

Take note of database names and ports in particular—they've got to match across
your Postgres setup and your ENVs. You can run lightning without any ENVs
assuming a vanilla postgres setup (see below), but you may want to make
adjustments.

#### Database Setup

If you're already using Postgres locally, create a new database called
`lightning_dev`, for example.

If you'd rather use Docker to set up a Postgres DB, create a new volume and
image:

```sh
docker volume create lightning-postgres-data

docker create \
  --name lightning-postgres \
  --mount source=lightning-postgres-data,target=/var/lib/postgresql/data \
  --publish 5432:5432 \
  -e POSTGRES_PASSWORD=postgres \
  postgres:14.1-alpine

docker start lightning-postgres
```

#### Elixir & Ecto Setup

We use [asdf](https://github.com/asdf-vm/asdf) to configure our local
environments. Included in the repo is a `.tool-versions` file that is read by
asdf in order to dynamically make the specified versions of Elixir and Erlang
available. You'll need asdf plugins for
[Erlang](https://github.com/asdf-vm/asdf-erlang),
[NodeJs](https://github.com/asdf-vm/asdf-nodejs), and
[Elixir](https://github.com/asdf-vm/asdf-elixir).

```sh
asdf install  # Install language versions
mix local.hex
mix deps.get
mix local.rebar --force
mix ecto.create # Create a development database in Postgres
mix ecto.migrate
mix lightning.install_runtime
mix lightning.install_schemas
npm install --prefix assets
```

### Run the app

Lightning is a web app. To run it in interactive Elixir mode, start the
development server by running with your environment variables by running:

```sh
iex -S mix phx.server
```

or if you have set up custom environment variables, run:

```sh
env $(cat .env | grep -v "#" | xargs ) iex -S mix phx.server
```

Once the server has started, head to [`localhost:4000`](http://localhost:4000)
in your browser.

### Run the tests

Before the first time running the tests, you need a test database setup.

```sh
MIX_ENV=test mix ecto.create
```

And then after that run the tests using:

```sh
MIX_ENV=test mix test
```

We also have `test.watch` installed which can be used to rerun the tests on file
changes.

### Generating Documentation

You can generate the HTML and EPUB documentation locally using:

`mix docs` and opening `doc/index.html` in your browser.

## Troubleshooting

### Trouble with environment variables

For troubleshooting custom environment variable configuration it's important to
know how an Elixir app loads and modifies configuration. The order is as
follows:

1. Stuff in `config.exs` is loaded.
2. _That_ is then modified (think: _overwritten_) by stuff your ENV-specific
   config: `dev.exs`, `prod.exs` or `test.exs`.
3. _That_ is then modified by `runtime.exs` which is where you are allowed to
   use `System.env()`
4. _Finally_ `init/2` (if present in a child application) gets called (which
   takes the config which has been set in steps 1-3) when that child application
   is started during the parent app startup defined in `application.ex`.

### Problems with Postgres

If you're having connecting issues with Postgres, check the database section of
your `.env` to ensure the DB url is correctly set for your environment — note
that composing a DB url out of other, earlier declared variables, does not work
while using `xargs`.

### Problems with Debian

If you're getting this error on debian

```
==> earmark_parser
Compiling 1 file (.yrl)
/usr/lib/erlang/lib/parsetools-2.3.1/include/yeccpre.hrl: no such file or directory
could not compile dependency :earmark_parser, "mix compile" failed. You can recompile this dependency with "mix deps.compile earmark_parser", update it with "mix deps.update earmark_parser" or clean it with "mix deps.clean earmark_parser"
```

You need to install erlang development environment `sudo apt install erlang-dev`
[refer to this issue](https://github.com/elixir-lang/ex_doc/issues/1441)

### Problems with Docker

#### Versions

The build may not work on old versions of Docker and Docker compose. It has been
tested against:

```
Docker version 20.10.17, build 100c701
Docker Compose version v2.6.0
```

#### Starting from scratch

If you're actively working with docker, you start experiencing issues, and you
would like to start from scratch you can clean up everything and start over like
this:

```sh
# To remove any ignored files and reset your .env to it's example
git clean -fdx && cp .env.example .env
# You can skip the line below if you want to keep your database
docker compose down --rmi all --volumes

docker compose build --no-cache web && \
  docker compose create --force-recreate

docker compose run --rm web mix ecto.migrate
docker compose up
```

### Security and Standards

We use a host of common Elixir static analysis tools to help us avoid common
pitfalls and make sure we keep everything clean and consistent.

In addition to our test suite, you can run the following commands:

- `mix format --check-formatted`  
  Code formatting checker, run again without the `--check-formatted` flag to
  have your code automatically changed.
- `mix dialyzer`  
  Static analysis for type mismatches and other common warnings. See
  [dialyxir](https://github.com/jeremyjh/dialyxir).
- `mix credo`  
  Static analysis for consistency, and coding standards. See
  [Credo](https://github.com/rrrene/credo).
- `mix sobelow`  
  Check for commonly known security exploits. See
  [Sobelow](https://sobelow.io/).
- `MIX_ENV=test mix coveralls`  
  Test coverage reporter. This command also runs the test suite, and can be used
  in place of `mix test` when checking everything before pushing your code. See
  [excoveralls](https://github.com/parroty/excoveralls).

> For convenience there is a `verify` mix task that runs all of the above and
> defaults the `MIX_ENV` to `test`.
