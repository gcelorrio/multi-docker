# Infraestructura Terraform — multi-docker (entorno de pruebas)

Sustituye al despliegue por `einaregilsson/beanstalk-deploy` en GitHub Actions.
Gestiona: VPC + subnets públicas, RDS Postgres, ElastiCache Redis, IAM
(instance profile + service role de EB) y el entorno de Elastic Beanstalk
(plataforma Docker AL2023, `docker-compose.yml`).

Un único entorno (sin workspaces dev/prod), acorde a que es solo de pruebas.

## 0. Requisito previo: permisos IAM

El usuario/rol que ejecuta esto (a mano o desde CI) necesita, además de
`AWSElasticBeanstalkFullAccess`: `AmazonVPCFullAccess`, `AmazonRDSFullAccess`,
`AmazonElastiCacheFullAccess`, y una policy propia acotada a S3 (el bucket de
`bootstrap/`), Secrets Manager y a los roles/instance-profile con prefijo
`<Terra_eb_app_name>-eb-*` (ajustar el patrón de recursos de esa policy a ese
prefijo, ya que los ficheros `iam.tf` nombran los roles así, no como
`aws-elasticbeanstalk-*`).

## 1. Bootstrap (una sola vez, en local, con credenciales de administrador)

Crea el bucket S3 que luego sirve de backend remoto y de almacén del
`deploy.zip`. No se ejecuta desde CI.

```bash
cd terraform/bootstrap
terraform init
terraform apply -var="state_bucket_name=<nombre-unico-del-bucket>"
```

Anota el nombre del bucket: es el valor de la variable de GitHub
`TF_STATE_BUCKET` (ver más abajo). El nombre lo elegís vosotros — no lo
genera AWS — así que se puede crear esa variable en GitHub antes o después
de correr este paso; lo que sí debe estar hecho antes de que `deploy.yaml`
se ejecute es que el bucket **exista realmente en AWS**.

## 2. Variables y secrets en GitHub Actions

**Secrets** (Settings → Secrets and variables → Actions → Secrets):

- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` — del usuario de despliegue.
- `DOCKER_USERNAME`, `DOCKER_PASSWORD` — sin cambios.

**Variables** (misma pantalla, pestaña Variables):

- `AWS_REGION` = `eu-south-2`
- `TF_STATE_BUCKET` = el bucket creado en el paso 1
- `EB_APP_NAME` = nombre de la aplicación EB
- `EB_ENV_NAME` = nombre del entorno EB

## 3. Uso en local (opcional, para probar antes de que corra en CI)

```bash
cd terraform
terraform init \
  -backend-config="bucket=<TF_STATE_BUCKET>" \
  -backend-config="key=multi-docker/terraform.tfstate" \
  -backend-config="region=eu-south-2"

terraform plan \
  -var="Terra_aws_region=eu-south-2" \
  -var="Terra_eb_app_name=<EB_APP_NAME>" \
  -var="Terra_eb_env_name=<EB_ENV_NAME>" \
  -var="Terra_version_label=local-test" \
  -var="Terra_deploy_package_path=../deploy.zip" \
  -var="Terra_state_bucket=<TF_STATE_BUCKET>"
```

En CI (`deploy.yaml`) estos mismos valores llegan como variables de entorno
`TF_VAR_Terra_*`, no como flags `-var`.

## Limitaciones conocidas (asumidas para este entorno de pruebas)

- El password de RDS es generado por Terraform y guardado en Secrets
  Manager, pero **también** queda en texto plano en la configuración del
  entorno EB (variable `PGPASSWORD`), porque el código de `server`/`worker`
  lo sigue leyendo como variable de entorno. Cambiar eso exigiría tocar el
  código de la aplicación.
- `EnvironmentType = SingleInstance`: sin Auto Scaling ni Load Balancer, para
  minimizar coste en un entorno de pruebas. No apto tal cual para producción.
- Sin NAT Gateway: RDS y ElastiCache están en subnets públicas, protegidos
  solo por security groups. Aceptable en pruebas; en producción irían en
  subnets privadas.
