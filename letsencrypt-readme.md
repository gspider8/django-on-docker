# Securing a Containerized Django Application with Let's Encrypt
link: https://testdriven.io/blog/django-lets-encrypt/
domain name: toruscommunity.org

Ensure that `.dockerignore` includes any local development venv 
## Development Environment
```shell
docker-compose up -d # --build
```
accessible at http://127.0.0.1:8000

## Staging Environment
**Build images and spin up containers**
```sh
# up
sudo docker-compose -f docker-compose.staging.yml up -d --build

# down
sudo docker-compose -f docker-compose.staging.yml down -v  # removes volumes
```
**New containers**
- nginx-proxy
  - handles routing
- acme
  - handles creation, renewal, and use of Let's Encrypt certificates for proxied Docker containers

**Staging Environment Variables**
- Ensure `SQL_USER` and `SQL_PASSWORD` match `POSTGRES_USER` and `POSTGRES_PASSWORD` (from _.env.staging.db_).
- `VIRTUAL_HOST` (and `VIRTUAL_PORT`) are needed by `nginx-proxy` to auto create the reverse proxy configuration.
  - So, requests made to the specified domain will be proxied to the container that has the domain set as the `VIRTUAL_HOST` environment variable.
- `LETSENCRYPT_HOST` is there so the `nginx-proxy-companion` can issue Let's Encrypt certificate for your domain.
- Since the Django app will be listening on port 8000, we also set the `VIRTUAL_PORT` environment variable.
- The `/var/run/docker.sock:/tmp/docker.sock:ro` volume in _docker-compose.staging.yml_ is used to listen for newly registered/de-registered containers.
- For testing/debugging purposes you may want to use a `*` for `DJANGO_ALLOWED_HOSTS` the first time you deploy to simplify things.
  - Make sure to limit this once testing is complete

_**.env.staging.db**_
```
POSTGRES_USER=hello_django
POSTGRES_PASSWORD=hello_django
POSTGRES_DB=hello_django_prod
```

_**.env.staging**_
```
DEBUG=0
SECRET_KEY=change_me
DJANGO_ALLOWED_HOSTS=<YOUR_DOMAIN.COM>
SQL_ENGINE=django.db.backends.postgresql
SQL_DATABASE=hello_django_prod
SQL_USER=hello_django
SQL_PASSWORD=hello_django
SQL_HOST=db
SQL_PORT=5432
DATABASE=postgres
VIRTUAL_HOST=<YOUR_DOMAIN.COM>
VIRTUAL_PORT=8000
LETSENCRYPT_HOST=<YOUR_DOMAIN.COM>
CSRF_TRUSTED_ORIGINS=https://<YOUR_DOMAIN.COM>
```

### Nginx Configuration
We will now be using nginx-proxy vs the nginx image

**Serve Static and Media files** 
_nginx/vhost.d/default_ 
- Requests that match any of these patterns will be served from static or media folders. They won't be proxied to other containers.

```
location /static/ {
  alias /home/app/web/staticfiles/;
  add_header Access-Control-Allow-Origin *;
}

location /media/ {
  alias /home/app/web/mediafiles/;
  add_header Access-Control-Allow-Origin *;
}
```
**Custom proxy-wide configuration**
_nginx/custom.conf_
```
client_max_body_size 10M;
```

**NGINX Dockerfile**
_nginx/Dockerfile_
```dockerfile
FROM nginxproxy/nginx-proxy
COPY vhost.d/default /etc/nginx/vhost.d/default
COPY custom.conf /etc/nginx/conf.d/custom.conf
```

### ACME Companion Service
**_.env.staging.proxy-companion_**
```
DEFAULT_EMAIL=youremail@yourdomain.com
ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory
NGINX_PROXY_CONTAINER=nginx-proxy
```
- `DEFAULT_EMAIL` is the email that Let's Encrypt will use to send you notifications about your certificates
(including renewals).
- `ACME_CA_URI` is the URL used to issue certificates. Again, use staging until you're 100% sure that everything works.
- `NGINX_PROXY_CONTAINER` is the name of nginx-proxy container.

### Running on Your Instance
**Prepare Instance**
I created a t2.micro running Amazon Linux 2023
- username: `ec2-user`
- ip: 34.201.114.157
SSH in 
```sh
# prepare directories
mkdir /home/ec2-user/django-on-docker
cd /home/ec2-user/django-on-docker
chmod +x app/entrypoint.prod.sh
chmod +x app/entrypoint.sh

# install docker
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html#install-docker-instructions
sudo yum update -y
sudo yum install -y docker
sudo yum install -y docker-compose
sudo service docker start
# need sudo to run docker commands

# install docker-compose
# https://medium.com/@fredmanre/how-to-configure-docker-docker-compose-in-aws-ec2-amazon-linux-2023-ami-ab4d10b2bcdc
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version
```
- ssh'd in and created _/home/ec2-user/django-on-docker_
- install docker on amazon linux w/ `sudo amazon-linux-extras install docker`
- use winscp to copy over
  - app, nginx
  - docker-compose.staging.yml
  - .env.staging, .env.staging.db, .env.staging.proxy-companion


<callout>
  <p>Have docker and docker-compose installed on instance startup in future</p>
  <p>that's a good use of userdata</p>
</callout>

## Production Environment
Create _.env.prod_, _.env.prod.db_, and _.env.prod.proxy-companion_ in root project directory

**_.env.prod_**
```
DEBUG=0
SECRET_KEY=change_me
DJANGO_ALLOWED_HOSTS=<YOUR_DOMAIN.COM>
SQL_ENGINE=django.db.backends.postgresql
SQL_DATABASE=hello_django_prod
SQL_USER=<YOUR_USERNAME>
SQL_PASSWORD=<YOUR_PASSWORD>
SQL_HOST=db
SQL_PORT=5432
DATABASE=postgres
VIRTUAL_HOST=<YOUR_DOMAIN.COM>
VIRTUAL_PORT=8000
LETSENCRYPT_HOST=<YOUR_DOMAIN.COM>
CSRF_TRUSTED_ORIGINS=https://<YOUR_DOMAIN.COM>
```

**_.env.prod.db_**
```
POSTGRES_USER=<YOUR_USERNAME>
POSTGRES_PASSWORD=<YOUR_PASSWORD>
POSTGRES_DB=hello_django_prod
```

**_.env.prod.proxy-companion_**
```
DEFAULT_EMAIL=youremail@yourdomain.co
NGINX_PROXY_CONTAINER=nginx-proxy
```
- `ACME_CA_URI` environment variable is not set since the `acme-companion` image uses Let's Encrypt's production environment by default.

The only difference between docker-compose.prod.yml and docker-compose.staging.yml is the different environment files

Commands to get up and running
```shell
docker-compose -f docker-compose.prod.yml down -v
docker-compose -f docker-compose.prod.yml up -d --build
docker-compose -f docker-compose.prod.yml exec web python manage.py migrate --noinput
docker-compose -f docker-compose.prod.yml exec web python manage.py collectstatic --no-input --clear
```

