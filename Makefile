PACKAGE_NAME          := github.com/vandot/bee-clef
GOLANG_CROSS_VERSION  ?= v1.15.3

SYSROOT_DIR     ?= sysroots
SYSROOT_ARCHIVE ?= sysroots.tar.bz2

.PHONY: sysroot-pack
sysroot-pack:
	@tar cf - $(SYSROOT_DIR) -P | pv -s $[$(du -sk $(SYSROOT_DIR) | awk '{print $1}') * 1024] | pbzip2 > $(SYSROOT_ARCHIVE)

.PHONY: sysroot-unpack
sysroot-unpack:
	@pv $(SYSROOT_ARCHIVE) | pbzip2 -cd | tar -xf -

.PHONY: release-dry-run
release-dry-run:
	@docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64
	docker run \
		--rm \
		--privileged \
		-e CGO_ENABLED=1 \
		--env-file .release-env \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v /proc/sys/fs/binfmt_misc:/proc/sys/fs/binfmt_misc \
		-v `pwd`:/go/src/$(PACKAGE_NAME) \
		-w /go/src/$(PACKAGE_NAME) \
		vandot/golang-cross:${GOLANG_CROSS_VERSION} \
		--rm-dist --skip-validate --skip-publish

.PHONY: release
release:
	@docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64
	if [ ! -f ".release-env" ]; then \
		echo "\033[91m.release-env is required for release\033[0m";\
		exit 1;\
	fi
	docker run \
		--rm \
		--privileged \
		-e CGO_ENABLED=1 \
		--env-file .release-env \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v /proc/sys/fs/binfmt_misc:/proc/sys/fs/binfmt_misc \
		-v `pwd`:/go/src/$(PACKAGE_NAME) \
		-v `echo ${HOME}`/.docker/config.json:/root/.docker/config.json \
		-w /go/src/$(PACKAGE_NAME) \
		vandot/golang-cross:${GOLANG_CROSS_VERSION} \
		release --rm-dist
