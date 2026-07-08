import type { Framework, Page, ThreatDetail, ThreatSummary } from '@/types'

const API_BASE = '/api/v1'

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message)
  }
}

async function request<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`)
  if (!res.ok) {
    throw new ApiError(res.status, `Request to ${path} failed with ${res.status}`)
  }
  return res.json() as Promise<T>
}

export const api = {
  getFrameworks: () => request<Framework[]>('/frameworks'),
  getFramework: (code: string) => request<Framework>(`/frameworks/${code}`),
  getThreats: (params: { frameworkCode?: string; severity?: string; q?: string; page?: number; size?: number } = {}) => {
    const search = new URLSearchParams()
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== '') search.set(key, String(value))
    })
    const suffix = search.toString() ? `?${search.toString()}` : ''
    return request<Page<ThreatSummary>>(`/threats${suffix}`)
  },
  getThreat: (id: string) => request<ThreatDetail>(`/threats/${id}`),
}

export { ApiError }
