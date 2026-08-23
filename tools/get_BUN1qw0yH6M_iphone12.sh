#!/bin/sh
set -u

VIDEO='https://www.youtube.com/watch?v=BUN1qw0yH6M'
YTDLP="$HOME/Documents/bin/yt-dlp"
QJS="$HOME/Documents/bin/qjs"
OUT='BUN1qw0yH6M-1080p-iPhone12.%(ext)s'

say(){ printf '%s\n' "$*"; }
fail(){ say ""; say "ОШИБКА: $*"; exit 1; }

cd "$HOME/Documents" 2>/dev/null || fail 'не могу открыть ~/Documents.'
command -v curl >/dev/null 2>&1 || fail 'в a-Shell нет curl.'
command -v python3 >/dev/null 2>&1 || fail 'в a-Shell нет python3.'
command -v ffmpeg >/dev/null 2>&1 || fail 'в a-Shell нет ffmpeg.'
command -v ffprobe >/dev/null 2>&1 || fail 'в a-Shell нет ffprobe.'
mkdir -p "$HOME/Documents/bin" || fail 'не удалось создать ~/Documents/bin.'

say '1/4 Готовлю JS-движок для YouTube...'
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

say '2/4 Обновляю yt-dlp с официального GitHub...'
TMP="$YTDLP.tmp"
rm -f "$TMP"
if ! curl -4 -fL --connect-timeout 8 --max-time 60 --retry 2 --retry-delay 2 --progress-bar 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp' -o "$TMP"; then
  rm -f "$TMP"
  fail 'не удалось скачать yt-dlp с GitHub.'
fi
python3 "$TMP" --version >/dev/null 2>&1 || { rm -f "$TMP"; fail 'скачанный yt-dlp не запускается.'; }
mv "$TMP" "$YTDLP" || fail 'не удалось сохранить yt-dlp.'

say '3/4 Быстро проверяю YouTube по IPv4. Видео пока НЕ скачивается...'
if ! python3 "$YTDLP" --force-ipv4 --js-runtimes "quickjs:$QJS" --remote-components ejs:github --no-playlist -t mp4 --simulate --socket-timeout 8 --extractor-retries 1 --retries 1 --retry-sleep extractor:1 "$VIDEO"; then
  fail 'YouTube не ответил за короткий срок или не отдал подходящий формат. Большая загрузка НЕ начата.'
fi

say '4/4 Начинаю большую загрузку 1080p. a-Shell лучше не сворачивать.'
python3 "$YTDLP" --force-ipv4 --js-runtimes "quickjs:$QJS" --remote-components ejs:github --no-playlist -t mp4 --continue --retries infinite --fragment-retries infinite --retry-sleep 3 --concurrent-fragments 1 --newline --progress --socket-timeout 15 -o "$OUT" "$VIDEO" || fail 'yt-dlp завершился ошибкой.'

FINAL=$(ls -t BUN1qw0yH6M-1080p-iPhone12*.mp4 2>/dev/null | head -n 1)
[ -n "${FINAL:-}" ] || fail 'итоговый MP4 не найден.'

V=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$FINAL" 2>/dev/null | head -n 1)
A=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$FINAL" 2>/dev/null | head -n 1)
W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$FINAL" 2>/dev/null | head -n 1)
H=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$FINAL" 2>/dev/null | head -n 1)
D=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$FINAL" 2>/dev/null | head -n 1)

[ "$V" = h264 ] || fail "получен не H.264: ${V:-?}."
[ "$A" = aac ] || fail "получен не AAC: ${A:-?}."
[ "${W:-0}" -ge 1900 ] 2>/dev/null || fail "получилось меньше 1080p: ${W:-?}x${H:-?}."
[ "${H:-0}" -ge 1080 ] 2>/dev/null || fail "получилось меньше 1080p: ${W:-?}x${H:-?}."
python3 -c 'import sys; d=float(sys.argv[1]); raise SystemExit(0 if d>4400 else 1)' "$D" 2>/dev/null || fail 'ролик выглядит обрезанным.'

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
