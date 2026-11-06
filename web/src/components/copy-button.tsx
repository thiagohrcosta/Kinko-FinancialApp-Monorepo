"use client";

import { useState } from "react";

export function CopyButton({ value, label = "Copiar" }: { value: string; label?: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <button
      type="button"
      onClick={async () => {
        try {
          await navigator.clipboard.writeText(value);
          setCopied(true);
          setTimeout(() => setCopied(false), 1500);
        } catch {
          // clipboard indisponível (http sem permissão): o usuário ainda pode selecionar o texto
        }
      }}
      className="shrink-0 rounded-full bg-white/20 px-3 py-1 text-xs font-semibold text-white transition hover:bg-white/30"
    >
      {copied ? "Copiado!" : label}
    </button>
  );
}
