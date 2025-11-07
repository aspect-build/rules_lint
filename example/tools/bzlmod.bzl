"""Utility functions for Bzlmod-related checks."""

def bzlmod_is_enabled():
    """Returns True if Bzlmod is enabled, False otherwise."""
    str(Label("//:invalid")).startswith("@@")
