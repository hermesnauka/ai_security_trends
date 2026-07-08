import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { api } from '@/api/client'
import type { Framework } from '@/types'

export default function Dashboard() {
  const [frameworks, setFrameworks] = useState<Framework[]>([])
  const [threatCount, setThreatCount] = useState<number | null>(null)
  const [query, setQuery] = useState('')
  const [loadError, setLoadError] = useState<string | null>(null)
  const navigate = useNavigate()

  useEffect(() => {
    api.getFrameworks().then(setFrameworks).catch(() => setLoadError('Nie udało się połączyć z API.'))
    api.getThreats({ size: 1 }).then((page) => setThreatCount(page.totalElements)).catch(() => {})
  }, [])

  function handleSearch(e: React.FormEvent) {
    e.preventDefault()
    if (query.trim()) navigate(`/frameworks?q=${encodeURIComponent(query.trim())}`)
  }

  return (
    <div className="space-y-8">
      <section>
        <h1 className="text-3xl font-bold text-white">ScalaShield 2026</h1>
        <p className="mt-2 max-w-2xl text-slate-400">
          Interaktywna baza zagrożeń, mitigacji i przykładów kodu w OWASP, MITRE ATLAS i CompTIA SecAI+.
        </p>
      </section>

      {loadError && (
        <p className="rounded-md border border-red-900 bg-red-950 px-4 py-3 text-sm text-red-300">
          {loadError} Sprawdź, czy backend działa na porcie 8080 (`docker compose up`).
        </p>
      )}

      <section className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="rounded-lg border border-slate-800 bg-slate-900 p-6">
          <div className="text-sm text-slate-400">Frameworki bezpieczeństwa</div>
          <div className="mt-1 text-3xl font-bold text-white">{frameworks.length}</div>
        </div>
        <div className="rounded-lg border border-slate-800 bg-slate-900 p-6">
          <div className="text-sm text-slate-400">Zagrożenia w katalogu</div>
          <div className="mt-1 text-3xl font-bold text-white">{threatCount ?? '—'}</div>
        </div>
      </section>

      <form onSubmit={handleSearch} className="flex gap-2">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Szybkie wyszukiwanie, np. prompt injection..."
          className="w-full rounded-md border border-slate-700 bg-slate-900 px-4 py-2 text-slate-100 placeholder-slate-500 focus:border-slate-500 focus:outline-none"
        />
        <button type="submit" className="rounded-md bg-slate-100 px-4 py-2 font-medium text-slate-900 hover:bg-white">
          Szukaj
        </button>
      </form>

      <section>
        <h2 className="mb-3 text-lg font-semibold text-white">Frameworki</h2>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {frameworks.map((f) => (
            <Link
              key={f.code}
              to={`/frameworks/${f.code}`}
              className="rounded-lg border border-slate-800 bg-slate-900 p-4 transition-colors hover:border-slate-600"
            >
              <div className="font-medium text-white">{f.name}</div>
              <div className="text-sm text-slate-400">{f.version}</div>
            </Link>
          ))}
        </div>
      </section>
    </div>
  )
}
