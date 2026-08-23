#!/bin/sh
set -u

VIDEO='https://www.youtube.com/watch?v=BUN1qw0yH6M'
BASE='https://p.savenow.to'
FORMAT='1080'

RAW='BUN1qw0yH6M-1080p-source.mp4.part'
FINAL='BUN1qw0yH6M-1080p-iPhone12.mp4'
CLEAN='BUN1qw0yH6M-1080p-iPhone12.tmp.mp4'

UA='Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 Version/26.0 Mobile/15E148 Safari/604.1'

say() { printf '%s\n' "$*"; }
log() { printf '%s\n' "$*" >&2; }
fail() { say ""; say "ОШИБКА: $*"; exit 1; }

cd "$HOME/Documents" 2>/dev/null || cd "$HOME" || exit 1

command -v curl >/dev/null 2>&1 || fail 'в a-Shell нет curl.'
command -v python3 >/dev/null 2>&1 || fail 'в a-Shell нет python3.'

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  say 'Не вижу ffmpeg/ffprobe. Пробую доступный менеджер пакетов...'
  if command -v pkg >/dev/null 2>&1; then pkg install ffmpeg >/dev/null 2>&1 || true; fi
fi

command -v ffmpeg >/dev/null 2>&1 || fail 'не удалось получить ffmpeg.'
command -v ffprobe >/dev/null 2>&1 || fail 'не удалось получить ffprobe.'

FREE=$(python3 -c 'import shutil; print(shutil.disk_usage(".").free)')
if [ "$FREE" -lt 6500000000 ] 2>/dev/null; then
  GB=$(python3 -c 'import shutil; print(round(shutil.disk_usage(".").free/1e9,1))')
  fail "нужно примерно 6.5 ГБ свободного места; сейчас около ${GB} ГБ."
fi

jget() {
  python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    v=d.get(sys.argv[1], "") if isinstance(d,dict) else ""
    print("" if v is None else v)
except Exception:
    pass
' "$1"
}

resolve_link() {
  INIT=''; TRY=1; ID=''; PURL=''
  while [ "$TRY" -le 6 ]; do
    INIT=$(curl -fsSL --connect-timeout 15 --max-time 60 --retry 2 --retry-delay 2 -A "$UA" -H 'Accept: application/json,*/*' -H "Referer: $BASE/api/button/" --get "$BASE/api/v2/download" --data-urlencode 'button=1' --data-urlencode "format=$FORMAT" --data-urlencode 'iframe_source=direct-iframe' --data-urlencode "url=$VIDEO" 2>/dev/null || true)
    ID=$(printf '%s' "$INIT" | jget id)
    PURL=$(printf '%s' "$INIT" | jget progress_url)
    [ -n "$ID" ] && break
    log "Сервис не ответил, повтор $TRY/6..."
    sleep $((TRY * 2))
    TRY=$((TRY + 1))
  done
  [ -n "$ID" ] || return 1

  log 'Сервис готовит 1080p...'
  N=1; DOWNLOAD=''
  while [ "$N" -le 360 ]; do
    if [ "$N" -eq 1 ] && [ -n "$PURL" ]; then POLL=$PURL; else POLL="$BASE/api/progress?id=$ID"; fi
    R=$(curl -fsSL --connect-timeout 15 --max-time 45 --retry 2 --retry-delay 2 -A "$UA" -H 'Accept: application/json,*/*' -H "Referer: $BASE/" "$POLL" 2>/dev/null || true)
    DOWNLOAD=$(printf '%s' "$R" | jget download_url)
    if [ -n "$DOWNLOAD" ]; then printf '\n' >&2; printf '%s' "$DOWNLOAD"; return 0; fi
    if [ $((N % 10)) -eq 0 ]; then printf '.' >&2; fi
    sleep 2
    N=$((N + 1))
  done
  printf '\n' >&2
  return 1
}

rm -f "$CLEAN"
ATTEMPT=1; DOWNLOADED=0
while [ "$ATTEMPT" -le 3 ]; do
  say "Получаю ссылку (попытка $ATTEMPT/3)..."
  DOWNLOAD=$(resolve_link) || DOWNLOAD=''
  if [ -z "$DOWNLOAD" ]; then
    say 'Не удалось получить готовую ссылку; повторяю.'
    ATTEMPT=$((ATTEMPT + 1)); sleep 5; continue
  fi

  rm -f "$RAW"
  say ""
  say 'Скачиваю полный файл.'
  say 'Оставь a-Shell открытым на экране.'
  say ""

  if curl -fL --retry 12 --retry-delay 3 --connect-timeout 20 --speed-time 60 --speed-limit 1024 -A "$UA" -H "Referer: $BASE/" --progress-bar -o "$RAW" "$DOWNLOAD"; then
    SIZE=$(python3 -c 'import os,sys; print(os.path.getsize(sys.argv[1]))' "$RAW" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 100000000 ] 2>/dev/null; then DOWNLOADED=1; break; fi
  fi

  say ""
  say 'Загрузка оборвалась или пришёл неправильный файл.'
  say 'Получаю новую ссылку и начинаю заново.'
  rm -f "$RAW"
  ATTEMPT=$((ATTEMPT + 1))
done

[ "$DOWNLOADED" -eq 1 ] || fail 'после трёх независимых попыток файл не скачался.'

say ""
say 'Проверяю кодеки...'
V=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$RAW" 2>/dev/null | head -n 1)
A=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$RAW" 2>/dev/null | head -n 1)
W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$RAW" 2>/dev/null | head -n 1)
H=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$RAW" 2>/dev/null | head -n 1)

[ "$V" = h264 ] || fail "ожидался H.264, получено: ${V:-неизвестно}."
[ "$A" = aac ] || fail "ожидался AAC, получено: ${A:-неизвестно}."
[ "${W:-0}" -ge 1900 ] 2>/dev/null || fail "ширина меньше 1080p: ${W:-?}."
[ "${H:-0}" -ge 1080 ] 2>/dev/null || fail "высота меньше 1080p: ${H:-?}."

say 'Очищаю MP4 для iPhone без перекодирования...'
rm -f "$CLEAN"
ffmpeg -hide_banner -loglevel error -y -i "$RAW" -map 0:v:0 -map 0:a:0 -map_chapters -1 -map_metadata -1 -c copy -movflags +faststart "$CLEAN" || fail 'ffmpeg не смог перепаковать MP4.'

STREAMS=$(ffprobe -v error -show_entries stream=codec_type -of csv=p=0 "$CLEAN" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
[ "$STREAMS" = 'video,audio' ] || fail "после очистки ожидались только video,audio; получено: $STREAMS"

DUR=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$CLEAN" 2>/dev/null | head -n 1)
python3 -c 'import sys
try: d=float(sys.argv[1])
except Exception: raise SystemExit(1)
raise SystemExit(0 if d > 4400 else 1)' "$DUR" || fail 'длительность итогового файла выглядит неправильной.'

rm -f "$FINAL"
mv "$CLEAN" "$FINAL" || fail 'не удалось переименовать итоговый файл.'
rm -f "$RAW"

SHA=$(python3 - "$FINAL" <<'PY'
import hashlib,sys
h=hashlib.sha256()
with open(sys.argv[1], 'rb') as f:
    for block in iter(lambda: f.read(8*1024*1024), b''):
        h.update(block)
print(h.hexdigest())
PY
)

SIZE_H=$(python3 - "$FINAL" <<'PY'
import os,sys
n=os.path.getsize(sys.argv[1])
print(f'{n/1e9:.2f} GB')
PY
)

say ""
say '========================================='
say 'ГОТОВО'
say "Файл: $PWD/$FINAL"
say "Размер: $SIZE_H"
say "SHA-256: $SHA"
say '========================================='
