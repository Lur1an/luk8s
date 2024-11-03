# EdgeDB Helm Chart

This Helm chart deploys EdgeDB on Kubernetes with support for both local storage and PostgreSQL backends.

## Installation

```bash
helm repo add luk8s https://lur1an.github.io/luk8s
helm install edgedb luk8s/edgedb
```

## Configuration

### Storage Options

The chart offers two mutually exclusive storage options:

1. **Local Storage** (default): Uses a PersistentVolumeClaim for data storage.
```yaml
storage:
 enabled: true
 className: "local-path"  # Your storage class
 storage: "10Gi"
```
2. **PostgreSQL Backend**: Uses an external PostgreSQL database.
```yaml
storage:
 enabled: false
postgres:
 enabled: true
 dsn: "postgres://user:pass@host:5432/dbname"
```
The DSN can also be provided via a secret:
```yaml
postgres:
 enabled: true
 dsn:
   valueFrom:
     secretKeyRef:
       name: postgres-secret
       key: uri
```
This is useful in case a postgres operator is creating the database for you and provides a secret with the full connection uri.

> **_Note_**: You cannot use both storage options simultaneously. When using PostgreSQL, you can run multiple replicas. Local storage mode only supports a single replica.

### Security Configuration
#### Server Password
By default, the chart generates a random password. You can provide your own password using a secret:
```yaml
security:
  password:
    secret:
      name: my-edgedb-secret
      key: password
```

#### TLS Configuration

TLS can be enabled with either a pre-existing secret or cert-manager:

1. **Using an existing secret:**
```yaml
security:
 tls:
   enabled: true
   secret: "my-tls-secret"  # Secret containing tls.crt and tls.key
```

2. **Using cert-manager:**
```yaml
security:
 tls:
   enabled: true
   cert:
     dnsNames:
     - "lurian.dev"
     issuerRef:
       name: letsencrypt-prod
       kind: ClusterIssuer
```
The schema for the `cert` field is the same as the [cert-manager Certificate](https://cert-manager.io/docs/usage/certificate/) with the omission of `secretName` and `secretTemplate` which are then filled in by the chart.
### Additional configuration
You can provide additional [environment variables](https://docs.edgedb.com/database/reference/environment) to the EdgeDB container to modify your deployment:
```yaml
env:
# enables the admin UI
- name: EDGEDB_SERVER_ADMIN_UI
  value: enabled
# allow non TLS connections for HTTP clients, useful if all your TLS is over your reverse proxy or cloud LB
- name: EDGEDB_SERVER_ALLOW_INSECURE_HTTP_CLIENTS
  value: "1"
```
> **_Note_**: Some environment variables are set automatically by the chart, such as `EDGEDB_SERVER_TLS_*`, `EDGEDB_SERVER_PASSWORD` and `EDGEDB_PORT`.

## Examples
### High-availability setup with [CloudnativePG](https://cloudnative-pg.io/):
Set up a Postgres cluster with CloudnativePG:
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: edgedb-postgres
spec:
  instances: 2
  storage:
    size: 30Gi
    storageClass: local-path
  managed:
    roles:
    - name: edgedb
      superuser: true
      createdb: true
      createrole: true
      login: true
      inRoles:
      - postgres
  bootstrap:
    initdb:
      owner: edgedb
      database: edgedb
```
It seems EdgeDB needs to run on a user that has all privileges, that's why we give it the postgres role.
```yaml
replicas: 2 # Multiple instances of EdgeDB seem to be working fine
storage:
  enabled: false
postgres:
  enabled: true
  dsn:
    valueFrom:
      secretKeyRef:
        name: edgedb-postgres-app
        key: uri
```
To connect to the database from your application set up your environment variables:
```yaml
env:
- name: EDGEDB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: edgedb-server-password
      key: password
- name: EDGEDB_DSN
  value: edgedb://edgedb:${EDGEDB_PASSWORD}@edgedb:5656/main
- name: EDGEDB_CLIENT_TLS_SECURITY
  value: insecure
- name: EDGEDB_CLIENT_SECURITY
  value: insecure_dev_mode
```
> **_Note_**: The `EDGEDB_CLIENT_TLS_SECURITY` and `EDGEDB_CLIENT_SECURITY` environment variables are required to connect to the database if you don't use a trusted source for your tls certificates. EdgeDB creates and signs its own TLS certificates if none are provided.
