import { useState, useEffect } from 'react';
import DashboardLayout from '../components/DashboardLayout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import Button from '../components/Button';
import { TrendingUp, TrendingDown, Hexagon, AlertCircle, Map, Box, Activity } from 'lucide-react';
import { analyticsService } from '../services/analytics';
import { inspectionsService } from '../services/inspections';
import { hivesService } from '../services/hives';
import { apiariesService } from '../services/apiaries';
import { useAuth } from '../contexts/AuthContext';
import { Analytics, Inspection, Hive, Apiary } from '../types';

export default function Dashboard() {
  const { user } = useAuth();
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [recentInspections, setRecentInspections] = useState<(Inspection & { hive?: Hive; apiary?: Apiary })[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, [user]);

  const loadDashboardData = async () => {
    if (!user) return;
    try {
      setLoading(true);
      const [analyticsData, inspections] = await Promise.all([
        analyticsService.getDashboardStats(user.id),
        inspectionsService.getAll(),
      ]);

      setAnalytics(analyticsData);

      const inspectionsWithDetails = await Promise.all(
        inspections.slice(0, 3).map(async (inspection) => {
          const hive = await hivesService.getById(inspection.hive_id);
          let apiary;
          if (hive) {
            apiary = await apiariesService.getById(hive.apiary_id);
          }
          return { ...inspection, hive, apiary };
        })
      );

      setRecentInspections(inspectionsWithDetails);
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading || !analytics) {
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

  const stats = [
    {
      name: 'إجمالي المناحل',
      value: analytics.totalApiaries,
      icon: Map,
      link: '/apiaries',
    },
    {
      name: 'إجمالي الخلايا',
      value: analytics.totalHives,
      icon: Box,
      link: '/hives',
    },
    {
      name: 'الخلايا النشطة',
      value: analytics.activeHives,
      change: analytics.totalHives > 0 ? `${Math.round((analytics.activeHives / analytics.totalHives) * 100)}%` : '0%',
      trend: analytics.activeHives === analytics.totalHives ? 'up' : 'down',
      icon: Activity,
    },
    {
      name: 'الإنتاج الشهري',
      value: `${analytics.monthlyProduction} كجم`,
      change: analytics.productionChange > 0 ? `+${analytics.productionChange}%` : `${analytics.productionChange}%`,
      trend: analytics.productionChange >= 0 ? 'up' : 'down',
      icon: Hexagon,
    },
  ];

  const getHealthBadge = (health: string) => {
    const healthMap = {
      excellent: { variant: 'success' as const, label: 'ممتازة' },
      good: { variant: 'info' as const, label: 'جيدة' },
      fair: { variant: 'warning' as const, label: 'متوسطة' },
      poor: { variant: 'danger' as const, label: 'ضعيفة' },
      critical: { variant: 'danger' as const, label: 'حرجة' },
    };
    const healthInfo = healthMap[health as keyof typeof healthMap];
    return <Badge variant={healthInfo.variant}>{healthInfo.label}</Badge>;
  };

  const getTimeAgo = (date: string) => {
    const now = new Date();
    const inspectionDate = new Date(date);
    const diffInHours = Math.floor((now.getTime() - inspectionDate.getTime()) / (1000 * 60 * 60));

    if (diffInHours < 24) {
      return `منذ ${diffInHours} ساعة`;
    }
    const diffInDays = Math.floor(diffInHours / 24);
    return `منذ ${diffInDays} ${diffInDays === 1 ? 'يوم' : 'أيام'}`;
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">لوحة التحكم</h1>
          <p className="text-sm sm:text-base text-gray-600 mt-2">نظرة عامة على مناحلك وخلاياك</p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
          {stats.map((stat) => (
            <Card
              key={stat.name}
              hoverable={!!stat.link}
              onClick={() => stat.link && window.history.pushState({}, '', stat.link)}
            >
              <div className="p-4 sm:p-6">
                <div className="flex items-center justify-between mb-3 sm:mb-4">
                  <div className="flex items-center justify-center w-10 h-10 sm:w-12 sm:h-12 bg-amber-100 rounded-lg">
                    <stat.icon className="w-5 h-5 sm:w-6 sm:h-6 text-amber-600" />
                  </div>
                  {stat.change && (
                    <span
                      className={`flex items-center gap-1 text-xs sm:text-sm font-medium ${
                        stat.trend === 'up' ? 'text-green-600' : 'text-red-600'
                      }`}
                    >
                      {stat.trend === 'up' ? (
                        <TrendingUp className="w-3 h-3 sm:w-4 sm:h-4" />
                      ) : (
                        <TrendingDown className="w-3 h-3 sm:w-4 sm:h-4" />
                      )}
                      {stat.change}
                    </span>
                  )}
                </div>
                <h3 className="text-xl sm:text-2xl font-bold text-gray-900">{stat.value}</h3>
                <p className="text-xs sm:text-sm text-gray-600 mt-1">{stat.name}</p>
              </div>
            </Card>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
          <Card title="آخر الفحوصات">
            <div className="p-4 sm:p-6">
              {recentInspections.length === 0 ? (
                <div className="text-center py-6 sm:py-8">
                  <p className="text-sm sm:text-base text-gray-500">لا توجد فحوصات مسجلة</p>
                  <Button
                    size="sm"
                    className="mt-4"
                    onClick={() => window.history.pushState({}, '', '/inspections')}
                  >
                    إضافة فحص
                  </Button>
                </div>
              ) : (
                <div className="space-y-3 sm:space-y-4">
                  {recentInspections.map((inspection) => (
                    <div key={inspection.id} className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 sm:gap-0 p-3 sm:p-4 bg-gray-50 rounded-lg">
                      <div className="min-w-0">
                        <p className="font-medium text-sm sm:text-base text-gray-900 truncate">
                          خلية {inspection.hive?.hive_number || 'غير محددة'}
                        </p>
                        <p className="text-xs sm:text-sm text-gray-600 truncate">
                          {inspection.apiary?.name || 'منحل غير محدد'}
                        </p>
                      </div>
                      <div className="flex items-center justify-between sm:block sm:text-left">
                        {getHealthBadge(inspection.overall_health)}
                        <p className="text-xs text-gray-500 sm:mt-1">
                          {getTimeAgo(inspection.inspection_date)}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </Card>

          <Card title="التنبيهات والتوصيات">
            <div className="p-4 sm:p-6">
              <div className="space-y-3 sm:space-y-4">
                {analytics.inspectionsDue > 0 && (
                  <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 rounded-lg bg-yellow-50 border border-yellow-200">
                    <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 mt-0.5 text-yellow-600 flex-shrink-0" />
                    <div className="min-w-0">
                      <p className="font-medium text-sm sm:text-base text-gray-900">فحوصات مستحقة</p>
                      <p className="text-xs sm:text-sm text-gray-600">
                        {analytics.inspectionsDue} خلية تحتاج إلى فحص دوري
                      </p>
                    </div>
                  </div>
                )}

                {analytics.criticalAlerts > 0 && (
                  <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 rounded-lg bg-red-50 border border-red-200">
                    <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 mt-0.5 text-red-600 flex-shrink-0" />
                    <div className="min-w-0">
                      <p className="font-medium text-sm sm:text-base text-gray-900">تنبيهات حرجة</p>
                      <p className="text-xs sm:text-sm text-gray-600">
                        {analytics.criticalAlerts} تنبيه يتطلب اهتماماً فورياً
                      </p>
                    </div>
                  </div>
                )}

                {analytics.averageHiveHealth >= 70 && analytics.activeHives === analytics.totalHives && (
                  <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 rounded-lg bg-green-50 border border-green-200">
                    <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 mt-0.5 text-green-600 flex-shrink-0" />
                    <div className="min-w-0">
                      <p className="font-medium text-sm sm:text-base text-gray-900">أداء ممتاز</p>
                      <p className="text-xs sm:text-sm text-gray-600">
                        جميع الخلايا في حالة جيدة. استمر في الرعاية الدورية
                      </p>
                    </div>
                  </div>
                )}

                {analytics.monthlyProduction > 0 && (
                  <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 rounded-lg bg-blue-50 border border-blue-200">
                    <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 mt-0.5 text-blue-600 flex-shrink-0" />
                    <div className="min-w-0">
                      <p className="font-medium text-sm sm:text-base text-gray-900">إنتاج جيد</p>
                      <p className="text-xs sm:text-sm text-gray-600">
                        الإنتاج الشهري: {analytics.monthlyProduction} كجم من العسل
                      </p>
                    </div>
                  </div>
                )}

                {analytics.totalApiaries === 0 && (
                  <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 rounded-lg bg-gray-50 border border-gray-200">
                    <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 mt-0.5 text-gray-600 flex-shrink-0" />
                    <div className="min-w-0">
                      <p className="font-medium text-sm sm:text-base text-gray-900">ابدأ رحلتك</p>
                      <p className="text-xs sm:text-sm text-gray-600">
                        أضف منحلك الأول لبدء تتبع الخلايا والإنتاج
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </Card>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          <Card>
            <div className="p-4 sm:p-6 text-center">
              <div className="w-10 h-10 sm:w-12 sm:h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2 sm:mb-3">
                <Activity className="w-5 h-5 sm:w-6 sm:h-6 text-green-600" />
              </div>
              <p className="text-2xl sm:text-3xl font-bold text-gray-900 mb-1">{analytics.averageHiveHealth}%</p>
              <p className="text-xs sm:text-sm text-gray-600">متوسط الصحة العامة</p>
            </div>
          </Card>

          <Card>
            <div className="p-4 sm:p-6 text-center">
              <div className="w-10 h-10 sm:w-12 sm:h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2 sm:mb-3">
                <Box className="w-5 h-5 sm:w-6 sm:h-6 text-blue-600" />
              </div>
              <p className="text-2xl sm:text-3xl font-bold text-gray-900 mb-1">
                {analytics.totalHives > 0 ? (analytics.monthlyProduction / analytics.totalHives).toFixed(1) : 0}
              </p>
              <p className="text-xs sm:text-sm text-gray-600">متوسط إنتاج الخلية (كجم)</p>
            </div>
          </Card>

          <Card>
            <div className="p-4 sm:p-6 text-center">
              <div className="w-10 h-10 sm:w-12 sm:h-12 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-2 sm:mb-3">
                <Map className="w-5 h-5 sm:w-6 sm:h-6 text-amber-600" />
              </div>
              <p className="text-2xl sm:text-3xl font-bold text-gray-900 mb-1">
                {analytics.totalApiaries > 0 ? Math.round(analytics.totalHives / analytics.totalApiaries) : 0}
              </p>
              <p className="text-xs sm:text-sm text-gray-600">متوسط خلايا المنحل</p>
            </div>
          </Card>
        </div>
      </div>
    </DashboardLayout>
  );
}
