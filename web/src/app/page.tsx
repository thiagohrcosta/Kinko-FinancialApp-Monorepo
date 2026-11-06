import { redirect } from "next/navigation";

// proxy.ts already redirects "/" based on the session; this is just a fallback.
export default function Home() {
  redirect("/login");
}
