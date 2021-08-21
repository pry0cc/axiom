#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# This file is part of nmaptocsv.
#
# Copyright (C) 2012, 2019 Thomas Debize <tdebize at mail.com>
# All rights reserved.
#
# nmaptocsv is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# nmaptocsv is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with nmaptocsv.  If not, see <http://www.gnu.org/licenses/>.

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

# Global imports
import sys
import re
import csv
import struct
import socket
import itertools
import argparse
import xml.etree.cElementTree as ET

# Python 2 and 3 compatibility
if (sys.version_info < (3, 0)):
    izip = itertools.izip
    fd_read_options = 'rb'
    fd_write_options = 'wb'
else:
    izip = zip
    fd_read_options = 'r'
    fd_write_options = 'w'

# Script version
VERSION = '1.6'

# Options definition
parser = argparse.ArgumentParser()

# Options definition
mandatory_grp = parser.add_argument_group('Mandatory parameters')
mandatory_grp.add_argument('-i', '--input', help = 'Nmap scan output file in normal (-oN) or Grepable (-oG) format (stdin if not specified)')
mandatory_grp.add_argument('-x', '--xml-input', help = 'Nmap scan output file in XML (-oX) format')

output_grp = parser.add_argument_group('Output parameters')
output_grp.add_argument('-o', '--output', help = 'CSV output filename (stdout if not specified)')
output_grp.add_argument('-f', '--format', help = 'CSV column format { fqdn, rdns, hop_number, ip, mac_address, mac_vendor, port, protocol, os, script, service, version } (default: ip-fqdn-port-protocol-service-version)', default = 'ip-fqdn-port-protocol-service-version')
output_grp.add_argument('-S', '--script', help = 'Adds the script column in output, alias for -f "ip-fqdn-port-protocol-service-version-script"', action = 'store_const', const = 'ip-fqdn-port-protocol-service-version-script')
output_grp.add_argument('-d', '--delimiter', help = 'CSV output delimiter (default ";"). Ex: -d ","', default = ';')
output_grp.add_argument('-n', '--no-newline', help = 'Do not insert a newline between each host. By default, a newline is added for better readability', action = 'store_true', default = False)
output_grp.add_argument('-s', '--skip-header', help = 'Do not print the CSV header', action = 'store_true', default = False)

# Handful patterns
#-- IP regex
p_ip_elementary = r'(?:[\d]{1,3})\.(?:[\d]{1,3})\.(?:[\d]{1,3})\.(?:[\d]{1,3})'
p_mac_elementary = r'[0-9a-fA-F][0-9a-fA-F]:){5}([0-9a-fA-F][0-9a-fA-F]'

# Nmap Normal Output patterns
#-- Target
p_ip_nmap5 = r'Interesting.*on\s(?:(?P<fqdn_nmap5>.*) (?=\((?P<ip_nmap5>%s)\)))|Interesting.*on\s(?P<ip_only_nmap5>.*)\:' % p_ip_elementary
p_ip_nmap6 = r'Nmap.*for\s(?:(?P<fqdn_nmap6>.*) (?=\((?P<ip_nmap6>%s)\)))|Nmap.*for\s(?P<ip_only_nmap6>%s)$' % (p_ip_elementary, p_ip_elementary)

p_ip = re.compile('%s|%s' % (p_ip_nmap5, p_ip_nmap6))

#-- rDNS
p_rdns = re.compile(r'rDNS record for (?P<ip>%s):\s(?P<rdns>.*)$' % p_ip_elementary)

#-- Port header
p_port_header = re.compile(r'^(?P<port>PORT)\s+(?P<state>STATE)\s+(?P<service>SERVICE)\s+(?P<reason>REASON\s*)?(?P<version>VERSION$)?')

#-- Port finding
p_port_without_reason = re.compile(r'^(?P<number>[\d]+)\/(?P<protocol>tcp|udp)\s+(?:open|open\|filtered)\s+(?P<service>[\w\S]*)(?:\s*(?P<version>.*))?$')
p_port_with_reason = re.compile(r'^(?P<number>[\d]+)\/(?P<protocol>tcp|udp)\s+(?:open|open\|filtered)\s+(?P<service>[\w\S]*)\s+(?P<reason>.* ttl [\d]+)\s*(?:\s*(?P<version>.*))$')

#-- Script output finding
p_script = re.compile(r'^\|[\s|\_](?P<script>.*)$')

#-- MAC address
p_mac = re.compile(r'MAC Address:\s(?P<mac_addr>(%s))\s\((?P<mac_vendor>.*)\)' % p_mac_elementary)

#-- OS detection (pattern order is important, the latter position the more precise and reliable the information is)
p_os = re.compile(r'(?:^Service Info: OS|^OS CPE|\s+OS|^OS details|smb-os-discovery|\|):\s(?P<os>[^;]+)')

#-- Network distance
p_network_dist = re.compile(r'Network Distance:\s(?P<hop_number>\d+)\shops?')

# Nmap Grepable output 
#-- Target, Ports
p_grepable = re.compile(r'(?P<whole_line>^Host:\s.*)')


# Handful functions
def dottedquad_to_num(ip):
    """
        Convert decimal dotted quad string IP to long integer
    """
    return struct.unpack('!L',socket.inet_aton(ip))[0]

def num_to_dottedquad(n):
    """
        Convert long int IP to dotted quad string
    """
    return socket.inet_ntoa(struct.pack('!L',n))

def unique_match_from_list(list):
    """
        Check the list for a potential pattern match

        @param list : a list of potential matching groups
        
        @rtype : return the string representation of the unique value that matched, or nothing if nothing matched
    """
    result = ''
    for item in list:
        if item != None:
            result = str(item)
    
    return result

def extract_matching_pattern(regex, group_name, unfiltered_list):
    """
        Return the desired group_name from a list of matching patterns

        @param regex : a regular expression with named groups
        @param group_name : the desired matching group name value
        @param unfiltered_list : a list of matches
        
        @rtype : the string value
    """
    result = ''
    filtered_list = list(filter(regex.search, unfiltered_list))
    
    if len(filtered_list) == 1:
        filtered_string = ''.join(filtered_list)
        result = regex.search(filtered_string).group(group_name)
    
    return result

class Host:
    def __init__(self, ip, fqdn=''):
        self.ip_dottedquad = ip
        self.ip_num = dottedquad_to_num(ip)
        self.fqdn = fqdn
        self.rdns = ''
        self.ports = []
        self.os = ''
        self.mac_address = ''
        self.mac_address_vendor = ''
        self.network_distance = ''
        
    def add_port(self, port):
        self.ports.append(port)
    
    # Getters
    def get_ip_num_format(self):
        return str(self.ip_num)
    
    def get_ip_dotted_format(self):
        return str(self.ip_dottedquad)
    
    def get_fqdn(self):
        return str(self.fqdn)
    
    def get_rdns_record(self):
        return str(self.rdns)
    
    def get_port_list(self):
        return self.ports
    
    def get_port_number_list(self):
        if not(self.get_port_list()):
            return ['']
        else:
            result = []
            for port in self.get_port_list():
                result.append(port.get_number())
        return result
    
    def get_port_protocol_list(self):
        if not(self.get_port_list()):
            return ['']
        else:
            result = []
            for port in self.get_port_list():
                result.append(port.get_protocol())
        return result

    def get_port_service_list(self):
        if not(self.get_port_list()):
            return ['']
        else:
            result = []
            for port in self.get_port_list():
                result.append(port.get_service())
        return result

    def get_port_version_list(self):
        if not(self.get_port_list()):
            return ['']
        else:
            result = []
            for port in self.get_port_list():
                result.append(port.get_version())
        return result

    def get_port_script_list(self):
        if not(self.get_port_list()):
            return ['']
        else:
            result = []
            for port in self.get_port_list():
                result.append(port.get_script())
        return result
    
    def get_os(self):
        return str(self.os)
    
    def get_mac_address(self):
        return str(self.mac_address)
    
    def get_mac_address_vendor(self):
        return str(self.mac_address_vendor)
    
    def get_network_distance(self):
        return str(self.network_distance)
        
    # Setters
    def set_fqdn(self, fqdn):
        self.fqdn = fqdn
        
    def set_rdns_record(self, rdns_record):
        self.rdns = rdns_record

    def set_os(self, os):
        self.os = os

    def set_mac(self, mac_address, mac_address_vendor = ''):
        self.mac_address = mac_address
        self.mac_address_vendor = mac_address_vendor

    def set_network_distance(self, network_distance):
        self.network_distance = network_distance

class Port:
    def __init__(self, number, protocol, service='', version='', script=''):
        self.number = number
        self.protocol = protocol
        self.service = service
        self.version = version
        self.script = script
    
    def get_number(self):
        return self.number
        
    def get_protocol(self):
        return self.protocol
    
    def get_service(self):
        return self.service
    
    def get_version(self):
        return self.version
    
    def get_script(self):
        return self.script.strip()
    
    def set_service(self, service):
        self.service = service
    
    def set_version(self, version):
        self.version = version
    
    def set_script(self, script):
        self.script = script

def split_grepable_match(raw_string):
    """
        Split the raw line to a neat Host object
        
        @param raw_string : the whole 'Host' line
        
        @rtype : return an Host object
    """
    global p_ip_elementary
    
    splitted_fields = raw_string.split("\t")
    
    # Patterns
    p_host = re.compile(r'Host:\s(?P<ip>%s)\s+\((?P<fqdn>|.*)\)' % p_ip_elementary) 
    p_ports = re.compile(r'Ports:\s+(?P<ports>.*)/')
    p_os = re.compile(r'OS:\s(?P<os>.*)')
    
    # Extracted named-group matches
    IP_str = extract_matching_pattern(p_host, 'ip', splitted_fields)
    FQDN_str = extract_matching_pattern(p_host, 'fqdn', splitted_fields)
    ports_str = extract_matching_pattern(p_ports, 'ports', splitted_fields)
    OS_str = extract_matching_pattern(p_os, 'os', splitted_fields)
    
    current_host = Host(IP_str, FQDN_str)
    current_host.set_os(OS_str)
    
    # Let's split the raw port list
    all_ports = ports_str.split(', ')
    
    # Keep only open ports
    open_ports_list = filter(lambda p: '/open/' in p, all_ports)
    
    for open_port in open_ports_list:
        # Extract each field from the format [port number / state / protocol / owner / service / rpc info / version info]
        # -- Thanks to http://www.unspecific.com/nmap-oG-output/
        number, state, protocol, owner, service, version = open_port.split('/', 5)
        
        # remove potential leading and trailing slashes on version
        version = version.strip('/')
        
        new_port = Port(number, protocol, service, version)
        
        current_host.add_port(new_port)
    
    return current_host

def parse(fd):
    """
        Parse the data according to several regexes
        
        @param fd : input file descriptor, could be a true file or stdin
        
        @rtype : return a list of <Host> objects indexed from their numerical IP representation
    """
    global p_ip_elementary, p_ip, p_port_without_reason, p_port_with_reason, p_grepable, p_script, p_mac, p_os, p_network_dist, p_rdns
    
    IPs = {}
    last_host = None
    p_port = p_port_without_reason
    in_script_line = False
    script = ''
    
    lines = [l.rstrip() for l in fd.readlines()]
    for line in lines:
        
        # 1st case:     Nmap Normal Output
        #-- 1st action: Grab the IP
        IP = p_ip.search(line)
        if IP:
            # Check out what patterns matched
            IP_potential_match = [IP.group('ip_nmap5'), IP.group('ip_only_nmap5'), IP.group('ip_nmap6'), IP.group('ip_only_nmap6')]
            IP_str = unique_match_from_list(IP_potential_match)
            
            FQDN_potential_match = [IP.group('fqdn_nmap5'), IP.group('fqdn_nmap6')]
            FQDN_str = unique_match_from_list(FQDN_potential_match)
            
            new_host = Host(IP_str, FQDN_str)
            
            IPs[new_host.get_ip_num_format()] = new_host
            
            last_host = new_host
        
        # 1st case: Nmap Normal Output
        #-- 2nd action: Check if there is a rDNS record
        rDNS = p_rdns.search(line)
        if rDNS:
            if rDNS.group('ip') and rDNS.group('rdns'):
                rdns_ip_num_format = str(dottedquad_to_num(rDNS.group('ip')))
                if rdns_ip_num_format in IPs.keys():
                    IPs[rdns_ip_num_format].set_rdns_record(rDNS.group('rdns'))
        
        # 1st case:     Nmap Normal Output
        #-- 3rd action: Check the port header, to know if there is a reason column
        port_header = p_port_header.search(line)
        if port_header:
            if port_header.group('reason'):
                p_port = p_port_with_reason
            else:
                p_port = p_port_without_reason
                
        # 1st case:     Nmap Normal Output
        #-- 4th action: Grab the script output
        script_line = p_script.search(line)
        if script_line:
            in_script_line = True
            script = script + script_line.group('script') + '\n'
        else:
            # We were in a script output section, now it's finished
            if in_script_line:
                last_port = last_host.get_port_list()[-1]
                last_port = last_port.set_script(script)
                
                # reseting trackers
                in_script_line = False
                script = ''
        
        
        # 1st case:     Nmap Normal Output
        #-- 5th action: Grab the port
        port = p_port.search(line)
        if port and last_host != None:
            number = str(port.group('number'))
            protocol = str(port.group('protocol'))
            service = str(port.group('service'))
            version = str(port.group('version'))
                        
            new_port = Port(number, protocol, service, version)
            
            last_host.add_port(new_port)
        
        
        # 1st case:     Nmap Normal Output
        #-- 6th action: Grab the MAC address
        mac = p_mac.search(line)
        if mac:
            last_host.set_mac(str(mac.group('mac_addr')), str(mac.group('mac_vendor')))
        
        
        # 1st case:     Nmap Normal Output  
        #-- 7th action: Grab the OS detection
        os = p_os.search(line)
        if os:
            last_host.set_os(str(os.group('os')))
        
        
        # 1st case:     Nmap Normal Output
        #-- 8th action: Grab the network distance
        network_distance = p_network_dist.search(line)
        if network_distance:
            last_host.set_network_distance(str(network_distance.group('hop_number')))
        
        
        # 2nd case:         Nmap Grepable Output
        #-- 1 sole action:  Grab the whole line for further splitting
        grepable = p_grepable.search(line)
        if grepable:
            if grepable.group('whole_line'):
                new_host = split_grepable_match(grepable.group('whole_line'))
                
                # Update the occurence found with 'Status: Up'
                IPs[new_host.get_ip_num_format()] = new_host
                
                last_host = new_host
    
    return IPs


def parse_xml(xml_file):
    """
        Parse the XML file 
        
        @param xml_file : the input file
        
        @rtype : return a list of <Host> objects indexed from their numerical IP representation
    """
    IPs = {}
    try:
        tree = ET.ElementTree(file=xml_file)
        root = tree.getroot()
    except ET.ParseError as e:
        print("[!] An error has occurred while parsing the XML file: '%s'.\nExiting" % e)
        return None
    
    for host in root.findall('host'):
        if 'up' in host.find('status').get('state'):
            # IP, MAC
            addresses = host.findall('address')
            for address in addresses:
                if 'ipv4' in address.get('addrtype') and address.get('addr'):
                    ip_dottedquad = address.get('addr')
                    new_host = Host(ip_dottedquad)
                    
                if 'mac' in address.get('addrtype'):
                    mac_addr = address.get('addr')
                    mac_vendor = address.get('vendor')
                    new_host.set_mac(mac_addr, mac_vendor)
            
            # FQDN, RDNS
            hostnames = host.findall('./hostnames/hostname')
            for hostname in hostnames:
                if hostname.get('name') and 'user' in hostname.get('type'):
                    new_host.set_fqdn(hostname.get('name'))
                if hostname.get('name') and 'PTR' in hostname.get('type'):
                    new_host.set_rdns_record(hostname.get('name'))
            
            # Ports (protocol, number, service, version) and script output
            open_ports = host.findall("./ports/port/state[@state='open']/..")
            for port in open_ports:
                protocol = port.get('protocol')
                number = port.get('portid')
                new_port = Port(number, protocol)
                
                service = port.find('service')
                if service != None:
                    service_name = service.get('name') if service.get('name') else ''
                    
                    service_product = service.get('product') if service.get('product') else ''
                    service_version = service.get('version') if service.get('version') else ''
                    service_extrainfo = service.get('extrainfo') if service.get('extrainfo') else ''
                    
                    version = ("%s %s %s" % (service_product, service_version, service_extrainfo)).strip()
                    new_port.set_service(service_name) 
                    new_port.set_version(version)
                
                scripts = port.findall('script')
                script_output = ''
                for script in scripts:
                    script_output = script_output + "\n%s: %s" % (script.get('id'), script.get('output'))

                new_port.set_script(script_output)
                
                new_host.add_port(new_port)
                
            # OS
            osmatches = host.findall('./os/osmatch')
            os = "|".join(osmatch.get('name') for osmatch in osmatches)
            new_host.set_os(os)
        
            # Hop
            hop_number = len(host.findall('./trace/hop'))
            new_host.set_network_distance(hop_number)
                
            IPs[new_host.get_ip_num_format()] = new_host
    
    return IPs
    
def is_format_valid(fmt):
    """
        Check for the supplied custom output format

        @param fmt : the supplied format
        
        @rtype : True or False
    """ 
    supported_format_objects = [ 'fqdn', 'rdns', 'hop_number', 'ip', 'mac_address', 'mac_vendor', 'port', 'protocol', 'os', 'script', 'service', 'version' ]
    unknown_items = []
    
    for fmt_object in fmt.split('-'):
        if not(fmt_object in supported_format_objects):
            unknown_items.append(fmt_object)
    
    if unknown_items:
        return False, unknown_items
    else:
        return True, None

def formatted_item(host, format_item):
    """
        return the attribute value related to the host
        
        @param host : host object
        @param format_item : the attribute supplied in the custom format
        
        @rtype : the <list> attribute value
    """
    if isinstance(host, Host):
        option_map = {
                    'fqdn':                 [host.get_fqdn()],
                    'rdns':                 [host.get_rdns_record()],
                    'hop_number':           [host.get_network_distance()],
                    'ip':                   [host.get_ip_dotted_format()],
                    'mac_address':          [host.get_mac_address()],
                    'mac_vendor':           [host.get_mac_address_vendor()],
                    'os':                   [host.get_os()],
                    'port':                 host.get_port_number_list(),
                    'protocol':             host.get_port_protocol_list(),
                    'service':              host.get_port_service_list(),
                    'version':              host.get_port_version_list(),
                    'script':               host.get_port_script_list()
                     }
        
        if format_item in option_map.keys():
            return option_map[format_item]
        else:
            return ''
    else:
        return []

def repeat_attributes(attribute_list):
    """
        repeat attribute lists to the maximum for the 
        
        @param attribute_list : raw list with different attribute list length
        
        @rtype : a list consisting of length equal attribute list
    """
    max_number = len(max(attribute_list, key=len))
    attribute_list = map(lambda x: x * max_number, attribute_list)
    
    return attribute_list

def generate_csv(fd, results, options):
    """
        Generate a plain ';' separated csv file with the desired or default attribute format

        @param fd : output file descriptor, could be a true file or stdout
    """
    if results:
        spamwriter = csv.writer(fd, delimiter=options.delimiter, quoting=csv.QUOTE_ALL, lineterminator='\n')
        
        splitted_options_format = options.format.split('-')
        
        if not options.skip_header:
            csv_header = [format_item.upper() for format_item in splitted_options_format]
            spamwriter.writerow(csv_header)
        
        # for IP in sorted(results.iterkeys())
        for IP in sorted(results):
            formatted_attribute_list = []
            
            for index,format_item in enumerate(splitted_options_format):
                item = formatted_item(results[IP], format_item)
                formatted_attribute_list.insert(index, item)
            
            formatted_attribute_list = repeat_attributes(formatted_attribute_list)
            
            for line_to_write in izip(*formatted_attribute_list):
                spamwriter.writerow(list(line_to_write))
            
            # Print a newline if asked
            if not options.no_newline:
                spamwriter.writerow('')

    return

def main():
    global parser
    
    options = parser.parse_args()
    
    # Supplied format
    if options.script:
        options.format = options.script
    
    valid_format, unknown_items = is_format_valid(options.format)
    if not valid_format:
        parser.error("Please specify a valid output format: '%s' is invalid \n\
         Supported objects are { fqdn, rdns, hop_number, ip, mac_address, mac_vendor, port, protocol, os, script, service, version }" % ', '.join(unknown_items))
    
    # Input selection
    if (options.input != None) and (options.xml_input != None):
        parser.error("Please specify either a normal/grepable or an XML input file")
    
    elif (options.input == None) and (options.xml_input != None):
        results = parse_xml(options.xml_input)
    
    elif options.xml_input == None:
        if options.input != None:
            fd_input = open(options.input, fd_read_options)
        else:
        # No input file specified, reading from stdin
            fd_input = sys.stdin
    
        # Analysis  
        results = parse(fd_input)
        fd_input.close()
     
    # Output descriptor
    if options.output != None:
        fd_output = open(options.output, fd_write_options)
    else:
        # No output file specified, writing to stdout
        fd_output = sys.stdout
    
    # CSV output
    generate_csv(fd_output, results, options)
    fd_output.close()
    
    return

if __name__ == "__main__":
    main()
