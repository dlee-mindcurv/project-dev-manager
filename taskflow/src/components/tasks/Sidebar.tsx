'use client';

import { useState } from 'react';
import { useTaskContext } from '@/context/TaskContext';
import { useTheme } from '@/context/ThemeContext';
import { Button, Input, Logo } from '@/components/ui';

export function Sidebar() {
  const { lists, addList, deleteList, selectedListId, setSelectedList, tasks } =
    useTaskContext();
  const { theme, toggleTheme } = useTheme();
  const [newListName, setNewListName] = useState('');
  const [isAdding, setIsAdding] = useState(false);

  const handleAddList = () => {
    if (!newListName.trim()) return;
    addList({ name: newListName.trim() });
    setNewListName('');
    setIsAdding(false);
  };

  const getTaskCount = (listId: string | null) => {
    if (listId === null) {
      return tasks.length;
    }
    return tasks.filter((t) => t.listId === listId).length;
  };

  return (
    <aside className="w-64 bg-gray-50 dark:bg-gray-900 border-r border-gray-200 dark:border-gray-700 p-4 hidden md:block">
      <div className="mb-6 pb-4 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
        <Logo size="md" />
        <button
          onClick={toggleTheme}
          className="p-2 rounded-lg text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-800 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500"
          aria-label="Toggle theme"
        >
          {theme === 'dark' ? (
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fillRule="evenodd"
                d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
                clipRule="evenodd"
              />
            </svg>
          ) : (
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
            </svg>
          )}
        </button>
      </div>

      <h2 className="font-semibold text-gray-900 dark:text-gray-100 mb-4">Lists</h2>

      <nav className="space-y-1">
        <button
          onClick={() => setSelectedList(null)}
          className={`w-full flex items-center justify-between px-3 py-2 text-sm rounded-lg transition-colors ${
            selectedListId === null
              ? 'bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-200'
              : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800'
          }`}
        >
          <span>All Tasks</span>
          <span className="text-xs bg-gray-200 dark:bg-gray-700 px-2 py-0.5 rounded-full">
            {getTaskCount(null)}
          </span>
        </button>

        {lists.map((list) => (
          <div key={list.id} className="group flex items-center">
            <button
              onClick={() => setSelectedList(list.id)}
              className={`flex-1 flex items-center justify-between px-3 py-2 text-sm rounded-lg transition-colors ${
                selectedListId === list.id
                  ? 'bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-200'
                  : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800'
              }`}
            >
              <span className="flex items-center gap-2">
                {list.color && (
                  <span
                    className="w-2 h-2 rounded-full"
                    style={{ backgroundColor: list.color }}
                  />
                )}
                {list.name}
              </span>
              <span className="text-xs bg-gray-200 dark:bg-gray-700 px-2 py-0.5 rounded-full">
                {getTaskCount(list.id)}
              </span>
            </button>
            <button
              onClick={() => deleteList(list.id)}
              className="p-1 text-gray-400 dark:text-gray-500 hover:text-red-600 dark:hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-4 w-4"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fillRule="evenodd"
                  d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                  clipRule="evenodd"
                />
              </svg>
            </button>
          </div>
        ))}
      </nav>

      <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
        {isAdding ? (
          <div className="space-y-2">
            <Input
              placeholder="List name"
              value={newListName}
              onChange={(e) => setNewListName(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleAddList()}
              autoFocus
            />
            <div className="flex gap-2">
              <Button size="sm" onClick={handleAddList}>
                Add
              </Button>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => {
                  setIsAdding(false);
                  setNewListName('');
                }}
              >
                Cancel
              </Button>
            </div>
          </div>
        ) : (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setIsAdding(true)}
            className="w-full justify-start"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-4 w-4 mr-2"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fillRule="evenodd"
                d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
                clipRule="evenodd"
              />
            </svg>
            New List
          </Button>
        )}
      </div>
    </aside>
  );
}
