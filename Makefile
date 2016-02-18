.SUFFIXES:
.PHONY: FORCE
.DELETE_ON_ERROR:

SHELL:=/bin/bash

# TODAY: today's date, YYYY-MM-DD
TODAY:=$(shell date +%Y/%m/%d)
UPDIR=${TODAY}.tmp


# LATEST: most recently *completed* sync directory, if any
# if LATEST is not empty (i.e., a prior directory exists), then use
# LATEST as a hard link source to save bandwidth and local space
LATEST:=$(lastword $(sort $(filter-out %.tmp,$(wildcard 201[0-9]/[0-9][0-9]/[0-9][0-9]))))
ifneq ("${TODAY}","")
RSYNC_LINK_DEST=--link-dest=${PWD}/${LATEST}
$(info RSYNC_LINK_DEST=${RSYNC_LINK_DEST})
endif


default:
	@echo "Ain't no $@ target; try 'make update'" 1>&2; exit 1


env:
	@echo TODAY=${TODAY}
	@echo LATEST=${LATEST}
	@echo RSYNC_LINK_DEST=${RSYNC_LINK_DEST}

update: sources FORCE
	mkdir -pv ${UPDIR}
	perl -lne 'next if m/^\#/ or not m/\w/; s/\n/ /; print' <$< \
	| while read f; do \
		(set -x; rsync --no-motd -HRavP ${RSYNC_LINK_DEST}/$${f%%/*} ftp.ncbi.nlm.nih.gov::$$f ${UPDIR}/$${f%%/*}) \
	done
	mv ${UPDIR} ${TODAY}
	ln -fnsv ${TODAY} latest
