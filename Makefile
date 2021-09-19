SUBDIRS = src

VERSION = 2.0

FILES = \
	README.md \
	init-screen.png \
	monitoring-screen.png \
	src/zak-supervisor.d64

DISTFILE = Zak-Supervisor-${VERSION}.zip

.PHONY: all clean dist

all:
	@for dir in ${SUBDIRS}; \
	do \
		(cd $$dir && make VERSION="${VERSION}" all) || exit 1; \
	done

dist: ${DISTFILE}

clean:
	@for dir in ${SUBDIRS}; \
	do \
		(cd $$dir && make clean) || exit 1; \
	done

${DISTFILE}: ${FILES}
	zip -9jq ${DISTFILE} ${FILES}
