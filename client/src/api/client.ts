const BASE = '/api/v1';

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
    ...options,
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(body.error || body.errors?.join(', ') || res.statusText);
  }

  return res.json();
}

export const api = {
  // Projects
  getProjects: () => request<any[]>('/projects'),
  getProject: (key: string) => request<any>(`/projects/${key}`),
  createProject: (data: any) => request<any>('/projects', { method: 'POST', body: JSON.stringify(data) }),
  updateProject: (key: string, data: any) => request<any>(`/projects/${key}`, { method: 'PUT', body: JSON.stringify(data) }),
  deleteProject: (key: string) => request<any>(`/projects/${key}`, { method: 'DELETE' }),

  // Issues
  getProjectIssues: (projectKey: string) => request<any[]>(`/projects/${projectKey}/issues`),
  getIssue: (trackingId: string) => request<any>(`/issues/${trackingId}`),
  createIssue: (projectKey: string, data: any) => request<any>(`/projects/${projectKey}/issues`, { method: 'POST', body: JSON.stringify(data) }),
  updateIssue: (trackingId: string, data: any) => request<any>(`/issues/${trackingId}`, { method: 'PUT', body: JSON.stringify(data) }),
  deleteIssue: (trackingId: string) => request<any>(`/issues/${trackingId}`, { method: 'DELETE' }),

  // Transitions
  transitionIssue: (trackingId: string, status: string) => request<any>(`/issues/${trackingId}/transitions`, { method: 'POST', body: JSON.stringify({ status }) }),

  // Comments
  addComment: (trackingId: string, body: string) => request<any>(`/issues/${trackingId}/comments`, { method: 'POST', body: JSON.stringify({ body }) }),

  // Boards
  getBoard: (projectKey: string) => request<any>(`/projects/${projectKey}/board`),
  updateBoard: (id: number, data: any) => request<any>(`/boards/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

  // Repair
  repair: () => request<any>('/repair', { method: 'POST' }),

  // Me
  getMe: () => request<any>('/me'),
};
