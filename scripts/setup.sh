#!/bin/bash

# Escola Flutter Project Setup Script
# This script helps set up the development environment for the Escola app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Required Flutter version (from .fvmrc)
REQUIRED_FLUTTER_VERSION="3.29.3"

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_requirements() {
    print_header "Checking System Requirements"

    local all_good=true

    # Check Git
    if command_exists git; then
        print_success "Git is installed ($(git --version))"
    else
        print_error "Git is not installed"
        all_good=false
    fi

    # Check Java
    if command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        print_success "Java is installed (version $JAVA_VERSION)"
    else
        print_warning "Java is not installed - required for Android builds"
    fi

    # Check FVM
    if command_exists fvm; then
        print_success "FVM is installed ($(fvm --version))"
    else
        print_warning "FVM is not installed"
        echo ""
        echo "Install FVM with one of these methods:"
        echo "  • dart pub global activate fvm"
        echo "  • brew tap leoafarias/fvm && brew install fvm (macOS)"
        echo ""
    fi

    # Check Flutter (via FVM or global)
    if command_exists fvm && fvm list | grep -q "$REQUIRED_FLUTTER_VERSION"; then
        print_success "Flutter $REQUIRED_FLUTTER_VERSION is installed via FVM"
    elif command_exists flutter; then
        FLUTTER_VERSION=$(flutter --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ "$FLUTTER_VERSION" == "$REQUIRED_FLUTTER_VERSION" ]; then
            print_success "Flutter $REQUIRED_FLUTTER_VERSION is installed globally"
        else
            print_warning "Flutter version $FLUTTER_VERSION found, but $REQUIRED_FLUTTER_VERSION is required"
        fi
    else
        print_warning "Flutter is not installed"
        echo ""
        echo "Install Flutter $REQUIRED_FLUTTER_VERSION:"
        echo "  • Using FVM: fvm install $REQUIRED_FLUTTER_VERSION && fvm use $REQUIRED_FLUTTER_VERSION"
        echo "  • Or download from: https://flutter.dev/docs/get-started/install"
        echo ""
    fi

    # Check for Android SDK (via ANDROID_HOME or ANDROID_SDK_ROOT)
    if [ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ]; then
        print_success "Android SDK found"
    else
        print_warning "Android SDK not found in environment variables"
    fi

    # Check for Xcode (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists xcodebuild; then
            XCODE_VERSION=$(xcodebuild -version | head -n 1)
            print_success "Xcode is installed ($XCODE_VERSION)"
        else
            print_warning "Xcode is not installed - required for iOS builds"
        fi

        # Check for CocoaPods
        if command_exists pod; then
            print_success "CocoaPods is installed ($(pod --version))"
        else
            print_warning "CocoaPods is not installed - required for iOS builds"
            echo "  Install with: sudo gem install cocoapods"
        fi
    fi

    echo ""
    if [ "$all_good" = true ]; then
        print_success "All required dependencies are installed!"
    else
        print_warning "Some dependencies are missing. Please install them before continuing."
    fi
}

# Install Flutter via FVM
install_flutter() {
    print_header "Installing Flutter $REQUIRED_FLUTTER_VERSION"

    if ! command_exists fvm; then
        print_error "FVM is not installed. Please install FVM first:"
        echo "  dart pub global activate fvm"
        exit 1
    fi

    # Install the required Flutter version
    print_info "Installing Flutter $REQUIRED_FLUTTER_VERSION via FVM..."
    fvm install "$REQUIRED_FLUTTER_VERSION"

    # Use it for this project
    print_info "Setting Flutter $REQUIRED_FLUTTER_VERSION for this project..."
    fvm use "$REQUIRED_FLUTTER_VERSION"

    print_success "Flutter $REQUIRED_FLUTTER_VERSION installed and configured!"
}

# Install project dependencies
install_dependencies() {
    print_header "Installing Project Dependencies"

    # Determine Flutter command
    if command_exists fvm && fvm list | grep -q "$REQUIRED_FLUTTER_VERSION"; then
        FLUTTER_CMD="fvm flutter"
    elif command_exists flutter; then
        FLUTTER_CMD="flutter"
    else
        print_error "Flutter is not available. Please install Flutter first."
        exit 1
    fi

    # Get dependencies
    print_info "Running flutter pub get..."
    $FLUTTER_CMD pub get

    print_success "Dependencies installed!"
}

# Run code generation
run_code_generation() {
    print_header "Running Code Generation"

    # Determine Flutter command
    if command_exists fvm && fvm list | grep -q "$REQUIRED_FLUTTER_VERSION"; then
        FLUTTER_CMD="fvm flutter"
    elif command_exists flutter; then
        FLUTTER_CMD="flutter"
    else
        print_error "Flutter is not available. Please install Flutter first."
        exit 1
    fi

    print_info "Running build_runner..."
    $FLUTTER_CMD pub run build_runner build --delete-conflicting-outputs

    print_success "Code generation complete!"
}

# Install iOS dependencies
install_ios_dependencies() {
    print_header "Installing iOS Dependencies"

    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "Skipping iOS setup - not on macOS"
        return
    fi

    if ! command_exists pod; then
        print_error "CocoaPods is not installed. Install with: sudo gem install cocoapods"
        return
    fi

    print_info "Installing CocoaPods dependencies..."
    cd ios
    pod install
    cd ..

    print_success "iOS dependencies installed!"
}

# Clean the project
clean_project() {
    print_header "Cleaning Project"

    # Determine Flutter command
    if command_exists fvm && fvm list | grep -q "$REQUIRED_FLUTTER_VERSION"; then
        FLUTTER_CMD="fvm flutter"
    elif command_exists flutter; then
        FLUTTER_CMD="flutter"
    else
        print_error "Flutter is not available. Please install Flutter first."
        exit 1
    fi

    print_info "Running flutter clean..."
    $FLUTTER_CMD clean

    print_info "Removing generated files..."
    rm -rf .dart_tool
    rm -rf build

    print_success "Project cleaned!"
}

# Full setup
full_setup() {
    print_header "Escola - Full Project Setup"

    check_requirements

    echo ""
    read -p "Continue with setup? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command_exists fvm; then
            install_flutter
        fi
        install_dependencies
        run_code_generation
        install_ios_dependencies

        print_header "Setup Complete!"
        echo ""
        echo "You can now run the app with:"
        echo ""
        echo "  # Parents app:"
        echo "  fvm flutter run -t lib/main.dart --flavor parents"
        echo ""
        echo "  # Professors app:"
        echo "  fvm flutter run -t lib/main_professores.dart --flavor professores"
        echo ""
    fi
}

# Show help
show_help() {
    echo "Escola Project Setup Script"
    echo ""
    echo "Usage: ./scripts/setup.sh [command]"
    echo ""
    echo "Commands:"
    echo "  check       Check system requirements"
    echo "  flutter     Install Flutter via FVM"
    echo "  deps        Install project dependencies"
    echo "  codegen     Run code generation (build_runner)"
    echo "  ios         Install iOS dependencies (macOS only)"
    echo "  clean       Clean the project"
    echo "  full        Run full setup (default)"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/setup.sh          # Run full setup"
    echo "  ./scripts/setup.sh check    # Just check requirements"
    echo "  ./scripts/setup.sh deps     # Just install dependencies"
    echo ""
}

# Main script
cd "$(dirname "$0")/.."

case "${1:-full}" in
    check)
        check_requirements
        ;;
    flutter)
        install_flutter
        ;;
    deps)
        install_dependencies
        ;;
    codegen)
        run_code_generation
        ;;
    ios)
        install_ios_dependencies
        ;;
    clean)
        clean_project
        ;;
    full)
        full_setup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
