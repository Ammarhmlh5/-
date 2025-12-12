import { useState, useEffect } from 'react';
import DashboardLayout from '../components/DashboardLayout';
import Button from '../components/Button';
import Card from '../components/Card';
import Modal from '../components/Modal';
import Input from '../components/Input';
import Select from '../components/Select';
import Badge from '../components/Badge';
import EmptyState from '../components/EmptyState';
import { FileCheck, Plus, Eye, Calendar } from 'lucide-react';
import { inspectionsService } from '../services/inspections';
import { hivesService } from '../services/hives';
import { apiariesService } from '../services/apiaries';
import { useAuth } from '../contexts/AuthContext';
import { Inspection, Hive, Apiary } from '../types';

export default function Inspections() {
  const { user } = useAuth();
  const [inspections, setInspections] = useState<Inspection[]>([]);
  const [hives, setHives] = useState<Hive[]>([]);
  const [apiaries, setApiaries] = useState<Apiary[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [viewModalOpen, setViewModalOpen] = useState(false);
  const [selectedInspection, setSelectedInspection] = useState<Inspection | null>(null);
  const [formData, setFormData] = useState({
    hive_id: '',
    inspection_date: new Date().toISOString().split('T')[0],
    inspector_name: '',
    queen_seen: false,
    eggs_seen: false,
    larvae_seen: false,
    capped_brood_seen: false,
    temperament: 'calm' as 'calm' | 'defensive' | 'aggressive',
    population_estimate: 'medium' as 'weak' | 'medium' | 'strong' | 'very_strong',
    honey_stores: 'medium' as 'none' | 'low' | 'medium' | 'high' | 'full',
    pollen_stores: 'medium' as 'none' | 'low' | 'medium' | 'high',
    diseases_found: '',
    pests_found: '',
    treatments_applied: '',
    feeding_done: false,
    frames_added: '',
    frames_removed: '',
    weather_conditions: '',
    temperature_celsius: '',
    notes: '',
    overall_health: 'good' as 'excellent' | 'good' | 'fair' | 'poor' | 'critical',
  });

  useEffect(() => {
    loadData();
  }, [user]);

  const loadData = async () => {
    if (!user) return;
    try {
      setLoading(true);
      const [inspectionsData, hivesData, apiariesData] = await Promise.all([
        inspectionsService.getAll(),
        hivesService.getAll(),
        apiariesService.getAll(user.id),
      ]);
      setInspections(inspectionsData);
      setHives(hivesData);
      setApiaries(apiariesData);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      const inspectionData = {
        ...formData,
        frames_added: formData.frames_added ? parseInt(formData.frames_added) : undefined,
        frames_removed: formData.frames_removed ? parseInt(formData.frames_removed) : undefined,
        temperature_celsius: formData.temperature_celsius ? parseFloat(formData.temperature_celsius) : undefined,
      };

      await inspectionsService.create(inspectionData);
      await loadData();
      handleCloseModal();
    } catch (error) {
      console.error('Error saving inspection:', error);
    }
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setFormData({
      hive_id: '',
      inspection_date: new Date().toISOString().split('T')[0],
      inspector_name: '',
      queen_seen: false,
      eggs_seen: false,
      larvae_seen: false,
      capped_brood_seen: false,
      temperament: 'calm',
      population_estimate: 'medium',
      honey_stores: 'medium',
      pollen_stores: 'medium',
      diseases_found: '',
      pests_found: '',
      treatments_applied: '',
      feeding_done: false,
      frames_added: '',
      frames_removed: '',
      weather_conditions: '',
      temperature_celsius: '',
      notes: '',
      overall_health: 'good',
    });
  };

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

  const getHiveInfo = (hiveId: string) => {
    const hive = hives.find(h => h.id === hiveId);
    if (!hive) return 'غير محدد';
    const apiary = apiaries.find(a => a.id === hive.apiary_id);
    return `${apiary?.name || 'منحل'} - خلية ${hive.hive_number}`;
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
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">الفحوصات</h1>
            <p className="text-sm sm:text-base text-gray-600 mt-2">سجلات فحص الخلايا</p>
          </div>
          <Button
            icon={<Plus className="w-5 h-5" />}
            onClick={() => setIsModalOpen(true)}
            disabled={hives.length === 0}
            className="w-full sm:w-auto"
          >
            إضافة فحص
          </Button>
        </div>

        {hives.length === 0 ? (
          <Card>
            <EmptyState
              icon={FileCheck}
              title="لا توجد خلايا"
              description="يجب إضافة خلايا أولاً قبل تسجيل الفحوصات"
              action={
                <Button onClick={() => window.history.pushState({}, '', '/hives')}>
                  إضافة خلية
                </Button>
              }
            />
          </Card>
        ) : inspections.length === 0 ? (
          <Card>
            <EmptyState
              icon={FileCheck}
              title="لا توجد فحوصات"
              description="ابدأ بإضافة فحص جديد لتتبع حالة الخلايا"
              action={
                <Button icon={<Plus className="w-5 h-5" />} onClick={() => setIsModalOpen(true)}>
                  إضافة فحص جديد
                </Button>
              }
            />
          </Card>
        ) : (
          <div className="grid grid-cols-1 gap-4">
            {inspections.map((inspection) => (
              <Card key={inspection.id} hoverable>
                <div className="p-4 sm:p-6">
                  <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-0">
                    <div className="flex items-center gap-3 sm:gap-4 min-w-0 flex-1">
                      <div className="w-10 h-10 sm:w-12 sm:h-12 bg-amber-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        <FileCheck className="w-5 h-5 sm:w-6 sm:h-6 text-amber-600" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <h3 className="text-base sm:text-lg font-bold text-gray-900 truncate">
                          {getHiveInfo(inspection.hive_id)}
                        </h3>
                        <div className="flex items-center gap-2 mt-1">
                          <Calendar className="w-3 h-3 sm:w-4 sm:h-4 text-gray-500 flex-shrink-0" />
                          <span className="text-xs sm:text-sm text-gray-600 truncate">
                            {new Date(inspection.inspection_date).toLocaleDateString('ar-SA')}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center justify-between sm:justify-end gap-2 sm:gap-3">
                      {getHealthBadge(inspection.overall_health)}
                      <Button
                        variant="ghost"
                        size="sm"
                        icon={<Eye className="w-4 h-4" />}
                        onClick={() => {
                          setSelectedInspection(inspection);
                          setViewModalOpen(true);
                        }}
                        className="text-xs sm:text-sm"
                      >
                        <span className="hidden sm:inline">التفاصيل</span>
                      </Button>
                    </div>
                  </div>

                  <div className="mt-3 sm:mt-4 grid grid-cols-2 lg:grid-cols-4 gap-2 sm:gap-4">
                    <div className="text-center p-2 sm:p-3 bg-gray-50 rounded-lg">
                      <p className="text-xs text-gray-600 mb-1">الملكة</p>
                      <p className="text-xs sm:text-sm font-semibold text-gray-900">
                        {inspection.queen_seen ? '✓ موجودة' : '✗ غير مرئية'}
                      </p>
                    </div>
                    <div className="text-center p-2 sm:p-3 bg-gray-50 rounded-lg">
                      <p className="text-xs text-gray-600 mb-1">السلوك</p>
                      <p className="text-xs sm:text-sm font-semibold text-gray-900">
                        {inspection.temperament === 'calm' ? 'هادئ' :
                         inspection.temperament === 'defensive' ? 'دفاعي' : 'عدواني'}
                      </p>
                    </div>
                    <div className="text-center p-2 sm:p-3 bg-gray-50 rounded-lg">
                      <p className="text-xs text-gray-600 mb-1">العسل</p>
                      <p className="text-xs sm:text-sm font-semibold text-gray-900">
                        {inspection.honey_stores === 'full' ? 'ممتلئ' :
                         inspection.honey_stores === 'high' ? 'عالي' :
                         inspection.honey_stores === 'medium' ? 'متوسط' : 'منخفض'}
                      </p>
                    </div>
                    <div className="text-center p-3 bg-gray-50 rounded-lg">
                      <p className="text-xs text-gray-600 mb-1">التغذية</p>
                      <p className="font-semibold text-gray-900">
                        {inspection.feeding_done ? '✓ تم' : '✗ لا'}
                      </p>
                    </div>
                  </div>

                  {inspection.notes && (
                    <p className="mt-4 text-sm text-gray-600 line-clamp-2">
                      {inspection.notes}
                    </p>
                  )}
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>

      <Modal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        title="إضافة فحص جديد"
        size="lg"
      >
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <Select
              label="الخلية"
              value={formData.hive_id}
              onChange={(e) => setFormData({ ...formData, hive_id: e.target.value })}
              options={[
                { value: '', label: 'اختر خلية' },
                ...hives.map(h => ({ value: h.id, label: getHiveInfo(h.id) }))
              ]}
              required
            />

            <Input
              label="تاريخ الفحص"
              type="date"
              value={formData.inspection_date}
              onChange={(e) => setFormData({ ...formData, inspection_date: e.target.value })}
              required
            />
          </div>

          <Input
            label="اسم الفاحص"
            value={formData.inspector_name}
            onChange={(e) => setFormData({ ...formData, inspector_name: e.target.value })}
            placeholder="اختياري"
          />

          <div className="border-t pt-4">
            <h4 className="font-semibold text-gray-900 mb-3">معاينة الخلية</h4>
            <div className="grid grid-cols-2 gap-4">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.queen_seen}
                  onChange={(e) => setFormData({ ...formData, queen_seen: e.target.checked })}
                  className="w-4 h-4 text-amber-500 rounded focus:ring-amber-500"
                />
                <span className="text-sm">الملكة موجودة</span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.eggs_seen}
                  onChange={(e) => setFormData({ ...formData, eggs_seen: e.target.checked })}
                  className="w-4 h-4 text-amber-500 rounded focus:ring-amber-500"
                />
                <span className="text-sm">بيض موجود</span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.larvae_seen}
                  onChange={(e) => setFormData({ ...formData, larvae_seen: e.target.checked })}
                  className="w-4 h-4 text-amber-500 rounded focus:ring-amber-500"
                />
                <span className="text-sm">يرقات موجودة</span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.capped_brood_seen}
                  onChange={(e) => setFormData({ ...formData, capped_brood_seen: e.target.checked })}
                  className="w-4 h-4 text-amber-500 rounded focus:ring-amber-500"
                />
                <span className="text-sm">حضنة مغطاة</span>
              </label>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Select
              label="سلوك النحل"
              value={formData.temperament}
              onChange={(e) => setFormData({ ...formData, temperament: e.target.value as any })}
              options={[
                { value: 'calm', label: 'هادئ' },
                { value: 'defensive', label: 'دفاعي' },
                { value: 'aggressive', label: 'عدواني' },
              ]}
            />

            <Select
              label="تقدير العدد"
              value={formData.population_estimate}
              onChange={(e) => setFormData({ ...formData, population_estimate: e.target.value as any })}
              options={[
                { value: 'weak', label: 'ضعيف' },
                { value: 'medium', label: 'متوسط' },
                { value: 'strong', label: 'قوي' },
                { value: 'very_strong', label: 'قوي جداً' },
              ]}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Select
              label="مخزون العسل"
              value={formData.honey_stores}
              onChange={(e) => setFormData({ ...formData, honey_stores: e.target.value as any })}
              options={[
                { value: 'none', label: 'لا يوجد' },
                { value: 'low', label: 'منخفض' },
                { value: 'medium', label: 'متوسط' },
                { value: 'high', label: 'عالي' },
                { value: 'full', label: 'ممتلئ' },
              ]}
            />

            <Select
              label="مخزون حبوب اللقاح"
              value={formData.pollen_stores}
              onChange={(e) => setFormData({ ...formData, pollen_stores: e.target.value as any })}
              options={[
                { value: 'none', label: 'لا يوجد' },
                { value: 'low', label: 'منخفض' },
                { value: 'medium', label: 'متوسط' },
                { value: 'high', label: 'عالي' },
              ]}
            />
          </div>

          <Select
            label="الحالة الصحية العامة"
            value={formData.overall_health}
            onChange={(e) => setFormData({ ...formData, overall_health: e.target.value as any })}
            options={[
              { value: 'excellent', label: 'ممتازة' },
              { value: 'good', label: 'جيدة' },
              { value: 'fair', label: 'متوسطة' },
              { value: 'poor', label: 'ضعيفة' },
              { value: 'critical', label: 'حرجة' },
            ]}
          />

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">
              ملاحظات
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              rows={3}
              className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-transparent"
              placeholder="ملاحظات إضافية..."
            />
          </div>

          <div className="flex gap-3 pt-4">
            <Button type="submit" className="flex-1">
              حفظ الفحص
            </Button>
            <Button type="button" variant="ghost" onClick={handleCloseModal} className="flex-1">
              إلغاء
            </Button>
          </div>
        </form>
      </Modal>

      {selectedInspection && (
        <Modal
          isOpen={viewModalOpen}
          onClose={() => {
            setViewModalOpen(false);
            setSelectedInspection(null);
          }}
          title="تفاصيل الفحص"
          size="lg"
        >
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600">الخلية</p>
                <p className="font-semibold">{getHiveInfo(selectedInspection.hive_id)}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">التاريخ</p>
                <p className="font-semibold">
                  {new Date(selectedInspection.inspection_date).toLocaleDateString('ar-SA')}
                </p>
              </div>
            </div>

            <div className="border-t pt-4">
              <h4 className="font-semibold mb-3">المعاينة</h4>
              <div className="grid grid-cols-2 gap-3">
                <div className="flex items-center gap-2">
                  <span className="text-sm text-gray-600">الملكة:</span>
                  <span className="font-medium">{selectedInspection.queen_seen ? '✓ موجودة' : '✗ غير مرئية'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm text-gray-600">البيض:</span>
                  <span className="font-medium">{selectedInspection.eggs_seen ? '✓ موجود' : '✗ غير مرئي'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm text-gray-600">اليرقات:</span>
                  <span className="font-medium">{selectedInspection.larvae_seen ? '✓ موجودة' : '✗ غير مرئية'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm text-gray-600">الحضنة المغطاة:</span>
                  <span className="font-medium">{selectedInspection.capped_brood_seen ? '✓ موجودة' : '✗ غير مرئية'}</span>
                </div>
              </div>
            </div>

            {selectedInspection.notes && (
              <div className="border-t pt-4">
                <h4 className="font-semibold mb-2">الملاحظات</h4>
                <p className="text-gray-700">{selectedInspection.notes}</p>
              </div>
            )}
          </div>
        </Modal>
      )}
    </DashboardLayout>
  );
}
