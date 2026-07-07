import os
import re

swift_files = []
for root, dirs, files in os.walk('.'):
    for f in files:
        if f.endswith('.swift'):
            swift_files.append(os.path.join(root, f))

for f in swift_files:
    with open(f, 'r') as file:
        content = file.read()
    
    # We want to find Text(some_var) inside pickers that might be missing LocalizedStringKey
    # It's easier to just blindly replace Text(some_var.rawValue) with Text(LocalizedStringKey(some_var.rawValue))
    # and Text(some_var.localizedName) with Text(LocalizedStringKey(some_var.localizedName))
    
    new_content = re.sub(r'Text\(([A-Za-z0-9_\.]+\.(?:rawValue|localizedName))\)', r'Text(LocalizedStringKey(\1))', content)
    
    if new_content != content:
        with open(f, 'w') as file:
            file.write(new_content)
        print(f"Fixed {f}")
