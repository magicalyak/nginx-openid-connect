# Ansible Configuration for NGINX Plus Ingress with OIDC

## Setup

Ensure you installed R22 and added the nginx-plus-module-njs in the Dockerfile already

Copy the nginx-oidc-install.yml to nginx-oidc-install-custom.yml
Configure the vars in the nginx-oidc-install-custom.yml file
Run the playbook to create the files

```bash
#git clone https://github.com/magicalyak/nginx-openid-connect.git
cd nginx-openid-connect
#git switch R22-k8s
cd ansible
cp nginx-oidc-install.yml nginx-oidc-install-custom.yml
vim nginx-oidc-install-custom.yml # Edit variables
ansible-playbook nginx-oidc-install-custom.yml
```

## Verify Files

Use the files in ./files to configure the ingress controller
You should have 4 or 5 files depending on your options.

```bash
ansible % ls -la files                                                                                                                              R22-k8s
total 112
drwxr-xr-x  10 tom.gamull  staff    320 Jun 17 15:57 .
drwxr-xr-x   7 tom.gamull  staff    224 Jun 17 15:54 ..
-rw-r--r--   1 tom.gamull  staff    239 Jun 17 15:57 headless.yaml
-rw-r--r--   1 tom.gamull  staff  18162 Jun 17 15:57 nginx-config.yaml
-rw-r--r--   1 tom.gamull  staff   2081 Jun 17 15:57 nginx-plus-ingress.yaml
-rw-r--r--   1 tom.gamull  staff  11248 Jun 17 15:57 openid_connect.js
-rw-r--r--   1 tom.gamull  staff   3850 Jun 17 15:57 openid_connect.server_conf
```

## Create Kubernetes Ingress Resources

Modify the nginx-plus-ingress.yaml if needed for proxy settings, etc.
Modify the nginx-plus-service.yaml in the kubernetes-ingress/deployments/service directory as appropriate
Create the ingress resource as normal but specify the nginx-config.yaml located here
Create the configmaps (these shouldn't change after you import the first time)

### First Time Install

```bash
NGINX_K8S_GIT_DIR=/home/centos/git/kubernetes-ingress
NGINX_K8S_OIDC_DIR=/home/centos/git/nginx-openid-connect
cd $NGINX_K8S_GIT_DIR/deployments
kubectl apply -f common/ns-and-sa.yaml
kubectl apply -f rbac/rbac.yaml
kubectl apply -f common/default-server-secret.yaml
kubectl apply -f common/vs-definition.yaml
kubectl apply -f common/vsr-definition.yaml
kubectl apply -f common/ts-definition.yaml
kubectl apply -f common/gc-definition.yaml
kubectl apply -f common/global-configuration.yaml
cd $NGINX_K8S_OIDC_DIR/ansible/files
kubectl apply -f nginx-config.yaml
kubectl create configmap -n nginx-ingress openid-connect.js --from-file=openid_connect.js
kubectl create configmap -n nginx-ingress openid-connect.server-conf --from-file=openid_connect.server_conf
kubectl apply -f nginx-plus-ingress.yaml
cd $NGINX_K8S_GIT_DIR/deployments
kubectl apply -f service/nginx-plus-service.yaml  # Make sure this exists and you modified it
cd $NGINX_K8S_OIDC_DIR
```

### Previous Install

Uncomment lines if you're upgrading the ingress controller from an earlier version.

```bash
NGINX_K8S_GIT_DIR=/home/centos/git/kubernetes-ingress
NGINX_K8S_OIDC_DIR=/home/centos/git/nginx-openid-connect
#cd $NGINX_K8S_GIT_DIR/deployments
#kubectl apply -f common/ns-and-sa.yaml
#kubectl apply -f rbac/rbac.yaml
#kubectl apply -f common/vs-definition.yaml
#kubectl apply -f common/vsr-definition.yaml
#kubectl apply -f common/ts-definition.yaml
#kubectl apply -f common/gc-definition.yaml
#kubectl apply -f common/global-configuration.yaml
cd $NGINX_K8S_OIDC_DIR/ansible/files
kubectl apply -f nginx-config.yaml
#kubectl apply -f nginx-plus-ingress.yaml
cd $NGINX_K8S_OIDC_DIR
kubectl -n nginx-ingress deployments nginx-ingress --replicas=0
kubectl -n nginx-ingress deployments nginx-ingress --replicas=4  # Change this to your number (1?)
```

## Configure your applications

Once you finish you can create an application like the cafe example

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: cafe-ingress
  annotations:
    custom.nginx.org/oidc:  "on"
    spec:
  tls:
  - hosts:
    - cafe.nginx.net
    secretName: cafe-secret
  rules:
  - host: cafe.nginx.net
    http:
      paths:
      - path: /tea
        backend:
          serviceName: tea-svc
          servicePort: 80
      - path: /coffee
        backend:
          serviceName: coffee-svc
          servicePort: 80
```

## Update IDPs

Simply run the playbook again and it will generate a new nginx-config.yml file (you'll see it in yellow as changed)
Then just apply the file and you'll only need to configure the app ingress.
This should be able to be automated quite easily.

```bash
cd /home/centos/git/nginx-openid-connect/ansible
vim nginx-oidc-install-custom.yml # Add the new app and IDP
ansible-playbook nginx-oidc-install-custom.yml
kubectl apply -f files/nginx-config.yml
# Scale the deployment down to 0 and back up
kubectl -n nginx-ingress deployments nginx-ingress --replicas=0
kubectl -n nginx-ingress deployments nginx-ingress --replicas=4  # Change this to your number (1?)
```
