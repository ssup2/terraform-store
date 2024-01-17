#!/bin/bash

i=0
until [ $i -ge 200 ]
do
        i=$(expr $i + 1)
        kubectl run mycurlpod-$i --labels=role=curl --restart="Never" --image=curlimages/curl -- amazon.com
        sleep 5
done

