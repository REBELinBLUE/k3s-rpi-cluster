eval (dircolors -c $HOME/.dircolors | sed 's/>&\/dev\/null$//')

starship init fish | source