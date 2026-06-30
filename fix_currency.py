import os

directory = "/Users/aryavansh/Desktop/NexusRetail/NexusRetail/Features/SalesAssociate/Sell"

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    new_content = content.replace(r'\$', r'$')

    if content != new_content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.swift'):
            process_file(os.path.join(root, file))

