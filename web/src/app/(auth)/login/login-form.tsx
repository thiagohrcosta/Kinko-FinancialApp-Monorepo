"use client";

import { useActionState } from "react";
import { login, type LoginState } from "./actions";

const initialState: LoginState = {};

function IconBubble({ children }: { children: React.ReactNode }) {
  return (
    <span className="grid size-7 shrink-0 place-items-center rounded-full bg-[rgba(205,196,196,0.35)] text-[#8c8c8c]">
      {children}
    </span>
  );
}

export function LoginForm() {
  const [state, formAction, pending] = useActionState(login, initialState);

  return (
    <form action={formAction}>
      <label className="flex items-center gap-2.5 px-1.5 py-1">
        <IconBubble>
          <span className="size-2 rounded-full bg-current" />
        </IconBubble>
        <span className="sr-only">Email</span>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          defaultValue={state.email}
          placeholder="Email"
          className="h-[42px] flex-1 bg-transparent px-1.5 text-[#1e1e1e] placeholder:text-[#7a7a7a] focus:outline-none"
        />
      </label>

      <div className="mx-1.5 my-1.5 h-px bg-[rgba(180,170,170,0.55)]" />

      <label className="flex items-center gap-2.5 px-1.5 py-1">
        <IconBubble>
          <svg viewBox="0 0 16 16" className="size-3.5" fill="currentColor" aria-hidden>
            <path d="M5 7V5a3 3 0 1 1 6 0v2h.5A1.5 1.5 0 0 1 13 8.5v5a1.5 1.5 0 0 1-1.5 1.5h-7A1.5 1.5 0 0 1 3 13.5v-5A1.5 1.5 0 0 1 4.5 7H5Zm1.5 0h3V5a1.5 1.5 0 0 0-3 0v2Z" />
          </svg>
        </IconBubble>
        <span className="sr-only">Password</span>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          placeholder="Password"
          className="h-[42px] flex-1 bg-transparent px-1.5 text-[#1e1e1e] placeholder:text-[#7a7a7a] focus:outline-none"
        />
        <span className="text-lg text-[#b7b0b0]" aria-hidden>
          ›
        </span>
      </label>

      {state.error && (
        <p role="alert" className="mt-3 rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko">
          {state.error}
        </p>
      )}

      <button type="submit" disabled={pending} className="btn-kinko mt-4 w-full">
        {pending ? "Logging in…" : "Log In"}
      </button>
    </form>
  );
}
