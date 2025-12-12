import { useEffect, useState } from 'react';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import Login from './pages/Login';
import Signup from './pages/Signup';
import Dashboard from './pages/Dashboard';
import Apiaries from './pages/Apiaries';
import Hives from './pages/Hives';
import Inspections from './pages/Inspections';
import Feeding from './pages/Feeding';
import Analytics from './pages/Analytics';
import Flora from './pages/Flora';
import AIChat from './pages/AIChat';

function AppContent() {
  const { user, loading } = useAuth();
  const [currentPath, setCurrentPath] = useState(window.location.pathname);

  useEffect(() => {
    const handleLocationChange = () => {
      setCurrentPath(window.location.pathname);
    };

    window.addEventListener('popstate', handleLocationChange);

    const originalPushState = window.history.pushState;
    window.history.pushState = function(...args) {
      originalPushState.apply(window.history, args);
      handleLocationChange();
    };

    return () => {
      window.removeEventListener('popstate', handleLocationChange);
      window.history.pushState = originalPushState;
    };
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-amber-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">جاري التحميل...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    if (currentPath === '/signup') {
      return <Signup />;
    }
    return <Login />;
  }

  if (currentPath === '/login' || currentPath === '/signup') {
    window.history.pushState({}, '', '/');
    setCurrentPath('/');
  }

  switch (currentPath) {
    case '/apiaries':
      return <Apiaries />;
    case '/hives':
      return <Hives />;
    case '/inspections':
      return <Inspections />;
    case '/feeding':
      return <Feeding />;
    case '/analytics':
      return <Analytics />;
    case '/flora':
      return <Flora />;
    case '/ai-chat':
      return <AIChat />;
    default:
      return <Dashboard />;
  }
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
