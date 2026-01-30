'use client';

import { useState } from 'react';

const STORAGE_KEY = 'taskflow-promo-dismissed';

const getInitialVisibility = () => {
  if (typeof window === 'undefined') {
    return false;
  }
  const isDismissed = localStorage.getItem(STORAGE_KEY);
  return !isDismissed;
};

export const PromoBanner = () => {
  const [isVisible, setIsVisible] = useState(getInitialVisibility);

  const handleDismiss = () => {
    setIsVisible(false);
    localStorage.setItem(STORAGE_KEY, 'true');
  };

  if (!isVisible) {
    return null;
  }

  return (
    <div className="bg-red-600 text-white">
      <div className="container mx-auto px-4 py-3 flex items-center justify-between gap-4">
        <div className="flex-1 min-w-0">
          <h2 className="text-lg font-semibold mb-1">Black Friday Sale Coming Soon!</h2>
          <p className="text-sm text-white/90">
            Exclusive deals arriving in 7 days. Don&apos;t miss out!
          </p>
        </div>
        <button
          onClick={handleDismiss}
          className="flex-shrink-0 p-2 hover:bg-red-700 rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-white/50"
          aria-label="Dismiss banner"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>
  );
};
