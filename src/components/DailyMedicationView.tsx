import { useState } from "react";
import { Card } from "./ui/card";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "./ui/alert-dialog";
import { Check, Clock, X, Plus, Pencil, Trash2 } from "lucide-react";

export interface DailyMedication {
  id: string;
  medicationId: string;
  medicationName: string;
  dosage: string;
  scheduledTime: string;
  date: string;
  status: "upcoming" | "on-time" | "late" | "missed" | "skipped";
  actualTime?: string;
  notes?: string;
}

interface DailyMedicationViewProps {
  date: Date;
  medications: DailyMedication[];
  onLogIntake: (medication: DailyMedication) => void;
  onMarkSkipped: (medicationId: string) => void;
  onEditRecord: (medication: DailyMedication) => void;
  onDeleteRecord: (medicationId: string) => void;
}

export function DailyMedicationView({
  date,
  medications,
  onLogIntake,
  onMarkSkipped,
  onEditRecord,
  onDeleteRecord,
}: DailyMedicationViewProps) {
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [medicationToDelete, setMedicationToDelete] = useState<DailyMedication | null>(null);

  const isToday = date.toDateString() === new Date().toDateString();
  const isPast = date < new Date(new Date().setHours(0, 0, 0, 0));
  const isFuture = date > new Date(new Date().setHours(23, 59, 59, 999));

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('zh-TW', { 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric',
      weekday: 'long'
    });
  };

  const getStatusBadge = (status: DailyMedication["status"]) => {
    switch (status) {
      case "on-time":
        return <Badge className="bg-green-600">準時</Badge>;
      case "late":
        return <Badge className="bg-yellow-600">遲到</Badge>;
      case "missed":
        return <Badge className="bg-red-600">錯過</Badge>;
      case "skipped":
        return <Badge variant="outline">已跳過</Badge>;
      case "upcoming":
        return <Badge variant="secondary">待服用</Badge>;
      default:
        return null;
    }
  };

  const getStatusIcon = (status: DailyMedication["status"]) => {
    switch (status) {
      case "on-time":
      case "late":
        return <Check className="w-5 h-5 text-green-600" />;
      case "missed":
        return <X className="w-5 h-5 text-red-600" />;
      case "skipped":
        return <X className="w-5 h-5 text-gray-400" />;
      case "upcoming":
        return <Clock className="w-5 h-5 text-gray-400" />;
    }
  };

  const sortedMedications = [...medications].sort((a, b) => {
    const timeA = a.scheduledTime || "";
    const timeB = b.scheduledTime || "";
    return timeA.localeCompare(timeB);
  });

  const stats = {
    total: medications.length,
    completed: medications.filter(m => m.status === "on-time" || m.status === "late").length,
    onTime: medications.filter(m => m.status === "on-time").length,
    late: medications.filter(m => m.status === "late").length,
    missed: medications.filter(m => m.status === "missed").length,
    skipped: medications.filter(m => m.status === "skipped").length,
  };

  const completionRate = stats.total > 0 
    ? Math.round((stats.completed / stats.total) * 100) 
    : 0;

  const handleDeleteClick = (medication: DailyMedication) => {
    setMedicationToDelete(medication);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = () => {
    if (medicationToDelete) {
      onDeleteRecord(medicationToDelete.id);
      setDeleteDialogOpen(false);
      setMedicationToDelete(null);
    }
  };

  return (
    <div className="space-y-4">
      {stats.total > 0 && (
        <Card className="p-4">
          <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
            <div className="text-center p-2 bg-gray-50 rounded-lg">
              <div className="text-xl font-semibold text-gray-900">{stats.total}</div>
              <div className="text-xs text-gray-600">總計</div>
            </div>
            <div className="text-center p-2 bg-blue-50 rounded-lg">
              <div className="text-xl font-semibold text-blue-600">{completionRate}%</div>
              <div className="text-xs text-gray-600">完成率</div>
            </div>
            <div className="text-center p-2 bg-green-50 rounded-lg">
              <div className="text-xl font-semibold text-green-600">{stats.onTime}</div>
              <div className="text-xs text-gray-600">準時</div>
            </div>
            <div className="text-center p-2 bg-yellow-50 rounded-lg">
              <div className="text-xl font-semibold text-yellow-600">{stats.late}</div>
              <div className="text-xs text-gray-600">遲到</div>
            </div>
            <div className="text-center p-2 bg-red-50 rounded-lg">
              <div className="text-xl font-semibold text-red-600">{stats.missed}</div>
              <div className="text-xs text-gray-600">錯過</div>
            </div>
          </div>
        </Card>
      )}

      {stats.total === 0 && (
        <div className="text-center py-12 text-gray-500">
          <Clock className="w-16 h-16 mx-auto mb-4 opacity-30" />
          <p className="text-lg">這天沒有安排藥物</p>
        </div>
      )}

      {stats.total > 0 && (
        <div className="space-y-3">
          {sortedMedications.map((medication) => (
            <Card key={medication.id} className="p-4">
            <div className="flex items-start gap-4">
              <div className="mt-1">
                {getStatusIcon(medication.status)}
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-3 mb-2">
                  <div>
                    <h3 className="font-medium text-gray-900">{medication.medicationName}</h3>
                    <p className="text-sm text-gray-600">{medication.dosage}</p>
                  </div>
                  {getStatusBadge(medication.status)}
                </div>

                <div className="flex items-center gap-4 text-sm text-gray-600">
                  <div>
                    <span className="font-medium">預定時間：</span>
                    {medication.scheduledTime}
                  </div>
                  {medication.actualTime && (
                    <div>
                      <span className="font-medium">實際時間：</span>
                      {medication.actualTime}
                    </div>
                  )}
                </div>

                {medication.notes && (
                  <p className="mt-2 text-sm text-gray-600 italic">
                    備註：{medication.notes}
                  </p>
                )}

                {medication.status === "upcoming" && !isFuture && (
                  <div className="mt-3 flex gap-2">
                    <Button 
                      size="sm" 
                      onClick={() => onLogIntake(medication)}
                    >
                      <Check className="w-4 h-4 mr-1" />
                      記錄服藥
                    </Button>
                    <Button 
                      size="sm" 
                      variant="outline"
                      onClick={() => onMarkSkipped(medication.id)}
                    >
                      <X className="w-4 h-4 mr-1" />
                      標記跳過
                    </Button>
                  </div>
                )}

                {(medication.status === "on-time" || medication.status === "late" || medication.status === "skipped") && (
                  <div className="mt-3 flex gap-2">
                    <Button 
                      size="sm" 
                      variant="outline"
                      onClick={() => onEditRecord(medication)}
                    >
                      <Pencil className="w-4 h-4 mr-1" />
                      修改記錄
                    </Button>
                    <Button 
                      size="sm" 
                      variant="outline"
                      onClick={() => handleDeleteClick(medication)}
                      className="text-red-600 hover:text-red-700 hover:bg-red-50 hover:border-red-200"
                    >
                      <Trash2 className="w-4 h-4 mr-1" />
                      取消記錄
                    </Button>
                  </div>
                )}
              </div>
            </div>
          </Card>
          ))}
        </div>
      )}

      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>確定要取消此服藥記錄嗎？</AlertDialogTitle>
            <AlertDialogDescription>
              取消「{medicationToDelete?.medicationName}」在 {medicationToDelete?.scheduledTime} 的服藥記錄後，
              該記錄將恢復為待服用狀態。此操作無法復原。
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>取消</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleConfirmDelete}
              className="bg-red-600 hover:bg-red-700"
            >
              確定取消
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
