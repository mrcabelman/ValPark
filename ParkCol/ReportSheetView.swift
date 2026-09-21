import SwiftUI

struct ReportSheetView: View {
    let allTickets: [ParkingTicket]
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(LocalizationManager.self) private var lm

    @State private var selectedZone = ""
    @State private var fromDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var fromTime = Calendar.current.startOfDay(for: Date())
    @State private var toDate   = Date()
    @State private var toTime: Date = {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = 23; c.minute = 59
        return Calendar.current.date(from: c) ?? Date()
    }()
    @State private var reportGenerated = false
    @State private var showZonePicker  = false

    private var zoneLabel: String {
        selectedZone.isEmpty ? lm["report.all_zones"] : selectedZone
    }

    private var stats: (total: Int, delivered: Int, cancelled: Int, revenue: Double) {
        let from = combined(fromDate, fromTime)
        let to   = combined(toDate,   toTime)
        let list = allTickets.filter {
            $0.checkedInAt >= from && $0.checkedInAt <= to &&
            (selectedZone.isEmpty || $0.parkingZone == selectedZone)
        }
        let delivered = list.filter { $0.status == .delivered }.count
        let cancelled = list.filter { $0.status == .cancelled }.count
        let revenue   = list.filter { $0.status == .delivered }.reduce(0.0) { $0 + $1.amount }
        return (list.count, delivered, cancelled, revenue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Location
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lm["report.location"]).font(.caption).foregroundStyle(.gray)
                            Button { showZonePicker = true } label: {
                                HStack {
                                    Text(zoneLabel).foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.gray).font(.caption)
                                }
                                .padding()
                                .background(Color(UIColor.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        // From
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lm["report.from"]).font(.caption).foregroundStyle(.gray)
                            HStack(spacing: 10) {
                                DatePicker("", selection: $fromDate, displayedComponents: .date)
                                    .labelsHidden().datePickerStyle(.compact).tint(.green)
                                    .padding(10).background(Color(UIColor.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10)).frame(maxWidth: .infinity)
                                DatePicker("", selection: $fromTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden().datePickerStyle(.compact).tint(.green)
                                    .padding(10).background(Color(UIColor.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10)).frame(maxWidth: .infinity)
                            }
                        }

                        // To
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lm["report.to"]).font(.caption).foregroundStyle(.gray)
                            HStack(spacing: 10) {
                                DatePicker("", selection: $toDate, displayedComponents: .date)
                                    .labelsHidden().datePickerStyle(.compact).tint(.green)
                                    .padding(10).background(Color(UIColor.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10)).frame(maxWidth: .infinity)
                                DatePicker("", selection: $toTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden().datePickerStyle(.compact).tint(.green)
                                    .padding(10).background(Color(UIColor.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10)).frame(maxWidth: .infinity)
                            }
                        }

                        // Generate
                        Button { withAnimation { reportGenerated = true } } label: {
                            Label(lm["report.generate"], systemImage: "chart.bar")
                                .font(.body.weight(.semibold)).foregroundStyle(.black)
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Stats
                        if reportGenerated {
                            let s = stats
                            HStack(spacing: 10) {
                                StatCell(value: "\(s.total)",                          label: lm["report.total"],     color: .white)
                                StatCell(value: "\(s.delivered)",                      label: lm["report.delivered"], color: .green)
                                StatCell(value: "\(s.cancelled)",                      label: lm["report.cancelled"], color: .red)
                                StatCell(value: String(format: "$%.2f", s.revenue),    label: lm["report.revenue"],   color: .white)
                            }
                            if s.total == 0 {
                                Text(lm["report.empty"])
                                    .font(.subheadline).foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center).padding(.top, 8)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(lm["report.title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lm["report.done"]) { dismiss() }.foregroundStyle(.green)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showZonePicker) {
            let zoneOptions = [lm["report.all_zones"]] + appSettings.parkingZones
            PickerSheet(title: lm["picker.location_title"],
                        options: [""] + appSettings.parkingZones,
                        displayOptions: zoneOptions,
                        selected: $selectedZone)
        }
    }

    private func combined(_ date: Date, _ time: Date) -> Date {
        let cal = Calendar.current
        var d = cal.dateComponents([.year, .month, .day], from: date)
        let t = cal.dateComponents([.hour, .minute], from: time)
        d.hour = t.hour; d.minute = t.minute
        return cal.date(from: d) ?? date
    }
}

struct StatCell: View {
    let value: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline.weight(.bold)).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Color(UIColor.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
