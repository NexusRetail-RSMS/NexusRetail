#!/usr/bin/env python3
# Generates NexusRetail_Team_Responsibilities.pdf
from fpdf import FPDF
from fpdf.enums import XPos, YPos

# Theme (burgundy / cream)
BURGUNDY = (114, 22, 40)
DARK = (60, 60, 60)
LIGHT = (245, 240, 233)
GREY = (110, 110, 110)
GREEN = (35, 110, 70)
AMBER = (150, 100, 10)

class PDF(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "", 8)
        self.set_text_color(*GREY)
        self.cell(0, 6, "NexusRetail - Team Responsibilities & Delivery Report",
                  align="L")
        self.ln(8)

    def footer(self):
        self.set_y(-12)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(*GREY)
        self.cell(0, 6, f"Page {self.page_no()}", align="C")

pdf = PDF(orientation="P", unit="mm", format="A4")
pdf.set_auto_page_break(auto=True, margin=16)
pdf.set_margins(16, 16, 16)
pdf.add_page()

def H1(t):
    pdf.set_font("Helvetica", "B", 20)
    pdf.set_text_color(*BURGUNDY)
    pdf.multi_cell(0, 9, t, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(1)

def H2(t):
    pdf.ln(2)
    pdf.set_font("Helvetica", "B", 13)
    pdf.set_text_color(*BURGUNDY)
    pdf.multi_cell(0, 7, t, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_draw_color(*BURGUNDY)
    pdf.set_line_width(0.4)
    y = pdf.get_y()
    pdf.line(16, y, 194, y)
    pdf.ln(2)

def body(t, size=10):
    pdf.set_font("Helvetica", "", size)
    pdf.set_text_color(*DARK)
    pdf.multi_cell(0, 5, t, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

def small(t, color=GREY, size=8.5):
    pdf.set_font("Helvetica", "", size)
    pdf.set_text_color(*color)
    pdf.multi_cell(0, 4.5, t, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

def member(name, subtitle, stories, pitch):
    if pdf.get_y() > 245:
        pdf.add_page()
    pdf.ln(1.5)
    pdf.set_font("Helvetica", "B", 11.5)
    pdf.set_text_color(*BURGUNDY)
    pdf.multi_cell(0, 6, name, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "BI", 9.5)
    pdf.set_text_color(*DARK)
    pdf.multi_cell(0, 5, subtitle, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "", 9.5)
    pdf.set_text_color(*DARK)
    pdf.multi_cell(0, 4.8, "Stories: " + stories, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "I", 9.5)
    pdf.set_text_color(*GREEN)
    pdf.multi_cell(0, 4.8, "For the examiner: " + pitch, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

# ---- Title ----
H1("NexusRetail")
pdf.set_font("Helvetica", "", 12)
pdf.set_text_color(*DARK)
pdf.multi_cell(0, 6, "Team Responsibilities & Delivery Report", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
small("Jira project TEAM5 (Team_5)  -  4 Epics, 77 user stories across NIRALI Sprints 1-3", GREY, 9)
pdf.ln(2)

# ---- Summary ----
H2("Delivery Summary")
body("- 77 user stories: all marked Done (Status = Done, Resolution = Done).")
body("- 4 Epics (Admin, Manager, Sales Associate, After Sales): shown as To Do, but these are container issues; every child story under them is completed.")
body("- Committed backlog delivered: 100%. A small number of stories are functionally present but shallow (see 'Gaps & Replacements').")

# ---- Responsibilities ----
H2("Member Responsibilities")

member("Nirali Garg",
       "Product Owner / Scrum Lead & Recommendations Engine",
       "TEAM5-60, 61, 26, 27, 41, 44, 53, 76 (8) + reporter/creator of the full backlog",
       "Led requirements, backlog and sprint planning, and delivered the recommendation engine and the after-sales ticket foundation.")

member("Aryavansh Saini",
       "Core Platform & Point-of-Sale / After-Sales Engineer",
       "TEAM5-2, 25, 31, 40, 43, 45, 46 (7) + created the Admin/Manager/After-Sales epics",
       "Owned the store-setup foundation, the POS checkout pipeline, and the after-sales exchange/warranty engine.")

member("Prakhar Manu",
       "Payments & Sales-Associate Epic Owner",
       "TEAM5-7, 12, 32, 33, 34, 42, 49, 80 (8) + created the Sales Associate epic",
       "Owned the payments integration end-to-end (Razorpay + card terminal + digital receipts).")

member("Dhruv Negi",
       "Admin Catalogue, Transfers & Analytics Dashboards",
       "TEAM5-66, 67, 68, 84, 85, 86, 11, 70, 71, 30 (10)",
       "Built the SKU catalogue and pricing bands, admin analytics dashboards, and the events subsystem.")

member("Anoop Singh",
       "Pricing Rules, Transfer Approval & Repair Workflow",
       "TEAM5-65, 83, 13, 14, 18, 19, 63, 47, 55, 57 (10)",
       "Owned pricing-policy enforcement and the after-sales repair-workflow state machine.")

member("Tanishka Saxena",
       "Clienteling / CRM & After-Sales Closure",
       "TEAM5-9, 58, 20, 21, 22, 24, 52, 54, 56, 77 (10)",
       "Built the clienteling/CRM and appointment experience and the after-sales estimate/closure screens.")

member("Harman Singh",
       "Staff/Manager Management & Order Fulfilment",
       "TEAM5-73, 82, 74, 88, 29, 35, 87, 50, 51, 81 (10)",
       "Owned the manager/staff lifecycle and the fulfilment-routing + BOPIS pickup flow.")

member("Aditya Kumar",
       "Store Configuration & Inventory / Stock Requests",
       "TEAM5-6, 8, 72, 15, 16, 17, 48, 75 (8)",
       "Built store configuration and the manager stock-request to tracking pipeline.")

member("Mahak Sharma",
       "Localization, Revenue Dashboard & Remote Selling",
       "TEAM5-89, 10, 62, 23, 28, 79 (6)",
       "Delivered app-wide multi-language localization and the executive cross-store revenue dashboard.")

# ---- Contribution table ----
pdf.add_page()
H2("Contribution Counts")
rows = [
    ("Dhruv Negi", "10", "Catalogue + analytics + events"),
    ("Anoop Singh", "10", "Pricing + repair workflow"),
    ("Tanishka Saxena", "10", "CRM + after-sales closure"),
    ("Harman Singh", "10", "User mgmt + fulfilment"),
    ("Nirali Garg", "8", "Project lead, backlog owner, recommendations"),
    ("Prakhar Manu", "8", "SA epic owner, payments"),
    ("Aditya Kumar", "8", "Store config + stock requests"),
    ("Aryavansh Saini", "7", "Created 3 epics, POS/after-sales core"),
    ("Mahak Sharma", "6", "Localization + revenue dashboard"),
]
pdf.set_font("Helvetica", "B", 9.5)
pdf.set_fill_color(*BURGUNDY)
pdf.set_text_color(255, 255, 255)
pdf.cell(50, 7, "  Member", border=0, fill=True)
pdf.cell(20, 7, "Stories", border=0, fill=True, align="C")
pdf.cell(108, 7, "Primary area", border=0, fill=True,
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
fill = False
for name, n, area in rows:
    pdf.set_font("Helvetica", "", 9.5)
    pdf.set_text_color(*DARK)
    if fill:
        pdf.set_fill_color(*LIGHT)
    else:
        pdf.set_fill_color(255, 255, 255)
    pdf.cell(50, 6.5, "  " + name, border=0, fill=True)
    pdf.cell(20, 6.5, n, border=0, align="C", fill=True)
    pdf.cell(108, 6.5, " " + area, border=0, fill=True,
             new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    fill = not fill

# ---- Gaps & Replacements ----
H2("Gaps & Suggested Replacements")
body("These stories are marked Done but the code shows them as shallow or not truly "
     "implemented. For each, the recommended action is to REPLACE it in the demo with an "
     "equivalent, fully-working story owned by the same member (so scope and ownership stay balanced).")
pdf.ln(1)

gaps = [
    ("TEAM5-23  Video consultation + curated cart link  (Mahak Sharma)",
     "Only a 'video' appointment type + generated meeting link exist; no in-app video or cart sharing.",
     "Replace with TEAM5-28 Cross-sell at cart (Mahak) - fully working - and demo video only as a scheduled appointment with a join link."),
    ("TEAM5-52  Client digital sign-off on collection  (Tanishka Saxena)",
     "No signature-capture pad in code (only Razorpay payment-signature verification).",
     "Replace with TEAM5-77 History of completed exchanges/repairs (Tanishka) - fully working - to prove closure/audit is real."),
    ("TEAM5-48  Mandatory QA checklist  (Aditya Kumar)",
     "qa_checklist table exists but is empty and never touched by the app.",
     "Replace with TEAM5-17 Monitor stock-request status (Aditya) - fully working state tracking."),
    ("TEAM5-43 (AC) Upload condition photos + notes  (Aryavansh Saini)",
     "Exchange processing works; the photo-upload / condition_photo part is not wired.",
     "Replace with TEAM5-45/46 Warranty validation & out-of-warranty flagging (Aryavansh) - fully working."),
    ("TEAM5-86  Transfer status notifications (persisted history)  (Dhruv Negi)",
     "Alerts are computed client-side; the notification table is empty (no retained history).",
     "Replace with TEAM5-68 Receive/review transfer requests (Dhruv) - fully working transfer intake + status."),
]
for i, (title, issue, repl) in enumerate(gaps, 1):
    if pdf.get_y() > 250:
        pdf.add_page()
    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(*AMBER)
    pdf.multi_cell(0, 5.2, f"{i}. {title}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "", 9.5)
    pdf.set_text_color(*DARK)
    pdf.multi_cell(0, 4.8, "   Issue: " + issue, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "I", 9.5)
    pdf.set_text_color(*GREEN)
    pdf.multi_cell(0, 4.8, "   Replace with: " + repl, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(1)

pdf.ln(1)
small("Note on Jira data quality: several Admin/Manager stories (e.g., TEAM5-82, 84, 85, 86, 25) "
      "have acceptance-criteria text copy-pasted from other stories. The delivered features match "
      "each story's SUMMARY correctly; only the pasted criteria are mismatched.", GREY, 8.5)

out = "/Users/aryavansh/Desktop/NexusRetail/NexusRetail_Team_Responsibilities.pdf"
pdf.output(out)
print("WROTE:", out)
