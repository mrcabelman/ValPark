import Foundation

// MARK: - Enums (unchanged from original)

enum TicketStatus: String, Codable, CaseIterable {
    case parked       = "Parked"
    case carRequested = "Car Requested"
    case onTheWay     = "On The Way"
    case delivered    = "Delivered"
    case cancelled    = "Cancelled"

    var color: String {
        switch self {
        case .parked:       return "blue"
        case .carRequested: return "orange"
        case .onTheWay:     return "yellow"
        case .delivered:    return "green"
        case .cancelled:    return "red"
        }
    }
}

enum PaymentTiming: String, Codable, CaseIterable {
    case payBefore = "Pay Before"
    case payHalf   = "Pay Half"
    case payAfter  = "Pay After"

    var displayStatus: String {
        switch self {
        case .payBefore: return "Paid"
        case .payHalf:   return "Half Paid"
        case .payAfter:  return "Pay After"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cash                = "Cash"
    case card                = "Card"
    case neiki               = "Neiki"
    case bancolombiaTransfer = "Bancolombia Transfer"
}

// MARK: - ParkingTicket
//
// Converted from a SwiftData @Model class to a plain Codable struct so it
// can be stored in and retrieved from Firestore.
// The `id` field is also used as the Firestore document ID.

struct ParkingTicket: Identifiable, Codable {
    var id: String = UUID().uuidString
    var customerFirstName: String = ""
    var customerLastName: String  = ""
    var phoneNumber: String       = ""
    var vehicle: String           = ""
    var parkingZone: String       = ""
    var paymentTimingRaw: String  = PaymentTiming.payAfter.rawValue
    var paymentMethodRaw: String  = PaymentMethod.cash.rawValue
    var amount: Double            = 0.0
    var notes: String             = ""
    var statusRaw: String         = TicketStatus.parked.rawValue
    var checkedInAt: Date         = Date()
    var deliveredAt: Date?        = nil
    var expectedEndTime: Date?    = nil
    var createdBy: String         = ""   // uid of the attendant who checked in the car
    var orgId: String             = ""

    // MARK: Computed helpers

    var customerFullName: String { "\(customerFirstName) \(customerLastName)" }

    var status: TicketStatus {
        get { TicketStatus(rawValue: statusRaw) ?? .parked }
        set { statusRaw = newValue.rawValue }
    }

    var paymentTiming: PaymentTiming {
        get { PaymentTiming(rawValue: paymentTimingRaw) ?? .payAfter }
        set { paymentTimingRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .cash }
        set { paymentMethodRaw = newValue.rawValue }
    }

    // MARK: Init

    init(customerFirstName: String = "",
         customerLastName: String  = "",
         phoneNumber: String       = "",
         vehicle: String           = "",
         parkingZone: String       = "",
         paymentTiming: PaymentTiming = .payAfter,
         paymentMethod: PaymentMethod = .cash,
         amount: Double            = 0.0,
         notes: String             = "",
         createdBy: String         = "",
         orgId: String             = "") {
        self.id                 = UUID().uuidString
        self.customerFirstName  = customerFirstName
        self.customerLastName   = customerLastName
        self.phoneNumber        = phoneNumber
        self.vehicle            = vehicle
        self.parkingZone        = parkingZone
        self.paymentTimingRaw   = paymentTiming.rawValue
        self.paymentMethodRaw   = paymentMethod.rawValue
        self.amount             = amount
        self.notes              = notes
        self.statusRaw          = TicketStatus.parked.rawValue
        self.checkedInAt        = Date()
        self.createdBy          = createdBy
        self.orgId              = orgId
    }
}
