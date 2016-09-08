.SUFFIXES:
.PHONY: FORCE
.DELETE_ON_ERROR:

PATH:=/usr/bin:/bin
SHELL:=/bin/bash -o pipefail

# TODAY: today's date, YYYY-MM-DD
TODAY:=$(shell date +%Y/%m/%d)

UPDIR:=${TODAY}.tmp
_:=$(shell mkdir -p ${UPDIR})

DIR:=$(abspath $(dir $(firstword $(MAKEFILE_LIST))))



# LATEST: most recently *completed* sync directory, if any
# if LATEST is not empty (i.e., a prior directory exists), then use
# LATEST as a hard link source to save bandwidth and local space
# Hmm... why can't I just use the latest symlink here?
LATEST:=$(lastword $(sort $(filter-out %.tmp,$(wildcard 201[0-9]/[0-9][0-9]/[0-9][0-9]))))
ifneq ("${TODAY}","")
RSYNC_LINK_DEST=--link-dest=${DIR}/${LATEST}
endif


default:
	@echo "Ain't no $@ target; try 'make update'" 1>&2; exit 1

vars:
	@echo TODAY=${TODAY}
	@echo DIR=${DIR}
	@echo UPDIR=${UPDIR}
	@echo LATEST=${LATEST}
	@echo RSYNC_LINK_DEST=${RSYNC_LINK_DEST}

update: ${TODAY}/log;

${TODAY}/log: ${UPDIR}/log
	if [ -d "${TODAY}" ]; then chmod -R u+wX ${TODAY}; rm -fr "${TODAY}"; fi
	mv ${UPDIR} ${TODAY}
	ln -fnsv ${TODAY} latest

.PRECIOUS: ${UPDIR}/log
${UPDIR}/log: sources vars FORCE
	if [ -d "${TODAY}" ]; then \
		echo "${TODAY}/: Directory exists -- already completed?" 1>&2; \
		exit 1; \
	fi

	( \
	set -e; \
	perl -lne 'next if m/^\#/ or not m/\w/; s/\n/ /; print' <$< \
	| while read f; do \
		(set -x; rsync --no-motd -HRavP ${RSYNC_LINK_DEST}/$${f%%/*} ftp.ncbi.nlm.nih.gov::$$f ${UPDIR}/$${f%%/*}) \
	done; \
	) 2>&1 | tee $@


.PHONY: _rsync_not_running
_rsync_not_running:
	ps -ef | grep 'rsync.*ncbi' >/dev/null

.PHONY: cleanup
cleanup: cleanup.log
cleanup.log: _rsync_not_running FORCE
	(make fix-perms; make remove-temps; make hardlink) >$@ 2>&1

fix-perms:
	find 201? -type d -print0 | xargs -0r chmod -c u+rwX,go+rX,go-w

remove-temps:
	find 201? -name \*tmp\* -type d -print0 | xargs -0r /bin/rm -fr

hardlink:
	(set -x; \
	df -h .; \
	hardlink -vfptoO .; \
	df -h . \
	) 2>&1 | tee $@.log
