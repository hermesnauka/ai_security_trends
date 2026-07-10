import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { api } from '@/api/client'
import type { ThreatDetail as ThreatDetailType } from '@/types'
import { SEVERITY_STYLES } from '@/lib/severity'

export default function ThreatDetail() {
  const { id } = useParams<{ id: string }>()
  const [threat, setThreat] = useState<ThreatDetailType | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!id) return
    api.getThreat(id).then(setThreat).catch(() => setError('Zagrożenie nie znalezione.'))
  }, [id])

  if (error) return <p className="text-red-400">{error}</p>
  if (!threat) return <p className="text-slate-400">Wczytywanie…</p>

  return (
    <div className="max-w-3xl">
      <Link to={`/frameworks/${threat.frameworkCode}`} className="text-sm text-slate-400 hover:text-white">
        ← {threat.frameworkName}
      </Link>

      <div className="mt-2 flex items-start justify-between gap-4">
        <div>
          <div className="font-mono text-sm text-slate-500">{threat.code}</div>
          <h1 className="text-2xl font-bold text-white">{threat.title}</h1>
        </div>
        <span className={`shrink-0 rounded-full border px-3 py-1 text-xs font-medium ${SEVERITY_STYLES[threat.severity] ?? SEVERITY_STYLES.INFO}`}>
          {threat.severity}
        </span>
      </div>

      {threat.category && <p className="mt-2 text-sm text-slate-400">{threat.category}</p>}

      {threat.description && <p className="mt-6 text-slate-300">{threat.description}</p>}

      {threat.attackVector && (
        <section className="mt-6">
          <h2 className="mb-1 text-sm font-semibold uppercase tracking-wide text-slate-500">Wektor ataku</h2>
          <p className="text-slate-300">{threat.attackVector}</p>
        </section>
      )}

      {threat.attackSurface && (
        <section className="mt-6">
          <h2 className="mb-1 text-sm font-semibold uppercase tracking-wide text-slate-500">Powierzchnia ataku</h2>
          <p className="text-slate-300">{threat.attackSurface}</p>
        </section>
      )}

      {threat.stride.length > 0 && (
        <section className="mt-6">
          <h2 className="mb-2 text-sm font-semibold uppercase tracking-wide text-slate-500">STRIDE</h2>
          <div className="flex flex-wrap gap-2">
            {threat.stride.map((s) => (
              <span key={s} className="rounded-full border border-slate-700 bg-slate-900 px-3 py-1 text-xs text-slate-300">
                {s}
              </span>
            ))}
          </div>
        </section>
      )}

      {threat.tags.length > 0 && (
        <section className="mt-6">
          <h2 className="mb-2 text-sm font-semibold uppercase tracking-wide text-slate-500">Tagi</h2>
          <div className="flex flex-wrap gap-2">
            {threat.tags.map((t) => (
              <span key={t} className="rounded-full border border-slate-800 bg-slate-900 px-3 py-1 text-xs text-slate-400">
                {t}
              </span>
            ))}
          </div>
        </section>
      )}

      {threat.cveReferences.length > 0 && (
        <section className="mt-6">
          <h2 className="mb-2 text-sm font-semibold uppercase tracking-wide text-slate-500">CVE</h2>
          <div className="flex flex-wrap gap-2">
            {threat.cveReferences.map((cve) => (
              <span key={cve} className="rounded-full border border-slate-800 bg-slate-900 px-3 py-1 text-xs text-slate-400">
                {cve}
              </span>
            ))}
          </div>
        </section>
      )}
    </div>
  )
}
