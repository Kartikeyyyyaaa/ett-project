# AWS EKS (Terraform)

Uses [terraform-aws-modules/vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) and [terraform-aws-modules/eks](https://github.com/terraform-aws-modules/terraform-aws-eks).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Configure kubectl:

```bash
aws eks update-kubeconfig --region <region> --name <cluster_name>
```

## Notes

- Pin module versions in `main.tf` to match your org’s Terraform version.
- Remote state (S3 + DynamoDB) is recommended for teams; add a `backend` block in `versions.tf`.
- If `terraform validate` fails after a major `eks` module upgrade, check the upstream module changelog for renamed inputs (node groups, IAM, addons).
