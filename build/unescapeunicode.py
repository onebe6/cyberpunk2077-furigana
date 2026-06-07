import os
import sys


def replace_timestamp(text):
    start = text.find('"ExportedDateTime":')
    if start >= 0:
        end = text.find(",", start)
        if end > start:
            ts = text[start:end]

            return text[:start] + '"ExportedDateTime": "2077-01-01T00:00:00.00Z"' + text[end:]

    return text


def unescape_text(text):
    pos = 0
    while True:
        pos = text.find("\\u", pos)
        if pos < 0:
            return text

        # check if this is a path (escaped backslash before u means literal \u, not unicode escape)
        if pos > 0 and text[pos-1] == "\\":
            pos += 1
            continue

        escaped = text[pos:pos + 6]

        if escaped == "\\u0022":
            uchar = '\\"'
        else:
            try:
                uchar = escaped.encode('latin1').decode('unicode-escape')
            except Exception as e:
                print(f"Failed to unescape unicode escape {escaped!r}: {e}")
                return None

        text = text[:pos] + uchar + text[pos + 6:]


def unescape_file(file):
    try:
        with open(file, 'r', encoding='utf8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Failed to read file {file!r}: {e}")
        return

    for i in range(len(lines)):
        line = lines[i]

        unescaped = unescape_text(line)
        if unescaped is None:
            continue  # Skip problematic files instead of failing entirely

        unescaped = replace_timestamp(unescaped)

        lines[i] = unescaped

    try:
        with open(file, 'w', encoding='utf8') as f:
            f.writelines(lines)
    except Exception as e:
        print(f"Failed to write file {file!r}: {e}")


def unescape_folder(path):
    for root, dirs, files in os.walk(path):
        # Skip hidden directories and __pycache__
        dirs[:] = [d for d in dirs if not d.startswith('.') and d != '__pycache__']

        for f in files:
            p = os.path.join(root, f)

            if os.path.isdir(p):
                unescape_folder(p)
            else:
                # Only process text/json files (skip binary archives like .archive or .cr2w)
                if not any(f.endswith(ext) for ext in ['.archive', '.cr2w', '.bin']):
                    unescape_file(p)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("No path given.")
        exit(1)

    p = sys.argv[1]

    if not os.path.isdir(p):
        print(f"No such directory {p!r}.")
        exit(1)

    unescape_folder(p)

    exit(0)
