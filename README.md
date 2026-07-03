# GCA Commercial Value Tool — Backend API

![CI](https://github.com/Crown-Commercial-Service/gca-cvt-backend/actions/workflows/ci.yml/badge.svg)

This is the Rails API backend for the Commercial Value Tool. It provides JSON endpoints consumed by the CVT frontend.

## Prerequisites

This guide assumes you have [Homebrew][] installed.

### Ruby

This is a [Ruby on Rails][] application using Ruby `3.4.7`. Ensure your Ruby version manager is set to the correct version before proceeding.

### PostgreSQL

Install [PostgreSQL][]:

```shell
brew install postgresql@17
```

## Developer setup

Clone the repository and move into the project directory. Confirm your Ruby version matches [`.ruby-version`](.ruby-version), then install dependencies:

```shell
bundle install
```

Create, migrate and seed the database:

```shell
bundle exec rake db:setup
```

### Environment variables

The application uses [`dotenv-rails`][dotenv-rails] to manage environment variables in `development` and `test` environments via `.env.*` files in the project root.

If you are new to the project, ask a developer to share their `.env.local`.

## Run the project

```shell
bin/dev
```

This starts the API server on [localhost:3000](http://localhost:3000).

## Development

### Code

The application is a Rails API exposing versioned JSON endpoints under `/api/v1/`.

Current endpoints:

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/contracts` | Paginated list of contracts |
| GET | `/api/v1/savings/:ocid` | Consolidated savings payload for a contract |
| GET | `/api/v1/savings/:ocid/peer-comparison` | Peer-group comparison for a contract's cashable savings |
| DELETE | `/api/v1/savings/:type/:savings_id` | Soft-delete a single savings record |

### Linting

We use [RuboCop][] with the [rubocop-rails-omakase][] style guide.

```shell
bundle exec rubocop        # check
bundle exec rubocop -A     # autofix
```

### Testing

The test suite uses [RSpec][].

```shell
bundle exec rake           # run all specs
bundle exec rspec path/to/file_spec.rb  # run a single spec
```

All specs run as part of the CI pipeline on every pull request.

## Contributing

Checkout a new branch from `main` and make your changes. Before pushing, squash your commits into one:

```shell
git rebase -i main  # change 'pick' to 's' for all but the first commit
```

Open a Pull Request against `main`. CI will run security scans, linting, and the test suite. Once all checks pass and the PR is reviewed, merge to trigger deployment.

## Continuous integration & deployment

CI runs on pull requests and pushes to `main` via GitHub Actions:

- **Security scan** — Brakeman static analysis + bundler-audit gem audit
- **Lint** — RuboCop

Deployment uses [Kamal][] (Docker-based). **_TO BE ADDED_**

## Environment variables

| Variable | Purpose |
|----------|---------|
| `DB_HOST` | Database host |
| `DB_USERNAME` | Database username |
| `DB_PASSWORD` | Database password |
| `DB_NAME` | Database name (development) |
| `DB_NAME_TEST` | Database name (test) |

[Homebrew]: https://brew.sh/
[Ruby on Rails]: https://rubyonrails.org/
[PostgreSQL]: https://www.postgresql.org/
[dotenv-rails]: https://github.com/bkeepers/dotenv
[RuboCop]: https://github.com/rubocop/rubocop
[rubocop-rails-omakase]: https://github.com/rails/rubocop-rails-omakase
[RSpec]: https://rspec.info/
[Kamal]: https://kamal-deploy.org/
