
version=0.5.3
registry=eigr

spawn-dice-game-image=${registry}/dice-game-example:${version}

build:
	mix deps.get && mix compile

start-minikube:
	minikube start

k8s-create-ns:
	kubectl create ns eigr-functions

k8s-create-operator:
	curl -L https://raw.githubusercontent.com/eigr/spawn/main/spawn_operator/spawn_operator/manifest.yaml | kubectl apply -f -

k8s-delete-operator:
	curl -L https://raw.githubusercontent.com/eigr/spawn/main/spawn_operator/spawn_operator/manifest.yaml | kubectl delete -f -

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

k8s-apply-host:
	kubectl apply -f .k8s/host.yaml

k8s-proxy: 
	kubectl port-forward service/spawn-dice-game 8800:8800

k8s-delete-all:
	kubectl delete -f .k8s/mysql.yaml
	kubectl delete secret mysql-connection-secret -n eigr-functions
	kubectl delete -f .k8s/system.yaml
	kubectl delete -f .k8s/host.yaml
	curl -L https://raw.githubusercontent.com/eigr/spawn/main/spawn_operator/spawn_operator/manifest.yaml | kubectl delete -f -

build-image:
	docker build -f Dockerfile -t ${spawn-dice-game-image} .

run-image:
	docker run --rm --name=spawn-dice-game --net=host ${spawn-dice-game-image}

push-image:
	docker push ${spawn-dice-game-image}
