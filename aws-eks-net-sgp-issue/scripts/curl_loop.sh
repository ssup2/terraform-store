#!/bin/bash

while :
do
        kubectl run mycurlpod-$RANDOM --labels=role=curl --restart="Never" --image=curlimages/curl -- amazon.com
        sleep 3
done

