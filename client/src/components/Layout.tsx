import { Outlet, Link, useLocation } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { api } from '../api/client'
import type { Project } from '../types'

export default function Layout() {
  const location = useLocation()
  const [projects, setProjects] = useState<Project[]>([])

  useEffect(() => {
    api.getProjects().then(setProjects).catch(console.error)
  }, [])

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <nav style={{
        width: 240,
        backgroundColor: 'var(--bg-secondary)',
        borderRight: '1px solid var(--border)',
        padding: '16px 0',
        display: 'flex',
        flexDirection: 'column',
        flexShrink: 0,
      }}>
        <Link to="/projects" style={{
          padding: '12px 20px',
          fontSize: 18,
          fontWeight: 700,
          color: 'var(--text-primary)',
          letterSpacing: '-0.02em',
          display: 'flex',
          alignItems: 'center',
          gap: 8,
        }}>
          <span style={{ fontSize: 20 }}>◆</span> ServiceMgmt
        </Link>

        <div style={{ padding: '16px 12px 8px', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          Projects
        </div>

        {projects.map(p => (
          <div key={p.key}>
            <Link
              to={`/projects/${p.key}/board`}
              style={{
                display: 'block',
                padding: '8px 20px',
                fontSize: 14,
                color: location.pathname.includes(`/projects/${p.key}`) ? 'var(--accent)' : 'var(--text-secondary)',
                fontWeight: location.pathname.includes(`/projects/${p.key}`) ? 600 : 400,
                backgroundColor: location.pathname.includes(`/projects/${p.key}`) ? 'rgba(59,130,246,0.1)' : 'transparent',
                borderLeft: location.pathname.includes(`/projects/${p.key}`) ? '2px solid var(--accent)' : '2px solid transparent',
              }}
            >
              <span style={{ fontWeight: 700, marginRight: 6 }}>{p.key}</span>
              {p.name}
            </Link>
            {location.pathname.includes(`/projects/${p.key}`) && (
              <div style={{ paddingLeft: 32 }}>
                <Link
                  to={`/projects/${p.key}/board`}
                  style={{
                    display: 'block',
                    padding: '4px 20px',
                    fontSize: 13,
                    color: location.pathname.endsWith('/board') ? 'var(--text-primary)' : 'var(--text-muted)',
                  }}
                >
                  Board
                </Link>
                <Link
                  to={`/projects/${p.key}/backlog`}
                  style={{
                    display: 'block',
                    padding: '4px 20px',
                    fontSize: 13,
                    color: location.pathname.endsWith('/backlog') ? 'var(--text-primary)' : 'var(--text-muted)',
                  }}
                >
                  Backlog
                </Link>
              </div>
            )}
          </div>
        ))}
      </nav>

      {/* Main content */}
      <main style={{ flex: 1, overflow: 'auto' }}>
        <Outlet />
      </main>
    </div>
  )
}
