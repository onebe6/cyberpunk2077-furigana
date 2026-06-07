import sys, os


def escape_non_unicode(text):
    pos = 0
    while True:
        pos = text.find("\\x", pos)
        if pos < 0:
            return text

        escaped = text[pos:pos+4]

        uchar = escaped.encode('latin1').decode('unicode-escape')

        text = text[:pos] + uchar + text[pos+4:]


def escape_file(file):
    # Only process .json.json files (skip other file types)
    if not file.endswith(".json.json"):
        return

    try:
        with open(file, 'r', encoding='utf8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Failed to read {file!r}: {e}")
        return

    for i in range(len(lines)):
        line = lines[i]

        escaped = line.encode('unicode-escape').decode('utf8')

        # Handle trailing newlines properly (don't double-encode)
        if escaped.endswith("\\n"):
            escaped = escaped[:len(escaped) - 2] + "\n"

        escaped = escape_non_unicode(escaped)
        
        # Fix the quote escaping issue from original code
        escaped = escaped.replace('\\"', '\\\\"')

        lines[i] = escaped

    try:
        with open(file, 'w', encoding='utf8') as f:
            f.writelines(lines)
    except Exception as e:
        print(f"Failed to write {file!r}: {e}")


def escape_folder(path):
    for root, dirs, files in os.walk(path):
        # Skip hidden directories and __pycache__
        dirs[:] = [d for d in dirs if not d.startswith('.') and d != '__pycache__']

        for f in files:
            p = os.path.join(root, f)

            if os.path.isdir(p):
                escape_folder(p)
            else:
                # Only process .json.json files (skip binary archives like .archive or .cr2w)
                if not any(f.endswith(ext) for ext in ['.archive', '.cr2w', '.bin']):
                    escape_file(p)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("No path given.")
        exit(1)

    p = sys.argv[1]

    if not os.path.isdir(p):
        print(f"No such directory {p!r}.")
        exit(1)

    escape_folder(p)

    exit(0)
