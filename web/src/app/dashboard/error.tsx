"use client";

export default function DashboardError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div className="card mx-auto max-w-md p-6 text-center">
      <h2 className="text-lg font-bold">Não foi possível carregar o dashboard</h2>
      <p className="mt-1 text-sm text-muted">Verifique se o backend está rodando e tente novamente.</p>
      {process.env.NODE_ENV !== "production" && (
        <pre className="mt-3 overflow-x-auto rounded bg-surface p-2 text-left text-xs text-muted">{error.message}</pre>
      )}
      <button onClick={reset} className="mt-4 rounded-xl bg-kinko px-4 py-2.5 text-sm font-semibold text-white hover:bg-kinko-dark">
        Tentar novamente
      </button>
    </div>
  );
}
