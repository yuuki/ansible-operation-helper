ANSIBLE_DOCKER_TAG='yuuki/ansible-playbooks'
LOCAL_ANSIBLE_DOCKER_TAG='yuuki/ansible-playbooks:local'
PROJECT='github.com/yuuki/ansible-playbooks'
ECR_ENDPOINT='123456789.example.ecr.ap-northeast-1.amazonaws.com'

.PHONY: setup
setup:
	bin/ecr_login
	docker pull $(ECR_ENDPOINT)/$(ANSIBLE_DOCKER_TAG):latest
	docker tag $(ECR_ENDPOINT)/$(ANSIBLE_DOCKER_TAG):latest $(ANSIBLE_DOCKER_TAG):latest

.PHONY: deploy
deploy: build push remote-pull

.PHONY: build
build:
	docker build -t $(ANSIBLE_DOCKER_TAG) .

.PHONY: local-build
local-build: build
	$(eval UID := $(shell id -u))
	docker build --build-arg UID=$(UID) -f Dockerfile.local -t $(LOCAL_ANSIBLE_DOCKER_TAG) .

.PHONY: push
push:
	bin/ecr_login
	docker tag $(ANSIBLE_DOCKER_TAG):latest $(ECR_ENDPOINT)/$(ANSIBLE_DOCKER_TAG):latest
	docker push $(ECR_ENDPOINT)/$(ANSIBLE_DOCKER_TAG):latest

.PHONY: remote-login
remote-login:
	bin/on_remote 'eval $$(ecr aws ecr get-login --no-include-email)'

.PHONY: remote-pull
remote-pull: remote-login
	bin/on_remote 'ecr docker pull "$(ECR_ENDPOINT)/$(ANSIBLE_DOCKER_TAG):latest"'

.PHONY: local-test-run
local-test-run: local-build
	bin/on_local_container ./bin/ansible-pssh example01 example02 example03 # ...

.PHONY: remote-test-run
remote-test-run:
	bin/on_remote_container ./bin/ansible-pssh example01 example02 example03 # ...

.PHONY: inventory
inventory:
	bin/on_local_container ./bin/mackerel_inventry | jq -rM '.'
