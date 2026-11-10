# Payment gateway: screenshots

Captured during the live end-to-end tests of PR #44 (real Rails API + PostgreSQL,
real signed webhooks). The API keys and webhook secrets shown belong to throwaway
users in a local, disposable database.

## Mobile (React Native, iPhone 13)

| Enter code | Invalid code | Insufficient funds |
| :---: | :---: | :---: |
| <img src="mobile/01-pay-empty.png" width="260"> | <img src="mobile/02-pay-invalid.png" width="260"> | <img src="mobile/03-pay-insufficient.png" width="260"> |

| Preview | Payment complete | Reopened: already paid |
| :---: | :---: | :---: |
| <img src="mobile/04-pay-preview.png" width="260"> | <img src="mobile/05-pay-success.png" width="260"> | <img src="mobile/06-pay-already-paid.png" width="260"> |

The payer (balance $250.00) is blocked on a $9,900.00 charge, pays a $75.90 charge with
the code pasted using dashes (balance → $174.10), and reopening the code shows
"You already paid this charge". The merchant received the `payment_request.paid` webhook.

## Web (Next.js)

### Merchant: API keys & webhook
![Merchant API keys and webhook](web/01-merchant-api-keys-webhook.png)

### Merchant: charge created (code + QR)
![Merchant charge created](web/02-merchant-charge-created.png)

### Payer: preview
![Payer preview](web/03-pay-preview.png)

### Payer: payment complete
![Payer payment complete](web/04-pay-success.png)
