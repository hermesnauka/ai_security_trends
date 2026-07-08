import { NavLink } from 'react-router-dom'

const linkClass = ({ isActive }: { isActive: boolean }) =>
  `px-3 py-2 rounded-md text-sm font-medium transition-colors ${
    isActive ? 'bg-slate-800 text-white' : 'text-slate-300 hover:bg-slate-800 hover:text-white'
  }`

export default function NavBar() {
  return (
    <nav className="border-b border-slate-800 bg-slate-900">
      <div className="mx-auto flex max-w-6xl items-center gap-2 px-4 py-3">
        <span className="mr-4 text-lg font-semibold text-white">ScalaShield 2026</span>
        <NavLink to="/" className={linkClass} end>
          Panel
        </NavLink>
        <NavLink to="/frameworks" className={linkClass}>
          Frameworki
        </NavLink>
      </div>
    </nav>
  )
}
