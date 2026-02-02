import { useState, useEffect, useCallback } from 'react'
import { useParams } from 'react-router-dom'
import { DndContext, DragOverlay, closestCenter, PointerSensor, useSensor, useSensors } from '@dnd-kit/core'
import type { DragEndEvent, DragStartEvent } from '@dnd-kit/core'
import { api } from '../api/client'
import KanbanColumn from '../components/KanbanColumn'
import IssueDetail from '../components/IssueDetail'
import CreateIssueModal from '../components/CreateIssueModal'
import type { Board, Issue } from '../types'

export default function BoardView() {
  const { projectKey } = useParams<{ projectKey: string }>()
  const [board, setBoard] = useState<Board | null>(null)
  const [loading, setLoading] = useState(true)
  const [selectedIssue, setSelectedIssue] = useState<string | null>(null)
  const [createModal, setCreateModal] = useState<{ status: string } | null>(null)
  const [activeId, setActiveId] = useState<string | null>(null)

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } })
  )

  const loadBoard = useCallback(async () => {
    if (!projectKey) return
    try {
      const data = await api.getBoard(projectKey)
      setBoard(data)
    } catch (err) {
      console.error(err)
    }
    setLoading(false)
  }, [projectKey])

  useEffect(() => {
    loadBoard()
  }, [loadBoard])

  // Keyboard shortcuts
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return
      if (e.key === 'n' || e.key === 'N') {
        e.preventDefault()
        setCreateModal({ status: 'backlog' })
      }
      if (e.key === 'Escape') {
        setSelectedIssue(null)
        setCreateModal(null)
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  function getIssuesForColumn(statusMapping: string): Issue[] {
    if (!board) return []
    return board.issues.filter(i => i.status === statusMapping)
  }

  function handleDragStart(event: DragStartEvent) {
    setActiveId(event.active.id as string)
  }

  async function handleDragEnd(event: DragEndEvent) {
    setActiveId(null)
    const { active, over } = event
    if (!over || !board) return

    const trackingId = active.id as string
    const targetStatus = over.id as string

    // Find current issue
    const issue = board.issues.find(i => i.tracking_id === trackingId)
    if (!issue || issue.status === targetStatus) return

    // Check if target is a valid column status
    const validStatuses = board.columns.map(c => c.status_mapping)
    if (!validStatuses.includes(targetStatus)) return

    // Optimistic update
    setBoard(prev => {
      if (!prev) return prev
      return {
        ...prev,
        issues: prev.issues.map(i =>
          i.tracking_id === trackingId ? { ...i, status: targetStatus as any } : i
        ),
      }
    })

    // API call
    try {
      await api.transitionIssue(trackingId, targetStatus)
    } catch (err) {
      console.error(err)
      loadBoard() // Revert on error
    }
  }

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', color: 'var(--text-muted)' }}>
        Loading board...
      </div>
    )
  }

  if (!board) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', color: 'var(--text-muted)' }}>
        Board not found
      </div>
    )
  }

  const activeIssue = activeId ? board.issues.find(i => i.tracking_id === activeId) : null

  return (
    <div style={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* Top bar */}
      <div style={{
        padding: '16px 24px',
        borderBottom: '1px solid var(--border)',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
      }}>
        <div>
          <h1 style={{ fontSize: 18, fontWeight: 600 }}>{board.name}</h1>
          <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            {board.issues.length} issue{board.issues.length !== 1 ? 's' : ''} · Press <kbd style={kbdStyle}>N</kbd> to create
          </span>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button
            onClick={() => setCreateModal({ status: 'backlog' })}
            style={{
              padding: '8px 16px',
              fontSize: 13,
              border: 'none',
              borderRadius: 5,
              backgroundColor: 'var(--accent)',
              color: '#fff',
              fontWeight: 600,
            }}
          >
            + New Issue
          </button>
        </div>
      </div>

      {/* Kanban board */}
      <div style={{
        flex: 1,
        display: 'flex',
        gap: 8,
        padding: '16px 16px',
        overflowX: 'auto',
      }}>
        <DndContext
          sensors={sensors}
          collisionDetection={closestCenter}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
        >
          {board.columns.map(col => (
            <KanbanColumn
              key={col.status_mapping}
              column={col}
              issues={getIssuesForColumn(col.status_mapping)}
              onIssueClick={(issue) => setSelectedIssue(issue.tracking_id)}
              onQuickCreate={(status) => setCreateModal({ status })}
            />
          ))}

          <DragOverlay>
            {activeIssue ? (
              <div style={{
                padding: '10px 12px',
                backgroundColor: 'var(--bg-secondary)',
                border: '1px solid var(--accent)',
                borderRadius: 6,
                boxShadow: '0 4px 20px rgba(0,0,0,0.4)',
                maxWidth: 280,
              }}>
                <div style={{ fontSize: 12, color: 'var(--text-muted)', fontFamily: 'monospace', marginBottom: 4 }}>
                  {activeIssue.tracking_id}
                </div>
                <div style={{ fontSize: 13, fontWeight: 500 }}>{activeIssue.title}</div>
              </div>
            ) : null}
          </DragOverlay>
        </DndContext>
      </div>

      {/* Issue detail side panel */}
      {selectedIssue && (
        <IssueDetail
          trackingId={selectedIssue}
          onClose={() => setSelectedIssue(null)}
          onUpdate={loadBoard}
        />
      )}

      {/* Create issue modal */}
      {createModal && projectKey && (
        <CreateIssueModal
          projectKey={projectKey}
          defaultStatus={createModal.status}
          onClose={() => setCreateModal(null)}
          onCreated={loadBoard}
        />
      )}
    </div>
  )
}

const kbdStyle: React.CSSProperties = {
  padding: '1px 6px',
  fontSize: 11,
  backgroundColor: 'var(--bg-primary)',
  border: '1px solid var(--border)',
  borderRadius: 3,
  fontFamily: 'monospace',
}
