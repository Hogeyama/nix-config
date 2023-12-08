use_aws_profile(){
  PROFILE=$1
  export AWS_ASSUME_ROLE_TTL=1h
  #shellcheck disable=SC2046
  export $(aws-vault exec "$PROFILE" --prompt=pass -- env | grep AWS_ | grep -v AWS_VAULT)
}

use_secret() {
  VAR=$1
  SECRET_NAME=$2
  SECRET=$(pass show "$SECRET_NAME")
  if [[ -z "$SECRET" ]]; then
    echo "failed to load $SECRET_NAME"
  else
    eval "export $VAR='$SECRET'"
  fi
}

# Usage:
#
# ```
# # Using stdin
# add_command foo <<-EOF
# 	#!/usr/bin/env bash
# 	echo "foo"
# EOF
# ```
#
# ```
# # Using arguments
# add_command bar 'echo "bar"'
# ```
add_command() {
    local bindir="$(direnv_layout_dir)/bin"
    if [[ -z "${ANY_COMMAND_ADDED:-}" ]]; then
        rm -rf "$bindir"
    fi
    ANY_COMMAND_ADDED=1
    local bindir="$(direnv_layout_dir)/bin"
    mkdir -p "$bindir"
    if ! grep -qE "(^|:)${bindir}(:|$)" <<< "$PATH"; then
        PATH_add "$bindir"
    fi

    local command=$1
    shift
    if [[ -t 0 ]]; then
        echo "$@" >"$bindir/$command"
    else
        cat >"$bindir/$command"
    fi
    chmod +x "$bindir/$command"
}

sepby() {
    local IFS=$1
    shift
    printf "%s" "$*"
}

source_env_if_exists .envrc.local

# vim:ft=bash:
