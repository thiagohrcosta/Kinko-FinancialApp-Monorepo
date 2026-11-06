"use client";

export default function DashboardError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div className="card mx-auto max-w-md p-6 text-center">
      <h2 className="text-lg font-semibold">Não foi possível carregar o dashboard</h2>
      <p className="mt-1 text-sm text-slate-500">
        Verifique se o backend está rodando e tente novamente.
      </p>
      {process.env.NODE_ENV !== "production" && (
        <pre className="mt-3 overflow-x-auto rounded bg-slate-100 p-2 text-left text-xs text-slate-600">
          {error.message}
        </pre>
      )}
      <button onClick={reset} className="btn-primary mt-4">
        Tentar novamente
      </button>
    </div>
  );
}
