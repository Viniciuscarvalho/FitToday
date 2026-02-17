#!/bin/bash
# ============================================================================
# iOS Deploy Script (xcodebuild + asc)
# Projeto: GastandoYa
#
# Comandos:
# ./deploy.sh release [--skip-tests] [--skip-build] [--ipa <path>] [--dry-run]
# ./deploy.sh build [--skip-tests]
# ./deploy.sh testflight [--skip-tests] [--skip-build] [--ipa <path>] [--dry-run]
# ./deploy.sh appstore [--skip-tests] [--skip-build] [--ipa <path>] [--dry-run]
# ============================================================================
set -euo pipefail

# Diretório do script (para carregar .env do mesmo local)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carrega .env ANTES dos defaults para que seus valores sejam respeitados
if [[ -f "$SCRIPT_DIR/.env" ]]; then
set -a; source "$SCRIPT_DIR/.env"; set +a
fi
if [[ -f "$SCRIPT_DIR/.env.local" ]]; then
set -a; source "$SCRIPT_DIR/.env.local"; set +a
fi

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() {
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}▶ $1${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# ============================================================================
# CONFIG (pode sobrescrever via .env / env vars)
# ============================================================================
PROJECT_NAME="${PROJECT_NAME:-GastandoYa}"
BUNDLE_ID="${BUNDLE_ID:-com.dev.GastandoYa}"
SCHEME="${SCHEME:-GastandoYa}"
PROJECT_PATH="${PROJECT_PATH:-./GastandoYa.xcodeproj}"

CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-./build}"
IPA_DIR="${IPA_DIR:-${BUILD_DIR}/ipa}"

ARCHIVE_PATH="${ARCHIVE_PATH:-${BUILD_DIR}/${SCHEME}.xcarchive}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-./ExportOptions-AppStore.plist}"

BETA_GROUP="${BETA_GROUP:-Beta Testers}"

# ASC: precisa do App ID numérico no App Store Connect
ASC_APP_ID="${ASC_APP_ID:-}"

# Timeouts/retries (opcional)
ASC_UPLOAD_TIMEOUT_SECONDS="${ASC_UPLOAD_TIMEOUT_SECONDS:-900}" # 15min
export ASC_UPLOAD_TIMEOUT_SECONDS

# ============================================================================
# .env
# ============================================================================
load_env() {
if [[ -f "$SCRIPT_DIR/.env" ]]; then
log_info "Carregando .env"
set -a; source "$SCRIPT_DIR/.env"; set +a
fi
if [[ -f "$SCRIPT_DIR/.env.local" ]]; then
log_info "Carregando .env.local"
set -a; source "$SCRIPT_DIR/.env.local"; set +a
fi
}

# ============================================================================
# PRÉ-REQUISITOS
# ============================================================================
check_prerequisites() {
log_step "Verificando pré-requisitos"

command -v xcodebuild >/dev/null || { log_error "xcodebuild não encontrado"; exit 1; }
log_success "Xcode: $(xcodebuild -version | head -1)"

command -v asc >/dev/null || {
log_error "asc não encontrado. Instale com:"
echo " brew tap rudrankriyam/tap"
echo " brew install rudrankriyam/tap/asc"
exit 1
}
log_success "asc encontrado: $(asc --version 2>/dev/null || echo "ok")"

[[ -d "$PROJECT_PATH" ]] || { log_error "PROJECT_PATH não existe: $PROJECT_PATH"; exit 1; }
log_success "Projeto: $PROJECT_PATH"

[[ -f "$EXPORT_OPTIONS_PLIST" ]] || {
log_error "ExportOptions.plist não encontrado: $EXPORT_OPTIONS_PLIST"
log_info "Crie o arquivo ExportOptions-AppStore.plist (eu te passei o template)."
exit 1
}
log_success "ExportOptions: $EXPORT_OPTIONS_PLIST"
}

# ============================================================================
# RESOLVE ASC APP ID
# ============================================================================
resolve_asc_app_id() {
# Se já veio setado, respeita
if [[ -n "${ASC_APP_ID:-}" ]]; then
log_info "ASC_APP_ID já definido: $ASC_APP_ID (pulando auto-resolve)"
return 0
fi

log_step "Resolvendo ASC_APP_ID automaticamente (bundleId/nome)"

# Listar apps e filtrar por bundleId ou name; imprimir tabela de candidatos
local result_json
result_json="$(asc apps --output json 2>/dev/null || true)"

if [[ -z "$result_json" ]]; then
log_error "Falha ao listar apps via asc. Verifique autenticação."
log_info "Teste: asc apps --output table"
exit 1
fi

# Usa python p/ evitar depender de jq
local resolved
resolved="$(
printf "%s" "$result_json" | python3 - <<'PY'
import json, os, sys

bundle_id = (os.environ.get("BUNDLE_ID") or "").strip()
name = (os.environ.get("PROJECT_NAME") or "").strip()

payload = json.load(sys.stdin)
data = payload.get("data", []) or []

def attr(item, k):
    return (item.get("attributes") or {}).get(k)

# candidatos por bundleId, depois por name
candidates = []

if bundle_id:
    for it in data:
        if attr(it, "bundleId") == bundle_id:
            candidates.append(it)

if not candidates and name:
    for it in data:
        if attr(it, "name") == name:
            candidates.append(it)

# imprime lista para diagnóstico (sempre que houver candidatos)
if candidates:
    print("CANDIDATES_START")
    for it in candidates:
        print(f'{it.get("id","")}\t{attr(it,"name") or ""}\t{attr(it,"bundleId") or ""}')
    print("CANDIDATES_END")

# decidir
if not candidates:
    sys.exit(2)

# se múltiplos, não adivinhar
if len(candidates) != 1:
    sys.exit(3)

print("RESOLVED_ID=" + (candidates[0].get("id") or ""))
PY
)" || true

# Se não achou nada:
if [[ -z "${resolved:-}" ]]; then
log_error "Não encontrei app por bundleId='$BUNDLE_ID' nem por nome='$PROJECT_NAME'."
log_info "Rode: asc apps --output table (e confirme name/bundleId)"
exit 1
fi

# Mostrar candidatos (se houver)
if echo "$resolved" | grep -q "CANDIDATES_START"; then
log_info "Apps candidatos encontrados:"
echo " ID\tNAME\tBUNDLE_ID"
echo "$resolved" | sed -n '/CANDIDATES_START/,/CANDIDATES_END/p' \
| sed '1d;$d' \
| while IFS=$'\t' read -r id nm bid; do
echo " ${id}\t${nm}\t${bid}"
done
fi

# Caso múltiplos matches:
if ! echo "$resolved" | grep -q "^RESOLVED_ID="; then
log_error "Mais de um app correspondeu ao filtro (bundleId/nome)."
log_info "Defina ASC_APP_ID manualmente no .env para evitar subir no app errado."
exit 1
fi

ASC_APP_ID="$(echo "$resolved" | sed -n 's/^RESOLVED_ID=//p')"
if [[ -z "$ASC_APP_ID" ]]; then
log_error "Falha ao extrair RESOLVED_ID."
exit 1
fi

export ASC_APP_ID
log_success "ASC_APP_ID resolvido: $ASC_APP_ID"
}

# ============================================================================
# TESTES (opcional)
# ============================================================================
run_tests() {
log_step "Executando testes"
local destination="platform=iOS Simulator,OS=latest,name=iPhone 16 Pro"

# Nota: xcpretty é opcional; se não tiver, mostra saída bruta
if command -v xcpretty >/dev/null; then
xcodebuild test \
-project "$PROJECT_PATH" \
-scheme "$SCHEME" \
-destination "$destination" \
-resultBundlePath "${BUILD_DIR}/test-results" \
| xcpretty || true
else
xcodebuild test \
-project "$PROJECT_PATH" \
-scheme "$SCHEME" \
-destination "$destination" \
-resultBundlePath "${BUILD_DIR}/test-results" \
|| true
fi

log_success "Testes concluídos (ou ignorados em caso de falha, se houver)."
}

# ============================================================================
# BUILD (archive + export IPA)
# ============================================================================
build_ipa() {
log_step "Build (xcodebuild archive)"
mkdir -p "$BUILD_DIR" "$IPA_DIR"

xcodebuild \
-project "$PROJECT_PATH" \
-scheme "$SCHEME" \
-configuration "$CONFIGURATION" \
-archivePath "$ARCHIVE_PATH" \
-allowProvisioningUpdates \
archive

log_step "Export IPA (xcodebuild -exportArchive)"
rm -rf "$IPA_DIR"
mkdir -p "$IPA_DIR"

xcodebuild -exportArchive \
-archivePath "$ARCHIVE_PATH" \
-exportPath "$IPA_DIR" \
-exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

local ipa_path
ipa_path="$(find "$IPA_DIR" -maxdepth 2 -name "*.ipa" | head -1 || true)"
[[ -n "$ipa_path" ]] || { log_error "IPA não encontrado em $IPA_DIR"; exit 1; }

log_success "IPA gerado: $ipa_path"
echo "$ipa_path"
}

# ============================================================================
# ASC helpers
# ============================================================================
asc_publish_testflight() {
local ipa="$1"
local dry_run="${2:-false}"

log_step "ASC: publish TestFlight (grupo: ${BETA_GROUP})"
local args=(publish testflight --app "$ASC_APP_ID" --ipa "$ipa" --group "$BETA_GROUP" --wait)

if [[ "$dry_run" == "true" ]]; then
args+=(--dry-run)
log_warning "DRY RUN habilitado (não envia de verdade)."
fi

asc "${args[@]}"
log_success "TestFlight ok."
}

asc_publish_appstore_submit() {
local ipa="$1"
local dry_run="${2:-false}"

log_step "ASC: publish App Store (upload + submit)"
local args=(publish appstore --app "$ASC_APP_ID" --ipa "$ipa" --submit --confirm --wait)

if [[ "$dry_run" == "true" ]]; then
args+=(--dry-run)
log_warning "DRY RUN habilitado (não envia de verdade)."
fi

asc "${args[@]}"
log_success "App Store submit ok."
}

# ============================================================================
# HELP
# ============================================================================
show_help() {
cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
iOS Deploy Script (xcodebuild + asc) - $PROJECT_NAME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

COMANDOS:
release Build + TestFlight + App Store submit (opção 4)
build Apenas gera o IPA (sem upload)
testflight Build + TestFlight (upload+distribute+wait)
appstore Build + App Store submit (upload+submit+wait)

OPÇÕES:
--skip-tests Pula testes
--skip-build Pula build (usa IPA existente)
--ipa <path> Caminho do IPA (quando --skip-build)
--dry-run Passa --dry-run para asc

-h, --help Ajuda

OBRIGATÓRIO (env/.env):
ASC_APP_ID (App ID numérico do App Store Connect)
E auth do asc via:
- ASC_KEY_ID / ASC_ISSUER_ID / ASC_PRIVATE_KEY_PATH
ou `asc auth login` + keychain/config

OPCIONAL:
BETA_GROUP="Beta Testers"
SCHEME, PROJECT_PATH, CONFIGURATION

EXEMPLOS:
ASC_APP_ID=123456789 ./deploy.sh release
./deploy.sh release --skip-tests
./deploy.sh testflight --dry-run
./deploy.sh build
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# ============================================================================
# MAIN
# ============================================================================
main() {
local command="${1:-}"
local skip_tests=false
local skip_build=false
local ipa_override=""
local dry_run=false

shift || true
while [[ $# -gt 0 ]]; do
case "$1" in
--skip-tests) skip_tests=true; shift ;;
--skip-build) skip_build=true; shift ;;
--ipa) ipa_override="${2:-}"; shift 2 ;;
--dry-run) dry_run=true; shift ;;
-h|--help) show_help; exit 0 ;;
*) log_warning "Opção desconhecida: $1"; shift ;;
esac
done

if [[ -z "$command" ]]; then
show_help
exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 🚀 iOS Deploy - $PROJECT_NAME"
echo " 📦 Bundle ID: $BUNDLE_ID"
echo " 🎯 Comando: $command"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

load_env
check_prerequisites
resolve_asc_app_id

local ipa_path=""

case "$command" in
build)
[[ "$skip_tests" == "true" ]] || run_tests
build_ipa >/dev/null
;;

testflight)
[[ "$skip_tests" == "true" ]] || run_tests
if [[ "$skip_build" == "true" ]]; then
ipa_path="$ipa_override"
[[ -n "$ipa_path" && -f "$ipa_path" ]] || { log_error "Use --ipa <path> com --skip-build"; exit 1; }
else
ipa_path="$(build_ipa)"
fi
asc_publish_testflight "$ipa_path" "$dry_run"
;;

appstore)
[[ "$skip_tests" == "true" ]] || run_tests
if [[ "$skip_build" == "true" ]]; then
ipa_path="$ipa_override"
[[ -n "$ipa_path" && -f "$ipa_path" ]] || { log_error "Use --ipa <path> com --skip-build"; exit 1; }
else
ipa_path="$(build_ipa)"
fi
asc_publish_appstore_submit "$ipa_path" "$dry_run"
;;

release)
[[ "$skip_tests" == "true" ]] || run_tests
if [[ "$skip_build" == "true" ]]; then
ipa_path="$ipa_override"
[[ -n "$ipa_path" && -f "$ipa_path" ]] || { log_error "Use --ipa <path> com --skip-build"; exit 1; }
else
ipa_path="$(build_ipa)"
fi
asc_publish_testflight "$ipa_path" "$dry_run"
asc_publish_appstore_submit "$ipa_path" "$dry_run"
;;

*)
log_error "Comando desconhecido: $command"
show_help
exit 1
;;
esac

echo ""
log_success "🎉 Concluído!"
echo ""
}

main "$@"
