# Demo Application

Application to demonstrate random connection reset in GCP.

This is a simple application consisting of two HTTP endpoints where the first endpoint invokes the second, via a Load Balancer when running in GCP, and the second endpoint does some queries to a DB.

The purpose is to generate some traffic to trigger the random connection reset bug.

## Run Locally

Run locally:

```bash
$ ./mvnw package
$ docker-compose up
```

Invoke the endpoints:

```bash
$ curl -v http://localhost:8080/demo/first
```

## Run in GCP

1. Create a Storage Bucket to store the terraform state, and update in `infra/backend.tf`
2. Enter values in `infra/env.tfvars`
3. Run the following commands:

```bash
$ ./mvnw package -Ddocker.arch=amd64
$ docker tag demo:latest $DOCKER_REPOSITORY/demo:latest
$ docker push $DOCKER_REPOSITORY/demo:latest

$ cd infra
$ terraform apply --var-file env.tfvars
```

4. Set up a DNS record for the domain to point to the LB IP

Invoke the endpoints:

```bash
$ curl -v https://$DOMAIN/demo/first
```

## Trigger the connection reset

```bash
while true; do
  sleep $[ ( $RANDOM % 3 )  + 1 ]s
  curl -v https://demo.dev.veritru.me/demo/first
  sleep $[ ( $RANDOM % 30 )  + 1 ]s
  curl -v https://demo.dev.veritru.me/demo/first
  sleep $[ ( $RANDOM % 300 )  + 1 ]s
  curl -v https://demo.dev.veritru.me/demo/first
done
```
