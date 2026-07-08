//
//  AfterSalesTicketsListView.swift
//  NexusRetail
//
//  Tapping a dashboard KPI opens this filtered list of real after-sales tickets.
//

import SwiftUI
import Supabase

enum AfterSalesTicketFilter: Identifiable {
    case all
    case pending          // not completed
    case inProgress       // repair + in_repair/qa_check
    case exchanges        // exchange / return

    var id: String { title }

    var title: String {
        switch self {
        case .all: return "All Service Tickets"
        case .pending: return "Pending Service Requests"
        case .inProgress: return "Repairs In Progress"
        case .exchanges: return "Exchanges & Returns"
        }
    }
}

struct AfterSalesTicketListRow: Decodable, Identifiable {
    let id: UUID
    let type: String
    let stage: String
    let createdAt: Date
    let serviceCost: Double?
    let itemName: String?
    let warrantyStatus: String?
    let issueDescription: String?

    enum CodingKeys: String, CodingKey {
        case id, type, stage
        case createdAt = "created_at"
        case serviceCost = "service_cost"
        case itemName = "item_name"
        case warrantyStatus = "warranty_status"
        case issueDescription = "issue_description"
    }
}

struct AfterSalesTicketsListView: View {
    let filter: AfterSalesTicketFilter
    let storeID: UUID?

    @Environment(\.dismiss) private var dismiss
    @State private var tickets: [AfterSalesTicketListRow] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background.ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading tickets...").tint(RSMSColors.burgundy)
                } else if tickets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 44))
                            .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
                        Text("No tickets here yet")
                            .font(.system(size: 15))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tickets) { ticket in
                                ticketRow(ticket)
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle(filter.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
            .task { await load() }
        }
    }

    private func ticketRow(_ t: AfterSalesTicketListRow) -> some View {
        let isExchange = (t.type == "exchange" || t.type == "return")
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((isExchange ? RSMSColors.burgundy : Color(hex: "34495E")).opacity(0.1))
                    .frame(width: 46, height: 46)
                Image(systemName: isExchange ? "arrow.triangle.2.circlepath" : "wrench.and.screwdriver.fill")
                    .foregroundColor(isExchange ? RSMSColors.burgundy : Color(hex: "34495E"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(t.itemName ?? "Item")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(t.type.capitalized)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(RSMSColors.burgundy)
                    Text("•").foregroundColor(RSMSColors.secondaryText)
                    Text(stageLabel(t.stage))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                Text(t.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.8))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if (t.serviceCost ?? 0) <= 0 {
                    Text("FREE")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(RSMSColors.success)
                } else {
                    Text(String(format: "₹%.0f", t.serviceCost ?? 0))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
                if t.warrantyStatus == "active" {
                    Text("In warranty")
                        .font(.system(size: 10))
                        .foregroundColor(RSMSColors.success)
                }
            }
        }
        .padding(14)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSColors.cardBorder, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func stageLabel(_ stage: String) -> String {
        switch stage {
        case "received": return "Received"
        case "in_repair": return "In Repair"
        case "qa_check": return "QA Check"
        case "completed": return "Completed"
        default: return stage.capitalized
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var query = SupabaseManager.shared.client
                .from("after_sales_ticket")
                .select("id, type, stage, created_at, service_cost, item_name, warranty_status, issue_description")

            if let storeID {
                query = query.eq("store_id", value: storeID.uuidString)
            }

            switch filter {
            case .all:
                break
            case .pending:
                query = query.neq("stage", value: "completed")
            case .inProgress:
                query = query.eq("type", value: "repair").in("stage", values: ["in_repair", "qa_check"])
            case .exchanges:
                query = query.in("type", values: ["exchange", "return"])
            }

            tickets = try await query
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            print("After Sales tickets list error: \(error)")
        }
    }
}
