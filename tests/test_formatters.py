"""
app.core.formatters birim testleri.
"""

import unittest

from app.core.formatters import format_duration


class TestFormatters(unittest.TestCase):

    def test_format_duration_standard(self):
        self.assertEqual(format_duration(0), "0 dk")
        self.assertEqual(format_duration(59), "0 dk")
        self.assertEqual(format_duration(60), "1 dk")
        self.assertEqual(format_duration(3600), "1 sa 0 dk")
        self.assertEqual(format_duration(3665), "1 sa 1 dk")
        self.assertEqual(format_duration(7320), "2 sa 2 dk")

    def test_format_duration_compact(self):
        self.assertEqual(format_duration(0, compact=True), "0dk")
        self.assertEqual(format_duration(60, compact=True), "1dk")
        self.assertEqual(format_duration(3665, compact=True), "1sa 1dk")

    def test_format_duration_negative_values(self):
        self.assertEqual(format_duration(-50), "0 dk")
        self.assertEqual(format_duration(-10, compact=True), "0dk")


if __name__ == "__main__":
    unittest.main()
