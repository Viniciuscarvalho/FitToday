# Session Context

## User Prompts

### Prompt 1

Verifique a issue https://github.com/Viniciuscarvalho/FitToday/issues/26 e detalhe ao máximo para a criação das tasks para execução dessa task de maneira correta e que escale. /feature-marker —interactive -prd-chat-ai-creator

### Prompt 2

Base directory for this skill: /Users/viniciuscarvalho/.claude/skills/feature-marker

# feature-marker

Automates feature development with a 5-phase workflow:

1. **Inputs Gate** - Validates `prd.md`, `techspec.md`, `tasks.md` exist; generates them via `~/.claude/commands/` if missing.
2. **Analysis & Planning** - Auto-installs product-manager skill if missing; reads docs, creates implementation plan.
3. **Implementation** - Executes tasks with progress tracking.
4. **Tests & Validation** - Runs...

