# Kinko Web

Frontend web do Kinko em **Next.js 16** (App Router, Cache Components, Tailwind CSS 4).

## Arquitetura

O navegador nunca fala direto com o Rails. O Next.js atua como **BFF (backend-for-frontend)**:

- **Login** (`src/app/login/actions.ts`): Server Action chama `POST /api/v1/auth/login` no Rails e grava o JWT
  num cookie **httpOnly** (`kinko_token`), inacessível ao JavaScript do browser. Por isso não é preciso CORS no Rails.
- **Chamadas autenticadas** (`src/lib/api.ts`): `authFetch` lê o cookie no servidor e envia `Authorization: Bearer <jwt>`.
  Se o Rails responder 401 (token expirado/inválido), o usuário vai para `/auth/logout?expired=1`, que limpa os cookies.
- **Proxy** (`src/proxy.ts`, antigo "middleware"): redirecionamento otimista — sem cookie, `/dashboard` → `/login`;
  com cookie, `/login` → `/dashboard`.
- **Endpoints do backend** ficam tipados em `src/lib/kinko.ts`.

## Páginas

| Rota | Descrição |
| --- | --- |
| `/login` | Login (e-mail/senha) |
| `/register` | Cadastro de pessoa física ou empresa (`POST /api/v1/auth/register`) |
| `/dashboard` | Saldo, entradas/saídas 30 dias, gráfico 7/14/30 dias, últimas movimentações |
| `/dashboard/statement?month=YYYY-MM` | Extrato mensal agrupado por dia, com totais e navegação entre meses |
| `/dashboard/transfer` | Transferência para outra conta (UUID); mostra o número da sua conta para copiar |
| `/dashboard/deposit` | Depósito com cartão via Stripe Payment Element |

### Depósito (Stripe)

1. O servidor Next chama `POST /api/v1/deposits`, e o Rails cria o PaymentIntent.
2. O navegador confirma o cartão com o Payment Element (`@stripe/react-stripe-js`).
3. O **crédito no ledger só acontece no webhook** `payment_intent.succeeded` do backend. A tela avisa que o saldo
   atualiza quando o Stripe confirmar.

Requer `STRIPE_PUBLISHABLE_KEY` no frontend e `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` no backend.
Em desenvolvimento, encaminhe os webhooks com
`stripe listen --forward-to localhost:3000/api/v1/webhooks/stripe`.

## Rodando localmente

```bash
cp .env.example .env.local   # API_BASE_URL=http://localhost:3000
npm install
npm run dev                  # http://localhost:3001
```

Com Docker, a partir da raiz do monorepo: `docker compose up` (web em `:3001`, backend em `:3000`).

Usuários de seed (`bin/rails db:seed` no backend) usam a senha `password123`, ex.: `admin@kinko.com`.

## Identidade visual

O tema segue o app mobile e o logo oficial. Os tokens ficam em `src/app/globals.css` (`@theme`) e viram classes do
Tailwind (`bg-kinko`, `text-income`, …):

| Token | Cor | Origem / uso |
| --- | --- | --- |
| `kinko-logo` | `#F52F35` | Quadrado do "K" no logo |
| `kinko` | `#D01C1C` | Vermelho principal ("Kinko!", botões, loaders) |
| `kinko-light` → `kinko-dark` | `#FF3B3B` → `#B30000` | Gradiente do botão de login / card de saldo |
| `kinko-accent` | `#FF3B30` | Filtros ativos, linha de saídas |
| `ink` | `#1F212A` | Texto "KINKO" do logo |
| `income` / `credit` | `#57A773` / `#16A34A` | Entradas (gráfico / extrato) |
| `debit` | `#DC2626` | Saídas no extrato |
| `surface` / `chip` | `#F5F5F5` / `#EEEEEE` | Fundo das telas / filtros inativos |

Fonte: **Roboto** (a mesma do app). Assets em `public/` vêm de `kinko-mobile/assets/images/`
(`logo.png`, `bglogin.png` convertido para JPG; `kinko-mark.png` e o favicon são o "K" recortado do logo).
