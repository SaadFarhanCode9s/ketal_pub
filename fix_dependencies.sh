#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }

# 1. Checkout upstream versions of config files
print_info "Checking out upstream versions of configuration files..."
git fetch upstream main
git checkout upstream/main -- project.yml app.yml fastlane/Fastfile localazy.json ketal/SupportingFiles/target.yml ElementX/SupportingFiles/target.yml 2>/dev/null || true

# 2. Re-apply branding
print_info "Re-applying Ketal branding..."

# project.yml
if [ -f project.yml ]; then
    print_info "Branding project.yml..."
    sed -i 's/name: ElementX/name: ketal/g' project.yml
    sed -i 's/ORGANIZATIONNAME: Element/ORGANIZATIONNAME: ketal/g' project.yml
    sed -i 's/- ElementX/- ketal/g' project.yml
    sed -i 's/pattern: ElementX/pattern: ketal/g' project.yml
    sed -i 's/APP_NAME: ElementX/APP_NAME: ketal/g' project.yml
    sed -i 's/ElementX\/SupportingFiles/ketal\/SupportingFiles/g' project.yml
fi

# app.yml
if [ -f app.yml ]; then
    print_info "Branding app.yml..."
    sed -i 's/APP_DISPLAY_NAME: ElementX/APP_DISPLAY_NAME: ketal/g' app.yml
    sed -i 's/PRODUCTION_APP_NAME: ElementX/PRODUCTION_APP_NAME: ketal/g' app.yml
    sed -i 's/APP_GROUP_IDENTIFIER: group.io.element.elementx/APP_GROUP_IDENTIFIER: group.io.ketal/g' app.yml
    sed -i 's/BASE_BUNDLE_IDENTIFIER: io.element.elementx/BASE_BUNDLE_IDENTIFIER: io.ketal.app/g' app.yml
    sed -i 's/DEVELOPMENT_TEAM: .*/DEVELOPMENT_TEAM: 7J4U792NQT/g' app.yml
fi

# localazy.json
if [ -f localazy.json ]; then
    print_info "Branding localazy.json..."
    sed -i 's/ElementX\/Resources/ketal\/Resources/g' localazy.json
fi

# fastlane/Fastfile
if [ -f fastlane/Fastfile ]; then
    print_info "Branding fastlane/Fastfile..."
    sed -i 's/scheme: "ElementX"/scheme: "ketal"/g' fastlane/Fastfile
    sed -i 's/target: "ElementX"/target: "ketal"/g' fastlane/Fastfile
    sed -i 's/project: "ElementX.xcodeproj"/project: "ketal.xcodeproj"/g' fastlane/Fastfile
fi

# Handle directory moves
if [ -d "ElementX" ]; then
    print_info "Moving ElementX/ directory logic..."
    # If using checkout --, we might have resurrected ElementX dir content if it changed.
    # We should merge it into ketal if needed, but for config files we just want the file.
    # If 'git checkout' brought back ElementX/SupportingFiles/target.yml, we should move it.
    
    if [ -f "ElementX/SupportingFiles/target.yml" ]; then
        print_info "Updating target.yml from upstream ElementX version..."
        mkdir -p ketal/SupportingFiles
        mv ElementX/SupportingFiles/target.yml ketal/SupportingFiles/target.yml
    fi
    # Remove ElementX dir if empty or redundant
    rm -rf ElementX
fi

print_success "Branding re-applied. You can now diff and commit."
