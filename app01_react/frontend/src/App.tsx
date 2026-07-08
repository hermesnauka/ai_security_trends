import { Route, Routes } from 'react-router-dom'
import NavBar from '@/components/NavBar'
import Dashboard from '@/pages/Dashboard'
import Frameworks from '@/pages/Frameworks'
import FrameworkDetail from '@/pages/FrameworkDetail'

export default function App() {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <NavBar />
      <main className="mx-auto max-w-6xl px-4 py-8">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/frameworks" element={<Frameworks />} />
          <Route path="/frameworks/:code" element={<FrameworkDetail />} />
        </Routes>
      </main>
    </div>
  )
}
