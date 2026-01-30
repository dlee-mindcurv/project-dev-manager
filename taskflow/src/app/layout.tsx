import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';
import { TaskProvider } from '@/context/TaskContext';
import { ThemeProvider } from '@/context/ThemeContext';

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
});

export const metadata: Metadata = {
  title: 'TaskFlow - Simple Task Management',
  description:
    'A lightweight, intuitive task management application to organize your daily work.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-gray-100 dark:bg-gray-950`}
      >
        <ThemeProvider>
          <TaskProvider>{children}</TaskProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
