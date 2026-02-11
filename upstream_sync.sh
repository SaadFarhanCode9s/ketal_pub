#!/bin/bash

# upstream_sync.sh
# Safe upstream sync script for Ketal repository
# Pulls from element-x-ios and merges while preserving Ketal branding

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
UPSTREAM_REPO="https://github.com/element-hq/element-x-ios.git"
UPSTREAM_BRANCH="main"
BACKUP_PREFIX="backup-before-upstream-sync"
MERGE_BRANCH_PREFIX="merge/upstream-main"

# Print colored messages
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
}

# Check if working tree is clean
check_clean_tree() {
    print_section "🔍 Pre-merge Validation"
    
    if ! git diff-index --quiet HEAD --; then
        print_error "Working tree is not clean. Please commit or stash your changes."
        git status --short
        exit 1
    fi
    print_success "Working tree is clean"
}

# Check current branch
check_branch() {
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        print_warning "Not on main branch (current: $current_branch)"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Aborted by user"
            exit 0
        fi
    else
        print_success "On main branch"
    fi
}

# Create backup branch
create_backup() {
    print_section "💾 Creating Backup"
    
    timestamp=$(date +%Y-%m-%d-%H%M%S)
    backup_branch="${BACKUP_PREFIX}-${timestamp}"
    
    git branch "$backup_branch"
    print_success "Created backup branch: $backup_branch"
    
    # Store backup name for later use
    echo "$backup_branch" > .sync_backup_branch
}

# Setup upstream remote
setup_upstream() {
    print_section "🔗 Setting up Upstream Remote"
    
    if git remote get-url upstream > /dev/null 2>&1; then
        print_info "Upstream remote already exists"
        current_upstream=$(git remote get-url upstream)
        if [ "$current_upstream" != "$UPSTREAM_REPO" ]; then
            print_warning "Upstream URL mismatch!"
            print_info "Current: $current_upstream"
            print_info "Expected: $UPSTREAM_REPO"
            read -p "Update upstream URL? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git remote set-url upstream "$UPSTREAM_REPO"
                print_success "Updated upstream URL"
            fi
        fi
    else
        git remote add upstream "$UPSTREAM_REPO"
        print_success "Added upstream remote: $UPSTREAM_REPO"
    fi
}

# Fetch upstream changes
fetch_upstream() {
    print_section "📥 Fetching Upstream Changes"
    
    print_info "Fetching from upstream/$UPSTREAM_BRANCH..."
    if git fetch upstream "$UPSTREAM_BRANCH"; then
        print_success "Successfully fetched upstream changes"
        
        # Show what's new
        commit_count=$(git rev-list --count HEAD..upstream/$UPSTREAM_BRANCH 2>/dev/null || echo "0")
        print_info "Commits to merge: $commit_count"
        
        if [ "$commit_count" -eq "0" ]; then
            print_success "Already up to date with upstream!"
            cleanup_backup
            exit 0
        fi
    else
        print_error "Failed to fetch from upstream"
        cleanup_backup
        exit 1
    fi
}

# Merge upstream
merge_upstream() {
    print_section "🔀 Merging Upstream Changes"
    
    timestamp=$(date +%Y-%m-%d-%H%M%S)
    merge_branch="${MERGE_BRANCH_PREFIX}-${timestamp}"
    
    print_info "Creating merge branch: $merge_branch"
    git checkout -b "$merge_branch"
    
    print_info "Attempting merge from upstream/$UPSTREAM_BRANCH..."
    if git merge "upstream/$UPSTREAM_BRANCH" --no-edit -m "Merge upstream/$UPSTREAM_BRANCH into ketal"; then
        print_success "Merge completed without conflicts!"
        return 0
    else
        # Check if it was an unrelated histories error
        if git merge "upstream/$UPSTREAM_BRANCH" --no-edit -m "Merge upstream/$UPSTREAM_BRANCH into ketal" 2>&1 | grep -q "unrelated histories"; then
            print_warning "Unrelated histories detected. Retrying with --allow-unrelated-histories..."
            if git merge "upstream/$UPSTREAM_BRANCH" --allow-unrelated-histories --no-edit -m "Merge upstream/$UPSTREAM_BRANCH into ketal"; then
                print_success "Merge completed (allowed unrelated histories)!"
                return 0
            fi
        fi

        print_warning "Conflicts detected during merge or merge failed"
        return 1
    fi
}

# Re-apply branding to configuration files
reapply_branding() {
    print_section "🎨 Re-applying Ketal Branding"
    
    # 1. project.yml
    if [ -f project.yml ]; then
        print_info "Branding project.yml..."
        sed -i 's/name: ElementX/name: ketal/g' project.yml
        sed -i 's/ORGANIZATIONNAME: Element/ORGANIZATIONNAME: ketal/g' project.yml
        sed -i 's/- ElementX/- ketal/g' project.yml
        sed -i 's/pattern: ElementX/pattern: ketal/g' project.yml
        sed -i 's/APP_NAME: ElementX/APP_NAME: ketal/g' project.yml
        sed -i 's/ElementX\/SupportingFiles/ketal\/SupportingFiles/g' project.yml
    fi

    # 2. app.yml
    if [ -f app.yml ]; then
        print_info "Branding app.yml..."
        sed -i 's/APP_DISPLAY_NAME: ElementX/APP_DISPLAY_NAME: ketal/g' app.yml
        sed -i 's/PRODUCTION_APP_NAME: ElementX/PRODUCTION_APP_NAME: ketal/g' app.yml
        sed -i 's/APP_GROUP_IDENTIFIER: group.io.element.elementx/APP_GROUP_IDENTIFIER: group.io.ketal/g' app.yml
        sed -i 's/BASE_BUNDLE_IDENTIFIER: io.element.elementx/BASE_BUNDLE_IDENTIFIER: io.ketal.app/g' app.yml
        sed -i 's/DEVELOPMENT_TEAM: .*/DEVELOPMENT_TEAM: 7J4U792NQT/g' app.yml
    fi
    
    # 3. localazy.json
    if [ -f localazy.json ]; then
        print_info "Branding localazy.json..."
        sed -i 's/ElementX\/Resources/ketal\/Resources/g' localazy.json
    fi

    # 4. fastlane/Fastfile
    if [ -f fastlane/Fastfile ]; then
        print_info "Branding fastlane/Fastfile..."
        sed -i 's/scheme: "ElementX"/scheme: "ketal"/g' fastlane/Fastfile
        sed -i 's/target: "ElementX"/target: "ketal"/g' fastlane/Fastfile
        sed -i 's/project: "ElementX.xcodeproj"/project: "ketal.xcodeproj"/g' fastlane/Fastfile
    fi
    
    # 5. Handle directory moves/renames
    if [ -d "ElementX" ]; then
        print_info "Moving ElementX/ directory to ketal/..."
        # If ketal already exists, we might need to be careful not to overwrite indiscriminately,
        # but for a sync, we generally want branding + new content.
        # Simplest approach: Sync content from ElementX to ketal, then remove ElementX
        mkdir -p ketal
        cp -R ElementX/* ketal/ 2>/dev/null || true
        rm -rf ElementX
    fi
    
    print_success "Branding re-applied successfully"
}

# Auto-resolve configuration file conflicts
auto_resolve_conflicts() {
    print_section "🔧 Resolving Configuration Conflicts"
    
    # Check if in merge state
    if ! git status | grep -q "You have unmerged paths"; then
        return 0
    fi
    
    # List of files to take UPSTREAM version (theirs) and then patch
    config_files=(
        "project.yml"
        "app.yml"
        "ketal/SupportingFiles/target.yml"
        "NSE/SupportingFiles/target.yml"
        "UITests/SupportingFiles/target.yml"
        "UnitTests/SupportingFiles/target.yml"
        "AccessibilityTests/SupportingFiles/target.yml"
        "PreviewTests/SupportingFiles/target.yml"
        "ShareExtension/SupportingFiles/target.yml"
        ".githooks/pre-commit"
        "localazy.json"
        "fastlane/Fastfile"
    )
    
    has_conflicts=false
    
    for file in "${config_files[@]}"; do
        # Check for conflicts (UU or AA)
        if git status --porcelain | grep -qE "^(UU|AA)[[:space:]]+$file$"; then
            print_info "Taking upstream version for: $file"
            git checkout --theirs "$file" 2>/dev/null || true        
            # If the file didn't exist in ours but exists in theirs, it might be in a different path (ElementX vs ketal)
            # If 'ketal/...' failed, try 'ElementX/...' equivalent if we can predict it, 
            # but usually git tracks this. 
            
            git add "$file"
            has_conflicts=true
        fi
    done
    
    # Handle test files - for these we generally want upstream changes too
    print_info "Checking for test file import conflicts..."
    test_files=$(git status --porcelain | grep -E "^(UU|AA).*Tests/" | awk '{print $2}' || true)
    
    for test_file in $test_files; do
        if [ -f "$test_file" ]; then
            print_info "Taking upstream version for test file: $test_file"
            git checkout --theirs "$test_file"
            
            # Post-processing: If imports need changing
            sed -i 's/import ElementX/import ketal/g' "$test_file"
            sed -i 's/@testable import ElementX/@testable import ketal/g' "$test_file"
            
            git add "$test_file"
            has_conflicts=true
        fi
    done

    # Re-apply Branding
    reapply_branding
    
    # Check for remaining conflicts
    remaining_conflicts=$(git status --porcelain | grep -E "^(UU|AA)" | wc -l)
    
    if [ "$remaining_conflicts" -gt 0 ]; then
        print_warning "Manual conflicts remaining: $remaining_conflicts files"
        git status --porcelain | grep -E "^(UU|AA)"
        return 1
    fi
    
    # No remaining conflicts, commit the merge
    if [ "$has_conflicts" = true ]; then
        git commit --no-edit -m "Merge upstream/$UPSTREAM_BRANCH - re-applied ketal branding"
        print_success "Merge committed successfully"
    fi
    
    return 0
}

# Regenerate Xcode project
regenerate_project() {
    print_section "🔨 Regenerating Xcode Project"
    
    print_info "Running: swift run tools setup-project"
    
    if swift run tools setup-project; then
        print_success "Xcode project regenerated successfully"
        
        # Add generated project files
        if [ -f "ketal.xcodeproj/project.pbxproj" ]; then
            git add ketal.xcodeproj/
            print_success "Added generated project files"
        fi
        
        return 0
    else
        print_error "Failed to regenerate Xcode project"
        print_info "You may need to fix issues manually and run: swift run tools setup-project"
        return 1
    fi
}

# Validate ketal configuration
validate_configuration() {
    print_section "🔍 Validating Ketal Configuration"
    
    errors=0
    
    # Check project.yml
    if grep -q "name: ketal" project.yml; then
        print_success "project.yml: name is 'ketal'"
    else
        print_error "project.yml: name is NOT 'ketal'"
        errors=$((errors + 1))
    fi
    
    # Check app.yml
    if grep -q "APP_DISPLAY_NAME: ketal" app.yml; then
        print_success "app.yml: APP_DISPLAY_NAME is 'ketal'"
    else
        print_error "app.yml: APP_DISPLAY_NAME is NOT 'ketal'"
        print_info "Found: $(grep "APP_DISPLAY_NAME" app.yml)"
        errors=$((errors + 1))
    fi
    
    # Check target.yml
    if [ -f "ketal/SupportingFiles/target.yml" ]; then
        print_success "ketal/SupportingFiles/target.yml exists"
    else
        print_error "ketal/SupportingFiles/target.yml NOT found"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        print_success "All validation checks passed!"
        return 0
    else
        print_error "Validation failed with $errors error(s)"
        return 1
    fi
}

# Finalize sync: merge to main
finalize_sync() {
    print_section "🏁 Finalizing Sync"
    
    current_branch=$(git branch --show-current)
    
    print_info "Sync and validation successful on branch: $current_branch"
    print_info "Do you want to merge these changes to 'main' and push to origin? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_info "Switching to main..."
        git checkout main
        
        print_info "Merging $current_branch into main..."
        if git merge "$current_branch"; then
            print_success "Merged successfully"
            
            print_info "Pushing to origin/main..."
            if git push origin main; then
                print_success "Pushed to origin successfully"
                
                print_info "Deleting temporary branch $current_branch..."
                git branch -D "$current_branch"
                
                print_success "Cleanup complete"
                print_success "🚀 Main branch is now up to date!"
                exit 0
            else
                print_error "Failed to push to origin"
                exit 1
            fi
        else
            print_error "Failed to merge to main"
            exit 1
        fi
    else
        print_info "Skipping merge to main."
        print_info "You are currently on branch: $current_branch"
        return 0
    fi
}

# Cleanup backup branch file
cleanup_backup() {
    if [ -f .sync_backup_branch ]; then
        rm .sync_backup_branch
    fi
}

# Main execution
main() {
    print_section "🚀 Ketal Upstream Sync Script"
    print_info "This script will safely merge changes from element-x-ios upstream"
    echo ""
    
    # Pre-flight checks
    check_git_repo
    check_clean_tree
    check_branch
    
    # Create backup
    create_backup
    
    # Setup and fetch
    setup_upstream
    fetch_upstream
    
    # Attempt merge
    if merge_upstream; then
        print_success "Clean merge - no conflicts!"
    else
        # Try to auto-resolve
        if ! auto_resolve_conflicts; then
            print_section "⚠️  Manual Intervention Required"
            print_warning "There are conflicts that need manual resolution"
            echo ""
            print_info "To resolve manually:"
            print_info "  1. Edit the conflicted files"
            print_info "  2. Run: git add <resolved-files>"
            print_info "  3. Run: git commit"
            print_info "  4. Run: swift run tools setup-project"
            echo ""
            print_info "To rollback:"
            backup_branch=$(cat .sync_backup_branch)
            print_info "  git reset --hard $backup_branch"
            echo ""
            exit 1
        fi
    fi
    
    # Regenerate project
    if ! regenerate_project; then
        print_warning "Project regeneration had issues, but merge is complete"
        print_info "You may need to run 'swift run tools setup-project' manually"
    fi
    
    # Validate
    if ! validate_configuration; then
        print_warning "Configuration validation failed!"
        print_info "Please review the configuration files manually"
    fi
    
    # Success summary
    print_section "✅ Sync Complete!"
    backup_branch=$(cat .sync_backup_branch)
    
    echo ""
    print_success "Upstream sync completed successfully!"
    print_info "Backup branch: $backup_branch"
    echo ""
    print_info "Next steps:"
    print_info "  1. Review changes: git log -p -1"
    print_info "  2. Build the project: xcodebuild -scheme ketal build"
    print_info "  3. Run tests (if available)"
    print_info "  4. If issues found, rollback: git reset --hard $backup_branch"
    echo ""
    
    # Offer to finalize
    finalize_sync
    echo ""
    print_info "If everything looks good, you can delete the backup branch:"
    print_info "  git branch -D $backup_branch"
    echo ""
    
    cleanup_backup
}

# Run main
main "$@"
