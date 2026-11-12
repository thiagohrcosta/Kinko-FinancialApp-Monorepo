import Link from "next/link";
import { Suspense } from "react";
import { Logo } from "@/components/logo";
import { getSessionUser } from "@/lib/session";
import { logout } from "@/lib/session-actions";
import { CountryPrompt } from "./_components/country-prompt";
import { DashboardNav } from "./_components/nav";

async function UserMenu() {
  const user = await getSessionUser();
  return (
    <div className="flex items-center gap-3">
      <div className="hidden text-right sm:block">
        <p className="text-sm font-medium text-ink">{user?.fullName ?? "—"}</p>
        <p className="text-xs text-subtle">{user?.email}</p>
      </div>
      <form action={logout}>
        <button type="submit" className="btn-ghost">
          Log out
        </button>
      </form>
    </div>
  );
}

async function Nav() {
  const user = await getSessionUser();
  return <DashboardNav isBusiness={user?.userType === "business"} />;
}

export default function DashboardLayout({ children }: LayoutProps<"/dashboard">) {
  return (
    <div className="flex min-h-full flex-1 flex-col">
      <header className="sticky top-0 z-20 bg-white shadow-[0_1px_0_rgba(0,0,0,0.06)]">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-5">
          <Link href="/dashboard" aria-label="Kinko — home">
            <Logo />
          </Link>
          <Suspense fallback={<div className="h-9 w-32 animate-pulse rounded-lg bg-chip" />}>
            <UserMenu />
          </Suspense>
        </div>
        <div className="mx-auto max-w-6xl px-5">
          <Suspense fallback={<DashboardNav />}>
            <Nav />
          </Suspense>
        </div>
      </header>
      <main className="mx-auto w-full max-w-6xl flex-1 px-5 py-8">
        <Suspense fallback={null}>
          <CountryPrompt />
        </Suspense>
        {children}
      </main>
    </div>
  );
}
