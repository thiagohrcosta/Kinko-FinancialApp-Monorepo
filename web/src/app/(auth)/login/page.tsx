import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { LoginForm } from "./login-form";
import { ExpiredNotice } from "./expired-notice";

export const metadata: Metadata = { title: "Entrar · Kinko" };

// Mesmo padrão visual da tela de login do app (kinko-mobile/app/login.tsx).
export default function LoginPage({ searchParams }: PageProps<"/login">) {
  return (
    <div className="mx-auto flex w-full max-w-6xl flex-col justify-between gap-10 px-5 py-10 md:flex-row md:items-center">
      <header className="md:self-start md:pt-16">
        <p className="text-[42px] leading-tight tracking-wide text-ink-soft">Bem-vindo ao</p>
        <p className="-mt-1 text-5xl font-bold text-kinko">Kinko!</p>
      </header>

      <div className="w-full max-w-[360px] self-center md:mb-16 md:self-end">
        <div className="glass-card">
          <Suspense>
            <ExpiredNotice searchParams={searchParams} />
          </Suspense>
          <LoginForm />
        </div>
        <p className="mt-4 text-center text-sm text-ink-soft">
          Ainda não tem conta?{" "}
          <Link href="/register" className="font-semibold text-kinko-link hover:underline">
            Criar conta
          </Link>
        </p>
      </div>
    </div>
  );
}
