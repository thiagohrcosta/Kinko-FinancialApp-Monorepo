# Kinko Payment Gateway: merchant API

Businesses use Kinko to charge their customers. A charge (`payment_request`) has a
**payment code** that the customer pastes under **Pay** in Kinko, or scans as a QR code.
Kinko debits the customer, credits the merchant's Kinko account and notifies the
merchant by webhook.

Merchants only ever use **Kinko API keys** (`kinko_sk_…`). They never get or use
Stripe credentials.

## Authentication

| Credential | Header | Can use |
| --- | --- | --- |
| API key (server-to-server) | `Authorization: Bearer kinko_sk_…` | `payment_requests` |
| Dashboard session (JWT from `/api/v1/auth/login`) | `Authorization: Bearer <jwt>` | everything below, including `api_keys` and `webhook_endpoint` |

* Only **business** accounts can use the merchant API (`403 Business account required`).
* API keys **cannot** manage API keys or webhooks (`403`), so a leaked key cannot
  create new keys or redirect your webhooks.
* Keys are shown **once**, at creation. Kinko stores only their SHA-256 digest.
  Revoke a key you no longer trust: it stops working right away.

Create a key from the dashboard (**Merchant → API keys & webhooks**) or:

```bash
curl -X POST $KINKO/api/v1/merchant/api_keys \
  -H "Authorization: Bearer $DASHBOARD_JWT" -H "Content-Type: application/json" \
  -d '{"name":"Production"}'
# → { "id": 1, "name": "Production", "masked_key": "kinko_sk_…pBLx", "secret": "kinko_sk_…", … }
```

## Charges

### Create

```bash
curl -X POST $KINKO/api/v1/merchant/payment_requests \
  -H "Authorization: Bearer $KINKO_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: order-1001" \
  -d '{
    "amount_cents": 12990,
    "description": "Order #1001",
    "external_reference": "ord_1001",
    "expires_in": 3600,
    "metadata": { "customer_id": "c_42" }
  }'
```

| Field | Required | Notes |
| --- | --- | --- |
| `amount_cents` | yes | Positive integer, in the ledger currency (`KINKO_CURRENCY`, default USD) |
| `description` | yes | Up to 140 chars, shown to the payer |
| `external_reference` | no | Your own id (up to 100 chars) |
| `expires_in` | no | Seconds, default 86400 (24 h), clamped to 5 min … 30 days |
| `metadata` | no | Up to 20 string key/values, returned as-is |

Response `201`:

```json
{
  "id": "37ec22c2-b97a-4adf-aaf0-64f69e473279",
  "object": "payment_request",
  "code": "KNK189Z1N3XGHP23ADCXRXP4HP9G",
  "status": "pending",
  "amount_cents": 12990,
  "fee_cents": 0,
  "currency": "USD",
  "description": "Order #1001",
  "external_reference": "ord_1001",
  "metadata": { "customer_id": "c_42" },
  "expires_at": "2026-11-07T02:40:00Z",
  "paid_at": null,
  "canceled_at": null,
  "payer": null,
  "created_at": "2026-11-07T01:40:00Z"
}
```

**Idempotency.** Send an `Idempotency-Key` header (unique per charge on your side).
Retrying with the same key returns the original charge (`200`) instead of creating
a new one. Reusing a key with a different amount, description, currency or
reference returns `409`.

**Showing the charge to your customer.** Display `code` (grouping it by 4 helps:
`KNK1 89Z1 N3XG …`) and/or the QR code at
`GET /api/v1/payment_requests/:code/qr` (public SVG). The code points to the charge
stored at Kinko. It does not contain the amount or the payee, so editing it cannot
change what is paid. A mistyped code fails its checksum and is rejected.

### Read, list, cancel

```bash
curl $KINKO/api/v1/merchant/payment_requests/$ID -H "Authorization: Bearer $KINKO_API_KEY"
curl "$KINKO/api/v1/merchant/payment_requests?status=paid&limit=20&offset=0" -H "Authorization: Bearer $KINKO_API_KEY"
curl -X POST $KINKO/api/v1/merchant/payment_requests/$ID/cancel -H "Authorization: Bearer $KINKO_API_KEY"
```

* `status` filter: `pending`, `paid`, `canceled` or `expired`. `limit` is 1 to 100, default 20.
* Only `pending` charges can be canceled (`422` otherwise).

### Status lifecycle

```
pending ──paid by a Kinko user──▶ paid
   │
   ├──merchant cancels──────────▶ canceled
   └──expires_at reached────────▶ expired
```

A pending charge past `expires_at` is reported and treated as `expired` right away.
A background job (`ExpirePaymentRequestsJob`, every 5 minutes) persists the change
and sends the webhook.

## Webhooks

Set your endpoint in the dashboard or with
`PUT /api/v1/merchant/webhook_endpoint {"url": "https://…"}` (dashboard session only).
The response includes the **signing secret** (`kinko_whsec_…`). Rotate it with
`POST /api/v1/merchant/webhook_endpoint/rotate_secret`. `DELETE` disables delivery.

Only public `https` URLs are accepted. URLs that resolve to private, loopback,
link-local or CGNAT addresses are rejected when you save them and checked again
before each delivery.

### Events

`payment_request.paid`, `payment_request.canceled`, `payment_request.expired`

```http
POST /your/webhook HTTP/1.1
Content-Type: application/json
User-Agent: Kinko-Webhooks/1.0
Kinko-Event-Id: evt_9ddcd2af-efab-4aed-b1c5-c0341f470a85
Kinko-Signature: t=1794015623,v1=5f2b…

{
  "id": "evt_9ddcd2af-efab-4aed-b1c5-c0341f470a85",
  "type": "payment_request.paid",
  "created_at": "2026-11-07T01:40:23Z",
  "data": { "id": "37ec22c2-…", "object": "payment_request", "status": "paid", "payer": { "account_uuid": "…", "name": "…" }, … }
}
```

* `data` is the same object the API returns for the charge.
* Answer with any `2xx` within 5 seconds. Other responses, timeouts and network
  errors are retried with growing delays, up to 8 attempts. After that the
  delivery is marked `failed`.
* Deliveries can arrive more than once. Use `Kinko-Event-Id` (or `data.id` + `type`)
  to process each event only once.
* A webhook is only sent once the payment is committed. A rolled-back payment never
  produces one.

### Verifying the signature

`Kinko-Signature` is `t=<unix time>,v1=<hex HMAC-SHA256 of "<t>.<raw body>">`,
the same scheme as Stripe. Compute the HMAC over the **raw** request body with your
signing secret, compare it in constant time, and reject timestamps more than
5 minutes old.

Ruby:

```ruby
def valid_kinko_signature?(raw_body, header, secret, tolerance: 300)
  parts = header.to_s.split(",").filter_map { |kv| kv.split("=", 2) if kv.include?("=") }.to_h
  t = Integer(parts["t"], exception: false)
  return false unless t && parts["v1"] && (Time.now.to_i - t).abs <= tolerance

  expected = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{t}.#{raw_body}")
  OpenSSL.secure_compare(expected, parts["v1"])
end
```

Node.js:

```js
import crypto from "node:crypto";

export function validKinkoSignature(rawBody, header, secret, tolerance = 300) {
  const parts = Object.fromEntries(header.split(",").map((kv) => kv.split("=", 2)));
  const t = Number(parts.t);
  if (!Number.isInteger(t) || !parts.v1 || Math.abs(Date.now() / 1000 - t) > tolerance) return false;
  const expected = crypto.createHmac("sha256", secret).update(`${t}.${rawBody}`).digest("hex");
  return expected.length === parts.v1.length && crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(parts.v1));
}
```

## Payer side (Kinko users)

| Endpoint | Description |
| --- | --- |
| `GET /api/v1/payment_requests/:code` | Preview: payee, amount, account to be debited, balance, `sufficient_funds`, expiry |
| `POST /api/v1/payment_requests/:code/pay` | Pays from the user's balance, **exactly once** (a repeated click returns the same success) |
| `GET /api/v1/payment_requests/:code/qr` | QR code SVG (public) |

The web app has this flow under **Pay** (`/dashboard/pay`, or `/dashboard/pay?code=…`).

## Errors

| Status | When |
| --- | --- |
| `400` | Missing parameter (`{"error": "Missing parameter: amount_cents"}`) |
| `401` | No credential, invalid or revoked API key, invalid or expired JWT |
| `403` | Not a business account, or an API key used on a session-only endpoint |
| `404` | Charge not found (or it belongs to another merchant) |
| `409` | `Idempotency-Key` reused with different parameters; charge already paid by someone else |
| `422` | Invalid input, invalid payment code, insufficient funds, charge expired/canceled/not cancelable, paying your own charge |
