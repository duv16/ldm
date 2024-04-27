VERSION=v0.7.1
VERSION_GIT=$(shell test -d .git && git describe 2> /dev/null)

ifneq "$(VERSION_GIT)" ""
VERSION=$(VERSION_GIT)
endif

CC ?= gcc
CFLAGS += -std=c99 \
          -D_GNU_SOURCE \
          -Wall -Wunused-parameter -Os \
          -DVERSION_STR="\"$(VERSION)\""
CFDEBUG  = -g3 -pedantic -Wlong-long
CFDEBUG += -Wsign-conversion -Wconversion -Wimplicit-function-declaration

LIBS = libudev mount glib-2.0
LDFLAGS := `pkg-config --libs $(LIBS)` $(LDFLAGS)

BINDIR ?= /usr/bin
SBINDIR ?= /sbin
SYSTEMDDIR ?= /usr/lib/systemd

all: ldm ldmc doc

.c.o:
	$(CC) $(CFLAGS) `pkg-config --cflags $(LIBS)` -o $@ -c $<

ldm: ipc.o ldm.o
	$(CC) -o ldm ipc.o ldm.o $(LDFLAGS)

ldmc: ipc.o ldmc.o
	$(CC) -o ldmc ipc.o ldmc.o $(LDFLAGS)

debug: ldm ldmc
debug: CC += $(CFDEBUG)

service:
	@sed "s|@@BINDIR@@|$(BINDIR)|" ldm.service.in > ldm.service

doc: ldm.pod ldmc.pod
	@pod2man --section=1 --center="ldm Manual" --name "ldm" --release="$(VERSION)" ldm.pod > ldm.1
	@pod2man --section=1 --center="ldmc Manual" --name "ldmc" --release="$(VERSION)" ldmc.pod > ldmc.1

readme: ldm.pod
	@pod2markdown -u ldm.pod README.md

clean:
	$(RM) *.o *.1 ldm ldmc ldm.service

mrproper: clean
	$(RM) ldm ldmc

install-main: ldm doc
	install -D -m 755 ldm $(DESTDIR)$(BINDIR)/ldm
	install -D -m 755 ldmc $(DESTDIR)$(BINDIR)/ldmc
	install -D -m 755 umount.ldm $(DESTDIR)$(SBINDIR)/umount.ldm
	install -D -m 644 ldm.1 $(DESTDIR)/usr/share/man/man1/ldm.1
	install -D -m 644 ldmc.1 $(DESTDIR)/usr/share/man/man1/ldmc.1

install-systemd: service
	install -D -m 644 ldm.service $(DESTDIR)$(SYSTEMDDIR)/system/ldm.service

install: all install-main install-systemd

uninstall:
	$(RM) $(DESTDIR)$(BINDIR)/ldm
	$(RM) $(DESTDIR)$(BINDIR)/ldmc
	$(RM) $(DESTDIR)$(SBINDIR)/umount.ldm
	$(RM) $(DESTDIR)/usr/share/man/man1/ldm.1
	$(RM) $(DESTDIR)/usr/share/man/man1/ldmc.1
	$(RM) $(DESTDIR)$(SYSTEMDDIR)/system/ldm.service

.PHONY: all debug clean mrproper install install-main install-systemd uninstall service readme
