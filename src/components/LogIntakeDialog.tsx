import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "./ui/dialog";
import { Button } from "./ui/button";
import { Label } from "./ui/label";
import { Input } from "./ui/input";
import { Textarea } from "./ui/textarea";

interface LogIntakeDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  medicationName: string;
  scheduledTime: string;
  onConfirm: (actualTime: string, notes: string) => void;
  isEditing?: boolean;
  initialActualTime?: string;
  initialNotes?: string;
}

export function LogIntakeDialog({
  open,
  onOpenChange,
  medicationName,
  scheduledTime,
  onConfirm,
  isEditing = false,
  initialActualTime,
  initialNotes,
}: LogIntakeDialogProps) {
  const getCurrentTime = () => {
    const now = new Date();
    return now.toTimeString().slice(0, 5);
  };

  const [actualTime, setActualTime] = useState(initialActualTime || getCurrentTime());
  const [notes, setNotes] = useState(initialNotes || "");

  // Update state when dialog opens or props change
  useEffect(() => {
    if (open) {
      setActualTime(initialActualTime || getCurrentTime());
      setNotes(initialNotes || "");
    }
  }, [open, initialActualTime, initialNotes]);

  const handleConfirm = () => {
    onConfirm(actualTime, notes);
    setNotes("");
    onOpenChange(false);
  };

  const handleUseNow = () => {
    setActualTime(getCurrentTime());
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEditing ? '修改服藥記錄' : '記錄服藥'}</DialogTitle>
          <DialogDescription>
            {isEditing ? `修改 ${medicationName} 的服藥時間` : `記錄 ${medicationName} 的服藥時間`}
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label>預定時間</Label>
            <div className="text-sm text-gray-600 bg-gray-50 p-3 rounded-md">
              {scheduledTime}
            </div>
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="actual-time">實際時間</Label>
            <div className="flex gap-2">
              <Input
                id="actual-time"
                type="time"
                value={actualTime}
                onChange={(e) => setActualTime(e.target.value)}
              />
              <Button type="button" variant="outline" onClick={handleUseNow}>
                現在
              </Button>
            </div>
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="notes">備註（選填）</Label>
            <Textarea
              id="notes"
              placeholder="輸入備註..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
            />
          </div>
        </div>
        
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            取消
          </Button>
          <Button onClick={handleConfirm}>
            {isEditing ? '儲存變更' : '確認記錄'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
