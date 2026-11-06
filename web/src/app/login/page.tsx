import type { Metadata } from "next";
import { Logo } from "@/components/logo";
import { LoginForm } from "./login-form";
import { ExpiredNotice } from "./expired-notice";
import { Suspense } from "react";

export const metadata: Metadata = { title: "Entrar · Kinko" };

export default function LoginPage({ searchParams }: PageProps<"/login">) {
  return (
    <main className="flex flex-1 items-center justify-center bg-slate-50 px-4 py-12">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex flex-col items-center gap-3 text-center">
          <Logo />
          <h1 className="text-2xl font-semibold tracking-tight text-slate-900">Bem-vindo de volta</h1>
          <p className="text-sm text-slate-500">Acesse sua conta para ver seu saldo e movimentações.</p>
        </div>

        <div className="card p-6">
          <Suspense>
            <ExpiredNotice searchParams={searchParams} />
          </Suspense>
          <LoginForm />
        </div>
      </div>
    </main>
  );
}
