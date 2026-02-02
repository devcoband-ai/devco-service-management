import { Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout'
import ProjectList from './pages/ProjectList'
import BoardView from './pages/BoardView'
import BacklogView from './pages/BacklogView'

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<Navigate to="/projects" replace />} />
        <Route path="/projects" element={<ProjectList />} />
        <Route path="/projects/:projectKey/board" element={<BoardView />} />
        <Route path="/projects/:projectKey/backlog" element={<BacklogView />} />
      </Route>
    </Routes>
  )
}
