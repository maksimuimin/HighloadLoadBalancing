LOAD_BALANCER_NAME="load_balancer"
LOAD_BALANCER_PORT=80
BACKEND_PORT=8000
PROMETHEUS_NAME="prometheus"
PROMETHEUS_PORT=9090
GRAFANA_NAME="grafana"
GRAFANA_PORT=3000

run_backend:
	@echo "node_id: ${hostname}" > ./backend/etc/data.txt
	./backend/etc/build_cfg.py > ./backend/etc/envoy.yaml
	docker-compose -f ./backend/docker-compose.yml up

stop_backend:
	docker-compose -f ./backend/docker-compose.yml stop

clear_backend:
	rm ./backend/etc/data.txt; \
	yes| docker-compose -f ./backend/docker-compose.yml rm; \
	docker rmi backend_backend

run_lb:
	docker build -t $(LOAD_BALANCER_NAME) ./balancer
	docker run -p $(LOAD_BALANCER_PORT):$(LOAD_BALANCER_PORT) -p 9901:9901 \
	-v /var/log/envoy:/var/log/envoy \
	--name $(LOAD_BALANCER_NAME) $(LOAD_BALANCER_NAME)

stop_lb:
	docker stop $(LOAD_BALANCER_NAME)

clear_lb:
	docker rm $(LOAD_BALANCER_NAME); \
	docker rmi $(LOAD_BALANCER_NAME)

run_prometheus:
	docker build -t $(PROMETHEUS_NAME) ./prometheus
	docker run --network=host --name $(PROMETHEUS_NAME) $(PROMETHEUS_NAME)

stop_prometheus:
	docker stop $(PROMETHEUS_NAME)

clear_prometheus:
	docker rm $(PROMETHEUS_NAME); \
	docker rmi $(PROMETHEUS_NAME)

run_grafana:
	docker run -p $(GRAFANA_PORT):$(GRAFANA_PORT) \
	--name $(GRAFANA_NAME) \
	grafana/grafana

stop_grafana:
	docker stop $(GRAFANA_NAME)

clear_grafana:
	docker rm $(GRAFANA_NAME)