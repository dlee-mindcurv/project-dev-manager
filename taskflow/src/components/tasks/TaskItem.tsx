'use client';

import { memo, useState } from 'react';
import { Task } from '@/types';
import { Badge, Button } from '@/components/ui';
import { formatDate, isOverdue } from '@/lib/utils';
import { useTaskContext } from '@/context/TaskContext';

interface TaskItemProps {
  task: Task;
}

export const TaskItem = memo(function TaskItem({ task }: TaskItemProps) {
  const { toggleTask, deleteTask } = useTaskContext();
  const [isExpanded, setIsExpanded] = useState(false);

  const overdue = isOverdue(task.dueDate) && !task.completed;

  return (
    <div
      className={`bg-white dark:bg-gray-800 border rounded-lg p-4 transition-all ${
        task.completed ? 'opacity-60' : ''
      } ${overdue ? 'border-red-300 dark:border-red-700' : 'border-gray-200 dark:border-gray-700'}`}
    >
      <div className="flex items-start gap-3">
        <input
          type="checkbox"
          checked={task.completed}
          onChange={() => toggleTask(task.id)}
          className="mt-1 h-5 w-5 rounded border-gray-300 dark:border-gray-600 text-blue-600 focus:ring-blue-500 cursor-pointer dark:bg-gray-700"
        />

        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <h3
              className={`font-medium text-gray-900 dark:text-gray-100 ${
                task.completed ? 'line-through' : ''
              }`}
            >
              {task.title}
            </h3>
            <Badge variant={task.priority}>{task.priority}</Badge>
            {overdue && <Badge variant="high">Overdue</Badge>}
          </div>

          {task.description && (
            <p
              className={`mt-1 text-sm text-gray-600 dark:text-gray-400 ${
                isExpanded ? '' : 'line-clamp-2'
              }`}
              onClick={() => setIsExpanded(!isExpanded)}
            >
              {task.description}
            </p>
          )}

          <div className="mt-2 flex items-center gap-4 text-xs text-gray-500 dark:text-gray-400">
            {task.dueDate && (
              <span className={overdue ? 'text-red-600 dark:text-red-400 font-medium' : ''}>
                Due: {formatDate(task.dueDate)}
              </span>
            )}
            {task.tags.length > 0 && (
              <div className="flex gap-1">
                {task.tags.map((tag) => (
                  <span
                    key={tag}
                    className="bg-gray-100 dark:bg-gray-700 px-1.5 py-0.5 rounded"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            )}
          </div>
        </div>

        <Button
          variant="ghost"
          size="sm"
          onClick={() => deleteTask(task.id)}
          className="text-gray-400 dark:text-gray-500 hover:text-red-600 dark:hover:text-red-400"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-5 w-5"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fillRule="evenodd"
              d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
              clipRule="evenodd"
            />
          </svg>
        </Button>
      </div>
    </div>
  );
});
