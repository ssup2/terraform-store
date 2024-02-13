#!/bin/bash

aws emr-containers start-job-run \
   --virtual-cluster-id jk518skp01ys9ka8b0npx9nt0 \
   --name=pi \
   --region ap-northeast-2 \
   --execution-role-arn arn:aws:iam::727618787612:role/ts-eks-emr-eks-emr-cli \
   --release-label emr-6.14.0-latest \
   --job-driver '{
     "sparkSubmitJobDriver":{
       "entryPoint": "local:///usr/lib/spark/examples/src/main/python/pi.py",
       "sparkSubmitParameters": "--conf spark.executor.instances=2 --conf spark.executor.memory=2G --conf spark.executor.cores=1 --conf spark.driver.cores=1"
     }
   }' 

