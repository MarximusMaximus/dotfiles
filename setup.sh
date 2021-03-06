#!/usr/bin/env sh

################################################################################
#region Preamble

#===============================================================================
#region RReadLink

#-------------------------------------------------------------------------------
#...............................................................................


rreadlink() {
    ( # Execute the function in a *subshell* to localize variables and the effect of `cd`.

        target=$1
        fname=
        targetDir=
        CDPATH=

        # Try to make the execution environment as predictable as possible:
        # All commands below are invoked via `command`, so we must make sure that `command`
        # itself is not redefined as an alias or shell function.
        # (NOTE: that command is too inconsistent across shells, so we don't use it.)
        # `command` is a *builtin* in bash, dash, ksh, zsh, and some platforms do not even have
        # an external utility version of it (e.g, Ubuntu).
        # `command` bypasses aliases and shell functions and also finds builtins
        # in bash, dash, and ksh. In zsh, option POSIX_BUILTINS must be turned on for that
        # to happen.
        { \unalias command; \unset -f command; } >/dev/null 2>&1
        # shellcheck disable=SC2034
        [ -n "$ZSH_VERSION" ] && options[POSIX_BUILTINS]=on # make zsh find *builtins* with `command` too.

        while :; do # Resolve potential symlinks until the ultimate target is found.
                [ -L "$target" ] || [ -e "$target" ] || { command printf '%s\n' "ERROR: '$target' does not exist." >&2; return 1; }
                # shellcheck disable=SC2164
                command cd "$(command dirname -- "$target")" # Change to target dir; necessary for correct resolution of target path.
                fname=$(command basename -- "$target") # Extract filename.
                [ "$fname" = '/' ] && fname='' # WARNING: curiously, `basename /` returns '/'
                if [ -L "$fname" ]; then
                    # Extract [next] target path, which may be defined
                    # relative to the symlink's own directory.
                    # NOTE: We parse `ls -l` output to find the symlink target
                    # NOTE:     which is the only POSIX-compliant, albeit somewhat fragile, way.
                    target=$(command ls -l "$fname")
                    target=${target#* -> }
                    continue # Resolve [next] symlink target.
                fi
                break # Ultimate target reached.
        done
        targetDir=$(command pwd -P) # Get canonical dir. path
        # Output the ultimate target's canonical path.
        # NOTE: that we manually resolve paths ending in /. and /.. to make sure we have a normalized path.
        if [ "$fname" = '.' ]; then
            command printf '%s\n' "${targetDir%/}"
        elif    [ "$fname" = '..' ]; then
            # NOTE: something like /var/.. will resolve to /private (assuming /var@ -> /private/var),
            # NOTE:     i.e. the '..' is applied AFTER canonicalization.
            command printf '%s\n' "$(command dirname -- "${targetDir}")"
        else
            command printf '%s\n' "${targetDir%/}/$fname"
        fi
    )
}

#endregion RReadLink
#===============================================================================

#===============================================================================
#region Self Referentials

MY_DIR_FULLPATH=$(dirname -- "$(rreadlink "$0")")
export MY_DIR_FULLPATH
MY_DIR_BASENAME=$(basename -- "${MY_DIR_FULLPATH}")
export MY_DIR_BASENAME

#endregion Self Referentials
#===============================================================================

#endregion Preamble
################################################################################

(
    ############################################################################
    #region Includes



    #endregion Includes
    ############################################################################

    ############################################################################
    #region Constants



    #endregion Constants
    ############################################################################

    ############################################################################
    #region Return Codes



    #endregion Return Codes
    ############################################################################

    ############################################################################
    #region Functions

    __main() {
        (
            cd "$HOME" || exit 1
            ln -sf "${MY_DIR_FULLPATH}"/.env_vars_profile .env_vars_profile || exit 1
            ln -sf "${MY_DIR_FULLPATH}"/.vimrc .vimrc || exit 1
            ln -sf "${MY_DIR_FULLPATH}"/.zshrc .zshrc || exit 1
            ln -sf "${MY_DIR_FULLPATH}"/.gitignore .gitignore-base || exit 1
            ln -sf "${MY_DIR_FULLPATH}"/.vscode/settings.json .vscode-settings-base.json || exit 1
            ln -sf "${MY_DIR_FULLPATH}"/LICENSE LICENSE-DEFAULT || exit 1
            ln -sf "${MY_DIR_FULLPATH}"/README.md README-DEFAULT.md || exit 1

            # TODO: insert missing lines
            if [ ! -f .gitconfig ]; then
                cp "${MY_DIR_FULLPATH}"/.gitconfig-base .gitconfig || exit 1
            fi

            exit 0
        )
        ret=$?
        return $ret
    }

    #endregion Functions
    ############################################################################

    ############################################################################
    #region Immediate

    #===============================================================================
    #region anti-sourceing

    sourced=0
    if [ -n "$ZSH_EVAL_CONTEXT" ]; then
        case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
    elif [ -n "$KSH_VERSION" ]; then
        # shellcheck disable=SC2296
        [ "$(cd "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")" != "$(cd "$(dirname -- "${.sh.file}")" && pwd -P)/$(basename -- "${.sh.file}")" ] && sourced=1
    elif [ -n "$BASH_VERSION" ]; then
        (return 0 2>/dev/null) && sourced=1
    else # All other shells: examine $0 for known shell binary filenames
        # Detects `sh` and `dash`; add additional shell filenames as needed.
        case ${0##*/} in sh|dash) sourced=1;; esac
    fi
    if [ $sourced -eq 1 ]; then
        >&2 printf "setup.sh should not be sourced"
        exit "${RET_ERROR_SCRIPT_WAS_SOURCED}"
    fi

    #endregion anti-sourceing
    #===========================================================================

    #===========================================================================
    #region anti-root

    # shellcheck disable=SC3028
    if [ $UID -eq 0 ] || [ $EUID -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
        >&2 printf "setup.sh should not be run as root nor with sudo"
        exit "${RET_ERROR_USER_IS_ROOT}"
    fi

    #endregion anti-root
    #===========================================================================

    __main "$@"
    ret=$?
    printf "setup.sh exiting with return code: %d\n" "${ret}"
    exit $ret

    #endregion Immediate
    ############################################################################
)
ret=$?
exit $ret
