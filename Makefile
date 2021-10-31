.SUFFIXES:
.PHONY: all

all: index.html
org-export:
	# should have org-export in path
	# git clone https://github.com/nhoffman/org-export.git
	# export PATH
	which org-export

src/index.tmp style.css src/make_index.py: reports/readme.org  
	cd reports
	emacs --batch -l org -L --eval '(org-babel-tangle "readme.org")'

index.html: $(wildcard reports/*org) src/make_index.py src/gopher.tmp src/index.tmp org-export
	python src/make_index.py
	# NB "h" is gopher server defined in ~/.ssh/config
	rsync --size-only -rvhi gopher/ s2:/var/gopher/
