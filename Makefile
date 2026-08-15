.PHONY: validate compile test audit run web windows linux docker

validate:
	python3 tools/validate_project.py

compile:
	godot --headless --path . --import
	godot --headless --path . --script res://scripts/tests/compile_all.gd

test:
	godot --headless --path . --script res://scripts/tests/run_headless_tests.gd

audit: validate compile test

run:
	godot --path .

web:
	mkdir -p build
	godot --headless --path . --export-release "Web" build/index.html

windows:
	mkdir -p build
	godot --headless --path . --export-release "Windows Desktop" build/IRONVEIL.exe

linux:
	mkdir -p build
	godot --headless --path . --export-release "Linux" build/IRONVEIL.x86_64

docker:
	docker build --no-cache -t ironveil:phase1 .
