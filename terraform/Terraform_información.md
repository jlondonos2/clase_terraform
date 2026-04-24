
# Terraform CLI

**Terraform CLI** (interfaz de línea de comandos de Terraform) es una herramienta de software de HashiCorp para la automatización de infraestructura como código. Permite a los administradores definir, desplegar y gestionar recursos de infraestructura en múltiples proveedores de nube mediante configuraciones declarativas escritas en HCL.

Es ampliamente utilizado por equipos DevOps para mantener entornos consistentes y reproducibles.

---

## Datos clave

- **Desarrollador:** HashiCorp  
- **Lanzamiento inicial:** 2014  
- **Lenguaje de configuración:** HashiCorp Configuration Language (HCL)  
- **Distribución:** Software libre (licencia MPL 2.0)  
- **Compatibilidad:** Multinube y local (AWS, Azure, Google Cloud, VMware, etc.)  

---

## Funcionamiento y flujo de trabajo

Terraform CLI utiliza archivos de configuración que describen los recursos deseados.

A través de comandos como:

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```
## Descargar Terraform:
https://developer.hashicorp.com/terraform/install

### Windows:

Agregar al Path: C:\Terraform o donde tenga el ejecutable

# Estructura básica de Terraform

Terraform utiliza archivos con extensión `.tf` para definir la infraestructura.

```bash
project/
 ├── main.tf
 ├── variables.tf
 ├── outputs.tf
 └── terraform.tfvars
```

