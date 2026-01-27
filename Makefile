# Escola Flutter Project Makefile
# Provides convenient shortcuts for common development tasks

.PHONY: help setup check deps codegen clean run-parents run-professors build-parents build-professors

# Default Flutter command (uses FVM if available)
FLUTTER := $(shell command -v fvm >/dev/null 2>&1 && echo "fvm flutter" || echo "flutter")

# Help target
help:
	@echo "Escola Flutter Project - Available Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup          - Run full project setup"
	@echo "  make check          - Check system requirements"
	@echo "  make deps           - Install dependencies (pub get)"
	@echo "  make codegen        - Run code generation (build_runner)"
	@echo "  make clean          - Clean build artifacts"
	@echo ""
	@echo "Run (Debug):"
	@echo "  make run-parents    - Run Parents app in debug mode"
	@echo "  make run-professors - Run Professors app in debug mode"
	@echo ""
	@echo "Build (Release):"
	@echo "  make build-parents-apk    - Build Parents APK"
	@echo "  make build-professors-apk - Build Professors APK"
	@echo "  make build-parents-ios    - Build Parents iOS (macOS only)"
	@echo "  make build-professors-ios - Build Professors iOS (macOS only)"
	@echo ""
	@echo "Maintenance:"
	@echo "  make analyze        - Run Flutter analyzer"
	@echo "  make format         - Format Dart code"
	@echo "  make outdated       - Check for outdated packages"
	@echo ""

# Setup targets
setup:
	@./scripts/setup.sh full

check:
	@./scripts/setup.sh check

deps:
	$(FLUTTER) pub get

codegen:
	$(FLUTTER) pub run build_runner build --delete-conflicting-outputs

codegen-watch:
	$(FLUTTER) pub run build_runner watch --delete-conflicting-outputs

clean:
	$(FLUTTER) clean
	rm -rf .dart_tool build

# Run targets (Debug)
run-parents:
	$(FLUTTER) run -t lib/main.dart --flavor parents

run-professors:
	$(FLUTTER) run -t lib/main_professores.dart --flavor professores

# Build targets (Release APK)
build-parents-apk:
	$(FLUTTER) build apk -t lib/main.dart --flavor parents --release

build-professors-apk:
	$(FLUTTER) build apk -t lib/main_professores.dart --flavor professores --release

# Build targets (Release iOS)
build-parents-ios:
	$(FLUTTER) build ios -t lib/main.dart --flavor parents --release

build-professors-ios:
	$(FLUTTER) build ios -t lib/main_professores.dart --flavor professores --release

# Build targets (App Bundle for Play Store)
build-parents-aab:
	$(FLUTTER) build appbundle -t lib/main.dart --flavor parents --release

build-professors-aab:
	$(FLUTTER) build appbundle -t lib/main_professores.dart --flavor professores --release

# Maintenance targets
analyze:
	$(FLUTTER) analyze

format:
	$(FLUTTER) format lib/

outdated:
	$(FLUTTER) pub outdated

upgrade:
	$(FLUTTER) pub upgrade

# iOS specific
ios-pods:
	cd ios && pod install

ios-pods-update:
	cd ios && pod update

# Android specific
android-clean:
	cd android && ./gradlew clean
