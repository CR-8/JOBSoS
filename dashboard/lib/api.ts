const API_BASE = process.env.NEXT_PUBLIC_API_URL || "/api";

export interface Resume {
  id: string;
  title: string;
  remote_id: string;
  version: string;
  is_default: boolean;
  synced_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface HealthStatus {
  status: string;
}

export async function fetchResumes(): Promise<Resume[]> {
  const res = await fetch(`${API_BASE}/resumes`, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to fetch resumes");
  return res.json();
}

export async function fetchHealth(): Promise<HealthStatus> {
  const res = await fetch(`${API_BASE}/health`, { cache: "no-store" });
  if (!res.ok) throw new Error("API unhealthy");
  return res.json();
}
