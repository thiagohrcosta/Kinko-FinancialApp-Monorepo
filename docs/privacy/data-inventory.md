# Personal data inventory

What personal data Kinko holds, why, on what legal basis, for how long, and what happens to it when someone asks
for their data to be deleted. This is our record of processing activities (GDPR Art. 30) and the base for the
privacy notice, data exports and deletions (#81).

> The tables below are generated from [`backend/config/personal_data.yml`](../../backend/config/personal_data.yml).
> Edit the YAML, then run `bin/rails privacy:inventory` in `backend/`. A spec fails when a database column isn't
> classified there, or when this file is out of date.

## Decisions

- **One flow for everyone.** Every user has the same rights: know what we hold, get a copy, correct it, delete it,
  opt out. Only the deadlines, the notices and a few extras change by region: Europe (GDPR), California (CCPA/CPRA),
  other US states with a privacy law, rest of the US. See `PrivacyRegion` in `backend/app/models/privacy_region.rb`.
- **Financial records are kept for 5 years.** Anti-money-laundering rules require keeping identification and
  transaction records for 5 years after the account is closed. A deletion request is accepted and recorded with
  its purge date (5 years later). Everything that can be removed or anonymized right away is; the rest is
  restricted to legal use and deleted on that date.
- **Region comes from the address**: country, plus the state for the US. Users created before the country was asked
  are `unknown` until they add it; until then, use the strictest deadlines.

## What a deletion request does today (summary)

| Data | Action |
| --- | --- |
| Email, phone | Anonymized right away |
| Password digest, reset tokens, API keys, webhook endpoint | Deleted right away |
| Name, government ID, address, business name | Moved to a restricted archive, deleted after 5 years |
| Accounts, ledger entries, charges | Kept for 5 years (not identifying once the above is done), then deleted |
| Names inside ledger descriptions and webhook payloads | Removed (#87, #89) |

## Inventory

<!-- BEGIN GENERATED: bin/rails privacy:inventory -->
### `users`

| Column | Category | Purpose | Basis | Retention | On erasure | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `full_name` | identity | Identify the account holder (know your customer) and show the name to people they pay | legal_obligation | aml_5_years | archive |  |
| `email` | contact | Sign-in and account emails | contract | account_lifetime | anonymize |  |
| `phone_number` | contact | Contact about the account and security | contract | account_lifetime | anonymize |  |
| `document_number` ⚠️ | government_id | Verify identity (know your customer) | legal_obligation | aml_5_years | archive |  |
| `address_street` | address | Verify identity (know your customer) and decide which privacy law applies | legal_obligation | aml_5_years | archive |  |
| `address_number` | address | Verify identity (know your customer) and decide which privacy law applies | legal_obligation | aml_5_years | archive |  |
| `address_complement` | address | Verify identity (know your customer) and decide which privacy law applies | legal_obligation | aml_5_years | archive |  |
| `address_neighborhood` | address | Verify identity (know your customer) and decide which privacy law applies | legal_obligation | aml_5_years | archive |  |
| `address_city` | address | Verify identity (know your customer) and decide which privacy law applies | legal_obligation | aml_5_years | archive |  |
| `address_state` | address | Verify identity (know your customer) and decide which privacy law applies | legal_obligation | aml_5_years | archive |  |
| `address_zip_code` | address | Verify identity (know your customer) and decide which privacy law applies | legal_obligation | aml_5_years | archive |  |
| `address_country` | address | Verify identity (know your customer) and decide which privacy law applies | legal_obligation | aml_5_years | archive |  |
| `business_name` | business | Identify the business (know your business) and show it to payers | legal_obligation | aml_5_years | archive |  |
| `business_sector` | business | Shown to payers next to the business name | contract | account_lifetime | delete |  |
| `user_type` | account | Personal or business account | contract | aml_5_years | keep |  |
| `encrypted_password` ⚠️ | credentials | Sign-in (bcrypt digest, never the password) | contract | account_lifetime | delete |  |
| `reset_password_token` ⚠️ | credentials | Password reset link | contract | account_lifetime | delete |  |
| `reset_password_sent_at` | credentials | Expire the password reset link | contract | account_lifetime | delete |  |
| `remember_created_at` | credentials | Devise "remember me" (unused by the API today) | contract | account_lifetime | delete |  |

### `accounts`

| Column | Category | Purpose | Basis | Retention | On erasure | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `user_id` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `uuid` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep | Shown to other users as the account number to receive transfers |
| `status` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |

### `ledger_entries`

| Column | Category | Purpose | Basis | Retention | On erasure | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `account_id` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `amount_cents` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `currency` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `entry_type` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `transaction_id` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `reference` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `description` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | scrub | Contains counterparties' names ("Transfer to <name>", "Payment from <name>"). Names must leave the ledger before deletion can work (#87). |

### `payment_requests`

| Column | Category | Purpose | Basis | Retention | On erasure | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `merchant_account_id` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `payer_account_id` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `amount_cents` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `fee_cents` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `currency` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `status` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `paid_at` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `canceled_at` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `expires_at` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `code` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `public_id` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep |  |
| `description` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep | Written by the merchant and shown to the payer |
| `external_reference` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep | The merchant's own id; can identify the merchant's customer |
| `metadata` | financial | Run the account and keep the transaction record | legal_obligation | aml_5_years | keep | Free-form key/values from the merchant; can contain their customer's data |

### `merchant_api_keys`

| Column | Category | Purpose | Basis | Retention | On erasure | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `user_id` | merchant_integration | Let the merchant's systems use the API | contract | account_lifetime | delete |  |
| `name` | merchant_integration | Let the merchant's systems use the API | contract | account_lifetime | delete |  |
| `last4` | merchant_integration | Let the merchant's systems use the API | contract | account_lifetime | delete |  |
| `last_used_at` | merchant_integration | Let the merchant's systems use the API | contract | account_lifetime | delete |  |
| `revoked_at` | merchant_integration | Let the merchant's systems use the API | contract | account_lifetime | delete |  |
| `token_digest` ⚠️ | credentials | Let the merchant's systems use the API | contract | account_lifetime | delete | SHA-256 digest; the key itself is never stored |

### `webhook_endpoints`

| Column | Category | Purpose | Basis | Retention | On erasure | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `user_id` | merchant_integration | Let the merchant's systems use the API | contract | account_lifetime | delete |  |
| `url` | merchant_integration | Let the merchant's systems use the API | contract | account_lifetime | delete |  |
| `active` | merchant_integration | Let the merchant's systems use the API | contract | account_lifetime | delete |  |
| `signing_secret` ⚠️ | credentials | Let the merchant's systems use the API | contract | account_lifetime | delete |  |

### `webhook_deliveries`

| Column | Category | Purpose | Basis | Retention | On erasure | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `payload` | merchant_integration | Notify the merchant that a charge was paid, canceled or expired | contract | webhook_30_days | scrub | Contains the payer's full name and account number; sent to the merchant (#96) |

### Outside the database

| Store | Where | Retention | Notes |
| --- | --- | --- | --- |
| Web session cookies | Browser: httpOnly cookies `kinko_token` (JWT) and `kinko_user` (id, email, full name, account type) | session_24_hours | `kinko_user` could hold only the id and account type (#96) |
| Mobile app storage | Phone: AsyncStorage `authToken` (JWT) and the user JSON (name, email) | session_24_hours | AsyncStorage isn't encrypted; move the token to the Keychain / Keystore (#96) |
| Application logs | Rails logs on the hosting provider | account_lifetime | Request parameters with token, password, email and other sensitive names are filtered. The Stripe webhook logs the whole PaymentIntent (#96). Log retention isn't set yet (#89). |
| Background jobs | Solid Queue tables (job arguments) | account_lifetime | Jobs receive record ids; finished jobs are cleared every hour |
| Database backups | Hosting provider | account_lifetime | Backup retention isn't set yet (#89) |

### Who else receives personal data

| Recipient | Role | Receives | Location | Transfer mechanism |
| --- | --- | --- | --- | --- |
| Stripe | Processor | Deposit amount, currency and the Kinko account number (PaymentIntent metadata). Card details are typed into Stripe's own form; Kinko never sees them. | United States | To confirm (EU-US Data Privacy Framework / SCCs in Stripe's DPA) |
| Hosting and database provider | Processor | Everything in the database, logs and backups | To confirm | To confirm |
| Email provider | Processor | Name and email, to send account emails (#79) | To confirm | To confirm |
| Merchants | Third party (independent controller) | The payer's full name and account number when a charge is paid (API and webhooks) | Wherever the merchant is | Disclosed in the privacy notice (#91); minimize what is sent (#96) |

### Legend

⚠️ Sensitive personal information under CPRA.

**Categories**

- `identity`: Name and other data that identify the person
- `contact`: Email and phone
- `address`: Postal address
- `government_id`: Government-issued ID or tax number
- `business`: Business account data
- `credentials`: Passwords, reset tokens and other secrets
- `financial`: Accounts, balances, transactions and charges
- `merchant_integration`: API keys, webhook endpoints and deliveries
- `account`: Account settings and type

**Retention**

- `account_lifetime`: While the account is open. Erased or anonymized as soon as the user asks for deletion.
- `aml_5_years`: 5 years after the account is closed, to meet anti-money-laundering record keeping (BSA in the US, AMLD in the EU). When a deletion request is accepted, the purge date is recorded and the data is removed then.
- `webhook_30_days`: 30 days after the delivery, then deleted (#89).
- `session_24_hours`: Until the session expires (24 hours) or the user logs out.

**On erasure**

- `delete`: Deleted when the deletion request is processed.
- `anonymize`: Replaced with a placeholder (the column can't be empty), when the deletion request is processed.
- `archive`: Moved out of the app into a restricted archive used only for legal obligations, and deleted when the retention period ends.
- `keep`: Kept for the retention period. Not identifying on its own once identity data is anonymized; deleted when the retention period ends.
- `scrub`: Personal data inside the value (names in free text) is removed; the rest is kept.
<!-- END GENERATED -->
