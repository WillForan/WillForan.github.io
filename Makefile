all:
	python src/make_index.py
	rsync --size-only -rvhi gopher/ h:/var/gopher/
