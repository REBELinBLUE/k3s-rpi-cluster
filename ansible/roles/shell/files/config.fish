fish_add_path -p ~/.local/bin

export QUOTING_STYLE=literal

eval (dircolors -c $HOME/.dircolors | sed 's/>&\/dev\/null$//')

starship init fish | source