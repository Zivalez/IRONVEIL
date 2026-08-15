.PHONY: validate lobby-test security-test persistence-test service-tests ci audit run web windows linux docker stack-build stack-up stack-down

validate:
	python3 tools/validate_project.py

lobby-test:
	python3 tools/test_lobby_contract.py

security-test:
	python3 tools/test_public_security_contract.py

persistence-test:
	python3 tools/test_persistence_contract.py

service-tests: lobby-test security-test persistence-test

ci:
	godot --headless --path . --import
	godot --headless --path . res://scenes/tests/ci_runner.tscn

audit: validate service-tests ci

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
	docker build --no-cache -t ironveil:1.0.0-client .

stack-build:
	docker compose --env-file .env.phase3 -f docker-compose.phase3.yml build --no-cache

stack-up:
	docker compose --env-file .env.phase3 -f docker-compose.phase3.yml up --build

stack-down:
	docker compose --env-file .env.phase3 -f docker-compose.phase3.yml down
