import os
import unittest


class RunfilesTest(unittest.TestCase):

    def test_types_not_in_runfiles(self):
        runfiles_dir = os.environ.get("RUNFILES_DIR") or os.environ.get(
            "TEST_SRCDIR"
        )
        self.assertIsNotNone(runfiles_dir, "Runfiles directory must be set")
        # Walk runfiles_dir and ensure dependency.py does not exist anywhere in runfiles
        found = []
        for root, _, files in os.walk(runfiles_dir):
            for file in files:
                if file == "dependency.py":
                    found.append(os.path.join(root, file))
        self.assertEqual(
            found,
            [],
            f"Types passed via aspect should not be present in target runfiles: {found}",
        )



if __name__ == "__main__":
    unittest.main()
