#!/bin/bash
# ============================================================================
# iOS Deploy Script (xcodebuild + asc)
#
# Comandos:
# ./deploy.sh release    [--skip-tests] [--skip-build] [--ipa <path>] [--dry-run]
# ./deploy.sh build      [--skip-tests]
# ./deploy.sh testflight [--skip-tests] [--skip-build] [--ipa <path>] [--dry-run]
# ./deploy.sh appstore   [--skip-tests] [--skip-build] [--ipa <path>] [--dry-run]
#
# Configuração via .env (veja show_help para todas as variáveis)
# ============================================================================
set -euo pipefail

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

# IMPORTANTE: todos os logs vão para stderr.
# Isso garante que $(build_ipa) capture APENAS o caminho do IPA (stdout),
# sem misturar mensagens de log no valor da variável.
log_info()    { echo -e "${BLUE}ℹ️  $1${NC}" >&2; }
log_success() { echo -e "${GREEN}✅ $1${NC}" >&2; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}" >&2; }
log_error()   { echo -e "${RED}❌ $1${NC}" >&2; }
log_step() {
  echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo -e "${GREEN}▶ $1${NC}" >&2
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n" >&2
}

# ============================================================================
# CONFIG — sobrescreva via .env / variáveis de ambiente
# ============================================================================
PROJECT_NAME="${PROJECT_NAME:-MyApp}"
BUNDLE_ID="${BUNDLE_ID:-}"
SCHEME="${SCHEME:-${PROJECT_NAME}}"
WORKSPACE_PATH="${WORKSPACE_PATH:-}"   # preferido quando definido (.xcworkspace)
PROJECT_PATH="${PROJECT_PATH:-./}"     # fallback (.xcodeproj)

CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-./build}"
IPA_DIR="${IPA_DIR:-${BUILD_DIR}/ipa}"

ARCHIVE_PATH="${ARCHIVE_PATH:-${BUILD_DIR}/${SCHEME}.xcarchive}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-./ExportOptions-AppStore.plist}"

BETA_GROUP="${BETA_GROUP:-Beta Testers}"
ASC_APP_ID="${ASC_APP_ID:-}"

ASC_UPLOAD_TIMEOUT_SECONDS="${ASC_UPLOAD_TIMEOUT_SECONDS:-900}"
export ASC_UPLOAD_TIMEOUT_SECONDS

# Array com -workspace/-project + -scheme, inicializado em init_xcode_target_args
# após load_env (quando as variáveis já têm valor final).
XCODE_TARGET_ARGS=()

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

# Monta XCODE_TARGET_ARGS após load_env.
# Suporta .xcworkspace (WORKSPACE_PATH) e .xcodeproj (PROJECT_PATH).
init_xcode_target_args() {
  if [[ -n "$WORKSPACE_PATH" && -e "$WORKSPACE_PATH" ]]; then
    XCODE_TARGET_ARGS=(-workspace "$WORKSPACE_PATH" -scheme "$SCHEME")
    log_info "Alvo: workspace $WORKSPACE_PATH"
  else
    XCODE_TARGET_ARGS=(-project "$PROJECT_PATH" -scheme "$SCHEME")
    log_info "Alvo: projeto $PROJECT_PATH"
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
    echo "  brew tap rudrankriyam/tap" >&2
    echo "  brew install rudrankriyam/tap/asc" >&2
    exit 1
  }
  log_success "asc: $(asc --version 2>/dev/null || echo "ok")"

  if [[ -n "$WORKSPACE_PATH" ]]; then
    [[ -e "$WORKSPACE_PATH" ]] || { log_error "WORKSPACE_PATH não existe: $WORKSPACE_PATH"; exit 1; }
    log_success "Workspace: $WORKSPACE_PATH"
  else
    [[ -d "$PROJECT_PATH" ]] || { log_error "PROJECT_PATH não existe: $PROJECT_PATH"; exit 1; }
    log_success "Projeto: $PROJECT_PATH"
  fi

  [[ -f "$EXPORT_OPTIONS_PLIST" ]] || {
    log_error "ExportOptions.plist não encontrado: $EXPORT_OPTIONS_PLIST"
    log_info "Crie o arquivo com method=app-store-connect."
    exit 1
  }
  log_success "ExportOptions: $EXPORT_OPTIONS_PLIST"
}

# ============================================================================
# RESOLVE ASC APP ID
# ============================================================================
resolve_asc_app_id() {
  if [[ -n "${ASC_APP_ID:-}" ]]; then
    log_info "ASC_APP_ID já definido: $ASC_APP_ID (pulando auto-resolve)"
    return 0
  fi

  log_step "Resolvendo ASC_APP_ID automaticamente (bundleId/nome)"

  local result_json
  result_json="$(asc apps --output json 2>/dev/null || true)"

  if [[ -z "$result_json" ]]; then
    log_error "Falha ao listar apps via asc. Verifique autenticação."
    log_info "Teste: asc apps --output table"
    exit 1
  fi

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

candidates = []
if bundle_id:
    for it in data:
        if attr(it, "bundleId") == bundle_id:
            candidates.append(it)
if not candidates and name:
    for it in data:
        if attr(it, "name") == name:
            candidates.append(it)

if candidates:
    print("CANDIDATES_START")
    for it in candidates:
        print(f'{it.get("id","")}\t{attr(it,"name") or ""}\t{attr(it,"bundleId") or ""}')
    print("CANDIDATES_END")

if not candidates:
    sys.exit(2)
if len(candidates) != 1:
    sys.exit(3)

print("RESOLVED_ID=" + (candidates[0].get("id") or ""))
PY
  )" || true

  if [[ -z "${resolved:-}" ]]; then
    log_error "Não encontrei app por bundleId='$BUNDLE_ID' nem por nome='$PROJECT_NAME'."
    log_info "Rode: asc apps --output table (e confirme name/bundleId)"
    exit 1
  fi

  if echo "$resolved" | grep -q "CANDIDATES_START"; then
    log_info "Apps candidatos encontrados:"
    echo "  ID\tNAME\tBUNDLE_ID" >&2
    echo "$resolved" | sed -n '/CANDIDATES_START/,/CANDIDATES_END/p' \
      | sed '1d;$d' \
      | while IFS=$'\t' read -r id nm bid; do
          echo "  ${id}\t${nm}\t${bid}" >&2
        done
  fi

  if ! echo "$resolved" | grep -q "^RESOLVED_ID="; then
    log_error "Mais de um app correspondeu ao filtro (bundleId/nome)."
    log_info "Defina ASC_APP_ID manualmente no .env para evitar subir no app errado."
    exit 1
  fi

  ASC_APP_ID="$(echo "$resolved" | sed -n 's/^RESOLVED_ID=//p')"
  [[ -n "$ASC_APP_ID" ]] || { log_error "Falha ao extrair RESOLVED_ID."; exit 1; }
  export ASC_APP_ID
  log_success "ASC_APP_ID resolvido: $ASC_APP_ID"
}

# ============================================================================
# TESTES
# ============================================================================
run_tests() {
  log_step "Executando testes"
  local sim_destination="platform=iOS Simulator,OS=latest,name=iPhone 16 Pro"
  # Timestamp no path evita colisão com resultBundlePath de runs anteriores
  local result_path="${BUILD_DIR}/test-results-$(date +%s)"
  mkdir -p "$BUILD_DIR"

  if command -v xcpretty >/dev/null; then
    xcodebuild test \
      "${XCODE_TARGET_ARGS[@]}" \
      -destination "$sim_destination" \
      -resultBundlePath "$result_path" \
      | xcpretty || true
  else
    xcodebuild test \
      "${XCODE_TARGET_ARGS[@]}" \
      -destination "$sim_destination" \
      -resultBundlePath "$result_path" \
      || true
  fi

  log_success "Testes concluídos."
}

# ============================================================================
# BUILD (archive + export IPA local)
#
# Se o ExportOptions tiver destination=upload (xcodebuild faz o upload direto),
# criamos um plist temporário com destination=export + uploadSymbols=false para:
#   1. Gerar o IPA localmente (necessário para o asc controlar o upload)
#   2. Evitar erros de dSYM de frameworks de terceiros (ex: Firebase) que
#      retornam exit code 1 mesmo quando o upload principal foi bem-sucedido
#
# Apenas o caminho do IPA é escrito em stdout; todo o resto vai para stderr.
# Isso permite capturar o caminho com: ipa_path=$(build_ipa)
# ============================================================================
build_ipa() {
  log_step "Build (xcodebuild archive)"
  mkdir -p "$BUILD_DIR" "$IPA_DIR"

  xcodebuild \
    "${XCODE_TARGET_ARGS[@]}" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    archive

  log_step "Export IPA (xcodebuild -exportArchive)"
  rm -rf "$IPA_DIR"
  mkdir -p "$IPA_DIR"

  # Detecta destination do ExportOptions plist
  local export_destination
  export_destination="$(/usr/libexec/PlistBuddy -c "Print :destination" "$EXPORT_OPTIONS_PLIST" 2>/dev/null || echo "export")"

  local export_plist="$EXPORT_OPTIONS_PLIST"
  local tmp_plist=""

  # destination=upload: xcodebuild faria upload direto, sem gerar IPA local.
  # Criamos plist temporário com export local para deixar o asc fazer o upload.
  if [[ "$export_destination" == "upload" ]]; then
    tmp_plist="${BUILD_DIR}/ExportOptions-local-$$.plist"
    cp "$EXPORT_OPTIONS_PLIST" "$tmp_plist"
    /usr/libexec/PlistBuddy -c "Set :destination export" "$tmp_plist"
    /usr/libexec/PlistBuddy -c "Set :uploadSymbols false" "$tmp_plist" 2>/dev/null \
      || /usr/libexec/PlistBuddy -c "Add :uploadSymbols bool false" "$tmp_plist" 2>/dev/null \
      || true
    export_plist="$tmp_plist"
    log_info "destination:upload detectado → exportando localmente para upload via asc"
  fi

  local export_exit_code=0
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$IPA_DIR" \
    -exportOptionsPlist "$export_plist" || export_exit_code=$?

  [[ -n "$tmp_plist" ]] && rm -f "$tmp_plist"

  if [[ $export_exit_code -ne 0 ]]; then
    log_error "xcodebuild -exportArchive falhou (exit $export_exit_code)"
    exit 1
  fi

  local ipa_path
  ipa_path="$(find "$IPA_DIR" -maxdepth 2 -name "*.ipa" | head -1 || true)"
  [[ -n "$ipa_path" ]] || { log_error "IPA não encontrado em $IPA_DIR"; exit 1; }

  log_success "IPA gerado: $ipa_path"
  echo "$ipa_path"  # única saída em stdout — capturada por ipa_path=$(build_ipa)
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
cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
iOS Deploy Script (xcodebuild + asc) — ${PROJECT_NAME}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

COMANDOS:
  release     Build + TestFlight + App Store submit
  build       Apenas gera o IPA (sem upload)
  testflight  Build + TestFlight (upload + distribute + wait)
  appstore    Build + App Store submit (upload + submit + wait)

OPÇÕES:
  --skip-tests   Pula testes
  --skip-build   Pula build (usa IPA existente via --ipa)
  --ipa <path>   Caminho do IPA (exigido com --skip-build)
  --dry-run      Passa --dry-run para asc (simulação)
  -h, --help     Ajuda

CONFIGURAÇÃO (.env ou variáveis de ambiente):
  PROJECT_NAME          Nome do app
  BUNDLE_ID             Bundle identifier (para auto-resolve do ASC_APP_ID)
  SCHEME                Nome do scheme Xcode
  WORKSPACE_PATH        Caminho do .xcworkspace (preferido sobre PROJECT_PATH)
  PROJECT_PATH          Caminho do .xcodeproj (fallback)
  EXPORT_OPTIONS_PLIST  Caminho do ExportOptions plist (padrão: ./ExportOptions-AppStore.plist)
  CONFIGURATION         Configuração Xcode (padrão: Release)
  BETA_GROUP            Grupo TestFlight (padrão: "Beta Testers")
  ASC_APP_ID            App ID numérico do App Store Connect (auto-resolve via bundleId/nome)

  Auth do asc via:
    ASC_KEY_ID + ASC_ISSUER_ID + ASC_PRIVATE_KEY_PATH
    ou: asc auth login

NOTA — destination=upload no ExportOptions:
  O script detecta automaticamente e cria um export local temporário.
  O upload é sempre feito pelo asc (TestFlight e App Store).

EXEMPLOS:
  ./deploy.sh release
  ./deploy.sh release --skip-tests
  ./deploy.sh testflight --dry-run
  ./deploy.sh appstore --skip-build --ipa ./build/ipa/MyApp.ipa
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
      --ipa)        ipa_override="${2:-}"; shift 2 ;;
      --dry-run)    dry_run=true; shift ;;
      -h|--help)    show_help; exit 0 ;;
      *)            log_warning "Opção desconhecida: $1"; shift ;;
    esac
  done

  if [[ -z "$command" ]]; then
    show_help; exit 0
  fi

  echo "" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo " 🚀 iOS Deploy — ${PROJECT_NAME}" >&2
  echo " 📦 Bundle ID:  ${BUNDLE_ID:-<não definido>}" >&2
  echo " 🎯 Comando:    $command" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  load_env
  init_xcode_target_args
  check_prerequisites
  resolve_asc_app_id

  local ipa_path=""

  # Resolve IPA: build ou usa override com --skip-build
  resolve_ipa() {
    if [[ "$skip_build" == "true" ]]; then
      [[ -n "$ipa_override" && -f "$ipa_override" ]] \
        || { log_error "Use --ipa <path> com --skip-build"; exit 1; }
      ipa_path="$ipa_override"
    else
      ipa_path="$(build_ipa)"
    fi
  }

  case "$command" in
    build)
      [[ "$skip_tests" == "true" ]] || run_tests
      build_ipa > /dev/null
      ;;

    testflight)
      [[ "$skip_tests" == "true" ]] || run_tests
      resolve_ipa
      asc_publish_testflight "$ipa_path" "$dry_run"
      ;;

    appstore)
      [[ "$skip_tests" == "true" ]] || run_tests
      resolve_ipa
      asc_publish_appstore_submit "$ipa_path" "$dry_run"
      ;;

    release)
      [[ "$skip_tests" == "true" ]] || run_tests
      resolve_ipa
      asc_publish_testflight "$ipa_path" "$dry_run"
      asc_publish_appstore_submit "$ipa_path" "$dry_run"
      ;;

    *)
      log_error "Comando desconhecido: $command"
      show_help
      exit 1
      ;;
  esac

  echo "" >&2
  log_success "🎉 Concluído!"
  echo "" >&2
}

main "$@"
