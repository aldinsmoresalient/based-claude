#!/usr/bin/env bash
#
# Atlas Generator Script
# Analyzes codebase and generates grep-friendly atlas files
#
set -euo pipefail

#───────────────────────────────────────────────────────────────────────────────
# Configuration
#───────────────────────────────────────────────────────────────────────────────

# Directories to always exclude
EXCLUDE_DIRS=(
    "node_modules"
    "vendor"
    ".git"
    "dist"
    "build"
    "target"
    "__pycache__"
    ".next"
    "coverage"
    ".claude-sdk"
    ".venv"
    "venv"
    "env"
)

# File patterns to include for analysis
INCLUDE_PATTERNS=(
    "*.ts"
    "*.tsx"
    "*.js"
    "*.jsx"
    "*.py"
    "*.go"
    "*.rs"
    "*.java"
    "*.rb"
    "*.php"
)

# Maximum files per folder to analyze in detail
MAX_FILES_PER_FOLDER=50

# Maximum depth for folder discovery
MAX_DEPTH=4

#───────────────────────────────────────────────────────────────────────────────
# Main
#───────────────────────────────────────────────────────────────────────────────

main() {
    local project_root="${1:-.}"
    local atlas_dir="${2:-.claude-sdk/atlas}"
    local target_folder="${3:-}"

    project_root=$(cd "$project_root" && pwd)

    echo "Atlas Generator"
    echo "==============="
    echo "Project: $project_root"
    echo ""

    # Create atlas directory
    mkdir -p "$atlas_dir"

    # Detect project type
    local project_type
    project_type=$(detect_project_type "$project_root")
    echo "Detected type: $project_type"

    # Find folders to index
    if [[ -n "$target_folder" ]]; then
        # Index specific folder
        generate_folder_map "$project_root" "$atlas_dir" "$target_folder"
    else
        # Index all important folders
        echo ""
        echo "Finding folders to index..."

        local folders
        folders=$(find_important_folders "$project_root")

        local count=0
        while IFS= read -r folder; do
            if [[ -n "$folder" ]]; then
                echo "  Indexing: $folder"
                generate_folder_map "$project_root" "$atlas_dir" "$folder"
                ((count++))
            fi
        done <<< "$folders"

        echo ""
        echo "Indexed $count folders"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Project Type Detection
#───────────────────────────────────────────────────────────────────────────────

detect_project_type() {
    local root="$1"

    if [[ -f "$root/package.json" ]]; then
        if grep -q '"next"' "$root/package.json" 2>/dev/null; then
            echo "nextjs"
        elif grep -q '"react"' "$root/package.json" 2>/dev/null; then
            echo "react"
        elif grep -q '"express"' "$root/package.json" 2>/dev/null; then
            echo "express"
        else
            echo "node"
        fi
    elif [[ -f "$root/pyproject.toml" ]] || [[ -f "$root/setup.py" ]]; then
        if grep -q "django" "$root/pyproject.toml" 2>/dev/null || \
           grep -q "django" "$root/requirements.txt" 2>/dev/null; then
            echo "django"
        elif grep -q "flask" "$root/pyproject.toml" 2>/dev/null || \
             grep -q "flask" "$root/requirements.txt" 2>/dev/null; then
            echo "flask"
        else
            echo "python"
        fi
    elif [[ -f "$root/go.mod" ]]; then
        echo "go"
    elif [[ -f "$root/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$root/pom.xml" ]] || [[ -f "$root/build.gradle" ]]; then
        echo "java"
    else
        echo "unknown"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Folder Discovery
#───────────────────────────────────────────────────────────────────────────────

find_important_folders() {
    local root="$1"

    # Build exclude pattern for find
    local exclude_pattern=""
    for dir in "${EXCLUDE_DIRS[@]}"; do
        exclude_pattern="$exclude_pattern -name $dir -prune -o"
    done

    # Find directories with code files
    find "$root" -maxdepth "$MAX_DEPTH" -type d \
        $exclude_pattern \
        -type d -print 2>/dev/null | \
    while read -r dir; do
        # Check if directory has relevant code files
        local has_code=false
        for pattern in "${INCLUDE_PATTERNS[@]}"; do
            if ls "$dir"/$pattern 2>/dev/null | head -1 | grep -q .; then
                has_code=true
                break
            fi
        done

        if $has_code; then
            # Output relative path
            echo "${dir#$root/}"
        fi
    done | grep -v "^$" | sort | uniq
}

#───────────────────────────────────────────────────────────────────────────────
# Folder Map Generation
#───────────────────────────────────────────────────────────────────────────────

generate_folder_map() {
    local project_root="$1"
    local atlas_dir="$2"
    local folder="$3"

    local folder_path="$project_root/$folder"
    local safe_name="${folder//\//_}"
    local atlas_file="$atlas_dir/${safe_name}.atlas.md"

    # Skip if folder doesn't exist
    if [[ ! -d "$folder_path" ]]; then
        return
    fi

    # Analyze folder
    local purpose=""
    local layer=""
    local risk="low"

    # Detect purpose based on folder name
    case "$folder" in
        *auth*|*login*|*session*)
            purpose="Authentication and session management"
            layer="business"
            risk="high"
            ;;
        *api*|*routes*|*handlers*|*controllers*)
            purpose="API route handlers"
            layer="presentation"
            risk="medium"
            ;;
        *model*|*entity*|*schema*)
            purpose="Data models and schemas"
            layer="data"
            risk="medium"
            ;;
        *service*|*core*|*domain*)
            purpose="Business logic"
            layer="business"
            risk="medium"
            ;;
        *db*|*database*|*repository*|*repo*)
            purpose="Database access layer"
            layer="data"
            risk="medium"
            ;;
        *util*|*helper*|*lib*)
            purpose="Utility functions"
            layer="infrastructure"
            risk="low"
            ;;
        *test*|*spec*|*__tests__*)
            purpose="Tests"
            layer="test"
            risk="low"
            ;;
        *config*|*settings*)
            purpose="Configuration"
            layer="infrastructure"
            risk="medium"
            ;;
        *component*|*ui*|*view*)
            purpose="UI components"
            layer="presentation"
            risk="low"
            ;;
        *)
            purpose="[Describe purpose]"
            layer="unknown"
            ;;
    esac

    # Count files
    local file_count=0
    for pattern in "${INCLUDE_PATTERNS[@]}"; do
        local count
        count=$(find "$folder_path" -maxdepth 1 -name "$pattern" 2>/dev/null | wc -l)
        file_count=$((file_count + count))
    done

    # Start writing atlas file
    cat > "$atlas_file" <<EOF
# FOLDER: $folder

PURPOSE: $purpose
LAYER: $layer
RISK: $risk
FILES: $file_count

## KEY FILES
EOF

    # List important files
    for pattern in "${INCLUDE_PATTERNS[@]}"; do
        find "$folder_path" -maxdepth 1 -name "$pattern" 2>/dev/null | \
        head -n "$MAX_FILES_PER_FOLDER" | \
        while read -r file; do
            local name
            name=$(basename "$file")
            echo "FILE: $name"
        done
    done >> "$atlas_file"

    # Find exports
    cat >> "$atlas_file" <<EOF

## EXPORTS
EOF

    # Extract exports based on file type
    if ls "$folder_path"/*.ts 2>/dev/null | head -1 | grep -q .; then
        grep -h "^export " "$folder_path"/*.ts 2>/dev/null | \
        head -20 | \
        sed 's/^/EXPORT: /' >> "$atlas_file" || true
    fi

    if ls "$folder_path"/*.js 2>/dev/null | head -1 | grep -q .; then
        grep -h "^export " "$folder_path"/*.js 2>/dev/null | \
        head -20 | \
        sed 's/^/EXPORT: /' >> "$atlas_file" || true

        grep -h "^module.exports" "$folder_path"/*.js 2>/dev/null | \
        head -10 | \
        sed 's/^/EXPORT: /' >> "$atlas_file" || true
    fi

    if ls "$folder_path"/*.py 2>/dev/null | head -1 | grep -q .; then
        grep -h "^def \|^class " "$folder_path"/*.py 2>/dev/null | \
        grep -v "^def _" | \
        head -20 | \
        sed 's/^/EXPORT: /' >> "$atlas_file" || true
    fi

    # Add search anchors
    cat >> "$atlas_file" <<EOF

## SEARCH ANCHORS
GREP: "function " in $folder
GREP: "class " in $folder
GREP: "export " in $folder
GREP: "import.*from" in $folder
EOF

    # Add dependencies section
    cat >> "$atlas_file" <<EOF

## DEPENDENCIES
EOF

    # Try to find imports
    if ls "$folder_path"/*.ts 2>/dev/null | head -1 | grep -q .; then
        grep -h "^import.*from" "$folder_path"/*.ts 2>/dev/null | \
        grep -v "node_modules\|@types" | \
        sed "s/.*from ['\"]\\([^'\"]*\\)['\"].*/DEPENDS_ON: \\1/" | \
        sort | uniq | head -10 >> "$atlas_file" || true
    fi

    cat >> "$atlas_file" <<EOF

## NOTES
[Add folder-specific notes here]
EOF
}

#───────────────────────────────────────────────────────────────────────────────
# Run
#───────────────────────────────────────────────────────────────────────────────

main "$@"
