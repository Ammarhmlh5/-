import { ReactNode, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import {
  Hexagon,
  LayoutDashboard,
  Map,
  Box,
  FileCheck,
  BarChart3,
  Flower2,
  Bell,
  Settings,
  LogOut,
  Menu,
  X,
  Bot,
  Coffee,
} from 'lucide-react';

interface DashboardLayoutProps {
  children: ReactNode;
}

const navigation = [
  { name: 'لوحة التحكم', href: '/', icon: LayoutDashboard },
  { name: 'المناحل', href: '/apiaries', icon: Map },
  { name: 'الخلايا', href: '/hives', icon: Box },
  { name: 'الفحوصات', href: '/inspections', icon: FileCheck },
  { name: 'التغذية', href: '/feeding', icon: Coffee },
  { name: 'التحليلات', href: '/analytics', icon: BarChart3 },
  { name: 'مكتبة النباتات', href: '/flora', icon: Flower2 },
  { name: 'الطيار الآلي', href: '/ai-chat', icon: Bot },
];

export default function DashboardLayout({ children }: DashboardLayoutProps) {
  const { user, signOut } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="min-h-screen bg-gray-50" dir="rtl">
      <div className={`fixed inset-y-0 right-0 z-50 flex w-72 flex-col bg-white border-l border-gray-200 lg:static transition-transform duration-300 ${
          sidebarOpen ? 'translate-x-0' : 'translate-x-full lg:translate-x-0'
        }`}>

        <div className="flex items-center justify-between h-16 px-6 border-b border-gray-200">
          <div className="flex items-center gap-3">
            <div className="flex items-center justify-center w-10 h-10 bg-amber-500 rounded-lg">
              <Hexagon className="w-6 h-6 text-white" />
            </div>
            <span className="text-xl font-bold text-gray-900">مام هاني</span>
          </div>
          <button
            onClick={() => setSidebarOpen(false)}
            className="lg:hidden p-2 rounded-lg hover:bg-gray-100"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
          {navigation.map((item) => (
            <a
              key={item.name}
              href={item.href}
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition"
            >
              <item.icon className="w-5 h-5" />
              <span className="font-medium">{item.name}</span>
            </a>
          ))}
        </nav>

        <div className="p-4 border-t border-gray-200">
          <button
            onClick={() => signOut()}
            className="flex items-center gap-3 w-full px-4 py-3 text-gray-700 rounded-lg hover:bg-red-50 hover:text-red-600 transition"
          >
            <LogOut className="w-5 h-5" />
            <span className="font-medium">تسجيل الخروج</span>
          </button>
        </div>
      </div>

      <div className="lg:mr-72">
        <header className="sticky top-0 z-40 flex items-center justify-between h-16 px-4 sm:px-6 bg-white border-b border-gray-200">
          <button
            onClick={() => setSidebarOpen(true)}
            className="lg:hidden p-2 rounded-lg hover:bg-gray-100"
          >
            <Menu className="w-6 h-6" />
          </button>

          <div className="flex items-center gap-2 sm:gap-4 mr-auto">
            <a
              href="/ai-chat"
              className="flex items-center gap-2 px-3 sm:px-4 py-2 bg-gradient-to-r from-amber-500 to-orange-500 text-white rounded-lg hover:from-amber-600 hover:to-orange-600 transition shadow-md hover:shadow-lg"
            >
              <Bot className="w-5 h-5" />
              <span className="font-medium hidden sm:inline">الطيار الآلي</span>
            </a>
            <button className="relative p-2 rounded-lg hover:bg-gray-100 hidden sm:block">
              <Bell className="w-6 h-6 text-gray-600" />
              <span className="absolute top-1 left-1 w-2 h-2 bg-red-500 rounded-full"></span>
            </button>
            <button className="p-2 rounded-lg hover:bg-gray-100 hidden md:block">
              <Settings className="w-6 h-6 text-gray-600" />
            </button>
            <div className="flex items-center gap-2 sm:gap-3 pr-2 sm:pr-4 border-r border-gray-200">
              <div className="text-right hidden sm:block">
                <p className="text-sm font-medium text-gray-900 truncate max-w-[120px] md:max-w-[200px]">
                  {user?.user_metadata?.full_name || user?.email}
                </p>
                <p className="text-xs text-gray-500">مربي نحل</p>
              </div>
              <div className="w-9 h-9 sm:w-10 sm:h-10 bg-amber-100 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-amber-700 font-medium text-sm sm:text-base">
                  {(user?.user_metadata?.full_name || user?.email)?.charAt(0).toUpperCase()}
                </span>
              </div>
            </div>
          </div>
        </header>

        <main className="p-4 sm:p-6">
          {children}
        </main>
      </div>

      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black bg-opacity-50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}
    </div>
  );
}
