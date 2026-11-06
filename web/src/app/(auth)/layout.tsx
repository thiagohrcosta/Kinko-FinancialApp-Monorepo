import Image from "next/image";

// Fundo compartilhado por login e cadastro — mesma arte da tela de login do app mobile.
export default function AuthLayout({ children }: LayoutProps<"/">) {
  return (
    <main className="relative flex flex-1 overflow-hidden">
      <Image src="/bglogin.jpg" alt="" fill priority sizes="100vw" className="-z-10 object-cover opacity-90" />
      {children}
    </main>
  );
}
