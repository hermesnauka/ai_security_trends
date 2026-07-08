// Mirrors backend DTOs in com.scalashield.model - keep in sync by hand for now;
// Phase 4+ could generate these from the OpenAPI spec instead.

export interface Framework {
  id: string
  code: string
  name: string
  version: string
  description: string | null
  referenceUrl: string | null
}

export interface ThreatSummary {
  id: string
  frameworkCode: string
  code: string
  title: string
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW' | 'INFO'
  category: string | null
  stride: string[]
  tags: string[]
}

export interface ThreatDetail extends ThreatSummary {
  frameworkName: string
  description: string | null
  attackVector: string | null
  attackSurface: string | null
  cveReferences: string[]
}

export interface Page<T> {
  content: T[]
  totalElements: number
  totalPages: number
  number: number
  size: number
}
