import Foundation
import Combine
import HealthKit

struct HRVReading: Identifiable {
    let id: UUID
    let date: Date
    let milliseconds: Double
    let source: String
}

@MainActor
final class HealthStore: ObservableObject {
    @Published private(set) var readings: [HRVReading] = []
    @Published private(set) var isLoading = false
    @Published private(set) var message = "连接苹果健康，查看手表已记录的 HRV。"
    @Published private(set) var lastRefresh: Date?
    private let store = HKHealthStore()

    func importFile(_ url: URL) {
        guard !isLoading else { return }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 2_000_000 else { throw HRVFile.Invalid(errorDescription: "文件超过 2 MB，请只导出最近七天。") }
            let parsed = try HRVFile.parse(String(contentsOf: url, encoding: .utf8))
            let now = Date()
            let start = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            let recent = parsed.filter { $0.date >= start && $0.date <= now }
            guard !recent.isEmpty else { throw HRVFile.Invalid(errorDescription: "文件中没有最近七天的记录，请检查导出日期。") }
            readings = recent
            lastRefresh = now
            message = "已导入 \(recent.count) 条最近七天记录。此方式需手动导入，不会自动同步。"
        } catch {
            message = "导入失败（已有记录未更改）：\(error.localizedDescription)"
        }
    }

    func connect() async {
        guard !isLoading else { return }
        guard HKHealthStore.isHealthDataAvailable(),
              let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            message = "此设备无法使用健康数据。请在真实 iPhone 上验证。"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await store.requestAuthorization(toShare: [], read: [type])
            let now = Date()
            let start = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
                let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
                let query = HKSampleQuery(sampleType: type, predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, results, error in
                        if let error { continuation.resume(throwing: error) }
                        else { continuation.resume(returning: results as? [HKQuantitySample] ?? []) }
                    }
                store.execute(query)
            }
            readings = samples.compactMap { sample in
                let value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                guard value.isFinite, value > 0 else { return nil }
                return HRVReading(id: sample.uuid, date: sample.startDate,
                    milliseconds: value, source: sample.sourceRevision.source.name)
            }
            lastRefresh = now
            message = readings.isEmpty
                ? "最近七天没有可读取的记录。可能尚未同步、没有测量，或未允许读取。苹果不会向 App 区分这些情况。"
                : "已读取最近七天的 \(readings.count) 条记录。"
        } catch {
            message = "读取失败（已有记录未更改）：\(error.localizedDescription)。如果提示缺少 HealthKit entitlement，请改用文件导入；手机设置无法补充签名权限。"
        }
    }
}
