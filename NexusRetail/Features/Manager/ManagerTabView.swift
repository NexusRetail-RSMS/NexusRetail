//
//  ManagerTabView.swift
//  NexusRetail
//

import SwiftUI

/// Manager shell: Inventory, Requests, Pricing, Events, Staff.
struct ManagerTabView: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var isProfilePresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Home")
                        .font(.largeTitle.bold())
                    
                    Spacer()
                    
                    Button {
                        isProfilePresented = true
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.gray, Color(UIColor.secondarySystemFill))
                            .font(.system(size: 38))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Profile")
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Black Card
                        VStack(alignment: .leading, spacing: 12) {  
                            Text("Manager Tasks")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Review pending staff schedules")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Spacer()
                                Button("Open Session") { }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                        .padding()
                        .background(Color.black)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        Button("Sign Out") {
                            Task { try? await sessionStore.signOut() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding(.top, 20)
                    }
                    .padding(.vertical)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.white.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isProfilePresented) {
                AdminProfileSheet()
            }
        }
    }
}
