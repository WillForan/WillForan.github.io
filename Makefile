.SUFFIXES:
.PHONY: all recent-pull

all: .make/gopher.ls
org-export:
	# should have org-export in path
	# git clone https://github.com/nhoffman/org-export.git
	# export PATH
	which org-export

src/index.tmp style.css src/make_index.py: reports/readme.org  
	cd reports
	emacs --batch -l org -L --eval '(org-babel-tangle "readme.org")'

gopher:
	mkdir -p gopher

index.html: $(wildcard reports/*org) src/make_index.py src/gopher.tmp src/index.tmp org-export | gopher
	python src/make_index.py

.make/gopher.ls: index.html | .make
	# NB "s2" is gopher server defined in ~/.ssh/config
	rsync --size-only -Lrvhi gopher/ s2:/var/gopher/
	date > .make/gopher.ls

# how to go from org to html
html/%.html: reports/%.org
	org-export html  --infile $< --outfile $@ --bootstrap

allreports = $(wildcard reports/*.org)
all-html: $(allreports:reports%org=html%html)
.make:
	@mkdir make

# if we did a pull, timestamps on export files wont be accurate
# instead of regenerating files. just touch them
recent-pull:
	touch html/*html
