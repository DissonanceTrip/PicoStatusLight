import requests
import sys
def session_for_src_addr(addr: str) -> requests.Session:
    session = requests.Session()
    for prefix in ('http://', 'https://'):
        session.get_adapter(prefix).init_poolmanager(
            # those are default values from HTTPAdapter's constructor
            connections=requests.adapters.DEFAULT_POOLSIZE,
            maxsize=requests.adapters.DEFAULT_POOLSIZE,
            # This should be a tuple of (address, port). Port 0 means auto-selection.
            source_address=(addr, 0),
        )
    return session
ip = sys.argv[1]
s = session_for_src_addr(ip)
s.get('http://192.168.0.128/available') # change this url to your Pico's local IP