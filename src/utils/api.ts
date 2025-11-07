import { projectId, publicAnonKey } from './supabase/info';

const API_BASE_URL = `https://${projectId}.supabase.co/functions/v1/make-server-3d52a703`;

async function apiCall(endpoint: string, options: RequestInit = {}) {
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${publicAnonKey}`,
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Unknown error' }));
    throw new Error(error.error || 'API request failed');
  }

  return response.json();
}

// Medication Schedule (template for recurring medications)
export interface MedicationSchedule {
  id: string;
  name: string;
  dosage: string;
  scheduledTime: string;
  frequency: "daily" | "weekly" | "custom";
  activeDays?: number[]; // 0-6 for weekly, Sunday = 0
  startDate: string;
  endDate?: string;
  isActive: boolean;
}

// Daily Medication Record (actual daily instance)
export interface DailyMedicationRecord {
  id: string;
  scheduleId: string;
  medicationName: string;
  dosage: string;
  scheduledTime: string;
  date: string; // YYYY-MM-DD
  status: "upcoming" | "on-time" | "late" | "missed" | "skipped";
  actualTime?: string;
  notes?: string;
}

export async function getMedicationSchedules(): Promise<MedicationSchedule[]> {
  const result = await apiCall('/schedules');
  return result.schedules || [];
}

export async function addMedicationSchedule(schedule: MedicationSchedule): Promise<MedicationSchedule> {
  const result = await apiCall('/schedules', {
    method: 'POST',
    body: JSON.stringify(schedule),
  });
  return result.schedule;
}

export async function updateMedicationSchedule(id: string, updates: Partial<MedicationSchedule>): Promise<MedicationSchedule> {
  const result = await apiCall(`/schedules/${id}`, {
    method: 'PUT',
    body: JSON.stringify(updates),
  });
  return result.schedule;
}

export async function deleteMedicationSchedule(id: string): Promise<void> {
  await apiCall(`/schedules/${id}`, {
    method: 'DELETE',
  });
}

export async function getDailyMedications(date: string): Promise<DailyMedicationRecord[]> {
  const result = await apiCall(`/daily-medications?date=${date}`);
  return result.medications || [];
}

export async function getDailyMedicationsRange(startDate: string, endDate: string): Promise<DailyMedicationRecord[]> {
  const result = await apiCall(`/daily-medications?startDate=${startDate}&endDate=${endDate}`);
  return result.medications || [];
}

export async function updateDailyMedication(id: string, updates: Partial<DailyMedicationRecord>): Promise<DailyMedicationRecord> {
  const result = await apiCall(`/daily-medications/${id}`, {
    method: 'PUT',
    body: JSON.stringify(updates),
  });
  return result.medication;
}

export async function deleteDailyMedication(id: string): Promise<void> {
  await apiCall(`/daily-medications/${id}`, {
    method: 'DELETE',
  });
}

export async function resetAllDailyMedications(): Promise<{ deletedCount: number }> {
  const result = await apiCall('/daily-medications/reset', {
    method: 'POST',
  });
  return result;
}
