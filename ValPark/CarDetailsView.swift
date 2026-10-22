import SwiftUI

struct CarDetailsView: View {
    @Environment(\.dismiss)             private var dismiss
    @Environment(TicketStore.self)      private var ticketStore
    @Environment(LocalizationManager.self) private var lm
    let ticket: ParkingTicket

    @State private var showCancelConfirm = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ticket.customerFullName)
                                .font(.title.weight(.bold)).foregroundStyle(.white)
                            Text(ticket.vehicle.uppercased())
                                .font(.subheadline).foregroundStyle(.gray)
                        }
                        Spacer()
                    }

                    // Location & phone
                    VStack(alignment: .leading, spacing: 14) {
                        Label(ticket.parkingZone, systemImage: "mappin.circle")
                            .foregroundStyle(.white)
                        Divider().background(Color.white.opacity(0.1))
                        Button {
                            if let url = URL(string: "tel://\(ticket.phoneNumber)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("+\(ticket.phoneNumber)", systemImage: "phone")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.systemGray6).opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Payment
                    VStack(alignment: .leading, spacing: 14) {
                        Label(ticket.paymentMethod.localized(lm), systemImage: "creditcard")
                            .foregroundStyle(.white)
                        Divider().background(Color.white.opacity(0.1))
                        Label(String(format: "$%.2f", ticket.amount), systemImage: "dollarsign.circle")
                            .foregroundStyle(.green)
                    }
                    .padding(16)
                    .background(Color(UIColor.systemGray6).opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Timeline
                    TimelineCard(ticket: ticket)

                    // Notes
                    if !ticket.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lm["details.notes_label"])
                                .font(.caption).foregroundStyle(.gray)
                            Text(ticket.notes).foregroundStyle(.white)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.systemGray6).opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Action buttons
                    if ticket.status != .delivered && ticket.status != .cancelled {
                        VStack(spacing: 12) {
                            if ticket.status != .onTheWay {
                                Button { advanceStatus() } label: {
                                    Label(advanceTitle, systemImage: "arrow.right.circle")
                                        .font(.body.weight(.semibold)).foregroundStyle(.white)
                                        .frame(maxWidth: .infinity).padding()
                                        .background(Color(UIColor.systemGray5))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                            Button { checkOutVehicle() } label: {
                                Label(lm["details.check_out"], systemImage: "checkmark")
                                    .font(.body.weight(.semibold)).foregroundStyle(.black)
                                    .frame(maxWidth: .infinity).padding()
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            Button { showCancelConfirm = true } label: {
                                Text(lm["details.cancel_ticket"])
                                    .font(.body.weight(.semibold)).foregroundStyle(.red)
                                    .frame(maxWidth: .infinity).padding()
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red, lineWidth: 1))
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { StatusBadge(status: ticket.status) }
        }
        .confirmationDialog(lm["details.cancel_confirm"],
                            isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button(lm["details.cancel_ticket"], role: .destructive) {
                ticketStore.cancel(ticket: ticket)
                dismiss()
            }
            Button(lm["details.keep"], role: .cancel) {}
        }
    }

    private var advanceTitle: String {
        switch ticket.status {
        case .parked:       return lm["details.mark_car_requested"]
        case .carRequested: return lm["details.mark_on_the_way"]
        default:            return ""
        }
    }

    private func advanceStatus() {
        switch ticket.status {
        case .parked:       ticketStore.updateStatus(ticketId: ticket.id, status: .carRequested)
        case .carRequested: ticketStore.updateStatus(ticketId: ticket.id, status: .onTheWay)
        default: break
        }
    }

    private func checkOutVehicle() {
        ticketStore.checkOut(ticket: ticket)
        dismiss()
    }
}

// MARK: - TimelineCard (unchanged)

struct TimelineCard: View {
    let ticket: ParkingTicket
    @Environment(LocalizationManager.self) private var lm

    private var steps: [(TicketStatus, String)] {
        [(.parked,       lm["details.checked_in"]),
         (.carRequested, lm["status.car_requested"]),
         (.onTheWay,     lm["status.on_the_way"]),
         (.delivered,    lm["status.delivered"])]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lm["details.timeline"])
                .font(.caption).foregroundStyle(.gray).padding(.bottom, 12)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(isCompleted(step.0) ? Color.green : Color.gray.opacity(0.4))
                            .frame(width: 12, height: 12).padding(.top, 4)
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(isCompleted(step.0) && isCompleted(steps[index+1].0)
                                      ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 2, height: 32)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.1)
                            .font(.body.weight(isCompleted(step.0) ? .semibold : .regular))
                            .foregroundStyle(isCompleted(step.0) ? .white : .gray)
                        if step.0 == .parked {
                            Text(ticket.checkedInAt, style: .time)
                                .font(.caption).foregroundStyle(.green)
                        } else if step.0 == .delivered, let d = ticket.deliveredAt {
                            Text(d, style: .time).font(.caption).foregroundStyle(.green)
                        }
                    }
                    .padding(.bottom, index < steps.count - 1 ? 20 : 0)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemGray6).opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func isCompleted(_ s: TicketStatus) -> Bool {
        let order: [TicketStatus] = [.parked, .carRequested, .onTheWay, .delivered]
        return (order.firstIndex(of: s) ?? 0) <= (order.firstIndex(of: ticket.status) ?? 0)
    }
}
