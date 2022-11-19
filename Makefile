.PHONY: build

build:
	flutter pub run build_runner build

build_delete:
	flutter pub run build_runner build --delete-conflicting-outputs

create_splash:
	flutter pub run flutter_native_splash:create
