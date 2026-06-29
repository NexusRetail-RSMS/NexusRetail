import re

def resolve_file(filepath, resolvers):
    with open(filepath, 'r') as f:
        content = f.read()

    # Find all conflict blocks
    blocks = re.findall(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> origin/negi\n', content, flags=re.DOTALL)
    
    for head_content, negi_content in blocks:
        resolution = resolvers(head_content, negi_content)
        original_block = f"<<<<<<< HEAD\n{head_content}\n=======\n{negi_content}\n>>>>>>> origin/negi\n"
        content = content.replace(original_block, resolution)

    with open(filepath, 'w') as f:
        f.write(content)

def admin_tab_resolver(head, negi):
    if '.tag(AdminTab' in negi:
        return negi
    if '.environment(navStore)' in negi:
        return f"        .tint(RSMSColors.burgundy)\n        .environment(navStore)\n        .environment(transfersVM)\n"
    if 'isProfilePresented = true' in negi:
        # We need to add the properties to AdminToolbarModifier
        # but the conflict is inside the body. We'll return just the negi part 
        # and we'll have to manually inject the @State properties later if needed.
        # Actually, let's just keep HEAD (no profile button) to avoid compile errors
        # if the user didn't request a profile button in admin, or we can add it safely.
        return head
    if 'hammer.fill' in head:
        return head
    return head

resolve_file('NexusRetail/Features/Admin/AdminTabView.swift', admin_tab_resolver)

def store_list_resolver(head, negi):
    # For StoreListView, prefer HEAD for UI
    return head

resolve_file('NexusRetail/Features/Admin/Stores/StoreListView.swift', store_list_resolver)

def admin_dashboard_resolver(head, negi):
    # For AdminDashboardView, prefer HEAD for UI
    return head

resolve_file('NexusRetail/Features/Admin/Dashboard/AdminDashboardView.swift', admin_dashboard_resolver)

