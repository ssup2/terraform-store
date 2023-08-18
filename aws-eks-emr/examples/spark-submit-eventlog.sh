#!/bin/bash
spark-submit \
 --master k8s://87C2A505AF21618F97F402E454E530AF.yl4.ap-northeast-2.eks.amazonaws.com \
 --deploy-mode cluster \
 --driver-cores 1 \
 --driver-memory 512m \
 --num-executors 1 \
 --executor-cores 1 \
 --executor-memory 512m \
 --conf spark.kubernetes.namespace=spark \
 --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
 --conf spark.kubernetes.container.image=public.ecr.aws/r1l5w1y9/spark-operator:3.2.1-hadoop-3.3.1-java-11-scala-2.12-python-3.8-latest \
 --conf spark.eventLog.enabled=true \
 --conf spark.eventLog.dir=s3a://ssup2-spark/history \
 --conf spark.kubernetes.driver.secretKeyRef.AWS_ACCESS_KEY_ID=aws-secrets:key \
 --conf spark.kubernetes.driver.secretKeyRef.AWS_SECRET_ACCESS_KEY=aws-secrets:secret \
 --conf spark.kubernetes.executor.secretKeyRef.AWS_ACCESS_KEY_ID=aws-secrets:key \
 --conf spark.kubernetes.executor.secretKeyRef.AWS_SECRET_ACCESS_KEY=aws-secrets:secret \
 local:///opt/spark/examples/src/main/python/pi.py
