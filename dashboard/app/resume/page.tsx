import { Suspense } from "react";

export default function ResumePage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Resume</h1>
        <p className="text-sm text-muted-foreground">
          Build and manage your resumes with Reactive Resume.
        </p>
      </div>
      <Suspense fallback={<div className="text-sm text-muted-foreground">Loading Resume Builder…</div>}>
        <iframe
          src="/resume"
          className="w-full rounded-lg border"
          style={{ height: "calc(100vh - 120px)" }}
          title="Reactive Resume"
        />
      </Suspense>
    </div>
  );
}
