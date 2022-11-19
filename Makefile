
version=0.1.1
registry=eigr

spawn-dice-game-image=${registry}/dice-game-example:${version}

build:
	mix deps.get && mix compile

start-minikube:
	minikube start

k8s-create-ns:
	kubectl create ns eigr-labs

k8s-create-mysql-connection-secret:
	kubectl ns eigr-labs
	kubectl create secret generic mysql-connection-secret \
		--from-literal=database=eigr-functions-db \
		--from-literal=host='mysql' \
		--from-literal=port='3306' \
		--from-literal=username='admin' \
		--from-literal=password='admin' \
		--from-literal=encryptionKey='3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE='

k8s-apply-mysql:
	kubectl ns eigr-labs
	kubectl apply -f .k8s/mysql.yaml

k8s-apply-system:
	kubectl ns eigr-labs
	kubectl apply -f .k8s/system.yaml

k8s-apply-node:
	kubectl ns eigr-labs
	kubectl apply -f .k8s/node.yaml

k8s-setup-all: k8s-create-ns k8s-create-mysql-connection-secret k8s-apply-system k8s-apply-node

build-image:
	docker build -f Dockerfile -t ${spawn-dice-game-image} .

run-image:
	docker run --rm --name=spawn-dice-game --net=host ${spawn-dice-game-image}

push-image:
	docker push ${spawn-dice-game-image}
