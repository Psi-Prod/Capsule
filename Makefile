USER?=
DEST?=
DEST_DIR := /home/$(USER)/public/
DEST_PORT?=

.PHONY: all clean build serve push
all: build

clean:
	rm -rf _build/site

build:
	dune exec bin/capsule.exe -- build

serve:
	dune exec bin/capsule.exe -- serve

push:
	rsync --delete -r -e "ssh -p $(DEST_PORT)" _build/site/ $(USER)@$(DEST):$(DEST_DIR)
