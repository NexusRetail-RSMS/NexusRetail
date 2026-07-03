import SwiftUI
import PhotosUI

struct CreateEventView: View {
    @Bindable var viewModel: EventsViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Optional event to edit. If nil, we are creating a new event.
    var eventToEdit: MockEvent? = nil
    
    @State private var title = ""
    @State private var description = ""
    @State private var eventType = EventType.productLaunch
    @State private var venue = "NexusRetail Current Store"
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600 * 2)
    @State private var maximumGuests = 50
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var bannerImageData: Data? = nil
    
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
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .buttonStyle(PlainButtonStyle())
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
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate, in: startDate...)
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
                    Button("Save") {
                        saveEvent()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(title.isEmpty ? .gray : RSMSColors.burgundy)
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let event = eventToEdit {
                    title = event.title
                    description = event.description
                    eventType = event.eventType
                    venue = event.venue
                    startDate = event.startDate
                    endDate = event.endDate
                    maximumGuests = event.maximumGuests
                    bannerImageData = event.bannerImageData
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        bannerImageData = data
                    }
                }
            }
        }
    }
    
    private func saveEvent() {
        if let event = eventToEdit {
            var updatedEvent = event
            updatedEvent.title = title
            updatedEvent.description = description
            updatedEvent.eventType = eventType
            updatedEvent.venue = venue
            updatedEvent.startDate = startDate
            updatedEvent.endDate = endDate
            updatedEvent.maximumGuests = maximumGuests
            if let imageData = bannerImageData {
                updatedEvent.bannerImageData = imageData
            }
            
            viewModel.updateEvent(updatedEvent)
        } else {
            viewModel.createEvent(
                title: title,
                description: description,
                eventType: eventType,
                venue: venue,
                startDate: startDate,
                endDate: endDate,
                maximumGuests: maximumGuests,
                bannerImageData: bannerImageData
            )
        }
    }
}
