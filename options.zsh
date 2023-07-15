function __opt_or_fallback() {
    # set variable with name $1 to $2 if it is not set
    eval "(( \${+$1} )) || $1=\"$2\""
}

# KEYBINDINGS ------------------------------------------------------------------
# - explanation      name              default setting
# ------------------------------------------------------------------------------

# for gsi
# - toggle staging
__opt_or_fallback    GDF_GSI_STAGE     ctrl-s
# - prompt to reset changes
__opt_or_fallback    GDF_GSI_RESET     ctrl-r
# - open diff view
__opt_or_fallback    GDF_GSI_DIFF      ctrl-v
# - commit
__opt_or_fallback    GDF_GSI_COMMIT    ctrl-o
# - amend commit
__opt_or_fallback    GDF_GSI_AMEND     ctrl-o

# for gd
# - open editor
__opt_or_fallback    GDF_GD_EDIT       ctrl-o

# for gl
# - start interactive rebase from parent commit
__opt_or_fallback    GDF_GL_REBASE     ctrl-r
# - copy (short) commit hash
__opt_or_fallback    GDF_GL_CPHASH     ctrl-o

# for gd
# - create/check out branch for issue
__opt_or_fallback    GDF_GHI_BRANCH    ctrl-b
# - copy issue number
__opt_or_fallback    GDF_GHI_CPNUM     ctrl-o

unset -f __opt_or_fallback
