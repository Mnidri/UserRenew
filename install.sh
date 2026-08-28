#!/bin/bash

# ==========================================
# UserRenew CRM & Panel - Ultimate Edition
# ==========================================

GREEN="\e[32m"
PURPLE="\e[35m"
RED="\e[31m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

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
echo -e "${PURPLE}      Welcome to UserRenew CRM Installer          ${RESET}"
echo -e "${CYAN}====================================================${RESET}"
echo ""

read -p "$(echo -e ${PURPLE}"[?] Enter Telegram Bot Token: "${RESET})" BOT_TOKEN
read -p "$(echo -e ${PURPLE}"[?] Enter Panel Port (e.g., 8081): "${RESET})" PANEL_PORT
read -p "$(echo -e ${PURPLE}"[?] Enter Panel Admin Username: "${RESET})" PANEL_USER
read -p "$(echo -e ${PURPLE}"[?] Enter Panel Admin Password: "${RESET})" PANEL_PASS

echo -e "${GREEN}[+] Starting Installation...${RESET}"

apt-get update -y -qq
apt-get install -y -qq python3 python3-venv python3-pip curl wget unzip sqlite3

if ! command -v xray &> /dev/null; then
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
fi

mkdir -p /root/UserRenew
cd /root/UserRenew

# --- panel.html ---
cat << 'EOF' > panel.html
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>پنل مدیریت UserRenew</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Vazirmatn:wght@400;700;900&display=swap');
        body { font-family: 'Vazirmatn', sans-serif; background-color: #09090b; color: #ffffff; overflow-x: hidden; }
        .glass-panel { background: #18181b; border: 1px solid #27272a; border-radius: 28px; padding: 24px; box-shadow: 0 10px 40px rgba(0,0,0,0.5); }
        @media (min-width: 640px) { .glass-panel { padding: 32px; } }
        input, select, textarea { 
            background: #27272a; border: 1px solid #3f3f46; color: white; width: 100%; 
            padding: 16px 20px; border-radius: 18px; margin-top: 8px; outline: none; 
            font-size: 1rem; transition: all 0.3s ease;
        }
        input:focus, select:focus, textarea:focus { border-color: #c084fc; background: #3f3f46; box-shadow: 0 0 0 4px rgba(192,132,252,0.1); }
        .checkbox-container { display: flex; items: center; gap: 10px; margin-top: 15px; cursor: pointer; }
        .checkbox-container input { width: 24px; height: 24px; margin: 0; cursor: pointer; accent-color: #c084fc; }
        .toast { position: fixed; top: 20px; left: 50%; transform: translateX(-50%) translateY(-20px); background: #c084fc; color: black; padding: 16px 32px; border-radius: 100px; z-index: 1000; opacity: 0; visibility: hidden; transition: 0.4s cubic-bezier(0.68, -0.55, 0.265, 1.55); font-weight: bold; width: max-content; max-width: 90%; text-align: center;}
        .toast.show { opacity: 1; visibility: visible; transform: translateX(-50%) translateY(0); }
        ::-webkit-scrollbar { width: 8px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #3f3f46; border-radius: 10px; }
        ::-webkit-scrollbar-thumb:hover { background: #c084fc; }
        .btn-primary { background: #c084fc; color: #09090b; font-weight: 900; padding: 16px; border-radius: 18px; transition: all 0.3s; width: 100%; font-size: 1.1rem; }
        .btn-primary:hover { background: #d8b4fe; transform: translateY(-2px); box-shadow: 0 10px 20px rgba(192,132,252,0.2); }
    </style>
</head>
<body>
    <div id="toast" class="toast">عملیات موفق</div>
    
    <div id="login-screen" class="min-h-screen flex items-center justify-center p-4">
        <div class="w-full max-w-md text-center glass-panel">
            <div class="w-24 h-24 rounded-full bg-[#c084fc]/10 flex items-center justify-center mx-auto mb-8 border border-[#c084fc]/30">
                <i class="fas fa-fingerprint text-5xl text-[#c084fc]"></i>
            </div>
            <h2 class="text-3xl font-black mb-8">ورود به سیستم</h2>
            <div class="space-y-5 mb-10">
                <input type="text" id="username" placeholder="نام کاربری" dir="ltr" class="text-center text-xl !m-0">
                <input type="password" id="password" placeholder="رمز عبور" dir="ltr" class="text-center text-xl !m-0">
            </div>
            <button onclick="login()" class="btn-primary">تایید و ورود</button>
        </div>
    </div>

    <div id="main-app" class="hidden max-w-4xl mx-auto p-4 pt-8 pb-24 space-y-6">
        <div class="flex justify-between items-center glass-panel !py-4 !px-6">
            <div class="text-2xl font-black text-[#c084fc] flex items-center"><i class="fas fa-bolt ml-3"></i> UserRenew</div>
            <div class="flex gap-3">
                <button onclick="openSettingsModal()" class="w-12 h-12 rounded-full bg-[#27272a] hover:bg-[#3f3f46] text-white transition-colors flex items-center justify-center"><i class="fas fa-users-cog text-xl"></i></button>
                <button onclick="logout()" class="w-12 h-12 rounded-full bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white transition-colors flex items-center justify-center"><i class="fas fa-power-off text-xl"></i></button>
            </div>
        </div>

        <div class="glass-panel">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8 border-b border-[#27272a] pb-6">
                <h3 class="text-xl font-bold flex items-center"><i class="fas fa-server ml-3 text-[#c084fc] text-2xl"></i>سرورهای متصل</h3>
                <button onclick="openServerModal()" class="w-full sm:w-auto bg-[#c084fc]/20 text-[#c084fc] hover:bg-[#c084fc] hover:text-black transition-all px-6 py-3 rounded-xl text-md font-bold border border-[#c084fc]/30 flex items-center justify-center"><i class="fas fa-plus ml-2"></i> افزودن سرور</button>
            </div>
            <div id="servers-list" class="space-y-4 max-h-[60vh] overflow-y-auto pr-2"></div>
        </div>
    </div>

    <div id="settings-modal" class="fixed inset-0 bg-black/95 hidden z-[100] flex items-center justify-center p-4 backdrop-blur-sm">
        <div class="w-full max-w-md glass-panel relative">
            <button onclick="closeSettingsModal()" class="absolute top-6 left-6 text-gray-400 hover:text-white"><i class="fas fa-times text-xl"></i></button>
            <h3 class="text-xl font-black mb-6 text-[#c084fc] flex items-center"><i class="fas fa-users-cog ml-3"></i> مدیریت تیم ادمین‌ها</h3>
            <div class="space-y-4 mb-8">
                <div>
                    <label class="text-sm font-bold text-gray-400 ml-2">آیدی‌های عددی (Chat IDs) - با کاما جدا کنید</label>
                    <textarea id="admin-ids-input" rows="3" placeholder="12345678, 98765432" dir="ltr" class="!mt-2"></textarea>
                    <p class="text-xs text-gray-500 mt-2">تمامی این آیدی‌ها دسترسی کامل به ربات خواهند داشت.</p>
                </div>
            </div>
            <button onclick="saveSettings()" class="btn-primary">ذخیره دسترسی‌ها</button>
        </div>
    </div>

    <div id="server-modal" class="fixed inset-0 bg-black/95 hidden z-[100] flex flex-col items-center justify-center p-4 backdrop-blur-sm overflow-y-auto">
        <div class="w-full max-w-lg glass-panel my-auto">
            <h3 class="text-2xl font-black mb-8 text-[#c084fc] flex items-center" id="server-modal-title"><i class="fas fa-server ml-3"></i> افزودن سرور جدید</h3>
            <input type="hidden" id="srv-id">
            <div class="space-y-5 mb-6">
                <div>
                    <label class="text-sm font-bold text-gray-400 ml-2">نام نمایشی</label>
                    <input type="text" id="srv-name" placeholder="مثال: سرور آلمان" class="!mt-2">
                </div>
                <div>
                    <label class="text-sm font-bold text-gray-400 ml-2">آدرس پنل (شامل پورت)</label>
                    <input type="text" id="srv-host" placeholder="https://ip:port/path" dir="ltr" class="!mt-2">
                </div>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                    <div>
                        <label class="text-sm font-bold text-gray-400 ml-2">نام کاربری پنل</label>
                        <input type="text" id="srv-user" placeholder="admin" dir="ltr" class="!mt-2">
                    </div>
                    <div>
                        <label class="text-sm font-bold text-gray-400 ml-2">رمز عبور پنل</label>
                        <input type="password" id="srv-pass" placeholder="***" dir="ltr" class="!mt-2">
                    </div>
                </div>
                <div>
                    <label class="text-sm font-bold text-gray-400 ml-2">نوع پنل (نسخه)</label>
                    <select id="srv-type" class="!mt-2">
                        <option value="new">پنل جدید (3x-ui / سنایی جدید)</option>
                        <option value="old">پنل قدیمی (x-ui کلاسیک / سنایی قدیم)</option>
                    </select>
                </div>
                <div>
                    <label class="text-sm font-bold text-gray-400 ml-2">مسیر امن Vless (جهت دور زدن فیلترینگ - اختیاری)</label>
                    <textarea id="srv-xray" rows="2" placeholder="vless://..." dir="ltr" class="text-sm font-mono !mt-2"></textarea>
                </div>
                <label class="checkbox-container text-gray-300 font-bold text-sm">
                    <input type="checkbox" id="srv-allow-sell" checked>
                    اجازه ساخت کانفیگ جدید (فروش) روی این سرور
                </label>
            </div>
            
            <div class="flex flex-col sm:flex-row gap-4">
                <button onclick="saveServer()" class="w-full sm:flex-[2] btn-primary">ثبت اطلاعات</button>
                <button onclick="closeServerModal()" class="w-full sm:flex-[1] bg-[#27272a] hover:bg-[#3f3f46] text-white font-bold py-4 rounded-[18px] transition-colors text-lg">انصراف</button>
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
            else showToast("اطلاعات ورود اشتباه است");
        }
        function logout() { localStorage.clear(); location.reload(); }
        function showApp() {
            document.getElementById('login-screen').classList.add('hidden');
            document.getElementById('main-app').classList.remove('hidden');
            fetchServers();
        }

        async function fetchServers() {
            const servers = await api('/servers');
            window.serversData = servers;
            const list = document.getElementById('servers-list');
            if(servers.length === 0) {
                list.innerHTML = '<div class="text-center text-gray-500 py-10 font-bold">هیچ سروری ثبت نشده است.</div>';
                return;
            }
            list.innerHTML = servers.map(s => `
                <div class="bg-[#18181b] p-5 rounded-3xl flex flex-col md:flex-row gap-5 justify-between items-start md:items-center border border-[#3f3f46] hover:border-[#c084fc]/50 transition-colors w-full overflow-hidden">
                    <div class="flex items-center gap-4 w-full md:w-auto overflow-hidden">
                        <div class="min-w-[48px] h-12 rounded-2xl bg-[#c084fc]/10 flex items-center justify-center border border-[#c084fc]/20">
                            <i class="fas fa-network-wired text-[#c084fc] text-xl"></i>
                        </div>
                        <div class="overflow-hidden w-full">
                            <div class="font-black text-lg truncate flex items-center gap-2">
                                ${s.name || 'بدون نام'}
                                ${s.allow_sell ? '<i class="fas fa-cart-plus text-green-400 text-xs" title="فروش فعال"></i>' : ''}
                            </div>
                            <div class="text-xs text-gray-400 mt-1" dir="ltr">${s.host} <span class="text-[#c084fc] ml-2">(${s.panel_type === 'old' ? 'قدیمی' : 'جدید'})</span></div>
                        </div>
                    </div>
                    <div class="flex flex-wrap items-center gap-4 w-full md:w-auto justify-between md:justify-end mt-2 md:mt-0">
                        ${s.xray_config ? '<span class="bg-green-500/20 text-green-400 border border-green-500/30 px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-2"><i class="fas fa-shield-check"></i> تونل فعال</span>' : '<span class="bg-gray-800 text-gray-300 px-3 py-2 rounded-xl text-xs font-bold">مستقیم</span>'}
                        <div class="flex gap-2 shrink-0">
                            <button onclick="editServer(${s.id})" class="w-12 h-12 rounded-xl bg-blue-500/10 text-blue-400 hover:bg-blue-500 hover:text-white transition-colors flex items-center justify-center"><i class="fas fa-pen"></i></button>
                            <button onclick="deleteServer(${s.id})" class="w-12 h-12 rounded-xl bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white transition-colors flex items-center justify-center"><i class="fas fa-trash"></i></button>
                        </div>
                    </div>
                </div>
            `).join('');
        }

        async function openSettingsModal() {
            const res = await api('/settings');
            document.getElementById('admin-ids-input').value = res.admin_ids || '';
            document.getElementById('settings-modal').classList.remove('hidden');
        }
        function closeSettingsModal() { document.getElementById('settings-modal').classList.add('hidden'); }
        async function saveSettings() {
            const admin_ids = document.getElementById('admin-ids-input').value;
            await api('/settings', {method: 'POST', body: JSON.stringify({admin_ids: admin_ids})});
            showToast("دسترسی‌ها ذخیره شد");
            closeSettingsModal();
        }

        function openServerModal(id = null) { 
            const title = document.getElementById('server-modal-title');
            if (id) {
                const s = window.serversData.find(x => x.id === id);
                document.getElementById('srv-id').value = s.id;
                document.getElementById('srv-name').value = s.name;
                document.getElementById('srv-host').value = s.host;
                document.getElementById('srv-user').value = s.user;
                document.getElementById('srv-pass').value = s.password;
                document.getElementById('srv-xray').value = s.xray_config;
                document.getElementById('srv-type').value = s.panel_type || 'new';
                document.getElementById('srv-allow-sell').checked = s.allow_sell ? true : false;
                title.innerHTML = '<i class="fas fa-pen ml-3"></i> ویرایش سرور';
            } else {
                document.getElementById('srv-id').value = '';
                document.getElementById('srv-name').value = '';
                document.getElementById('srv-host').value = '';
                document.getElementById('srv-user').value = '';
                document.getElementById('srv-pass').value = '';
                document.getElementById('srv-xray').value = '';
                document.getElementById('srv-type').value = 'new';
                document.getElementById('srv-allow-sell').checked = true;
                title.innerHTML = '<i class="fas fa-server ml-3"></i> افزودن سرور جدید';
            }
            document.getElementById('server-modal').classList.remove('hidden'); 
        }
        function editServer(id) { openServerModal(id); }
        function closeServerModal() { document.getElementById('server-modal').classList.add('hidden'); }

        async function saveServer() {
            const id = document.getElementById('srv-id').value;
            const data = {
                name: document.getElementById('srv-name').value, host: document.getElementById('srv-host').value,
                user: document.getElementById('srv-user').value, password: document.getElementById('srv-pass').value,
                xray_config: document.getElementById('srv-xray').value, allow_sell: document.getElementById('srv-allow-sell').checked,
                panel_type: document.getElementById('srv-type').value
            };
            if(!data.host || !data.user || !data.password) return showToast("فیلدهای ضروری را پر کنید!");
            
            if (id) {
                await api('/servers/'+id, {method: 'PUT', body: JSON.stringify(data)});
                showToast('سرور با موفقیت ویرایش شد');
            } else {
                await api('/servers', {method: 'POST', body: JSON.stringify(data)});
                showToast('سرور جدید اضافه شد');
            }
            closeServerModal(); fetchServers(); 
        }
        async function deleteServer(id) {
            if(confirm('آیا از حذف این سرور اطمینان دارید؟')) { await api('/servers/'+id, {method:'DELETE'}); fetchServers(); }
        }
    </script>
</body>
</html>
EOF

# --- xray_bot.py ---
cat << 'EOF' > xray_bot.py
import telebot
from telebot import types
import sqlite3, os, requests, json, urllib3, socket, subprocess, time, urllib.parse, uuid, random, string
urllib3.disable_warnings()

BOT_TOKEN = "BOT_TOKEN_PLACEHOLDER"
DB_PATH = "users.db"
bot = telebot.TeleBot(BOT_TOKEN)

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"

active_targets = {}
step_states = {}
create_states = {}

def get_session():
    s = requests.Session()
    s.verify = False
    s.headers.update({
        "User-Agent": USER_AGENT,
        "Accept": "application/json, text/plain, */*",
        "X-Requested-With": "XMLHttpRequest"
    })
    return s

def get_db():
    conn = sqlite3.connect(DB_PATH, timeout=20)
    conn.row_factory = sqlite3.Row
    return conn

def get_admin_ids():
    conn = get_db(); c = conn.cursor()
    c.execute("SELECT value FROM settings WHERE key='admin_ids'")
    row = c.fetchone(); conn.close()
    if row and row['value']:
        ids = []
        for x in str(row['value']).split(','):
            try: ids.append(int(x.strip()))
            except: pass
        return ids
    return []

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
    url = server['host'].rstrip('/')
    if not url.startswith("http"): url = "https://" + url
    with XrayTunnel(server.get('xray_config', '')) as pxy:
        proxies = {"http": pxy, "https": pxy} if pxy else None
        s = get_session()
        try:
            res_login = s.post(f"{url}/login", data={"username": server['user'], "password": server['password']}, proxies=proxies, timeout=10)
            try: is_logged = res_login.json().get('success')
            except: is_logged = res_login.status_code == 200
            
            if not is_logged: return []
            
            res = s.get(f"{url}/panel/api/inbounds/list", proxies=proxies, timeout=10).json()
            clients_info = []
            for ib in res.get("obj", []):
                inbound_id = ib['id']
                settings = json.loads(ib.get('settings', '{}'))
                stats = {st['email']: st for st in ib.get('clientStats', [])}
                for c in settings.get('clients', []):
                    em = c.get('email', '')
                    uid_str = c.get('id') or c.get('password') or ''
                    st = stats.get(em, {})
                    clients_info.append({
                        "server_id": server['id'], "server_name": server['name'] or url,
                        "inbound_id": inbound_id, "uuid": uid_str, "email": em, "enable": c.get('enable', True),
                        "total": st.get('total', 0), "up": st.get('up', 0), "down": st.get('down', 0), "expiry": st.get('expiryTime', 0)
                    })
            return clients_info
        except: return []

def perform_action(server_id, uuid_str, action, **kwargs):
    conn = get_db(); c = conn.cursor()
    c.execute("SELECT * FROM servers WHERE id=?", (server_id,))
    srv = c.fetchone(); conn.close()
    if not srv: return False, "سرور یافت نشد"

    url = srv['host'].rstrip('/')
    if not url.startswith("http"): url = "https://" + url

    with XrayTunnel(srv.get('xray_config', '')) as pxy:
        proxies = {"http": pxy, "https": pxy} if pxy else None
        s = get_session()
        try:
            s.post(f"{url}/login", data={"username": srv['user'], "password": srv['password']}, proxies=proxies, timeout=10)
            inbounds = s.get(f"{url}/panel/api/inbounds/list", proxies=proxies, timeout=10).json().get("obj", [])
            target_inb, target_client = None, None
            for ib in inbounds:
                settings = json.loads(ib.get('settings', '{}'))
                for cl in settings.get('clients', []):
                    client_id = cl.get('id') or cl.get('password') or ''
                    if client_id == uuid_str:
                        target_inb = ib['id']; target_client = cl; break
                if target_inb: break
            
            if not target_inb: return False, "کلاینت در سرور یافت نشد"

            if action == "delete":
                s.post(f"{url}/panel/api/inbounds/{target_inb}/delClient/{uuid_str}", proxies=proxies, timeout=10)
                return True, "کانفیگ با موفقیت حذف شد. 🗑"
            elif action == "toggle":
                target_client['enable'] = not target_client['enable']
                payload = {"id": target_inb, "settings": json.dumps({"clients": [target_client]})}
                res = s.post(f"{url}/panel/api/inbounds/updateClient/{uuid_str}", json=payload, proxies=proxies, timeout=10)
                try: is_ok = res.json().get('success', False)
                except: is_ok = res.status_code == 200
                state_msg = "فعال ✅" if target_client['enable'] else "غیرفعال ⏸"
                return is_ok, f"وضعیت اکانت با موفقیت تغییر کرد و اکنون **{state_msg}** است."
            elif action == "extend":
                days, gb = kwargs['days'], kwargs['gb']
                target_client['enable'] = True
                target_client['expiryTime'] = int(time.time() * 1000) + (days * 24 * 3600 * 1000) if days > 0 else 0
                target_client['totalGB'] = gb * (1024 ** 3) if gb > 0 else 0
                payload = {"id": target_inb, "settings": json.dumps({"clients": [target_client]})}
                res = s.post(f"{url}/panel/api/inbounds/updateClient/{uuid_str}", json=payload, proxies=proxies, timeout=10)
                try: is_ok = res.json().get('success')
                except: is_ok = res.status_code == 200
                
                if is_ok:
                    s.post(f"{url}/panel/api/inbounds/{target_inb}/resetClientTraffic/{target_client['email']}", proxies=proxies, timeout=10)
                    return True, "✅ **اکانت با موفقیت تمدید و حجم آن ریست شد.**"
                return False, "❌ خطا در برقراری ارتباط برای تمدید."
        except Exception as e: return False, f"خطا: {str(e)}"

def create_config(server_id, inb_ids_list, username, days, gb, inbounds_data):
    conn = get_db(); c = conn.cursor()
    c.execute("SELECT * FROM servers WHERE id=?", (server_id,))
    srv = c.fetchone(); conn.close()
    if not srv: return False, "سرور یافت نشد", None

    url = srv['host'].rstrip('/')
    if not url.startswith("http"): url = "https://" + url
    panel_type = srv.get('panel_type', 'new')

    with XrayTunnel(srv.get('xray_config', '')) as pxy:
        proxies = {"http": pxy, "https": pxy} if pxy else None
        s = get_session()
        try:
            s.post(f"{url}/login", data={"username": srv['user'], "password": srv['password']}, proxies=proxies, timeout=10)
            
            uid = str(uuid.uuid4())
            subid = ''.join(random.choices(string.ascii_lowercase + string.digits, k=16))
            
            created_count = 0
            for inb_id in inb_ids_list:
                target_ib = next((x for x in inbounds_data if x['id'] == inb_id), None)
                protocol = target_ib['protocol'] if target_ib else 'vless'
                
                client_dict = {
                    "email": username, 
                    "enable": True,
                    "expiryTime": int(time.time() * 1000) + (days * 86400000) if days > 0 else 0,
                    "totalGB": gb * 1073741824 if gb > 0 else 0
                }
                
                if protocol in ["vless", "vmess"]:
                    client_dict["id"] = uid
                    if protocol == "vless" and panel_type != 'old':
                        client_dict["flow"] = ""
                elif protocol in ["trojan", "shadowsocks"]:
                    client_dict["password"] = uid.replace("-", "")[:16]
                    
                if panel_type != 'old':
                    client_dict["subId"] = subid
                    client_dict["tgId"] = ""
                    client_dict["limitIp"] = 1
                    client_dict["reset"] = 0
                
                payload = {"id": inb_id, "settings": json.dumps({"clients": [client_dict]})}
                res = s.post(f"{url}/panel/api/inbounds/addClient", json=payload, proxies=proxies, timeout=10)
                try:
                    if res.json().get('success'): created_count += 1
                except:
                    if res.status_code == 200: created_count += 1
            
            if created_count > 0:
                sub_url = ""
                if panel_type != 'old':
                    try:
                        settings_res = s.get(f"{url}/panel/setting/all", proxies=proxies, timeout=10).json()
                        sub_domain = settings_res.get('obj', {}).get('subDomain', '')
                        if not sub_domain: sub_domain = urllib.parse.urlparse(url).hostname
                        sub_port = settings_res.get('obj', {}).get('subPort', '')
                        sub_path = settings_res.get('obj', {}).get('subPath', '/sub/')
                        
                        port_str = f":{sub_port}" if sub_port and str(sub_port) not in ["80", "443"] else ""
                        if not sub_path.startswith('/'): sub_path = '/' + sub_path
                        if not sub_path.endswith('/'): sub_path = sub_path + '/'
                        sub_url = f"http://{sub_domain}{port_str}{sub_path}{subid}"
                    except: pass
                
                msg = f"✅ **اکانت با موفقیت ساخته شد!**\n\n👤 نام: `{username}`\n📦 حجم: {'نامحدود' if gb==0 else str(gb)+' GB'}\n⏳ اعتبار: {'نامحدود' if days==0 else str(days)+' روز'}\n🔗 پورت‌های متصل: {created_count} عدد"
                if sub_url:
                    msg += f"\n\n🌐 **لینک سابسکریپشن:**\n`{sub_url}`"
                msg += f"\n\n🔑 **شناسه (UUID/Password):**\n`{uid}`"
                return True, msg, uid
            return False, "خطا در API ساخت اکانت پنل (هیچ پورتی متصل نشد)", None
        except Exception as e: return False, f"خطای ارتباط: {str(e)}", None

def get_main_reply_keyboard():
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True, row_width=2)
    markup.add("➕ ساخت کانفیگ جدید")
    markup.add("🔄 تمدید اکانت", "⏯ تغییر وضعیت (فعال/غیرفعال)")
    markup.add("❌ حذف اکانت", "🔙 پایان مدیریت")
    return markup

def check_admin(m):
    admin_ids = get_admin_ids()
    if not admin_ids or m.chat.id not in admin_ids:
        text = f"🔒 **دسترسی غیرمجاز!**\n\nآیدی عددی تلگرام شما:\n`{m.chat.id}`\n\nلطفاً این آیدی را کپی کرده و در تنظیمات پنل ثبت کنید."
        bot.reply_to(m, text, parse_mode="Markdown")
        return False
    return True

@bot.message_handler(commands=['start'])
def start(m):
    if not check_admin(m): return
    active_targets.pop(m.chat.id, None)
    text = "به دستیار هوشمند CRM خوش آمدید! 🤖\n\nبرای جستجو و مدیریت، یکی از موارد زیر را بفرستید:\n🔸 **نام کاربری (Email)**\n🔸 **UUID یا Password کلاینت**\n🔸 **متن کانفیگ Vless/Trojan**\n\nیا از منوی پایین برای ساخت اکانت استفاده کنید 👇"
    bot.send_message(m.chat.id, text, parse_mode="Markdown", reply_markup=get_main_reply_keyboard())

def get_inb_keyboard(chat_id):
    st = create_states.get(chat_id)
    markup = types.InlineKeyboardMarkup(row_width=1)
    if not st: return markup
    for ib in st.get('inbounds', []):
        mark = "✅ " if ib['id'] in st['selected'] else "▫️ "
        markup.add(types.InlineKeyboardButton(f"{mark}پورت: {ib['port']} ({ib.get('protocol','-')}) | {ib.get('remark','-')}", callback_data=f"cr_inb_{ib['id']}"))
    
    row = []
    row.append(types.InlineKeyboardButton("☑️ انتخاب همه", callback_data="cr_all"))
    row.append(types.InlineKeyboardButton("📥 تایید و ادامه", callback_data="cr_done"))
    markup.add(*row)
    markup.add(types.InlineKeyboardButton("❌ انصراف", callback_data="cr_cancel"))
    return markup

@bot.message_handler(func=lambda m: True)
def handle_messages(m):
    if not check_admin(m): return
    txt = m.text.strip()
    
    if txt == "🔙 پایان مدیریت" or txt == "لغو":
        active_targets.pop(m.chat.id, None)
        create_states.pop(m.chat.id, None)
        bot.clear_step_handler_by_chat_id(m.chat.id)
        bot.reply_to(m, "عملیات لغو شد. 🔙", reply_markup=get_main_reply_keyboard())
        return

    if txt == "➕ ساخت کانفیگ جدید":
        conn = get_db(); c = conn.cursor()
        c.execute("SELECT * FROM servers WHERE allow_sell=1")
        servers = c.fetchall(); conn.close()
        if not servers:
            bot.reply_to(m, "❌ هیچ سروری برای فروش فعال نیست! از داخل پنل تیک 'اجازه ساخت کانفیگ' را بزنید.")
            return
        markup = types.InlineKeyboardMarkup(row_width=1)
        for s in servers:
            markup.add(types.InlineKeyboardButton(f"🌐 {s['name']}", callback_data=f"cr_srv_{s['id']}"))
        bot.send_message(m.chat.id, "لطفاً سرور مورد نظر برای ساخت اکانت را انتخاب کنید:", reply_markup=markup)
        return

    if txt in ["🔄 تمدید اکانت", "⏯ تغییر وضعیت (فعال/غیرفعال)", "❌ حذف اکانت"]:
        target = active_targets.get(m.chat.id)
        if not target:
            bot.reply_to(m, "⚠️ هیچ اکانتی انتخاب نشده است! ابتدا جستجو کنید.")
            return
        if txt == "❌ حذف اکانت":
            wait = bot.send_message(m.chat.id, "⏳ در حال حذف...")
            ok, msg = perform_action(target['sid'], target['uuid'], "delete")
            bot.delete_message(m.chat.id, wait.message_id)
            bot.send_message(m.chat.id, msg, reply_markup=get_main_reply_keyboard())
            active_targets.pop(m.chat.id, None)
        elif txt == "⏯ تغییر وضعیت (فعال/غیرفعال)":
            wait = bot.send_message(m.chat.id, "⏳ در حال تغییر وضعیت...")
            ok, msg = perform_action(target['sid'], target['uuid'], "toggle")
            bot.delete_message(m.chat.id, wait.message_id)
            bot.send_message(m.chat.id, msg, parse_mode="Markdown")
        elif txt == "🔄 تمدید اکانت":
            step_states[m.chat.id] = {'sid': target['sid'], 'uuid': target['uuid']}
            msg = bot.send_message(m.chat.id, "🔄 **تمدید:**\nتعداد روز را بصورت عدد وارد کنید:\n(0 = نامحدود | لغو)", parse_mode="Markdown", reply_markup=types.ReplyKeyboardRemove())
            bot.register_next_step_handler(msg, step_days)
        return

    bot.clear_step_handler_by_chat_id(m.chat.id)
    query = urllib.parse.urlparse("vless://" + txt.split("://")[-1]).username if "vless://" in txt.lower() else txt
    query = urllib.parse.urlparse("trojan://" + query.split("://")[-1]).username if "trojan://" in query.lower() else query
    msg_wait = bot.reply_to(m, "⏳ در حال جستجو...", reply_markup=get_main_reply_keyboard())
    conn = get_db(); c = conn.cursor(); c.execute("SELECT * FROM servers")
    servers = c.fetchall(); conn.close()
    
    found = []
    for srv in servers:
        for cl in fetch_clients(dict(srv)):
            if query == cl['uuid'] or query.lower() == cl['email'].lower(): found.append(cl)
    bot.delete_message(m.chat.id, msg_wait.message_id)
    if not found:
        bot.send_message(m.chat.id, "❌ اکانتی یافت نشد!")
        return
    if len(found) > 1:
        markup = types.InlineKeyboardMarkup(row_width=1)
        for cl in found: markup.add(types.InlineKeyboardButton(f"سـرور: {cl['server_name']} | یوزر: {cl['email']}", callback_data=f"sel_{cl['server_id']}_{cl['uuid']}"))
        bot.send_message(m.chat.id, "⚠️ **تکرار در چند سرور!** انتخاب کنید:", reply_markup=markup, parse_mode="Markdown")
    else: show_client_info_and_keyboard(m.chat.id, found[0])

def show_client_info_and_keyboard(chat_id, cl):
    active_targets[chat_id] = {'sid': cl['server_id'], 'uuid': cl['uuid']}
    status = "✅ فعال" if cl['enable'] else "⏸ غیرفعال"
    used = (cl['up'] + cl['down']) / (1024**3)
    total = cl['total'] / (1024**3) if cl['total'] > 0 else 0
    t_left = (cl['expiry'] - (time.time() * 1000)) / (24*3600*1000)
    exp_str = f"{t_left:.1f} روز" if cl['expiry'] > 0 and t_left > 0 else "❌ پایان یافته" if cl['expiry'] > 0 else "♾ نامحدود"
    markup = types.InlineKeyboardMarkup(row_width=2)
    markup.add(types.InlineKeyboardButton(f"👤 {cl['email']}", callback_data="ign"), types.InlineKeyboardButton(f"🖥 {cl['server_name']}", callback_data="ign"))
    markup.add(types.InlineKeyboardButton(f"📦 {'♾' if total==0 else f'{total:.1f} GB'}", callback_data="ign"), types.InlineKeyboardButton(f"📉 مصرف: {used:.2f} GB", callback_data="ign"))
    markup.add(types.InlineKeyboardButton(f"⏳ {exp_str}", callback_data="ign"), types.InlineKeyboardButton(f"وضعیت: {status}", callback_data="ign"))
    bot.send_message(chat_id, "🔍 **اکانت پیدا شد!**", reply_markup=get_main_reply_keyboard(), parse_mode="Markdown")
    bot.send_message(chat_id, "📊 **جزئیات:**", reply_markup=markup, parse_mode="Markdown")

@bot.callback_query_handler(func=lambda c: c.data.startswith('cr_srv_'))
def handle_create_srv(call):
    bot.delete_message(call.message.chat.id, call.message.message_id)
    sid = int(call.data.split('_')[2])
    create_states[call.message.chat.id] = {'sid': sid, 'selected': []}
    wait = bot.send_message(call.message.chat.id, "⏳ در حال دریافت پورت‌های سرور...")
    
    conn = get_db(); c = conn.cursor(); c.execute("SELECT * FROM servers WHERE id=?", (sid,))
    srv = c.fetchone(); conn.close()
    url = srv['host'].rstrip('/')
    if not url.startswith("http"): url = "https://" + url
    
    inbounds = []
    with XrayTunnel(srv.get('xray_config', '')) as pxy:
        proxies = {"http": pxy, "https": pxy} if pxy else None
        s = get_session()
        try:
            res_login = s.post(f"{url}/login", data={"username": srv['user'], "password": srv['password']}, proxies=proxies, timeout=10)
            try: is_logged = res_login.json().get('success')
            except: is_logged = res_login.status_code == 200
            
            if is_logged:
                inb_res = s.get(f"{url}/panel/api/inbounds/list", proxies=proxies, timeout=10)
                try: inbounds = inb_res.json().get("obj", [])
                except: pass
        except: pass
    
    bot.delete_message(call.message.chat.id, wait.message_id)
    if not inbounds:
        bot.send_message(call.message.chat.id, "❌ خطا در دریافت پورت‌ها! (ممکن است اطلاعات سرور اشتباه باشد)", reply_markup=get_main_reply_keyboard())
        return
        
    create_states[call.message.chat.id]['inbounds'] = inbounds
    bot.send_message(call.message.chat.id, "🔘 **لطفاً پورت(های) مورد نظر را انتخاب کنید:**", reply_markup=get_inb_keyboard(call.message.chat.id), parse_mode="Markdown")

@bot.callback_query_handler(func=lambda c: c.data.startswith('cr_'))
def handle_create_actions(call):
    action = call.data
    cid = call.message.chat.id
    st = create_states.get(cid)
    if not st: return
    
    if action == "cr_cancel":
        bot.delete_message(cid, call.message.message_id)
        create_states.pop(cid, None)
        bot.send_message(cid, "عملیات لغو شد.", reply_markup=get_main_reply_keyboard())
        return
        
    elif action == "cr_all":
        all_ids = [ib['id'] for ib in st.get('inbounds', [])]
        if set(st['selected']) == set(all_ids): st['selected'] = []
        else: st['selected'] = all_ids
        bot.edit_message_reply_markup(cid, call.message.message_id, reply_markup=get_inb_keyboard(cid))
        
    elif action == "cr_done":
        if not st['selected']:
            bot.answer_callback_query(call.id, "حداقل یک پورت را انتخاب کنید!", show_alert=True)
            return
        bot.delete_message(cid, call.message.message_id)
        msg = bot.send_message(cid, "📝 **نام کاربری (Email) را به انگلیسی وارد کنید:**\n(لغو)", reply_markup=types.ReplyKeyboardRemove(), parse_mode="Markdown")
        bot.register_next_step_handler(msg, cr_step_name)
        
    elif action.startswith('cr_inb_'):
        inb_id = int(action.split('_')[2])
        if inb_id in st['selected']: st['selected'].remove(inb_id)
        else: st['selected'].append(inb_id)
        bot.edit_message_reply_markup(cid, call.message.message_id, reply_markup=get_inb_keyboard(cid))

def cr_step_name(m):
    txt = m.text.strip()
    if txt == "لغو": return handle_messages(m)
    create_states[m.chat.id]['name'] = txt
    msg = bot.send_message(m.chat.id, "📅 **تعداد روز اعتبار را وارد کنید:**\n(0 = نامحدود)", parse_mode="Markdown")
    bot.register_next_step_handler(msg, cr_step_days)

def cr_step_days(m):
    txt = m.text.strip()
    if txt == "لغو": return handle_messages(m)
    if not txt.isdigit():
        msg = bot.reply_to(m, "❌ فقط عدد! تعداد روز:"); bot.register_next_step_handler(msg, cr_step_days); return
    create_states[m.chat.id]['days'] = int(txt)
    msg = bot.send_message(m.chat.id, "📦 **حجم به گیگابایت را وارد کنید:**\n(0 = نامحدود)", parse_mode="Markdown")
    bot.register_next_step_handler(msg, cr_step_gb)

def cr_step_gb(m):
    txt = m.text.strip()
    if txt == "لغو": return handle_messages(m)
    if not txt.isdigit():
        msg = bot.reply_to(m, "❌ فقط عدد! حجم (GB):"); bot.register_next_step_handler(msg, cr_step_gb); return
    st = create_states.get(m.chat.id)
    if not st: return
    
    wait = bot.send_message(m.chat.id, "⏳ در حال ساخت کانفیگ در سرور...")
    ok, msg_resp, uid = create_config(st['sid'], st['selected'], st['name'], st['days'], int(txt), st['inbounds'])
    bot.delete_message(m.chat.id, wait.message_id)
    bot.send_message(m.chat.id, msg_resp, parse_mode="Markdown", reply_markup=get_main_reply_keyboard())
    create_states.pop(m.chat.id, None)

@bot.callback_query_handler(func=lambda c: c.data.startswith('sel_'))
def handle_select_server(call):
    bot.delete_message(call.message.chat.id, call.message.message_id)
    data = call.data.split('_'); sid, uuid = int(data[1]), data[2]
    conn = get_db(); cr = conn.cursor(); cr.execute("SELECT * FROM servers WHERE id=?", (sid,))
    srv = cr.fetchone(); conn.close()
    if srv:
        for cl in fetch_clients(dict(srv)):
            if cl['uuid'] == uuid: show_client_info_and_keyboard(call.message.chat.id, cl); return
    bot.send_message(call.message.chat.id, "❌ خطا در دریافت اطلاعات.")

def step_days(m):
    txt = m.text.strip()
    if txt == "لغو" or txt == "🔙 پایان مدیریت": return handle_messages(m)
    if not txt.isdigit():
        msg = bot.reply_to(m, "❌ فقط عدد وارد کنید.\nتعداد روز:"); bot.register_next_step_handler(msg, step_days); return
    step_states[m.chat.id]['days'] = int(txt)
    msg = bot.send_message(m.chat.id, "📊 **حجم (گیگابایت):**", parse_mode="Markdown")
    bot.register_next_step_handler(msg, step_gb)

def step_gb(m):
    txt = m.text.strip()
    if txt == "لغو" or txt == "🔙 پایان مدیریت": return handle_messages(m)
    if not txt.isdigit():
        msg = bot.reply_to(m, "❌ فقط عدد!\nمقدار حجم:"); bot.register_next_step_handler(msg, step_gb); return
    st = step_states.get(m.chat.id)
    if not st: return
    wait = bot.send_message(m.chat.id, "⏳ در حال تمدید...")
    ok, msg_resp = perform_action(st['sid'], st['uuid'], "extend", days=st['days'], gb=int(txt))
    bot.delete_message(m.chat.id, wait.message_id)
    bot.send_message(m.chat.id, msg_resp, parse_mode="Markdown", reply_markup=get_main_reply_keyboard())
    step_states.pop(m.chat.id, None)

@bot.callback_query_handler(func=lambda c: c.data == "ign")
def ignore_clicks(call): bot.answer_callback_query(call.id, "این دکمه نمایشی است 📊")

bot.infinity_polling()
EOF

# --- main.py ---
cat << 'EOF' > main.py
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import sqlite3, uvicorn, os, glob

for f in glob.glob('/tmp/userrenew_*.json'):
    try: os.remove(f)
    except: pass
os.system("pkill -f 'xray run -c /tmp/userrenew_'")

app = FastAPI()
DB_PATH = 'users.db'

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('CREATE TABLE IF NOT EXISTS servers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, host TEXT, user TEXT, password TEXT, xray_config TEXT, allow_sell INTEGER DEFAULT 1)')
    try: c.execute("ALTER TABLE servers ADD COLUMN allow_sell INTEGER DEFAULT 1")
    except: pass
    try: c.execute("ALTER TABLE servers ADD COLUMN panel_type TEXT DEFAULT 'new'")
    except: pass
    c.execute('CREATE TABLE IF NOT EXISTS admin (username TEXT, password TEXT)')
    c.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)')
    if c.execute('SELECT count(*) FROM admin').fetchone()[0] == 0:
        c.execute("INSERT INTO admin VALUES ('ADMIN_PLACEHOLDER', 'PASS_PLACEHOLDER')")
    conn.commit(); conn.close()
init_db()

class LoginModel(BaseModel): username: str; password: str
class ServerModel(BaseModel): name: str; host: str; user: str; password: str; xray_config: str; allow_sell: bool; panel_type: str = 'new'
class SettingsModel(BaseModel): admin_ids: str

@app.post("/api/login")
def login(data: LoginModel):
    conn = sqlite3.connect(DB_PATH); c = conn.cursor()
    c.execute("SELECT * FROM admin WHERE username=? AND password=?", (data.username, data.password))
    valid = c.fetchone() is not None; conn.close()
    return {"success": valid}

@app.get("/api/settings")
def get_settings():
    conn = sqlite3.connect(DB_PATH); c = conn.cursor()
    c.execute("SELECT value FROM settings WHERE key='admin_ids'")
    row = c.fetchone(); conn.close()
    return {"admin_ids": row[0] if row else ""}

@app.post("/api/settings")
def save_settings(s: SettingsModel):
    conn = sqlite3.connect(DB_PATH); c = conn.cursor()
    c.execute("INSERT OR REPLACE INTO settings (key, value) VALUES ('admin_ids', ?)", (s.admin_ids,))
    conn.commit(); conn.close(); return {"success": True}

@app.get("/api/servers")
def get_servers():
    conn = sqlite3.connect(DB_PATH); conn.row_factory = sqlite3.Row; c = conn.cursor()
    servers = [dict(r) for r in c.execute("SELECT * FROM servers ORDER BY id DESC").fetchall()]; conn.close()
    return servers

@app.post("/api/servers")
def add_server(s: ServerModel):
    conn = sqlite3.connect(DB_PATH); c = conn.cursor()
    c.execute("INSERT INTO servers (name, host, user, password, xray_config, allow_sell, panel_type) VALUES (?, ?, ?, ?, ?, ?, ?)", (s.name, s.host, s.user, s.password, s.xray_config, 1 if s.allow_sell else 0, s.panel_type))
    conn.commit(); conn.close(); return {"success": True}

@app.put("/api/servers/{server_id}")
def edit_server(server_id: int, s: ServerModel):
    conn = sqlite3.connect(DB_PATH); c = conn.cursor()
    c.execute("UPDATE servers SET name=?, host=?, user=?, password=?, xray_config=?, allow_sell=?, panel_type=? WHERE id=?", (s.name, s.host, s.user, s.password, s.xray_config, 1 if s.allow_sell else 0, s.panel_type, server_id))
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

sed -i "s/BOT_TOKEN_PLACEHOLDER/$BOT_TOKEN/g" xray_bot.py
sed -i "s/PORT_PLACEHOLDER/$PANEL_PORT/g" main.py
sed -i "s/ADMIN_PLACEHOLDER/$PANEL_USER/g" main.py
sed -i "s/PASS_PLACEHOLDER/$PANEL_PASS/g" main.py

python3 -m venv venv
source venv/bin/activate
pip install -q telebot "requests[socks]" fastapi uvicorn pydantic

cat << 'EOF_MENU' > /usr/bin/userrenew
#!/bin/bash
PURPLE="\e[35m"
GREEN="\e[32m"
RED="\e[31m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

change_token() {
    read -p "Enter New Bot Token: " new_token
    sed -i "s/BOT_TOKEN = \".*\"/BOT_TOKEN = \"$new_token\"/g" /root/UserRenew/xray_bot.py
    systemctl restart userrenew-bot
    echo -e "${GREEN}[+] Bot token updated successfully!${RESET}"
    sleep 2
}

change_port() {
    read -p "Enter New Panel Port: " new_port
    sed -i "s/port=[0-9]*/port=$new_port/g" /root/UserRenew/main.py
    systemctl restart userrenew-panel
    echo -e "${GREEN}[+] Panel port updated to $new_port successfully!${RESET}"
    sleep 2
}

change_creds() {
    read -p "Enter New Admin Username: " new_user
    read -p "Enter New Admin Password: " new_pass
    safe_user=$(echo "$new_user" | sed "s/'/''/g")
    safe_pass=$(echo "$new_pass" | sed "s/'/''/g")
    sqlite3 /root/UserRenew/users.db "UPDATE admin SET username='$safe_user', password='$safe_pass';"
    echo -e "${GREEN}[+] Admin credentials updated successfully!${RESET}"
    sleep 2
}

uninstall_all() {
    echo -e "${RED}[!] WARNING: This will delete everything (including database).${RESET}"
    read -p "Are you sure? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        systemctl stop userrenew-panel userrenew-bot
        systemctl disable userrenew-panel userrenew-bot
        rm -f /etc/systemd/system/userrenew-*
        systemctl daemon-reload
        rm -rf /root/UserRenew
        rm -f /usr/bin/userrenew
        echo -e "${GREEN}[+] UserRenew completely uninstalled.${RESET}"
        exit 0
    fi
}

while true; do
    clear
    echo -e "${CYAN}====================================================${RESET}"
    echo -e "${PURPLE}             UserRenew Management                   ${RESET}"
    echo -e "${CYAN}====================================================${RESET}"
    echo -e "1. ${YELLOW}Change Telegram Bot Token${RESET}"
    echo -e "2. ${YELLOW}Change Panel Web Port${RESET}"
    echo -e "3. ${YELLOW}Change Panel Username & Password${RESET}"
    echo -e "4. ${GREEN}Restart Services${RESET}"
    echo -e "5. ${RED}Uninstall Entire System${RESET}"
    echo -e "6. Exit"
    echo -e "${CYAN}====================================================${RESET}"
    read -p "Select an option [1-6]: " choice
    case $choice in
        1) change_token ;;
        2) change_port ;;
        3) change_creds ;;
        4) systemctl restart userrenew-panel userrenew-bot && echo -e "${GREEN}[+] Services Restarted!${RESET}" && sleep 2 ;;
        5) uninstall_all ;;
        6) exit 0 ;;
        *) echo -e "${RED}Invalid option!${RESET}" && sleep 1 ;;
    esac
done
EOF_MENU
chmod +x /usr/bin/userrenew

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
echo -e "${PURPLE}[+] Admin Username:${RESET} $PANEL_USER"
echo -e "${PURPLE}[+] Type ${GREEN}userrenew${PURPLE} in terminal for CLI menu.${RESET}"
echo -e "${GREEN}====================================================${RESET}"
