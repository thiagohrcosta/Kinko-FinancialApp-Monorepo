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
