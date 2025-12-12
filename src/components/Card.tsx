import { ReactNode } from 'react';

interface CardProps {
  children: ReactNode;
  title?: string;
  subtitle?: string;
  action?: ReactNode;
  className?: string;
  hoverable?: boolean;
  onClick?: () => void;
}

export default function Card({
  children,
  title,
  subtitle,
  action,
  className = '',
  hoverable = false,
  onClick,
}: CardProps) {
  return (
    <div
      className={`bg-white rounded-xl border border-gray-200 shadow-sm ${
        hoverable ? 'hover:shadow-md transition-shadow cursor-pointer' : ''
      } ${className}`}
      onClick={onClick}
    >
      {(title || action) && (
        <div className="px-4 sm:px-6 py-3 sm:py-4 border-b border-gray-200 flex items-center justify-between gap-2">
          <div className="min-w-0 flex-1">
            {title && <h3 className="text-base sm:text-lg font-bold text-gray-900 truncate">{title}</h3>}
            {subtitle && <p className="text-xs sm:text-sm text-gray-600 mt-1 truncate">{subtitle}</p>}
          </div>
          {action && <div className="flex-shrink-0">{action}</div>}
        </div>
      )}
      <div className={`${title || action ? 'p-4 sm:p-6' : 'p-0'}`}>
        {children}
      </div>
    </div>
  );
}
