import os
import nltk

print("Initializing Independent Knowledge Graph...")

# 1. Download Synonym Data
try:
    nltk.download("wordnet")
    nltk.download("omw-1.4")
except:  # noqa: E722
    pass

# 2. Create the Memory Folder
folder = "./.agent_memory"
if not os.path.exists(folder):
    os.makedirs(folder)
    print(f"Created memory folder at {folder}")

# 3. Create the Root Node (The Entry Point)
index_path = os.path.join(folder, "000_Index.md")
if not os.path.exists(index_path):
    with open(index_path, "w") as f:
        f.write("# Main Index\n\n## Topics\n- (Empty)")
    print("Created 000_Index.md (The Root Node)")

print("Setup Complete. Your agent is ready to write.")
