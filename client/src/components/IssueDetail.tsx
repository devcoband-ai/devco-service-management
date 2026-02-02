import { useState, useEffect } from 'react'
import { api } from '../api/client'
import type { Issue, IssueStatus, Priority, IssueType } from '../types'

const STATUSES: IssueStatus[] = ['backlog', 'todo', 'in_progress', 'in_review', 'done', 'cancelled']
const PRIORITIES: Priority[] = ['critical', 'high', 'medium', 'low']
const TYPES: IssueType[] = ['epic', 'story', 'task', 'bug', 'spike', 'decision']

const STATUS_LABELS: Record<string, string> = {
  backlog: 'Backlog',
  todo: 'To Do',
  in_progress: 'In Progress',
  in_review: 'In Review',
  done: 'Done',
  cancelled: 'Cancelled',
}

interface Props {
  trackingId: string
  onClose: () => void
  onUpdate: () => void
}

export default function IssueDetail({ trackingId, onClose, onUpdate }: Props) {
  const [issue, setIssue] = useState<Issue | null>(null)
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState(false)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [priority, setPriority] = useState<Priority>('medium')
  const [issueType, setIssueType] = useState<IssueType>('task')
  const [commentBody, setCommentBody] = useState('')

  useEffect(() => {
    loadIssue()
  }, [trackingId])

  async function loadIssue() {
    setLoading(true)
    try {
      const data = await api.getIssue(trackingId)
      setIssue(data)
      setTitle(data.title)
      setDescription(data.description || '')
      setPriority(data.priority)
      setIssueType(data.issue_type)
    } catch (err) {
      console.error(err)
    }
    setLoading(false)
  }

  async function handleSave() {
    if (!issue) return
    try {
      await api.updateIssue(trackingId, { title, description, priority, issue_type: issueType })
      setEditing(false)
      await loadIssue()
      onUpdate()
    } catch (err) {
      console.error(err)
    }
  }

  async function handleTransition(status: string) {
    try {
      await api.transitionIssue(trackingId, status)
      await loadIssue()
      onUpdate()
    } catch (err) {
      console.error(err)
    }
  }

  async function handleAddComment() {
    if (!commentBody.trim()) return
    try {
      await api.addComment(trackingId, commentBody)
      setCommentBody('')
      await loadIssue()
    } catch (err) {
      console.error(err)
    }
  }

  async function handleDelete() {
    if (!confirm(`Delete ${trackingId}? This cannot be undone.`)) return
    try {
      await api.deleteIssue(trackingId)
      onUpdate()
      onClose()
    } catch (err) {
      console.error(err)
    }
  }

  if (loading) return <div style={overlayStyle}><div style={panelStyle}><p style={{ color: 'var(--text-muted)' }}>Loading...</p></div></div>
  if (!issue) return null

  return (
    <div style={overlayStyle} onClick={onClose}>
      <div style={panelStyle} onClick={e => e.stopPropagation()}>
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 20 }}>
          <div>
            <span style={{ fontSize: 13, color: 'var(--text-muted)', fontFamily: 'monospace' }}>{issue.tracking_id}</span>
            <span style={{ margin: '0 8px', color: 'var(--text-muted)' }}>·</span>
            <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>{issue.project_key}</span>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={() => setEditing(!editing)} style={btnStyle}>
              {editing ? 'Cancel' : 'Edit'}
            </button>
            <button onClick={onClose} style={{ ...btnStyle, color: 'var(--text-muted)' }}>✕</button>
          </div>
        </div>

        {/* Title */}
        {editing ? (
          <input
            value={title}
            onChange={e => setTitle(e.target.value)}
            style={inputStyle}
            autoFocus
          />
        ) : (
          <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 16, color: 'var(--text-primary)' }}>{issue.title}</h2>
        )}

        {/* Status + Priority row */}
        <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
          <div>
            <label style={labelStyle}>Status</label>
            <select
              value={issue.status}
              onChange={e => handleTransition(e.target.value)}
              style={selectStyle}
            >
              {STATUSES.map(s => <option key={s} value={s}>{STATUS_LABELS[s]}</option>)}
            </select>
          </div>
          <div>
            <label style={labelStyle}>Priority</label>
            {editing ? (
              <select value={priority} onChange={e => setPriority(e.target.value as Priority)} style={selectStyle}>
                {PRIORITIES.map(p => <option key={p} value={p}>{p}</option>)}
              </select>
            ) : (
              <div style={{ fontSize: 14, color: 'var(--text-secondary)', textTransform: 'capitalize' }}>{issue.priority}</div>
            )}
          </div>
          <div>
            <label style={labelStyle}>Type</label>
            {editing ? (
              <select value={issueType} onChange={e => setIssueType(e.target.value as IssueType)} style={selectStyle}>
                {TYPES.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            ) : (
              <div style={{ fontSize: 14, color: 'var(--text-secondary)', textTransform: 'capitalize' }}>{issue.issue_type}</div>
            )}
          </div>
        </div>

        {/* Assignee, Reporter */}
        <div style={{ display: 'flex', gap: 24, marginBottom: 16 }}>
          <div>
            <label style={labelStyle}>Assignee</label>
            <div style={{ fontSize: 14, color: 'var(--text-secondary)' }}>
              {issue.assignee?.name || issue.assignee?.email || 'Unassigned'}
            </div>
          </div>
          <div>
            <label style={labelStyle}>Reporter</label>
            <div style={{ fontSize: 14, color: 'var(--text-secondary)' }}>
              {issue.reporter?.name || issue.reporter?.email || '—'}
            </div>
          </div>
        </div>

        {/* Labels */}
        {issue.labels && issue.labels.length > 0 && (
          <div style={{ marginBottom: 16 }}>
            <label style={labelStyle}>Labels</label>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {issue.labels.map(l => (
                <span key={l} style={{
                  fontSize: 12,
                  padding: '2px 8px',
                  borderRadius: 4,
                  backgroundColor: 'rgba(59,130,246,0.15)',
                  color: 'var(--accent)',
                }}>{l}</span>
              ))}
            </div>
          </div>
        )}

        {/* Description */}
        <div style={{ marginBottom: 20 }}>
          <label style={labelStyle}>Description</label>
          {editing ? (
            <textarea
              value={description}
              onChange={e => setDescription(e.target.value)}
              style={{ ...inputStyle, minHeight: 120, resize: 'vertical' }}
            />
          ) : (
            <div style={{ fontSize: 14, color: 'var(--text-secondary)', whiteSpace: 'pre-wrap', lineHeight: 1.6 }}>
              {issue.description || 'No description'}
            </div>
          )}
        </div>

        {editing && (
          <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
            <button onClick={handleSave} style={{ ...btnStyle, backgroundColor: 'var(--accent)', color: '#fff' }}>Save Changes</button>
            <button onClick={handleDelete} style={{ ...btnStyle, backgroundColor: 'var(--danger)', color: '#fff' }}>Delete Issue</button>
          </div>
        )}

        {/* Links */}
        {issue.links && issue.links.length > 0 && (
          <div style={{ marginBottom: 20 }}>
            <label style={labelStyle}>Links</label>
            {issue.links.map((link, i) => (
              <div key={i} style={{ fontSize: 13, color: 'var(--text-secondary)', padding: '4px 0' }}>
                <span style={{ color: 'var(--text-muted)', textTransform: 'capitalize' }}>{link.type.replace(/_/g, ' ')}</span>
                {' → '}
                <span style={{ color: 'var(--accent)', fontFamily: 'monospace' }}>{link.ref}</span>
              </div>
            ))}
          </div>
        )}

        {/* Comments */}
        <div>
          <label style={labelStyle}>Comments ({issue.comments?.length || 0})</label>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 12 }}>
            {(issue.comments || []).map(c => (
              <div key={c.id} style={{
                padding: '10px 12px',
                backgroundColor: 'var(--bg-primary)',
                borderRadius: 6,
                border: '1px solid var(--border)',
              }}>
                <div style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 4 }}>
                  {c.author?.name || c.author?.email || 'Unknown'} · {new Date(c.created_at).toLocaleDateString()}
                </div>
                <div style={{ fontSize: 14, color: 'var(--text-secondary)' }}>{c.body}</div>
              </div>
            ))}
          </div>

          {/* Add comment */}
          <div style={{ display: 'flex', gap: 8 }}>
            <input
              value={commentBody}
              onChange={e => setCommentBody(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleAddComment()}
              placeholder="Add a comment..."
              style={{ ...inputStyle, flex: 1 }}
            />
            <button onClick={handleAddComment} style={{ ...btnStyle, backgroundColor: 'var(--accent)', color: '#fff' }}>
              Post
            </button>
          </div>
        </div>

        {/* Transitions history */}
        {issue.transitions && issue.transitions.length > 0 && (
          <div style={{ marginTop: 20 }}>
            <label style={labelStyle}>History</label>
            {issue.transitions.map((t, i) => (
              <div key={i} style={{ fontSize: 12, color: 'var(--text-muted)', padding: '2px 0' }}>
                {STATUS_LABELS[t.from_status]} → {STATUS_LABELS[t.to_status]}
                {t.transitioned_by && ` by ${t.transitioned_by}`}
                {' · '}{new Date(t.transitioned_at).toLocaleDateString()}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

const overlayStyle: React.CSSProperties = {
  position: 'fixed',
  top: 0,
  left: 0,
  right: 0,
  bottom: 0,
  backgroundColor: 'rgba(0,0,0,0.6)',
  display: 'flex',
  justifyContent: 'flex-end',
  zIndex: 1000,
}

const panelStyle: React.CSSProperties = {
  width: 560,
  maxWidth: '90vw',
  height: '100vh',
  backgroundColor: 'var(--bg-secondary)',
  borderLeft: '1px solid var(--border)',
  padding: 24,
  overflowY: 'auto',
}

const btnStyle: React.CSSProperties = {
  padding: '6px 12px',
  fontSize: 13,
  border: '1px solid var(--border)',
  borderRadius: 5,
  backgroundColor: 'var(--bg-tertiary)',
  color: 'var(--text-secondary)',
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

const selectStyle: React.CSSProperties = {
  padding: '6px 10px',
  fontSize: 13,
  backgroundColor: 'var(--bg-primary)',
  border: '1px solid var(--border)',
  borderRadius: 5,
  color: 'var(--text-primary)',
  outline: 'none',
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
