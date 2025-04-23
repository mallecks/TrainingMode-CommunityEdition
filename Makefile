.PHONY: clean iso all release

dats = build/eventMenu.dat build/labCSS.dat  build-events

# find all .asm and .s files in the ASM dir. We have the escape the spaces, so we pipe to sed
ASM_FILES := $(shell find ASM -type f \( -name '*.asm' -o -name '*.s' \) | sed 's/ /\\ /g')
SHELL := /bin/bash

MEX_BUILD=mono MexTK/MexTK.exe -ff -b "build" -q -ow -l "MexTK/melee.link" -op 2

ifndef iso
$(error Error: INVALID ISO - run `make iso=path/to/vanilla/melee iso`)
endif

HEADER := $(shell ./gc_fst get-header ${iso})
ifeq ($(HEADER), GALE01)
PATCH := patch.xdelta
else
ifeq ($(HEADER), GALJ01)
PATCH := patch_jp.xdelta
else
$(error Error: INVALID ISO - run `make iso=path/to/vanilla/melee iso`)
endif
endif

clean:
	rm -rf TM-CE/patch.xdelta
	rm -rf TM-CE.iso
	rm -rf ./build/

build/eventMenu.dat: src/events.c src/events.h src/event_data.c
	@echo "//Auto-generated include list" > build/generated_include_meta.c; \
    for dir in src/events/*; do \
		base=$$(basename $$dir); \
		if [ -f "$$dir/$${base}_meta.c" ]; then \
		  echo "#include \"../src/events/$$base/$${base}_meta.c\"" >> build/generated_include_meta.c; \
		fi; \
	done
	@echo "//Auto-generated include list" > build/generated_include_meta.h; \
    for dir in src/events/*; do \
		base=$$(basename $$dir); \
		if [ -f "$$dir/$${base}_meta.h" ]; then \
		  echo "#include \"../src/events/$$base/$${base}_meta.h\"" >> build/generated_include_meta.h; \
		fi; \
	done
	cp "dats/eventMenu.dat" "build/eventMenu.dat"
	$(MEX_BUILD) -i "src/events.c" "src/event_data.c" "build/generated_include_meta.c" -s "tmFunction" -dat "build/eventMenu.dat" -t "MexTK/tmFunction.txt"

build/labCSS.dat: src/events/lab/lab_css.c src/events/lab/lab_common.h src/events.h
	cp "src/events/lab/labCSS.dat" "build/labCSS.dat"
	$(MEX_BUILD) -i "src/events/lab/lab_css.c" -s "cssFunction" -dat "build/labCSS.dat" -t "MexTK/cssFunction.txt"

build-events: src/events.h
	@for dir in src/events/*; do \
		base=$$(basename $$dir); \
		if [ -f "$$dir/$$base.c" ]; then \
			if [ -f "$$dir/$$base.dat" ]; then \
			  echo "Copying src/events/$$base/$$base.dat to build/$$base.dat"; \
			  cp "src/events/$$base/$$base.dat" "build/$$base.dat"; \
			fi;\
			$(MEX_BUILD) -i "src/events/$$base/$$base.c" -s "evFunction" -dat "build/$$base.dat" -t "MexTK/evFunction.txt"; \
		fi; \
	done

build/codes.gct: Additional\ ISO\ Files/opening.bnr $(ASM_FILES)
	@echo "#Auto-generated include list" > build/generated_include_events.asm; \
    for dir in src/events/*; do \
		base=$$(basename $$dir); \
		if [ -f "$$dir/$$base.asm" ]; then \
		  echo ".include \"../src/events/$$base/$$base.asm\"" >> build/generated_include_events.asm; \
		fi; \
	done
	cd "Build TM Codeset" && ./gecko build
	cp Additional\ ISO\ Files/* build/

build/Start.dol: | build
	./gc_fst read ${iso} Start.dol build/Start.dol
	xdelta3 -d -f -s build/Start.dol "Build TM Start.dol/$(PATCH)" build/Start.dol

TM-CE.iso: build/Start.dol build/codes.gct $(dats)
	@GC_FST_CMD="delete MvHowto.mth delete MvOmake15.mth delete MvOpen.mth"; \
    for f in $(wildcard build/*.dat); do \
        base=$$(basename $$f); \
        GC_FST_CMD="$$GC_FST_CMD insert TM/$$base $$f"; \
    done; \
    GC_FST_CMD="$$GC_FST_CMD insert codes.gct build/codes.gct insert Start.dol build/Start.dol insert opening.bnr build/opening.bnr";\
	if [[ ! -f TM-CE.iso ]]; then cp ${iso} TM-CE.iso; fi ;\
	echo ./gc_fst fs TM-CE.iso $$GC_FST_CMD ;\
	./gc_fst fs TM-CE.iso $$GC_FST_CMD ;\
	./gc_fst set-header TM-CE.iso "GTME01" "Training Mode Community Edition";

build:
	mkdir -p build

iso: TM-CE.iso

TM-CE.zip: TM-CE.iso
	xdelta3 -f -s ${iso} -e TM-CE.iso TM-CE/patch.xdelta
	zip -r TM-CE.zip TM-CE/

release: TM-CE.zip

all: iso release
