export interface User {
  id: number;
  email: string;
  name: string;
}

export interface Project {
  id: number;
  key: string;
  name: string;
  description: string | null;
  lead: User | null;
  status: string;
  issue_count?: number;
  issues_by_status?: Record<string, number>;
  created_at: string;
  updated_at: string;
}

export interface Issue {
  id: number;
  tracking_id: string;
  project_key: string;
  issue_type: IssueType;
  title: string;
  description?: string;
  status: IssueStatus;
  priority: Priority;
  assignee: User | null;
  reporter: User | null;
  labels: string[];
  story_points: number | null;
  sprint: string | null;
  due_date: string | null;
  comments?: Comment[];
  links?: IssueLink[];
  transitions?: Transition[];
  created_at: string;
  updated_at: string;
}

export interface Comment {
  id: number;
  author: User | null;
  body: string;
  created_at: string;
}

export interface IssueLink {
  type: string;
  ref: string;
}

export interface Transition {
  from_status: string;
  to_status: string;
  transitioned_by: string | null;
  transitioned_at: string;
}

export interface BoardColumn {
  name: string;
  status_mapping: string;
  wip_limit: number | null;
}

export interface Board {
  id: number;
  project_key: string;
  name: string;
  columns: BoardColumn[];
  issues: Issue[];
}

export type IssueType = 'epic' | 'story' | 'task' | 'bug' | 'spike' | 'decision';
export type IssueStatus = 'backlog' | 'todo' | 'in_progress' | 'in_review' | 'done' | 'cancelled';
export type Priority = 'critical' | 'high' | 'medium' | 'low';
