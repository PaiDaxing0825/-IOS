import SwiftUI
import Charts

@main
struct HRVCompanionApp: App {
    var body: some Scene { WindowGroup { Dashboard() } }
}

struct Dashboard: View {
    @StateObject private var health = HealthStore()
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("给自己一点呼吸的空间", systemImage: "leaf.fill")
                            .font(.headline).foregroundStyle(.teal)
                        Text("最新 HRV · SDNN").foregroundStyle(.secondary)
                        if let latest = health.readings.first {
                            HStack(alignment: .firstTextBaseline) {
                                Text(latest.milliseconds, format: .number.precision(.fractionLength(1)))
                                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                                Text("毫秒").foregroundStyle(.secondary)
                            }
                            Text(latest.date.formatted(date: .abbreviated, time: .shortened))
                            Text("来源：\(latest.source)").font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("—").font(.system(size: 52, weight: .semibold))
                            Text("等待真实健康数据").foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 10)
                }
                Section("连接状态") {
                    Text(health.message).font(.subheadline)
                    Button {
                        Task { await health.connect() }
                    } label: {
                        HStack {
                            if health.isLoading { ProgressView() }
                            Text(health.isLoading ? "正在读取…" : "连接 / 刷新苹果健康")
                        }
                    }.disabled(health.isLoading)
                    if let refresh = health.lastRefresh {
                        Text("上次读取：\(refresh.formatted(date: .omitted, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                if !health.readings.isEmpty {
                    Section("最近七天 · 每次测量") {
                        Chart(health.readings.sorted { $0.date < $1.date }) { reading in
                            PointMark(x: .value("时间", reading.date), y: .value("SDNN（毫秒）", reading.milliseconds))
                                .foregroundStyle(.teal)
                        }.frame(height: 200).accessibilityLabel("最近七天 HRV 散点图，下方提供每条记录")
                    }
                    Section("测量记录") {
                        ForEach(health.readings) { reading in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(reading.date.formatted(date: .abbreviated, time: .shortened))
                                    Spacer()
                                    Text("\(reading.milliseconds, specifier: "%.1f") ms").monospacedDigit()
                                }
                                Text(reading.source).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("关于验证版") {
                    Text("仅读取已同步到苹果健康的记录，不会启动手表测量。HRV 随测量条件变化，不能直接当作心理压力诊断。")
                    Text("不注册、不上传、不写入健康数据。当前数据仅保存在运行内存中。")
                    Text("没有记录？请先在健康 App → 心脏 → 心率变异性确认数据，并检查健康 App 的应用读取权限。")
                }.font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("心息")
            .tint(.teal)
        }
    }
}
