
version=1.0.0-rc.18
registry=eigr

spawn-dice-game-image=${registry}/dice-game-example:${version}

build:
	mix deps.get && mix compile

start-minikube:
	minikube start

k8s-create-ns:
	kubectl create ns eigr-functions

k8s-create-operator:
	curl -L https://github.com/eigr/spawn/releases/download/v1.0.0-rc.17/manifest.yaml | kubectl apply -f -

k8s-delete-operator:
	curl -L https://github.com/eigr/spawn/releases/download/v1.0.0-rc.17/manifest.yaml | kubectl delete -f -

k8s-create-mysql-connection-secret:
	kubectl create secret generic mysql-connection-secret \
		--from-literal=database=eigr-functions-db \
		--from-literal=host='mysql' \
		--from-literal=port='3306' \
		--from-literal=username='admin' \
		--from-literal=password='admin' \
		--from-literal=encryptionKey='3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE=' -n eigr-functions

k8s-apply-mysql:
	kubectl apply -f .k8s/mysql.yaml

k8s-apply-system:
	kubectl apply -f .k8s/system.yaml
	sleep 5

k8s-apply-host:
	kubectl apply -f .k8s/host.yaml

k8s-proxy: 
	kubectl port-forward service/spawn-dice-game 8800:8800

k8s-delete-all:
	kubectl delete -f .k8s/mysql.yaml
	kubectl delete secret mysql-connection-secret -n eigr-functions
	kubectl delete -f .k8s/system.yaml
	kubectl delete -f .k8s/host.yaml
	curl -L curl -L https://github.com/eigr/spawn/releases/download/v1.0.0-rc.17/manifest.yaml | kubectl delete -f -

build-image:
	docker build -f Dockerfile -t ${spawn-dice-game-image} .

run:
	PROXY_ACTOR_SYSTEM_NAME=game-system PROXY_CLUSTER_STRATEGY=epmd PROXY_ACTOR_SYSTEM_NAME=game-system SPAWN_USE_INTERNAL_NATS=true SPAWN_PUBSUB_ADAPTER=nats PROXY_DATABASE_TYPE=mysql PROXY_DATABASE_POOL_SIZE=10 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a2@127.0.0.1 -S mix phx.server

run-image:
	docker run --rm --name=spawn-dice-game --net=host -e PROXY_DATABASE_TYPE=mysql -e PROXY_DATABASE_POOL_SIZE=10 -e SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= ${spawn-dice-game-image}

push-image:
	docker push ${spawn-dice-game-image}
