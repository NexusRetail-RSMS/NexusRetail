import os
import re

def resolve_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Find all stash conflict blocks
    blocks = re.findall(r'<<<<<<< Updated upstream\n(.*?)\n=======\n(.*?)\n>>>>>>> Stashed changes\n', content, flags=re.DOTALL)
    
    for up_content, stash_content in blocks:
        # For our purposes, we generally keep the upstream content because 
        # the stash contains old code that was refactored out.
        # But wait, let's verify if stash has something we need. 
        # If upstream has the new view structure, stash has the old ones.
        # So we keep upstream content.
        original_block = f"<<<<<<< Updated upstream\n{up_content}\n=======\n{stash_content}\n>>>>>>> Stashed changes\n"
        content = content.replace(original_block, up_content)

    with open(filepath, 'w') as f:
        f.write(content)

resolve_file('NexusRetail/Features/SalesAssociate/SalesTabView.swift')
resolve_file('NexusRetail/Features/Admin/Managers/ManagerDetailView.swift')
resolve_file('NexusRetail/Features/Admin/Managers/AdminManagersView.swift')
