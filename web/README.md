# Kinko Web

Kinko's web frontend, built with **Next.js 16** (App Router, Cache Components, Tailwind CSS 4).
The UI is in English and uses US formats (USD, `en-US` dates).

## Architecture

The browser never talks to Rails directly. Next.js acts as a **BFF (backend-for-frontend)**:

- **Login** (`src/app/(auth)/login/actions.ts`): a Server Action calls `POST /api/v1/auth/login` and stores the JWT
  in an **httpOnly** cookie (`kinko_token`) that browser JavaScript can't read. No CORS setup is needed on Rails.
- **Authenticated calls** (`src/lib/api.ts`): `authFetch` reads the cookie on the server and sends
  `Authorization: Bearer <jwt>`. If Rails answers 401 (expired/invalid token), the user is sent to
  `/auth/logout?expired=1`, which clears the cookies. Server Actions rethrow that redirect (`unstable_rethrow`).
- **Proxy** (`src/proxy.ts`, formerly "middleware"): optimistic redirects — without a cookie `/dashboard` → `/login`;
  with one, `/login` and `/register` → `/dashboard`.
- Backend endpoints are typed in `src/lib/kinko.ts`.

## Pages

| Route | Description |
| --- | --- |
| `/login` | Log in with email and password |
| `/register` | Personal or business sign-up (`POST /api/v1/auth/register`) |
| `/dashboard` | Balance, 30-day income/expenses, 7/14/30-day chart, latest transactions |
| `/dashboard/statement?month=YYYY-MM` | Monthly statement grouped by day, with totals and month navigation |
| `/dashboard/transfer` | Transfer to another account (UUID); shows your own account number with a copy button |
| `/dashboard/deposit` | Card deposit through the Stripe Payment Element |

Dates and times are shown in **UTC** to match how the backend buckets months (see `src/lib/format.ts`).

### Deposits (Stripe)

1. The Next server calls `POST /api/v1/deposits`; Rails creates the PaymentIntent.
2. The browser confirms the card with the Payment Element (`@stripe/react-stripe-js`).
3. **The ledger is only credited by the backend's `payment_intent.succeeded` webhook**, which is idempotent per
   Stripe event. The page explains that the balance updates once Stripe confirms.

Requires `STRIPE_PUBLISHABLE_KEY` on the frontend and `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` on the backend.
In development, forward webhooks with `stripe listen --forward-to localhost:3000/api/v1/webhooks/stripe`.

## Running locally

```bash
cp .env.example .env.local   # API_BASE_URL=http://localhost:3000
npm install
npm run dev                  # http://localhost:3001
```

Checks (same as CI): `npm run lint`, `npm run typecheck`, `npm test`, `npm run build`.

With Docker, from the monorepo root: `docker compose up` (web on `:3001`, backend on `:3000`).

Seed users (`bin/rails db:seed` in the backend) use the password `password123`, e.g. `admin@kinko.com`.
`bin/rails runner create_user_with_transactions.rb` creates `test_with_balance@kinko.com` with sample entries.

## Visual identity

The theme follows the mobile app and the official logo. Tokens live in `src/app/globals.css` (`@theme`) and become
Tailwind classes (`bg-kinko`, `text-income`, …):

| Token | Color | Source / usage |
| --- | --- | --- |
| `kinko-logo` | `#F52F35` | The "K" square in the logo |
| `kinko` | `#D01C1C` | Primary red ("Kinko!", buttons, loaders) |
| `kinko-light` → `kinko-dark` | `#FF3B3B` → `#B30000` | Login button / balance card gradient |
| `kinko-accent` | `#FF3B30` | Active filters, expenses line |
| `ink` | `#1F212A` | "KINKO" wordmark |
| `income` / `credit` | `#57A773` / `#16A34A` | Income (chart / statement) |
| `debit` | `#DC2626` | Expenses in the statement |
| `surface` / `chip` | `#F5F5F5` / `#EEEEEE` | Screen background / inactive filters |

Font: **Roboto** (same as the app). Assets in `public/` come from `kinko-mobile/assets/images/`
(`logo.png`, `bglogin.png` converted to JPG; `kinko-mark.png` and the favicon are the "K" cropped from the logo).
