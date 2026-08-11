# Minimal Powerlevel10k configuration. Powerlevel10k is loaded by Home Manager
# before this file is sourced from programs.zsh.initContent.

typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  dir
  vcs
  command_execution_time
  status
  context
  time
  newline
  background_jobs
  prompt_char
)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

# Use a plain, space-separated prompt without icons or Powerline separators.
typeset -g POWERLEVEL9K_BACKGROUND=
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=

# Keep up to ten trailing path components, matching the previous Starship limit.
typeset -g POWERLEVEL9K_DIR_FOREGROUND=blue
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=blue
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_last
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=10

# Format Git status from the variables supplied asynchronously by gitstatus.
function my_git_formatter() {
  emulate -L zsh

  # P9K_CONTENT contains fallback content while gitstatus is loading or when
  # P10k has fallen back to vcs_info.
  if [[ -n $P9K_CONTENT ]]; then
    typeset -g my_git_format=$P9K_CONTENT
    return
  fi

  local commit=${VCS_STATUS_COMMIT[1,7]}
  local branch=${VCS_STATUS_LOCAL_BRANCH//\%/%%}
  local remote=${VCS_STATUS_REMOTE_BRANCH//\%/%%}
  local tag=${VCS_STATUS_TAG//\%/%%}
  local action=${VCS_STATUS_ACTION//\%/%%}
  local result

  if [[ -n $branch ]]; then
    result=$branch
    [[ -n $remote && $remote != $branch ]] && result+=":$remote"
    result+="($commit"
    [[ -n $tag ]] && result+="#$tag"
    result+=")"
  else
    result="@$commit"
    [[ -n $tag ]] && result+="#$tag"
  fi

  # Preserve the old Starship status shape: one marker per category, grouped
  # in brackets, with counts only for a diverged branch.
  local git_status=
  (( VCS_STATUS_NUM_CONFLICTED > 0 )) && git_status+='❎'
  (( VCS_STATUS_NUM_STAGED_DELETED > 0 || VCS_STATUS_NUM_UNSTAGED_DELETED > 0 )) && git_status+='🚮'
  (( VCS_STATUS_NUM_UNSTAGED > VCS_STATUS_NUM_UNSTAGED_DELETED )) && git_status+='🎨'
  (( VCS_STATUS_NUM_STAGED > 0 )) && git_status+='💨'
  (( VCS_STATUS_NUM_UNTRACKED > 0 )) && git_status+='🤔'

  if (( VCS_STATUS_COMMITS_AHEAD > 0 && VCS_STATUS_COMMITS_BEHIND > 0 )); then
    git_status+="🤸(↑${VCS_STATUS_COMMITS_AHEAD}↓${VCS_STATUS_COMMITS_BEHIND})"
  elif (( VCS_STATUS_COMMITS_AHEAD > 0 )); then
    git_status+='🔼'
  elif (( VCS_STATUS_COMMITS_BEHIND > 0 )); then
    git_status+='🔽'
  elif [[ -n $VCS_STATUS_REMOTE_BRANCH ]]; then
    git_status+='✅'
  fi

  [[ -n $git_status ]] && result+="[$git_status]"
  [[ -n $action ]] && result+="($action)"

  typeset -g my_git_format=$result
}
functions -M my_git_formatter 2>/dev/null

typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true
typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter(1)))+${my_git_format}}'
typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((my_git_formatter(0)))+${my_git_format}}'
typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED,CONFLICTED,COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=-1
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=green
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=yellow
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=yellow
typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=red
typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=244
typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)

# Hide successful status, but retain failures and long-command timing.
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR=true
typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE=true
typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
typeset -g POWERLEVEL9K_STATUS_VERBOSE=true
typeset -g POWERLEVEL9K_STATUS_PREFIX='exit '
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=2
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='took '
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=true
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_PREFIX='jobs '

# Always render identity and time on the first line.
typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%B%n@%m'
typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=white
typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=white
typeset -g POWERLEVEL9K_TIME_FOREGROUND=white
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
typeset -g POWERLEVEL9K_TIME_CONTENT_EXPANSION='[$P9K_CONTENT]'

# Keep the same white dollar prompt for success and failure.
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=white
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=white
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_{VIINS,VICMD,VIVIS,VIOWR}_CONTENT_EXPANSION='$'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true

typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

# Apply this file when it is sourced after the theme during shell startup.
(( ! $+functions[p10k] )) || p10k reload
