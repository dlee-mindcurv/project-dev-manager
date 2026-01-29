'use client';

import {
  createContext,
  useContext,
  useReducer,
  useEffect,
  ReactNode,
} from 'react';
import { Task, List, TaskFilter, TaskSort, Priority } from '@/types';
import { generateId } from '@/lib/utils';
import { loadTasks, saveTasks, loadLists, saveLists } from '@/lib/storage';

interface TaskState {
  tasks: Task[];
  lists: List[];
  filter: TaskFilter;
  sort: TaskSort;
  searchQuery: string;
  selectedListId: string | null;
}

type TaskAction =
  | { type: 'SET_TASKS'; payload: Task[] }
  | { type: 'SET_LISTS'; payload: List[] }
  | { type: 'ADD_TASK'; payload: Omit<Task, 'id' | 'createdAt' | 'updatedAt'> }
  | { type: 'UPDATE_TASK'; payload: { id: string; updates: Partial<Task> } }
  | { type: 'DELETE_TASK'; payload: string }
  | { type: 'TOGGLE_TASK'; payload: string }
  | { type: 'ADD_LIST'; payload: Omit<List, 'id' | 'createdAt'> }
  | { type: 'DELETE_LIST'; payload: string }
  | { type: 'SET_FILTER'; payload: TaskFilter }
  | { type: 'SET_SORT'; payload: TaskSort }
  | { type: 'SET_SEARCH'; payload: string }
  | { type: 'SET_SELECTED_LIST'; payload: string | null };

const initialState: TaskState = {
  tasks: [],
  lists: [],
  filter: 'all',
  sort: 'createdAt',
  searchQuery: '',
  selectedListId: null,
};

function taskReducer(state: TaskState, action: TaskAction): TaskState {
  switch (action.type) {
    case 'SET_TASKS':
      return { ...state, tasks: action.payload };

    case 'SET_LISTS':
      return { ...state, lists: action.payload };

    case 'ADD_TASK': {
      const now = new Date().toISOString();
      const newTask: Task = {
        ...action.payload,
        id: generateId(),
        createdAt: now,
        updatedAt: now,
      };
      return { ...state, tasks: [newTask, ...state.tasks] };
    }

    case 'UPDATE_TASK': {
      const { id, updates } = action.payload;
      return {
        ...state,
        tasks: state.tasks.map((task) =>
          task.id === id
            ? { ...task, ...updates, updatedAt: new Date().toISOString() }
            : task
        ),
      };
    }

    case 'DELETE_TASK':
      return {
        ...state,
        tasks: state.tasks.filter((task) => task.id !== action.payload),
      };

    case 'TOGGLE_TASK':
      return {
        ...state,
        tasks: state.tasks.map((task) =>
          task.id === action.payload
            ? {
                ...task,
                completed: !task.completed,
                updatedAt: new Date().toISOString(),
              }
            : task
        ),
      };

    case 'ADD_LIST': {
      const newList: List = {
        ...action.payload,
        id: generateId(),
        createdAt: new Date().toISOString(),
      };
      return { ...state, lists: [...state.lists, newList] };
    }

    case 'DELETE_LIST':
      return {
        ...state,
        lists: state.lists.filter((list) => list.id !== action.payload),
        tasks: state.tasks.map((task) =>
          task.listId === action.payload ? { ...task, listId: undefined } : task
        ),
        selectedListId:
          state.selectedListId === action.payload
            ? null
            : state.selectedListId,
      };

    case 'SET_FILTER':
      return { ...state, filter: action.payload };

    case 'SET_SORT':
      return { ...state, sort: action.payload };

    case 'SET_SEARCH':
      return { ...state, searchQuery: action.payload };

    case 'SET_SELECTED_LIST':
      return { ...state, selectedListId: action.payload };

    default:
      return state;
  }
}

interface TaskContextValue extends TaskState {
  addTask: (task: Omit<Task, 'id' | 'createdAt' | 'updatedAt'>) => void;
  updateTask: (id: string, updates: Partial<Task>) => void;
  deleteTask: (id: string) => void;
  toggleTask: (id: string) => void;
  addList: (list: Omit<List, 'id' | 'createdAt'>) => void;
  deleteList: (id: string) => void;
  setFilter: (filter: TaskFilter) => void;
  setSort: (sort: TaskSort) => void;
  setSearch: (query: string) => void;
  setSelectedList: (listId: string | null) => void;
  filteredTasks: Task[];
}

const TaskContext = createContext<TaskContextValue | null>(null);

export function TaskProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(taskReducer, initialState);

  // Load data from localStorage on mount
  useEffect(() => {
    dispatch({ type: 'SET_TASKS', payload: loadTasks() });
    dispatch({ type: 'SET_LISTS', payload: loadLists() });
  }, []);

  // Save tasks to localStorage when they change
  useEffect(() => {
    if (state.tasks.length > 0 || loadTasks().length > 0) {
      saveTasks(state.tasks);
    }
  }, [state.tasks]);

  // Save lists to localStorage when they change
  useEffect(() => {
    if (state.lists.length > 0 || loadLists().length > 0) {
      saveLists(state.lists);
    }
  }, [state.lists]);

  // Filter and sort tasks
  const filteredTasks = state.tasks
    .filter((task) => {
      // Filter by completion status
      if (state.filter === 'active' && task.completed) return false;
      if (state.filter === 'completed' && !task.completed) return false;

      // Filter by selected list
      if (state.selectedListId && task.listId !== state.selectedListId)
        return false;

      // Filter by search query
      if (state.searchQuery) {
        const query = state.searchQuery.toLowerCase();
        return (
          task.title.toLowerCase().includes(query) ||
          task.description?.toLowerCase().includes(query) ||
          task.tags.some((tag) => tag.toLowerCase().includes(query))
        );
      }

      return true;
    })
    .sort((a, b) => {
      switch (state.sort) {
        case 'dueDate':
          if (!a.dueDate && !b.dueDate) return 0;
          if (!a.dueDate) return 1;
          if (!b.dueDate) return -1;
          return new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime();
        case 'priority': {
          const priorityOrder: Record<Priority, number> = {
            high: 0,
            medium: 1,
            low: 2,
          };
          return priorityOrder[a.priority] - priorityOrder[b.priority];
        }
        case 'createdAt':
        default:
          return (
            new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
          );
      }
    });

  const value: TaskContextValue = {
    ...state,
    filteredTasks,
    addTask: (task) => dispatch({ type: 'ADD_TASK', payload: task }),
    updateTask: (id, updates) =>
      dispatch({ type: 'UPDATE_TASK', payload: { id, updates } }),
    deleteTask: (id) => dispatch({ type: 'DELETE_TASK', payload: id }),
    toggleTask: (id) => dispatch({ type: 'TOGGLE_TASK', payload: id }),
    addList: (list) => dispatch({ type: 'ADD_LIST', payload: list }),
    deleteList: (id) => dispatch({ type: 'DELETE_LIST', payload: id }),
    setFilter: (filter) => dispatch({ type: 'SET_FILTER', payload: filter }),
    setSort: (sort) => dispatch({ type: 'SET_SORT', payload: sort }),
    setSearch: (query) => dispatch({ type: 'SET_SEARCH', payload: query }),
    setSelectedList: (listId) =>
      dispatch({ type: 'SET_SELECTED_LIST', payload: listId }),
  };

  return <TaskContext.Provider value={value}>{children}</TaskContext.Provider>;
}

export function useTaskContext() {
  const context = useContext(TaskContext);
  if (!context) {
    throw new Error('useTaskContext must be used within a TaskProvider');
  }
  return context;
}
