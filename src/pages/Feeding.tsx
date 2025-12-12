import { useState, useEffect } from 'react';
import DashboardLayout from '../components/DashboardLayout';
import Button from '../components/Button';
import Card from '../components/Card';
import Modal from '../components/Modal';
import Input from '../components/Input';
import Select from '../components/Select';
import Badge from '../components/Badge';
import EmptyState from '../components/EmptyState';
import { Coffee, Plus, Edit2, Trash2, Calendar, Droplets } from 'lucide-react';
import { feedingService } from '../services/feeding';
import { hivesService } from '../services/hives';
import { apiariesService } from '../services/apiaries';
import { useAuth } from '../contexts/AuthContext';
import { Feeding, Hive } from '../types';

export default function FeedingPage() {
  const { user } = useAuth();
  const [feedings, setFeedings] = useState<Feeding[]>([]);
  const [hives, setHives] = useState<Hive[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingFeeding, setEditingFeeding] = useState<Feeding | null>(null);
  const [formData, setFormData] = useState({
    hive_id: '',
    feeding_type: 'syrup' as 'syrup' | 'pollen_sub' | 'protein' | 'vitamins' | 'candy',
    amount: '',
    unit: 'ml',
    feeding_date: new Date().toISOString().split('T')[0],
    reason: '',
    notes: '',
  });

  useEffect(() => {
    loadData();
  }, [user]);

  const loadData = async () => {
    if (!user) return;
    try {
      setLoading(true);
      const [feedingsData, apiariesData] = await Promise.all([
        feedingService.getAll(user.id),
        apiariesService.getAll(user.id),
      ]);

      const allHives: Hive[] = [];
      for (const apiary of apiariesData) {
        const apiaryHives = await hivesService.getAll(apiary.apiary_id);
        allHives.push(...apiaryHives);
      }

      setFeedings(feedingsData);
      setHives(allHives);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    try {
      const feedingData = {
        hive_id: formData.hive_id,
        feeding_type: formData.feeding_type,
        amount: formData.amount ? parseFloat(formData.amount) : undefined,
        unit: formData.unit,
        feeding_date: new Date(formData.feeding_date).toISOString(),
        reason: formData.reason || undefined,
        notes: formData.notes || undefined,
      };

      if (editingFeeding) {
        await feedingService.update(editingFeeding.feeding_id, feedingData);
      } else {
        await feedingService.create(feedingData);
      }

      await loadData();
      handleCloseModal();
    } catch (error) {
      console.error('Error saving feeding:', error);
      alert('حدث خطأ أثناء حفظ التغذية. يرجى المحاولة مرة أخرى.');
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('هل أنت متأكد من حذف هذا السجل؟')) return;

    try {
      await feedingService.delete(id);
      await loadData();
    } catch (error) {
      console.error('Error deleting feeding:', error);
      alert('حدث خطأ أثناء حذف السجل. يرجى المحاولة مرة أخرى.');
    }
  };

  const handleEdit = (feeding: Feeding) => {
    setEditingFeeding(feeding);
    setFormData({
      hive_id: feeding.hive_id,
      feeding_type: feeding.feeding_type,
      amount: feeding.amount?.toString() || '',
      unit: feeding.unit || 'ml',
      feeding_date: feeding.feeding_date.split('T')[0],
      reason: feeding.reason || '',
      notes: feeding.notes || '',
    });
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingFeeding(null);
    setFormData({
      hive_id: '',
      feeding_type: 'syrup',
      amount: '',
      unit: 'ml',
      feeding_date: new Date().toISOString().split('T')[0],
      reason: '',
      notes: '',
    });
  };

  const getFeedingTypeBadge = (type: string) => {
    const typeMap = {
      syrup: { variant: 'info' as const, label: 'محلول سكري' },
      pollen_sub: { variant: 'warning' as const, label: 'بديل حبوب لقاح' },
      protein: { variant: 'success' as const, label: 'بروتين' },
      vitamins: { variant: 'neutral' as const, label: 'فيتامينات' },
      candy: { variant: 'info' as const, label: 'كاندي' },
    };
    const typeInfo = typeMap[type as keyof typeof typeMap];
    return <Badge variant={typeInfo.variant}>{typeInfo.label}</Badge>;
  };

  const getHiveName = (hiveId: string) => {
    const hive = hives.find((h) => h.hive_id === hiveId);
    return hive ? hive.hive_number : 'غير معروف';
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('ar-SA', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
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
            <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">سجلات التغذية</h1>
            <p className="text-sm sm:text-base text-gray-600 mt-2">تتبع وإدارة تغذية خلايا النحل</p>
          </div>
          <Button icon={<Plus className="w-5 h-5" />} onClick={() => setIsModalOpen(true)} className="w-full sm:w-auto">
            إضافة تغذية
          </Button>
        </div>

        {feedings.length === 0 ? (
          <Card>
            <EmptyState
              icon={Coffee}
              title="لا توجد سجلات تغذية"
              description="ابدأ بإضافة سجل تغذية جديد لتتبع تغذية خلايا النحل"
              action={
                <Button icon={<Plus className="w-5 h-5" />} onClick={() => setIsModalOpen(true)}>
                  إضافة سجل تغذية
                </Button>
              }
            />
          </Card>
        ) : (
          <div className="grid grid-cols-1 gap-4">
            {feedings.map((feeding) => (
              <Card key={feeding.feeding_id} hoverable>
                <div className="p-4 sm:p-6">
                  <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 sm:gap-4">
                    <div className="flex items-start gap-3 sm:gap-4 flex-1 min-w-0">
                      <div className="w-10 h-10 sm:w-12 sm:h-12 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        <Coffee className="w-5 h-5 sm:w-6 sm:h-6 text-blue-600" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex flex-wrap items-center gap-2 sm:gap-3 mb-2">
                          <h3 className="text-base sm:text-lg font-bold text-gray-900 truncate">
                            خلية {getHiveName(feeding.hive_id)}
                          </h3>
                          {getFeedingTypeBadge(feeding.feeding_type)}
                        </div>
                        <div className="flex flex-wrap items-center gap-3 sm:gap-6 text-xs sm:text-sm text-gray-600">
                          <div className="flex items-center gap-2">
                            <Calendar className="w-3 h-3 sm:w-4 sm:h-4 flex-shrink-0" />
                            <span className="truncate">{formatDate(feeding.feeding_date)}</span>
                          </div>
                          {feeding.amount && (
                            <div className="flex items-center gap-2">
                              <Droplets className="w-3 h-3 sm:w-4 sm:h-4 flex-shrink-0" />
                              <span>
                                {feeding.amount} {feeding.unit}
                              </span>
                            </div>
                          )}
                        </div>
                        {feeding.reason && (
                          <p className="text-xs sm:text-sm text-gray-600 mt-2 line-clamp-2">
                            <span className="font-medium">السبب:</span> {feeding.reason}
                          </p>
                        )}
                        {feeding.notes && (
                          <p className="text-xs sm:text-sm text-gray-500 mt-1 line-clamp-2">{feeding.notes}</p>
                        )}
                      </div>
                    </div>
                    <div className="flex gap-2 sm:flex-col sm:gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        icon={<Edit2 className="w-4 h-4" />}
                        onClick={() => handleEdit(feeding)}
                        className="flex-1 sm:flex-none text-xs sm:text-sm"
                      >
                        <span className="hidden sm:inline">تعديل</span>
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        icon={<Trash2 className="w-4 h-4" />}
                        onClick={() => handleDelete(feeding.feeding_id)}
                        className="flex-1 sm:flex-none text-red-600 hover:bg-red-50 text-xs sm:text-sm"
                      >
                        حذف
                      </Button>
                    </div>
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
        title={editingFeeding ? 'تعديل سجل التغذية' : 'إضافة سجل تغذية جديد'}
        size="md"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <Select
            label="الخلية"
            value={formData.hive_id}
            onChange={(e) => setFormData({ ...formData, hive_id: e.target.value })}
            required
            options={[
              { value: '', label: 'اختر الخلية' },
              ...hives.map((hive) => ({
                value: hive.hive_id,
                label: `خلية ${hive.hive_number}`,
              })),
            ]}
          />

          <Select
            label="نوع التغذية"
            value={formData.feeding_type}
            onChange={(e) => setFormData({ ...formData, feeding_type: e.target.value as any })}
            required
            options={[
              { value: 'syrup', label: 'محلول سكري' },
              { value: 'pollen_sub', label: 'بديل حبوب لقاح' },
              { value: 'protein', label: 'بروتين' },
              { value: 'vitamins', label: 'فيتامينات' },
              { value: 'candy', label: 'كاندي' },
            ]}
          />

          <div className="grid grid-cols-2 gap-4">
            <Input
              label="الكمية"
              type="number"
              step="any"
              value={formData.amount}
              onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
              placeholder="1000"
            />

            <Select
              label="الوحدة"
              value={formData.unit}
              onChange={(e) => setFormData({ ...formData, unit: e.target.value })}
              options={[
                { value: 'ml', label: 'مل' },
                { value: 'l', label: 'لتر' },
                { value: 'g', label: 'جرام' },
                { value: 'kg', label: 'كيلوجرام' },
              ]}
            />
          </div>

          <Input
            label="تاريخ التغذية"
            type="date"
            value={formData.feeding_date}
            onChange={(e) => setFormData({ ...formData, feeding_date: e.target.value })}
            required
          />

          <Input
            label="السبب"
            value={formData.reason}
            onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
            placeholder="مثال: نقص في المخزون الغذائي"
          />

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">ملاحظات</label>
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
              {editingFeeding ? 'حفظ التعديلات' : 'إضافة سجل'}
            </Button>
            <Button type="button" variant="ghost" onClick={handleCloseModal} className="flex-1">
              إلغاء
            </Button>
          </div>
        </form>
      </Modal>
    </DashboardLayout>
  );
}
