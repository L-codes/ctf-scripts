#!/usr/bin/env python3
__author__ = 'L'
__date__ = '2017-08-11'
__version__ = '1.0.1'

import warnings
import logging
warnings.filterwarnings('ignore', category=DeprecationWarning)
logging.getLogger('scapy.runtime').setLevel(logging.ERROR)
import time,socket,threading,argparse,sys
from datetime import datetime


def prn(pk):
    p_or_s = pk.sprintf('%TCP.sport%').replace('_', '-')
    port = p_or_s if p_or_s.isdigit() else socket.getservbyname(p_or_s, 'tcp')
    service = 'unknown' if p_or_s.isdigit() else p_or_s
    return '{:<5} open  {}'.format(port, service)

def lfilter(pk):
    global open_ports
    flags = pk.sprintf('%TCP.flags%') == 'A' 
    window = pk.sprintf('%TCP.window%') != '0'
    ip = pk.sprintf('%IP.src%') == ip_src
    port = pk.sprintf('%TCP.sport%')
    if all((flags, window, ip, port not in open_ports)):
        open_ports.add(port)
        return True

def SYNProxy_filter(ip_src):
    sniff(lfilter=lfilter, prn=prn, store=0)


def send(ip, port, timeout):
    try:
        c = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
        c.settimeout(timeout)
        c.connect((ip, port))
        c.close()
    except:
        pass


def Thread(target, *args):
    t = threading.Thread(target=target, args=args)
    t.setDaemon(True)
    t.start()


def commandline():
    port_default = '1,7,9,11,13,15,17,18,19,20,21,22,23,25,37,42,43,49,50,53,57,65,67,68,70,77,79,80,87,88,95,101,102,104,105,107,109,110,111,113,115,117,119,123,129,135,137,138,139,143,161,162,163,164,174,177,178,179,191,194,199,201,202,204,206,209,210,213,220,345,346,347,369,370,371,372,389,406,427,443,444,445,464,465,487,500,554,607,610,611,612,628,631,512,513,514,515,526,530,531,532,538,540,543,544,546,547,548,549,556,563,587,636,655,706,749,765,873,989,990,992,993,994,995,1080,1093,1094,1194,1099,1214,1241,1352,1433,1434,1524,1525,1645,1646,1649,1677,1701,1812,1813,1863,1957,1958,1959,2000,2010,2010,2049,2086,2101,2119,2135,2401,2430,2431,2432,2433,2583,2628,2792,2811,2947,3050,3130,3260,3306,3493,3632,3689,3690,4031,4094,4190,4369,4373,4353,4569,4691,4899,5002,5050,5060,5061,5190,5222,5269,5308,5353,5432,5556,5671,5672,5688,6000,6001,6002,6003,6004,6005,6006,6007,6346,6347,6444,6445,6446,7000,7001,7002,7003,7004,7005,7006,7007,7008,7009,7100,8080,8181,8443,9101,9102,9103,9667,10809,10050,10051,10080,11112,11371,13720,13721,13722,13724,13782,13783,17500,22125,22128,22273,750,751,754,760,901,1109,2053,2105,2111,2121,871,1127,98,106,775,777,783,808,1001,1178,1236,1300,1313,1314,1529,2003,2121,2150,2600,2601,2602,2603,2604,2605,2606,2607,2608,2988,2989,4224,4557,4559,4600,4949,5051,5052,5151,5354,5355,5666,5667,5674,5675,5680,6514,6566,6667,8021,8081,8088,8990,9098,9418,9673,10000,10081,10082,10083,11201,15345,17004,20011,20012,24554,27374,30865,57000,60177,60179'
    def port_parse(ports_str):
        if '-' == ports_str:
            return range(1,65536)
        else:
            ports = ports_str.split(',')
            ps = []
            for p in ports:
                if '-' in p:
                    start, end = p.split('-')
                    ps += range(int(start), int(end)+1)
                else:
                    ps.append(int(p))
            return set(ps)
    parser = argparse.ArgumentParser(prog='L-SYN Proxy Scan', add_help=False, description='Author: {__author__}, Version: {__version__}, Date: {__date__}'.format(**globals()))
    parser.add_argument('TARGET', help='Hostname or IP address')
    parser.add_argument('-p', metavar='PORTS', help='Port Ranges', default=port_default)
    parser.add_argument('-t', metavar='THREADS', help='MAX Threads [default:%(default)s]', default=300, type=int)
    parser.add_argument('--timeout', metavar='SECONDS', help='Timeout [default:%(default)s]', default=5, type=int)
    if not sys.argv[1:]:
        parser.print_help()
        exit()
    args = parser.parse_args()
    try:
        ip = socket.gethostbyname(args.TARGET)
    except:
        raise SystemExit('Failed to resolve "{}"'.format(args.TARGET))
    return ip, port_parse(args.p), args.t, args.timeout


if __name__ == '__main__':
    ip, ports, MAX_THREAD, timeout = commandline()
    try:
        from scapy.all import sniff
    except:
        raise SystemExit('Please install scapy module')
    banner = r''' ______   ___   _   ____                        ____                  
/ ___\ \ / / \ | | |  _ \ _ __ _____  ___   _  / ___|  ___ __ _ _ __  
\___ \\ V /|  \| | | |_) | '__/ _ \ \/ / | | | \___ \ / __/ _` | '_ \ 
 ___) || | | |\  | |  __/| | | (_) >  <| |_| |  ___) | (_| (_| | | | |
|____/ |_| |_| \_| |_|   |_|  \___/_/\_\\__, | |____/ \___\__,_|_| |_|
      author: {__author__} version: {__version__}          |___/                        
'''.format(**globals())
    print(banner)
    open_ports = set()
    try:
        Thread(SYNProxy_filter, ip)
        start = time.time()
        print('Strting SYN Proxy Scan {} at {}'.format(__version__, datetime.now().strftime('%Y-%m-%d %H:%M:%S')))
        print('\nScan report for {}\nPORT  STATE SERVICE'.format(ip))
        for port in ports:
            Thread(send, ip, port, timeout)
            if threading.activeCount() > MAX_THREAD:
                time.sleep(0.5)

        while threading.activeCount() > 2:
            time.sleep(0.5)
        end = time.time() - start
        if not len(open_ports):
            print(' --   None   ----')
        print('\nSYN Proxy Scan Done: {} ports ({} open) in {:.2f} seconds'.format(len(ports), len(open_ports), end))
        exit()
    except KeyboardInterrupt:
        raise SystemExit('\nInterrrput success')
