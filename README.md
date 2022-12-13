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
