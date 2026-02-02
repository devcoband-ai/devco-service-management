import { useDroppable } from '@dnd-kit/core'
import { SortableContext, verticalListSortingStrategy } from '@dnd-kit/sortable'
import IssueCard from './IssueCard'
import type { Issue, BoardColumn } from '../types'

interface Props {
  column: BoardColumn
  issues: Issue[]
  onIssueClick: (issue: Issue) => void
  onQuickCreate: (status: string) => void
}

export default function KanbanColumn({ column, issues, onIssueClick, onQuickCreate }: Props) {
  const { setNodeRef, isOver } = useDroppable({ id: column.status_mapping })

  const isOverLimit = column.wip_limit != null && issues.length > column.wip_limit

  return (
    <div
      ref={setNodeRef}
      style={{
        flex: '1 1 0',
        minWidth: 260,
        maxWidth: 360,
        display: 'flex',
        flexDirection: 'column',
        backgroundColor: isOver ? 'rgba(59,130,246,0.05)' : 'transparent',
        borderRadius: 8,
        transition: 'background-color 0.15s',
      }}
    >
      {/* Column header */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '8px 12px',
        marginBottom: 8,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{
            fontSize: 13,
            fontWeight: 600,
            color: 'var(--text-primary)',
            textTransform: 'uppercase',
            letterSpacing: '0.04em',
          }}>
            {column.name}
          </span>
          <span style={{
            fontSize: 12,
            color: isOverLimit ? 'var(--danger)' : 'var(--text-muted)',
            fontWeight: isOverLimit ? 700 : 400,
          }}>
            {issues.length}{column.wip_limit != null ? `/${column.wip_limit}` : ''}
          </span>
        </div>
        <button
          onClick={() => onQuickCreate(column.status_mapping)}
          style={{
            background: 'none',
            border: 'none',
            color: 'var(--text-muted)',
            fontSize: 18,
            lineHeight: 1,
            padding: '0 4px',
          }}
          title="Quick create"
        >
          +
        </button>
      </div>

      {/* Cards */}
      <div style={{
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        gap: 6,
        padding: '0 6px 16px',
        minHeight: 100,
      }}>
        <SortableContext items={issues.map(i => i.tracking_id)} strategy={verticalListSortingStrategy}>
          {issues.map(issue => (
            <IssueCard key={issue.tracking_id} issue={issue} onClick={onIssueClick} />
          ))}
        </SortableContext>
      </div>
    </div>
  )
}
