# Django + S3
Resources: 
- https://www.youtube.com/watch?v=JQVQcNN0cXE
- https://testdriven.io/blog/storing-django-static-and-media-files-on-amazon-s3

### Building
```shell
terraform apply -auto-approve
# update docker-compose env variables with IAM user credentials 
docker-compose up -d
docker-compose exec web python manage.py collectstatic
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py makemigrations
```

TODO 
- make a script to write aws credentials to ~/.aws/credentials in format: 
  ```
  [profile-name]
  aws_access_key_id=Aafhjkahlkjs
  aws_secret_access_key=faefaeafs
  ```
  - and delete on destroy

### Tearing Down
```shell
docker-compose down
aws s3 rm s3://learn-django-docker-s3 --recursive
terraform destroy -auto-approve
```