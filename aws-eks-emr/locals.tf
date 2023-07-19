locals {
  name = "ts-eks-emr"

  region   = "ap-northeast-2"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr = "10.0.0.0/16"

  s3_bucket_spark                       = "ssup2-spark"
  s3_bucket_spark_historyserver_dir     = "history"
  s3_bucket_spark_startjobrunlog_dir    = "startjobrun"
  cloudwatch_spark_startjobrunlog_group = "spark-startjobrun"
}
