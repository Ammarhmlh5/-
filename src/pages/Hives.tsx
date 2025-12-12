import { useState, useEffect } from 'react';
import DashboardLayout from '../components/DashboardLayout';
import Button from '../components/Button';
import Card from '../components/Card';
import Modal from '../components/Modal';
import Input from '../components/Input';
import Select from '../components/Select';
import Badge from '../components/Badge';
import EmptyState from '../components/EmptyState';
import { Box, Plus, Edit2, Trash2, Activity, Calendar } from 'lucide-react';
import { hivesService } from '../services/hives';
import { apiariesService } from '../services/apiaries';
import { useAuth } from '../contexts/AuthContext';
import { Hive, Apiary } from '../types';

export default function Hives() {
  const { user } = useAuth();
  const [hives, setHives] = useState<Hive[]>([]);
  const [apiaries, setApiaries] = useState<Apiary[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingHive, setEditingHive] = useState<Hive | null>(null);
  const [formData, setFormData] = useState({
    apiary_id: '',
    hive_number: '',
    hive_type: 'langstroth',
    queen_age_months: '',
    frame_count: '',
    status: 'active' as 'active' | 'inactive' | 'swarmed' | 'queenless',
    health_status: 'good' as 'excellent' | 'good' | 'fair' | 'poor',
    notes: '',
  });

  useEffect(() => {
    loadData();
  }, [user]);

  const loadData = async () => {
    if (!user) return;
    try {
      setLoading(true);
      const [hivesData, apiariesData] = await Promise.all([
        hivesService.getAll(),
        apiariesService.getAll(user.id),
      ]);
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
      const hiveData = {
        ...formData,
        queen_age_months: formData.queen_age_months ? parseInt(formData.queen_age_months) : undefined,
        frame_count: formData.frame_count ? parseInt(formData.frame_count) : undefined,
      };

      if (editingHive) {
        await hivesService.update(editingHive.id, hiveData);
      } else {
        await hivesService.create(hiveData);
      }

      await loadData();
      handleCloseModal();
    } catch (error) {
      console.error('Error saving hive:', error);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('هل أنت متأكد من حذف هذه الخلية؟')) return;

    try {
      await hivesService.delete(id);
      await loadData();
    } catch (error) {
      console.error('Error deleting hive:', error);
    }
  };

  const handleEdit = (hive: Hive) => {
    setEditingHive(hive);
    setFormData({
      apiary_id: hive.apiary_id,
      hive_number: hive.hive_number,
      hive_type: hive.hive_type,
      queen_age_months: hive.queen_age_months?.toString() || '',
      frame_count: hive.frame_count?.toString() || '',
      status: hive.status,
      health_status: hive.health_status || 'good',
      notes: hive.notes || '',
    });
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingHive(null);
    setFormData({
      apiary_id: '',
      hive_number: '',
      hive_type: 'langstroth',
      queen_age_months: '',
      frame_count: '',
      status: 'active',
      health_status: 'good',
      notes: '',
    });
  };

  const getStatusBadge = (status: string) => {
    const statusMap = {
      active: { variant: 'success' as const, label: 'نشط' },
      inactive: { variant: 'neutral' as const, label: 'غير نشط' },
      swarmed: { variant: 'warning' as const, label: 'تطريد' },
      queenless: { variant: 'danger' as const, label: 'بدون ملكة' },
    };
    const statusInfo = statusMap[status as keyof typeof statusMap] || statusMap.active;
    return <Badge variant={statusInfo.variant}>{statusInfo.label}</Badge>;
  };

  const getHealthBadge = (health?: string) => {
    if (!health) return null;
    const healthMap = {
      excellent: { variant: 'success' as const, label: 'ممتازة' },
      good: { variant: 'info' as const, label: 'جيدة' },
      fair: { variant: 'warning' as const, label: 'متوسطة' },
      poor: { variant: 'danger' as const, label: 'ضعيفة' },
    };
    const healthInfo = healthMap[health as keyof typeof healthMap];
    return <Badge variant={healthInfo.variant}>{healthInfo.label}</Badge>;
  };

  const getApiaryName = (apiaryId: string) => {
    const apiary = apiaries.find(a => a.id === apiaryId);
    return apiary?.name || 'غير محدد';
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
            <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">الخلايا</h1>
            <p className="text-sm sm:text-base text-gray-600 mt-2">إدارة جميع خلايا النحل</p>
          </div>
          <Button
            icon={<Plus className="w-5 h-5" />}
            onClick={() => setIsModalOpen(true)}
            disabled={apiaries.length === 0}
            className="w-full sm:w-auto"
          >
            إضافة خلية
          </Button>
        </div>

        {apiaries.length === 0 ? (
          <Card>
            <EmptyState
              icon={Box}
              title="لا توجد مناحل"
              description="يجب إضافة منحل أولاً قبل إضافة الخلايا"
              action={
                <Button onClick={() => window.history.pushState({}, '', '/apiaries')}>
                  إضافة منحل
                </Button>
              }
            />
          </Card>
        ) : hives.length === 0 ? (
          <Card>
            <EmptyState
              icon={Box}
              title="لا توجد خلايا"
              description="ابدأ بإضافة خلية جديدة لتتبع حالتها وإنتاجها"
              action={
                <Button icon={<Plus className="w-5 h-5" />} onClick={() => setIsModalOpen(true)}>
                  إضافة خلية جديدة
                </Button>
              }
            />
          </Card>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {hives.map((hive) => (
              <Card key={hive.id} hoverable>
                <div className="p-4 sm:p-6">
                  <div className="flex items-start justify-between mb-3 sm:mb-4">
                    <div className="flex items-center gap-2 sm:gap-3 min-w-0 flex-1">
                      <div className="w-10 h-10 sm:w-12 sm:h-12 bg-amber-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        <Box className="w-5 h-5 sm:w-6 sm:h-6 text-amber-600" />
                      </div>
                      <div className="min-w-0">
                        <h3 className="text-base sm:text-lg font-bold text-gray-900 truncate">
                          خلية رقم {hive.hive_number}
                        </h3>
                        <p className="text-xs sm:text-sm text-gray-600 truncate">{getApiaryName(hive.apiary_id)}</p>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-2 mb-3 sm:mb-4">
                    <div className="flex flex-wrap items-center gap-2">
                      {getStatusBadge(hive.status)}
                      {getHealthBadge(hive.health_status)}
                    </div>
                    <div className="flex items-center gap-2 text-gray-600">
                      <Activity className="w-4 h-4 flex-shrink-0" />
                      <span className="text-xs sm:text-sm truncate">
                        {hive.frame_count || 0} إطار - {hive.hive_type}
                      </span>
                    </div>
                    {hive.last_inspection_date && (
                      <div className="flex items-center gap-2 text-gray-600">
                        <Calendar className="w-4 h-4 flex-shrink-0" />
                        <span className="text-xs sm:text-sm truncate">
                          آخر فحص: {new Date(hive.last_inspection_date).toLocaleDateString('ar-SA')}
                        </span>
                      </div>
                    )}
                  </div>

                  {hive.notes && (
                    <p className="text-xs sm:text-sm text-gray-600 mb-3 sm:mb-4 line-clamp-2">
                      {hive.notes}
                    </p>
                  )}

                  <div className="flex gap-2 pt-3 sm:pt-4 border-t border-gray-200">
                    <Button
                      variant="ghost"
                      size="sm"
                      icon={<Edit2 className="w-4 h-4" />}
                      onClick={() => handleEdit(hive)}
                      className="flex-1 text-xs sm:text-sm"
                    >
                      تعديل
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      icon={<Trash2 className="w-4 h-4" />}
                      onClick={() => handleDelete(hive.id)}
                      className="flex-1 text-red-600 hover:bg-red-50 text-xs sm:text-sm"
                    >
                      حذف
                    </Button>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>

      <Modal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        title={editingHive ? 'تعديل خلية' : 'إضافة خلية جديدة'}
        size="md"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <Select
            label="المنحل"
            value={formData.apiary_id}
            onChange={(e) => setFormData({ ...formData, apiary_id: e.target.value })}
            options={[
              { value: '', label: 'اختر منحل' },
              ...apiaries.map(a => ({ value: a.id, label: a.name }))
            ]}
            required
          />

          <Input
            label="رقم الخلية"
            value={formData.hive_number}
            onChange={(e) => setFormData({ ...formData, hive_number: e.target.value })}
            required
            placeholder="مثال: 1 أو A-1"
          />

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select
              label="نوع الخلية"
              value={formData.hive_type}
              onChange={(e) => setFormData({ ...formData, hive_type: e.target.value })}
              options={[
                { value: 'langstroth', label: 'لانجستروث' },
                { value: 'top_bar', label: 'شريط علوي' },
                { value: 'warre', label: 'واري' },
                { value: 'traditional', label: 'تقليدية' },
              ]}
            />

            <Input
              label="عدد الإطارات"
              type="number"
              value={formData.frame_count}
              onChange={(e) => setFormData({ ...formData, frame_count: e.target.value })}
              placeholder="10"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select
              label="حالة الخلية"
              value={formData.status}
              onChange={(e) => setFormData({ ...formData, status: e.target.value as any })}
              options={[
                { value: 'active', label: 'نشطة' },
                { value: 'inactive', label: 'غير نشطة' },
                { value: 'swarmed', label: 'تطريد' },
                { value: 'queenless', label: 'بدون ملكة' },
              ]}
            />

            <Select
              label="الحالة الصحية"
              value={formData.health_status}
              onChange={(e) => setFormData({ ...formData, health_status: e.target.value as any })}
              options={[
                { value: 'excellent', label: 'ممتازة' },
                { value: 'good', label: 'جيدة' },
                { value: 'fair', label: 'متوسطة' },
                { value: 'poor', label: 'ضعيفة' },
              ]}
            />
          </div>

          <Input
            label="عمر الملكة (بالأشهر)"
            type="number"
            value={formData.queen_age_months}
            onChange={(e) => setFormData({ ...formData, queen_age_months: e.target.value })}
            placeholder="12"
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

          <div className="flex flex-col-reverse sm:flex-row gap-3 pt-4">
            <Button type="button" variant="ghost" onClick={handleCloseModal} className="flex-1">
              إلغاء
            </Button>
            <Button type="submit" className="flex-1">
              {editingHive ? 'حفظ التعديلات' : 'إضافة خلية'}
            </Button>
          </div>
        </form>
      </Modal>
    </DashboardLayout>
  );
}
