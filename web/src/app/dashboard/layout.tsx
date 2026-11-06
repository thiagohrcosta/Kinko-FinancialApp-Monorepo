import { Suspense } from "react";
import { Logo } from "@/components/logo";
import { getSessionUser } from "@/lib/session";
import { logout } from "../login/actions";

async function UserMenu() {
  const user = await getSessionUser();
  return (
    <div className="flex items-center gap-3">
      <div className="hidden text-right sm:block">
        <p className="text-sm font-medium text-slate-900">{user?.fullName ?? "—"}</p>
        <p className="text-xs text-slate-500">{user?.email}</p>
      </div>
      <form action={logout}>
        <button type="submit" className="btn-ghost">
          Sair
        </button>
      </form>
    </div>
  );
}

export default function DashboardLayout({ children }: LayoutProps<"/dashboard">) {
  return (
    <div className="flex min-h-full flex-1 flex-col">
      <header className="sticky top-0 z-10 border-b border-slate-200 bg-white/80 backdrop-blur">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
          <Logo />
          <Suspense fallback={<div className="h-9 w-32 animate-pulse rounded-lg bg-slate-100" />}>
            <UserMenu />
          </Suspense>
        </div>
      </header>
      <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-8">{children}</main>
    </div>
  );
}
