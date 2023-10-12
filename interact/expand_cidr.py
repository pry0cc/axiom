#!/usr/bin/env python3

import ipaddress
import argparse

def expand_subnets(ip_list, silent=False):
    expanded_list = []
    
    for item in ip_list:
        item_stripped = item.strip()
        try:
            # Check if item is a single IP
            if ipaddress.ip_address(item_stripped):
                expanded_list.append(item_stripped)
                continue
        except ValueError:
            pass
            
        try:
            # Check if item is a subnet
            subnet = ipaddress.ip_network(item_stripped, strict=False)
            if subnet.prefixlen != 32:
                if not silent:  # Only print if not in silent mode
                    print(f"Expanding subnet {subnet}")
                expanded_list.extend([str(ip) for ip in subnet])
            else:
                expanded_list.append(item_stripped)
        except ValueError:
            # Item is not a subnet
            if not silent:  # Only print if not in silent mode
                print(f"'{item_stripped}' is not a subnet.")
            expanded_list.append(item_stripped)
            
    return expanded_list

def main():
    parser = argparse.ArgumentParser(description="Expand subnets from a file.")
    parser.add_argument("filepath", help="Path to the file containing subnets or IPs.")
    parser.add_argument("--replace", action="store_true", help="Replace file content with expanded subnets.")
    parser.add_argument("--silent", action="store_true", help="Only return the expanded subnets.")
    
    args = parser.parse_args()

    with open(args.filepath, 'r') as f:
        lines = f.readlines()

    expanded = expand_subnets(lines, args.silent)
    
    if args.replace:
        with open(args.filepath, 'w') as f:
            for ip in expanded:
                f.write(f"{ip}\n")
    elif not args.silent:
        for ip in expanded:
            print(ip)
    else:
        # In silent mode, just print the expanded list without any status messages.
        print('\n'.join(expanded))

if __name__ == "__main__":
    main()

