# TaskFlow Development Guide

## Project Overview

TaskFlow is a web-based todo application built with Next.js. This document provides guidance for AI assistants and developers working on the codebase.

## Tech Stack

- **Framework**: Next.js 14+ (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State Management**: React Context + useReducer
- **Storage**: Local Storage (browser) with optional API sync
- **Testing**: Jest + React Testing Library

## Project Structure

```
taskflow/
├── src/
│   ├── app/                 # Next.js App Router pages
│   │   ├── layout.tsx       # Root layout
│   │   ├── page.tsx         # Home page
│   │   └── tasks/           # Task-related pages
│   ├── components/          # React components
│   │   ├── ui/              # Reusable UI components
│   │   └── tasks/           # Task-specific components
│   ├── hooks/               # Custom React hooks
│   ├── lib/                 # Utility functions
│   ├── types/               # TypeScript type definitions
│   └── context/             # React Context providers
├── public/                  # Static assets
├── tests/                   # Test files
└── package.json
```

## Development Commands

```bash
npm run dev      # Start development server
npm run build    # Build for production
npm run start    # Start production server
npm run lint     # Run ESLint
npm run test     # Run tests
```

## Code Conventions

### Components
- Use functional components with TypeScript
- Place component-specific types in the same file
- Use named exports for components

### Naming
- Components: PascalCase (`TaskList.tsx`)
- Hooks: camelCase with `use` prefix (`useTaskStore.ts`)
- Utilities: camelCase (`formatDate.ts`)
- Types: PascalCase (`Task`, `Priority`)

### Styling
- Use Tailwind CSS utility classes
- Extract repeated patterns to component classes
- Follow mobile-first responsive design

## Data Models

### Task
```typescript
interface Task {
  id: string;
  title: string;
  description?: string;
  completed: boolean;
  priority: 'high' | 'medium' | 'low';
  dueDate?: string;
  listId?: string;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}
```

### List
```typescript
interface List {
  id: string;
  name: string;
  color?: string;
  createdAt: string;
}
```

## Key Patterns

### State Management
Tasks are managed through a React Context provider with useReducer for predictable state updates.

### Local Storage
Data persists to localStorage automatically on state changes. The app works fully offline.

### Error Handling
Use try-catch blocks for async operations. Display user-friendly error messages via toast notifications.

## Testing Guidelines

- Write unit tests for utility functions
- Write integration tests for user flows
- Test components in isolation with React Testing Library
- Aim for 80% code coverage on critical paths

## Performance Considerations

- Use React.memo for list items to prevent unnecessary re-renders
- Implement virtual scrolling for large task lists
- Lazy load non-critical components
- Optimize images with next/image
