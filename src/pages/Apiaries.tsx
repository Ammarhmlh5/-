import { useState, useEffect } from 'react';
import DashboardLayout from '../components/DashboardLayout';
import Button from '../components/Button';
import Card from '../components/Card';
import Modal from '../components/Modal';
import Input from '../components/Input';
import Select from '../components/Select';
import Badge from '../components/Badge';
import EmptyState from '../components/EmptyState';
import { Map, Plus, Edit2, Trash2, Box, MapPin } from 'lucide-react';
import { apiariesService } from '../services/apiaries';
import { useAuth } from '../contexts/AuthContext';
import { Apiary } from '../types';

export default function Apiaries() {
  const { user } = useAuth();
  const [apiaries, setApiaries] = useState<Apiary[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingApiary, setEditingApiary] = useState<Apiary | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    region: '',
    latitude: '',
    longitude: '',
    altitude: '',
    description: '',
    type: 'fixed' as 'fixed' | 'mobile',
  });

  useEffect(() => {
    loadApiaries();
  }, [user]);

  const loadApiaries = async () => {
    if (!user) return;
    try {
      setLoading(true);
      const data = await apiariesService.getAll(user.id);
      setApiaries(data);
    } catch (error) {
      console.error('Error loading apiaries:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    try {
      const apiaryData = {
        name: formData.name,
        region: formData.region,
        description: formData.description,
        type: formData.type,
        owner_id: user.id,
        latitude: formData.latitude ? parseFloat(formData.latitude) : undefined,
        longitude: formData.longitude ? parseFloat(formData.longitude) : undefined,
        altitude: formData.altitude ? parseFloat(formData.altitude) : undefined,
      };

      if (editingApiary) {
        await apiariesService.update(editingApiary.apiary_id, apiaryData);
      } else {
        await apiariesService.create(apiaryData);
      }

      await loadApiaries();
      handleCloseModal();
    } catch (error) {
      console.error('Error saving apiary:', error);
      alert('حدث خطأ أثناء حفظ المنحل. يرجى المحاولة مرة أخرى.');
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('هل أنت متأكد من حذف هذا المنحل؟')) return;

    try {
      await apiariesService.delete(id);
      await loadApiaries();
    } catch (error) {
      console.error('Error deleting apiary:', error);
      alert('حدث خطأ أثناء حذف المنحل. يرجى المحاولة مرة أخرى.');
    }
  };

  const handleEdit = (apiary: Apiary) => {
    setEditingApiary(apiary);
    setFormData({
      name: apiary.name,
      region: apiary.region || '',
      latitude: apiary.latitude?.toString() || '',
      longitude: apiary.longitude?.toString() || '',
      altitude: apiary.altitude?.toString() || '',
      description: apiary.description || '',
      type: apiary.type,
    });
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingApiary(null);
    setFormData({
      name: '',
      region: '',
      latitude: '',
      longitude: '',
      altitude: '',
      description: '',
      type: 'fixed',
    });
  };

  const getTypeBadge = (type: string) => {
    const typeMap = {
      fixed: { variant: 'success' as const, label: 'ثابت' },
      mobile: { variant: 'info' as const, label: 'متنقل' },
    };
    const typeInfo = typeMap[type as keyof typeof typeMap];
    return <Badge variant={typeInfo.variant}>{typeInfo.label}</Badge>;
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
            <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">المناحل</h1>
            <p className="text-sm sm:text-base text-gray-600 mt-2">إدارة جميع المناحل الخاصة بك</p>
          </div>
          <Button icon={<Plus className="w-5 h-5" />} onClick={() => setIsModalOpen(true)} className="w-full sm:w-auto">
            إضافة منحل
          </Button>
        </div>

        {apiaries.length === 0 ? (
          <Card>
            <EmptyState
              icon={Map}
              title="لا توجد مناحل"
              description="ابدأ بإضافة منحل جديد لتتبع خلايا النحل الخاصة بك"
              action={
                <Button icon={<Plus className="w-5 h-5" />} onClick={() => setIsModalOpen(true)}>
                  إضافة منحل جديد
                </Button>
              }
            />
          </Card>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {apiaries.map((apiary) => (
              <Card key={apiary.apiary_id} hoverable>
                <div className="p-4 sm:p-6">
                  <div className="flex items-start justify-between mb-3 sm:mb-4">
                    <div className="flex items-center gap-2 sm:gap-3 min-w-0 flex-1">
                      <div className="w-10 h-10 sm:w-12 sm:h-12 bg-amber-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        <Map className="w-5 h-5 sm:w-6 sm:h-6 text-amber-600" />
                      </div>
                      <div className="min-w-0">
                        <h3 className="text-base sm:text-lg font-bold text-gray-900 truncate">{apiary.name}</h3>
                        {getTypeBadge(apiary.type)}
                      </div>
                    </div>
                  </div>

                  <div className="space-y-2 sm:space-y-3 mb-3 sm:mb-4">
                    {apiary.region && (
                      <div className="flex items-center gap-2 text-gray-600">
                        <MapPin className="w-4 h-4 flex-shrink-0" />
                        <span className="text-xs sm:text-sm truncate">{apiary.region}</span>
                      </div>
                    )}
                    <div className="flex items-center gap-2 text-gray-600">
                      <Box className="w-4 h-4 flex-shrink-0" />
                      <span className="text-xs sm:text-sm">{apiary.hive_count || 0} خلية</span>
                    </div>
                  </div>

                  {apiary.description && (
                    <p className="text-xs sm:text-sm text-gray-600 mb-3 sm:mb-4 line-clamp-2">
                      {apiary.description}
                    </p>
                  )}

                  <div className="flex gap-2 pt-3 sm:pt-4 border-t border-gray-200">
                    <Button
                      variant="ghost"
                      size="sm"
                      icon={<Edit2 className="w-4 h-4" />}
                      onClick={() => handleEdit(apiary)}
                      className="flex-1 text-xs sm:text-sm"
                    >
                      تعديل
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      icon={<Trash2 className="w-4 h-4" />}
                      onClick={() => handleDelete(apiary.apiary_id)}
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
        title={editingApiary ? 'تعديل منحل' : 'إضافة منحل جديد'}
        size="md"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="اسم المنحل"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            required
            placeholder="مثال: منحل الروضة"
          />

          <Input
            label="المنطقة"
            value={formData.region}
            onChange={(e) => setFormData({ ...formData, region: e.target.value })}
            required
            placeholder="مثال: الرياض"
          />

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              label="خط العرض"
              type="number"
              step="any"
              value={formData.latitude}
              onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
              placeholder="24.7136"
            />

            <Input
              label="خط الطول"
              type="number"
              step="any"
              value={formData.longitude}
              onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
              placeholder="46.6753"
            />
          </div>

          <Input
            label="الارتفاع (متر)"
            type="number"
            step="any"
            value={formData.altitude}
            onChange={(e) => setFormData({ ...formData, altitude: e.target.value })}
            placeholder="600"
          />

          <Select
            label="نوع المنحل"
            value={formData.type}
            onChange={(e) => setFormData({ ...formData, type: e.target.value as any })}
            options={[
              { value: 'fixed', label: 'ثابت' },
              { value: 'mobile', label: 'متنقل' },
            ]}
          />

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">
              الوصف
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={3}
              className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-transparent"
              placeholder="وصف مختصر عن المنحل..."
            />
          </div>

          <div className="flex flex-col-reverse sm:flex-row gap-3 pt-4">
            <Button type="button" variant="ghost" onClick={handleCloseModal} className="flex-1">
              إلغاء
            </Button>
            <Button type="submit" className="flex-1">
              {editingApiary ? 'حفظ التعديلات' : 'إضافة منحل'}
            </Button>
          </div>
        </form>
      </Modal>
    </DashboardLayout>
  );
}
