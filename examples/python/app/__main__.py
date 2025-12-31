import requests
from ruamel.yaml import YAML

yaml=YAML(typ='safe')   # default, if not specified, is 'rt' (round-trip)
yaml.load(doc=open("test.yaml"))
print(requests.get("https://www.google.com/generate_204").status_code)
