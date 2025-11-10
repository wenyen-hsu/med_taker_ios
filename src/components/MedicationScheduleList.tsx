import { useState } from "react";
import { Card } from "./ui/card";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "./ui/alert-dialog";
import { Pill, Trash2, Clock, Calendar } from "lucide-react";
import { MedicationSchedule } from "../utils/api";

interface MedicationScheduleListProps {
  schedules: MedicationSchedule[];
  onDelete: (id: string) => void;
}

export function MedicationScheduleList({ schedules, onDelete }: MedicationScheduleListProps) {
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [scheduleToDelete, setScheduleToDelete] = useState<MedicationSchedule | null>(null);

  const handleDeleteClick = (schedule: MedicationSchedule) => {
    setScheduleToDelete(schedule);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = () => {
    if (scheduleToDelete) {
      onDelete(scheduleToDelete.id);
      setDeleteDialogOpen(false);
      setScheduleToDelete(null);
    }
  };

  const getFrequencyText = (schedule: MedicationSchedule) => {
    if (schedule.frequency === "daily") {
      return "每日";
    } else if (schedule.frequency === "weekly" && schedule.activeDays) {
      const dayNames = ["日", "一", "二", "三", "四", "五", "六"];
      const days = schedule.activeDays.map(d => dayNames[d]).join("、");
      return `每週 ${days}`;
    }
    return "自訂";
  };

  const activeSchedules = schedules.filter(s => s.isActive);

  if (activeSchedules.length === 0) {
    return (
      <Card className="p-8 text-center">
        <Pill className="w-12 h-12 text-gray-400 mx-auto mb-4" />
        <p className="text-gray-600">尚無藥物排程</p>
        <p className="text-sm text-gray-500 mt-2">點擊上方按鈕新增藥物排程</p>
      </Card>
    );
  }

  return (
    <>
      <div className="space-y-3">
        {activeSchedules.map((schedule) => (
          <Card key={schedule.id} className="p-4 hover:shadow-md transition-shadow">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-2">
                  <Pill className="w-5 h-5 text-blue-600" />
                  <h3 className="text-lg">{schedule.name}</h3>
                  <Badge variant="secondary">{schedule.dosage}</Badge>
                </div>
                
                <div className="space-y-1 text-sm text-gray-600 ml-7">
                  <div className="flex items-center gap-2">
                    <Clock className="w-4 h-4" />
                    <span>每日 {schedule.scheduledTime} 服用</span>
                  </div>
                  
                  <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4" />
                    <span>{getFrequencyText(schedule)}</span>
                  </div>
                  
                  <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4" />
                    <span>開始日期：{new Date(schedule.startDate).toLocaleDateString('zh-TW')}</span>
                  </div>
                  
                  {schedule.endDate && (
                    <div className="flex items-center gap-2">
                      <Calendar className="w-4 h-4" />
                      <span>結束日期：{new Date(schedule.endDate).toLocaleDateString('zh-TW')}</span>
                    </div>
                  )}
                </div>
              </div>

              <Button
                variant="ghost"
                size="sm"
                onClick={() => handleDeleteClick(schedule)}
                className="text-red-600 hover:text-red-700 hover:bg-red-50"
              >
                <Trash2 className="w-4 h-4" />
              </Button>
            </div>
          </Card>
        ))}
      </div>

      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>確定要刪除此藥物排程嗎？</AlertDialogTitle>
            <AlertDialogDescription>
              刪除「{scheduleToDelete?.name}」排程後，將無法復原。
              此操作不會刪除已記錄的服藥記錄，但未來將不會再自動產生此藥物的服藥提醒。
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>取消</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleConfirmDelete}
              className="bg-red-600 hover:bg-red-700"
            >
              刪除
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
