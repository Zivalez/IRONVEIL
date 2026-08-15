.PHONY: validate ci audit run web windows linux docker

validate:
	python3 tools/validate_project.py

ci:
	godot --headless --path . --import
	godot --headless --path . res://scenes/tests/ci_runner.tscn

audit: validate ci

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
