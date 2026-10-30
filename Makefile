-include env_make

T3CODE_VER ?= 0.1.5
T3CODE_VER_MINOR = $(shell echo "${T3CODE_VER}" | grep -oE '^[0-9]+\.[0-9]+')

TAG ?= $(T3CODE_VER_MINOR)

REPO = wodby/t3code
NAME = t3code-$(T3CODE_VER)

IMAGETOOLS_TAG ?= $(TAG)

ifneq ($(ARCH),)
	override TAG := $(TAG)-$(ARCH)
endif

.PHONY: build test push shell run clean buildx-imagetools-create

default: build

build:
	docker build -t $(REPO):$(TAG) --build-arg T3CODE_VER=$(T3CODE_VER) ./

test:
	cd ./tests && IMAGE=$(REPO):$(TAG) NAME=$(NAME) T3CODE_VER=$(T3CODE_VER) ./run.sh

push:
	docker push $(REPO):$(TAG)

buildx-imagetools-create:
	docker buildx imagetools create -t $(REPO):$(IMAGETOOLS_TAG) \
				$(REPO):$(TAG)-amd64 \
				$(REPO):$(TAG)-arm64

shell:
	docker run --rm --name $(NAME) -i -t $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --name $(NAME) -p 3773:3773 $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

clean:
	-docker rm -f $(NAME)
