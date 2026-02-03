import unittest
import os
import shutil
from librarian import KnowledgeGraphTool

class TestLibrarian(unittest.TestCase):
    def setUp(self):
        self.storage_folder = "./test_agent_memory"
        self.tool = KnowledgeGraphTool(storage_folder=self.storage_folder)
        os.makedirs(self.storage_folder, exist_ok=True)

    def tearDown(self):
        shutil.rmtree(self.storage_folder)

    def test_search_with_special_characters(self):
        test_file = "test_file.md"
        test_content = "This is a test file with special characters like .*+?^${}()|[]\\"
        with open(os.path.join(self.storage_folder, test_file), "w") as f:
            f.write(test_content)

        keywords = [".*+?^${}()|[]\\"]
        result = self.tool.search_notes(keywords)
        self.assertIn(test_file, result)

if __name__ == "__main__":
    unittest.main()
