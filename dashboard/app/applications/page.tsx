import { Suspense } from "react";

export default function ApplicationsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Applications</h1>
        <p className="text-sm text-muted-foreground">
          Track your job applications seamlessly.
        </p>
      </div>
      <Suspense fallback={<div className="text-sm text-muted-foreground">Loading JobOps…</div>}>
        <iframe
          src="/jobs"
          className="w-full rounded-lg border"
          style={{ height: "calc(100vh - 120px)" }}
          title="JobOps"
        />
      </Suspense>
    </div>
  );
}
