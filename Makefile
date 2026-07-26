-include .env
export

FIREBASE_PROJECT_ID ?= app-fisio-care-2
GOOGLE_OAUTH_CLIENT_ID_WEB ?=
GOOGLE_OAUTH_CLIENT_ID_ANDROID ?=
APP_VERSION := $(shell grep '^version: ' pubspec.yaml | sed 's/version: //')

.DEFAULT_GOAL := help

.PHONY: help dev dev-android dev-web prod-web prod-android check-android-oauth maestro-test maestro-check test lint test-e2e ci-local release-dev release-prod

help: ## Lista os comandos disponíveis
	@echo "Comandos disponíveis:"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "  make %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dev: dev-android ## Alias compatível para rodar no device Android

maestro-check: ## Verifica se Maestro CLI está instalado
	@command -v maestro >/dev/null 2>&1 || command -v $(HOME)/.maestro/bin/maestro >/dev/null 2>&1 || \
		(echo "Maestro não encontrado. Instale: curl -Ls https://get.maestro.mobile.dev | bash" && exit 1)
	@maestro --version 2>/dev/null || $(HOME)/.maestro/bin/maestro --version

test: ## Roda todos os testes Flutter
	flutter test

lint: ## Roda análise estática (flutter analyze)
	flutter analyze

icones: ## Regera o ícone do app em todas as plataformas (Android, web, iOS, macOS, Windows)
	flutter test tool/gerar_icones.dart
	python3 tool/finalizar_icones.py
	@echo "Ícones regerados. Confira o diff antes de commitar."

# ---------------------------------------------------------------------------
# CI/CD — fluxo via GitHub Actions (auxiliares -> develop -> master)
# ---------------------------------------------------------------------------

ci-local: ## Roda localmente o mesmo que a CI faz (lint + testes + build web)
	flutter pub get
	flutter analyze
	flutter test --coverage
	flutter build web --release --base-href=/
	@echo "CI local OK — seguro para subir."

release-dev: ## Mescla a branch atual na develop e publica o ambiente de testes (preview)
	@BR=$$(git rev-parse --abbrev-ref HEAD); \
	echo "Mesclando '$$BR' -> develop e enviando ao GitHub..."; \
	git checkout develop && \
	git merge --no-edit $$BR && \
	git push origin develop && \
	git checkout $$BR && \
	echo "Pronto. Acompanhe o deploy em: https://github.com/lacerdaRodrigo/app-fisio2/actions"

release-prod: ## Mescla develop -> master e PUBLICA EM PRODUÇÃO (dispara deploy de produção)
	@echo "ATENÇÃO: isso publica no site OFICIAL (app-fisio-care-2.web.app)."
	@printf "Confirma? [s/N] "; read ans; [ "$$ans" = "s" ] || [ "$$ans" = "S" ] || (echo "Cancelado." && exit 1)
	@BR=$$(git rev-parse --abbrev-ref HEAD); \
	git checkout master && \
	git merge --no-edit develop && \
	git push origin master && \
	git checkout $$BR && \
	echo "Deploy de produção disparado. Acompanhe em: https://github.com/lacerdaRodrigo/app-fisio2/actions"

maestro-test: maestro-check ## Roda smoke E2E Maestro (.maestro/flows/smoke_app_abre.yaml)
	maestro test .maestro/flows/smoke_app_abre.yaml

test-e2e: ## Roda testes E2E com Patrol (Android device necessário)
	patrol test -d android

check-android-oauth: ## Verifica se google-services.json tem cliente OAuth Android
	@if grep -q '"client_type": 1' android/app/google-services.json; then \
		echo "OK: cliente OAuth Android (client_type 1) encontrado."; \
	else \
		echo "ERRO: google-services.json sem cliente OAuth Android (client_type 1)."; \
		echo "Siga documentacao/chaves.md → seção Login Android."; \
		exit 1; \
	fi

dev-android: ## Roda local no celular/device Android conectado
	flutter pub get
	flutter run \
		--dart-define=GOOGLE_OAUTH_CLIENT_ID_WEB=$(GOOGLE_OAUTH_CLIENT_ID_WEB) \
		--dart-define=GOOGLE_OAUTH_CLIENT_ID_ANDROID=$(GOOGLE_OAUTH_CLIENT_ID_ANDROID) \
		--dart-define=APP_VERSION=$(APP_VERSION)

dev-web: ## Roda local no Chrome em http://localhost:5000
	flutter pub get
	flutter run -d chrome --web-hostname localhost --web-port 5000 \
		--dart-define=GOOGLE_OAUTH_CLIENT_ID_WEB=$(GOOGLE_OAUTH_CLIENT_ID_WEB) \
		--dart-define=APP_VERSION=$(APP_VERSION)

prod-web: ## Compila e publica a Web em produção no Firebase Hosting
	@echo "1/5 Atualizando dependências Flutter..."
	flutter pub get && \
	V=$$(grep '^version: ' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1) && \
	MAJOR=$$(echo $$V | cut -d'.' -f1) && \
	MINOR=$$(echo $$V | cut -d'.' -f2) && \
	PATCH=$$(echo $$V | cut -d'.' -f3) && \
	NEW_PATCH=$$((PATCH + 1)) && \
	NEW_VER="$$MAJOR.$$MINOR.$$NEW_PATCH" && \
	NEW_FULL="$$MAJOR.$$MINOR.$$NEW_PATCH+0" && \
	sed -i "s/^version: .*/version: $$NEW_FULL/" pubspec.yaml && \
	sed -i "s/\"version\": \".*\"/\"version\": \"$$NEW_VER\"/" web/version.json && \
	BUILD_TS=$$(date +%s) && \
	sed -i "s/\"build\": \".*\"/\"build\": \"$$BUILD_TS\"/" web/version.json && \
	echo "2/5 Versão: v$$NEW_VER" && \
	echo "3/5 Compilando app Web..." && \
	flutter build web --release \
		--base-href=/ \
		--dart-define=GOOGLE_OAUTH_CLIENT_ID_WEB=$(GOOGLE_OAUTH_CLIENT_ID_WEB) \
		--dart-define=GOOGLE_OAUTH_CLIENT_ID_ANDROID=$(GOOGLE_OAUTH_CLIENT_ID_ANDROID) \
		--dart-define=APP_VERSION=$$NEW_VER && \
	echo "4/5 Copiando páginas públicas (privacidade, termos, verificação Google)..." && \
	cp branding/privacidade.html build/web/privacidade.html && \
	cp branding/termos.html build/web/termos.html && \
	cp branding/google505e804a9d870920.html build/web/google505e804a9d870920.html && \
	echo "5/5 Publicando no Firebase Hosting ($(FIREBASE_PROJECT_ID))..." && \
	firebase deploy --only hosting --project $(FIREBASE_PROJECT_ID) && \
	echo "Deploy v$$NEW_VER concluído."

prod-android: ## Gera APK Android release para preparar publicação na loja
	flutter pub get
	flutter build apk --release \
		--dart-define=GOOGLE_OAUTH_CLIENT_ID_WEB=$(GOOGLE_OAUTH_CLIENT_ID_WEB) \
		--dart-define=GOOGLE_OAUTH_CLIENT_ID_ANDROID=$(GOOGLE_OAUTH_CLIENT_ID_ANDROID) \
		--dart-define=APP_VERSION=$(APP_VERSION)
