# Makefile for the Credit Platform project

.PHONY: help install run-backend run-frontend run test migrate build deploy-k8s

help:
	@echo "Available commands:"
	@echo "  make install       - Install backend and frontend dependencies"
	@echo "  make run           - Run backend and frontend simultaneously"
	@echo "  make run-backend   - Run only the backend"
	@echo "  make run-frontend  - Run only the frontend"
	@echo "  make migrate       - Run database migrations"
	@echo "  make test          - Run backend tests"
	@echo "  make build         - Build Docker images"
	@echo "  make deploy-k8s    - Apply Kubernetes manifests"

install:
	cd backend && bundle install
	cd frontend && npm install

run-backend:
	cd backend && bin/dev

run-frontend:
	cd frontend && npm run dev

run:
	@echo "Starting backend and frontend..."
	@ (trap 'kill 0' SIGINT; cd backend && bin/dev & cd frontend && npm run dev)

migrate:
	cd backend && bin/rails db:prepare

test:
	cd backend && bin/rails test

build:
	docker build -t credit-backend:latest ./backend
	docker build -t credit-frontend:latest ./frontend

deploy-k8s:
	kubectl apply -f infra/k8s/
