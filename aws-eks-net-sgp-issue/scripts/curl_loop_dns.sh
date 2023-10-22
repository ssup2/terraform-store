#!/bin/bash

while :
do
        kubectl run mycurlpod-dns-$RANDOM --labels=role=curl --restart="Never" --image=curlimages/curl --overrides='{ "apiVersion":"v1","spec":{"dnsPolicy":"Default"}}' -- amazon.com
        sleep 3
done

