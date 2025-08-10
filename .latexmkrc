# man page can be found at https://www.cantab.net/users/johncollins/latexmk/latexmk-480.txt
$out_dir  = 'out';
$pdf_mode = 1; # Create .pdf file directly from .tex file using pdfLaTex.
# man page for pdflatex can be found at https://linux.die.net/man/1/pdflatex
$pdflatex = 'pdflatex -file-line-error -halt-on-error -interaction=nonstopmode -synctex=1 %O %S';

# These options are commented out as they are the same as default.
# $max_repeat = 5;
# $bibtex_use = 1;
# @default_files = ('*.tex');

# Commands that we occasionally use when pdfLaTex fails, especially when there are Unicode characters like Japanese.
# Run by `latexmk -lualatex`
$lualatex = 'lualatex -file-line-error -halt-on-error -interaction=nonstopmode -synctex=1 %O %S';
# Run by `latexmk -pdfdvi`. You might need dvipdfx in "\documentclass[journal, dvipdfmx]{IEEEtran}".
$latex    = 'uplatex -synctex=1 %O %S';
$dvipdf   = 'dvipdfmx %O -o %D %S';