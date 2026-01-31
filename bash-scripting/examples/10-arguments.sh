#!/bin/bash
#
# Обработка аргументов командной строки
#

set -euo pipefail

echo "=== Базовые аргументы ==="
echo "Script name: $0"
echo "First argument: ${1:-<none>}"
echo "Second argument: ${2:-<none>}"
echo "All arguments: $*"
echo "All arguments (array): $@"
echo "Number of arguments: $#"

echo -e "\n=== Итерация по аргументам ==="
echo "Arguments:"
for arg in "$@"; do
    echo "  - $arg"
done

echo -e "\n=== Shift - сдвиг аргументов ==="
demo_shift() {
    echo "Before shift: $@"
    shift
    echo "After 1 shift: $@"
    shift 2
    echo "After 2 more shifts: $@"
}

demo_shift a b c d e

echo -e "\n=== Getopts - короткие опции ==="
demo_getopts() {
    local verbose=0
    local output=""
    local name=""

    while getopts "vho:n:" opt; do
        case $opt in
            v)
                verbose=1
                ;;
            h)
                echo "Usage: script [-v] [-o output] [-n name]"
                return 0
                ;;
            o)
                output="$OPTARG"
                ;;
            n)
                name="$OPTARG"
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                return 1
                ;;
            :)
                echo "Option -$OPTARG requires an argument" >&2
                return 1
                ;;
        esac
    done

    shift $((OPTIND-1))

    echo "Verbose: $verbose"
    echo "Output: ${output:-stdout}"
    echo "Name: ${name:-<not set>}"
    echo "Remaining args: $@"
}

echo "Example 1: -v -o file.txt -n John arg1 arg2"
demo_getopts -v -o file.txt -n John arg1 arg2

echo -e "\nExample 2: -vo output.log"
demo_getopts -vo output.log

echo -e "\n=== Manual parsing - длинные опции ==="
parse_long_options() {
    local verbose=0
    local file=""
    local positional=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat <<EOF
Usage: script [OPTIONS] [ARGUMENTS]

Options:
    -h, --help          Show help
    -v, --verbose       Verbose output
    -f, --file FILE     Input file
    --output=FILE       Output file

Examples:
    script --verbose --file input.txt
    script -v --output=output.txt arg1 arg2
EOF
                return 0
                ;;
            -v|--verbose)
                verbose=1
                shift
                ;;
            -f|--file)
                file="$2"
                shift 2
                ;;
            --output=*)
                output="${1#*=}"
                shift
                ;;
            --output)
                output="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1" >&2
                return 1
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    # Restore positional arguments
    set -- "${positional[@]}"

    echo "Verbose: $verbose"
    echo "File: ${file:-<not set>}"
    echo "Output: ${output:-<not set>}"
    echo "Positional: $@"
}

echo "Example: --verbose --file input.txt --output=result.txt pos1 pos2"
parse_long_options --verbose --file input.txt --output=result.txt pos1 pos2

echo -e "\n=== Полный пример с валидацией ==="
full_example() {
    # Defaults
    local verbose=0
    local dry_run=0
    local config=""
    local input_file=""
    local output_file="/dev/stdout"

    # Usage function
    usage() {
        cat <<EOF
Usage: $0 [OPTIONS] FILE

Process input file and generate output.

Options:
    -h, --help              Show this help
    -v, --verbose           Verbose output
    -n, --dry-run           Dry run mode
    -c, --config FILE       Configuration file
    -o, --output FILE       Output file (default: stdout)

Arguments:
    FILE                    Input file (required)

Examples:
    $0 -v input.txt
    $0 --config app.conf --output result.txt input.txt
    $0 --dry-run --verbose input.txt

EOF
        exit 0
    }

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                verbose=1
                shift
                ;;
            -n|--dry-run)
                dry_run=1
                shift
                ;;
            -c|--config)
                config="$2"
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                echo "Try '$0 --help' for more information." >&2
                return 1
                ;;
            *)
                input_file="$1"
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [ -z "$input_file" ]; then
        echo "Error: Input file is required" >&2
        echo "Try '$0 --help' for more information." >&2
        return 1
    fi

    # Validate input file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' not found" >&2
        return 1
    fi

    # Validate config if provided
    if [ -n "$config" ] && [ ! -f "$config" ]; then
        echo "Error: Config file '$config' not found" >&2
        return 1
    fi

    # Display settings
    echo "=== Configuration ==="
    echo "Verbose: $verbose"
    echo "Dry run: $dry_run"
    echo "Config: ${config:-<none>}"
    echo "Input: $input_file"
    echo "Output: $output_file"

    # Simulate processing
    if [ $verbose -eq 1 ]; then
        echo -e "\n=== Processing ==="
        echo "Reading input file..."
    fi

    if [ $dry_run -eq 1 ]; then
        echo "[DRY RUN] Would process: $input_file"
    else
        echo "Processing: $input_file"
    fi

    echo "Done!"
}

# Create test file
echo "test data" > /tmp/test_input.txt

echo "Example 1: -v /tmp/test_input.txt"
full_example -v /tmp/test_input.txt

echo -e "\nExample 2: --dry-run --verbose --output=/tmp/output.txt /tmp/test_input.txt"
full_example --dry-run --verbose --output=/tmp/output.txt /tmp/test_input.txt

echo -e "\nExample 3: Missing required argument"
full_example --verbose 2>&1 || echo "Failed as expected"

# Cleanup
rm -f /tmp/test_input.txt /tmp/output.txt

echo -e "\n=== Субкоманды (git-style) ==="
git_style() {
    local command="${1:-}"

    if [ -z "$command" ]; then
        echo "Usage: script <command> [options]"
        echo "Commands: init, add, commit, push"
        return 1
    fi

    shift

    case "$command" in
        init)
            echo "Initializing repository..."
            ;;
        add)
            echo "Adding files: $@"
            ;;
        commit)
            local message=""
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -m|--message)
                        message="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            echo "Committing with message: $message"
            ;;
        push)
            echo "Pushing changes..."
            ;;
        *)
            echo "Unknown command: $command"
            return 1
            ;;
    esac
}

echo "Example: init"
git_style init

echo -e "\nExample: add file1.txt file2.txt"
git_style add file1.txt file2.txt

echo -e "\nExample: commit -m 'Initial commit'"
git_style commit -m "Initial commit"
