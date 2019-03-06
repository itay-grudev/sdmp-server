# Basic Setup
EXECNAME = sdmp-server
BINDIR   = bin/
OBJDIR   = $(BINDIR)obj/

# List the source input directories
SRCDIRS = src

# Default build
# Can be changed when invocating 'make' using the '-e BUILD=???' argument
BUILD = debug

# Compiler command
CC = g++

# Compiler and Linker flags
CCFLAGS = -Wall -pedantic -std=c++11
LDFLAGS = -lgnutls

SRCEXTS = .c .cc .cpp .c++ .cxx .cp
SOURCES = $(foreach d,$(SRCDIRS),$(wildcard $(addprefix $(d)/*,$(SRCEXTS))))
OBJECTS = $(addprefix $(OBJDIR), $(patsubst %,%.o,$(SOURCES)))
EXECUTABLE = $(BINDIR)$(EXECNAME)

# Check for debug or not
ifeq ($(BUILD),debug)
	CCFLAGS += -g
else
	CCFLAGS += -O2
endif

# Check if we need to make a seperate bin folder
ifneq ($(BINDIR), )
	BINDIRCOMMAND = mkdir -p $(BINDIR)
else
	BINDIRCOMMAND =
endif

# Check if we need to make a seperate obj folder and its subfolder structure
ifneq ($(OBJDIR), )
	OBJDIRCOMMAND = mkdir -p $(OBJDIR)
	OBJDIRCOMMAND += $(foreach d,$(SRCDIRS), $(OBJDIR)$(d))
else
	OBJDIRCOMMAND =
endif

# Building recipies
.PHONY: all
all: bindir objdir $(EXECUTABLE) srp ssl

.PHONY: run
run: $(EXECUTABLE) ssl srp
	$(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(CCFLAGS) $(OBJECTS) -o $@ $(LDFLAGS)

bindir:
	$(BINDIRCOMMAND)

objdir:
	$(OBJDIRCOMMAND)

$(OBJECTS) : $(SOURCES)
	$(CC) $(CCFLAGS) -c -o $@ $(patsubst $(OBJDIR)%.o,%,$@)

.PHONY: clean
clean:
	rm -rf $(BINDIR)
	rm -rf $(OBJDIR)

.PHONY: srp
srp: tpasswd tpasswd.conf

tpasswd:
	touch tpasswd

tpasswd.conf:
	srptool --create-conf=tpasswd.conf

.PHONY: ssl
ssl: server.key server.crt

server.key:
	openssl genrsa -out server.key 4096

server.crt: server.key
	openssl req \
	-new -days 365 -nodes -x509 \
	-subj "/C=/ST=/L=/O=/CN=" \
	-key server.key \
	-out server.crt
