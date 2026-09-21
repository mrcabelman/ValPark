import Foundation
import Observation

@Observable
final class LocalizationManager {

    enum Language: String, CaseIterable, Identifiable {
        case english = "English"
        case spanish = "Español"
        var id: String { rawValue }
    }

    var language: Language {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
        language = Language(rawValue: saved) ?? .english
    }

    subscript(key: String) -> String {
        let dict = language == .english ? Self.en : Self.es
        return dict[key] ?? Self.en[key] ?? key
    }

    // MARK: - English

    static let en: [String: String] = [
        // Tabs
        "tab.active": "Active",
        "tab.history": "History",
        "tab.settings": "Settings",

        // Welcome
        "welcome.title": "Welcome to ParkCol",
        "welcome.subtitle": "Valet parking management",
        "welcome.sign_in": "Sign in with Google",
        "welcome.signing_in": "Signing in…",
        "welcome.error": "Sign-in failed. Please try again.",

        // Active
        "active.empty": "No active tickets",

        // Status
        "status.parked": "Parked",
        "status.car_requested": "Car Requested",
        "status.on_the_way": "On The Way",
        "status.delivered": "Delivered",
        "status.cancelled": "Cancelled",

        // Payment display
        "payment.paid": "Paid",
        "payment.half_paid": "Half Paid",
        "payment.pay_after": "Pay After",
        "payment.pay_before": "Pay Before",
        "payment.pay_half": "Pay Half",
        "payment.cash": "Cash",
        "payment.card": "Card",
        "payment.neiki": "Neiki",
        "payment.bancolombia": "Bancolombia Transfer",

        // Car Details
        "details.timeline": "TIMELINE",
        "details.notes_label": "NOTES",
        "details.check_out": "Check Out Vehicle",
        "details.cancel_ticket": "Cancel Ticket",
        "details.mark_car_requested": "Mark Car Requested",
        "details.mark_on_the_way": "Mark On The Way",
        "details.cancel_confirm": "Cancel this ticket?",
        "details.keep": "Keep",
        "details.checked_in": "Checked In",

        // Add Ticket
        "add.title": "New Ticket",
        "add.cancel": "Cancel",
        "add.customer": "CUSTOMER",
        "add.first_name": "First name *",
        "add.last_name": "Last name *",
        "add.phone": "Phone number *",
        "add.vehicle_section": "VEHICLE",
        "add.vehicle_placeholder": "e.g. Black BMW X5 *",
        "add.zone_section": "PARKING ZONE *",
        "add.zone_select": "Select zone…",
        "add.timing_section": "PAYMENT TIMING *",
        "add.method_section": "PAYMENT METHOD",
        "add.parking_time": "PARKING TIME",
        "add.start": "Start",
        "add.end": "End",
        "add.amount_section": "AMOUNT",
        "add.photos_section": "PHOTOS",
        "add.camera": "Camera",
        "add.gallery": "Gallery",
        "add.notes_section": "NOTES (OPTIONAL)",
        "add.notes_placeholder": "e.g. Scratch on rear bumper",
        "add.check_in_btn": "Check In Vehicle",
        "add.success_title": "Checked In",
        "add.done": "Done",

        // History
        "history.search": "Search by name or vehicle…",
        "history.empty": "No history yet",
        "history.no_results": "No results found",
        "history.report_btn": "Report",
        "history.ago": "ago",

        // Report
        "report.title": "Create Report",
        "report.done": "Done",
        "report.location": "LOCATION",
        "report.all_zones": "All Zones",
        "report.from": "FROM",
        "report.to": "TO",
        "report.generate": "Generate Report",
        "report.total": "Total",
        "report.delivered": "Delivered",
        "report.cancelled": "Cancelled",
        "report.revenue": "Revenue",
        "report.empty": "No tickets found for this period.",

        // Settings
        "settings.title": "Settings",
        "settings.language": "LANGUAGE",
        "settings.zones": "PARKING ZONES",
        "settings.remove": "Remove",
        "settings.new_zone": "New zone name…",
        "settings.add": "Add",
        "settings.app_section": "APP",
        "settings.version": "Version",
        "settings.notifications": "Push Notifications",
        "settings.disabled": "Disabled",
        "settings.sync": "Sync with Google",
        "settings.syncing": "Syncing…",
        "settings.synced": "Synced",
        "settings.sync_section": "CLOUD SYNC",
        "settings.sign_out": "Sign Out",
        "settings.sign_out_confirm": "Sign out?",
        "settings.cancel": "Cancel",

        // Picker
        "picker.done": "Done",
        "picker.timing_title": "Payment Timing",
        "picker.method_title": "Payment Method",
        "picker.zone_title": "Parking Zone",
        "picker.location_title": "Location",
    ]

    // MARK: - Spanish

    static let es: [String: String] = [
        // Tabs
        "tab.active": "Activo",
        "tab.history": "Historial",
        "tab.settings": "Configuración",

        // Welcome
        "welcome.title": "Bienvenido a ParkCol",
        "welcome.subtitle": "Gestión de parqueo valet",
        "welcome.sign_in": "Iniciar sesión con Google",
        "welcome.signing_in": "Iniciando sesión…",
        "welcome.error": "Error al iniciar sesión. Inténtalo de nuevo.",

        // Active
        "active.empty": "Sin tickets activos",

        // Status
        "status.parked": "Estacionado",
        "status.car_requested": "Auto Solicitado",
        "status.on_the_way": "En Camino",
        "status.delivered": "Entregado",
        "status.cancelled": "Cancelado",

        // Payment display
        "payment.paid": "Pagado",
        "payment.half_paid": "Mitad Pagado",
        "payment.pay_after": "Pagar Después",
        "payment.pay_before": "Pagar Antes",
        "payment.pay_half": "Pagar Mitad",
        "payment.cash": "Efectivo",
        "payment.card": "Tarjeta",
        "payment.neiki": "Neiki",
        "payment.bancolombia": "Transferencia Bancolombia",

        // Car Details
        "details.timeline": "LÍNEA DE TIEMPO",
        "details.notes_label": "NOTAS",
        "details.check_out": "Entregar Vehículo",
        "details.cancel_ticket": "Cancelar Ticket",
        "details.mark_car_requested": "Marcar Auto Solicitado",
        "details.mark_on_the_way": "Marcar En Camino",
        "details.cancel_confirm": "¿Cancelar este ticket?",
        "details.keep": "Mantener",
        "details.checked_in": "Registrado",

        // Add Ticket
        "add.title": "Nuevo Ticket",
        "add.cancel": "Cancelar",
        "add.customer": "CLIENTE",
        "add.first_name": "Nombre *",
        "add.last_name": "Apellido *",
        "add.phone": "Número de teléfono *",
        "add.vehicle_section": "VEHÍCULO",
        "add.vehicle_placeholder": "ej. BMW X5 Negro *",
        "add.zone_section": "ZONA DE PARQUEO *",
        "add.zone_select": "Seleccionar zona…",
        "add.timing_section": "TIEMPO DE PAGO *",
        "add.method_section": "MÉTODO DE PAGO",
        "add.parking_time": "TIEMPO DE PARQUEO",
        "add.start": "Inicio",
        "add.end": "Fin",
        "add.amount_section": "MONTO",
        "add.photos_section": "FOTOS",
        "add.camera": "Cámara",
        "add.gallery": "Galería",
        "add.notes_section": "NOTAS (OPCIONAL)",
        "add.notes_placeholder": "ej. Rayón en el parachoques trasero",
        "add.check_in_btn": "Registrar Vehículo",
        "add.success_title": "Registrado",
        "add.done": "Listo",

        // History
        "history.search": "Buscar por nombre o vehículo…",
        "history.empty": "Sin historial",
        "history.no_results": "Sin resultados",
        "history.report_btn": "Reporte",
        "history.ago": "hace",

        // Report
        "report.title": "Crear Reporte",
        "report.done": "Listo",
        "report.location": "UBICACIÓN",
        "report.all_zones": "Todas las Zonas",
        "report.from": "DESDE",
        "report.to": "HASTA",
        "report.generate": "Generar Reporte",
        "report.total": "Total",
        "report.delivered": "Entregados",
        "report.cancelled": "Cancelados",
        "report.revenue": "Ingresos",
        "report.empty": "Sin tickets para este período.",

        // Settings
        "settings.title": "Configuración",
        "settings.language": "IDIOMA",
        "settings.zones": "ZONAS DE PARQUEO",
        "settings.remove": "Eliminar",
        "settings.new_zone": "Nombre de nueva zona…",
        "settings.add": "Agregar",
        "settings.app_section": "APP",
        "settings.version": "Versión",
        "settings.notifications": "Notificaciones",
        "settings.disabled": "Desactivadas",
        "settings.sync": "Sincronizar con Google",
        "settings.syncing": "Sincronizando…",
        "settings.synced": "Sincronizado",
        "settings.sync_section": "SINCRONIZACIÓN",
        "settings.sign_out": "Cerrar Sesión",
        "settings.sign_out_confirm": "¿Cerrar sesión?",
        "settings.cancel": "Cancelar",

        // Picker
        "picker.done": "Listo",
        "picker.timing_title": "Tiempo de Pago",
        "picker.method_title": "Método de Pago",
        "picker.zone_title": "Zona de Parqueo",
        "picker.location_title": "Ubicación",
    ]
}

// MARK: - Enum localization helpers

extension TicketStatus {
    func localized(_ lm: LocalizationManager) -> String {
        switch self {
        case .parked:       return lm["status.parked"]
        case .carRequested: return lm["status.car_requested"]
        case .onTheWay:     return lm["status.on_the_way"]
        case .delivered:    return lm["status.delivered"]
        case .cancelled:    return lm["status.cancelled"]
        }
    }
}

extension PaymentTiming {
    func localizedDisplay(_ lm: LocalizationManager) -> String {
        switch self {
        case .payBefore: return lm["payment.paid"]
        case .payHalf:   return lm["payment.half_paid"]
        case .payAfter:  return lm["payment.pay_after"]
        }
    }
    func localizedName(_ lm: LocalizationManager) -> String {
        switch self {
        case .payBefore: return lm["payment.pay_before"]
        case .payHalf:   return lm["payment.pay_half"]
        case .payAfter:  return lm["payment.pay_after"]
        }
    }
}

extension PaymentMethod {
    func localized(_ lm: LocalizationManager) -> String {
        switch self {
        case .cash:               return lm["payment.cash"]
        case .card:               return lm["payment.card"]
        case .neiki:              return lm["payment.neiki"]
        case .bancolombiaTransfer: return lm["payment.bancolombia"]
        }
    }
}
