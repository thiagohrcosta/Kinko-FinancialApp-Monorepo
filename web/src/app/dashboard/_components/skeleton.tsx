export function CardSkeleton({ className = "" }: { className?: string }) {
  return <div className={`card animate-pulse bg-chip ${className}`} />;
}
