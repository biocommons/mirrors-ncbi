.SUFFIXES:
.PHONY: FORCE
.DELETE_ON_ERROR:

# TODAY: today's date, YYYY-MM-DD
TODAY:=$(shell date +%F)

# LATEST: alphanumerically-sorted last entry (i.e., most recent)
# dated directory, if any
LATEST:=$(lastword $(sort $(wildcard 201[0-9]-[0-9][0-9]-[0-9][0-9])))

# SOURCES: list of relative paths at NCBI to mirror
SOURCES:=$(shell perl -ne 'next if m/^\#/; s/\n/ /; print' sources)

# if LATEST is empty or not TODAY, then use LATEST as a hard link
# source to save bandwidth and local space
ifneq (${TODAY},${LATEST})
RSYNC_LINK_DEST=--link-dest=${PWD}/${LATEST}
endif

default:
	@echo "Ain't no $@ target; try 'make update'" 1>&2; exit 1

update: $(addprefix ${TODAY}/,${SOURCES});
	ln -fnsv ${TODAY} latest

${TODAY}/%: FORCE
	-@mkdir -p ${TODAY}
	rsync ${RSYNC_LINK_DEST} -HRavP ftp.ncbi.nih.gov::$* ${TODAY}/
