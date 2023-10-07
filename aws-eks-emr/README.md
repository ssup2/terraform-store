# aws-eks-karpenter-elb-efs

## Provisioning EKS cluster, EMR on EKS, spark-operator

* Set S3 bucket names
  * Modify "s3_bucket_spark_history", "s3_bucket_spark_history_dir" to unique S3 bucket name in locals.tf
  * Modify "bucket" in terraform.tf

* Provisioning

```
$ terraform init
$ terraform apply -target="module.vpc" 
$ terraform apply
```

