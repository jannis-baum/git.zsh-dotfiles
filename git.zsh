alias gs="git status -s"
alias gca="git commit --amend"
alias grc="git rebase --continue"
alias gp="git push"
alias gpf="git push --force"
alias gpp="git pull && gprune-branches"
alias gx="git config --get remote.origin.url | xargs open"
alias gst="git stash"
alias gsp="git stash pop"

# stage all or given files/dirs
function ga() {
    [[ $# -eq 0 ]] && git add --all || git add $*
    gs
}

# unstage all or given files/dirs
function gr() {
    if [[ $# -eq 0 ]]; then
       git restore --staged $(git rev-parse --show-toplevel)
   else
       git restore --staged $*
    fi
    gs
}

# interactive staging
# - GDF_GSI_STAGE: toggle staging
# - GDF_GSI_RESET: prompt to reset changes
# - GDF_GSI_DIFF: open diff view
# - GDF_GSI_COMMIT: commit
# - GDF_GSI_AMEND: amend commit
# - return: open file
function gsi() {
    local out key file
    out=$(_git_interactive_status_helper \
        | nl -ba -s: | sed 's/^[[:space:]]*//' \
        | fzf --ansi --exit-0 --delimiter ':' --with-nth 3 \
            --bind="start:pos($1)" \
            --expect=$GDF_GSI_STAGE,$GDF_GSI_RESET,$GDF_GSI_DIFF,$GDF_GSI_COMMIT,$GDF_GSI_AMEND \
            --preview="git diff --color=always HEAD -- {2} | tail -n +5" \
            --preview-window='60%,nowrap,nohidden')

    key=$(head -1 <<< $out)
    file=$(tail -n +2 <<< $out | cut -d: -f2)
    pos=$(tail -n +2 <<< $out | cut -d: -f1)

    [[ -z "$file" ]] && return

    if [[ "$key" == $GDF_GSI_STAGE ]]; then; _git_toggle_staging $file && gsi $pos
    elif [[ "$key" == $GDF_GSI_RESET ]]; then; greset "$file" && gsi $pos
    elif [[ "$key" == $GDF_GSI_DIFF ]]; then; git difftool HEAD -- "$file" && gsi $pos
    elif [[ "$key" == $GDF_GSI_COMMIT ]]; then; gc
    elif [[ "$key" == $GDF_GSI_AMEND ]]; then; gca
    else $EDITOR $file; fi
}

# commit
# if branch follows `issue/NUMBER-title` scheme will copy issue ref
# as conventional commit context
function gc() {
    local context=$(_gh_get_branch_issue)
    [[ -n "$context" ]] && printf "(#$context): " | pbcopy
    git commit
}

# checkout
# automatically creates local copies of remote branches
function gco() {
    local branch
    branch=$(git branch -a \
        | sed -e 's/^..//' -e '/->/d' -e 's,^remotes/origin/,,' \
        | sort -u | fzf)
    [[ -n $branch ]] && (git checkout $branch 2>/dev/null || git checkout -b $branch)
}

# reset changes of all or given files
function greset() {
    local changes
    [[ $# -eq 0 ]] && changes="all changes" || changes="$*"
    printf "reset $changes? (y/*) "
    read -q && printf "\n" || {printf "\n" && return}

    if [[ $# -eq 0 ]]; then
        git reset --hard
        return
    fi
    git checkout HEAD -- $*
}

# fzf to see diff to parent commit or between given commits
# - shows preview and opens difftool on return
# - offers zsh completion
# bindings
# - GDF_GD_EDIT opens editor
function gd() {
    local out key file
    out=$(_git_pretty_diff $1 $2 | sed '$d' \
        | fzf --ansi --exit-0 --delimiter=' ' --expect=$GDF_GD_EDIT \
            --preview="git diff --color=always $1 $2 -- $(git rev-parse --show-toplevel)/{2} | tail -n +5" \
            --preview-window='60%,nowrap,nohidden' \
        | sed -r 's/^. *([^[:blank:]]*) *\|.*$/\1/')

    key=$(head -1 <<< $out)
    file=$(tail -n +2 <<< $out)

    [[ -z "$file" ]] && return
    file="$(git rev-parse --show-toplevel)/$file"

    if [[ "$key" == $GDF_GD_EDIT ]]; then $EDITOR $file;
    else git difftool $1 $2 -- "$file" && gd $1 $2;
    fi
}

autoload -U compinit; compinit
function _MINE_git_branch_names() {
    compadd "${(@)${(f)$(git branch -a)}#??}"
}
compdef _MINE_git_branch_names gd

# fzf to see git log
# log args:
# - uses `git log main..` if not on main branch (uses remote head branch if
#                                                main doesn't exist)
#   - first arg -a or --all to avoid this
# - otherwise passes args to git log
# bindings:
# - GDF_GL_REBASE starts rebase from parent of selected commit
# - GDF_GL_CPHASH copies commit hash
# - return opens diff (gd, see above) between commit and parent
function gl() {
    local commit hash key logargs

    if [ -n "$*" ]; then
        [ "$1" = "-a" -o "$1" = "--all" ] \
            && logargs="" || logargs="$1"
    else
        local head_branch=""
        git rev-parse --verify main &>/dev/null \
            && head_branch="main" \
            || head_branch=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
        [ $(git branch --show-current) = "$head_branch" ] \
            && logargs="" || logargs="$head_branch.."
    fi

    out=$(git log --oneline --decorate --color=always $logargs \
        | fzf --delimiter=' ' --with-nth='2..' --no-sort --track --exact --ansi \
            --expect=$GDF_GL_REBASE,$GDF_GL_CPHASH \
            --preview "zsh -c '$(which _git_pretty_diff);
                "$'_git_pretty_diff $(git log --pretty=%P -n 1 {1}) {1} | less -R\'' \
            --preview-window='60%,nowrap,nohidden')

    key=$(head -1 <<< $out)
    hash=$(tail -n +2 <<< $out | sed 's/ .*$//')

    if [ -n "$hash" ]; then
        if [[ "$key" == $GDF_GL_REBASE ]]; then git rebase -i $hash^;
        elif [[ "$key" == $GDF_GL_CPHASH ]]; then printf $hash | pbcopy;
        else gd $(git log --pretty=%P -n 1 $hash) $hash; gl;
        fi
    fi
}

# delete branches that don't have remote
# -f to also force delete branches that aren't fully merged
function gprune-branches() {
    local flag="-d"
    git fetch --prune
    [[ "$1" == "-f" || "$1" == "--force" ]] && flag="-D"
    git branch -vv \
        | rg ': gone] ' | rg -v '^\*' \
        | awk '{ print $1 }' \
        | xargs -r git branch $flag
}

# switch directory to a(nother) submodule of root repo
function gsm() {
    # traverse to super repo until topmost is reached
    local repo_dir="$(pwd)"
    while true; do
        local super_dir="$(git -C "$repo_dir" rev-parse --show-superproject-working-tree)"
        [[ -z "$super_dir" ]] && break
        repo_dir="$super_dir"
    done
    # root repo dir
    repo_dir=$(git -C "$repo_dir" rev-parse --show-toplevel)
    [[ -f "$repo_dir/.gitmodules" ]] || return

    # read .gitmodules and label status for each
    local modules=( . )
    modules+=(${(f)"$(rg --no-line-number --replace '' '^\s*path ?= ?' "$repo_dir/.gitmodules")"})
    local -a labels
    for m in $modules; do
        [[ -z $(git -C "$repo_dir/$m" status -s) ]] \
            && labels+=("  $m") \
            || labels+=("✻ $m")
    done

    local out=$(\
        paste -d ":" <(echo ${(F)modules}) <(echo ${(F)labels}) \
            | sort --field-separator=":" --reverse --key=2 \
            | fzf \
                --delimiter=":" --with-nth="2" --nth="1" \
                --preview-window="nohidden" \
                --preview "COLOR=always git -C '$repo_dir/{1}' --config-env=color.status=COLOR status")
    [[ -z "$out" ]] && return

    local target=$(sed 's/:.*$//'<<< $out)
    cd "$repo_dir/$target"
}
