import { Hono } from "npm:hono";
import { cors } from "npm:hono/cors";
import { logger } from "npm:hono/logger";
import { createClient } from "npm:@supabase/supabase-js@2";
import * as kv from "./kv_store.tsx";

const app = new Hono();

app.use("*", cors());
app.use("*", logger(console.log));

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
);

// Helper function to check if a schedule should generate a medication for a given date
function shouldGenerateMedication(schedule: any, date: Date): boolean {
  // Get date string in YYYY-MM-DD format for comparison
  const dateStr = date.toISOString().split('T')[0];
  const startDateStr = schedule.startDate;
  const endDateStr = schedule.endDate;
  
  // Simple string comparison for dates in YYYY-MM-DD format
  if (dateStr < startDateStr) {
    return false;
  }
  if (endDateStr && dateStr > endDateStr) {
    return false;
  }
  if (!schedule.isActive) {
    return false;
  }
  
  if (schedule.frequency === "daily") {
    return true;
  } else if (schedule.frequency === "weekly") {
    const dayOfWeek = date.getDay();
    return schedule.activeDays?.includes(dayOfWeek) ?? false;
  }
  
  return false;
}

// Get all medication schedules
app.get("/make-server-3d52a703/schedules", async (c) => {
  try {
    const schedules = await kv.getByPrefix("schedule:");
    return c.json({ success: true, schedules });
  } catch (error) {
    console.error("Error fetching schedules:", error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Add a new medication schedule
app.post("/make-server-3d52a703/schedules", async (c) => {
  try {
    const body = await c.req.json();
    const { id, name, dosage, scheduledTime, frequency, activeDays, startDate, endDate, isActive } = body;

    if (!id || !name || !dosage || !scheduledTime || !frequency || !startDate) {
      return c.json(
        { success: false, error: "Missing required fields" },
        400
      );
    }

    const schedule = {
      id,
      name,
      dosage,
      scheduledTime,
      frequency,
      activeDays: activeDays || null,
      startDate,
      endDate: endDate || null,
      isActive: isActive ?? true,
    };

    await kv.set(`schedule:${id}`, schedule);
    return c.json({ success: true, schedule });
  } catch (error) {
    console.error("Error adding schedule:", error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Update a medication schedule
app.put("/make-server-3d52a703/schedules/:id", async (c) => {
  try {
    const id = c.req.param("id");
    const body = await c.req.json();

    const existing = await kv.get(`schedule:${id}`);
    if (!existing) {
      return c.json({ success: false, error: "Schedule not found" }, 404);
    }

    const updated = { ...existing, ...body };
    await kv.set(`schedule:${id}`, updated);

    return c.json({ success: true, schedule: updated });
  } catch (error) {
    console.error("Error updating schedule:", error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Delete a medication schedule
app.delete("/make-server-3d52a703/schedules/:id", async (c) => {
  try {
    const id = c.req.param("id");
    await kv.del(`schedule:${id}`);
    return c.json({ success: true });
  } catch (error) {
    console.error("Error deleting schedule:", error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Get daily medications for a specific date or date range
app.get("/make-server-3d52a703/daily-medications", async (c) => {
  try {
    const date = c.req.query("date");
    const startDate = c.req.query("startDate");
    const endDate = c.req.query("endDate");

    console.log(`📥 GET daily-medications request: date=${date}, startDate=${startDate}, endDate=${endDate}`);

    const schedules = await kv.getByPrefix("schedule:");
    const dailyRecords = await kv.getByPrefix("daily:");

    console.log(`📊 Retrieved ${schedules.length} schedules and ${dailyRecords.length} daily records from KV`);

    let medications: any[] = [];

    if (date) {
      // Single date query
      const targetDate = new Date(date);
      medications = await generateDailyMedications(schedules, dailyRecords, targetDate, targetDate);
    } else if (startDate && endDate) {
      // Date range query
      const start = new Date(startDate);
      const end = new Date(endDate);
      medications = await generateDailyMedications(schedules, dailyRecords, start, end);
    }

    console.log(`📤 Returning ${medications.length} medications`);
    return c.json({ success: true, medications });
  } catch (error) {
    console.error("❌ Error fetching daily medications:", error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

async function generateDailyMedications(schedules: any[], dailyRecords: any[], startDate: Date, endDate: Date) {
  const medications: any[] = [];
  const currentDate = new Date(startDate);

  console.log(`📋 Generating medications from ${startDate.toISOString()} to ${endDate.toISOString()}`);
  console.log(`📋 Found ${schedules.length} schedules and ${dailyRecords.length} daily records`);
  
  // Debug: log all daily records
  if (dailyRecords.length > 0) {
    console.log(`📋 Sample daily record:`, JSON.stringify(dailyRecords[0]));
  }

  while (currentDate <= endDate) {
    const dateStr = currentDate.toISOString().split('T')[0];

    for (const schedule of schedules) {
      const shouldGenerate = shouldGenerateMedication(schedule, currentDate);
      
      if (shouldGenerate) {
        const recordId = `${schedule.id}-${dateStr}`;
        const existingRecord = dailyRecords.find((r: any) => r.id === recordId);

        if (existingRecord) {
          console.log(`✅ Found existing record for ${schedule.name} on ${dateStr}: status=${existingRecord.status}`);
          medications.push(existingRecord);
        } else {
          console.log(`➕ Creating new record for ${schedule.name} on ${dateStr}`);
          // Generate default record
          medications.push({
            id: recordId,
            scheduleId: schedule.id,
            medicationName: schedule.name,
            dosage: schedule.dosage,
            scheduledTime: schedule.scheduledTime,
            date: dateStr,
            status: "upcoming",
            actualTime: null,
            notes: null,
          });
        }
      }
    }

    currentDate.setDate(currentDate.getDate() + 1);
  }

  console.log(`📋 Generated ${medications.length} total medication records`);
  return medications;
}

// Update a daily medication record
app.put("/make-server-3d52a703/daily-medications/:id", async (c) => {
  try {
    const id = c.req.param("id");
    const body = await c.req.json();

    console.log(`📝 Updating daily medication ${id} with:`, JSON.stringify(body));

    // Get existing record
    let existing = await kv.get(`daily:${id}`);
    
    if (existing) {
      console.log(`📋 Found existing record:`, JSON.stringify(existing));
    } else {
      console.log(`⚠️ No existing record found for ${id}, will create new one`);
      // If it doesn't exist, we need to reconstruct from the ID
      // ID format is: ${scheduleId}-${dateStr}
      const parts = id.split('-');
      if (parts.length >= 4) {
        // Extract date from ID (last 3 parts: YYYY-MM-DD)
        const dateStr = `${parts[parts.length - 3]}-${parts[parts.length - 2]}-${parts[parts.length - 1]}`;
        const scheduleId = parts.slice(0, parts.length - 3).join('-');
        
        // Get the schedule to fill in missing data
        const schedule = await kv.get(`schedule:${scheduleId}`);
        
        if (schedule) {
          existing = {
            id,
            scheduleId,
            medicationName: schedule.name,
            dosage: schedule.dosage,
            scheduledTime: schedule.scheduledTime,
            date: dateStr,
            status: "upcoming",
            actualTime: null,
            notes: null,
          };
          console.log(`📋 Created base record from schedule:`, JSON.stringify(existing));
        } else {
          console.log(`⚠️ Could not find schedule ${scheduleId}`);
          existing = { id };
        }
      } else {
        existing = { id };
      }
    }

    const updated = { ...existing, ...body, id };
    await kv.set(`daily:${id}`, updated);

    console.log(`✅ Successfully updated daily medication ${id}:`, JSON.stringify(updated));
    return c.json({ success: true, medication: updated });
  } catch (error) {
    console.error("❌ Error updating daily medication:", error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Delete daily medication record
app.delete("/make-server-3d52a703/daily-medications/:id", async (c) => {
  try {
    const id = c.req.param("id");
    await kv.del(`daily:${id}`);
    
    console.log(`Deleted daily medication record: ${id}`);
    return c.json({ success: true });
  } catch (error) {
    console.error("Error deleting daily medication:", error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Reset all daily medication records
app.post("/make-server-3d52a703/daily-medications/reset", async (c) => {
  try {
    const dailyRecords = await kv.getByPrefix("daily:");
    const recordIds = dailyRecords.map((record: any) => `daily:${record.id}`);
    
    if (recordIds.length > 0) {
      await kv.mdel(recordIds);
      console.log(`Reset ${recordIds.length} daily medication records`);
    }
    
    return c.json({ success: true, deletedCount: recordIds.length });
  } catch (error) {
    console.error("Error resetting daily medications:", error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

Deno.serve(app.fetch);
