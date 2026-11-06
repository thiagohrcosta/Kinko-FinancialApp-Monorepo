import type { Metadata } from "next";
import Image from "next/image";
import { Suspense } from "react";
import { LoginForm } from "./login-form";
import { ExpiredNotice } from "./expired-notice";

export const metadata: Metadata = { title: "Entrar · Kinko" };

// Mesmo padrão visual da tela de login do app (kinko-mobile/app/login.tsx):
// arte do Fuji ao fundo, "Welcome to Kinko!" e card branco translúcido.
export default function LoginPage({ searchParams }: PageProps<"/login">) {
  return (
    <main className="relative flex flex-1 overflow-hidden">
      <Image
        src="/bglogin.jpg"
        alt=""
        fill
        priority
        sizes="100vw"
        className="-z-10 object-cover opacity-90"
      />

      <div className="mx-auto flex w-full max-w-6xl flex-col justify-between gap-10 px-5 py-10 md:flex-row md:items-center">
        <header className="md:self-start md:pt-16">
          <p className="text-[42px] leading-tight tracking-wide text-ink-soft">Bem-vindo ao</p>
          <p className="-mt-1 text-5xl font-bold text-kinko">Kinko!</p>
        </header>

        <div className="w-full max-w-[360px] self-center rounded-[22px] border border-white/40 bg-white/75 p-5 shadow-[0_10px_20px_rgba(0,0,0,0.25)] backdrop-blur-sm md:self-end md:mb-16">
          <Suspense>
            <ExpiredNotice searchParams={searchParams} />
          </Suspense>
          <LoginForm />
        </div>
      </div>
    </main>
  );
}
