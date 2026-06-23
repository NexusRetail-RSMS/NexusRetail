// Role-based router (RBAC). Reads the signed-in user's role from SessionStore and
// mounts only that role's tab view (Admin / Manager / Sales / After-Sales), or LoginView
// when there is no active session.

//
//  ContentView.swift
//  NexusRetail
//
//  Created by Aryavansh on 23/06/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // Show the login screen. (Replace with the role-based router once a
        // session exists in SessionStore.)
        LoginView()
    }
}

#Preview {
    ContentView()
}
