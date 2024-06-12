#!/usr/bin/env python3

import sys,json

def scon_char(ch):
    if ord(ch) >= 32 and ord(ch) <= 127:
        if ch == '\\':
            return '\\\\'
        if ch == '"':
            return '\\"'
        return ch
    if ord(ch) <= 0xFF:
        if (ch == "\n"): return "\\n"
        if (ch == "\r"): return "\\r"
        if (ch == "\t"): return "\\t"
        return f'\\x{ord(ch):02x}'
    elif ord(ch) <= 0xFFFF:
        return f'\\u{ord(ch):04x}'
    else:
        return f'\\U{ord(ch):08x}'
    
def scon_string(s):
    unquoted=''.join(scon_char(ch) for ch in s)
    return f'"{unquoted}"'


def scon_from_json(data):
    if isinstance(data, dict):
        print("[", end="")
        for key, value in data.items():
            print(f"[\"{key}\",",end="")
            scon_from_json(value)
            print("],",end="")
        print("]", end="")
    elif isinstance(data, list):
        print("[", end="")
        for item in data:
            scon_from_json(item)
            print(",",end="")
        print(']', end="")            
    else:
        if data == None: print("undef",end="")
        elif data == True: print("true",end="")
        elif data == False: print("false",end="")
        elif type(data) == "string": print(scon_string(data),end="")
        else: print(data,end="")

def main():
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stdin.reconfigure(encoding='utf-8')
        
        data = json.load(sys.stdin)
        
        scon_from_json(data)
        print()
        
    except json.JSONDecodeError:
        print("Failed to decode JSON from input.", file=sys.stderr)
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)

if __name__ == '__main__':
    main()
