import SwiftUI

struct HistoryView: View {
    @Environment(TicketStore.self)       private var ticketStore
    @Environment(LocalizationManager.self) private var lm

    @State private var searchText  = ""
    @State private var showReport  = false

    private var filtered: [ParkingTicket] {
        let all = ticketStore.historyTickets
        guard !searchText.isEmpty else { return all }
        let q = searchText.lowercased()
        return all.filter {
            $0.customerFullName.lowercased().contains(q) ||
            $0.vehicle.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.gray)
                        TextField(lm["history.search"], text: $searchText)
                            .foregroundStyle(.white).tint(.green)
                    }
                    .padding(10)
                    .background(Color(UIColor.systemGray6).opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal).padding(.top, 8).padding(.bottom, 12)

                    if filtered.isEmpty {
                        Spacer()
                        Text(searchText.isEmpty ? lm["history.empty"] : lm["history.no_results"])
                            .foregroundStyle(.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { ticket in
                                    NavigationLink(destination: CarDetailsView(ticket: ticket)) {
                                        HistoryRowView(ticket: ticket)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal).padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle(lm["tab.history"])
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showReport = true
                    } label: {
                        Label(lm["history.report_btn"], systemImage: "chart.bar.doc.horizontal")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.green)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.green.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .sheet(isPresented: $showReport) {
            ReportSheetView(allTickets: ticketStore.historyTickets)
        }
    }
}

struct HistoryRowView: View {
    let ticket: ParkingTicket
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(ticket.customerFullName).font(.headline).foregroundStyle(.white)
                Spacer()
                StatusBadge(status: ticket.status)
            }
            Text(ticket.vehicle).font(.subheadline).foregroundStyle(.gray)
            HStack {
                Label(ticket.parkingZone, systemImage: "mappin")
                    .font(.caption).foregroundStyle(.gray)
                Spacer()
                Text(ticket.checkedInAt, style: .relative)
                    .font(.caption).foregroundStyle(.gray)
                + Text(" \(lm["history.ago"])")
                    .font(.caption).foregroundStyle(.gray)
            }
        }
        .padding(14)
        .background(Color(UIColor.systemGray6).opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}
