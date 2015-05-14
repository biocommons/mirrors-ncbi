.SUFFIXES:
.PHONY: FORCE
.DELETE_ON_ERROR:

SHELL:=/bin/bash

# TODAY: today's date, YYYY-MM-DD
TODAY:=$(shell date +%F)

# LATEST: alphanumerically-sorted last entry (i.e., most recent)
# dated directory, if any
LATEST:=$(lastword $(sort $(filter-out ${TODAY},$(wildcard 201[0-9]-[0-9][0-9]-[0-9][0-9]))))

# if LATEST is empty or not TODAY, then use LATEST as a hard link
# source to save bandwidth and local space
ifneq (${TODAY},${LATEST})
RSYNC_LINK_DEST=--link-dest=${PWD}/${LATEST}
endif
$(notice RSYNC_LINK_DEST=$RSYNC_LINK_DEST)

default:
	@echo "Ain't no $@ target; try 'make update'" 1>&2; exit 1

update: sources FORCE
	mkdir -p ${TODAY}
	perl -lne 'next if m/^\#/; s/\n/ /; print' <$< \
	| while read f; do \
		(set -x; rsync --no-motd -HRavP ${RSYNC_LINK_DEST}/$${f%%/*} ftp.ncbi.nih.gov::$$f ${TODAY}/$${f%%/*}) \
	done
	ln -fnsv ${TODAY} latest
