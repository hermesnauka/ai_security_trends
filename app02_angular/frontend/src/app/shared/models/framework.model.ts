// Mirrors backend com.threatview.dto.FrameworkResponse - kept in sync by hand
// for now; Phase 4+ could generate these from the OpenAPI spec instead.
export interface Framework {
  id: string;
  code: string;
  name: string;
  version: string;
  description: string | null;
  referenceUrl: string | null;
}
