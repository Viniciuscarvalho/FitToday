# FitToday
Nunca foi tão fácil treinar e ter um treino sob medida

## OpenAI Integration Setup

Para habilitar o compositor híbrido (Local + OpenAI) no motor de treino:

1. **Configuração em `Data/Resources/OpenAIConfig.plist`**
   - `OPENAI_API_KEY`: sua API key da OpenAI
   - `OPENAI_MODEL`: modelo a usar (default: `gpt-4o-mini`)
   - `OPENAI_BASE_URL`: endpoint da API (default: `https://api.openai.com/v1/chat/completions`)
   - `OPENAI_TIMEOUT_SECONDS`: timeout em segundos (default: `20`)
   - `OPENAI_MAX_TOKENS`: máximo de tokens na resposta (default: `800`)
   - `OPENAI_TEMPERATURE`: criatividade da resposta (default: `0.2`)
   - `OPENAI_CACHE_TTL_SECONDS`: tempo de cache em segundos (default: `300`)
   
   > **Nota:** O arquivo `OpenAIConfig.plist` é separado do `Info.plist` principal para evitar conflitos de build em projetos Xcode modernos.

2. **Limites de custo**
   - O cliente usa cache em memória por `cacheTTL` para evitar chamadas duplicadas
   - Há um limitador diário (padrão 1 geração Pro/dia). Ajuste em `OpenAIUsageLimiter`
   - Apenas usuários Pro têm acesso à geração via IA

3. **Execução**
   - Caso a key não esteja configurada, o app opera 100% com o motor local determinístico
   - Falhas ou timeouts da API degradam automaticamente para o motor local e registram logs `[OpenAI]`

## Debug Mode

Em builds de desenvolvimento (`DEBUG`), você pode alternar entre usuário Free e Pro diretamente na aba Perfil:
- Acesse Perfil > Modo Debug > Ativar
- Alterne entre Pro/Free para testar diferentes fluxos

**Nota:** Esta funcionalidade é removida automaticamente em builds de Release.

## Exercícios

Os exercícios da biblioteca utilizam imagens e GIFs da [ExerciseDB API](https://github.com/ExerciseDB/exercisedb-api), uma base de dados com mais de 11.000 exercícios estruturados.
