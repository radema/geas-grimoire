import os
import subprocess
import re
import sys
import argparse

try:
    from nltk.corpus import wordnet
except ImportError:
    wordnet = None


class KnowledgeGraphTool:
    def __init__(
        self,
        storage_folder="./.agent_memory",
        max_steps=15,
    ):
        self.storage_folder = os.path.abspath(storage_folder)
        self.visited = set()
        self.max_steps = max_steps
        self.current_step = 0

        # Ensure the folder exists immediately
        if not os.path.exists(self.storage_folder):
            os.makedirs(self.storage_folder)
            # Create a root index if empty
            index_path = os.path.join(self.storage_folder, "000_Index.md")
            if not os.path.exists(index_path):
                with open(index_path, "w") as f:
                    f.write("# Knowledge Base Index\n\nStarting point.")

    def _safe_path(self, filename):
        """Security: Ensure filename ends in .md and stays in folder"""
        if not filename.endswith(".md"):
            filename += ".md"
        # Allow slashes for subdirectories to support organized vaults
        clean_name = re.sub(r"[^a-zA-Z0-9_\-\.\/]", "", filename)
        return os.path.join(self.storage_folder, clean_name)

    def _expand_synonyms(self, keywords):
        """Cheap NLTK synonym expansion"""
        if not wordnet:
            return keywords
        expanded = set(keywords)
        for k in keywords:
            try:
                for syn in wordnet.synsets(k):
                    for lemma in syn.lemmas():
                        expanded.add(lemma.name().replace("_", " "))
            except:  # noqa: E722
                pass
        return list(expanded)

    # --- READ TOOLS ---

    def search_notes(self, keywords: list):
        """Finds files containing keywords (using grep)"""
        self.current_step += 1
        all_terms = self._expand_synonyms(keywords)
        pattern = "|".join(all_terms)

        # grep -r -i -l (recursive, case-insensitive, filename only)
        # Fix: handle cases where pattern might be empty or problematic
        if not pattern:
            return "Error: No keywords provided."

        cmd = ["grep", "-r", "-i", "-l", "-E", pattern, self.storage_folder]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if not result.stdout:
                return f"No matches found for: {all_terms}"
            # Return list of filenames
            files = [os.path.basename(f) for f in result.stdout.splitlines()][:10]
            return f"Found matches in: {files}"
        except Exception as e:
            return f"Search Error: {str(e)}"

    def read_note(self, filename: str):
        """Reads a specific file"""
        self.current_step += 1
        path = self._safe_path(filename)

        if not os.path.exists(path):
            return "Error: File does not exist. Did you mean to create it?"

        with open(path, "r", encoding="utf-8") as f:
            return f.read()

    # --- WRITE TOOLS (New) ---

    def create_note(self, filename: str, content: str):
        """Creates a new file. Fails if it already exists."""
        path = self._safe_path(filename)
        if os.path.exists(path):
            return f"Error: '{filename}' already exists. Use append_note or overwrite logic."

        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        return f"Success: Created '{filename}'."

    def append_note(self, filename: str, content: str):
        """Adds text to the end of an existing note."""
        path = self._safe_path(filename)
        if not os.path.exists(path):
            return f"Error: '{filename}' does not exist. Use create_note first."

        with open(path, "a", encoding="utf-8") as f:
            f.write("\n" + content)
        return f"Success: Appended to '{filename}'."

    def get_status(self):
        return f"Steps: {self.current_step}/{self.max_steps}. Folder: {self.storage_folder}"


def main():
    parser = argparse.ArgumentParser(description="Librarian: Knowledge Base Tool")
    parser.add_argument("command", choices=["search", "read", "create", "append"])
    parser.add_argument("--filename", help="Filename for read/create/append")
    parser.add_argument("--content", help="Content for create/append")
    parser.add_argument("--keywords", nargs="+", help="Keywords for search")
    parser.add_argument("--storage", default="./.agent_memory", help="Storage folder")

    args = parser.parse_args()
    tool = KnowledgeGraphTool(storage_folder=args.storage)

    if args.command == "search":
        if not args.keywords:
            print("Error: --keywords required for search")
            sys.exit(1)
        print(tool.search_notes(args.keywords))
    elif args.command == "read":
        if not args.filename:
            print("Error: --filename required for read")
            sys.exit(1)
        print(tool.read_note(args.filename))
    elif args.command == "create":
        if not args.filename or not args.content:
            print("Error: --filename and --content required for create")
            sys.exit(1)
        print(tool.create_note(args.filename, args.content))
    elif args.command == "append":
        if not args.filename or not args.content:
            print("Error: --filename and --content required for append")
            sys.exit(1)
        print(tool.append_note(args.filename, args.content))


if __name__ == "__main__":
    main()
