import Foundation
import Observation
import FirebaseFirestore

// MARK: - TicketStore
//
// Replaces SwiftData @Query. Listens to the Firestore tickets subcollection
// for the active organization and provides CRUD operations.
// Called from MainTabView.onChange(of: orgStore.currentOrg?.id).

@Observable
@MainActor
final class TicketStore {

    // MARK: - State

    var tickets: [ParkingTicket] = []
    var errorMessage: String?

    // Filtered views (derive from tickets array to avoid duplicate listeners)
    var activeTickets: [ParkingTicket] {
        tickets
            .filter { $0.status != .delivered && $0.status != .cancelled }
            .sorted { $0.checkedInAt > $1.checkedInAt }
    }

    var historyTickets: [ParkingTicket] {
        tickets
            .filter { $0.status == .delivered || $0.status == .cancelled }
            .sorted { $0.checkedInAt > $1.checkedInAt }
    }

    // MARK: - Private

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private(set) var currentOrgId: String?

    // MARK: - Listener lifecycle

    func listen(orgId: String) {
        guard orgId != currentOrgId else { return }
        stopListening()
        currentOrgId = orgId

        listener = db.collection("organizations/\(orgId)/tickets")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.tickets = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: ParkingTicket.self)
                } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        currentOrgId = nil
        tickets = []
    }

    // MARK: - Create

    func create(_ ticket: ParkingTicket) {
        guard let orgId = currentOrgId else { return }
        let ref = db.collection("organizations/\(orgId)/tickets").document(ticket.id)
        do {
            try ref.setData(from: ticket)
            NotificationManager.scheduleReminders(for: ticket)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Update status

    func updateStatus(ticketId: String, status: TicketStatus) {
        guard let orgId = currentOrgId else { return }
        db.collection("organizations/\(orgId)/tickets").document(ticketId)
            .updateData(["statusRaw": status.rawValue])
    }

    // MARK: - Check out

    func checkOut(ticket: ParkingTicket) {
        guard let orgId = currentOrgId else { return }
        NotificationManager.cancelReminders(for: ticket)
        db.collection("organizations/\(orgId)/tickets").document(ticket.id)
            .updateData([
                "statusRaw":   TicketStatus.delivered.rawValue,
                "deliveredAt": Date()
            ])
    }

    // MARK: - Cancel

    func cancel(ticket: ParkingTicket) {
        guard let orgId = currentOrgId else { return }
        NotificationManager.cancelReminders(for: ticket)
        db.collection("organizations/\(orgId)/tickets").document(ticket.id)
            .updateData(["statusRaw": TicketStatus.cancelled.rawValue])
    }

    // MARK: - Delete

    func delete(ticketId: String) {
        guard let orgId = currentOrgId else { return }
        // Find the ticket to cancel its notifications before deleting
        if let ticket = tickets.first(where: { $0.id == ticketId }) {
            NotificationManager.cancelReminders(for: ticket)
        }
        db.collection("organizations/\(orgId)/tickets").document(ticketId).delete()
    }
}
