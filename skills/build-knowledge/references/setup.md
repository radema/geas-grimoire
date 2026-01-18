# Setup Instructions for Build Knowledge

Before using the Librarian tool for the first time, ensure the environment is prepared.

## Steps

1. **Install Dependencies**
   Use `uv` to install necessary packages (primarily `nltk` for synonym expansion).
   ```bash
   uv run pip install -r .agent/skills/build-knowledge/scripts/requirements.txt
   ```

2. **Initialize Environment**
   Run the setup script to download NLTK data (wordnet) and create the initial memory folder.
   ```bash
   uv run python .agent/skills/build-knowledge/scripts/setup.py
   ```

3. **Verify**
   Check if `.agent_memory/000_Index.md` exists. This is your root knowledge node.
