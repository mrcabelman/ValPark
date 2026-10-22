import SwiftUI

struct ActiveView: View {
    @Environment(TicketStore.self)       private var ticketStore
    @Environment(OrganizationStore.self) private var orgStore
    @Environment(LocalizationManager.self) private var lm

    @State private var showAddTicket   = false
    @State private var showOrgSwitcher = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.black.ignoresSafeArea()

                if ticketStore.activeTickets.isEmpty {
                    VStack {
                        Spacer()
                        Text(lm["active.empty"])
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(ticketStore.activeTickets) { ticket in
                                NavigationLink(destination: CarDetailsView(ticket: ticket)) {
                                    TicketRowView(ticket: ticket)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }

                // FAB
                Button { showAddTicket = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
            .navigationTitle(orgStore.currentOrg?.name ?? lm["tab.active"])
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Active ticket count
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !ticketStore.activeTickets.isEmpty {
                        Text("\(ticketStore.activeTickets.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
                // Org switcher (only visible when user has multiple orgs)
                ToolbarItem(placement: .navigationBarLeading) {
                    if orgStore.myOrgs.count > 1 {
                        Button {
                            showOrgSwitcher = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2")
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTicket)   { AddTicketView() }
        .sheet(isPresented: $showOrgSwitcher) { OrgSwitcherSheet() }
    }
}

// MARK: - Org switcher sheet

struct OrgSwitcherSheet: View {
    @Environment(OrganizationStore.self) private var orgStore
    @Environment(LocalizationManager.self) private var lm
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6).ignoresSafeArea()
                List(orgStore.myOrgs) { org in
                    Button {
                        orgStore.selectOrg(org)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(org.name).foregroundStyle(.primary).font(.headline)
                                Text(org.myRole == .admin ? lm["orgs.role_admin"] : lm["orgs.role_member"])
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if orgStore.currentOrg?.id == org.id {
                                Image(systemName: "checkmark").foregroundStyle(.green)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
            .navigationTitle(lm["orgs.switcher_title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lm["picker.done"]) { dismiss() }.foregroundStyle(.green)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - TicketRowView (unchanged from original)

struct TicketRowView: View {
    let ticket: ParkingTicket
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        TimelineView(.periodic(from: ticket.checkedInAt, by: 1)) { context in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(ticket.customerFullName.uppercased())
                        .font(.headline).foregroundStyle(.white)
                    Spacer()
                    StatusBadge(status: ticket.status)
                }
                Text(ticket.vehicle)
                    .font(.subheadline).foregroundStyle(.gray)
                HStack(spacing: 12) {
                    Label(ticket.parkingZone, systemImage: "mappin")
                        .font(.caption).foregroundStyle(.gray)
                    Text(ticket.paymentTiming.localizedDisplay(lm))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(paymentColor)
                    Spacer()
                    Label(elapsed(at: context.date), systemImage: "clock")
                        .font(.caption).foregroundStyle(.green)
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.systemGray6).opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    private var paymentColor: Color {
        switch ticket.paymentTiming {
        case .payBefore: return .green
        case .payHalf:   return .yellow
        case .payAfter:  return .orange
        }
    }

    private func elapsed(at now: Date) -> String {
        let s = Int(now.timeIntervalSince(ticket.checkedInAt))
        if s < 60   { return "\(s)s" }
        if s < 3600 { return "\(s/60)m" }
        return "\(s/3600)h"
    }
}

// MARK: - StatusBadge (unchanged from original)

struct StatusBadge: View {
    let status: TicketStatus
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        Text(status.localized(lm))
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .parked:       return .blue
        case .carRequested: return .orange
        case .onTheWay:     return .yellow
        case .delivered:    return .green
        case .cancelled:    return .red
        }
    }
}
