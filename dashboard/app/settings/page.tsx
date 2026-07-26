export default function SettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Settings</h1>
        <p className="text-sm text-muted-foreground">
          Manage your CareerHub configuration.
        </p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="rounded-lg border bg-card p-4">
          <h2 className="text-sm font-medium">SSO Provider</h2>
          <p className="mt-1 text-xs text-muted-foreground">
            Configured via Authentik dashboard at <code className="rounded bg-muted px-1">/auth</code>
          </p>
        </div>
        <div className="rounded-lg border bg-card p-4">
          <h2 className="text-sm font-medium">Backup</h2>
          <p className="mt-1 text-xs text-muted-foreground">
            Run <code className="rounded bg-muted px-1">./backup.sh</code> to create a full snapshot.
          </p>
        </div>
      </div>
    </div>
  );
}
