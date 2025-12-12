import { useState, useEffect } from 'react';
import DashboardLayout from '../components/DashboardLayout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import EmptyState from '../components/EmptyState';
import Input from '../components/Input';
import { Flower2, Search } from 'lucide-react';
import { floraService } from '../services/flora';
import { Flora } from '../types';

export default function FloraLibrary() {
  const [floraList, setFloraList] = useState<Flora[]>([]);
  const [filteredFlora, setFilteredFlora] = useState<Flora[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadFlora();
  }, []);

  useEffect(() => {
    if (searchTerm) {
      const filtered = floraList.filter(flora =>
        flora.common_name_ar.includes(searchTerm) ||
        flora.common_name_en?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        flora.scientific_name?.toLowerCase().includes(searchTerm.toLowerCase())
      );
      setFilteredFlora(filtered);
    } else {
      setFilteredFlora(floraList);
    }
  }, [searchTerm, floraList]);

  const loadFlora = async () => {
    try {
      setLoading(true);
      const data = await floraService.getAll();
      setFloraList(data);
      setFilteredFlora(data);
    } catch (error) {
      console.error('Error loading flora:', error);
    } finally {
      setLoading(false);
    }
  };

  const getQualityBadge = (quality: string) => {
    const qualityMap = {
      excellent: { variant: 'success' as const, label: 'ممتاز' },
      good: { variant: 'info' as const, label: 'جيد' },
      fair: { variant: 'warning' as const, label: 'متوسط' },
      poor: { variant: 'neutral' as const, label: 'ضعيف' },
    };
    const qualityInfo = qualityMap[quality as keyof typeof qualityMap];
    return <Badge variant={qualityInfo.variant}>{qualityInfo.label}</Badge>;
  };

  const getMonthName = (month: number) => {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1] || '';
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

  return (
    <DashboardLayout>
      <div className="space-y-4 sm:space-y-6">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">مكتبة النباتات</h1>
          <p className="text-sm sm:text-base text-gray-600 mt-2">دليل النباتات المفيدة لنحل العسل</p>
        </div>

        <div className="max-w-2xl relative">
          <Input
            placeholder="ابحث عن نبات..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pr-10"
          />
          <Search className="absolute left-4 top-3 w-4 h-4 sm:w-5 sm:h-5 text-gray-400 pointer-events-none" />
        </div>

        {filteredFlora.length === 0 ? (
          <Card>
            <EmptyState
              icon={Flower2}
              title="لا توجد نباتات"
              description={searchTerm ? 'لم يتم العثور على نتائج للبحث' : 'لا توجد نباتات في المكتبة'}
            />
          </Card>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {filteredFlora.map((flora) => (
              <Card key={flora.id} hoverable>
                <div className="p-4 sm:p-6">
                  <div className="flex items-start gap-2 sm:gap-3 mb-3 sm:mb-4">
                    <div className="w-10 h-10 sm:w-12 sm:h-12 bg-green-100 rounded-lg flex items-center justify-center flex-shrink-0">
                      <Flower2 className="w-5 h-5 sm:w-6 sm:h-6 text-green-600" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="text-base sm:text-lg font-bold text-gray-900 truncate">
                        {flora.common_name_ar}
                      </h3>
                      {flora.common_name_en && (
                        <p className="text-xs sm:text-sm text-gray-600 truncate">{flora.common_name_en}</p>
                      )}
                      {flora.scientific_name && (
                        <p className="text-xs text-gray-500 italic truncate mt-1">
                          {flora.scientific_name}
                        </p>
                      )}
                    </div>
                  </div>

                  {flora.description_ar && (
                    <p className="text-xs sm:text-sm text-gray-600 mb-3 sm:mb-4 line-clamp-3">
                      {flora.description_ar}
                    </p>
                  )}

                  <div className="space-y-2 sm:space-y-3">
                    <div>
                      <p className="text-xs text-gray-500 mb-1">جودة الرحيق</p>
                      {getQualityBadge(flora.nectar_quality)}
                    </div>

                    <div>
                      <p className="text-xs text-gray-500 mb-1">جودة حبوب اللقاح</p>
                      {getQualityBadge(flora.pollen_quality)}
                    </div>

                    {flora.bloom_season_start && flora.bloom_season_end && (
                      <div>
                        <p className="text-xs text-gray-500 mb-1">موسم الإزهار</p>
                        <p className="text-xs sm:text-sm font-medium text-gray-900">
                          {getMonthName(flora.bloom_season_start)} - {getMonthName(flora.bloom_season_end)}
                        </p>
                      </div>
                    )}

                    {flora.region && (
                      <div>
                        <p className="text-xs text-gray-500 mb-1">المنطقة</p>
                        <p className="text-xs sm:text-sm font-medium text-gray-900 truncate">{flora.region}</p>
                      </div>
                    )}
                  </div>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
