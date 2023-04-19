# Makefile for www.epydemic.org


# Tools
PYTHON = python3
PIP = pip
NIKOLA = nikola
RM = rm -fr
ACTIVATE = . $(VENV)/bin/activate
MKDIR = mkdir
CHDIR = cd
GIT = git
SVN = svn
RSYNC = rsync -rav
ECHO = echo
CURL = curl
EMACS = emacs --batch -L elisp

# Venv
VENV = venv3
REQUIREMENTS = requirements.txt

# Constructed diretories
BUILD_DIR = output
PLUGINS_DIR = plugins

# Constructed files
EXTRAS = \
	plugins/orgmode/conf.el \
	themes/adolf/assets/css/fonts.css

# Plug-ins to download
PLUGINS = \
	orgmode \
	static_tag_cloud \
	accordion \
	category_prevnext \
	similarity

# Web fonts to include (from Google Fonts)
WEBFONTS = \
	"Cormorant" \
	"Libre+Baskerville" \
	"EB+Garamond" \
	"Varela+Round" \
	"Questrial" \
	"Alegreya"
WEBFONTS_API = "https://fonts.googleapis.com/css2?family="

# The git branch we're currently working on
GIT_BRANCH = $(shell $(GIT) rev-parse --abbrev-ref HEAD 2>/dev/null)

# Run a live local server
live: env
	$(ACTIVATE) && $(NIKOLA) auto

# Build a static copy
build:  env
	$(ACTIVATE) && $(NIKOLA) build

# Upload to the Github remote
publish: upload

deploy: upload

# Possibly auto-update as well before deployment?
upload: env src-only
	$(ACTIVATE) && $(NIKOLA) github_deploy

# Check we're on the src branch before deploying
src-only:
	if [ "$(GIT_BRANCH)" != "src" ]; then echo "Can only deploy from src branch"; exit 1; fi

# Build the environment
env: $(VENV) $(PLUGINS_DIR) $(PLUGINS_DIR)/continuous_import extras

$(VENV):
	$(PYTHON) -m venv $(VENV)
	$(ACTIVATE) && $(PIP) install -U pip wheel && $(PIP) install -r $(REQUIREMENTS)

$(PLUGINS_DIR):
	$(MKDIR) $(PLUGINS_DIR)
	$(foreach p, $(PLUGINS), $(ACTIVATE) && $(NIKOLA) plugin -i $p)

extras: $(EXTRAS)

plugins/orgmode/conf.el: elisp/orgmode-conf.el
	$(RSYNC) $< $@

themes/adolf/assets/css/fonts.css:
	$(ECHO) '' $@
	$(foreach f, $(WEBFONTS), $(CURL) $(WEBFONTS_API)$f >> $@;)

# Clean up the build, to force a complete re-build
.PHONY: clean
clean:
	$(RM) $(BUILD_DIR)

# Clean up the environment as well
.PHONY: reallyclean
reallyclean: clean
	$(RM) $(VENV) $(PLUGINS_DIR) $(EXTRAS)
