# Ansible Configuration for NGINX Plus Ingress with OIDC

configure the vars in the nginx-oidc-install.yml file
ansible-playbook nginx-oidc-install.yml

Use the files in ./files to configure the ingress controller

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
