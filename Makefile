export HOMEBREW_NO_AUTO_UPDATE = 1

### Helpers

XCODEPROJ=StateMachine.xcodeproj
SCHEME=StateMachine
CONFIGURATION=Release

PHONEDESTINATION="platform=iOS Simulator,name=iPhone 8,OS=latest"
TVDESTINATION="platform=tvOS Simulator,name=Apple TV,OS=latest"
WATCHDESTINATION="platform=watchOS Simulator,name=Apple Watch Series 3 - 42mm,OS=latest"

### Actions

test-iOS:
	xcodebuild -project $(XCODEPROJ) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination $(PHONEDESTINATION) \
		-disable-concurrent-testing \
		clean build test

test-macOS:
	xcodebuild -project $(XCODEPROJ) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		clean build test

test-tvOS:
	xcodebuild -project $(XCODEPROJ) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination $(TVDESTINATION) \
		clean build test

build-watchOS:
	xcodebuild -project $(XCODEPROJ) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination $(WATCHDESTINATION) \
		clean build 

run-test: test-iOS test-macOS test-tvOS build-watchOS

install-lint:
	brew remove swiftlint --force || true
	brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/af232506f5f1879af77852d6297b1e2a5b040270/Formula/swiftlint.rb

run-lint: install-lint
	swiftlint lint --strict 2>/dev/null

install-carthage:
	brew remove carthage --force || true
	brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/af232506f5f1879af77852d6297b1e2a5b040270/Formula/carthage.rb

run-carthage: install-carthage
	carthage build \
		--no-skip-current \
		--configuration $(CONFIGURATION) \
		--verbose
	ls Carthage/build/Mac/StateMachine.framework
	ls Carthage/build/iOS/StateMachine.framework
	ls Carthage/build/tvOS/StateMachine.framework

