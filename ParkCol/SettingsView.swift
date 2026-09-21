import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self)        private var appSettings
    @Environment(LocalizationManager.self) private var lm

    @State private var newZoneName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Language
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lm["settings.language"]).font(.caption).foregroundStyle(.gray)
                            LanguageToggle()
                        }

                        // Parking Zones
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lm["settings.zones"]).font(.caption).foregroundStyle(.gray)

                            if !appSettings.parkingZones.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(appSettings.parkingZones, id: \.self) { zone in
                                        HStack {
                                            Label(zone, systemImage: "mappin").foregroundStyle(.white)
                                            Spacer()
                                            Button(lm["settings.remove"]) {
                                                appSettings.removeZone(zone)
                                            }
                                            .font(.subheadline).foregroundStyle(.red)
                                        }
                                        .padding(.horizontal, 16).padding(.vertical, 14)
                                        if zone != appSettings.parkingZones.last {
                                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(Color(UIColor.systemGray6).opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            HStack(spacing: 10) {
                                TextField(lm["settings.new_zone"], text: $newZoneName)
                                    .foregroundStyle(.white).padding().frame(height: 48)
                                    .background(Color(UIColor.systemGray6).opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 10)).tint(.green)
                                Button(lm["settings.add"]) {
                                    appSettings.addZone(newZoneName)
                                    newZoneName = ""
                                }
                                .font(.body.weight(.semibold)).foregroundStyle(.black)
                                .frame(width: 72, height: 48)
                                .background(newZoneName.trimmingCharacters(in: .whitespaces).isEmpty
                                             ? Color.green.opacity(0.4) : Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .disabled(newZoneName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }

                        // App info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lm["settings.app_section"]).font(.caption).foregroundStyle(.gray)
                            VStack(spacing: 0) {
                                HStack {
                                    Text(lm["settings.version"]).foregroundStyle(.white)
                                    Spacer()
                                    Text("1.0.0").foregroundStyle(.gray)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                                HStack {
                                    Text(lm["settings.notifications"]).foregroundStyle(.white)
                                    Spacer()
                                    Label(lm["settings.disabled"], systemImage: "bell.slash")
                                        .font(.subheadline).foregroundStyle(.gray)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                            }
                            .background(Color(UIColor.systemGray6).opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(lm["settings.title"])
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
