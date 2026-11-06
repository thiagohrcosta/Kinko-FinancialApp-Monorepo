export async function ExpiredNotice({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { expired } = await searchParams;
  if (!expired) return null;
  return (
    <p className="mb-4 rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko">
      Your session has expired. Please log in again.
    </p>
  );
}
