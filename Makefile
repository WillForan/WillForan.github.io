.SUFFIXES:
.PHONY: all serve
REPORTS := $(wildcard reports/*org)
GOPH_LN := $(patsubst %.org,%.txt,$(subst reports/,gopher/,$(REPORTS)))
all: .make/gopher.ls .make/blog.log

serve:
	hugo -s hugo serve

hugo/public/index.html: $(REPORTS) $(wildcard hugo/themes/wf/*/*) hugo/config.toml
	hugo -s hugo

.make/blog.log: hugo/public/index.html | .make/
	rsync --size-only -azvhi hugo/public/ s2:/srv/http/hugo/ > $@

## gopher is (1) linked .org as .txt, (2) generaed index.gph, and  (3)rsync to server

gopher/%.txt: | gopher/
	test -e "$@" || ( cd gopher && ln -s "../reports/$(patsubst %.txt,%.org,$(notdir $@))" "$(notdir $@)" )

gopher/index.gph: $(GOPH_LN)
	./mkgoph.pl $^ > "$@"

.make/gopher.ls: hugo/public/index.html gopher/index.gph $(GOPH_LN) | .make/ gopher/
	# NB "s2" is gopher server defined in ~/.ssh/config
	rsync --size-only -Lrvhi gopher/ s2:/var/gopher/
	rsync --size-only -Lrvhi images/ s2:/var/gopher/images/
	date > .make/gopher.ls

%/:
	mkdir -p $@
