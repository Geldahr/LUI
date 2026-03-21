#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  build_embedded_zip_bat.sh --zip-path <zip> --bat-path <bat> --target-root <windows path>
EOF
}

zip_path=""
bat_path=""
target_root=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --zip-path)
      zip_path="${2:-}"
      shift 2
      ;;
    --bat-path)
      bat_path="${2:-}"
      shift 2
      ;;
    --target-root)
      target_root="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$zip_path" || -z "$bat_path" || -z "$target_root" ]]; then
  usage >&2
  exit 1
fi

if [[ ! -f "$zip_path" ]]; then
  echo "ZIP payload not found: $zip_path" >&2
  exit 1
fi

mkdir -p "$(dirname "$bat_path")"

stub_unix_path="${bat_path}.stub.unix"
rm -f "$bat_path" "$stub_unix_path"

cat > "$stub_unix_path" <<EOF
@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "TARGET_ROOT=$target_root"
set "TARGET_DIR=%TARGET_ROOT%\LUI"
set "TEMP_DIR=%TEMP%\LUI-bat-%RANDOM%%RANDOM%"
set "ZIP_FILE=%TEMP_DIR%\LUI.zip"
set "SELF=%~f0"
set "EXITCODE=1"

echo Installing LUI to "%TARGET_DIR%"

if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%" >nul 2>nul || goto :cleanup

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "\$lines = Get-Content -LiteralPath \$env:SELF; " ^
  "\$marker = [Array]::IndexOf(\$lines, '__PAYLOAD_BELOW__'); " ^
  "if (\$marker -lt 0) { exit 1 }; " ^
  "\$b64 = [string]::Join('', \$lines[(\$marker + 1)..(\$lines.Length - 1)]); " ^
  "[IO.File]::WriteAllBytes(\$env:ZIP_FILE, [Convert]::FromBase64String(\$b64))"
if errorlevel 1 goto :cleanup

if exist "%TARGET_DIR%" (
  rmdir /s /q "%TARGET_DIR%"
  if exist "%TARGET_DIR%" goto :cleanup
)

if not exist "%TARGET_ROOT%" mkdir "%TARGET_ROOT%" >nul 2>nul || goto :cleanup

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Expand-Archive -LiteralPath \$env:ZIP_FILE -DestinationPath \$env:TARGET_ROOT -Force"
if errorlevel 1 goto :cleanup

if not exist "%TARGET_DIR%" goto :cleanup

echo Installed LUI to "%TARGET_DIR%"
set "EXITCODE=0"

:cleanup
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" >nul 2>nul
if "%EXITCODE%"=="0" exit /b 0

echo Failed to extract LUI to "%TARGET_ROOT%".
exit /b %EXITCODE%

__PAYLOAD_BELOW__
EOF

sed 's/$/\r/' "$stub_unix_path" > "$bat_path"
base64 -w 76 "$zip_path" | sed 's/$/\r/' >> "$bat_path"

rm -f "$stub_unix_path"

echo "Built $bat_path"
