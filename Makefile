.PHONY: build test package doctor

build:
	./Scripts/build-app.sh

test:
	swift build
	./Scripts/test-engine.sh

package: build
	./Scripts/package-release.sh

doctor:
	./Scripts/doctor.sh
