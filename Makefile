#=====================================================================
# make site
#=====================================================================

#=====================================================================
# Setup
#=====================================================================
# CORE MACROS
ifeq ($(OS), Windows_NT)
CD=cd
else
CD=cd -P "$(CURDIR)"; cd   # This handles the case when CURDIR is a softlink
endif
CP=cp
MAKE=make
MV=mv
RM=rm -f
MKDIR=mkdir -p
RMDIR=$(RM) -r
ASPELL=aspell
SORT=sort
R_SCRIPT = Rscript

# Capabilities
HAS_ASPELL := $(shell $(R_SCRIPT) -e "cat(Sys.getenv('HAS_ASPELL', !is.na(utils:::aspell_find_program('aspell'))))")
HTML_FILES := $(wildcard html/*.html html/*/*.html html/*/*/*.html)


#=====================================================================
# Configs
#=====================================================================


#=====================================================================
# Global
#=====================================================================
all: scrape build alpha


#=====================================================================
# Pages
#=====================================================================
scrape:
	$(R_SCRIPT) "R/scrape-old.R"

build_scrape:
	$(R_SCRIPT) "R/build15.R" --input=scrape

build_content:
	$(R_SCRIPT) "R/build15.R" --input=content

build_content_tmp:
	$(MKDIR) content,tmp/
	rsync -avvz scraped/5.rsp/ content,tmp/
	rsync -avvz --checksum content/ content,tmp/

build_both: build_content_tmp
	$(R_SCRIPT) "R/build15.R" --input=content,tmp

build: build_content


spell:
	@echo $(HTML_FILES)
	$(RM) spell-words.txt
	for file in $(HTML_FILES); do \
	  echo file=$$file; \
          $(ASPELL) --personal=./.aspell.en_US.pws --mode=html list < $$file >> spell-words.txt; \
	done
	cat spell-words.txt | sort -u > spell-words.sorted.txt
	cat spell-words.sorted.txt

check_links:
	wget -R '*+url+*' --spider -o wget.log -e robots=off -w 1 -r -p http://alpha.aroma-project.org/index.html
	grep -B 2 '404' wget.log

check_html:
	$(R_SCRIPT) "R/w3c-html"

check_css:
	$(R_SCRIPT) -e "browseURL('http://jigsaw.w3.org/css-validator/validator?uri=http%3A%2F%2Falpha.aroma-project.org')"



#=====================================================================
# Publish (=go live!)
#=====================================================================
# Requires a 'cbc.ucsf.edu' entry in ~/.ssh/config with:
#
#  Host cbc.ucsf.edu
#    User <username on cbc.ucsf.edu>

alpha:
	rsync -avvz --exclude '*~' --exclude 'references/*' --perms --chmod=ugo+rx --progress html/ aroma-project.org:public_html/aroma-project.org-alpha

#publish:
#	rsync -avvz --exclude '*~' --exclude 'references/*' --perms --chmod=ugo+rx --progress html/ aroma-project.org:public_html/aroma-project.org-NOT-YET


#=====================================================================
# Cleanups
#=====================================================================
clean:
	$(RM) -rf html/

