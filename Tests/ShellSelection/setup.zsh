PS1='BRUME_TEST> '
RPS1=''

_brume_test_plugins() {
    source Vendor/zsh-autosuggestions/zsh-autosuggestions.zsh
    _zsh_autosuggest_start
    source Vendor/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
}
[[ $BRUME_TEST_PRELOADED == 1 ]] && _brume_test_plugins
source Vendor/libghostty-spm/Sources/GhosttyTerminal/Resources/Ghostty/shell-integration/zsh/ghostty-integration

_brume_test_seed() {
    BUFFER='jj edit something'
    CURSOR=12
    REGION_ACTIVE=0
}
_brume_test_state() {
    local start=$(( CURSOR < MARK ? CURSOR : MARK ))
    local end=$(( CURSOR > MARK ? CURSOR : MARK ))
    local selected=''
    (( end > start && REGION_ACTIVE )) && selected=${BUFFER[start+1,end]}
    (( ! REGION_ACTIVE && ${region_highlight[(I)*standout*]} )) && selected=STALE_HIGHLIGHT
    print -r -- "STATE|$CURSOR|$MARK|$REGION_ACTIVE|$selected|"
}
_brume_test_clear() { BUFFER=''; CURSOR=0; REGION_ACTIVE=0; }
zle -N _brume_test_clear
zle -N _brume_test_seed
zle -N _brume_test_state
for map in emacs viins; do
    bindkey -M $map '^Xs' _brume_test_seed
    bindkey -M $map '^Xt' _brume_test_state
    bindkey -M $map '^Xc' _brume_test_clear
done
[[ $BRUME_TEST_PRELOADED == 0 ]] && _brume_test_plugins

_brume_test_redraw() { print -r -- DRAW_READY; }
add-zle-hook-widget line-pre-redraw _brume_test_redraw
print READY
