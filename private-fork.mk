RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
BLUE   := \033[0;34m
RESET  := \033[0m

GH_ACTIVE_USER:=$(shell gh api user --template '{{.login}}')

SRC_GIT_REPO?=$(error Please set SRC_GIT_REPO = <username>/<repo-name>)
SRC_GIT_URL:="https://github.com/$(SRC_GIT_REPO).git"
SRC_USER:=$(dir $(SRC_GIT_REPO))

REPO_NAME:=$(notdir $(SRC_GIT_REPO))
DEST_USER?=$(GH_ACTIVE_USER)
DEST_GIT_URL:="https://github.com/$(DEST_USER)/$(REPO_NAME).git"

all: private-fork

debug:
	@echo $(SRC_USER)
	@echo $(REPO_NAME)
	@echo $(SRC_GIT_URL)
	@echo $(DEST_GIT_URL)

assert-src-exists:
	@STATUS=$$(curl -sL -X HEAD -o /dev/null -w "%{http_code}" $(SRC_GIT_URL)); \
	if [ "$$STATUS" != "200" ]; then \
		echo "Error: Getting $(SRC_GIT_URL) expected 200, got $$STATUS"; \
		exit 1; \
	fi

private-fork: assert-src-exists
	@echo -e "$(YELLOW)Creating new private repo at $(DEST_GIT_URL)$(RESET)"
	gh repo create $(REPO_NAME) --private

	@echo -e "$(YELLOW)Cloning from $(SRC_GIT_URL)$(RESET)"
	git clone $(SRC_GIT_URL)

	@echo -e "$(YELLOW)Changing remote origin to $(DEST_GIT_URL)$(RESET)"
	cd "$(REPO_NAME)" && git remote remove origin
	cd "$(REPO_NAME)" && git remote add origin $(DEST_GIT_URL)

	# set src repo as upstream to allow fetching future changes
	@echo -e "$(YELLOW)Set $(SRC_GIT_URL) as upstream$(RESET)"
	cd "$(REPO_NAME)" && git remote add upstream $(SRC_GIT_URL)
	cd "$(REPO_NAME)" && git remote set-url --push upstream DISABLE

	@echo -e "$(YELLOW)Pushing to fork destination at $(DEST_GIT_URL)$(RESET)"
	cd "$(REPO_NAME)" && git push -u origin main

	# list all remotes
	cd "$(REPO_NAME)" && git remote -v
	@echo -e "$(RESET)"
