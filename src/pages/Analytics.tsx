import { useState, useEffect } from 'react';
import DashboardLayout from '../components/DashboardLayout';
import Card from '../components/Card';
import { BarChart3, TrendingUp, TrendingDown, Package, Activity } from 'lucide-react';
import { analyticsService } from '../services/analytics';
import { useAuth } from '../contexts/AuthContext';
import { Analytics as AnalyticsType } from '../types';

export default function Analytics() {
  const { user } = useAuth();
  const [analytics, setAnalytics] = useState<AnalyticsType | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadAnalytics();
  }, [user]);

  const loadAnalytics = async () => {
    if (!user) return;
    try {
      setLoading(true);
      const data = await analyticsService.getDashboardStats(user.id);
      setAnalytics(data);
    } catch (error) {
      console.error('Error loading analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <div className="w-12 h-12 border-4 border-amber-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
            <p className="text-gray-600">جاري التحميل...</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  if (!analytics) {
    return (
      <DashboardLayout>
        <div className="text-center py-12">
          <p className="text-gray-600">لا توجد بيانات للعرض</p>
        </div>
      </DashboardLayout>
    );
  }

  const stats = [
    {
      name: 'إجمالي المناحل',
      value: analytics.totalApiaries,
      icon: BarChart3,
      color: 'amber',
    },
    {
      name: 'إجمالي الخلايا',
      value: analytics.totalHives,
      icon: Package,
      color: 'amber',
    },
    {
      name: 'الخلايا النشطة',
      value: analytics.activeHives,
      icon: Activity,
      color: 'green',
    },
    {
      name: 'متوسط الصحة',
      value: `${analytics.averageHiveHealth}%`,
      icon: TrendingUp,
      color: 'blue',
    },
  ];

  const productionStats = [
    {
      label: 'الإنتاج الشهري',
      value: `${analytics.monthlyProduction} كجم`,
      change: analytics.productionChange,
      trend: analytics.productionChange >= 0 ? 'up' : 'down',
    },
    {
      label: 'الفحوصات المستحقة',
      value: analytics.inspectionsDue,
      status: analytics.inspectionsDue > 0 ? 'warning' : 'success',
    },
    {
      label: 'التنبيهات الحرجة',
      value: analytics.criticalAlerts,
      status: analytics.criticalAlerts > 0 ? 'danger' : 'success',
    },
  ];

  return (
    <DashboardLayout>
      <div className="space-y-4 sm:space-y-6">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">التحليلات</h1>
          <p className="text-sm sm:text-base text-gray-600 mt-2">نظرة شاملة على أداء المناحل والخلايا</p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
          {stats.map((stat) => (
            <Card key={stat.name}>
              <div className="p-4 sm:p-6">
                <div className="flex items-center justify-between mb-3 sm:mb-4">
                  <div className={`flex items-center justify-center w-10 h-10 sm:w-12 sm:h-12 bg-${stat.color}-100 rounded-lg`}>
                    <stat.icon className={`w-5 h-5 sm:w-6 sm:h-6 text-${stat.color}-600`} />
                  </div>
                </div>
                <h3 className="text-2xl sm:text-3xl font-bold text-gray-900 mb-1">{stat.value}</h3>
                <p className="text-xs sm:text-sm text-gray-600">{stat.name}</p>
              </div>
            </Card>
          ))}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          {productionStats.map((stat) => (
            <Card key={stat.label}>
              <div className="p-4 sm:p-6">
                <p className="text-xs sm:text-sm text-gray-600 mb-2">{stat.label}</p>
                <div className="flex items-center gap-2 sm:gap-3">
                  <h3 className="text-xl sm:text-2xl font-bold text-gray-900">{stat.value}</h3>
                  {stat.trend && (
                    <span className={`flex items-center text-xs sm:text-sm font-medium ${
                      stat.trend === 'up' ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {stat.trend === 'up' ? (
                        <TrendingUp className="w-3 h-3 sm:w-4 sm:h-4" />
                      ) : (
                        <TrendingDown className="w-3 h-3 sm:w-4 sm:h-4" />
                      )}
                      {Math.abs(stat.change || 0)}%
                    </span>
                  )}
                </div>
              </div>
            </Card>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
          <Card title="الأداء الشهري">
            <div className="p-4 sm:p-6">
              <div className="space-y-3 sm:space-y-4">
                <div className="flex items-center justify-between">
                  <span className="text-xs sm:text-sm text-gray-600">الإنتاج الكلي</span>
                  <span className="text-sm sm:text-base font-bold text-gray-900">{analytics.monthlyProduction} كجم</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-xs sm:text-sm text-gray-600">متوسط الإنتاج لكل خلية</span>
                  <span className="text-sm sm:text-base font-bold text-gray-900">
                    {analytics.totalHives > 0
                      ? (analytics.monthlyProduction / analytics.totalHives).toFixed(2)
                      : 0} كجم
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-xs sm:text-sm text-gray-600">معدل النشاط</span>
                  <span className="text-sm sm:text-base font-bold text-gray-900">
                    {analytics.totalHives > 0
                      ? ((analytics.activeHives / analytics.totalHives) * 100).toFixed(0)
                      : 0}%
                  </span>
                </div>
              </div>
            </div>
          </Card>

          <Card title="التنبيهات والمتابعة">
            <div className="p-4 sm:p-6">
              <div className="space-y-3 sm:space-y-4">
                <div className={`p-3 sm:p-4 rounded-lg ${
                  analytics.inspectionsDue > 0 ? 'bg-yellow-50' : 'bg-green-50'
                }`}>
                  <div className="flex items-center justify-between">
                    <span className={`text-xs sm:text-sm ${analytics.inspectionsDue > 0 ? 'text-yellow-700' : 'text-green-700'}`}>
                      فحوصات مستحقة
                    </span>
                    <span className="text-sm sm:text-base font-bold">
                      {analytics.inspectionsDue}
                    </span>
                  </div>
                </div>

                <div className={`p-3 sm:p-4 rounded-lg ${
                  analytics.criticalAlerts > 0 ? 'bg-red-50' : 'bg-green-50'
                }`}>
                  <div className="flex items-center justify-between">
                    <span className={`text-xs sm:text-sm ${analytics.criticalAlerts > 0 ? 'text-red-700' : 'text-green-700'}`}>
                      تنبيهات حرجة
                    </span>
                    <span className="text-sm sm:text-base font-bold">
                      {analytics.criticalAlerts}
                    </span>
                  </div>
                </div>

                <div className="p-3 sm:p-4 rounded-lg bg-blue-50">
                  <div className="flex items-center justify-between">
                    <span className="text-xs sm:text-sm text-blue-700">متوسط الصحة العامة</span>
                    <span className="text-sm sm:text-base font-bold">{analytics.averageHiveHealth}%</span>
                  </div>
                </div>
              </div>
            </div>
          </Card>
        </div>

        <Card title="رؤى وتوصيات">
          <div className="p-4 sm:p-6">
            <div className="space-y-3">
              {analytics.activeHives < analytics.totalHives && (
                <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 bg-yellow-50 rounded-lg">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm sm:text-base font-medium text-yellow-900">خلايا غير نشطة</p>
                    <p className="text-xs sm:text-sm text-yellow-700 mt-1">
                      لديك {analytics.totalHives - analytics.activeHives} خلية غير نشطة. يُنصح بفحصها لمعرفة السبب.
                    </p>
                  </div>
                </div>
              )}

              {analytics.averageHiveHealth < 70 && (
                <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 bg-red-50 rounded-lg">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm sm:text-base font-medium text-red-900">انخفاض متوسط الصحة</p>
                    <p className="text-xs sm:text-sm text-red-700 mt-1">
                      متوسط الصحة العامة منخفض. يُنصح بإجراء فحوصات شاملة واتخاذ إجراءات علاجية.
                    </p>
                  </div>
                </div>
              )}

              {analytics.inspectionsDue > 0 && (
                <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 bg-blue-50 rounded-lg">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm sm:text-base font-medium text-blue-900">فحوصات مستحقة</p>
                    <p className="text-xs sm:text-sm text-blue-700 mt-1">
                      يجب إجراء {analytics.inspectionsDue} فحص للحفاظ على صحة الخلايا.
                    </p>
                  </div>
                </div>
              )}

              {analytics.activeHives === analytics.totalHives && analytics.averageHiveHealth >= 70 && analytics.inspectionsDue === 0 && (
                <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 bg-green-50 rounded-lg">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm sm:text-base font-medium text-green-900">أداء ممتاز</p>
                    <p className="text-xs sm:text-sm text-green-700 mt-1">
                      جميع الخلايا نشطة وبصحة جيدة. استمر في المتابعة الدورية للحفاظ على هذا الأداء.
                    </p>
                  </div>
                </div>
              )}
            </div>
          </div>
        </Card>
      </div>
    </DashboardLayout>
  );
}
