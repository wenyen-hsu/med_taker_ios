import { useState, useEffect } from "react";
import { CalendarView } from "./components/CalendarView";
import { DailyMedicationView, DailyMedication } from "./components/DailyMedicationView";
import { LogIntakeDialog } from "./components/LogIntakeDialog";
import { AddMedicationDialog } from "./components/AddMedicationDialog";
import { MedicationScheduleList } from "./components/MedicationScheduleList";
import { Button } from "./components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./components/ui/tabs";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "./components/ui/alert-dialog";
import { Pill, Plus, Loader2, ArrowLeft, Calendar as CalendarIcon, List, RotateCcw } from "lucide-react";
import { Toaster, toast } from "sonner@2.0.3";
import * as api from "./utils/api";

export default function App() {
  const [view, setView] = useState<"calendar" | "day">("calendar");
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [dailyMedications, setDailyMedications] = useState<DailyMedication[]>([]);
  const [medicationSchedules, setMedicationSchedules] = useState<api.MedicationSchedule[]>([]);
  const [medicationRecords, setMedicationRecords] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(true);
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [logDialogOpen, setLogDialogOpen] = useState(false);
  const [resetDialogOpen, setResetDialogOpen] = useState(false);
  const [selectedMedication, setSelectedMedication] = useState<DailyMedication | null>(null);

  useEffect(() => {
    loadInitialData();
  }, []);

  useEffect(() => {
    loadDailyMedications(selectedDate);
  }, [selectedDate]);

  const loadInitialData = async () => {
    try {
      setLoading(true);
      await Promise.all([
        loadMonthRecords(new Date()),
        loadMedicationSchedules(),
      ]);
    } catch (error) {
      console.error("Error loading initial data:", error);
      toast.error("載入資料失敗");
    } finally {
      setLoading(false);
    }
  };

  const loadMedicationSchedules = async () => {
    try {
      const schedules = await api.getMedicationSchedules();
      setMedicationSchedules(schedules);
    } catch (error) {
      console.error("Error loading medication schedules:", error);
      toast.error("載入藥物排程失敗");
    }
  };

  const loadMonthRecords = async (date: Date) => {
    try {
      const year = date.getFullYear();
      const month = date.getMonth();
      const startDate = new Date(year, month, 1);
      const endDate = new Date(year, month + 1, 0);

      const startStr = startDate.toISOString().split('T')[0];
      const endStr = endDate.toISOString().split('T')[0];

      const medications = await api.getDailyMedicationsRange(startStr, endStr);
      
      console.log('📅 Loading medications for range:', startStr, 'to', endStr);
      console.log('📊 Total medications received:', medications.length);

      // Calculate records for each day
      const records: Record<string, any> = {};
      medications.forEach((med) => {
        if (!records[med.date]) {
          records[med.date] = {
            total: 0,
            completed: 0,
            onTime: 0,
            late: 0,
            missed: 0,
            skipped: 0,
            upcoming: 0,
          };
        }
        
        // Count all medications
        records[med.date].total++;
        
        // Count by status
        if (med.status === "on-time") {
          records[med.date].completed++;
          records[med.date].onTime++;
        } else if (med.status === "late") {
          records[med.date].completed++;
          records[med.date].late++;
        } else if (med.status === "missed") {
          records[med.date].missed++;
        } else if (med.status === "skipped") {
          records[med.date].skipped++;
        } else if (med.status === "upcoming") {
          records[med.date].upcoming++;
        }
      });

      console.log('📈 Medication records by date:', records);
      console.log('✅ Updated medication records state');
      setMedicationRecords(records);
    } catch (error) {
      console.error("❌ Error loading month records:", error);
      toast.error("載入月份資料失敗");
    }
  };

  const loadDailyMedications = async (date: Date) => {
    try {
      const dateStr = date.toISOString().split('T')[0];
      console.log(`📅 Loading daily medications for ${dateStr}...`);
      const medications = await api.getDailyMedications(dateStr);
      console.log(`📅 Received ${medications.length} medications:`, medications.map(m => ({ id: m.id, status: m.status })));
      
      // Convert to DailyMedication type
      const dailyMeds: DailyMedication[] = medications.map((med) => ({
        id: med.id,
        medicationId: med.scheduleId,
        medicationName: med.medicationName,
        dosage: med.dosage,
        scheduledTime: med.scheduledTime,
        date: med.date,
        status: med.status,
        actualTime: med.actualTime,
        notes: med.notes,
      }));

      setDailyMedications(dailyMeds);
      console.log(`✅ Daily medications updated`);
    } catch (error) {
      console.error("❌ Error loading daily medications:", error);
      toast.error("載入每日藥物失敗");
    }
  };

  const handleAddMedication = async (newSchedule: {
    name: string;
    dosage: string;
    scheduledTime: string;
    frequency: "daily" | "weekly";
    activeDays?: number[];
    startDate: string;
  }) => {
    try {
      const schedule: api.MedicationSchedule = {
        id: Date.now().toString(),
        name: newSchedule.name,
        dosage: newSchedule.dosage,
        scheduledTime: newSchedule.scheduledTime,
        frequency: newSchedule.frequency,
        activeDays: newSchedule.activeDays,
        startDate: newSchedule.startDate,
        isActive: true,
      };

      await api.addMedicationSchedule(schedule);
      toast.success("藥物排程已新增");

      // Reload data
      await loadMedicationSchedules();
      await loadMonthRecords(selectedDate);
      await loadDailyMedications(selectedDate);
    } catch (error) {
      console.error("Error adding medication schedule:", error);
      toast.error("新增失敗，請重試");
    }
  };

  const handleLogIntake = (medication: DailyMedication) => {
    setSelectedMedication(medication);
    setLogDialogOpen(true);
  };

  const handleConfirmIntake = async (actualTime: string, notes: string) => {
    if (!selectedMedication) return;

    try {
      const scheduled = new Date(`2024-01-01 ${selectedMedication.scheduledTime}`);
      const actual = new Date(`2024-01-01 ${actualTime}`);
      const diffMinutes = Math.floor((actual.getTime() - scheduled.getTime()) / 60000);

      let status: DailyMedication["status"];
      if (Math.abs(diffMinutes) <= 15) {
        status = "on-time";
      } else {
        status = "late";
      }

      const updates = {
        status,
        actualTime,
        notes: notes || selectedMedication.notes,
      };

      console.log(`💊 Updating medication ${selectedMedication.id}:`, updates);
      await api.updateDailyMedication(selectedMedication.id, updates);
      console.log(`✅ Update successful, reloading data...`);

      // Update local state immediately
      setDailyMedications((prev) =>
        prev.map((med) =>
          med.id === selectedMedication.id ? { ...med, ...updates } : med
        )
      );

      // Reload month records to update calendar - this is crucial for calendar view
      console.log(`🔄 Reloading month records for ${selectedDate.toISOString().split('T')[0]}...`);
      await loadMonthRecords(selectedDate);
      
      // Also reload daily medications to ensure consistency
      console.log(`🔄 Reloading daily medications...`);
      await loadDailyMedications(selectedDate);
      console.log(`✅ All data reloaded`);

      toast.success("服藥記錄已更新");
      setLogDialogOpen(false);
    } catch (error) {
      console.error("❌ Error updating medication:", error);
      toast.error("更新失敗，請重試");
    }
  };

  const handleMarkSkipped = async (medicationId: string) => {
    try {
      await api.updateDailyMedication(medicationId, { status: "skipped" });

      setDailyMedications((prev) =>
        prev.map((med) =>
          med.id === medicationId ? { ...med, status: "skipped" } : med
        )
      );

      // Reload data to update calendar
      await loadMonthRecords(selectedDate);
      await loadDailyMedications(selectedDate);
      
      toast.success("已標記為跳過");
    } catch (error) {
      console.error("Error marking as skipped:", error);
      toast.error("操作失敗，請重試");
    }
  };

  const handleEditRecord = (medication: DailyMedication) => {
    setSelectedMedication(medication);
    setLogDialogOpen(true);
  };

  const handleDeleteRecord = async (medicationId: string) => {
    try {
      await api.deleteDailyMedication(medicationId);

      // Update local state - reset to upcoming status
      setDailyMedications((prev) =>
        prev.map((med) =>
          med.id === medicationId 
            ? { ...med, status: "upcoming", actualTime: undefined, notes: undefined } 
            : med
        )
      );

      // Reload data to update calendar
      await loadMonthRecords(selectedDate);
      await loadDailyMedications(selectedDate);
      
      toast.success("記錄已取消");
    } catch (error) {
      console.error("Error deleting medication record:", error);
      toast.error("刪除失敗，請重試");
    }
  };

  const handleDateSelect = async (date: Date) => {
    setSelectedDate(date);
    
    // Check if we need to load a new month
    if (date.getMonth() !== selectedDate.getMonth() || 
        date.getFullYear() !== selectedDate.getFullYear()) {
      await loadMonthRecords(date);
    }
  };

  const handleDateClick = async (date: Date) => {
    await handleDateSelect(date);
    setView("day");
  };

  const handleResetAllMedications = async () => {
    try {
      const result = await api.resetAllDailyMedications();
      
      // Refresh data
      setMedicationRecords({});
      await loadMonthRecords(selectedDate);
      await loadDailyMedications(selectedDate);
      
      toast.success(`已重置 ${result.deletedCount} 筆用藥記錄`);
      setResetDialogOpen(false);
    } catch (error) {
      console.error("Error resetting all medications:", error);
      toast.error("重置失敗，請重試");
    }
  };

  const handleBackToCalendar = () => {
    setView("calendar");
  };

  const handleDeleteSchedule = async (scheduleId: string) => {
    try {
      await api.deleteMedicationSchedule(scheduleId);
      toast.success("藥物排程已刪除");
      
      // Reload data
      await loadMedicationSchedules();
      await loadMonthRecords(selectedDate);
      await loadDailyMedications(selectedDate);
    } catch (error) {
      console.error("Error deleting medication schedule:", error);
      toast.error("刪除失敗，請重試");
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-12 h-12 animate-spin text-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">載入中...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      <div className="max-w-4xl mx-auto p-6">
        {view === "calendar" ? (
          <>
            <div className="mb-8">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-3">
                  <Pill className="w-8 h-8 text-blue-600" />
                  <h1>服藥追蹤系統</h1>
                </div>
                <div className="flex items-center gap-2">
                  <Button 
                    variant="outline" 
                    onClick={() => setResetDialogOpen(true)}
                    className="text-red-600 border-red-200 hover:bg-red-50 hover:text-red-700"
                  >
                    <RotateCcw className="w-4 h-4 sm:mr-2" />
                    <span className="hidden sm:inline">重置所有用藥</span>
                  </Button>
                  <Button onClick={() => setAddDialogOpen(true)}>
                    <Plus className="w-4 h-4 sm:mr-2" />
                    <span className="hidden sm:inline">新增藥物排程</span>
                  </Button>
                </div>
              </div>
            </div>

            <Tabs defaultValue="calendar" className="w-full">
              <TabsList className="grid w-full grid-cols-2 mb-6">
                <TabsTrigger value="calendar" className="flex items-center gap-2">
                  <CalendarIcon className="w-4 h-4" />
                  日曆視圖
                </TabsTrigger>
                <TabsTrigger value="schedules" className="flex items-center gap-2">
                  <List className="w-4 h-4" />
                  藥物排程
                </TabsTrigger>
              </TabsList>

              <TabsContent value="calendar" className="mt-0">
                <p className="text-gray-600 mb-4">
                  點擊日曆上的日期查看當天的服藥記錄
                </p>
                <CalendarView
                  selectedDate={selectedDate}
                  onDateSelect={handleDateClick}
                  onMonthChange={loadMonthRecords}
                  medicationRecords={medicationRecords}
                />
              </TabsContent>

              <TabsContent value="schedules" className="mt-0">
                <p className="text-gray-600 mb-4">
                  管理您的藥物排程，點擊刪除按鈕可移除不需要的排程
                </p>
                <MedicationScheduleList
                  schedules={medicationSchedules}
                  onDelete={handleDeleteSchedule}
                />
              </TabsContent>
            </Tabs>
          </>
        ) : (
          <>
            <div className="mb-6">
              <Button 
                variant="ghost" 
                onClick={handleBackToCalendar}
                className="mb-4 -ml-2"
              >
                <ArrowLeft className="w-4 h-4 mr-2" />
                返回日曆
              </Button>
              
              <div className="text-center mb-6">
                <h1 className="text-3xl mb-2">
                  {selectedDate.toLocaleDateString('zh-TW', { 
                    year: 'numeric', 
                    month: 'long', 
                    day: 'numeric',
                  })}
                </h1>
                <p className="text-lg text-gray-600">
                  {selectedDate.toLocaleDateString('zh-TW', { 
                    weekday: 'long'
                  })}
                </p>
              </div>
            </div>

            <DailyMedicationView
              date={selectedDate}
              medications={dailyMedications}
              onLogIntake={handleLogIntake}
              onMarkSkipped={handleMarkSkipped}
              onEditRecord={handleEditRecord}
              onDeleteRecord={handleDeleteRecord}
            />
          </>
        )}

        {selectedMedication && (
          <LogIntakeDialog
            open={logDialogOpen}
            onOpenChange={setLogDialogOpen}
            medicationName={selectedMedication.medicationName}
            scheduledTime={selectedMedication.scheduledTime}
            onConfirm={handleConfirmIntake}
            isEditing={selectedMedication.status !== "upcoming"}
            initialActualTime={selectedMedication.actualTime}
            initialNotes={selectedMedication.notes}
          />
        )}

        <AddMedicationDialog
          open={addDialogOpen}
          onOpenChange={setAddDialogOpen}
          onAdd={handleAddMedication}
        />

        <AlertDialog open={resetDialogOpen} onOpenChange={setResetDialogOpen}>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>確認重置所有用藥記錄</AlertDialogTitle>
              <AlertDialogDescription>
                此操作將刪除所有已記錄的用藥時間和備註，但不會刪除藥物排程。您確定要繼續嗎？此操作無法復原。
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>取消</AlertDialogCancel>
              <AlertDialogAction
                onClick={handleResetAllMedications}
                className="bg-red-600 hover:bg-red-700"
              >
                確認重置
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>

        <Toaster position="top-center" richColors />
      </div>
    </div>
  );
}
