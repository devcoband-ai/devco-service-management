import { useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import type { Issue } from '../types'

const TYPE_ICONS: Record<string, string> = {
  epic: '⚡',
  story: '📖',
  task: '✅',
  bug: '🐛',
  spike: '🔬',
  decision: '🎯',
}

const PRIORITY_COLORS: Record<string, string> = {
  critical: '#ef4444',
  high: '#f97316',
  medium: '#3b82f6',
  low: '#6b7280',
}

interface Props {
  issue: Issue
  onClick: (issue: Issue) => void
}

export default function IssueCard({ issue, onClick }: Props) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: issue.tracking_id })

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  }

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      onClick={(e) => {
        e.stopPropagation()
        onClick(issue)
      }}
      className="issue-card"
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 6 }}>
        <span style={{ fontSize: 12, color: 'var(--text-muted)', fontFamily: 'monospace' }}>
          {TYPE_ICONS[issue.issue_type] || '📋'} {issue.tracking_id}
        </span>
        <span style={{
          width: 8,
          height: 8,
          borderRadius: '50%',
          backgroundColor: PRIORITY_COLORS[issue.priority] || '#6b7280',
          flexShrink: 0,
          marginTop: 2,
        }} title={issue.priority} />
      </div>

      <div style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', lineHeight: 1.4 }}>
        {issue.title}
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 8 }}>
        <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
          {(issue.labels || []).slice(0, 2).map(label => (
            <span key={label} style={{
              fontSize: 10,
              padding: '1px 6px',
              borderRadius: 3,
              backgroundColor: 'rgba(59,130,246,0.15)',
              color: 'var(--accent)',
            }}>
              {label}
            </span>
          ))}
        </div>
        {issue.assignee && (
          <span style={{
            width: 24,
            height: 24,
            borderRadius: '50%',
            backgroundColor: 'var(--accent)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 11,
            fontWeight: 600,
            color: '#fff',
          }} title={issue.assignee.name || issue.assignee.email}>
            {(issue.assignee.name || issue.assignee.email)[0].toUpperCase()}
          </span>
        )}
        {issue.story_points != null && (
          <span style={{
            fontSize: 11,
            padding: '1px 6px',
            borderRadius: 10,
            backgroundColor: 'var(--bg-primary)',
            color: 'var(--text-muted)',
            border: '1px solid var(--border)',
          }}>
            {issue.story_points}
          </span>
        )}
      </div>

      <style>{`
        .issue-card {
          background: var(--bg-secondary);
          border: 1px solid var(--border);
          border-radius: 6px;
          padding: 10px 12px;
          cursor: grab;
          transition: border-color 0.15s, box-shadow 0.15s;
        }
        .issue-card:hover {
          border-color: var(--border-hover);
          box-shadow: 0 2px 8px rgba(0,0,0,0.3);
        }
        .issue-card:active {
          cursor: grabbing;
        }
      `}</style>
    </div>
  )
}
