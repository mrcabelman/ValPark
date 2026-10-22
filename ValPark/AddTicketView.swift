import SwiftUI
import PhotosUI

struct AddTicketView: View {
    @Environment(\.dismiss)              private var dismiss
    @Environment(TicketStore.self)       private var ticketStore
    @Environment(OrganizationStore.self) private var orgStore
    @Environment(FirebaseAuthManager.self) private var auth
    @Environment(LocalizationManager.self) private var lm

    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var phoneNumber = ""
    @State private var vehicle   = ""
    @State private var selectedZone   = ""
    @State private var selectedTiming: PaymentTiming = .payAfter
    @State private var selectedMethod: PaymentMethod = .cash
    @State private var amount    = ""
    @State private var notes     = ""
    @State private var startTime = Date()
    @State private var endTime   = Date().addingTimeInterval(3600)

    @State private var showZonePicker   = false
    @State private var showTimingPicker = false
    @State private var showMethodPicker = false
    @State private var showSuccessAlert = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedPhotos: [UIImage] = []

    private var zones: [String] { orgStore.currentOrg?.parkingZones ?? [] }

    private var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !phoneNumber.isEmpty &&
        !vehicle.isEmpty && !selectedZone.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Customer
                        SectionHeader(title: lm["add.customer"])
                        HStack(spacing: 10) {
                            FormTextField(placeholder: lm["add.first_name"], text: $firstName)
                            FormTextField(placeholder: lm["add.last_name"],  text: $lastName)
                        }
                        HStack(spacing: 10) {
                            Text("+1")
                                .font(.body.weight(.semibold)).foregroundStyle(.white)
                                .frame(width: 44, height: 48)
                                .background(Color(UIColor.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            FormTextField(placeholder: lm["add.phone"], text: $phoneNumber)
                                .keyboardType(.phonePad)
                        }

                        // Vehicle
                        SectionHeader(title: lm["add.vehicle_section"])
                        FormTextField(placeholder: lm["add.vehicle_placeholder"], text: $vehicle)

                        // Parking Zone
                        SectionHeader(title: lm["add.zone_section"])
                        if zones.isEmpty {
                            Text(lm["add.zone_none"])
                                .font(.caption).foregroundStyle(.orange)
                        } else {
                            PickerButton(label: selectedZone.isEmpty ? lm["add.zone_select"] : selectedZone,
                                         isEmpty: selectedZone.isEmpty) { showZonePicker = true }
                        }

                        // Payment Timing
                        SectionHeader(title: lm["add.timing_section"])
                        PickerButton(label: selectedTiming.localizedName(lm),
                                     isEmpty: false) { showTimingPicker = true }

                        // Payment Method
                        SectionHeader(title: lm["add.method_section"])
                        PickerButton(label: selectedMethod.localized(lm),
                                     isEmpty: false) { showMethodPicker = true }

                        // Parking Time
                        SectionHeader(title: lm["add.parking_time"])
                        VStack(spacing: 0) {
                            HStack {
                                Text(lm["add.start"]).foregroundStyle(.gray).frame(width: 44, alignment: .leading)
                                Spacer()
                                DatePicker("", selection: $startTime,
                                           displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden().datePickerStyle(.compact).tint(.green)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                            HStack {
                                Text(lm["add.end"]).foregroundStyle(.gray).frame(width: 44, alignment: .leading)
                                Spacer()
                                DatePicker("", selection: $endTime, in: startTime...,
                                           displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden().datePickerStyle(.compact).tint(.green)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                        }
                        .background(Color(UIColor.systemGray6).opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Amount
                        SectionHeader(title: lm["add.amount_section"])
                        HStack(spacing: 0) {
                            Text("$")
                                .font(.body.weight(.semibold)).foregroundStyle(.white)
                                .frame(width: 44, height: 48)
                                .background(Color(UIColor.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad).foregroundStyle(.white)
                                .padding(.horizontal, 12).frame(height: 48)
                                .background(Color(UIColor.systemGray6).opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.leading, 10)
                        }

                        // Photos (picked locally; not persisted to cloud in this version)
                        SectionHeader(title: "\(lm["add.photos_section"]) (\(selectedPhotos.count)/5)")
                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhotoItems,
                                         maxSelectionCount: max(0, 5 - selectedPhotos.count),
                                         matching: .images) {
                                PhotoButtonLabel(icon: "camera",             label: lm["add.camera"])
                            }
                            PhotosPicker(selection: $selectedPhotoItems,
                                         maxSelectionCount: max(0, 5 - selectedPhotos.count),
                                         matching: .images) {
                                PhotoButtonLabel(icon: "photo.on.rectangle", label: lm["add.gallery"])
                            }
                            ForEach(selectedPhotos, id: \.self) { img in
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .onChange(of: selectedPhotoItems) { _, items in
                            Task {
                                var imgs: [UIImage] = []
                                for item in items {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let img = UIImage(data: data) { imgs.append(img) }
                                }
                                selectedPhotos = imgs
                            }
                        }

                        // Notes
                        SectionHeader(title: lm["add.notes_section"])
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text(lm["add.notes_placeholder"])
                                    .foregroundStyle(.gray).padding(.top, 12).padding(.leading, 16)
                            }
                            TextEditor(text: $notes)
                                .foregroundStyle(.white).scrollContentBackground(.hidden)
                                .frame(minHeight: 80).padding(8)
                        }
                        .background(Color(UIColor.systemGray6).opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Check In
                        Button { checkIn() } label: {
                            Text(lm["add.check_in_btn"])
                                .font(.body.weight(.semibold)).foregroundStyle(.black)
                                .frame(maxWidth: .infinity).padding()
                                .background(isValid ? Color.green : Color.green.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!isValid)
                        .padding(.bottom, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle(lm["add.title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lm["add.cancel"]) { dismiss() }.foregroundStyle(.green)
                }
            }
            .alert(lm["add.success_title"], isPresented: $showSuccessAlert) {
                Button(lm["add.done"]) { dismiss() }
            } message: {
                Text("\(firstName)'s vehicle has been checked in.")
            }
        }
        .sheet(isPresented: $showZonePicker) {
            PickerSheet(title: lm["picker.zone_title"],
                        options: zones,
                        selected: $selectedZone)
        }
        .sheet(isPresented: $showTimingPicker) {
            PickerSheet(
                title: lm["picker.timing_title"],
                options: PaymentTiming.allCases.map { $0.rawValue },
                displayOptions: PaymentTiming.allCases.map { $0.localizedName(lm) },
                selected: Binding(
                    get: { selectedTiming.rawValue },
                    set: { selectedTiming = PaymentTiming(rawValue: $0) ?? .payAfter }
                ))
        }
        .sheet(isPresented: $showMethodPicker) {
            PickerSheet(
                title: lm["picker.method_title"],
                options: PaymentMethod.allCases.map { $0.rawValue },
                displayOptions: PaymentMethod.allCases.map { $0.localized(lm) },
                selected: Binding(
                    get: { selectedMethod.rawValue },
                    set: { selectedMethod = PaymentMethod(rawValue: $0) ?? .cash }
                ))
        }
    }

    private func checkIn() {
        guard let orgId = orgStore.currentOrg?.id,
              let uid   = auth.currentUser?.uid else { return }

        var ticket = ParkingTicket(
            customerFirstName: firstName,
            customerLastName:  lastName,
            phoneNumber:       phoneNumber,
            vehicle:           vehicle,
            parkingZone:       selectedZone,
            paymentTiming:     selectedTiming,
            paymentMethod:     selectedMethod,
            amount:            Double(amount) ?? 0.0,
            notes:             notes,
            createdBy:         uid,
            orgId:             orgId
        )
        ticket.checkedInAt     = startTime
        ticket.expectedEndTime = endTime

        ticketStore.create(ticket)
        showSuccessAlert = true
    }
}

// MARK: - Shared sub-views (PickerSheet moved here; SectionHeader / FormTextField / PickerButton in AddTicketView)

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title).font(.caption).foregroundStyle(.gray)
    }
}

struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .foregroundStyle(.white).padding().frame(height: 48)
            .background(Color(UIColor.systemGray6).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10)).tint(.green)
    }
}

struct PickerButton: View {
    let label: String
    let isEmpty: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(label).foregroundStyle(isEmpty ? .gray : .white)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.gray).font(.caption)
            }
            .padding()
            .background(Color(UIColor.systemGray6).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct PhotoButtonLabel: View {
    let icon: String
    let label: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3)
            Text(label).font(.caption)
        }
        .foregroundStyle(.gray)
        .frame(width: 80, height: 70)
        .background(Color(UIColor.systemGray6).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct PickerSheet: View {
    let title: String
    let options: [String]
    var displayOptions: [String]? = nil
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6).ignoresSafeArea()
                List(options.indices, id: \.self) { i in
                    let value   = options[i]
                    let display = displayOptions?[i] ?? value
                    Button {
                        selected = value
                        dismiss()
                    } label: {
                        HStack {
                            Text(display).foregroundStyle(.primary)
                            Spacer()
                            if selected == value {
                                Image(systemName: "checkmark").foregroundStyle(.green)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
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
