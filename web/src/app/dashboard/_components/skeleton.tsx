export function CardSkeleton({ className = "" }: { className?: string }) {
  return <div className={`card animate-pulse bg-slate-100 ${className}`} />;
}
