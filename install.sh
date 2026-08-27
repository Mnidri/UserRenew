#!/bin/bash

# ==========================================
# UserRenew Panel - Auto Installer
# ==========================================

GREEN="\e[32m"
PURPLE="\e[35m"
RED="\e[31m"
CYAN="\e[36m"
RESET="\e[0m"

# 1. Check Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[!] Please run as root (sudo su)${RESET}"
  exit 1
fi

if [ -d "/root/UserRenew" ] || [ -f "/usr/bin/userrenew" ]; then
    echo -e "${PURPLE}[!] UserRenew is already installed!${RESET}"
    echo -e "${CYAN}[*] Running the Management Menu...${RESET}"
    sleep 2
    userrenew
    exit 0
fi

clear
echo -e "${CYAN}====================================================${RESET}"
echo -e "${PURPLE}      Welcome to UserRenew Smart Installer        ${RESET}"
echo -e "${CYAN}====================================================${RESET}"
echo ""

read -p "$(echo -e ${PURPLE}"[?] Enter Telegram Admin Bot Token: "${RESET})" BOT_TOKEN
read -p "$(echo -e ${PURPLE}"[?] Enter Your Telegram Admin Numeric ID (e.g. 12345678): "${RESET})" ADMIN_ID
read -p "$(echo -e ${PURPLE}"[?] Enter Panel Port (e.g., 8081): "${RESET})" PANEL_PORT
read -p "$(echo -e ${PURPLE}"[?] Enter Panel Admin Username: "${RESET})" PANEL_USER
read -p "$(echo -e ${PURPLE}"[?] Enter Panel Admin Password: "${RESET})" PANEL_PASS

echo ""
echo -e "${GREEN}[+] Starting Installation...${RESET}"

apt-get update -y -qq
apt-get install -y -qq python3 python3-venv python3-pip curl wget unzip sqlite3

if ! command -v xray &> /dev/null; then
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
fi

mkdir -p /root/UserRenew
cd /root/UserRenew

# --- panel.html (تم بنفش و مشکی) ---
cat << 'EOF' > panel.html
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>پنل مدیریت UserRenew</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Vazirmatn:wght@400;700;900&display=swap');
        body { font-family: 'Vazirmatn', sans-serif; background-color: #0f0f11; color: #ffffff; }
        .glass-panel { background: #1a1a1e; border: 1px solid #2d2d35; border-radius: 24px; padding: 24px; }
        input, select, textarea { background: #25252b; border: 1px solid #363640; color: white; width: 100%; padding: 16px 18px; border-radius: 16px; margin-top: 6px; outline: none; }
        input:focus, select:focus, textarea:focus { border-color: #a855f7; }
        .toast { position: fixed; top: 20px; left: 50%; transform: translateX(-50%); background: #a855f7; color: white; padding: 14px 28px; border-radius: 100px; z-index: 1000; opacity: 0; visibility: hidden; transition: 0.4s; }
        .toast.show { opacity: 1; visibility: visible; }
    </style>
</head>
<body>
    <div id="toast" class="toast">عملیات موفق</div>
    
    <div id="login-screen" class="min-h-screen flex items-center justify-center p-4">
        <div class="w-full max-w-sm text-center glass-panel shadow-2xl">
            <i class="fas fa-fingerprint text-5xl text-[#a855f7] mb-6 block"></i>
            <h2 class="text-2xl font-black mb-8">ورود به سیستم</h2>
            <input type="text" id="username" placeholder="نام کاربری" dir="ltr" class="mb-4">
            <input type="password" id="password" placeholder="رمز عبور" dir="ltr" class="mb-8">
            <button onclick="login()" class="w-full bg-[#a855f7] hover:bg-[#9333ea] text-white font-black py-4 rounded-2xl">ورود</button>
        </div>
    </div>

    <div id="main-app" class="hidden max-w-2xl mx-auto p-4 pt-10">
        <div class="flex justify-between items-center mb-8 glass-panel !py-4">
            <div class="text-xl font-black text-[#a855f7]">UserRenew Manager</div>
            <button onclick="logout()" class="text-gray-400 hover:text-white"><i class="fas fa-power-off text-xl"></i></button>
        </div>

        <div class="glass-panel space-y-5">
            <div class="flex justify-between items-center mb-4">
                <h3 class="text-lg font-bold"><i class="fas fa-server ml-2 text-[#a855f7]"></i>مدیریت سرورها</h3>
                <button onclick="openServerModal()" class="bg-[#a855f7]/20 text-[#a855f7] px-4 py-2 rounded-xl text-sm font-bold border border-[#a855f7]/30"><i class="fas fa-plus"></i> افزودن</button>
            </div>
            <div id="servers-list" class="space-y-4"></div>
        </div>
    </div>

    <div id="server-modal" class="fixed inset-0 bg-black/90 hidden z-[100] flex items-center justify-center p-4">
        <div class="w-full max-w-sm glass-panel">
            <h3 class="text-xl font-black mb-6 text-[#a855f7]" id="server-modal-title">افزودن سرور</h3>
            <input type="hidden" id="srv-id">
            <input type="text" id="srv-name" placeholder="نام نمایشی" class="mb-3">
            <input type="text" id="srv-host" placeholder="آدرس (https://...:port)" dir="ltr" class="mb-3">
            <div class="grid grid-cols-2 gap-3 mb-3">
                <input type="text" id="srv-user" placeholder="یوزر" dir="ltr">
                <input type="password" id="srv-pass" placeholder="پسورد" dir="ltr">
            </div>
            <textarea id="srv-xray" rows="3" placeholder="vless://... (کانفیگ امن سرور)" dir="ltr" class="mb-6"></textarea>
            <div class="flex gap-3">
                <button onclick="saveServer()" class="flex-[2] bg-[#a855f7] text-white font-bold py-3 rounded-xl">ذخیره</button>
                <button onclick="closeServerModal()" class="flex-[1] bg-gray-700 text-white font-bold py-3 rounded-xl">بستن</button>
            </div>
        </div>
    </div>

    <script>
        function showToast(msg) {
            const toast = document.getElementById('toast');
            toast.textContent = msg; toast.classList.add('show');
            setTimeout(() => toast.classList.remove('show'), 3000);
        }

        async function api(path, options = {}) {
            const res = await fetch('/api' + path, { ...options, headers: { 'Content-Type': 'application/json' } });
            return await res.json();
        }

        window.onload = () => { if(localStorage.getItem('logged_in')) showApp(); };

        async function login() {
            const u = document.getElementById('username').value, p = document.getElementById('password').value;
            const res = await api('/login', { method: 'POST', body: JSON.stringify({username: u, password: p}) });
            if (res.success) { localStorage.setItem('logged_in', 'true'); showApp(); }
            else showToast("اطلاعات اشتباه است");
        }

        function logout() { localStorage.clear(); location.reload(); }

        function showApp() {
            document.getElementById('login-screen').classList.add('hidden');
            document.getElementById('main-app').classList.remove('hidden');
            fetchServers();
        }

        async function fetchServers() {
            const servers = await api('/servers');
            document.getElementById('servers-list').innerHTML = servers.map(s => `
                <div class="bg-[#25252b] p-4 rounded-2xl flex justify-between items-center border border-[#363640]">
                    <div>
                        <div class="font-bold">${s.name || 'بدون نام'}</div>
                        <div class="text-xs text-gray-400 font-mono" dir="ltr">${s.host}</div>
                    </div>
                    <button onclick="deleteServer(${s.id})" class="text-red-400 hover:text-red-500 bg-red-400/10 p-2 rounded-lg"><i class="fas fa-trash"></i></button>
                </div>
            `).join('');
        }

        function openServerModal() { document.getElementById('server-modal').classList.remove('hidden'); }
        function closeServerModal() { document.getElementById('server-modal').classList.add('hidden'); }

        async function saveServer() {
            const data = {
                name: document.getElementById('srv-name').value, host: document.getElementById('srv-host').value,
                user: document.getElementById('srv-user').value, password: document.getElementById('srv-pass').value,
                xray_config: document.getElementById('srv-xray').value
            };
            await api('/servers', {method: 'POST', body: JSON.stringify(data)});
            closeServerModal(); fetchServers(); showToast('سرور ذخیره شد');
        }
        async function deleteServer(id) {
            if(confirm('حذف شود؟')) { await api('/servers/'+id, {method:'DELETE'}); fetchServers(); }
        }
    </script>
</body>
</html>
EOF

# --- xray_bot.py (ربات دستیار ادمین) ---
cat << 'EOF' > xray_bot.py
import telebot
from telebot import types
import sqlite3, os, requests, json, urllib3, socket, subprocess, time, urllib.parse
urllib3.disable_warnings()

BOT_TOKEN = "BOT_TOKEN_PLACEHOLDER"
ADMIN_ID = ADMIN_ID_PLACEHOLDER
DB_PATH = "users.db"

bot = telebot.TeleBot(BOT_TOKEN)
user_states = {}

def get_db():
    conn = sqlite3.connect(DB_PATH, timeout=20)
    conn.row_factory = sqlite3.Row
    return conn

def get_free_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0)); return s.getsockname()[1]

def build_xray_outbound(vless_link):
    vless_link = "vless://" + vless_link.split("://")[-1]
    parsed = urllib.parse.urlparse(vless_link)
    qs = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
    def get_qs(key, default=""): return qs.get(key, [""])[0] or default
    outbound = {
        "protocol": "vless",
        "settings": {"vnext": [{"address": parsed.hostname, "port": int(parsed.port), "users": [{"id": parsed.username, "encryption": "none"}]}]},
        "streamSettings": {"network": get_qs("type", "tcp"), "security": get_qs("security", "none")}
    }
    if outbound["streamSettings"]["security"] == "tls": outbound["streamSettings"]["tlsSettings"] = {"serverName": get_qs("sni", parsed.hostname), "fingerprint": get_qs("fp", "")}
    elif outbound["streamSettings"]["security"] == "reality": outbound["streamSettings"]["realitySettings"] = {"serverName": get_qs("sni", parsed.hostname), "fingerprint": get_qs("fp", ""), "publicKey": get_qs("pbk", ""), "shortId": get_qs("sid", "")}
    if outbound["streamSettings"]["network"] == "ws": outbound["streamSettings"]["wsSettings"] = {"path": get_qs("path", ""), "headers": {"Host": get_qs("host", "")}}
    return outbound

class XrayTunnel:
    def __init__(self, link): self.link = link; self.p = None; self.port = None; self.cfg = None
    def __enter__(self):
        if not self.link or not self.link.startswith("vless://"): return None
        out = build_xray_outbound(self.link)
        if not out: return None
        self.port = get_free_port()
        self.cfg = f'/tmp/userrenew_{self.port}.json'
        with open(self.cfg, 'w') as f: json.dump({"inbounds": [{"port": self.port, "listen": "127.0.0.1", "protocol": "socks"}], "outbounds": [out]}, f)
        self.p = subprocess.Popen(['/usr/local/bin/xray', 'run', '-c', self.cfg], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(1.5); return f"socks5://127.0.0.1:{self.port}"
    def __exit__(self, *args):
        if self.p: self.p.terminate()
        if self.cfg and os.path.exists(self.cfg): os.remove(self.cfg)

def fetch_clients(server):
    url = server['host']
    if not url.startswith("http"): url = "https://" + url
    url = url.rstrip('/')
    
    with XrayTunnel(server['xray_config']) as pxy:
        proxies = {"http": pxy, "https": pxy} if pxy else None
        s = requests.Session(); s.verify = False
        try:
            if not s.post(f"{url}/login", data={"username": server['user'], "password": server['password']}, proxies=proxies, timeout=10).json().get('success'): return []
            res = s.get(f"{url}/panel/api/inbounds/list", proxies=proxies, timeout=10).json()
            clients_info = []
            for ib in res.get("obj", []):
                inbound_id = ib['id']
                settings = json.loads(ib.get('settings', '{}'))
                stats = {st['email']: st for st in ib.get('clientStats', [])}
                for c in settings.get('clients', []):
                    em = c.get('email', '')
                    st = stats.get(em, {})
                    clients_info.append({
                        "server_id": server['id'], "server_name": server['name'] or url,
                        "inbound_id": inbound_id, "uuid": c.get('id'), "email": em, "enable": c.get('enable', True),
                        "total": st.get('total', 0), "up": st.get('up', 0), "down": st.get('down', 0), "expiry": st.get('expiryTime', 0)
                    })
            return clients_info
        except: return []

def perform_action(server_id, uuid, action, **kwargs):
    conn = get_db(); c = conn.cursor()
    c.execute("SELECT * FROM servers WHERE id=?", (server_id,))
    srv = c.fetchone(); conn.close()
    if not srv: return False, "سرور یافت نشد"

    url = srv['host']
    if not url.startswith("http"): url = "https://" + url
    url = url.rstrip('/')

    with XrayTunnel(srv['xray_config']) as pxy:
        proxies = {"http": pxy, "https": pxy} if pxy else None
        s = requests.Session(); s.verify = False
        try:
            s.post(f"{url}/login", data={"username": srv['user'], "password": srv['password']}, proxies=proxies, timeout=10)
            
            # Find Inbound ID and Client Data
            inbounds = s.get(f"{url}/panel/api/inbounds/list", proxies=proxies, timeout=10).json().get("obj", [])
            target_inb, target_client = None, None
            for ib in inbounds:
                settings = json.loads(ib.get('settings', '{}'))
                for cl in settings.get('clients', []):
                    if cl.get('id') == uuid:
                        target_inb = ib['id']
                        target_client = cl
                        break
                if target_inb: break
            
            if not target_inb: return False, "کلاینت در سرور یافت نشد"

            if action == "delete":
                res = s.post(f"{url}/panel/api/inbounds/{target_inb}/delClient/{uuid}", proxies=proxies, timeout=10)
                return res.json().get('success', False), "حذف شد"
                
            elif action == "disable":
                target_client['enable'] = False
                payload = {"id": target_inb, "settings": json.dumps({"clients": [target_client]})}
                res = s.post(f"{url}/panel/api/inbounds/updateClient/{uuid}", json=payload, proxies=proxies, timeout=10)
                return res.json().get('success', False), "غیرفعال شد"

            elif action == "extend":
                days, gb = kwargs['days'], kwargs['gb']
                target_client['enable'] = True
                target_client['expiryTime'] = int(time.time() * 1000) + (days * 24 * 3600 * 1000)
                target_client['totalGB'] = gb * (1024 ** 3)
                
                payload = {"id": target_inb, "settings": json.dumps({"clients": [target_client]})}
                res = s.post(f"{url}/panel/api/inbounds/updateClient/{uuid}", json=payload, proxies=proxies, timeout=10)
                
                if res.json().get('success'):
                    s.post(f"{url}/panel/api/inbounds/{target_inb}/resetClientTraffic/{target_client['email']}", proxies=proxies, timeout=10)
                    return True, "تمدید و ریست حجم با موفقیت انجام شد"
                return False, "خطا در تمدید"
                
        except Exception as e: return False, str(e)

@bot.message_handler(commands=['start'])
def start(m):
    if m.chat.id != ADMIN_ID: return
    bot.reply_to(m, "👋 سلام ادمین عزیز!\nبرای مدیریت کاربر، کافیه **نام کاربری (Email)** یا **کانفیگ Vless** کاربر رو بفرستی.", parse_mode="Markdown")

@bot.message_handler(func=lambda m: m.chat.id == ADMIN_ID)
def search_client(m):
    txt = m.text.strip()
    bot.clear_step_handler_by_chat_id(m.chat.id)
    
    query = txt
    if "vless://" in txt.lower():
        try: query = urllib.parse.urlparse("vless://" + txt.split("://")[-1]).username
        except: pass

    msg = bot.reply_to(m, "⏳ در حال جستجوی اکانت در تمامی سرورها...")
    
    conn = get_db(); c = conn.cursor()
    c.execute("SELECT * FROM servers")
    servers = c.fetchall(); conn.close()
    
    found = []
    for srv in servers:
        clients = fetch_clients(dict(srv))
        for cl in clients:
            if query == cl['uuid'] or query.lower() == cl['email'].lower():
                found.append(cl)
    
    bot.delete_message(m.chat.id, msg.message_id)
    
    if not found:
        bot.send_message(m.chat.id, "❌ اکانتی با این مشخصات یافت نشد!")
        return

    if len(found) > 1:
        markup = types.InlineKeyboardMarkup(row_width=1)
        for cl in found:
            markup.add(types.InlineKeyboardButton(f"سـرور: {cl['server_name']} | یوزر: {cl['email']}", callback_data=f"select_{cl['server_id']}_{cl['uuid']}"))
        bot.send_message(m.chat.id, "⚠️ این نام در چند سرور پیدا شد. لطفاً سرور مورد نظر را انتخاب کنید:", reply_markup=markup)
    else:
        show_client_menu(m.chat.id, found[0])

def show_client_menu(chat_id, cl):
    status = "✅ فعال" if cl['enable'] else "⏸ غیرفعال"
    used = (cl['up'] + cl['down']) / (1024**3)
    total = cl['total'] / (1024**3) if cl['total'] > 0 else 0
    t_left = (cl['expiry'] - (time.time() * 1000)) / (24*3600*1000) if cl['expiry'] > 0 else 0
    
    text = f"👤 **کاربر:** `{cl['email']}`\n"
    text += f"🖥 **سرور:** {cl['server_name']}\n"
    text += f"وضعیت: {status}\n"
    text += f"حجم: {used:.2f} GB / {'نامحدود' if total==0 else f'{total:.2f} GB'}\n"
    text += f"اعتبار: {'نامحدود' if cl['expiry']==0 else f'{t_left:.1f} روز'}"

    markup = types.InlineKeyboardMarkup(row_width=2)
    markup.add(
        types.InlineKeyboardButton("🔄 تمدید اکانت", callback_data=f"ext_{cl['server_id']}_{cl['uuid']}"),
        types.InlineKeyboardButton("⏸ غیرفعال‌سازی", callback_data=f"dis_{cl['server_id']}_{cl['uuid']}")
    )
    markup.add(types.InlineKeyboardButton("❌ حذف کامل اکانت", callback_data=f"del_{cl['server_id']}_{cl['uuid']}"))
    
    bot.send_message(chat_id, text, reply_markup=markup, parse_mode="Markdown")

@bot.callback_query_handler(func=lambda c: True)
def callbacks(call):
    data = call.data.split('_')
    action, sid, uuid = data[0], int(data[1]), data[2]
    
    if action == "select":
        bot.delete_message(call.message.chat.id, call.message.message_id)
        conn = get_db(); cr = conn.cursor()
        cr.execute("SELECT * FROM servers WHERE id=?", (sid,))
        srv = cr.fetchone(); conn.close()
        for cl in fetch_clients(dict(srv)):
            if cl['uuid'] == uuid:
                show_client_menu(call.message.chat.id, cl)
                break
                
    elif action == "del":
        ok, msg = perform_action(sid, uuid, "delete")
        bot.answer_callback_query(call.id, msg, show_alert=True)
        if ok: bot.delete_message(call.message.chat.id, call.message.message_id)
        
    elif action == "dis":
        ok, msg = perform_action(sid, uuid, "disable")
        bot.answer_callback_query(call.id, msg, show_alert=True)

    elif action == "ext":
        user_states[call.message.chat.id] = {'sid': sid, 'uuid': uuid}
        msg = bot.send_message(call.message.chat.id, "🔄 **مرحله ۱ از ۲:**\nتعداد **روز** برای تمدید را بصورت عدد وارد کنید:", parse_mode="Markdown")
        bot.register_next_step_handler(msg, get_days)

def get_days(m):
    if not m.text.isdigit():
        bot.reply_to(m, "❌ لطفاً فقط عدد وارد کنید. عملیات لغو شد.")
        return
    user_states[m.chat.id]['days'] = int(m.text)
    msg = bot.send_message(m.chat.id, "📊 **مرحله ۲ از ۲:**\nمقدار **حجم (گیگابایت)** را وارد کنید:", parse_mode="Markdown")
    bot.register_next_step_handler(msg, get_gb)

def get_gb(m):
    if not m.text.isdigit():
        bot.reply_to(m, "❌ لطفاً فقط عدد وارد کنید. عملیات لغو شد.")
        return
    st = user_states[m.chat.id]
    days, gb = st['days'], int(m.text)
    
    wait = bot.send_message(m.chat.id, "⏳ در حال اعمال تغییرات در سرور...")
    ok, msg = perform_action(st['sid'], st['uuid'], "extend", days=days, gb=gb)
    
    bot.delete_message(m.chat.id, wait.message_id)
    bot.send_message(m.chat.id, f"✅ نتیجه عملیات:\n{msg}")

bot.infinity_polling()
EOF

# --- main.py (FastAPI) ---
cat << 'EOF' > main.py
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import sqlite3, uvicorn, os, glob

# Cleanup old proxies
for f in glob.glob('/tmp/userrenew_*.json'):
    try: os.remove(f)
    except: pass
os.system("pkill -f 'xray run -c /tmp/userrenew_'")

app = FastAPI()
DB_PATH = 'users.db'

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('CREATE TABLE IF NOT EXISTS servers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, host TEXT, user TEXT, password TEXT, xray_config TEXT)')
    c.execute('CREATE TABLE IF NOT EXISTS admin (username TEXT, password TEXT)')
    if c.execute('SELECT count(*) FROM admin').fetchone()[0] == 0:
        c.execute("INSERT INTO admin VALUES ('ADMIN_PLACEHOLDER', 'PASS_PLACEHOLDER')")
    conn.commit(); conn.close()
init_db()

class LoginModel(BaseModel): username: str; password: str
class ServerModel(BaseModel): name: str; host: str; user: str; password: str; xray_config: str

@app.post("/api/login")
def login(data: LoginModel):
    conn = sqlite3.connect(DB_PATH); c = conn.cursor()
    c.execute("SELECT * FROM admin WHERE username=? AND password=?", (data.username, data.password))
    valid = c.fetchone() is not None; conn.close()
    return {"success": valid}

@app.get("/api/servers")
def get_servers():
    conn = sqlite3.connect(DB_PATH); conn.row_factory = sqlite3.Row; c = conn.cursor()
    servers = [dict(r) for r in c.execute("SELECT * FROM servers ORDER BY id DESC").fetchall()]; conn.close()
    return servers

@app.post("/api/servers")
def add_server(s: ServerModel):
    conn = sqlite3.connect(DB_PATH); c = conn.cursor()
    c.execute("INSERT INTO servers (name, host, user, password, xray_config) VALUES (?, ?, ?, ?, ?)", (s.name, s.host, s.user, s.password, s.xray_config))
    conn.commit(); conn.close(); return {"success": True}

@app.delete("/api/servers/{server_id}")
def del_server(server_id: int):
    conn = sqlite3.connect(DB_PATH); c = conn.cursor()
    c.execute("DELETE FROM servers WHERE id=?", (server_id,))
    conn.commit(); conn.close(); return {"success": True}

@app.get("/", response_class=HTMLResponse)
def serve_panel():
    with open("panel.html", "r", encoding="utf-8") as f: return f.read()

if __name__ == "__main__": uvicorn.run(app, host="0.0.0.0", port=PORT_PLACEHOLDER)
EOF

# جایگذاری مقادیر متغیرها
sed -i "s/BOT_TOKEN_PLACEHOLDER/$BOT_TOKEN/g" xray_bot.py
sed -i "s/ADMIN_ID_PLACEHOLDER/$ADMIN_ID/g" xray_bot.py
sed -i "s/PORT_PLACEHOLDER/$PANEL_PORT/g" main.py
sed -i "s/ADMIN_PLACEHOLDER/$PANEL_USER/g" main.py
sed -i "s/PASS_PLACEHOLDER/$PANEL_PASS/g" main.py

python3 -m venv venv
source venv/bin/activate
pip install -q telebot "requests[socks]" fastapi uvicorn pydantic

# ایجاد منوی CLI به نام userrenew
cat << 'EOF_MENU' > /usr/bin/userrenew
#!/bin/bash
PURPLE="\e[35m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

while true; do
    clear
    echo -e "${PURPLE}=======================================${RESET}"
    echo -e "       UserRenew Admin Menu            "
    echo -e "${PURPLE}=======================================${RESET}"
    echo "1. Restart Services"
    echo "2. Uninstall System"
    echo "3. Exit"
    read -p "Select option: " opt
    case $opt in
        1) systemctl restart userrenew-panel userrenew-bot && echo -e "${GREEN}Restarted!${RESET}" && sleep 2 ;;
        2) systemctl stop userrenew-panel userrenew-bot; rm -rf /root/UserRenew /etc/systemd/system/userrenew-*.service /usr/bin/userrenew; systemctl daemon-reload; echo -e "${RED}Uninstalled!${RESET}"; exit 0 ;;
        3) exit 0 ;;
    esac
done
EOF_MENU
chmod +x /usr/bin/userrenew

# ایجاد سرویس‌های لینوکس
cat << 'EOF_SERVICE' > /etc/systemd/system/userrenew-panel.service
[Unit]
Description=UserRenew Panel Web
After=network.target
[Service]
WorkingDirectory=/root/UserRenew
ExecStart=/root/UserRenew/venv/bin/python main.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF_SERVICE

cat << 'EOF_SERVICE' > /etc/systemd/system/userrenew-bot.service
[Unit]
Description=UserRenew Telegram Bot
After=network.target
[Service]
WorkingDirectory=/root/UserRenew
ExecStart=/root/UserRenew/venv/bin/python xray_bot.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF_SERVICE

systemctl daemon-reload
systemctl enable userrenew-panel userrenew-bot > /dev/null 2>&1
systemctl restart userrenew-panel userrenew-bot

IPV4=$(curl -4 -s icanhazip.com || curl -s -4 ifconfig.me)

echo -e "${GREEN}====================================================${RESET}"
echo -e "${GREEN}   Installation Completed Successfully!             ${RESET}"
echo -e "${PURPLE}[+] Panel URL:${RESET} http://$IPV4:$PANEL_PORT"
echo -e "${PURPLE}[+] Type ${GREEN}userrenew${PURPLE} in terminal for CLI menu.${RESET}"
echo -e "${GREEN}====================================================${RESET}"
