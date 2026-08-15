.PHONY: validate test run web windows linux docker

validate:
	python3 tools/validate_project.py

test:
	godot --headless --path . --script res://scripts/tests/run_headless_tests.gd

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
	docker build -t ironveil:phase1 .
