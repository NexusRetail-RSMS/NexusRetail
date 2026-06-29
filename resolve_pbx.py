import re

with open('NexusRetail.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

blocks = re.findall(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> origin/negi\n', content, flags=re.DOTALL)

for head_content, negi_content in blocks:
    if 'DEVELOPMENT_TEAM' in head_content:
        # Keep HEAD for development team
        res = head_content
    elif 'Config.xcconfig' in head_content:
        # Keep HEAD's Config.xcconfig reference and add any negi content (which might be empty or other files)
        # But wait, negi also added DFC599BE2FEBCD9300B2BFED for Config.xcconfig which is a duplicate!
        # If negi_content has Config.xcconfig, we skip it.
        filtered_negi = [line for line in negi_content.split('\n') if 'Config.xcconfig' not in line]
        res = head_content + '\n' + '\n'.join(filtered_negi)
    else:
        # For everything else, keep both
        res = head_content + '\n' + negi_content

    original_block = f"<<<<<<< HEAD\n{head_content}\n=======\n{negi_content}\n>>>>>>> origin/negi\n"
    content = content.replace(original_block, res)

with open('NexusRetail.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

