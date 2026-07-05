import requests, re, os, time, sys, subprocess
from datetime import datetime

# --- Config ---
TARGET_LANG = "es"
WOW_DIR = r"C:\Program Files (x86)\World of Warcraft\_classic_era_"
CHAT_LOG = os.path.join(WOW_DIR, "Logs", "WoWChatLog.txt")

# --- Keystroke injection via PowerShell ---

PS_SEND_KEYS = '''Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait({0})
'''

def ps_send(text):
    escaped = text.replace("'", "''").replace("{", "{{}").replace("}", "{}}")
    code = PS_SEND_KEYS.format(repr("{" + escaped + "}"))
    subprocess.run(["powershell", "-NoProfile", "-Command", code],
                   capture_output=True, timeout=5)

def inject_lua(lua_code):
    """Open chat, type Lua command, execute, close."""
    ps_send("{ENTER}")
    time.sleep(0.15)
    ps_send(lua_code)
    time.sleep(0.1)
    ps_send("{ENTER}")
    time.sleep(0.15)
    ps_send("{ESC}")

# --- Chat log monitoring ---

def get_log_size():
    try:
        return os.path.getsize(CHAT_LOG)
    except:
        return 0

CHAT_LOG_RE = re.compile(
    r'^\d+/\d+\s+\d+:\d+:\d+\.\d+\s+\[([^\]]+)\]\s+([^:]+):\s+(.+)$'
)

def read_new_lines(last_size):
    """Read new lines from chat log since last_size. Returns (new_lines, new_size)."""
    try:
        size = os.path.getsize(CHAT_LOG)
        if size <= last_size:
            return [], size
        with open(CHAT_LOG, "r", encoding="utf-8", errors="replace") as f:
            f.seek(last_size)
            content = f.read()
        return content.splitlines(), size
    except:
        return [], last_size

def parse_line(line):
    """Parse a chat log line. Returns (channel, speaker, text) or None."""
    m = CHAT_LOG_RE.match(line.strip())
    if m:
        return m.group(1), m.group(2).strip(), m.group(3).strip()
    return None

# --- Translation ---

def translate_text(text, target=TARGET_LANG, retries=3):
    url = "https://translate.googleapis.com/translate_a/single"
    params = {"client": "gtx", "sl": "auto", "tl": target, "dt": "t", "q": text}
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
    for attempt in range(retries):
        try:
            resp = requests.get(url, params=params, headers=headers, timeout=10)
            resp.raise_for_status()
            data = resp.json()
            translated = ""
            for part in data[0]:
                if part[0]:
                    translated += part[0]
            return translated if translated else text
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1)
            else:
                print(f"[{datetime.now():%H:%M:%S}] ERROR: {e}")
                return text

def main():
    print("=" * 50)
    print("  ChatLingo - Companion App")
    print("  Monitorea WoWChatLog.txt e inyecta traducciones")
    print("=" * 50)
    print()
    print(f"Chat log: {CHAT_LOG}")

    if not os.path.exists(CHAT_LOG):
        print("\n[!] WoWChatLog.txt no existe.")
        print("    Activalo en WoW con: /console chatlog 1")
        print("    Luego escribe algo en chat para que se cree el archivo.")
        print()

    last_size = get_log_size()
    seen_texts = set()
    print("Traduciendo... (Ctrl+C para detener)")
    print()

    try:
        while True:
            lines, last_size = read_new_lines(last_size)
            for line in lines:
                parsed = parse_line(line)
                if not parsed:
                    continue
                channel, speaker, text = parsed
                # Skip own messages (speaker is your character name)
                if text in seen_texts:
                    continue
                seen_texts.add(text)
                if not text.strip():
                    continue

                print(f"[{datetime.now():%H:%M:%S}] [{channel}] {speaker}: {text[:60]}")
                translated = translate_text(text, TARGET_LANG)
                print(f"  -> {translated[:60]}")

                safe = translated.replace('"', '\\"').replace('\n', ' ')
                lua = f'/run local c=ChatFrame1;c:AddMessage("|cff00ccff[TR]|r {safe}",1,1,0)'
                if len(lua) > 200:
                    lua = lua[:200]
                inject_lua(lua)
                time.sleep(0.5)

            time.sleep(0.5)

    except KeyboardInterrupt:
        print("\nChatLingo detenido.")
    except Exception as e:
        import traceback; traceback.print_exc()
        print(f"\nERROR: {e}")
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
