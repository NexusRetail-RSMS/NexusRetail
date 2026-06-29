import os
import re

directory = "/Users/aryavansh/Desktop/NexusRetail/NexusRetail/Features/SalesAssociate/Sell"

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replace ₹\(Int(variable.price)) with $\(String(format: "%.2f", variable.price))
    # Pattern: ₹\(Int(([^)]+)))
    new_content = re.sub(r'₹\\\(Int\(([^)]+)\)\)', r'$\\($1)', content)
    
    # We should actually format it to 2 decimal places.
    # We can do this: $\(String(format: "%.2f", \1))
    new_content = re.sub(r'₹\\\(Int\(([^)]+)\)\)', r'\\$\\(String(format: "%.2f", \1))', content)

    # Some are just ₹\(cachedSubtotal) or similar without Int() if it's already Int? 
    # Let's just find any remaining ₹ and replace with $
    new_content = new_content.replace('₹', '$')

    if content != new_content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.swift'):
            process_file(os.path.join(root, file))

