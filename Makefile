.SUFFIXES:
.PHONY: all

all: index.html

src/index.tmp style.css src/make_index.py: reports/readme.org  
	cd reports
	emacs --batch -l org -L --eval '(org-babel-tangle "readme.org")'

index.html: $(wildcard reports/*org) src/make_index.py src/gopher.tmp src/index.tmp
	python src/make_index.py
	# NB "h" is gopher server defined in ~/.ssh/config
	rsync --size-only -rvhi gopher/ h:/var/gopher/
