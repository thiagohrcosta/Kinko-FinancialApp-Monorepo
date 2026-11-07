# Backend (Rails API)

This service uses Ruby on Rails and includes a baseline quality and security toolchain.

## Installed development/test stack

- **RSpec** for automated testing
- **FactoryBot** for test data factories
- **SimpleCov** for code coverage reports
- **RuboCop (rails-omakase)** for style and lint checks
- **Brakeman** for static security analysis

## Initial setup commands

Run these commands from the `backend` directory:

```bash
bundle install
bundle exec rails generate rspec:install
```

> Note: In this repository, the equivalent RSpec setup files were created manually to keep the process deterministic in CI.

## Environment variables

Set in `backend/.env` (loaded by `docker-compose.yml`).

| Variable | Required | Description |
| --- | --- | --- |
| `STRIPE_SECRET_KEY` | yes | Stripe secret key used to create PaymentIntents. |
| `STRIPE_WEBHOOK_SECRET` | yes | Signing secret used to verify Stripe webhooks (`whsec_…`, also printed by `stripe listen`). |
| `SYSTEM_ACCOUNT_UUID` | yes | UUID of the Kinko system account that mirrors card deposits. |
| `KINKO_CURRENCY` | no (default `USD`) | ISO 4217 currency of the ledger. Accounts reject entries in any other currency, so set it once per environment: changing it later requires migrating existing entries. |
| `STRIPE_WEBHOOK_ALLOW_UNSIGNED` | no (default off) | `true` accepts unsigned Stripe webhooks, **development only** (ignored in every other environment). Useful for replaying a payload with `curl`; `stripe listen` signs its events and does not need it. |

## Database schema

`db/schema.rb` is regenerated from your local database on every `db:migrate`. If your database has migrations that are not on your branch (e.g. from another feature branch), the dump will include their tables: discard those hunks (`git checkout -- db/schema.rb` or `git add -p`) instead of committing them.

## Running checks locally

### Tests and coverage

```bash
bundle exec rspec
```

SimpleCov output is generated automatically when specs run:

- Coverage report: `coverage/index.html`

### RuboCop

```bash
bin/rubocop
```

### Brakeman

```bash
bin/brakeman --no-pager
```

## CI/CD quality gates

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs:

1. **Brakeman** security scan and uploads SARIF results to GitHub Code Scanning
2. **RuboCop** lint/style validation
3. **RSpec** test suite

This setup follows current common market practices by combining security scanning, style enforcement, and automated tests on pull requests and pushes to `main`.

## FactoryBot user factory

A `User` factory is available at:

- `spec/factories/users.rb`

Example usage in specs:

```ruby
user = build(:user)
create(:user, email: "custom@example.com")
```
