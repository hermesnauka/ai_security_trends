import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { api } from '@/api/client'
import type { Framework, ThreatSummary } from '@/types'
import { SEVERITY_STYLES } from '@/lib/severity'

export default function FrameworkDetail() {
  const { code } = useParams<{ code: string }>()
  const [framework, setFramework] = useState<Framework | null>(null)
  const [threats, setThreats] = useState<ThreatSummary[]>([])
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!code) return
    api.getFramework(code).then(setFramework).catch(() => setError('Framework nie znaleziony.'))
    api
      .getThreats({ frameworkCode: code, size: 50 })
      .then((page) => setThreats(page.content))
      .catch(() => setError('Nie udało się wczytać zagrożeń.'))
  }, [code])

  if (error) return <p className="text-red-400">{error}</p>
  if (!framework) return <p className="text-slate-400">Wczytywanie…</p>

  return (
    <div>
      <Link to="/frameworks" className="text-sm text-slate-400 hover:text-white">
        ← Wszystkie frameworki
      </Link>
      <h1 className="mt-2 text-2xl font-bold text-white">{framework.name}</h1>
      <p className="text-slate-400">
        {framework.code} · v{framework.version}
      </p>
      {framework.description && <p className="mt-3 max-w-2xl text-slate-300">{framework.description}</p>}

      <h2 className="mt-8 mb-3 text-lg font-semibold text-white">Zagrożenia ({threats.length})</h2>
      <div className="space-y-2">
        {threats.map((t) => (
          <Link
            key={t.id}
            to={`/threats/${t.id}`}
            className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-900 p-4 transition-colors hover:border-slate-600"
          >
            <div>
              <div className="font-mono text-xs text-slate-500">{t.code}</div>
              <div className="font-medium text-white">{t.title}</div>
              {t.category && <div className="text-sm text-slate-400">{t.category}</div>}
            </div>
            <span className={`rounded-full border px-3 py-1 text-xs font-medium ${SEVERITY_STYLES[t.severity] ?? SEVERITY_STYLES.INFO}`}>
              {t.severity}
            </span>
          </Link>
        ))}
      </div>
    </div>
  )
}
