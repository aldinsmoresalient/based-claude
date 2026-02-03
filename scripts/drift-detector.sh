#!/usr/bin/env bash
#
# Drift Detector Script
# Detects divergence between Atlas and actual codebase
#
set -euo pipefail

#───────────────────────────────────────────────────────────────────────────────
# Configuration
#───────────────────────────────────────────────────────────────────────────────

# Thresholds for warnings
FILE_COUNT_THRESHOLD=5      # Warn if file count differs by this much
EXPORT_COUNT_THRESHOLD=3    # Warn if export count differs by this much

#───────────────────────────────────────────────────────────────────────────────
# Main
#───────────────────────────────────────────────────────────────────────────────

main() {
    local project_root="${1:-.}"
    local sdk_dir="$project_root/.claude-sdk"
    local atlas_file="$sdk_dir/ATLAS.md"
    local atlas_dir="$sdk_dir/atlas"

    echo "Drift Detector"
    echo "=============="
    echo ""

    # Check if atlas exists
    if [[ ! -f "$atlas_file" ]]; then
        echo "ERROR: No atlas found at $atlas_file"
        echo "Run 'claude-sdk atlas build' to create one."
        exit 1
    fi

    local drift_count=0
    local warning_count=0

    # Check root atlas freshness
    echo "Checking root atlas..."
    check_atlas_freshness "$atlas_file"
    local result=$?
    if [[ $result -gt 0 ]]; then
        ((warning_count++))
    fi

    # Check each folder atlas
    if [[ -d "$atlas_dir" ]]; then
        echo ""
        echo "Checking folder atlases..."

        for atlas in "$atlas_dir"/*.atlas.md; do
            if [[ -f "$atlas" ]]; then
                check_folder_atlas "$project_root" "$atlas"
                result=$?
                if [[ $result -eq 1 ]]; then
                    ((drift_count++))
                elif [[ $result -eq 2 ]]; then
                    ((warning_count++))
                fi
            fi
        done
    fi

    # Summary
    echo ""
    echo "─────────────────────────"
    echo "Summary"
    echo ""

    if [[ $drift_count -eq 0 ]] && [[ $warning_count -eq 0 ]]; then
        echo "✓ No drift detected"
        exit 0
    fi

    if [[ $drift_count -gt 0 ]]; then
        echo "✗ $drift_count folders have significant drift"
    fi

    if [[ $warning_count -gt 0 ]]; then
        echo "⚠ $warning_count warnings"
    fi

    echo ""
    echo "Run 'claude-sdk atlas refresh' to update."

    if [[ $drift_count -gt 0 ]]; then
        exit 1
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Freshness Check
#───────────────────────────────────────────────────────────────────────────────

check_atlas_freshness() {
    local atlas_file="$1"

    # Extract build time
    local built
    built=$(grep "^BUILT:" "$atlas_file" 2>/dev/null | head -1 | cut -d' ' -f2-)

    if [[ -z "$built" ]] || [[ "$built" == "not-yet-built" ]]; then
        echo "  ⚠ Atlas has never been built"
        return 1
    fi

    # Extract commit
    local commit
    commit=$(grep "^COMMIT:" "$atlas_file" 2>/dev/null | head -1 | cut -d' ' -f2-)

    # Check if we're in a git repo
    if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
        local current_commit
        current_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

        if [[ "$commit" != "$current_commit" ]]; then
            echo "  ⚠ Atlas built at commit $commit, now at $current_commit"

            # Count commits since atlas was built
            local commits_behind
            commits_behind=$(git rev-list --count "$commit"..HEAD 2>/dev/null || echo "?")

            if [[ "$commits_behind" != "?" ]]; then
                echo "    $commits_behind commits since last atlas build"
            fi

            return 1
        else
            echo "  ✓ Atlas is current (commit: $commit)"
            return 0
        fi
    else
        echo "  Built: $built"
        return 0
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Folder Atlas Check
#───────────────────────────────────────────────────────────────────────────────

check_folder_atlas() {
    local project_root="$1"
    local atlas_file="$2"

    # Extract folder path from atlas
    local folder
    folder=$(grep "^# FOLDER:" "$atlas_file" | head -1 | cut -d: -f2- | xargs)

    if [[ -z "$folder" ]]; then
        return 0
    fi

    local folder_path="$project_root/$folder"
    local atlas_name
    atlas_name=$(basename "$atlas_file")

    # Check if folder still exists
    if [[ ! -d "$folder_path" ]]; then
        echo "  ✗ $folder: folder no longer exists"
        return 1
    fi

    # Check file count
    local atlas_files
    atlas_files=$(grep "^FILES:" "$atlas_file" 2>/dev/null | head -1 | cut -d: -f2- | xargs)

    if [[ -n "$atlas_files" ]]; then
        local actual_files
        actual_files=$(find "$folder_path" -maxdepth 1 -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) 2>/dev/null | wc -l | xargs)

        local diff=$((actual_files - atlas_files))
        if [[ ${diff#-} -gt $FILE_COUNT_THRESHOLD ]]; then
            echo "  ⚠ $folder: file count changed ($atlas_files → $actual_files)"
            return 2
        fi
    fi

    # Check for new files not in atlas
    local listed_files
    listed_files=$(grep "^FILE:" "$atlas_file" 2>/dev/null | cut -d: -f2- | xargs)

    local new_files=0
    for file in "$folder_path"/*.ts "$folder_path"/*.js "$folder_path"/*.py; do
        if [[ -f "$file" ]]; then
            local name
            name=$(basename "$file")
            if ! echo "$listed_files" | grep -q "$name"; then
                ((new_files++))
            fi
        fi
    done 2>/dev/null

    if [[ $new_files -gt $FILE_COUNT_THRESHOLD ]]; then
        echo "  ⚠ $folder: $new_files new files not in atlas"
        return 2
    fi

    echo "  ✓ $folder: OK"
    return 0
}

#───────────────────────────────────────────────────────────────────────────────
# Run
#───────────────────────────────────────────────────────────────────────────────

main "$@"
