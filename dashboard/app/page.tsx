import { fetchResumes, fetchHealth } from "@/lib/api";

export default async function DashboardHome() {
  let resumes = [];
  let health = { status: "unknown" };

  try {
    [resumes, health] = await Promise.all([
      fetchResumes().catch(() => []),
      fetchHealth().catch(() => ({ status: "unreachable" })),
    ]);
  } catch {
    // Non-critical — dashboard still renders
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Dashboard</h1>
        <p className="text-sm text-muted-foreground">
          Welcome to your CareerHub.
        </p>
      </div>

      {/* Summary cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <SummaryCard title="Applications" value="—" />
        <SummaryCard title="Resumes" value={String(resumes.length)} />
        <SummaryCard title="Sync Status" value={health.status} />
        <SummaryCard title="Default Resume" value={resumes.find((r) => r.is_default)?.title || "None"} />
      </div>

      {/* Recent activity / resume list */}
      <div className="rounded-lg border bg-card p-4">
        <h2 className="mb-3 text-sm font-medium">Resumes</h2>
        {resumes.length === 0 ? (
          <p className="text-sm text-muted-foreground">
            No resumes synced yet. Create one in the Resume section.
          </p>
        ) : (
          <ul className="space-y-2">
            {resumes.map((r) => (
              <li key={r.id} className="flex items-center justify-between text-sm">
                <span>{r.title}</span>
                <span className="text-muted-foreground">{r.is_default ? "Default" : ""}</span>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Quick actions */}
      <div className="rounded-lg border bg-card p-4">
        <h2 className="mb-3 text-sm font-medium">Quick Actions</h2>
        <div className="flex flex-wrap gap-2">
          <a href="/resume" className="rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground">
            Open Resume Builder
          </a>
          <a href="/applications" className="rounded-md bg-secondary px-3 py-1.5 text-xs font-medium text-secondary-foreground">
            Track Applications
          </a>
        </div>
      </div>
    </div>
  );
}

function SummaryCard({ title, value }: { title: string; value: string }) {
  return (
    <div className="rounded-lg border bg-card p-4">
      <p className="text-xs text-muted-foreground">{title}</p>
      <p className="mt-1 text-lg font-semibold">{value}</p>
    </div>
  );
}
