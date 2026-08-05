# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.


# ------ Zsh Start ------

export ZSH="$HOME/.oh-my-zsh"
zstyle ':omz:update' mode reminder

# ------ Completion styling ------ 

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --long -G -a --group-directories-first --git --git-ignore --no-filesize --icons=always --no-time --no-user --no-permissions $realpath'
#zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group '<' '>'

# ------ Theme ------ 

ZSH_THEME="powerlevel10k/powerlevel10k"

# ------Load Modules ------

plugins=(git copypath rsync autojump sudo zsh-interactive-cd zsh-autosuggestions you-should-use zsh-syntax-highlighting fzf-tab)
source $ZSH/oh-my-zsh.sh
source <(fzf --zsh)
autoload -U compinit && compinit -u

# ------ History ------

HIST_STAMPS="dd.mm.yyyy"
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# ------ Modules configuration ------

# --- BAT ---

#export BAT_THEME=CatppuccinMacchiato

# --- Eza (better ls) ---

alias ls="eza --color=always --long -G -a --group-directories-first --git --git-ignore --no-filesize --icons=always --no-time --no-user --no-permissions"

# --- FZF ---

# - Use fd instead of fzf -

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# --- FZF Preview ---

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

# --- FZF opts ---

export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/fzf-opts"

# ------ Aliases ------

alias config='nvim ~/.config/zsh/.zshrc'
alias hyprkey='nvim ~/.config/hypr/keybindings.conf'
alias hyprcfg='nvim ~/.config/hypr/userprefs.conf'
alias hyprstart='nvim ~/.config/hypr/startup.conf'
alias nv='nvim'
alias c='clear'
alias bat='bat -n --color=always'
alias rg='rg -S'
alias fman='compgen -c | fzf | xargs batman'
alias py='python3'
alias fastfetch='clear && fastfetch'
#alias fsys='fuzzy-sys'
alias yt-mp3="yt-dlp --no-keep-video -t mp3 -o '%(artist)s - %(title)s.%(ext)s' -P /mnt/Data/Musique/Youtube-dl/yt-dlp/"
alias hardware="~/.scripts/inxilogs/hardware.sh"
alias pkgdep="pacman -Qq | fzf --preview 'pactree -lur {} | sort' --layout reverse --bind 'enter:execute(pactree -lu {} | sort | less)'"
alias llama-start="llama-server --models-dir /home/perletero/.cache/huggingface/models/ --models-preset /home/perletero/.cache/huggingface/presets/config.ini --main-gpu 0 --host 0.0.0.0 --port 8033 --tools all"

# ------ Exports ------

export EDITOR='nvim'
export BROWSER='firefox'

# ------ Shell integrations ------

eval "$(fzf --zsh)" #CTRL-T = FZF Select | CTRL-R = FZF History | ALT-C = FZF cd
eval "$(zoxide init --cmd cd zsh)"
eval $(thefuck --alias)
eval $(thefuck --alias fuck)

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

# opencode
export PATH=/home/perletero/.opencode/bin:$PATH
