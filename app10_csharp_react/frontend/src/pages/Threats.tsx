import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { api } from '@/api/client'
import type { Framework, ThreatSummary } from '@/types'
import { SEVERITY_STYLES } from '@/lib/severity'

const SEVERITIES = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO']
const PAGE_SIZE = 20

export default function Threats() {
  const [params, setParams] = useSearchParams()
  const [threats, setThreats] = useState<ThreatSummary[]>([])
  const [frameworks, setFrameworks] = useState<Framework[]>([])
  const [totalElements, setTotalElements] = useState(0)
  const [totalPages, setTotalPages] = useState(0)
  const [error, setError] = useState<string | null>(null)

  const q = params.get('q') ?? ''
  const severity = params.get('severity') ?? ''
  const frameworkCode = params.get('frameworkCode') ?? ''
  const page = Number(params.get('page') ?? '0')

  useEffect(() => {
    api.getFrameworks().then(setFrameworks).catch(() => {})
  }, [])

  useEffect(() => {
    api
      .getThreats({ q, severity, frameworkCode, page, size: PAGE_SIZE })
      .then((result) => {
        setThreats(result.content)
        setTotalElements(result.totalElements)
        setTotalPages(result.totalPages)
        setError(null)
      })
      .catch(() => setError('Nie udało się wczytać zagrożeń.'))
  }, [q, severity, frameworkCode, page])

  function updateFilter(key: string, value: string) {
    const next = new URLSearchParams(params)
    if (value) next.set(key, value)
    else next.delete(key)
    next.delete('page')
    setParams(next)
  }

  function goToPage(nextPage: number) {
    const next = new URLSearchParams(params)
    next.set('page', String(nextPage))
    setParams(next)
  }

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-white">Zagrożenia</h1>

      <div className="mb-6 flex flex-wrap gap-3">
        <input
          value={q}
          onChange={(e) => updateFilter('q', e.target.value)}
          placeholder="Szukaj, np. prompt injection..."
          className="min-w-[16rem] flex-1 rounded-md border border-slate-700 bg-slate-900 px-4 py-2 text-slate-100 placeholder-slate-500 focus:border-slate-500 focus:outline-none"
        />
        <select
          value={severity}
          onChange={(e) => updateFilter('severity', e.target.value)}
          className="rounded-md border border-slate-700 bg-slate-900 px-3 py-2 text-slate-100 focus:border-slate-500 focus:outline-none"
        >
          <option value="">Wszystkie poziomy</option>
          {SEVERITIES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
        <select
          value={frameworkCode}
          onChange={(e) => updateFilter('frameworkCode', e.target.value)}
          className="rounded-md border border-slate-700 bg-slate-900 px-3 py-2 text-slate-100 focus:border-slate-500 focus:outline-none"
        >
          <option value="">Wszystkie frameworki</option>
          {frameworks.map((f) => (
            <option key={f.code} value={f.code}>
              {f.name}
            </option>
          ))}
        </select>
      </div>

      {error && <p className="text-red-400">{error}</p>}

      <p className="mb-3 text-sm text-slate-500">{totalElements} wyników</p>

      <div className="space-y-2">
        {threats.map((t) => (
          <Link
            key={t.id}
            to={`/threats/${t.id}`}
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
        <div className="mt-6 flex items-center justify-center gap-2">
          <button
            disabled={page <= 0}
            onClick={() => goToPage(page - 1)}
            className="rounded-md border border-slate-700 px-3 py-1 text-sm text-slate-300 disabled:opacity-40"
          >
            ← Poprzednia
          </button>
          <span className="text-sm text-slate-500">
            {page + 1} / {totalPages}
          </span>
          <button
            disabled={page >= totalPages - 1}
            onClick={() => goToPage(page + 1)}
            className="rounded-md border border-slate-700 px-3 py-1 text-sm text-slate-300 disabled:opacity-40"
          >
            Następna →
          </button>
        </div>
      )}
    </div>
  )
}
