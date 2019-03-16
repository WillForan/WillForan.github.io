all:
	python src/make_index.py
	rsync -rvhi gopher/ h:/var/gopher/
