import { Task, List } from '@/types';

const TASKS_KEY = 'taskflow_tasks';
const LISTS_KEY = 'taskflow_lists';

export function loadTasks(): Task[] {
  if (typeof window === 'undefined') return [];
  try {
    const data = localStorage.getItem(TASKS_KEY);
    return data ? JSON.parse(data) : [];
  } catch {
    return [];
  }
}

export function saveTasks(tasks: Task[]): void {
  if (typeof window === 'undefined') return;
  try {
    localStorage.setItem(TASKS_KEY, JSON.stringify(tasks));
  } catch {
    console.error('Failed to save tasks to localStorage');
  }
}

export function loadLists(): List[] {
  if (typeof window === 'undefined') return [];
  try {
    const data = localStorage.getItem(LISTS_KEY);
    return data ? JSON.parse(data) : [];
  } catch {
    return [];
  }
}

export function saveLists(lists: List[]): void {
  if (typeof window === 'undefined') return;
  try {
    localStorage.setItem(LISTS_KEY, JSON.stringify(lists));
  } catch {
    console.error('Failed to save lists to localStorage');
  }
}
