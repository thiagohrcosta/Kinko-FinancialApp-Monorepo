export async function ExpiredNotice({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { expired } = await searchParams;
  if (!expired) return null;
  return (
    <p className="mb-5 rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-800">
      Sua sessão expirou. Entre novamente.
    </p>
  );
}
