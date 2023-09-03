#!/bin/bash

aws emr-containers start-job-run \
   --virtual-cluster-id jk518skp01ys9ka8b0npx9nt0 \
   --name=pi-logs \
   --region ap-northeast-2 \
   --execution-role-arn arn:aws:iam::727618787612:role/ts-eks-emr-eks-emr-cli \
   --release-label emr-6.8.0-latest \
   --job-driver '{
     "sparkSubmitJobDriver":{
       "entryPoint": "local:///usr/lib/spark/examples/src/main/python/pi.py",
       "sparkSubmitParameters": "--conf spark.driver.cores=1 --conf spark.driver.memory=512M --conf spark.executor.instances=1 --conf spark.executor.memory=512M --conf spark.executor.cores=1"
     }
   }' \
   --configuration-overrides '{
     "monitoringConfiguration": {
       "persistentAppUI": "ENABLED", 
       "cloudWatchMonitoringConfiguration": {
         "logGroupName": "spark-startjobrun", 
         "logStreamNamePrefix": "pi-logs"
       }, 
       "s3MonitoringConfiguration": {
         "logUri": "s3://ssup2-spark/startjobrun/"
       }
     }
   }'

