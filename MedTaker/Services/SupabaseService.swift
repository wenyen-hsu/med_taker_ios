import Foundation

/// Supabase API 服務層
class SupabaseService {
    static let shared = SupabaseService()

    private let projectId = "yrfxmlzgczwrcxepqegp"
    private let publicAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyZnhtbHpnY3p3cmN4ZXBxZWdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU0NjUxNDIsImV4cCI6MjA1MTA0MTE0Mn0.L9NG_ZqpDGK4PHXSKuaZFtB1Eo_jB8O8BwRCNVx1gHA"
    private let apiBaseURL: String

    private init() {
        apiBaseURL = "https://\(projectId).supabase.co/functions/v1/make-server-3d52a703"
    }

    // MARK: - 通用 API 調用

    private func apiCall<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(apiBaseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(publicAnonKey)", forHTTPHeaderField: "Authorization")

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(T.self, from: data)
    }

    // MARK: - 排程 API

    /// 獲取所有排程
    func fetchSchedules() async throws -> [MedicationSchedule] {
        struct Response: Decodable {
            let success: Bool
            let schedules: [[String: Any]]

            private enum CodingKeys: String, CodingKey {
                case success, schedules
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                success = try container.decode(Bool.self, forKey: .success)

                // 手動解析 schedules
                let schedulesArray = try container.decode([[String: AnyCodable]].self, forKey: .schedules)
                schedules = schedulesArray.map { dict in
                    dict.mapValues { $0.value }
                }
            }
        }

        let response: Response = try await apiCall(endpoint: "/schedules")

        return response.schedules.compactMap { MedicationSchedule.fromAPIResponse($0) }
    }

    /// 新增排程
    func addSchedule(_ schedule: MedicationSchedule) async throws {
        struct Response: Decodable {
            let success: Bool
        }

        let _: Response = try await apiCall(
            endpoint: "/schedules",
            method: "POST",
            body: schedule.toAPIFormat()
        )
    }

    /// 更新排程
    func updateSchedule(_ schedule: MedicationSchedule) async throws {
        struct Response: Decodable {
            let success: Bool
        }

        let _: Response = try await apiCall(
            endpoint: "/schedules/\(schedule.id)",
            method: "PUT",
            body: schedule.toAPIFormat()
        )
    }

    /// 刪除排程
    func deleteSchedule(id: String) async throws {
        struct Response: Decodable {
            let success: Bool
        }

        let _: Response = try await apiCall(
            endpoint: "/schedules/\(id)",
            method: "DELETE"
        )
    }

    // MARK: - 記錄 API

    /// 獲取指定日期的記錄
    func fetchDailyRecords(for date: Date) async throws -> [DailyMedicationRecord] {
        struct Response: Decodable {
            let success: Bool
            let medications: [[String: Any]]

            private enum CodingKeys: String, CodingKey {
                case success, medications
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                success = try container.decode(Bool.self, forKey: .success)

                let medicationsArray = try container.decode([[String: AnyCodable]].self, forKey: .medications)
                medications = medicationsArray.map { dict in
                    dict.mapValues { $0.value }
                }
            }
        }

        let dateStr = date.dateString()
        let response: Response = try await apiCall(endpoint: "/daily-medications?date=\(dateStr)")

        return response.medications.compactMap { DailyMedicationRecord.fromAPIResponse($0) }
    }

    /// 獲取日期範圍內的記錄
    func fetchRecordsRange(from startDate: Date, to endDate: Date) async throws -> [DailyMedicationRecord] {
        struct Response: Decodable {
            let success: Bool
            let medications: [[String: Any]]

            private enum CodingKeys: String, CodingKey {
                case success, medications
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                success = try container.decode(Bool.self, forKey: .success)

                let medicationsArray = try container.decode([[String: AnyCodable]].self, forKey: .medications)
                medications = medicationsArray.map { dict in
                    dict.mapValues { $0.value }
                }
            }
        }

        let startStr = startDate.dateString()
        let endStr = endDate.dateString()
        let response: Response = try await apiCall(
            endpoint: "/daily-medications?startDate=\(startStr)&endDate=\(endStr)"
        )

        return response.medications.compactMap { DailyMedicationRecord.fromAPIResponse($0) }
    }

    /// 更新記錄
    func updateRecord(_ record: DailyMedicationRecord) async throws {
        struct Response: Decodable {
            let success: Bool
        }

        let _: Response = try await apiCall(
            endpoint: "/daily-medications/\(record.id)",
            method: "PUT",
            body: record.toAPIFormat()
        )
    }

    /// 刪除記錄
    func deleteRecord(id: String) async throws {
        struct Response: Decodable {
            let success: Bool
        }

        let _: Response = try await apiCall(
            endpoint: "/daily-medications/\(id)",
            method: "DELETE"
        )
    }

    /// 重置所有記錄
    func resetAllRecords() async throws -> Int {
        struct Response: Decodable {
            let deletedCount: Int
        }

        let response: Response = try await apiCall(
            endpoint: "/daily-medications/reset",
            method: "POST"
        )

        return response.deletedCount
    }
}

// MARK: - 錯誤類型

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 URL"
        case .invalidResponse:
            return "無效的回應"
        case .httpError(let code):
            return "HTTP 錯誤：\(code)"
        case .decodingError:
            return "資料解析錯誤"
        case .networkError(let error):
            return "網路錯誤：\(error.localizedDescription)"
        }
    }
}

// MARK: - 輔助類型（用於解析動態 JSON）

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "不支援的類型")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "不支援的類型")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
