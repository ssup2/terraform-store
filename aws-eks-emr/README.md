# aws-eks-karpenter-elb-efs

## Provisioning EKS cluster, EMR on EKS, spark-operator

* Set S3 bucket names
  * Modify "s3_bucket_spark_history", "s3_bucket_spark_history_dir" to unique S3 bucket name in locals.tf
  * Modify "bucket" in terraform.tf

* Provision

```
$ terraform init
$ terraform apply -target="module.vpc" 
$ terraform apply
```

## Run examples

### emrack-pi.yaml

* Replace "virtualClusterID" in emrack-pi.yaml

* Run

```
$ kubectl apply -f emrack-pi.yaml
```

### sparkoperator-pi.yaml

* Create aws-secrets

```
$ kubectl -n spark create secret generic aws-secrets --from-literal=key=<accesskey> --from-literal=secret=<secretaccesskey>"  
```

* Run

```
$ kubectl apply -f sparkoperator-pi.yaml
```
