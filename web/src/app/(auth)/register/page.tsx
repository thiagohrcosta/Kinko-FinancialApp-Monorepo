import type { Metadata } from "next";
import Link from "next/link";
import { RegisterForm } from "./register-form";

export const metadata: Metadata = { title: "Sign Up · Kinko" };

export default function RegisterPage() {
  return (
    <div className="mx-auto w-full max-w-2xl px-5 py-10">
      <header className="mb-6">
        <p className="text-3xl leading-tight tracking-wide text-ink-soft sm:text-[42px]">Create your account at</p>
        <p className="-mt-1 text-4xl font-bold text-kinko sm:text-5xl">Kinko!</p>
      </header>

      <div className="glass-card sm:p-7">
        <RegisterForm />
      </div>

      <p className="mt-4 text-center text-sm text-ink-soft">
        Already have an account?{" "}
        <Link href="/login" className="font-semibold text-kinko-link hover:underline">
          Log in
        </Link>
      </p>
    </div>
  );
}
