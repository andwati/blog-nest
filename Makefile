SHELL := /bin/bash

ROOT_DIR := $(shell pwd)
COMPOSE_DEV := docker compose -f infra/docker-compose.yml
COMPOSE_PROD := docker compose -f infra/docker-compose.prod.yml

DOMAIN ?=
EMAIL ?=

.PHONY: help \
	dev-up dev-down dev-logs dev-ps dev-restart \
	prod-build prod-up prod-down prod-logs prod-ps prod-restart \
	deploy deploy-rebuild health \
	ssl-selfsigned ssl-certbot ssl-install ssl-renew-test

help:
	@echo "Available targets:"
	@echo "  make dev-up            # Start development stack"
	@echo "  make dev-down          # Stop development stack"
	@echo "  make dev-logs          # Follow development logs"
	@echo "  make dev-ps            # Show development service status"
	@echo "  make dev-restart       # Restart development stack"
	@echo ""
	@echo "  make prod-build        # Build production images"
	@echo "  make prod-up           # Start production stack"
	@echo "  make prod-down         # Stop production stack"
	@echo "  make prod-logs         # Follow production logs"
	@echo "  make prod-ps           # Show production service status"
	@echo "  make prod-restart      # Restart production stack"
	@echo ""
	@echo "  make deploy            # Build + start production stack"
	@echo "  make deploy-rebuild    # Down + build(no-cache) + up"
	@echo "  make health            # Check HTTP/HTTPS + compose status"
	@echo ""
	@echo "  make ssl-selfsigned    # Generate local self-signed certs in infra/ssl"
	@echo "  make ssl-certbot DOMAIN=example.com EMAIL=ops@example.com"
	@echo "                        # Request Let's Encrypt cert (standalone)"
	@echo "  make ssl-install DOMAIN=example.com"
	@echo "                        # Copy LE certs into infra/ssl and restart nginx"
	@echo "  make ssl-renew-test    # Dry-run certbot renew"

dev-up:
	$(COMPOSE_DEV) up

dev-down:
	$(COMPOSE_DEV) down

dev-logs:
	$(COMPOSE_DEV) logs -f

dev-ps:
	$(COMPOSE_DEV) ps

dev-restart:
	$(COMPOSE_DEV) down
	$(COMPOSE_DEV) up -d

prod-build:
	$(COMPOSE_PROD) build

prod-up:
	$(COMPOSE_PROD) up -d

prod-down:
	$(COMPOSE_PROD) down

prod-logs:
	$(COMPOSE_PROD) logs -f

prod-ps:
	$(COMPOSE_PROD) ps

prod-restart:
	$(COMPOSE_PROD) down
	$(COMPOSE_PROD) up -d

deploy:
	$(COMPOSE_PROD) build
	$(COMPOSE_PROD) up -d

deploy-rebuild:
	$(COMPOSE_PROD) down
	$(COMPOSE_PROD) build --no-cache
	$(COMPOSE_PROD) up -d

health:
	@echo "== Compose status =="
	$(COMPOSE_PROD) ps
	@echo ""
	@echo "== HTTP check (expect 301) =="
	@curl -sS -I http://localhost:80 | head -1
	@echo "== HTTPS check (expect 200) =="
	@curl -k -sS -o /dev/null -w "%{http_code}\n" https://localhost:443

ssl-selfsigned:
	mkdir -p infra/ssl
	docker run --rm -v $(ROOT_DIR)/infra/ssl:/out alpine:3.21 sh -lc "apk add --no-cache openssl >/dev/null && openssl req -x509 -nodes -newkey rsa:2048 -keyout /out/key.pem -out /out/cert.pem -days 365 -subj '/CN=localhost'"
	chmod 600 infra/ssl/key.pem
	@echo "Self-signed certs created at infra/ssl/cert.pem and infra/ssl/key.pem"

ssl-certbot:
	@if [ -z "$(DOMAIN)" ] || [ -z "$(EMAIL)" ]; then \
		echo "Usage: make ssl-certbot DOMAIN=example.com EMAIL=ops@example.com"; \
		exit 1; \
	fi
	sudo certbot certonly --standalone -d $(DOMAIN) --email $(EMAIL) --agree-tos --no-eff-email

ssl-install:
	@if [ -z "$(DOMAIN)" ]; then \
		echo "Usage: make ssl-install DOMAIN=example.com"; \
		exit 1; \
	fi
	mkdir -p infra/ssl
	sudo cp /etc/letsencrypt/live/$(DOMAIN)/fullchain.pem infra/ssl/cert.pem
	sudo cp /etc/letsencrypt/live/$(DOMAIN)/privkey.pem infra/ssl/key.pem
	sudo chown $(USER):$(USER) infra/ssl/cert.pem infra/ssl/key.pem
	chmod 600 infra/ssl/key.pem
	$(COMPOSE_PROD) restart nginx
	@echo "Installed Let's Encrypt certs for $(DOMAIN) and restarted nginx"

ssl-renew-test:
	sudo certbot renew --dry-run
