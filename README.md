# Travel Surprise

Um álbum digital para acompanhar uma viagem em casal — elegante, emocional e offline-first.

## Visão Geral

| Aba | Função |
|-----|--------|
| **Checklist** | Lista editável de itens da viagem com categorias e progresso |
| **Timeline** | Linha do tempo interativa com fotos, emojis e músicas |
| **Financeiro** | Dashboard com saldo, gastos por categoria e gráficos |

---

## Pré-requisitos do Host

- **Docker** ≥ 24
- **Docker Compose** ≥ 2.20
- **adb** instalado no host (para acesso ao dispositivo Android físico)
- Dispositivo Android com **Depuração USB** habilitada *(opcional — para run no device)*

> Nada mais é instalado no host — toda a stack roda em containers.

---

## Primeiros Passos

### 1. Construir a imagem Docker

```bash
make build
```

> A primeira build leva ~10 min (baixa Flutter stable + Android SDK 34).

### 2. Inicializar o projeto Flutter

```bash
make init
```

Cria os arquivos nativos Android/iOS/**Web** (gerado por `flutter create`).
Execute **uma única vez** após o clone.

> Se você já rodou `make init` antes desta atualização (sem web), execute:
> ```bash
> make web-init
> ```

### 3. Instalar dependências Dart

```bash
make setup
```

### 4. Conectar o dispositivo Android

Conecte via USB e habilite Depuração USB. Verifique:

```bash
make devices
# ou:
adb devices
```

### 5. Rodar no dispositivo Android

```bash
make run
```

### 5b. Rodar no navegador (Web Preview)

```bash
make web
```

Depois acesse: **http://localhost:8080**

---

## Preview Web

### Como funciona

O Flutter roda como um servidor web dentro do container Docker. Como o container usa `network_mode: host`, a porta 8080 do container **é** a porta 8080 do host — sem mapeamento necessário.

```
Container (flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080)
    │
    └── network_mode: host
    │
Host: http://localhost:8080  ←  Navegador
```

### Iniciar o preview

```bash
make web
```

Abre o servidor em `http://localhost:8080` com hot reload ativo.

### Atalhos no terminal

| Tecla | Ação |
|-------|------|
| `r` | Hot reload (preserva estado) |
| `R` | Hot restart (reinicia app) |
| `q` | Encerrar servidor |

### Device Preview

O app usa o pacote `device_preview` — **ativo apenas em `web + debug`**.

No navegador você verá um painel lateral para simular diferentes dispositivos:

- iPhone 15 Pro
- Pixel 7
- iPad Pro
- Samsung Galaxy S24
- e dezenas de outros modelos

O frame simulado mostra como o app fica em diferentes resoluções e densidades de pixel.

> Em Android físico (`make run`), o device_preview está **desativado** — nenhum overhead.

### Build de produção

Para gerar um bundle estático (HTML/JS/CSS):

```bash
make web-release
# Output em: app/build/web/
```

---

## Comandos Disponíveis

```bash
make help         # Lista todos os comandos
make build        # Constrói a imagem Docker
make init         # Inicializa projeto Flutter (uma vez)
make web-init     # Adiciona plataforma web a projeto já inicializado
make setup        # Instala dependências (build + pub get)
make run          # Executa no dispositivo Android conectado
make run-debug    # Executa com output verbose
make web          # Abre Flutter Web em http://localhost:8080
make web-release  # Gera bundle web estático
make test         # Roda os testes
make analyze      # Análise estática
make apk          # Gera APK de release
make apk-debug    # Gera APK de debug
make generate     # Gera código (freezed + json_serializable)
make format       # Formata o código Dart
make shell        # Abre shell no container
make clean        # Limpa artefatos de build
make devices      # Lista dispositivos Android conectados
```

---

## Estrutura do Projeto

```
travel-router/
├── docker/
│   └── flutter/
│       └── Dockerfile          # Imagem Ubuntu + JDK 17 + Flutter stable + Android SDK 34
├── docker-compose.yml          # Serviço flutter com network_mode: host
├── Makefile                    # Comandos simplificados
├── funtional-requriments.md    # Requisitos originais
└── app/
    ├── pubspec.yaml
    ├── assets/
    │   ├── data/
    │   │   ├── timeline.json   # 8 eventos de exemplo
    │   │   ├── checklist.json  # 30 itens pré-configurados
    │   │   └── finance.json    # Orçamento e gastos iniciais
    │   ├── photos/             # Fotos (adicionar manualmente)
    │   └── animations/         # Animações Lottie/Rive
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── theme/          # Cores + tema Material 3
        │   ├── router/         # go_router com StatefulShellRoute
        │   └── constants/      # Constantes da app
        ├── shared/
        │   └── widgets/        # MainScaffold, EmptyState
        └── features/
            ├── timeline/       # Linha do tempo
            ├── checklist/      # Lista de itens
            └── finance/        # Controle financeiro
```

---

## Arquitetura

### Stack

| Camada | Tecnologia |
|--------|-----------|
| UI | Flutter / Material 3 |
| Estado | Riverpod (`AsyncNotifierProvider`) |
| Navegação | go_router (`StatefulShellRoute`) |
| Persistência | Hive (JSON serializado) |
| Gráficos | fl_chart |
| PDF | pdf + printing |
| Fontes | google_fonts (Playfair Display + Nunito) |

### Fluxo de Dados

```
Assets JSON  →  Hive (seed na 1ª execução)
                ↓
          Repository
                ↓
    AsyncNotifierProvider (Riverpod)
                ↓
            UI / Screens
```

Os dados são **seeded** automaticamente dos arquivos JSON de assets no primeiro boot.
Toda edição subsequente é persistida no Hive (local, offline).

### Padrão de Repositório

Cada feature segue a mesma estrutura:

```
feature/
├── models/           # Data classes com fromJson/toJson
├── repositories/     # Acesso ao Hive + seed dos assets
├── providers/        # AsyncNotifierProvider (Riverpod)
└── views/            # Screens + Widgets
```

---

## Personalização Visual

O tema é definido em `lib/core/theme/`:

| Arquivo | Conteúdo |
|---------|---------|
| `app_colors.dart` | Toda a palette de cores |
| `app_theme.dart` | ThemeData com tipografia e componentes |

**Palette principal:**
- Background: `#FDF8F3` (creme quente)
- Primary: `#C8956C` (terracota)
- Secondary: `#8B4E6B` (ameixa)
- Gold: `#D4AF6E`

---

## Adicionando Fotos

Adicione imagens à pasta `app/assets/photos/` e referencie nos eventos da timeline:

```json
{
  "photos": [
    { "url": "assets/photos/jantar.jpg", "emojiOverlay": "❤️", "caption": "Primeira noite" }
  ]
}
```

---

## Como o ADB funciona no Docker

O container usa `network_mode: host`, portanto compartilha o stack de rede do host Linux.
O `adb` do container se conecta ao servidor ADB que roda no host na porta `5037`.

```bash
# Host — inicia o servidor ADB (automático ao rodar 'make run')
adb start-server

# Container — vê os mesmos dispositivos
adb devices
```

---

## Geração de Código (Opcional)

O projeto inclui `freezed` e `json_serializable` configurados, mas os modelos V1
são escritos manualmente para funcionar sem build_runner.

Para migrar para freezed e usar `@freezed`:

```bash
make generate
```

---

## Roadmap V2

- [ ] Sincronização cloud (Firebase / Supabase)
- [ ] Múltiplas viagens
- [ ] Câmera / Galeria para fotos
- [ ] Mapa integrado (MapBox offline)
- [ ] QR Codes de desbloqueio de eventos surpresa
- [ ] Geração automática de vídeo
- [ ] Compartilhamento em tempo real (casal)
- [ ] Integração com calendário
- [ ] Exportação completa do álbum com fotos em PDF

---

## Problemas Comuns

**`flutter run` não encontra dispositivo**
```bash
adb start-server && adb devices
# O dispositivo deve aparecer antes de rodar o app
```

**Permissão negada nos volumes**
```bash
# O Makefile já passa UID/GID automaticamente
# Se precisar forçar:
UID=$(id -u) GID=$(id -g) docker compose build
```

**Android license não aceita**
```bash
make shell
# Dentro do container:
yes | sdkmanager --licenses
```

**Cmdline-tools URL expirada**
Atualize `CMDLINE_TOOLS_VERSION` no `docker/flutter/Dockerfile`.
Consulte: https://developer.android.com/studio#command-tools
