#!/bin/sh
set -u

VIDEO='https://www.youtube.com/watch?v=BUN1qw0yH6M'
YTDLP="$HOME/Documents/bin/yt-dlp"
QJS="$HOME/Documents/bin/qjs"
RAW='BUN1qw0yH6M-1080p-iPhone12.raw.mp4'
CLEAN='BUN1qw0yH6M-1080p-iPhone12.clean.mp4'
FINAL='BUN1qw0yH6M-1080p-iPhone12.mp4'
FORMAT='bestvideo[height=1080][vcodec^=avc1][ext=mp4]+bestaudio[acodec^=mp4a][ext=m4a]/bestvideo[height<=1080][vcodec^=avc1][ext=mp4]+bestaudio[acodec^=mp4a][ext=m4a]/best[height<=1080][vcodec^=avc1][ext=mp4]'

say(){ printf '%s\n' "$*"; }
fail(){ say ""; say "ОШИБКА: $*"; exit 1; }

cd "$HOME/Documents" 2>/dev/null || fail 'не могу открыть ~/Documents.'
command -v curl >/dev/null 2>&1 || fail 'в a-Shell нет curl.'
command -v python3 >/dev/null 2>&1 || fail 'в a-Shell нет python3.'
command -v ffmpeg >/dev/null 2>&1 || fail 'в a-Shell нет ffmpeg.'
command -v ffprobe >/dev/null 2>&1 || fail 'в a-Shell нет ffprobe.'
mkdir -p "$HOME/Documents/bin" || fail 'не удалось создать ~/Documents/bin.'

say '1/5 Проверяю JS-движок...'
if ! command -v qjs >/dev/null 2>&1 && [ ! -f "$QJS" ]; then
  pkg install qjs || fail 'не удалось установить qjs.'
fi
if command -v qjs >/dev/null 2>&1; then
  QJS=$(command -v qjs)
elif [ -f "$HOME/Documents/bin/qjs" ]; then
  QJS="$HOME/Documents/bin/qjs"
else
  fail 'qjs не появился после установки.'
fi

say '2/5 Проверяю yt-dlp...'
if [ ! -f "$YTDLP" ] || ! python3 "$YTDLP" --version >/dev/null 2>&1; then
  TMP="$YTDLP.tmp"
  rm -f "$TMP"
  curl -4 -fL --connect-timeout 8 --max-time 60 --retry 2 --retry-delay 2 --progress-bar \
    'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp' -o "$TMP" \
    || { rm -f "$TMP"; fail 'не удалось скачать yt-dlp с GitHub.'; }
  python3 "$TMP" --version >/dev/null 2>&1 \
    || { rm -f "$TMP"; fail 'скачанный yt-dlp не запускается.'; }
  mv "$TMP" "$YTDLP" || fail 'не удалось сохранить yt-dlp.'
fi

say '3/5 Проверяю YouTube по IPv4. Большая загрузка НЕ начата...'
python3 - "$YTDLP" "$QJS" "$VIDEO" "$FORMAT" <<'PY'
import json, subprocess, sys

ytdlp, qjs, video, fmt = sys.argv[1:]
cmd = [
    sys.executable, ytdlp,
    '--force-ipv4',
    '--js-runtimes', f'quickjs:{qjs}',
    '--remote-components', 'ejs:github',
    '--no-playlist',
    '--simulate',
    '--socket-timeout', '8',
    '--extractor-retries', '1',
    '--retries', '1',
    '-f', fmt,
    '--dump-single-json',
    video,
]
try:
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=45)
except subprocess.TimeoutExpired:
    print('ОШИБКА: YouTube не ответил за 45 секунд. Большая загрузка не начата.')
    raise SystemExit(20)
if p.returncode != 0:
    tail = (p.stderr or p.stdout or '').strip().splitlines()[-4:]
    print('ОШИБКА: предварительная проверка YouTube не прошла.')
    for line in tail:
        print(line)
    raise SystemExit(21)
try:
    d = json.loads(p.stdout)
except Exception:
    print('ОШИБКА: yt-dlp вернул непонятный ответ. Большая загрузка не начата.')
    raise SystemExit(22)
parts = d.get('requested_formats') or [d]
v = next((x for x in parts if (x.get('vcodec') or 'none') != 'none'), None)
a = next((x for x in parts if (x.get('acodec') or 'none') != 'none'), None)
if not v or not a:
    print('ОШИБКА: не удалось выбрать видео+аудио.')
    raise SystemExit(23)
vcodec = v.get('vcodec') or ''
acodec = a.get('acodec') or ''
height = int(v.get('height') or 0)
width = int(v.get('width') or 0)
if not (vcodec.startswith('avc1') or vcodec.startswith('h264')):
    print('ОШИБКА: выбран не H.264:', vcodec)
    raise SystemExit(24)
if not (acodec.startswith('mp4a') or acodec.startswith('aac')):
    print('ОШИБКА: выбран не AAC:', acodec)
    raise SystemExit(25)
if height < 1080 or width < 1900:
    print(f'ОШИБКА: выбран формат ниже 1080p: {width}x{height}')
    raise SystemExit(26)
print(f'OK: выбран {width}x{height}, H.264 + AAC.')
PY
PRECHECK=$?
[ "$PRECHECK" -eq 0 ] || exit "$PRECHECK"

FREE=$(python3 -c 'import shutil; print(shutil.disk_usage(".").free)')
if [ "$FREE" -lt 6500000000 ] 2>/dev/null; then
  GB=$(python3 -c 'import shutil; print(round(shutil.disk_usage(".").free/1e9,1))')
  fail "для загрузки и финальной очистки нужно около 6.5 ГБ свободного места; сейчас около ${GB} ГБ."
fi

say ''
say 'Проверка прошла. Следующий шаг скачает примерно 2–3 ГБ.'
printf 'Если ты сейчас на Wi-Fi и хочешь начать, введи GO и нажми Enter: '
IFS= read -r CONFIRM
[ "$CONFIRM" = 'GO' ] || fail 'большая загрузка отменена. Ничего тяжёлого не скачано.'

say '4/5 Скачиваю 1080p H.264 + AAC. a-Shell не сворачивай.'
rm -f "$CLEAN"
python3 "$YTDLP" \
  --force-ipv4 \
  --js-runtimes "quickjs:$QJS" \
  --remote-components ejs:github \
  --no-playlist \
  -f "$FORMAT" \
  --merge-output-format mp4 \
  --continue \
  --retries infinite \
  --fragment-retries infinite \
  --retry-sleep 3 \
  --concurrent-fragments 1 \
  --newline \
  --progress \
  --socket-timeout 15 \
  -o "$RAW" \
  "$VIDEO" \
  || fail 'yt-dlp завершился ошибкой.'

[ -f "$RAW" ] || fail 'скачивание завершилось, но итоговый MP4 не найден.'

say '5/5 Очищаю MP4 для iPhone без перекодирования...'
ffmpeg -hide_banner -loglevel error -y -i "$RAW" \
  -map 0:v:0 -map 0:a:0 -map_chapters -1 -map_metadata -1 \
  -c copy -movflags +faststart "$CLEAN" \
  || fail 'ffmpeg не смог очистить MP4.'

STREAMS=$(ffprobe -v error -show_entries stream=codec_type -of csv=p=0 "$CLEAN" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
[ "$STREAMS" = 'video,audio' ] || fail "после очистки ожидались только video,audio; получено: $STREAMS"
V=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$CLEAN" 2>/dev/null | head -n 1)
A=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$CLEAN" 2>/dev/null | head -n 1)
W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$CLEAN" 2>/dev/null | head -n 1)
H=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$CLEAN" 2>/dev/null | head -n 1)
D=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$CLEAN" 2>/dev/null | head -n 1)
[ "$V" = h264 ] || fail "финальное видео не H.264: ${V:-?}."
[ "$A" = aac ] || fail "финальное аудио не AAC: ${A:-?}."
[ "${W:-0}" -ge 1900 ] 2>/dev/null || fail "финальное видео меньше 1080p: ${W:-?}x${H:-?}."
[ "${H:-0}" -ge 1080 ] 2>/dev/null || fail "финальное видео меньше 1080p: ${W:-?}x${H:-?}."
python3 -c 'import sys; d=float(sys.argv[1]); raise SystemExit(0 if d>4400 else 1)' "$D" 2>/dev/null \
  || fail 'финальный ролик выглядит обрезанным.'

rm -f "$FINAL"
mv "$CLEAN" "$FINAL" || fail 'не удалось сохранить финальный файл.'
rm -f "$RAW"

SHA=$(python3 -c 'import hashlib,sys; h=hashlib.sha256(); f=open(sys.argv[1],"rb"); [h.update(b) for b in iter(lambda:f.read(8*1024*1024),b"")]; print(h.hexdigest())' "$FINAL")
SIZE=$(python3 -c 'import os,sys; print(f"{os.path.getsize(sys.argv[1])/1e9:.2f} GB")' "$FINAL")

say ''
say '========================================='
say 'ГОТОВО'
say "Файл: $HOME/Documents/$FINAL"
say "Видео: ${W}x${H} H.264"
say 'Аудио: AAC'
say "Размер: $SIZE"
say "SHA-256: $SHA"
say '========================================='
