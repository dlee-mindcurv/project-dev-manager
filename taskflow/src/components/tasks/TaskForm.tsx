'use client';

import { useState, FormEvent } from 'react';
import { Button, Input, Select } from '@/components/ui';
import { useTaskContext } from '@/context/TaskContext';
import { Priority } from '@/types';

export function TaskForm() {
  const { addTask, lists } = useTaskContext();
  const [isExpanded, setIsExpanded] = useState(false);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState<Priority>('medium');
  const [dueDate, setDueDate] = useState('');
  const [listId, setListId] = useState('');
  const [tags, setTags] = useState('');

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    addTask({
      title: title.trim(),
      description: description.trim() || undefined,
      completed: false,
      priority,
      dueDate: dueDate || undefined,
      listId: listId || undefined,
      tags: tags
        .split(',')
        .map((t) => t.trim())
        .filter(Boolean),
    });

    // Reset form
    setTitle('');
    setDescription('');
    setPriority('medium');
    setDueDate('');
    setListId('');
    setTags('');
    setIsExpanded(false);
  };

  const priorityOptions = [
    { value: 'low', label: 'Low' },
    { value: 'medium', label: 'Medium' },
    { value: 'high', label: 'High' },
  ];

  const listOptions = [
    { value: '', label: 'No list' },
    ...lists.map((list) => ({ value: list.id, label: list.name })),
  ];

  return (
    <form onSubmit={handleSubmit} className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4">
      <div className="flex gap-2">
        <Input
          placeholder="Add a new task..."
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onFocus={() => setIsExpanded(true)}
          className="flex-1"
        />
        <Button type="submit" disabled={!title.trim()}>
          Add
        </Button>
      </div>

      {isExpanded && (
        <div className="mt-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Description
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Add more details..."
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Priority"
              options={priorityOptions}
              value={priority}
              onChange={(e) => setPriority(e.target.value as Priority)}
            />
            <Input
              label="Due Date"
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Select
              label="List"
              options={listOptions}
              value={listId}
              onChange={(e) => setListId(e.target.value)}
            />
            <Input
              label="Tags"
              placeholder="tag1, tag2, ..."
              value={tags}
              onChange={(e) => setTags(e.target.value)}
            />
          </div>

          <div className="flex justify-end">
            <Button
              type="button"
              variant="ghost"
              onClick={() => setIsExpanded(false)}
            >
              Collapse
            </Button>
          </div>
        </div>
      )}
    </form>
  );
}
