# Escola Flutter Project Makefile
# Provides convenient shortcuts for common development tasks

.PHONY: help setup deps codegen clean run-parents run-professors build-parents build-professors

# Default Flutter command (uses FVM if available)
FLUTTER := $(shell command -v fvm >/dev/null 2>&1 && echo "fvm flutter" || echo "flutter")
DART := $(shell command -v fvm >/dev/null 2>&1 && echo "fvm dart" || echo "dart")

# Build flags (--no-tree-shake-icons required due to dynamic IconData in my_icon.dart)
BUILD_FLAGS := --no-tree-shake-icons

# Help target
help:
	@echo "Escola Flutter Project - Available Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup          - Run full project setup (deps + codegen)"
	@echo "  make deps           - Install dependencies (pub get)"
	@echo "  make codegen        - Run code generation (build_runner)"
	@echo "  make clean          - Clean build artifacts"
	@echo ""
	@echo "Run (Debug):"
	@echo "  make run-parents    - Run Parents app in debug mode"
	@echo "  make run-professors - Run Professors app in debug mode"
	@echo ""
	@echo "Build (Debug):"
	@echo "  make build-parents-debug    - Build Parents debug APK"
	@echo "  make build-professors-debug - Build Professors debug APK"
	@echo ""
	@echo "Build (Release):"
	@echo "  make build-parents-apk    - Build Parents release APK"
	@echo "  make build-professors-apk - Build Professors release APK"
	@echo "  make build-parents-ios    - Build Parents iOS (macOS only)"
	@echo "  make build-professors-ios - Build Professors iOS (macOS only)"
	@echo ""
	@echo "Maintenance:"
	@echo "  make analyze        - Run Flutter analyzer"
	@echo "  make format         - Format Dart code"
	@echo "  make outdated       - Check for outdated packages"
	@echo ""

# Setup targets
setup: deps codegen
	@echo "Setup complete!"

deps:
	$(FLUTTER) pub get

codegen:
	$(DART) run build_runner build --delete-conflicting-outputs

codegen-watch:
	$(DART) run build_runner watch --delete-conflicting-outputs

clean:
	$(FLUTTER) clean
	rm -rf .dart_tool build

# Run targets (Debug)
run-parents:
	$(FLUTTER) run -t lib/main.dart --flavor parents

run-professors:
	$(FLUTTER) run -t lib/main_professores.dart --flavor professores

# Build targets (Debug APK)
build-parents-debug:
	$(FLUTTER) build apk -t lib/main.dart --flavor parents --debug

build-professors-debug:
	$(FLUTTER) build apk -t lib/main_professores.dart --flavor professores --debug

# Build targets (Release APK)
build-parents-apk:
	$(FLUTTER) build apk -t lib/main.dart --flavor parents --release $(BUILD_FLAGS)

build-professors-apk:
	$(FLUTTER) build apk -t lib/main_professores.dart --flavor professores --release $(BUILD_FLAGS)

# Build targets (Release iOS)
build-parents-ios:
	$(FLUTTER) build ios -t lib/main.dart --flavor parents --release $(BUILD_FLAGS)

build-professors-ios:
	$(FLUTTER) build ios -t lib/main_professores.dart --flavor professores --release $(BUILD_FLAGS)

# Build targets (App Bundle for Play Store)
build-parents-aab:
	$(FLUTTER) build appbundle -t lib/main.dart --flavor parents --release $(BUILD_FLAGS)

build-professors-aab:
	$(FLUTTER) build appbundle -t lib/main_professores.dart --flavor professores --release $(BUILD_FLAGS)

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
