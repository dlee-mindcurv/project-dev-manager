interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  variant?: 'full' | 'icon';
  className?: string;
}

const sizes = {
  sm: { icon: 'w-6 h-6', text: 'text-lg' },
  md: { icon: 'w-8 h-8', text: 'text-xl' },
  lg: { icon: 'w-10 h-10', text: 'text-2xl' },
};

export function Logo({ size = 'md', variant = 'full', className = '' }: LogoProps) {
  const { icon: iconSize, text: textSize } = sizes[size];

  return (
    <div className={`flex items-center gap-2 ${className}`}>
      <div
        className={`${iconSize} bg-blue-600 rounded-lg flex items-center justify-center`}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="w-2/3 h-2/3 text-white"
        >
          <path d="M9 11l3 3L22 4" />
          <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11" />
        </svg>
      </div>
      {variant === 'full' && (
        <span className={`${textSize} font-semibold text-gray-900`}>
          TaskFlow
        </span>
      )}
    </div>
  );
}
