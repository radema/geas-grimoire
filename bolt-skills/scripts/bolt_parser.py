import argparse
import sys
import re
from pathlib import Path

def extract_section(filepath: str, section_name: str) -> str:
    path = Path(filepath)
    if not path.is_file():
        return f"Error: File {filepath} not found."

    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return f"Error reading file: {e}"

    # Find the heading that contains the section name
    # Matches #, ##, ### etc. followed by text containing section_name
    pattern = re.compile(rf'^(#+)\s+.*?{re.escape(section_name)}.*$', re.IGNORECASE | re.MULTILINE)
    match = pattern.search(content)
    
    if not match:
        return f"Error: Section containing '{section_name}' not found in {filepath}."
    
    start_pos = match.end()
    heading_level = len(match.group(1))
    
    # Find the next heading of the same or higher level (fewer or equal '#'s)
    # E.g., if we matched ## (level 2), the next section ends at the next ^# or ^##.
    next_pattern = re.compile(rf'^(#{{1,{heading_level}}})\s+.*$', re.MULTILINE)
    next_match = next_pattern.search(content, start_pos)
    
    end_pos = next_match.start() if next_match else len(content)
    
    return content[start_pos:end_pos].strip()

def main():
    parser = argparse.ArgumentParser(description="Extract a specific section from a markdown document.")
    parser.add_argument("filepath", help="Path to the markdown file")
    parser.add_argument("--section", required=True, help="Substring of the heading to extract")
    args = parser.parse_args()
    
    extracted = extract_section(args.filepath, args.section)
    print(extracted)

if __name__ == "__main__":
    main()
