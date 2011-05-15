OPT = -W
CC = erlc

ESRC = src
EBIN = bin
EDOC = doc

SRC = $(wildcard $(ESRC)/*.erl)
TARGET = $(addsuffix .beam, $(basename $(addprefix $(EBIN)/, $(notdir $(SRC)))))

SEP :=  ","
EMPTY:=
SPACE:= $(EMPTY) $(EMPTY)
DOC_SRC = $(addsuffix ", $(addprefix ", $(strip $(subst $(SPACE),$(SEP),$(SRC)))))

# make sure all folders exists
$(shell [ -d "$(EBIN)" ] || mkdir -p $(EBIN))
$(shell [ -d "$(EDOC)" ] || mkdir -p $(EDOC))

all: build test docs

build: $(TARGET)

$(EBIN)/%.beam: $(ESRC)/%.erl
	$(CC) $(OPT) -o $(EBIN) $<
	
clean:
	- rm -Rf $(EBIN)/*.beam
	
distclean:
	- rm -Rf $(EBIN)
	- rm -Rf $(EDOC)
	
clean_docs:
	- rm -Rf $(EDOC)/*.*
	- cp *.edoc $(EDOC)/
	
start: build
	erl -noshell -pa $(EBIN) -s apoidea start -s init stop
	
start_drone: build
	erl -noshell -pa $(EBIN) -s drone start

test:
	erl -noshell -pa $(EBIN) -eval 'eunit:test("$(EBIN)", [verbose])' -s init stop
	
docs: clean_docs
	erl -noshell -run edoc_run files '[$(DOC_SRC)]' '[{dir, "$(EDOC)"}, {new, true}]'
	
rebuild: clean build

help:
	@echo "== Welcome to the Apoidea Project =="
	@echo ""
	@echo "Secure and anonymous file sharing in Erlang."
	@echo "Made by The Awesome Team at Uppsala University."
	@echo ""
	@echo "Sunshine!"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "\tall (default)		Builds everything"
	@echo "\tbuild			Builds only the binary"
	@echo "\tdocs			Builds the documentation"
	@echo "\ttest			Run tests"
	@echo "\trebuild			Rebuild the binary"
	@echo "\tclean			Clean up binary files"
	@echo "\tdistclean		Clean up everything"
	@echo "\tstart_drone		Start a drone"
	@echo "\tstart_downloader	Start a worker that acts as a downloader"
	@echo "\tstart_uploader		Start a worker that acts as an uploader"
	@echo "\thelp			This help text"
	@echo ""
