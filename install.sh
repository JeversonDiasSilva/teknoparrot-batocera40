#!/bin/bash
# Batocera TeknoParrot — instalador para Batocera 40
#
#   Instalar/atualizar (app + prefixo Wine + jogo Star Wars):
#     curl -fsSL https://raw.githubusercontent.com/JeversonDiasSilva/teknoparrot-batocera40/main/install.sh | bash
#   Só o sistema, sem o jogo:
#     curl -fsSL https://raw.githubusercontent.com/JeversonDiasSilva/teknoparrot-batocera40/main/install.sh | bash -s -- --sem-jogo
#   A partir de pacotes já baixados (sem internet):
#     TP_LOCAL=/caminho/dos/pacotes bash install.sh
#
# O Wine (ge-custom) NÃO é instalado: já vem no Batocera 40 (/usr/wine/ge-custom).
set -euo pipefail

REPO="JeversonDiasSilva/teknoparrot-batocera40"
VERSAO="v1.0"
APP_PACOTE="teknoparrot-app-batocera40.squashfs";     APP_SHA="5d3b934c89dfc3320de23b1ea98ce1765bd7ae9a653aee65ffb37a9b7c61046c"
PREFIX_PACOTE="teknoparrot-prefix-batocera40.squashfs"; PREFIX_SHA="e31cbac9e51c85d80d8e6576fef1f6632674c01be808fbe195096454bc78c925"
JOGO_PACOTE="starwars-battlepod.squashfs";             JOGO_SHA="3cfddcd2d49e3cc4d719c8eca37a974e2b6074779fd2b2f1484469abc332ee22"
JOGO_NPARTES=2   # 1 = arquivo único; >1 = baixa part-00..part-NN e junta

APP_DIR="/userdata/system/.dev/apps/teknoparrot"
PREFIX_DIR="/userdata/system/.local/share/TeknoParrotUI"
ROMS="/userdata/roms/teknoparrot"
JOGO_DIR="$ROMS/StarWarsBattlePod"
ESCFG="/userdata/system/configs/emulationstation/es_systems_teknoparrot.cfg"
KEYS="/userdata/system/configs/evmapy/teknoparrot.keys"
DESKTOP="/userdata/system/.local/share/applications/teknoparrot.desktop"
DATA="$(date +%Y%m%d-%H%M%S)"
BASEURL="https://github.com/$REPO/releases/download/$VERSAO"

msg()  { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
erro() { printf '\033[1;31mERRO:\033[0m %s\n' "$*" >&2; exit 1; }

command -v unsquashfs >/dev/null || erro "unsquashfs não encontrado"
[ -d /userdata ] || erro "isto é para o Batocera (/userdata não existe)"
[ -x /usr/wine/ge-custom/bin/wine ] || msg "AVISO: /usr/wine/ge-custom não encontrado — o TeknoParrot precisa do Wine ge-custom do Batocera 40"
grep -q '^40' /usr/share/batocera/batocera.version 2>/dev/null || \
  msg "AVISO: testado no Batocera 40; versão atual: $(cat /usr/share/batocera/batocera.version 2>/dev/null || echo desconhecida)"

SEM_JOGO=0
[ "${1:-}" = "--sem-jogo" ] && SEM_JOGO=1

TMP="$(mktemp -d /userdata/system/.teknoparrot-install.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# baixa (ou usa local via TP_LOCAL) um pacote e confere o SHA-256. Suporta pacote dividido em partes.
obter() { # $1=pacote $2=sha $3=npartes
  local pac="$1" sha="$2" np="${3:-1}" destino="$TMP/$1" i num
  if [ "$np" -le 1 ]; then
    if [ -n "${TP_LOCAL:-}" ] && [ -f "$TP_LOCAL/$pac" ]; then cp "$TP_LOCAL/$pac" "$destino"
    else msg "Baixando $pac..."; curl -fL --retry 3 -o "$destino" "$BASEURL/$pac"; fi
  else
    msg "Baixando $pac ($np partes)..."; : > "$destino"
    for i in $(seq 0 $((np-1))); do
      num="$(printf '%02d' "$i")"
      if [ -n "${TP_LOCAL:-}" ] && [ -f "$TP_LOCAL/$pac.part-$num" ]; then cat "$TP_LOCAL/$pac.part-$num" >> "$destino"
      else curl -fL --retry 3 -o "$TMP/p" "$BASEURL/$pac.part-$num"; cat "$TMP/p" >> "$destino"; rm -f "$TMP/p"; fi
    done
  fi
  msg "Conferindo SHA-256 de $pac..."
  echo "$sha  $destino" | sha256sum -c --quiet - || erro "pacote $pac corrompido (SHA-256 não confere) — baixe de novo"
}

backup() { [ -e "$1" ] && cp -a "$1" "$1.antes-$DATA.bak" || true; }

# junta um gamelist.xml em outro sem apagar os jogos existentes
mesclar_gamelist() {
  local novo="$1" dest="$2"
  [ -f "$dest" ] || { cp "$novo" "$dest"; return; }
  cp "$dest" "$dest.antes-$DATA.bak"
  python3 -I - "$novo" "$dest" <<'PY'
import sys, xml.etree.ElementTree as ET
novo=ET.parse(sys.argv[1]).getroot(); dest=ET.parse(sys.argv[2]); raiz=dest.getroot()
tem={g.findtext('path') for g in raiz.findall('game')}
for g in novo.findall('game'):
    if g.findtext('path') not in tem: raiz.append(g)
dest.write(sys.argv[2], encoding='utf-8', xml_declaration=True)
PY
}

### 1) APP ###
obter "$APP_PACOTE" "$APP_SHA" 1
[ -e "$APP_DIR" ] && { msg "Guardando app anterior em $APP_DIR.antes-$DATA"; mv "$APP_DIR" "$APP_DIR.antes-$DATA"; }
mkdir -p "$(dirname "$APP_DIR")"            # cria /userdata/system/.dev/apps se não existir
msg "Extraindo o app em $APP_DIR..."
unsquashfs -q -n -d "$APP_DIR" "$TMP/$APP_PACOTE" >/dev/null

# posiciona as configs (pasta sistema/ do pacote). Os caminhos internos já apontam p/ .dev/apps.
SIS="$APP_DIR/sistema"
mkdir -p "$(dirname "$ESCFG")" "$(dirname "$KEYS")" "$(dirname "$DESKTOP")" "$ROMS/images"
backup "$ESCFG";  cp "$SIS/es_systems_teknoparrot.cfg" "$ESCFG"
backup "$KEYS";   cp "$SIS/teknoparrot.keys" "$KEYS"
backup "$DESKTOP";cp "$SIS/teknoparrot.desktop" "$DESKTOP"
cp "$SIS"/*.teknoparrot "$ROMS/" 2>/dev/null || true
[ -f "$SIS/_info.txt" ] && cp "$SIS/_info.txt" "$ROMS/_info.txt"
[ -f "$SIS/gamelist.xml" ] && mesclar_gamelist "$SIS/gamelist.xml" "$ROMS/gamelist.xml"
cp "$SIS"/images/* "$ROMS/images/" 2>/dev/null || true
rm -rf "$SIS"
msg "App instalado em $APP_DIR"

### 2) PREFIXO WINE (controles + registro já configurados) ###
obter "$PREFIX_PACOTE" "$PREFIX_SHA" 1
[ -e "$PREFIX_DIR" ] && { msg "Guardando prefixo anterior em $PREFIX_DIR.antes-$DATA"; mv "$PREFIX_DIR" "$PREFIX_DIR.antes-$DATA"; }
mkdir -p "$(dirname "$PREFIX_DIR")"
msg "Extraindo o prefixo Wine em $PREFIX_DIR..."
unsquashfs -q -n -d "$PREFIX_DIR" "$TMP/$PREFIX_PACOTE" >/dev/null
msg "Prefixo Wine instalado"

### 3) JOGO Star Wars Battle Pod ###
if [ "$SEM_JOGO" = 0 ]; then
  obter "$JOGO_PACOTE" "$JOGO_SHA" "$JOGO_NPARTES"
  [ -e "$JOGO_DIR" ] && { msg "Guardando jogo anterior em $JOGO_DIR.antes-$DATA"; mv "$JOGO_DIR" "$JOGO_DIR.antes-$DATA"; }
  mkdir -p "$ROMS"
  msg "Extraindo o jogo em $JOGO_DIR (grande, aguarde)..."
  unsquashfs -q -n -d "$JOGO_DIR" "$TMP/$JOGO_PACOTE" >/dev/null
  msg "Jogo instalado em $JOGO_DIR"
else
  msg "Pulado o jogo (--sem-jogo). Coloque a pasta do jogo em $ROMS/ e crie o <nome>.teknoparrot."
fi

curl -s -m 5 http://127.0.0.1:1234/reloadgames >/dev/null 2>&1 || true
msg "Instalado! ($VERSAO)"
cat <<EOF

Próximos passos:
  1. Se o sistema "TeknoParrot" não aparecer, reinicie o EmulationStation
     (Menu > Sair > Reiniciar EmulationStation).
  2. Abra STAR WARS: Battle Pod. Na 1ª vez pode demorar ~40s carregando (tela "CARREGANDO...").
  3. Sair do jogo: SELECT+START ou HOTKEY+START.
  4. Controles: já vêm configurados no perfil (tiro=A, arma=B, visão=RB, Start=START, analógicos).
     Para reconfigurar: abra o TeknoParrot pelo menu de apps > CONTROLLER SETUP.

Log dos jogos: /userdata/system/logs/teknoparrot.log
O Wine usado é o ge-custom do Batocera 40 (/usr/wine/ge-custom) — não é instalado por aqui.
EOF
