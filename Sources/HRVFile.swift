import Foundation

enum HRVFile {
    struct Invalid: LocalizedError {
        let errorDescription: String?
    }
    // Deliberately narrow format: ISO 8601 timestamp, milliseconds; no quoted CSV fields.
    static func parse(_ text: String) throws -> [HRVReading] {
        let formatter = ISO8601DateFormatter()
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var values: [HRVReading] = []
        var seen = Set<String>()
        let lines = text.replacingOccurrences(of: "\u{FEFF}", with: "").components(separatedBy: .newlines)
        guard lines.count <= 20000 else { throw Invalid(errorDescription: "记录过多，请只导出最近七天。") }
        for (index, raw) in lines.enumerated() {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line == "date,sdnn_ms" { continue }
            let fields = line.split(separator: ",", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
            guard fields.count == 2,
                  let date = fractional.date(from: fields[0]) ?? formatter.date(from: fields[0]),
                  let value = Double(fields[1]), value.isFinite, value > 0 else {
                throw Invalid(errorDescription: "第 \(index + 1) 行格式不正确。需要 ISO 8601 日期和毫秒数值，以英文逗号分隔。")
            }
            let key = "\(date.timeIntervalSince1970)|\(value)"
            if seen.insert(key).inserted {
                values.append(HRVReading(id: UUID(), date: date, milliseconds: value, source: "文件导入 · 原始设备未验证"))
            }
        }
        guard !values.isEmpty else { throw Invalid(errorDescription: "文件没有有效的 HRV 记录。") }
        return values.sorted { $0.date > $1.date }
    }
}
