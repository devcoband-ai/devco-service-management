import { useState } from 'react'
import { api } from '../api/client'
import type { IssueType, Priority } from '../types'

const TYPES: IssueType[] = ['task', 'story', 'bug', 'epic', 'spike', 'decision']
const PRIORITIES: Priority[] = ['critical', 'high', 'medium', 'low']

interface Props {
  projectKey: string
  defaultStatus?: string
  onClose: () => void
  onCreated: () => void
}

export default function CreateIssueModal({ projectKey, defaultStatus = 'backlog', onClose, onCreated }: Props) {
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [issueType, setIssueType] = useState<IssueType>('task')
  const [priority, setPriority] = useState<Priority>('medium')
  const [labels, setLabels] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!title.trim()) return

    setSubmitting(true)
    setError('')

    try {
      await api.createIssue(projectKey, {
        title: title.trim(),
        description: description.trim() || null,
        issue_type: issueType,
        priority,
        status: defaultStatus,
        labels: labels.split(',').map(l => l.trim()).filter(Boolean),
      })
      onCreated()
      onClose()
    } catch (err: any) {
      setError(err.message)
    }
    setSubmitting(false)
  }

  return (
    <div style={overlayStyle} onClick={onClose}>
      <div style={modalStyle} onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <h3 style={{ fontSize: 16, fontWeight: 600 }}>Create Issue</h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: 18 }}>✕</button>
        </div>

        {error && (
          <div style={{ padding: '8px 12px', marginBottom: 12, backgroundColor: 'rgba(239,68,68,0.1)', border: '1px solid var(--danger)', borderRadius: 5, fontSize: 13, color: 'var(--danger)' }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: 16 }}>
            <label style={labelStyle}>Title *</label>
            <input
              value={title}
              onChange={e => setTitle(e.target.value)}
              style={inputStyle}
              placeholder="Issue title"
              autoFocus
            />
          </div>

          <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
            <div style={{ flex: 1 }}>
              <label style={labelStyle}>Type</label>
              <select value={issueType} onChange={e => setIssueType(e.target.value as IssueType)} style={{ ...inputStyle, cursor: 'pointer' }}>
                {TYPES.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </div>
            <div style={{ flex: 1 }}>
              <label style={labelStyle}>Priority</label>
              <select value={priority} onChange={e => setPriority(e.target.value as Priority)} style={{ ...inputStyle, cursor: 'pointer' }}>
                {PRIORITIES.map(p => <option key={p} value={p}>{p}</option>)}
              </select>
            </div>
          </div>

          <div style={{ marginBottom: 16 }}>
            <label style={labelStyle}>Description</label>
            <textarea
              value={description}
              onChange={e => setDescription(e.target.value)}
              style={{ ...inputStyle, minHeight: 100, resize: 'vertical' }}
              placeholder="Describe the issue..."
            />
          </div>

          <div style={{ marginBottom: 20 }}>
            <label style={labelStyle}>Labels (comma-separated)</label>
            <input
              value={labels}
              onChange={e => setLabels(e.target.value)}
              style={inputStyle}
              placeholder="e.g. frontend, urgent"
            />
          </div>

          <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
            <button type="button" onClick={onClose} style={cancelBtnStyle}>Cancel</button>
            <button type="submit" disabled={submitting || !title.trim()} style={{
              ...submitBtnStyle,
              opacity: submitting || !title.trim() ? 0.5 : 1,
            }}>
              {submitting ? 'Creating...' : 'Create Issue'}
            </button>
          </div>
        </form>
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
  alignItems: 'center',
  justifyContent: 'center',
  zIndex: 1000,
}

const modalStyle: React.CSSProperties = {
  width: 480,
  maxWidth: '90vw',
  maxHeight: '85vh',
  backgroundColor: 'var(--bg-secondary)',
  border: '1px solid var(--border)',
  borderRadius: 10,
  padding: 24,
  overflowY: 'auto',
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

const cancelBtnStyle: React.CSSProperties = {
  padding: '8px 16px',
  fontSize: 13,
  border: '1px solid var(--border)',
  borderRadius: 5,
  backgroundColor: 'var(--bg-tertiary)',
  color: 'var(--text-secondary)',
}

const submitBtnStyle: React.CSSProperties = {
  padding: '8px 16px',
  fontSize: 13,
  border: 'none',
  borderRadius: 5,
  backgroundColor: 'var(--accent)',
  color: '#fff',
  fontWeight: 600,
}
