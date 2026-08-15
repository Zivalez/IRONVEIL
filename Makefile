.PHONY: validate lobby-test ci audit run web windows linux docker docker-phase2 phase2-up phase2-down

validate:
	python3 tools/validate_project.py

lobby-test:
	python3 tools/test_lobby_contract.py

ci:
	godot --headless --path . --import
	godot --headless --path . res://scenes/tests/ci_runner.tscn

audit: validate lobby-test ci

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
	docker build --no-cache -t ironveil:phase2-client .

docker-phase2:
	docker compose --env-file .env.phase2 -f docker-compose.phase2.yml build --no-cache

phase2-up:
	docker compose --env-file .env.phase2 -f docker-compose.phase2.yml up --build

phase2-down:
	docker compose --env-file .env.phase2 -f docker-compose.phase2.yml down
