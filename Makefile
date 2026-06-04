.PHONY: help build init web-init setup run run-debug web web-release \
        test analyze apk apk-debug generate clean shell \
        pub-get pub-upgrade devices format

# Pass host UID/GID into Docker so volume files are owned by the right user
UID  := $(shell id -u)
GID  := $(shell id -g)
export UID
export GID

COMPOSE := UID=$(UID) GID=$(GID) docker compose
FLUTTER  := $(COMPOSE) run --rm flutter flutter
DART     := $(COMPOSE) run --rm flutter dart

# ─── Help ─────────────────────────────────────────────────────────────────────

help: ## Show available commands
	@printf "\n  \033[1mTravel Surprise — Dev Commands\033[0m\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ─── Setup ────────────────────────────────────────────────────────────────────

build: ## Build the Docker image
	$(COMPOSE) build

init: ## Initialize Flutter project structure (run once, after `make build`)
	$(FLUTTER) create . \
		--project-name travel_surprise \
		--org com.travelsurprise \
		--platforms android,ios,web
	@echo ""
	@echo "  Flutter project initialized."
	@echo "  Next: make setup"

web-init: ## Add web platform to an existing project (if init ran without web)
	$(FLUTTER) create . --platforms web
	@echo ""
	@echo "  Web platform added. Run: make pub-get"

setup: build ## Build image and install Dart dependencies
	$(FLUTTER) pub get
	@echo ""
	@echo "  Setup complete. Connect your Android device and run: make run"

# ─── Development ──────────────────────────────────────────────────────────────

run: ## Run app on connected Android device (hot-reload enabled)
	@adb start-server
	$(FLUTTER) run

run-debug: ## Run app with verbose output
	@adb start-server
	$(FLUTTER) run --verbose

web: ## Run Flutter Web preview with hot reload — open http://localhost:8080
	@echo ""
	@printf "  \033[1;36m✦ Flutter Web Preview\033[0m\n"
	@printf "  Open your browser at \033[1;32mhttp://localhost:8080\033[0m\n"
	@printf "  Press \033[1mr\033[0m = hot reload  |  \033[1mR\033[0m = hot restart  |  \033[1mq\033[0m = quit\n\n"
	$(COMPOSE) run --rm flutter flutter run \
		-d web-server \
		--web-hostname 0.0.0.0 \
		--web-port 8080

web-release: ## Build Flutter Web as a static bundle (output: app/build/web/)
	$(FLUTTER) build web --release
	@echo ""
	@echo "  Web build complete: app/build/web/"
	@echo "  Serve with: npx serve app/build/web"

shell: ## Open an interactive shell inside the container
	$(COMPOSE) run --rm flutter /bin/bash

devices: ## List connected Android devices visible to adb
	@adb devices

# ─── Code Quality ─────────────────────────────────────────────────────────────

test: ## Run all tests
	$(FLUTTER) test

analyze: ## Run static analysis
	$(FLUTTER) analyze

format: ## Format all Dart source files
	$(DART) format lib/

# ─── Build ────────────────────────────────────────────────────────────────────

apk: ## Build release APK (output: build/app/outputs/flutter-apk/)
	$(FLUTTER) build apk --release

apk-debug: ## Build debug APK
	$(FLUTTER) build apk --debug

# ─── Dependencies ─────────────────────────────────────────────────────────────

pub-get: ## Fetch Dart dependencies
	$(FLUTTER) pub get

pub-upgrade: ## Upgrade Dart dependencies
	$(FLUTTER) pub upgrade

generate: ## Run code-generation (freezed + json_serializable)
	$(FLUTTER) pub run build_runner build --delete-conflicting-outputs

# ─── Maintenance ──────────────────────────────────────────────────────────────

clean: ## Clean Flutter build artefacts
	$(FLUTTER) clean
