import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { api } from '@/api/client'
import type { ThreatSummary } from '@/types'

const SEVERITY_STYLES: Record<string, string> = {
  CRITICAL: 'bg-red-950 text-red-300 border-red-900',
  HIGH: 'bg-orange-950 text-orange-300 border-orange-900',
  MEDIUM: 'bg-yellow-950 text-yellow-300 border-yellow-900',
  LOW: 'bg-blue-950 text-blue-300 border-blue-900',
  INFO: 'bg-slate-800 text-slate-300 border-slate-700',
}

const PAGE_SIZE = 20

export default function Threats() {
  const [searchParams, setSearchParams] = useSearchParams()
  const q = searchParams.get('q') ?? ''
  const severity = searchParams.get('severity') ?? ''
  const page = Number(searchParams.get('page') ?? '0')

  const [query, setQuery] = useState(q)
  const [threats, setThreats] = useState<ThreatSummary[]>([])
  const [totalPages, setTotalPages] = useState(0)
  const [totalElements, setTotalElements] = useState(0)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => setQuery(q), [q])

  useEffect(() => {
    api
      .getThreats({ q: q || undefined, severity: severity || undefined, page, size: PAGE_SIZE })
      .then((result) => {
        setThreats(result.content)
        setTotalPages(result.totalPages)
        setTotalElements(result.totalElements)
        setError(null)
      })
      .catch(() => setError('Nie udało się wczytać zagrożeń.'))
  }, [q, severity, page])

  function updateParams(next: { q?: string; severity?: string; page?: number }) {
    const params = new URLSearchParams(searchParams)
    if (next.q !== undefined) {
      if (next.q) params.set('q', next.q)
      else params.delete('q')
    }
    if (next.severity !== undefined) {
      if (next.severity) params.set('severity', next.severity)
      else params.delete('severity')
    }
    params.set('page', String(next.page ?? 0))
    setSearchParams(params)
  }

  function handleSearch(e: React.FormEvent) {
    e.preventDefault()
    updateParams({ q: query.trim() })
  }

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-white">Zagrożenia</h1>

      <form onSubmit={handleSearch} className="mb-4 flex flex-wrap gap-2">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Szukaj po tytule lub opisie..."
          className="min-w-[16rem] flex-1 rounded-md border border-slate-700 bg-slate-900 px-4 py-2 text-slate-100 placeholder-slate-500 focus:border-slate-500 focus:outline-none"
        />
        <select
          value={severity}
          onChange={(e) => updateParams({ severity: e.target.value })}
          className="rounded-md border border-slate-700 bg-slate-900 px-3 py-2 text-slate-100 focus:border-slate-500 focus:outline-none"
        >
          <option value="">Wszystkie poziomy</option>
          <option value="CRITICAL">CRITICAL</option>
          <option value="HIGH">HIGH</option>
          <option value="MEDIUM">MEDIUM</option>
          <option value="LOW">LOW</option>
          <option value="INFO">INFO</option>
        </select>
        <button type="submit" className="rounded-md bg-slate-100 px-4 py-2 font-medium text-slate-900 hover:bg-white">
          Szukaj
        </button>
      </form>

      {error && <p className="text-red-400">{error}</p>}

      <p className="mb-3 text-sm text-slate-400">{totalElements} wyników</p>

      <div className="space-y-2">
        {threats.map((t) => (
          <Link
            key={t.id}
            to={`/frameworks/${t.frameworkCode}`}
            className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-900 p-4 transition-colors hover:border-slate-600"
          >
            <div>
              <div className="font-mono text-xs text-slate-500">
                {t.frameworkCode} · {t.code}
              </div>
              <div className="font-medium text-white">{t.title}</div>
              {t.category && <div className="text-sm text-slate-400">{t.category}</div>}
            </div>
            <span className={`rounded-full border px-3 py-1 text-xs font-medium ${SEVERITY_STYLES[t.severity] ?? SEVERITY_STYLES.INFO}`}>
              {t.severity}
            </span>
          </Link>
        ))}
      </div>

      {totalPages > 1 && (
        <div className="mt-6 flex items-center justify-center gap-4">
          <button
            disabled={page <= 0}
            onClick={() => updateParams({ page: page - 1 })}
            className="rounded-md border border-slate-700 px-3 py-1 text-sm text-slate-200 disabled:opacity-40"
          >
            ← Poprzednia
          </button>
          <span className="text-sm text-slate-400">
            Strona {page + 1} z {totalPages}
          </span>
          <button
            disabled={page >= totalPages - 1}
            onClick={() => updateParams({ page: page + 1 })}
            className="rounded-md border border-slate-700 px-3 py-1 text-sm text-slate-200 disabled:opacity-40"
          >
            Następna →
          </button>
        </div>
      )}
    </div>
  )
}
