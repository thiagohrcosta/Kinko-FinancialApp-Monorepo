import Image from "next/image";

// Shared by login and sign-up — same artwork as the mobile app's login screen.
export default function AuthLayout({ children }: LayoutProps<"/">) {
  return (
    <main className="relative flex flex-1 overflow-hidden">
      <Image src="/bglogin.jpg" alt="" fill priority sizes="100vw" className="-z-10 object-cover opacity-90" />
      {children}
    </main>
  );
}
