locals {
  name = "ts-eks-emr"

  region   = "ap-northeast-2"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr = "10.0.0.0/16"

  s3_bucket_spark_history     = "ssup2-spark-history"
  s3_bucket_spark_history_dir = "history"
}
