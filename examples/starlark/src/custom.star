"""Example generic Starlark file with a Buildifier warning."""

def custom_macro():
    values = []
    values += ["hello"]
    return values
