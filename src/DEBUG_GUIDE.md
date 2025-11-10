# 燈號同步調試指南

## 問題描述
標記完成後紅點會消失而不是變綠色

## 調試步驟

### 1. 打開瀏覽器控制台
按 F12 或右鍵選擇"檢查"，切換到 Console 標籤

### 2. 記錄服藥並觀察日誌

當你點擊"記錄服藥"並確認後，應該看到以下日誌順序：

#### 前端日誌：
```
💊 Updating medication {id}: {status: "on-time", actualTime: "...", notes: "..."}
✅ Update successful, reloading data...
🔄 Reloading month records for YYYY-MM-DD...
📅 Loading medications for range: YYYY-MM-01 to YYYY-MM-31
📊 Total medications received: X
📈 Medication records by date: {...}
✅ Updated medication records state
🔄 Reloading daily medications...
📅 Loading daily medications for YYYY-MM-DD...
📅 Received X medications: [{id: "...", status: "on-time"}, ...]
✅ Daily medications updated
✅ All data reloaded
```

#### 後端日誌（在 Supabase Functions 日誌中）：
```
📝 Updating daily medication {id} with: {...}
📋 Found existing record: {...} OR ⚠️ No existing record found...
✅ Successfully updated daily medication {id}: {...}
📥 GET daily-medications request: ...
📊 Retrieved X schedules and Y daily records from KV
📋 Generating medications from ... to ...
✅ Found existing record for {name} on {date}: status=on-time
📋 Generated X total medication records
```

#### CalendarView 日誌：
```
📅 YYYY-MM-DD: total=X, completed=Y, onTime=Z, late=0, missed=0 → 完美
```

### 3. 檢查點

#### ✅ 更新是否成功？
- 查看是否有 "✅ Successfully updated daily medication" 日誌
- 檢查更新後的記錄是否包含正確的 status: "on-time"

#### ✅ 重新查詢是否找到更新後的記錄？
- 查看 "✅ Found existing record" 日誌
- 確認 status 是 "on-time" 而不是 "upcoming"

#### ✅ 統計數據是否正確？
- 查看 "📈 Medication records by date" 日誌
- 確認該日期的統計：completed=總數, onTime=總數, late=0, missed=0

#### ✅ 日曆狀態是否正確？
- 查看 CalendarView 的日誌，確認顯示 "→ 完美"

### 4. 常見問題排查

#### 問題 A: 更新後查詢找不到記錄
**症狀**: 看到 "➕ Creating new record" 而不是 "✅ Found existing record"

**可能原因**:
- KV store 的 key 格式不一致
- 記錄 ID 格式問題

**解決方案**: 檢查後端日誌中的 record ID 格式

#### 問題 B: 找到記錄但 status 還是 "upcoming"
**症狀**: "✅ Found existing record" 但 status 不是 "on-time"

**可能原因**:
- 更新沒有正確保存到 KV
- 查詢到的是舊數據

**解決方案**: 檢查 KV set 操作是否成功

#### 問題 C: 統計數據不正確
**症狀**: completed 或 onTime 數量為 0

**可能原因**:
- loadMonthRecords 的計算邏輯有問題
- 返回的記錄 status 欄位不正確

**解決方案**: 檢查 "📊 Total medications received" 和統計計算邏輯

## 預期結果

當所有藥物都準時服用時：
- 🟢 綠色點：total=X, completed=X, onTime=X, late=0, missed=0
- 狀態標籤：完美（全部準時）

當都服用但有遲到時：
- 🟡 黃色點：total=X, completed=X, onTime=Y, late=Z, missed=0
- 狀態標籤：完成（有遲到）

## 下一步

如果問題仍然存在，請提供：
1. 完整的控制台日誌
2. 具體的操作步驟
3. 預期行為 vs 實際行為的描述
