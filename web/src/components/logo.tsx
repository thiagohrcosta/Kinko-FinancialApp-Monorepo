import Image from "next/image";

/** Logo oficial (mesmo arquivo do app mobile). `mark` mostra só o "K". */
export function Logo({ variant = "full", className = "" }: { variant?: "full" | "mark"; className?: string }) {
  if (variant === "mark") {
    return <Image src="/kinko-mark.png" alt="Kinko" width={40} height={40} className={className} priority />;
  }
  return <Image src="/logo.png" alt="Kinko" width={120} height={33} className={className} priority />;
}
