import { useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import { api } from '../api/client'
import IssueDetail from '../components/IssueDetail'
import CreateIssueModal from '../components/CreateIssueModal'
import type { Issue, Project } from '../types'

const TYPE_ICONS: Record<string, string> = {
  epic: '⚡', story: '📖', task: '✅', bug: '🐛', spike: '🔬', decision: '🎯',
}

const PRIORITY_COLORS: Record<string, string> = {
  critical: '#ef4444', high: '#f97316', medium: '#3b82f6', low: '#6b7280',
}

const STATUS_LABELS: Record<string, string> = {
  backlog: 'Backlog', todo: 'To Do', in_progress: 'In Progress', in_review: 'In Review', done: 'Done', cancelled: 'Cancelled',
}

export default function BacklogView() {
  const { projectKey } = useParams<{ projectKey: string }>()
  const [issues, setIssues] = useState<Issue[]>([])
  const [project, setProject] = useState<Project | null>(null)
  const [loading, setLoading] = useState(true)
  const [selectedIssue, setSelectedIssue] = useState<string | null>(null)
  const [createModal, setCreateModal] = useState(false)
  const [filter, setFilter] = useState({ type: '', status: '', search: '' })
  const [sortBy, setSortBy] = useState<'tracking_id' | 'priority' | 'status' | 'updated_at'>('tracking_id')

  useEffect(() => {
    loadData()
  }, [projectKey])

  async function loadData() {
    if (!projectKey) return
    try {
      const [issuesData, projectData] = await Promise.all([
        api.getProjectIssues(projectKey),
        api.getProject(projectKey),
      ])
      setIssues(issuesData)
      setProject(projectData)
    } catch (err) {
      console.error(err)
    }
    setLoading(false)
  }

  // Keyboard shortcuts
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return
      if (e.key === 'n' || e.key === 'N') {
        e.preventDefault()
        setCreateModal(true)
      }
      if (e.key === '/') {
        e.preventDefault()
        document.getElementById('backlog-search')?.focus()
      }
      if (e.key === 'Escape') {
        setSelectedIssue(null)
        setCreateModal(false)
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  const priorityOrder = { critical: 0, high: 1, medium: 2, low: 3 }

  let filtered = issues.filter(i => {
    if (filter.type && i.issue_type !== filter.type) return false
    if (filter.status && i.status !== filter.status) return false
    if (filter.search && !i.title.toLowerCase().includes(filter.search.toLowerCase()) &&
        !i.tracking_id.toLowerCase().includes(filter.search.toLowerCase())) return false
    return true
  })

  filtered.sort((a, b) => {
    if (sortBy === 'priority') return (priorityOrder[a.priority] || 2) - (priorityOrder[b.priority] || 2)
    if (sortBy === 'status') return a.status.localeCompare(b.status)
    if (sortBy === 'updated_at') return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
    return a.tracking_id.localeCompare(b.tracking_id, undefined, { numeric: true })
  })

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', color: 'var(--text-muted)' }}>
        Loading...
      </div>
    )
  }

  return (
    <div style={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{
        padding: '16px 24px',
        borderBottom: '1px solid var(--border)',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
      }}>
        <div>
          <h1 style={{ fontSize: 18, fontWeight: 600 }}>{project?.name} — Backlog</h1>
          <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            {filtered.length} of {issues.length} issues · <kbd style={kbdStyle}>/</kbd> search · <kbd style={kbdStyle}>N</kbd> create
          </span>
        </div>
        <button onClick={() => setCreateModal(true)} style={{
          padding: '8px 16px', fontSize: 13, border: 'none', borderRadius: 5,
          backgroundColor: 'var(--accent)', color: '#fff', fontWeight: 600,
        }}>
          + New Issue
        </button>
      </div>

      {/* Filters */}
      <div style={{
        padding: '12px 24px',
        borderBottom: '1px solid var(--border)',
        display: 'flex',
        gap: 12,
        alignItems: 'center',
        flexWrap: 'wrap',
      }}>
        <input
          id="backlog-search"
          value={filter.search}
          onChange={e => setFilter({ ...filter, search: e.target.value })}
          placeholder="Search issues..."
          style={{ ...inputStyle, width: 240 }}
        />
        <select value={filter.type} onChange={e => setFilter({ ...filter, type: e.target.value })} style={selectStyle}>
          <option value="">All types</option>
          {['epic', 'story', 'task', 'bug', 'spike', 'decision'].map(t => (
            <option key={t} value={t}>{t}</option>
          ))}
        </select>
        <select value={filter.status} onChange={e => setFilter({ ...filter, status: e.target.value })} style={selectStyle}>
          <option value="">All statuses</option>
          {Object.entries(STATUS_LABELS).map(([k, v]) => (
            <option key={k} value={k}>{v}</option>
          ))}
        </select>
        <select value={sortBy} onChange={e => setSortBy(e.target.value as any)} style={selectStyle}>
          <option value="tracking_id">Sort: ID</option>
          <option value="priority">Sort: Priority</option>
          <option value="status">Sort: Status</option>
          <option value="updated_at">Sort: Updated</option>
        </select>
      </div>

      {/* Issue list */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '0 24px' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid var(--border)' }}>
              {['Type', 'Key', 'Title', 'Status', 'Priority', 'Assignee'].map(h => (
                <th key={h} style={{
                  padding: '10px 8px', textAlign: 'left', fontSize: 11, fontWeight: 600,
                  color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em',
                }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.map(issue => (
              <tr
                key={issue.tracking_id}
                onClick={() => setSelectedIssue(issue.tracking_id)}
                style={{ borderBottom: '1px solid var(--border)', cursor: 'pointer' }}
                onMouseOver={e => (e.currentTarget.style.backgroundColor = 'var(--bg-secondary)')}
                onMouseOut={e => (e.currentTarget.style.backgroundColor = 'transparent')}
              >
                <td style={{ padding: '10px 8px', fontSize: 16 }}>
                  {TYPE_ICONS[issue.issue_type] || '📋'}
                </td>
                <td style={{ padding: '10px 8px', fontSize: 13, fontFamily: 'monospace', color: 'var(--accent)' }}>
                  {issue.tracking_id}
                </td>
                <td style={{ padding: '10px 8px', fontSize: 14 }}>
                  {issue.title}
                  {issue.labels && issue.labels.length > 0 && (
                    <span style={{ marginLeft: 8 }}>
                      {issue.labels.slice(0, 2).map(l => (
                        <span key={l} style={{
                          fontSize: 10, padding: '1px 6px', borderRadius: 3, marginRight: 4,
                          backgroundColor: 'rgba(59,130,246,0.15)', color: 'var(--accent)',
                        }}>{l}</span>
                      ))}
                    </span>
                  )}
                </td>
                <td style={{ padding: '10px 8px' }}>
                  <span style={{
                    fontSize: 12, padding: '2px 8px', borderRadius: 10,
                    backgroundColor: 'var(--bg-tertiary)', color: 'var(--text-secondary)',
                  }}>
                    {STATUS_LABELS[issue.status] || issue.status}
                  </span>
                </td>
                <td style={{ padding: '10px 8px' }}>
                  <span style={{
                    display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12,
                    color: PRIORITY_COLORS[issue.priority] || 'var(--text-muted)',
                  }}>
                    <span style={{
                      width: 8, height: 8, borderRadius: '50%',
                      backgroundColor: PRIORITY_COLORS[issue.priority],
                    }} />
                    {issue.priority}
                  </span>
                </td>
                <td style={{ padding: '10px 8px', fontSize: 13, color: 'var(--text-secondary)' }}>
                  {issue.assignee?.name || issue.assignee?.email || '—'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {filtered.length === 0 && (
          <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)' }}>
            No issues found
          </div>
        )}
      </div>

      {selectedIssue && (
        <IssueDetail
          trackingId={selectedIssue}
          onClose={() => setSelectedIssue(null)}
          onUpdate={loadData}
        />
      )}

      {createModal && projectKey && (
        <CreateIssueModal
          projectKey={projectKey}
          onClose={() => setCreateModal(false)}
          onCreated={loadData}
        />
      )}
    </div>
  )
}

const kbdStyle: React.CSSProperties = {
  padding: '1px 6px', fontSize: 11, backgroundColor: 'var(--bg-primary)',
  border: '1px solid var(--border)', borderRadius: 3, fontFamily: 'monospace',
}

const inputStyle: React.CSSProperties = {
  padding: '6px 10px', fontSize: 13, backgroundColor: 'var(--bg-primary)',
  border: '1px solid var(--border)', borderRadius: 5, color: 'var(--text-primary)', outline: 'none',
}

const selectStyle: React.CSSProperties = {
  padding: '6px 10px', fontSize: 13, backgroundColor: 'var(--bg-primary)',
  border: '1px solid var(--border)', borderRadius: 5, color: 'var(--text-primary)', outline: 'none',
}
