export type Severity = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW' | 'INFO';

export interface ThreatSummary {
  id: string;
  frameworkCode: string;
  code: string;
  title: string;
  severity: Severity;
  category: string | null;
  stride: string[];
  tags: string[];
}

export interface ThreatDetail extends ThreatSummary {
  frameworkName: string;
  description: string | null;
  attackVector: string | null;
  attackSurface: string | null;
  cveReferences: string[];
}

export interface Page<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}
