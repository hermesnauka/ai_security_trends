import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '@/api/client'
import type { Framework } from '@/types'

export default function Frameworks() {
  const [frameworks, setFrameworks] = useState<Framework[]>([])
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    api.getFrameworks().then(setFrameworks).catch(() => setError('Nie udało się wczytać frameworków.'))
  }, [])

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-white">Frameworki bezpieczeństwa</h1>
      {error && <p className="text-red-400">{error}</p>}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {frameworks.map((f) => (
          <Link
            key={f.code}
            to={`/frameworks/${f.code}`}
            className="rounded-lg border border-slate-800 bg-slate-900 p-5 transition-colors hover:border-slate-600"
          >
            <div className="text-xs uppercase tracking-wide text-slate-500">{f.code}</div>
            <div className="mt-1 text-lg font-semibold text-white">{f.name}</div>
            <div className="text-sm text-slate-400">{f.version}</div>
            {f.description && <p className="mt-2 text-sm text-slate-400">{f.description}</p>}
          </Link>
        ))}
      </div>
    </div>
  )
}
