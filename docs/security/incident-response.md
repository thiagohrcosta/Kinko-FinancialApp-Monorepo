# Incident response runbook

What to do when something may have exposed customer data or money: who does what, how to contain it, how to find
who was affected, and who must be told by when.

> ⚠️ The notification deadlines below are a starting point for engineering, not legal advice. Before a real
> notification, privacy counsel confirms which laws apply and what to send. Part of #81 (privacy program).

## 1. Is this an incident?

Declare an incident as soon as **any** of these is suspected, even without proof:

- personal or financial data seen, copied or changed by someone who shouldn't (database, backup, logs, exports)
- a leaked credential: an API key, a webhook signing secret, `JWT_SECRET_KEY`, `secret_key_base`, Stripe keys,
  database credentials, a developer's laptop or token
- money moved without the customer's authorization, or ledger entries that don't balance
- a vulnerability that exposes data and may have been exploited

When in doubt, declare it. Closing a false alarm costs minutes; a late notification can cost far more.

## 2. Severity

| Level | Examples | Response |
| --- | --- | --- |
| **SEV1** | Confirmed exposure of personal or financial data; unauthorized money movement; production credentials leaked publicly | Start now, around the clock. Notification clock is likely running (section 6). |
| **SEV2** | Suspected exposure under investigation; one merchant's API key leaked; personal data found in logs | Start the same working day. |
| **SEV3** | Vulnerability found with no sign of exploitation; secret committed and removed within minutes | Fix within the week; record it. |

Raise the level as soon as new facts justify it; lowering it needs the incident lead's decision, written down.

## 3. Roles

A small team can hold several roles, but each one has a name in the incident record.

| Role | Does |
| --- | --- |
| **Incident lead** | Declares the incident and its severity, decides, keeps the timeline, closes it |
| **Technical lead** | Investigates, contains, fixes, keeps evidence |
| **Privacy / legal** | With counsel, decides whether and whom to notify, approves every external message |
| **Communications** | Sends the notifications and answers users and merchants |
| **Scribe** | Writes down every fact, decision and time (UTC) as it happens |

## 4. First hour

1. **Open the incident record** (section 9) and write the time you became aware: most deadlines count from it.
2. **Name the roles.**
3. **Preserve evidence before changing anything:** export the relevant logs, take a database snapshot, note the
   deployed commit (`git rev-parse HEAD` of the release), keep access logs. Never delete data during an incident.
4. **Contain** (section 5).
5. **Find who is affected** (section 7).
6. **Decide on notifications** with privacy / legal (section 6).

## 5. Containment

Run the dry run first, then add `APPLY=1`. All tasks are in `backend/`.

| Situation | Action |
| --- | --- |
| A merchant API key leaked | The merchant revokes it in **Merchant → API keys & webhooks** (or `DELETE /api/v1/merchant/api_keys/:id`) |
| Many keys or the key database exposed | `bin/rails incident:revoke_api_keys` (every merchant must create new keys) |
| A webhook receiver is compromised, or webhooks are leaking data | `bin/rails incident:disable_webhooks` (merchants re-enable by saving their URL) |
| Webhook signing secrets exposed | `bin/rails incident:rotate_webhook_secrets`, then tell merchants to rotate again in the dashboard to see their new secret |
| `JWT_SECRET_KEY` exposed | Set a new value and restart: every session ends, users log in again |
| `secret_key_base` exposed | Set a new value and restart. ⚠️ It also signs payment code checksums, so pending payment codes stop working: cancel and recreate open charges. It ends every session too when `JWT_SECRET_KEY` isn't set (the JWT falls back to it) |
| Stripe keys exposed | Roll the secret key and the webhook signing secret in the Stripe dashboard, update `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` |
| Database credentials exposed | Rotate them at the hosting provider, update `DATABASE_URL`, check the database access log |
| Unauthorized money movement | Stop the path (feature flag, revert, or take the endpoint down), then correct the ledger **with new entries**: never update or delete ledger rows |

## 6. Who must be told, by when

The clock usually starts when we **become aware** of the incident, not when we finish investigating. Ask privacy /
legal on day one.

| Who | When | Rule |
| --- | --- | --- |
| EU / EEA supervisory authority | **72 hours** after becoming aware, unless the breach is unlikely to put people at risk. Late? Send it anyway with the reasons for the delay | GDPR Art. 33 |
| UK: the ICO | 72 hours, same test | UK GDPR |
| Affected people in the EU / UK | Without undue delay when the risk to them is **high** | GDPR Art. 34 |
| California residents | In the most expedient time possible, without unreasonable delay. Also the California Attorney General when more than 500 residents are notified | Cal. Civ. Code §1798.82 |
| Residents of other US states | Each state has its own law: some say "without unreasonable delay", others set 30, 45 or 60 days, and many require telling the state attorney general above a number of residents | State breach laws (counsel to check per state) |
| The FTC | Within 30 days of discovery when 500 or more consumers' information is involved | GLBA Safeguards Rule |
| Merchants whose integration or customers are affected | Within 72 hours (our commitment) | Our terms |
| Stripe | If card or Stripe data may be involved | Stripe's terms |

Use the affected users list (section 7): its `address_country`, `address_state` and `privacy_region` columns say
which rows of this table apply to each person.

Templates are in [notification-templates.md](notification-templates.md). Every external message is approved by privacy /
legal before it's sent.

## 7. Find who is affected

```bash
FROM=2026-11-01T00:00:00Z TO=2026-11-03T00:00:00Z TABLES=users,ledger_entries EXPOSURE=snapshot \
  bin/rails incident:affected_users > affected.csv
```

- `TABLES`: `users`, `accounts`, `ledger_entries`, `payment_requests`, `merchant_api_keys`, `webhook_endpoints`,
  `webhook_deliveries`. Payment requests count both the merchant and the payer; webhook deliveries count the merchant
  that received them and the payer named in the payload.
- `EXPOSURE=snapshot` (default): everyone whose rows existed at `TO`. Use it for a database dump, a backup or read
  access to a table.
- `EXPOSURE=activity`: only rows created or changed between `FROM` and `TO`. Use it for data that went through a
  leaking log, request or job during that time.
- The CSV has `id, email, full_name, user_type, address_state, address_country, privacy_region`.
- `affected.csv` is personal data itself: keep it out of the repository, chat and email; store it with the incident
  record and delete it when the incident is closed.

`backend/config/personal_data.yml` (#82) lists what each column holds, which helps describe "the categories of data
involved" in notifications.

## 8. After the incident

Within two weeks of closing a SEV1 or SEV2:

- a blameless review: timeline, root cause, what helped, what didn't
- an issue for each follow-up, linked from the record
- update this runbook if a step was missing or wrong

## 9. Incident register

GDPR Art. 33(5) requires a record of **every** personal data breach, including the ones that didn't need to be
notified. Keep it **outside this repository** (it's sensitive): a restricted document or tracker. Each entry has:

| Field | |
| --- | --- |
| Id and title | `INC-2026-001: Merchant API key published in a public repo` |
| Became aware at (UTC) | starts the notification clocks |
| Severity and roles | |
| What happened | facts only, with times |
| Data and people involved | categories of data, number of people, countries / states |
| Likely consequences | for the people involved |
| Containment and fixes | what was done, when, by whom |
| Notifications | to whom, when, or why not (the reason is required) |
| Follow-ups | links to issues |
| Closed at | |

## 10. Practice

Once a year, run a one-hour tabletop exercise with a scenario, for example:

- a merchant reports that someone used their API key to create charges
- a backup bucket was public for three days
- personal data was found in the application logs for the last month

Walk through sections 4 to 7 without touching production, and fix this runbook with what you learn.
