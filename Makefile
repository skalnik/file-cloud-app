PROJECT := File Cloud.xcodeproj
IOS_SCHEME := File Cloud (iOS)
MAC_SCHEME := File Cloud (macOS)
MAC_APP := File Cloud.app
SIMULATOR ?= iPhone 17
IOS_BUILD_DESTINATION := generic/platform=iOS Simulator
IOS_TEST_DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)
MAC_DESTINATION := platform=macOS
BUILD_DIR := build

FORMAT := $(shell command -v xcbeautify >/dev/null 2>&1 && echo "| xcbeautify" || echo "")

# xcodebuild makes or renews the signing certificate and the profile only with
# this flag. Xcode does it for you, so a build fails from the CLI first.
SIGNING := -allowProvisioningUpdates

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.PHONY: generate
generate: ## Make the Xcode project from project.yml
	@xcodegen generate

.PHONY: build
build: build-macos build-ios ## Build both apps

.PHONY: build-ios
build-ios: generate ## Build the iOS app for the simulator
	set -o pipefail; xcodebuild build \
		-project "$(PROJECT)" -scheme "$(IOS_SCHEME)" $(SIGNING) \
		-destination "$(IOS_BUILD_DESTINATION)" -configuration Debug $(FORMAT)

.PHONY: build-macos
build-macos: generate ## Build the macOS app
	set -o pipefail; xcodebuild build \
		-project "$(PROJECT)" -scheme "$(MAC_SCHEME)" $(SIGNING) \
		-destination "$(MAC_DESTINATION)" -configuration Debug $(FORMAT)

.PHONY: test
test: test-macos test-ios ## Run all tests

.PHONY: test-ios
test-ios: generate ## Run the iOS UI tests in the simulator
	set -o pipefail; xcodebuild test \
		-project "$(PROJECT)" -scheme "$(IOS_SCHEME)" $(SIGNING) \
		-destination "$(IOS_TEST_DESTINATION)" $(FORMAT)

.PHONY: test-macos
test-macos: generate ## Run the macOS unit tests
	set -o pipefail; xcodebuild test \
		-project "$(PROJECT)" -scheme "$(MAC_SCHEME)" $(SIGNING) \
		-destination "$(MAC_DESTINATION)" $(FORMAT)

.PHONY: run
run: build-macos ## Build and start the macOS app
	@set -e -o pipefail; \
	dir=$$(xcodebuild -project "$(PROJECT)" -scheme "$(MAC_SCHEME)" \
		-destination "$(MAC_DESTINATION)" -configuration Debug -showBuildSettings \
		| awk -F' = ' '/ BUILT_PRODUCTS_DIR/ {print $$2; exit}'); \
	test -n "$$dir"; \
	open "$$dir/$(MAC_APP)"

.PHONY: archive-macos
archive-macos: generate ## Make a macOS archive in build/
	set -o pipefail; xcodebuild archive \
		-project "$(PROJECT)" -scheme "$(MAC_SCHEME)" $(SIGNING) \
		-destination "$(MAC_DESTINATION)" \
		-archivePath "$(BUILD_DIR)/File Cloud (macOS).xcarchive" $(FORMAT)

.PHONY: archive-ios
archive-ios: generate ## Make an iOS archive in build/
	set -o pipefail; xcodebuild archive \
		-project "$(PROJECT)" -scheme "$(IOS_SCHEME)" $(SIGNING) \
		-destination "generic/platform=iOS" \
		-archivePath "$(BUILD_DIR)/File Cloud (iOS).xcarchive" $(FORMAT)

.PHONY: bump
bump: ## Set the version to today's date and the build number to 1
	bin/bump-version
	@$(MAKE) generate

.PHONY: open
open: generate ## Open the project in Xcode
	open "$(PROJECT)"

.PHONY: clean
clean: ## Remove build output
	rm -rf "$(BUILD_DIR)"
	xcodebuild clean -project "$(PROJECT)" -scheme "$(MAC_SCHEME)" >/dev/null 2>&1 || true
	xcodebuild clean -project "$(PROJECT)" -scheme "$(IOS_SCHEME)" >/dev/null 2>&1 || true

.PHONY: distclean
distclean: clean ## Remove build output and the generated Xcode project
	rm -rf "$(PROJECT)"
