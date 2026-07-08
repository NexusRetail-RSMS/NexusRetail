import SwiftUI
import PhotosUI

struct CreateEventView: View {
    @Bindable var viewModel: EventsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    
    // Optional event to edit. If nil, we are creating a new event.
    var eventToEdit: SupabaseEvent? = nil
    
    @State private var title = ""
    @State private var description = ""
    @State private var eventType = EventType.productLaunch
    @State private var venue = "NexusRetail Current Store"
    @State private var eventDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600 * 2)
    @State private var maximumGuests = 50
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var bannerImageData: Data? = nil
    @State private var isSaving = false
    @State private var isProcessingImage = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Banner Section
                Section {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack {
                            if let data = bannerImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 140)
                                    .clipped()
                            } else if let urlString = eventToEdit?.bannerImageURL, let url = URL(string: urlString) {
                                // Show the existing banner when editing (until a new one is picked)
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.1)
                                }
                                .frame(height: 140)
                                .clipped()
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 140)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray)
                                    Text("Tap to add event banner")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }

                            // Spinner while the picked image is being downscaled/prepared
                            if isProcessingImage {
                                Color.black.opacity(0.25)
                                    .frame(height: 140)
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isProcessingImage || isSaving)
                }
                
                // Details Section
                Section(header: Text("Event Details")) {
                    TextField("Event Name", text: $title)
                        .font(.body)
                    
                    Picker("Event Type", selection: $eventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextField("Venue", text: $venue)
                        .font(.body)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(.leading, -4)
                    }
                }
                
                // Date & Time Section
                Section(header: Text("Date & Time")) {
                    if eventToEdit == nil {
                        DatePicker("Date", selection: $eventDate, in: Date()..., displayedComponents: .date)
                    } else {
                        DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                    }
                    
                    if eventToEdit == nil && Calendar.current.isDateInToday(eventDate) {
                        DatePicker("Start Time", selection: $startTime, in: Date()..., displayedComponents: .hourAndMinute)
                    } else {
                        DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                // Capacity Section
                Section(header: Text("Capacity")) {
                    HStack {
                        Text("Maximum Guests")
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button {
                                if maximumGuests > 1 {
                                    maximumGuests -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(maximumGuests > 1 ? RSMSColors.burgundy : .gray)
                                    .font(.title3)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("\(maximumGuests)")
                                .font(.headline)
                                .frame(width: 40, alignment: .center)
                            
                            Button {
                                if maximumGuests < 1000 {
                                    maximumGuests += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(maximumGuests < 1000 ? RSMSColors.burgundy : .gray)
                                    .font(.title3)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle(eventToEdit == nil ? "Create Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(RSMSColors.burgundy)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await saveEvent() }
                        }
                        .fontWeight(.bold)
                        .foregroundColor((title.isEmpty || isProcessingImage) ? .gray : RSMSColors.burgundy)
                        .disabled(title.isEmpty || isProcessingImage)
                    }
                }
            }
            .onAppear {
                if let event = eventToEdit {
                    title = event.title
                    description = event.description ?? ""
                    eventType = EventType(rawValue: event.eventType ?? "") ?? .custom
                    venue = event.venue ?? ""
                    eventDate = event.eventDate
                    startTime = event.startTime
                    endTime = event.endTime ?? event.startTime
                    maximumGuests = event.maximumGuests
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    isProcessingImage = true
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        // Downscale + recompress before upload. Raw PhotosPicker data can be
                        // 5-15MB, which causes the upload stream to drop (NSURLError -1005).
                        // Run off the main thread so the UI stays responsive.
                        let compressed = await Task.detached(priority: .userInitiated) {
                            Self.compressForUpload(data)
                        }.value
                        bannerImageData = compressed
                    }
                    isProcessingImage = false
                }
            }
        }
    }
    
    /// Resizes the picked image to a max dimension and recompresses it to JPEG so the
    /// upload payload stays small (banners are wide, so we allow up to 1200px).
    private static func compressForUpload(_ data: Data, maxDimension: CGFloat = 1200, quality: CGFloat = 0.6) -> Data {
        guard let image = UIImage(data: data) else { return data }

        let size = image.size
        let largestSide = max(size.width, size.height)
        let scale = largestSide > maxDimension ? maxDimension / largestSide : 1.0
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: quality) ?? data
    }

    @MainActor
    private func saveEvent() async {
        guard let storeID = sessionStore.currentUser?.storeID else { return }

        isSaving = true
        defer { isSaving = false }

        var success = false
        do {
            if let event = eventToEdit {
                // Combine the selected date with the start/end times so the stored
                // scheduled_at / end_time carry both the correct day and time.
                let calendar = Calendar.current
                var dayComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
                let startComponents = calendar.dateComponents([.hour, .minute, .second], from: startTime)
                dayComponents.hour = startComponents.hour
                dayComponents.minute = startComponents.minute
                dayComponents.second = startComponents.second
                let combinedStart = calendar.date(from: dayComponents) ?? startTime

                // Automatically set the end time to 2 hours after the start time since the UI picker was removed.
                let combinedEnd = combinedStart.addingTimeInterval(3600 * 2)

                let updatedEvent = SupabaseEvent(
                    id: event.id,
                    storeID: event.storeID,
                    name: title,
                    description: description,
                    scheduledAt: combinedStart,
                    venue: venue,
                    launchSkuID: event.launchSkuID,
                    eventType: eventType.rawValue,
                    endTime: combinedEnd,
                    maxGuests: maximumGuests,
                    bannerImageURL: event.bannerImageURL,
                    eventGuests: event.eventGuests
                )
                
                success = await viewModel.updateEvent(updatedEvent, newBannerData: bannerImageData)
            } else {
                success = await viewModel.createEvent(
                    storeID: storeID,
                    title: title,
                    description: description,
                    eventType: eventType,
                    venue: venue,
                    eventDate: eventDate,
                    startTime: startTime,
                    endTime: startTime.addingTimeInterval(3600 * 2),
                    maximumGuests: maximumGuests,
                    bannerImageData: bannerImageData
                )
            }
        }

        // Only dismiss once the upload + save have actually completed.
        if success {
            dismiss()
        }
    }
}
