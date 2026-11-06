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
| `/login` | Formulário de login (e-mail/senha) |
| `/dashboard` | Saldo (ledger), entradas/saídas 30 dias, gráfico 7/14/30 dias, movimentações do mês |

## Rodando localmente

```bash
cp .env.example .env.local   # API_BASE_URL=http://localhost:3000
npm install
npm run dev                  # http://localhost:3001
```

Com Docker, a partir da raiz do monorepo: `docker compose up` (web em `:3001`, backend em `:3000`).

Usuários de seed (`bin/rails db:seed` no backend) usam a senha `password123`, ex.: `admin@kinko.com`.
