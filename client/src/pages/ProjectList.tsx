import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../api/client'
import type { Project } from '../types'

export default function ProjectList() {
  const [projects, setProjects] = useState<Project[]>([])
  const [loading, setLoading] = useState(true)
  const [creating, setCreating] = useState(false)
  const [newKey, setNewKey] = useState('')
  const [newName, setNewName] = useState('')
  const [newDesc, setNewDesc] = useState('')
  const [repairing, setRepairing] = useState(false)

  useEffect(() => {
    loadProjects()
  }, [])

  async function loadProjects() {
    try {
      const data = await api.getProjects()
      // Load stats for each project
      const withStats = await Promise.all(
        data.map(async (p: Project) => {
          try {
            const detail = await api.getProject(p.key)
            return { ...p, ...detail }
          } catch {
            return p
          }
        })
      )
      setProjects(withStats)
    } catch (err) {
      console.error(err)
    }
    setLoading(false)
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault()
    if (!newKey.trim() || !newName.trim()) return

    try {
      await api.createProject({ key: newKey.toUpperCase(), name: newName, description: newDesc })
      setCreating(false)
      setNewKey('')
      setNewName('')
      setNewDesc('')
      loadProjects()
    } catch (err: any) {
      alert(err.message)
    }
  }

  async function handleRepair() {
    if (!confirm('This will wipe all service management DB tables and rebuild from JSON files. Continue?')) return
    setRepairing(true)
    try {
      const result = await api.repair()
      alert(`Repair complete: ${JSON.stringify(result.stats)}`)
      loadProjects()
    } catch (err: any) {
      alert(`Repair failed: ${err.message}`)
    }
    setRepairing(false)
  }

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', color: 'var(--text-muted)' }}>
        Loading projects...
      </div>
    )
  }

  return (
    <div style={{ padding: 32, maxWidth: 900, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 32 }}>
        <div>
          <h1 style={{ fontSize: 24, fontWeight: 700 }}>Projects</h1>
          <p style={{ color: 'var(--text-muted)', fontSize: 14, marginTop: 4 }}>
            {projects.length} project{projects.length !== 1 ? 's' : ''}
          </p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={handleRepair} disabled={repairing} style={{
            padding: '8px 16px',
            fontSize: 13,
            border: '1px solid var(--border)',
            borderRadius: 5,
            backgroundColor: 'var(--bg-tertiary)',
            color: 'var(--warning)',
            fontWeight: 500,
            opacity: repairing ? 0.5 : 1,
          }}>
            {repairing ? '⟳ Repairing...' : '⟳ Repair DB'}
          </button>
          <button onClick={() => setCreating(true)} style={{
            padding: '8px 16px',
            fontSize: 13,
            border: 'none',
            borderRadius: 5,
            backgroundColor: 'var(--accent)',
            color: '#fff',
            fontWeight: 600,
          }}>
            + New Project
          </button>
        </div>
      </div>

      {/* Create form */}
      {creating && (
        <form onSubmit={handleCreate} style={{
          padding: 20,
          marginBottom: 24,
          backgroundColor: 'var(--bg-secondary)',
          border: '1px solid var(--border)',
          borderRadius: 8,
        }}>
          <div style={{ display: 'flex', gap: 12, marginBottom: 12 }}>
            <div style={{ width: 100 }}>
              <label style={labelStyle}>Key *</label>
              <input
                value={newKey}
                onChange={e => setNewKey(e.target.value.toUpperCase())}
                style={inputStyle}
                placeholder="KEY"
                maxLength={10}
                autoFocus
              />
            </div>
            <div style={{ flex: 1 }}>
              <label style={labelStyle}>Name *</label>
              <input
                value={newName}
                onChange={e => setNewName(e.target.value)}
                style={inputStyle}
                placeholder="Project name"
              />
            </div>
          </div>
          <div style={{ marginBottom: 12 }}>
            <label style={labelStyle}>Description</label>
            <input
              value={newDesc}
              onChange={e => setNewDesc(e.target.value)}
              style={inputStyle}
              placeholder="Brief description"
            />
          </div>
          <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
            <button type="button" onClick={() => setCreating(false)} style={cancelBtn}>Cancel</button>
            <button type="submit" style={submitBtn}>Create Project</button>
          </div>
        </form>
      )}

      {/* Project cards */}
      <div style={{ display: 'grid', gap: 12 }}>
        {projects.map(p => (
          <Link
            key={p.key}
            to={`/projects/${p.key}/board`}
            style={{
              display: 'block',
              padding: 20,
              backgroundColor: 'var(--bg-secondary)',
              border: '1px solid var(--border)',
              borderRadius: 8,
              transition: 'border-color 0.15s',
              textDecoration: 'none',
              color: 'inherit',
            }}
            onMouseOver={e => (e.currentTarget.style.borderColor = 'var(--border-hover)')}
            onMouseOut={e => (e.currentTarget.style.borderColor = 'var(--border)')}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
                  <span style={{
                    fontWeight: 700,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    padding: '2px 8px',
                    backgroundColor: 'rgba(59,130,246,0.15)',
                    color: 'var(--accent)',
                    borderRadius: 4,
                  }}>
                    {p.key}
                  </span>
                  <span style={{ fontSize: 16, fontWeight: 600 }}>{p.name}</span>
                </div>
                {p.description && (
                  <p style={{ fontSize: 14, color: 'var(--text-secondary)', marginTop: 4 }}>
                    {p.description}
                  </p>
                )}
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--accent)' }}>
                  {p.issue_count || 0}
                </div>
                <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>issues</div>
              </div>
            </div>

            {p.issues_by_status && Object.keys(p.issues_by_status).length > 0 && (
              <div style={{ display: 'flex', gap: 12, marginTop: 12 }}>
                {Object.entries(p.issues_by_status).map(([status, count]) => (
                  <span key={status} style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                    <span style={{ textTransform: 'capitalize' }}>{status.replace(/_/g, ' ')}</span>: {count}
                  </span>
                ))}
              </div>
            )}
          </Link>
        ))}
      </div>
    </div>
  )
}

const labelStyle: React.CSSProperties = {
  display: 'block',
  fontSize: 11,
  fontWeight: 600,
  color: 'var(--text-muted)',
  textTransform: 'uppercase',
  letterSpacing: '0.05em',
  marginBottom: 4,
}

const inputStyle: React.CSSProperties = {
  width: '100%',
  padding: '8px 12px',
  fontSize: 14,
  backgroundColor: 'var(--bg-primary)',
  border: '1px solid var(--border)',
  borderRadius: 5,
  color: 'var(--text-primary)',
  outline: 'none',
}

const cancelBtn: React.CSSProperties = {
  padding: '8px 16px',
  fontSize: 13,
  border: '1px solid var(--border)',
  borderRadius: 5,
  backgroundColor: 'var(--bg-tertiary)',
  color: 'var(--text-secondary)',
}

const submitBtn: React.CSSProperties = {
  padding: '8px 16px',
  fontSize: 13,
  border: 'none',
  borderRadius: 5,
  backgroundColor: 'var(--accent)',
  color: '#fff',
  fontWeight: 600,
}
