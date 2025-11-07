import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "./ui/dialog";
import { Button } from "./ui/button";
import { Label } from "./ui/label";
import { Input } from "./ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Checkbox } from "./ui/checkbox";
import { Plus } from "lucide-react";

interface AddMedicationDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onAdd: (medication: {
    name: string;
    dosage: string;
    scheduledTime: string;
    frequency: "daily" | "weekly";
    activeDays?: number[];
    startDate: string;
  }) => void;
}

const WEEKDAYS = [
  { value: 0, label: "週日" },
  { value: 1, label: "週一" },
  { value: 2, label: "週二" },
  { value: 3, label: "週三" },
  { value: 4, label: "週四" },
  { value: 5, label: "週五" },
  { value: 6, label: "週六" },
];

export function AddMedicationDialog({
  open,
  onOpenChange,
  onAdd,
}: AddMedicationDialogProps) {
  const [name, setName] = useState("");
  const [dosage, setDosage] = useState("");
  const [scheduledTime, setScheduledTime] = useState("");
  const [frequency, setFrequency] = useState<"daily" | "weekly">("daily");
  const [activeDays, setActiveDays] = useState<number[]>([1, 2, 3, 4, 5]); // Default: weekdays
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!name || !dosage || !scheduledTime || !startDate) {
      return;
    }

    if (frequency === "weekly" && activeDays.length === 0) {
      return;
    }

    onAdd({
      name,
      dosage,
      scheduledTime,
      frequency,
      activeDays: frequency === "weekly" ? activeDays : undefined,
      startDate,
    });

    // Reset form
    setName("");
    setDosage("");
    setScheduledTime("");
    setFrequency("daily");
    setActiveDays([1, 2, 3, 4, 5]);
    setStartDate(new Date().toISOString().split('T')[0]);
    onOpenChange(false);
  };

  const toggleDay = (day: number) => {
    setActiveDays((prev) => 
      prev.includes(day) 
        ? prev.filter((d) => d !== day)
        : [...prev, day].sort()
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>新增藥物排程</DialogTitle>
          <DialogDescription>
            添加新的藥物提醒，系統將幫助您追蹤服藥時間
          </DialogDescription>
        </DialogHeader>
        
        <form onSubmit={handleSubmit}>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="medication-name">藥物名稱 *</Label>
              <Input
                id="medication-name"
                placeholder="例如：Lisinopril"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="dosage">劑量 *</Label>
              <Input
                id="dosage"
                placeholder="例如：10mg tablet"
                value={dosage}
                onChange={(e) => setDosage(e.target.value)}
                required
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="scheduled-time">預定時間 *</Label>
              <Input
                id="scheduled-time"
                type="time"
                value={scheduledTime}
                onChange={(e) => setScheduledTime(e.target.value)}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="start-date">開始日期 *</Label>
              <Input
                id="start-date"
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="frequency">重複頻率 *</Label>
              <Select value={frequency} onValueChange={(value: "daily" | "weekly") => setFrequency(value)}>
                <SelectTrigger id="frequency">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="daily">每天</SelectItem>
                  <SelectItem value="weekly">每週特定日期</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {frequency === "weekly" && (
              <div className="space-y-2">
                <Label>選擇星期 *</Label>
                <div className="grid grid-cols-4 gap-2">
                  {WEEKDAYS.map((day) => (
                    <div key={day.value} className="flex items-center space-x-2">
                      <Checkbox
                        id={`day-${day.value}`}
                        checked={activeDays.includes(day.value)}
                        onCheckedChange={() => toggleDay(day.value)}
                      />
                      <label
                        htmlFor={`day-${day.value}`}
                        className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 cursor-pointer"
                      >
                        {day.label}
                      </label>
                    </div>
                  ))}
                </div>
                {frequency === "weekly" && activeDays.length === 0 && (
                  <p className="text-sm text-red-600">請至少選擇一天</p>
                )}
              </div>
            )}

            <div className="bg-blue-50 p-3 rounded-md border border-blue-100">
              <p className="text-sm text-blue-800">
                {frequency === "daily" 
                  ? "此藥物將從開始日期起每天重複" 
                  : `此藥物將在每週的 ${activeDays.map(d => WEEKDAYS.find(w => w.value === d)?.label).join('、')} 重複`}
              </p>
            </div>
          </div>
          
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              取消
            </Button>
            <Button type="submit">
              <Plus className="w-4 h-4 mr-2" />
              新增藥物
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
