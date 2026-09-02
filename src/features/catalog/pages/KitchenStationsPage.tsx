import { useState, useEffect, useCallback } from 'react';
import { Plus, Edit2, Trash2, GripVertical, UsersRound, Tags } from 'lucide-react';
import { useLanguage } from '@/context/LanguageContext';
import { useToast } from '@/components/Toast';
import { DesignSurface, DesignPageHeader } from '@/components/design/DesignSurface';
import { DataTable, type Column } from '@/components/DataTable';
import { Button } from '@/components/Button';
import { Input } from '@/components/Input';
import { Modal } from '@/components/Modal';
import { ConfirmDialog } from '@/components/ConfirmDialog';
import { useCan } from '@/lib/permissions';
import { useBranchFilter } from '@/lib/useBranchFilter';
import { catalog } from '@/api/domains/catalog';
import { supabase } from '@/api';
import type { KitchenStation } from '@/lib/types';

interface StationForm {
  code: string;
  name_ar: string;
  name_en: string;
  sort_order: number;
}

interface AssignmentStation extends KitchenStation {
  user_ids: string[];
  category_ids: string[];
}

interface BranchUser { id: string; full_name: string | null; email: string; role: string }
interface BranchCategory { id: string; name: string; name_en: string | null }

const EMPTY_FORM: StationForm = { code: '', name_ar: '', name_en: '', sort_order: 0 };

export function KitchenStationsPage() {
  const { lang } = useLanguage();
  const { show } = useToast();
  const can = useCan();
  const branchFilter = useBranchFilter();
  const ar = lang === 'ar';

  const [stations, setStations] = useState<KitchenStation[]>([]);
  const [assignments, setAssignments] = useState<Record<string, AssignmentStation>>({});
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<StationForm>(EMPTY_FORM);
  const [deleteTarget, setDeleteTarget] = useState<KitchenStation | null>(null);
  const [assignmentTarget, setAssignmentTarget] = useState<KitchenStation | null>(null);
  const [branchUsers, setBranchUsers] = useState<BranchUser[]>([]);
  const [branchCategories, setBranchCategories] = useState<BranchCategory[]>([]);
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [selectedCategories, setSelectedCategories] = useState<string[]>([]);
  const [savingAssignment, setSavingAssignment] = useState(false);

  const loadAssignments = useCallback(async () => {
    if (!branchFilter || !can('settings.manage')) {
      setAssignments({});
      return;
    }
    const { data, error } = await supabase.rpc('get_kitchen_station_assignments', { p_branch_id: branchFilter });
    if (error) throw error;
    const res = data as { success?: boolean; error?: string; stations?: AssignmentStation[] } | null;
    if (!res?.success) throw new Error(res?.error || 'ASSIGNMENTS_LOAD_FAILED');
    setAssignments(Object.fromEntries((res.stations || []).map((s) => [s.id, s])));
  }, [branchFilter, can]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await catalog.listKitchenStations();
      setStations((data ?? []) as KitchenStation[]);
      await loadAssignments();
    } catch (err) {
      show(String((err as Error).message ?? err), 'error');
    } finally {
      setLoading(false);
    }
  }, [loadAssignments, show]);

  useEffect(() => { void load(); }, [load]);

  const handleSave = async () => {
    if (!form.code.trim() || !form.name_ar.trim()) {
      show(ar ? 'أكمل الحقول المطلوبة' : 'Fill required fields', 'error');
      return;
    }
    try {
      if (editingId) {
        await catalog.updateKitchenStation(editingId, { name_ar: form.name_ar, name_en: form.name_en, sort_order: form.sort_order });
      } else {
        await catalog.createKitchenStation({ code: form.code.trim().toLowerCase(), name_ar: form.name_ar, name_en: form.name_en, sort_order: form.sort_order });
      }
      show(ar ? 'تم الحفظ' : 'Saved', 'success');
      setShowForm(false);
      setEditingId(null);
      setForm(EMPTY_FORM);
      void load();
    } catch (err) { show(String((err as Error).message ?? err), 'error'); }
  };

  const handleToggle = async (s: KitchenStation) => {
    try {
      await catalog.updateKitchenStation(s.id, { is_active: !s.is_active });
      void load();
    } catch (err) { show(String((err as Error).message ?? err), 'error'); }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      await catalog.deleteKitchenStation(deleteTarget.id);
      show(ar ? 'تم الحذف' : 'Deleted', 'success');
      setDeleteTarget(null);
      void load();
    } catch (err) { show(String((err as Error).message ?? err), 'error'); }
  };

  const openEdit = (s: KitchenStation) => {
    setEditingId(s.id);
    setForm({ code: s.code, name_ar: s.name_ar, name_en: s.name_en ?? '', sort_order: s.sort_order });
    setShowForm(true);
  };

  const openAssignments = async (s: KitchenStation) => {
    if (!branchFilter) {
      show(ar ? 'اختر فرعًا أولًا من محدد الفروع' : 'Select a branch first', 'warning');
      return;
    }
    try {
      const [usersRes, catsRes] = await Promise.all([
        supabase.from('users').select('id,full_name,email,role').eq('branch_id', branchFilter).eq('is_active', true).order('full_name'),
        supabase.from('categories').select('id,name,name_en').eq('branch_id', branchFilter).order('name'),
      ]);
      if (usersRes.error) throw usersRes.error;
      if (catsRes.error) throw catsRes.error;
      setBranchUsers((usersRes.data || []) as BranchUser[]);
      setBranchCategories((catsRes.data || []) as BranchCategory[]);
      const current = assignments[s.id];
      setSelectedUsers(current?.user_ids || []);
      setSelectedCategories(current?.category_ids || []);
      setAssignmentTarget(s);
    } catch (err) {
      show(String((err as Error).message ?? err), 'error');
    }
  };

  const saveAssignments = async () => {
    if (!branchFilter || !assignmentTarget) return;
    setSavingAssignment(true);
    try {
      const { data, error } = await supabase.rpc('save_kitchen_station_assignments', {
        p_branch_id: branchFilter,
        p_station_id: assignmentTarget.id,
        p_user_ids: selectedUsers,
        p_category_ids: selectedCategories,
      });
      if (error) throw error;
      const res = data as { success?: boolean; error?: string } | null;
      if (!res?.success) throw new Error(res?.error || 'ASSIGNMENT_SAVE_FAILED');
      show(ar ? 'تم حفظ تعيينات المحطة' : 'Station assignments saved', 'success');
      setAssignmentTarget(null);
      await loadAssignments();
    } catch (err) {
      show(String((err as Error).message ?? err), 'error');
    } finally {
      setSavingAssignment(false);
    }
  };

  const toggleId = (id: string, selected: string[], setter: (v: string[]) => void) => {
    setter(selected.includes(id) ? selected.filter((x) => x !== id) : [...selected, id]);
  };

  const columns: Column<KitchenStation>[] = [
    { key: 'sort_order', header: '#', render: r => <span className="text-ui-muted"><GripVertical className="h-4 w-4 inline" /> {r.sort_order}</span> },
    { key: 'code', header: ar ? 'الكود' : 'Code', render: r => <code className="rounded bg-ui-muted px-1.5 py-0.5 text-xs">{r.code}</code> },
    { key: 'name_ar', header: ar ? 'المحطة' : 'Station', render: r => ar ? r.name_ar : (r.name_en || r.name_ar) },
    { key: 'assignments', header: ar ? 'التعيينات' : 'Assignments', render: r => (
      <div className="flex flex-wrap gap-1 text-[11px] text-ui-muted">
        <span className="inline-flex items-center gap-1 rounded-md bg-ui-page-alt px-1.5 py-1"><UsersRound className="h-3 w-3" /> {assignments[r.id]?.user_ids?.length || 0}</span>
        <span className="inline-flex items-center gap-1 rounded-md bg-ui-page-alt px-1.5 py-1"><Tags className="h-3 w-3" /> {assignments[r.id]?.category_ids?.length || 0}</span>
      </div>
    ) },
    { key: 'is_active', header: ar ? 'نشط' : 'Active', render: r => (
      <button onClick={() => void handleToggle(r)} className={`rounded-full px-2 py-0.5 text-xs font-semibold ${r.is_active ? 'bg-ui-success-soft text-ui-success' : 'bg-ui-page-alt text-ui-subtle'}`}>
        {r.is_active ? (ar ? 'نعم' : 'Yes') : (ar ? 'لا' : 'No')}
      </button>
    )},
  ];

  if (can('settings.manage')) {
    columns.push({
      key: 'actions', header: '', render: (r: KitchenStation) => (
        <div className="flex gap-2">
          <button onClick={() => void openAssignments(r)} className="text-ui-primary hover:opacity-80" title={ar ? 'تعيين مستخدمين وفئات' : 'Assign users and categories'}><UsersRound className="h-4 w-4" /></button>
          <button onClick={() => openEdit(r)} className="text-ui-info hover:opacity-80"><Edit2 className="h-4 w-4" /></button>
          <button onClick={() => setDeleteTarget(r)} className="text-ui-danger hover:opacity-80"><Trash2 className="h-4 w-4" /></button>
        </div>
      ),
    });
  }

  return (
    <DesignSurface testId="kitchen-stations">
      <DesignPageHeader title={ar ? 'محطات المطبخ' : 'Kitchen Stations'} subtitle={ar ? 'اربط كل فئة بمحطة وحدد المستخدمين المسموح لهم برؤيتها' : 'Map product categories to stations and assign the users allowed to see them'} />
      <div className="space-y-4">
        {!branchFilter && <div className="rounded-xl border border-ui-warning/30 bg-ui-warning/10 px-3 py-2 text-sm text-ui-warning">{ar ? 'اختر فرعًا لتعديل تعيينات المستخدمين والفئات.' : 'Select a branch to edit user/category assignments.'}</div>}
        {can('settings.manage') && (
          <Button onClick={() => { setEditingId(null); setForm(EMPTY_FORM); setShowForm(true); }}>
            <Plus className="h-4 w-4" /> {ar ? 'إضافة محطة' : 'Add Station'}
          </Button>
        )}
        <DataTable columns={columns} data={stations} loading={loading} />
      </div>

      <Modal open={showForm} onClose={() => setShowForm(false)} title={editingId ? (ar ? 'تعديل محطة' : 'Edit Station') : (ar ? 'محطة جديدة' : 'New Station')}>
        <div className="space-y-3">
          <Input label={ar ? 'الكود (إنجليزي)' : 'Code'} value={form.code} onChange={e => setForm(f => ({ ...f, code: e.target.value }))} disabled={!!editingId} placeholder="grill, salad, ..." />
          <Input label={ar ? 'الاسم عربي' : 'Name (AR)'} value={form.name_ar} onChange={e => setForm(f => ({ ...f, name_ar: e.target.value }))} />
          <Input label={ar ? 'الاسم إنجليزي' : 'Name (EN)'} value={form.name_en} onChange={e => setForm(f => ({ ...f, name_en: e.target.value }))} />
          <Input label={ar ? 'ترتيب العرض' : 'Sort Order'} type="number" value={form.sort_order} onChange={e => setForm(f => ({ ...f, sort_order: +e.target.value }))} />
          <div className="flex justify-end gap-2 pt-2"><Button variant="outline" onClick={() => setShowForm(false)}>{ar ? 'إلغاء' : 'Cancel'}</Button><Button onClick={() => void handleSave()}>{ar ? 'حفظ' : 'Save'}</Button></div>
        </div>
      </Modal>

      <Modal open={!!assignmentTarget} onClose={() => setAssignmentTarget(null)} title={`${ar ? 'تعيينات محطة' : 'Station Assignments'}: ${assignmentTarget ? (ar ? assignmentTarget.name_ar : assignmentTarget.name_en) : ''}`}>
        <div className="grid max-h-[65dvh] gap-4 overflow-y-auto sm:grid-cols-2">
          <section>
            <h3 className="mb-2 flex items-center gap-2 text-sm font-black text-ui-text"><UsersRound className="h-4 w-4" /> {ar ? 'المستخدمون' : 'Users'}</h3>
            <div className="space-y-1.5">
              {branchUsers.map((u) => <label key={u.id} className="flex cursor-pointer items-start gap-2 rounded-lg border border-ui-border p-2 text-xs"><input type="checkbox" className="mt-0.5 h-4 w-4" checked={selectedUsers.includes(u.id)} onChange={() => toggleId(u.id, selectedUsers, setSelectedUsers)} /><span className="min-w-0"><span className="block font-bold text-ui-text">{u.full_name || u.email}</span><span className="text-ui-subtle">{u.role}</span></span></label>)}
              {branchUsers.length === 0 && <p className="text-xs text-ui-subtle">{ar ? 'لا يوجد مستخدمون في الفرع.' : 'No branch users.'}</p>}
            </div>
          </section>
          <section>
            <h3 className="mb-2 flex items-center gap-2 text-sm font-black text-ui-text"><Tags className="h-4 w-4" /> {ar ? 'فئات المنتجات' : 'Product Categories'}</h3>
            <div className="space-y-1.5">
              {branchCategories.map((c) => <label key={c.id} className="flex cursor-pointer items-start gap-2 rounded-lg border border-ui-border p-2 text-xs"><input type="checkbox" className="mt-0.5 h-4 w-4" checked={selectedCategories.includes(c.id)} onChange={() => toggleId(c.id, selectedCategories, setSelectedCategories)} /><span className="font-bold text-ui-text">{ar ? c.name : (c.name_en || c.name)}</span></label>)}
              {branchCategories.length === 0 && <p className="text-xs text-ui-subtle">{ar ? 'لا توجد فئات في الفرع.' : 'No branch categories.'}</p>}
            </div>
          </section>
        </div>
        <div className="mt-4 flex justify-end gap-2 border-t border-ui-border pt-3"><Button variant="outline" onClick={() => setAssignmentTarget(null)}>{ar ? 'إلغاء' : 'Cancel'}</Button><Button disabled={savingAssignment} onClick={() => void saveAssignments()}>{savingAssignment ? (ar ? 'جاري الحفظ...' : 'Saving...') : (ar ? 'حفظ التعيينات' : 'Save Assignments')}</Button></div>
      </Modal>

      <ConfirmDialog open={!!deleteTarget} onClose={() => setDeleteTarget(null)} onConfirm={() => void handleDelete()} title={ar ? 'حذف المحطة' : 'Delete Station'} message={ar ? `هل تريد حذف "${deleteTarget?.name_ar}"؟` : `Delete "${deleteTarget?.name_en}"?`} />
    </DesignSurface>
  );
}
