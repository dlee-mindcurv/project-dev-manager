'use client';

import { TaskForm, TaskList, TaskFilters, Sidebar } from '@/components/tasks';
import { Logo } from '@/components/ui';

export default function Home() {
  return (
    <div className="min-h-screen flex">
      <Sidebar />

      <main className="flex-1 p-6 md:p-8">
        <div className="max-w-3xl mx-auto">
          <header className="mb-8">
            <div className="md:hidden mb-4">
              <Logo size="lg" />
            </div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100 hidden md:block">TaskFlow</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-1">
              Organize your tasks, focus on what matters.
            </p>
          </header>

          <div className="space-y-6">
            <TaskForm />
            <TaskFilters />
            <TaskList />
          </div>
        </div>
      </main>
    </div>
  );
}
