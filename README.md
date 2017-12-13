# Profistory

Microservice for sharing employee **profi**les and company hi**story**.

## Requirements

* Database
    * Mongo DB
* Authentication
    * OneLogin SAML IdP or Twitter OAuth
* URL Embed
    * [embed.ly](http://embed.ly/)

## How to Develop

```
## Write your configuration
$ vi config/settings/development.yml

## Run docker containers
$ docker-compose up -d

## Access to web application
$ curl http://localhost:8082
```
