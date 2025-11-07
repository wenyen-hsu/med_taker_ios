import { useState } from "react";
import { DayPicker } from "react-day-picker@8.10.1";
import { Card } from "./ui/card";
import { Badge } from "./ui/badge";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "./ui/button";
import { cn } from "./ui/utils";
import { buttonVariants } from "./ui/button";

interface CalendarViewProps {
  selectedDate: Date;
  onDateSelect: (date: Date) => void;
  onMonthChange?: (date: Date) => void;
  medicationRecords: Record<string, {
    total: number;
    completed: number;
    onTime: number;
    late: number;
    missed: number;
    skipped?: number;
    upcoming?: number;
  }>;
}

export function CalendarView({ selectedDate, onDateSelect, onMonthChange, medicationRecords }: CalendarViewProps) {
  const [currentMonth, setCurrentMonth] = useState(new Date());

  const getDayStatus = (date: Date) => {
    const dateKey = date.toISOString().split('T')[0];
    const record = medicationRecords[dateKey];
    
    if (!record || record.total === 0) return null;
    
    // For past dates, treat upcoming as missed
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const isPast = date < today;
    
    const actualMissed = isPast ? (record.missed || 0) + (record.upcoming || 0) : (record.missed || 0);
    const completed = record.completed || 0;
    const onTime = record.onTime || 0;
    const late = record.late || 0;
    
    // Calculate completion rate (excluding skipped from denominator)
    const totalRequired = record.total - (record.skipped || 0);
    if (totalRequired === 0) return null;
    
    const completionRate = (completed / totalRequired) * 100;
    
    let status;
    // Perfect: all completed and all on time
    if (completionRate === 100 && late === 0 && actualMissed === 0) {
      status = { color: "bg-green-500", label: "完美" };
    } 
    // Completed: all completed but some late
    else if (completionRate === 100 && actualMissed === 0) {
      status = { color: "bg-yellow-500", label: "完成" };
    } 
    // Partial: some completed
    else if (completed > 0) {
      status = { color: "bg-orange-500", label: "部分" };
    } 
    // Not completed: nothing completed
    else {
      status = { color: "bg-red-500", label: "未完成" };
    }
    
    // Debug logging for dates with records
    console.log(`📅 ${dateKey}: total=${record.total}, completed=${completed}, onTime=${onTime}, late=${late}, missed=${actualMissed} → ${status.label}`);
    
    return status;
  };

  const formatMonth = (date: Date) => {
    return date.toLocaleDateString('zh-TW', { year: 'numeric', month: 'long' });
  };

  const goToPreviousMonth = () => {
    const newMonth = new Date(currentMonth);
    newMonth.setMonth(newMonth.getMonth() - 1);
    setCurrentMonth(newMonth);
    if (onMonthChange) {
      onMonthChange(newMonth);
    }
  };

  const goToNextMonth = () => {
    const newMonth = new Date(currentMonth);
    newMonth.setMonth(newMonth.getMonth() + 1);
    setCurrentMonth(newMonth);
    if (onMonthChange) {
      onMonthChange(newMonth);
    }
  };

  return (
    <Card className="p-6">
      <div className="mb-4 flex items-center justify-center">
        <h2 className="text-lg">服藥日曆</h2>
      </div>

      <div className="flex justify-center">
        <DayPicker
        mode="single"
        selected={selectedDate}
        onSelect={(date) => date && onDateSelect(date)}
        month={currentMonth}
        onMonthChange={(newMonth) => {
          setCurrentMonth(newMonth);
          if (onMonthChange) {
            onMonthChange(newMonth);
          }
        }}
        showOutsideDays={true}
        className={cn("p-3")}
        classNames={{
          months: "flex flex-col sm:flex-row gap-2",
          month: "flex flex-col gap-4",
          caption: "flex justify-center pt-1 relative items-center w-full",
          caption_label: "text-sm font-medium",
          nav: "flex items-center gap-1",
          nav_button: cn(
            buttonVariants({ variant: "outline" }),
            "size-7 bg-transparent p-0 opacity-50 hover:opacity-100",
          ),
          nav_button_previous: "absolute left-1",
          nav_button_next: "absolute right-1",
          table: "w-full border-collapse space-x-1",
          head_row: "flex",
          head_cell:
            "text-muted-foreground rounded-md w-8 font-normal text-[0.8rem]",
          row: "flex w-full mt-2",
          cell: cn(
            "relative p-0 text-center text-sm focus-within:relative focus-within:z-20",
          ),
          day: cn(
            buttonVariants({ variant: "ghost" }),
            "size-8 p-0 font-normal aria-selected:opacity-100 relative hover:bg-blue-100 hover:scale-110 transition-all cursor-pointer",
          ),
          day_selected:
            "bg-primary text-primary-foreground hover:bg-primary hover:text-primary-foreground focus:bg-primary focus:text-primary-foreground",
          day_today: "bg-accent text-accent-foreground",
          day_outside:
            "day-outside text-muted-foreground aria-selected:text-muted-foreground",
          day_disabled: "text-muted-foreground opacity-50",
          day_hidden: "invisible",
        }}
        components={{
          IconLeft: ({ className, ...props }) => (
            <ChevronLeft className={cn("size-4", className)} {...props} />
          ),
          IconRight: ({ className, ...props }) => (
            <ChevronRight className={cn("size-4", className)} {...props} />
          ),
          Day: ({ date, displayMonth, ...props }) => {
            const status = getDayStatus(date);
            const isSelected = selectedDate?.toDateString() === date.toDateString();
            
            return (
              <button
                type="button"
                onClick={() => onDateSelect(date)}
                className={cn(
                  buttonVariants({ variant: "ghost" }),
                  "size-8 p-0 font-normal aria-selected:opacity-100 relative hover:bg-blue-100 hover:scale-110 transition-all cursor-pointer",
                  isSelected && "bg-primary text-primary-foreground hover:bg-primary hover:text-primary-foreground",
                  date.toDateString() === new Date().toDateString() && !isSelected && "bg-accent text-accent-foreground",
                  date.getMonth() !== currentMonth.getMonth() && "text-muted-foreground opacity-50"
                )}
              >
                <span className="relative z-10">{date.getDate()}</span>
                {status && !isSelected && (
                  <div className={`absolute bottom-0.5 left-1/2 -translate-x-1/2 w-1.5 h-1.5 rounded-full ${status.color}`} />
                )}
              </button>
            );
          },
        }}
      />
      </div>

      <div className="mt-6">
        <p className="text-sm text-gray-500 mb-3 text-center">點擊日期查看詳細記錄</p>
        <div className="flex flex-wrap justify-center gap-3 text-sm">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-green-500" />
            <span className="text-gray-600">完美達成（全部準時）</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-yellow-500" />
            <span className="text-gray-600">全部完成（有遲到）</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-orange-500" />
            <span className="text-gray-600">部分完成</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-red-500" />
            <span className="text-gray-600">未完成</span>
          </div>
        </div>
      </div>
    </Card>
  );
}
