try:
    import json
except ImportError:
    import sys
    sys.path.append('simplejson-2.3.3')
    import simplejson as json
    
import urllib



class NameTranslation:

    def __init__(self, url):
        if url != None:
            self.url = url

    def get_all_translations(self, name):

        arg_hash = { 'method': 'NameTranslation.get_all_translations',
                     'params': [name],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def get_scientific_names_by_name(self, name):

        arg_hash = { 'method': 'NameTranslation.get_scientific_names_by_name',
                     'params': [name],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def get_all_names_by_name(self, name):

        arg_hash = { 'method': 'NameTranslation.get_all_names_by_name',
                     'params': [name],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def get_scientific_name_by_tax_id(self, tax_id):

        arg_hash = { 'method': 'NameTranslation.get_scientific_name_by_tax_id',
                     'params': [tax_id],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def get_tax_id_by_scientific_name(self, name):

        arg_hash = { 'method': 'NameTranslation.get_tax_id_by_scientific_name',
                     'params': [name],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def get_tax_ids_by_name(self, name):

        arg_hash = { 'method': 'NameTranslation.get_tax_ids_by_name',
                     'params': [name],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def get_all_names_by_tax_id(self, tax_id):

        arg_hash = { 'method': 'NameTranslation.get_all_names_by_tax_id',
                     'params': [tax_id],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None




        
