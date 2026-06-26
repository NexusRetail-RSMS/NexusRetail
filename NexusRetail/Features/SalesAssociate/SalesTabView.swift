//
//  SalesTabView.swift
//  NexusRetail
//

import SwiftUI

/// Sales shell: Clients, Suggest, Sell, Settings.
struct SalesTabView: View {
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
                        Text("Sales Dashboard")
                            .font(.headline)
                            .padding(.top, 20)
                        
                        Button("Sign Out") {
                            Task { try? await sessionStore.signOut() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
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
