export type Priority = 'high' | 'medium' | 'low';

export interface Task {
  id: string;
  title: string;
  description?: string;
  completed: boolean;
  priority: Priority;
  dueDate?: string;
  listId?: string;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

export interface List {
  id: string;
  name: string;
  color?: string;
  createdAt: string;
}

export type TaskFilter = 'all' | 'active' | 'completed';
export type TaskSort = 'createdAt' | 'dueDate' | 'priority';
