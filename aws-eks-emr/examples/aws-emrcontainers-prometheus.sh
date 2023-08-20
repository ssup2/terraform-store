#!/bin/bash

aws emr-containers start-job-run \
   --virtual-cluster-id jk518skp01ys9ka8b0npx9nt0 \
   --name=pi \
   --region ap-northeast-2 \
   --execution-role-arn arn:aws:iam::727618787612:role/ts-eks-emr-eks-emr-cli \
   --release-label emr-6.8.0-latest \
   --job-driver '{
     "sparkSubmitJobDriver":{
       "entryPoint": "local:///usr/lib/spark/examples/src/main/python/pi.py",
       "sparkSubmitParameters": "--conf spark.executor.instances=2 --conf spark.executor.memory=2G --conf spark.executor.cores=1 --conf spark.driver.cores=1"
     }
   }' \
   --configuration-overrides '{
     "applicationConfiguration": [
       {
         "classification": "spark-defaults",
         "properties": {
           "job-start-timeout":"1800",
           "spark.ui.prometheus.enabled":"true",
           "spark.executor.processTreeMetrics.enabled":"true",
           "spark.kubernetes.driver.annotation.prometheus.io/scrape":"true",
           "spark.kubernetes.driver.annotation.prometheus.io/path":"/metrics/executors/prometheus/",
           "spark.kubernetes.driver.annotation.prometheus.io/port":"4040",
           "spark.kubernetes.driver.service.annotation.prometheus.io/scrape":"true",
           "spark.kubernetes.driver.service.annotation.prometheus.io/path":"/metrics/driver/prometheus/",
           "spark.kubernetes.driver.service.annotation.prometheus.io/port":"4040",
           "spark.metrics.conf.*.sink.prometheusServlet.class":"org.apache.spark.metrics.sink.PrometheusServlet",
           "spark.metrics.conf.*.sink.prometheusServlet.path":"/metrics/driver/prometheus/",
           "spark.metrics.conf.master.sink.prometheusServlet.path":"/metrics/master/prometheus/",
           "spark.metrics.conf.applications.sink.prometheusServlet.path":"/metrics/applications/prometheus/"
         }
       }
     ]
   }'
