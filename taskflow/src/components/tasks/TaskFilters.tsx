'use client';

import { useTaskContext } from '@/context/TaskContext';
import { Input, Select } from '@/components/ui';
import { TaskFilter, TaskSort } from '@/types';

export function TaskFilters() {
  const {
    filter,
    setFilter,
    sort,
    setSort,
    searchQuery,
    setSearch,
    tasks,
    filteredTasks,
  } = useTaskContext();

  const filterOptions: { value: TaskFilter; label: string }[] = [
    { value: 'all', label: 'All' },
    { value: 'active', label: 'Active' },
    { value: 'completed', label: 'Completed' },
  ];

  const sortOptions: { value: TaskSort; label: string }[] = [
    { value: 'createdAt', label: 'Date Created' },
    { value: 'dueDate', label: 'Due Date' },
    { value: 'priority', label: 'Priority' },
  ];

  const completedCount = tasks.filter((t) => t.completed).length;
  const activeCount = tasks.filter((t) => !t.completed).length;

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="flex-1">
          <Input
            placeholder="Search tasks..."
            value={searchQuery}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="flex gap-2">
          <Select
            options={filterOptions}
            value={filter}
            onChange={(e) => setFilter(e.target.value as TaskFilter)}
            className="w-32"
          />
          <Select
            options={sortOptions}
            value={sort}
            onChange={(e) => setSort(e.target.value as TaskSort)}
            className="w-36"
          />
        </div>
      </div>

      <div className="flex items-center justify-between text-sm text-gray-600 dark:text-gray-400">
        <div className="flex gap-4">
          <span>{activeCount} active</span>
          <span>{completedCount} completed</span>
        </div>
        {filteredTasks.length !== tasks.length && (
          <span>Showing {filteredTasks.length} of {tasks.length}</span>
        )}
      </div>
    </div>
  );
}
