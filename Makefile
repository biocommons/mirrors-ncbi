.SUFFIXES:
.PHONY: FORCE
.DELETE_ON_ERROR:

DST_DIR:=$(shell date +%F)
SOURCES:=$(shell perl -ne 'next if m/^\#/; s/\n/ /; print' sources)

default:
	@echo "Ain't no $@ target; try 'make update'" 1>&2; exit 1

update:
	if [ -e latest -a "$(shell readlink latest)" != "${DST_DIR}" ]; then cp -al latest/ ${DST_DIR}; else mkdir -pv ${DST_DIR}; fi
	make update-sources
	ln -fnsv ${DST_DIR} latest

update-sources: $(addprefix ${DST_DIR}/,${SOURCES});

${DST_DIR}/%: FORCE
	rsync -HRav ftp.ncbi.nih.gov::$* ${DST_DIR}/
