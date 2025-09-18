#!/usr/bin/env zsh
# Multi-project worktree manager with Claude support
#
# ASSUMPTIONS & SETUP:
# - Your git projects live in: ~/Projects/
# - Worktrees will be created in: ~/Projects/worktrees/<project>/<branch>
# - New branches will be named: <your-username>/<feature-name>
#
# DIRECTORY STRUCTURE EXAMPLE:
# ~/Projects/
# ├── my-app/              (main git repo)
# ├── another-project/     (main git repo)
# └── worktrees/
#     ├── my-app/
#     │   ├── feature-x/   (worktree)
#     │   └── bugfix-y/    (worktree)
#     └── another-project/
#         └── new-feature/ (worktree)
#
# CUSTOMIZATION:
# To use different directories, modify these lines in the w() function:
#   local projects_dir="$HOME/Projects"
#   local worktrees_dir="$HOME/Projects/worktrees"
#
# INSTALLATION:
# 1. Add to your .zshrc (in this order):
#    fpath=(~/.zsh/completions $fpath)
#    autoload -U compinit && compinit
#
# 2. Copy this entire script to your .zshrc (after the lines above)
#
# 3. Restart your terminal or run: source ~/.zshrc
#
# 4. Test it works: w <TAB> should show your projects
#
# If tab completion doesn't work:
# - Make sure the fpath line comes BEFORE the w function in your .zshrc
# - Restart your terminal completely
#
# USAGE:
#   w <project> <worktree>              # cd to worktree (creates if needed)
#   w <project> <worktree> <command>    # run command in worktree
#   w --list                            # list all worktrees
#   w --rm <project> <worktree>         # remove worktree
#
# EXAMPLES:
#   w myapp feature-x                   # cd to feature-x worktree
#   w myapp feature-x claude            # run claude in worktree
#   w myapp feature-x gst               # git status in worktree
#   w myapp feature-x gcmsg "fix: bug"  # git commit in worktree

# Multi-project worktree manager
w() {
    local projects_dir="$HOME/Projects"
    local worktrees_dir="$HOME/Projects/worktrees"

    # Handle special flags
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        cat << 'EOF'
Multi-project worktree manager with Claude support

USAGE:
  w <project> <worktree>              # cd to worktree (creates if needed)
  w <project> <worktree> <command>    # run command in worktree
  w --list                            # list all worktrees
  w --rm <project> <worktree>         # remove worktree
  w --help, -h                        # show this help

EXAMPLES:
  w myapp feature-x                   # cd to feature-x worktree
  w myapp feature-x claude            # run claude in worktree
  w myapp feature-x gst               # git status in worktree
  w myapp feature-x gcmsg "fix: bug"  # git commit in worktree

DIRECTORY STRUCTURE:
  ~/Projects/                         # Your git projects
  ~/Projects/worktrees/<project>/     # Worktrees for each project

NEW BRANCHES:
  Created as: <username>/<worktree-name>
  Example: svenlito/feature-x
EOF
        return 0
    elif [[ "$1" == "--list" ]]; then
        echo "=== All Worktrees ==="
        # Check new location
        if [[ -d "$worktrees_dir" ]]; then
            for project in $worktrees_dir/*(/N); do
                project_name=$(basename "$project")
                echo "\n[$project_name]"
                for wt in $project/*(/N); do
                    echo "  • $(basename "$wt")"
                done
            done
        fi
        return 0
    elif [[ "$1" == "--rm" ]]; then
        shift
        local project="$1"
        local worktree="$2"
        if [[ -z "$project" || -z "$worktree" ]]; then
            echo "Usage: w --rm <project> <worktree>"
            return 1
        fi
        local wt_path="$worktrees_dir/$project/$worktree"
        if [[ ! -d "$wt_path" ]]; then
            echo "Worktree not found: $wt_path"
            return 1
        fi
        (cd "$projects_dir/$project" && git worktree remove "$wt_path")
        return $?
    fi

    # Normal usage: w <project> <worktree> [command...]
    local project="$1"
    local worktree="$2"

    if [[ -z "$project" || -z "$worktree" ]]; then
        echo "Usage: w <project> <worktree> [command...]"
        echo "       w --list"
        echo "       w --rm <project> <worktree>"
        echo "       w --help"
        return 1
    fi

    shift 2
    local command=("$@")

    # Check if project exists
    if [[ ! -d "$projects_dir/$project" ]]; then
        echo "Project not found: $projects_dir/$project"
        return 1
    fi

    # Determine worktree path
    local wt_path="$worktrees_dir/$project/$worktree"

    # If worktree doesn't exist, create it
    if [[ ! -d "$wt_path" ]]; then
        echo "Creating new worktree: $worktree"

        # Ensure worktrees directory exists
        mkdir -p "$worktrees_dir/$project"

        # Determine branch name (use current username prefix)
        local branch_name="$USER/$worktree"

        (cd "$projects_dir/$project" && git worktree add "$wt_path" -b "$branch_name") || {
            echo "Failed to create worktree"
            return 1
        }
    fi

    # Execute based on number of arguments
    if [[ ${#command[@]} -eq 0 ]]; then
        # No command specified - just cd to the worktree
        cd "$wt_path"
    else
        # Command specified - run it in the worktree without cd'ing
        local old_pwd="$PWD"
        cd "$wt_path"
        eval "${command[@]}"
        local exit_code=$?
        cd "$old_pwd"
        return $exit_code
    fi
}

# Setup completion if not already done
if [[ ! -f ~/.zsh/completions/_w ]]; then
    mkdir -p ~/.zsh/completions
    cat > ~/.zsh/completions/_w << 'EOF'
#compdef w

_w() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    local projects_dir="$HOME/Projects"
    local worktrees_dir="$HOME/Projects/worktrees"

    # Define the main arguments
    _arguments -C \
        '(--rm)--list[List all worktrees]' \
        '(--list)--rm[Remove a worktree]' \
        '1: :->project' \
        '2: :->worktree' \
        '3: :->command' \
        '*:: :->command_args' \
        && return 0

    case $state in
        project)
            if [[ "${words[1]}" == "--list" ]]; then
                # No completion needed for --list
                return 0
            fi

            # Get list of projects (directories in ~/projects that are git repos)
            local -a projects
            for dir in $projects_dir/*(N/); do
                if [[ -d "$dir/.git" ]]; then
                    projects+=(${dir:t})
                fi
            done

            _describe -t projects 'project' projects && return 0
            ;;

        worktree)
            local project="${words[2]}"

            if [[ -z "$project" ]]; then
                return 0
            fi

            local -a worktrees

            # Check for existing worktrees
            if [[ -d "$worktrees_dir/$project" ]]; then
                for wt in $worktrees_dir/$project/*(N/); do
                    worktrees+=(${wt:t})
                done
            fi

            if (( ${#worktrees} > 0 )); then
                _describe -t worktrees 'existing worktree' worktrees
            else
                _message 'new worktree name'
            fi
            ;;

        command)
            # Suggest common commands when user has typed project and worktree
            local -a common_commands
            common_commands=(
                'claude:Start Claude Code session'
                'gst:Git status'
                'gp:Git push'
                'gd:Git diff'
                'gl:Git log'
                'pnpm:Run pnpm commands'
                'just:Run just commands'
            )

            _describe -t commands 'command' common_commands

            # Also complete regular commands
            _command_names -e
            ;;

        command_args)
            # Let zsh handle completion for the specific command
            words=(${words[4,-1]})
            CURRENT=$((CURRENT - 3))
            _normal
            ;;
    esac
}

_w "$@"
EOF
    # Add completions to fpath if not already there
    fpath=(~/.zsh/completions $fpath)
fi

# Initialize completions
autoload -U compinit && compinit
