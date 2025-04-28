#!/usr/bin/env python3
import sys
import json
import argparse

def scon_char(ch):
    # Escape the character according to SCON rules.
    if 32 <= ord(ch) <= 127:
        if ch == '\\':
            return '\\\\'
        if ch == '"':
            return '\\"'
        return ch
    if ord(ch) <= 0xFF:
        if ch == "\n":
            return "\\n"
        if ch == "\r":
            return "\\r"
        if ch == "\t":
            return "\\t"
        return f'\\x{ord(ch):02x}'
    elif ord(ch) <= 0xFFFF:
        return f'\\u{ord(ch):04x}'
    else:
        return f'\\U{ord(ch):08x}'

def scon_string(s):
    # Convert a string to a properly escaped SCON string.
    unquoted = ''.join(scon_char(ch) for ch in s)
    return f'"{unquoted}"'

def scon_from_json(data):
    # Recursively converts JSON data into SCON format.
    if isinstance(data, dict):
        items = []
        for key, value in data.items():
            # Convert key to a string using scon_string for consistency.
            items.append(f'[{scon_string(str(key))}, {scon_from_json(value)}]')
        return "[" + ", ".join(items) + "]"
    elif isinstance(data, list):
        items = [scon_from_json(item) for item in data]
        return "[" + ", ".join(items) + "]"
    else:
        if data is None:
            return "undef"
        elif data is True:
            return "true"
        elif data is False:
            return "false"
        elif isinstance(data, str):
            return scon_string(data)
        else:
            return str(data)

def main():
    # Parse command-line arguments.
    parser = argparse.ArgumentParser(
        description='Convert JSON from stdin to SCON format, with optional formatting for SCAD snippets.')
    parser.add_argument(
        '--fmt',
        type=str,
        default=None,
        help="Formatting string which must include the placeholder '{scon}'. "
             "For example: --fmt='cfg=scon_make({scon},base);'"
    )
    args = parser.parse_args()

    # Ensure the standard I/O streams support utf-8 encoding.
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stdin.reconfigure(encoding='utf-8')
    except Exception:
        pass  # Not all environments support this change.
    
    try:
        data = json.load(sys.stdin)
        scon_output = scon_from_json(data)
        
        # If a formatting string is provided, replace the {scon} placeholder.
        if args.fmt:
            # Check that the {scon} placeholder is present.
            if "{scon}" not in args.fmt:
                print("Error: The formatting string must include the '{scon}' placeholder.", file=sys.stderr)
                sys.exit(1)
            final_output = args.fmt.replace("{scon}", scon_output)
            print(final_output)
        else:
            print(scon_output)
    except json.JSONDecodeError:
        print("Failed to decode JSON from input.", file=sys.stderr)
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)

if __name__ == '__main__':
    main()