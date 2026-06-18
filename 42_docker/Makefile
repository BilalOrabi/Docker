COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/borabi/data

all: build up

$(DATA_DIR)/mariadb:
	mkdir -p $(DATA_DIR)/mariadb

$(DATA_DIR)/wordpress:
	mkdir -p $(DATA_DIR)/wordpress

build: $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) build

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

down-v:
	docker compose -f $(COMPOSE_FILE) down -v

ps:
	docker compose -f $(COMPOSE_FILE) ps

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

clean: down-v
	docker system prune -af

fclean: clean
	docker volume prune -f
	sudo rm -rf $(DATA_DIR)

re: fclean all

status:
	@echo "=============== CONTAINERS ==============="
	@docker ps -a
	@echo "================ IMAGES =================="
	@docker images
	@echo "================ VOLUMES ================="
	@docker volume ls
	@echo "================ NETWORKS ================"
	@docker network ls

.PHONY: all build up down down-v ps logs clean fclean re status