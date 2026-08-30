param([string]$DriveRoot="")
$ErrorActionPreference='Stop'

function Find-DriveRoot {
  if ($DriveRoot -and (Test-Path $DriveRoot)) { return (Resolve-Path $DriveRoot).Path }
  $candidates=@('G:\My Drive','G:\Мой диск',"$env:USERPROFILE\My Drive","$env:USERPROFILE\Google Drive\My Drive")
  foreach($p in $candidates){ if(Test-Path $p){ return (Resolve-Path $p).Path } }
  throw "Google Drive Desktop folder not found. Run: .\ff_direct_bridge.ps1 -DriveRoot 'G:\My Drive'"
}
function Mk([string]$p){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
function YUrl([string]$pub,[string]$path){
  $u='https://cloud-api.yandex.net/v1/disk/public/resources/download?public_key='+[uri]::EscapeDataString($pub)+'&path='+[uri]::EscapeDataString($path)
  (Invoke-RestMethod $u -Headers @{'User-Agent'='Mozilla/5.0'} -TimeoutSec 60).href
}
function YList([string]$pub,[string]$path){
  $all=@();$off=0
  while($true){
    $u='https://cloud-api.yandex.net/v1/disk/public/resources?public_key='+[uri]::EscapeDataString($pub)+'&path='+[uri]::EscapeDataString($path)+"&limit=1000&offset=$off"
    $o=Invoke-RestMethod $u -Headers @{'User-Agent'='Mozilla/5.0'} -TimeoutSec 60
    $b=@($o._embedded.items);$all+=$b;$off+=$b.Count
    if($b.Count -eq 0 -or $off -ge [int64]$o._embedded.total){break}
  }
  $all
}
function GetExact([string]$url,[string]$dest,[Int64]$size){
  Mk (Split-Path -Parent $dest);$tmp="$dest.partial"
  if(Test-Path $dest){ if((Get-Item $dest).Length -eq $size){Write-Host "OK $dest";return}; Rename-Item $dest "$dest.badsize" -Force }
  & curl.exe -L --fail --retry 8 --retry-delay 2 -C - -o $tmp $url
  if($LASTEXITCODE -ne 0){throw "curl failed: $dest"}
  $got=(Get-Item $tmp).Length
  if($got -ne $size){throw "size mismatch $dest expected=$size got=$got"}
  Move-Item $tmp $dest -Force;Write-Host "DONE $dest ($got bytes)"
}
function GetY([string]$pub,[string]$remote,[string]$dest,[Int64]$size){
  for($i=1;$i -le 8;$i++){try{GetExact (YUrl $pub $remote) $dest $size;return}catch{if($i -eq 8){throw};Start-Sleep (2*$i)}}
}
function MirrorY([string]$pub,[string]$remote,[string]$local){
  Mk $local
  foreach($it in (YList $pub $remote)){
    $d=Join-Path $local $it.name
    if($it.type -eq 'dir'){MirrorY $pub $it.path $d}else{GetY $pub $it.path $d ([int64]$it.size)}
  }
}

$root=Find-DriveRoot
$school='https://disk.yandex.ru/d/GedxLT7sVZldWw'
$june='https://disk.yandex.ru/d/W4ZzS8wAMv8RlA'
$schoolRoot=Join-Path $root 'школа 1259'
$files=@(
 @{p='/Выпускной готовое/выпускной клип.mp4';s=[int64]1241060815;r='Выпускной готовое\выпускной клип.mp4'},
 @{p='/Выпускной готовое/выпускной.mp4';s=[int64]11294518113;r='Выпускной готовое\выпускной.mp4'},
 @{p='/Последний звонок готовое/Последний звонок клип.mp4';s=[int64]1528082371;r='Последний звонок готовое\Последний звонок клип.mp4'},
 @{p='/Последний звонок готовое/Последний звонок.mp4';s=[int64]5053962886;r='Последний звонок готовое\Последний звонок.mp4'}
)
foreach($f in $files){GetY $school $f.p (Join-Path $schoolRoot $f.r) $f.s}

$jroot=Join-Path $root '30 июня 2026'
$wdir=Join-Path $jroot 'Wfolio — СОХО 30.06.2026 (терраса)';Mk $wdir
GetExact 'https://zip.wfolio.ru/gateway/mod_zip/disk/download/aGEgzHUhQe' (Join-Path $wdir 'СОХО 30.06.2026 (терраса).zip') ([int64]5584535044)
MirrorY $june '/' (Join-Path $jroot 'Яндекс Диск — фото')
Write-Host 'BRIDGE COMPLETE: exact source bytes written into Google Drive Desktop folder.'
