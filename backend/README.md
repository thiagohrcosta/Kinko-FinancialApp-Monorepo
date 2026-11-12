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

## Payment gateway

Merchants (business users) can charge Kinko users with copy-and-paste payment
codes and QR codes, integrate with Kinko API keys and receive signed webhooks.
See [docs/payment-gateway.md](docs/payment-gateway.md) for the merchant API.

## Environment variables

Set in `backend/.env` (loaded by `docker-compose.yml`).

| Variable | Required | Description |
| --- | --- | --- |
| `STRIPE_SECRET_KEY` | yes | Stripe secret key used to create PaymentIntents. |
| `STRIPE_WEBHOOK_SECRET` | yes | Signing secret used to verify Stripe webhooks (`whsec_…`, also printed by `stripe listen`). |
| `SYSTEM_ACCOUNT_UUID` | yes | UUID of the Kinko system account that mirrors card deposits. |
| `KINKO_CURRENCY` | no (default `USD`) | ISO 4217 currency of the ledger. Accounts reject entries in any other currency, so set it once per environment: changing it later requires migrating existing entries. |

### Stripe webhooks in development

Every Stripe event must be signed, in development too. Forward events with the Stripe CLI, which signs them,
and use the secret it prints as `STRIPE_WEBHOOK_SECRET`:

```bash
stripe listen --forward-to localhost:3000/api/v1/webhooks/stripe
```

To replay an event, use `stripe events resend <evt_id>` or `stripe trigger payment_intent.succeeded`
instead of posting JSON with `curl`.

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
