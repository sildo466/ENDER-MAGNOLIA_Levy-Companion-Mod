import threading
import json
import time
import os
import re
import requests

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

CONFIG_FILE  = os.path.join(SCRIPT_DIR, "config.json")
INPUT_FILE   = os.path.join(SCRIPT_DIR, "data", "input.txt")
OUTPUT_FILE  = os.path.join(SCRIPT_DIR, "data", "output.txt")
HISTORY_FILE = os.path.join(SCRIPT_DIR, "data", "history.json")
SYSTEM_FILE  = os.path.join(SCRIPT_DIR, "prompts", "system.txt")

def load_config():
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"[Error] config.json not found: {CONFIG_FILE}")
        exit(1)
    except json.JSONDecodeError as e:
        print(f"[Error] config.json parse error: {e}")
        exit(1)

def load_system_prompt():
    try:
        with open(SYSTEM_FILE, "r", encoding="utf-8") as f:
            content = f.read().strip()
            if not content:
                print("[Warning] system.txt is empty")
            return content
    except FileNotFoundError:
        print(f"[Error] system.txt not found: {SYSTEM_FILE}")
        exit(1)

def load_history(config):
    try:
        with open(HISTORY_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except:
        return []

def save_history(history, config):
    max_h = config.get("max_history", 20)
    history = history[-max_h:]
    with open(HISTORY_FILE, "w", encoding="utf-8") as f:
        json.dump(history, f, ensure_ascii=False, indent=2)

def clear_history():
    with open(HISTORY_FILE, "w", encoding="utf-8") as f:
        json.dump([], f)
    print("\n[Bridge] History cleared!")
    print("[Bridge] Waiting for player input...\n")

def start_hotkey_listener():
    try:
        import keyboard
        keyboard.add_hotkey("alt+d", clear_history)
        print("[Bridge] Hotkey Alt+D registered (clear history)")
    except ImportError:
        print("[Bridge] 'keyboard' module not found")
        print("[Bridge] Install it: pip install keyboard")
        print("[Bridge] Or type 'clear' in this terminal to clear history manually")

def init():
    os.makedirs(os.path.join(SCRIPT_DIR, "data"), exist_ok=True)
    os.makedirs(os.path.join(SCRIPT_DIR, "prompts"), exist_ok=True)

    with open(INPUT_FILE, "w", encoding="utf-8") as f:
        f.write("")
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("")

    if not os.path.exists(HISTORY_FILE):
        with open(HISTORY_FILE, "w", encoding="utf-8") as f:
            json.dump([], f)

def query_ollama(user_input, config, system_prompt):
    history = load_history(config)

    context_lines = []
    for entry in history[-config.get("context_history", 10):]:
        context_lines.append(f"玩家: {entry['player']}")
        context_lines.append(f"露薇: {entry['levy']}")
    context = "\n".join(context_lines)

    if context:
        full_prompt = (
            f"{system_prompt}\n\n"
            f"最近的对话记录:\n{context}\n\n"
            f"玩家: {user_input}\n露薇:"
        )
    else:
        full_prompt = (
            f"{system_prompt}\n\n"
            f"玩家: {user_input}\n露薇:"
        )

    try:
        response = requests.post(
            config["ollama_url"],
            json={
                "model":  config["model"],
                "prompt": full_prompt,
                "stream": False,
                "think":  config.get("think", False),
                "options": {
                    "temperature":    config.get("temperature", 0.6),
                    "num_predict":    config.get("num_predict", 500),
                    "top_p":          config.get("top_p", 0.9),
                    "repeat_penalty": config.get("repeat_penalty", 1.1),
                }
            },
            timeout=config.get("timeout", 120)
        )

        if response.status_code == 200:
            result = response.json()
            raw = result.get("response", "")

            print(f"Full raw reply:\n{raw}\n---")

            reply = raw.strip()
            reply = re.sub(r'<think>.*?</think>', '', reply, flags=re.DOTALL).strip()
            reply = re.sub(r'<[^>]+>', '', reply).strip()

            lines = [l.strip() for l in reply.split("\n") if l.strip()]
            reply = lines[0] if lines else ""

            reply = reply.strip('"').strip("'").strip("「").strip("」")

            for prefix in ["露薇:", "Levy:", "露薇：", "Levy："]:
                if reply.startswith(prefix):
                    reply = reply[len(prefix):].strip()

            max_len = config.get("max_reply_length", 60)
            if len(reply) > max_len:
                reply = reply[:max_len] + "..."

            if not reply:
                import random
                reply = random.choice(["嗯！", "哦？", "是吗...", "唔。"])
                print(f"[Fallback] Empty reply")

            print(f"Cleaned: {reply}")

            history.append({
                "player": user_input,
                "levy":   reply,
                "time":   time.strftime("%H:%M:%S")
            })
            save_history(history, config)

            return reply

        else:
            print(f"Ollama HTTP error: {response.status_code}")
            return "......"

    except requests.exceptions.ConnectionError:
        print("Cannot connect to Ollama.")
        return "（无法连接到Ollama）"
    except requests.exceptions.Timeout:
        print("Ollama timeout.")
        return "（回复超时）"
    except Exception as e:
        print(f"Unexpected error: {e}")
        return "......"

def main():
    init()

    config        = load_config()
    system_prompt = load_system_prompt()

    print("=" * 50)
    print("Levy AI Bridge Started")
    print(f"Model:       {config['model']}")
    print(f"Temperature: {config.get('temperature', 0.6)}")
    print(f"Input:       {INPUT_FILE}")
    print(f"Output:      {OUTPUT_FILE}")
    print("=" * 50)

    try:
        test = requests.get(
            config["ollama_url"].replace("/api/generate", ""),
            timeout=3
        )
        print(f"Ollama status: OK (HTTP {test.status_code})")
    except:
        print("WARNING: Cannot reach Ollama")

    start_hotkey_listener()

    print("\n[Bridge] Alt+D = Clear history")
    print("[Bridge] Ctrl+C = Exit")
    print("[Bridge] Waiting for player input...\n")

    last_input = ""

    while True:
        try:
            if os.path.exists(INPUT_FILE):
                with open(INPUT_FILE, "r", encoding="utf-8") as f:
                    current_input = f.read().strip()
                if current_input:
                    print(f"[Debug] Read: '{current_input}' last='{last_input}'")
                if current_input and current_input != last_input:
                    last_input = current_input

                    with open(INPUT_FILE, "w", encoding="utf-8") as f:
                        f.write("")

                    print(f"\n[{time.strftime('%H:%M:%S')}] Player: {current_input}")

                    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
                        f.write("STATUS:THINKING")

                    reply = query_ollama(current_input, config, system_prompt)
                    print(f"[{time.strftime('%H:%M:%S')}] Levy:   {reply}\n")

                    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
                        f.write(reply)

                    last_input = ""
                    print(f"[Bridge] Waiting for player input...\n")

            time.sleep(config.get("poll_interval", 0.2))

        except KeyboardInterrupt:
            print("\nBridge stopped.")
            break
        except Exception as e:
            print(f"Loop error: {e}")
            time.sleep(1)

if __name__ == "__main__":
    main()
