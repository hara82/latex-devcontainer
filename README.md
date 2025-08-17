# latex-devcontainer

A repository for LaTeX development in a dev container environment.
## Dev Container
This dev container is based on the `texlive/texlive` [Docker image.](https://hub.docker.com/r/texlive/texlive/)


## Files
- `latex-diffgen.sh`: Shell script for generating LaTeX diffs using `latexdiff-vc`.\
See `latex-diffgen.sh -h` for usage information.


# Memo
LuaLaTeXで日本語を含む.texファイルで、IEEEtran.clsを利用するものをコンパイルするときには下3行が必要かもしれない.
```tex
\usepackage{newtxtext, newtxmath}
\usepackage{luatexja}
\usepackage[match]{luatexja-fontspec} % fontspec連携
```