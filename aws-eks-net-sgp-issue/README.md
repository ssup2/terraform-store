# aws-eks-net-sgp-issue 

## About issue

In an environment where SGPP (Security Group per Pod) pods are created and repeated quickly, there is an issue where some SGPP pods that have just been created temporarily cannot communicate with other Pods. Due to this issue, the just created SGPP pod may temporarily fail to communicate with the CoreDNS pod, resulting in DNS query failure.

## Cause of issue

When SGPP pods are repeatedly created and deleted, some pods can be used by recycling the IP of previously deleted pods. However, even if the IP is the same, Mac address is very likely to be different from before. This is because when the SGPP pod repeats creation and deletion, the Branch ENI used by the SGPP pod also repeats creation/deletion. (SGPP pod does not currently provide warm IP feature in Linux environment.)

Linux kernel manages the ARP cache, which stores IP and Mac Address mapping information to minimize frequent ARP requests. The problem is that in an environment where IP and Mac address mapping can change due to the creation or deletion of SGPP pods, there is a high probability that the ARP cache information stored by Linux kernel is invalid.

This issue occurs when there is a mismatch between the actual IP and Mac address mapping information and the IP and Mac address stored in the ARP cache. The timeout of ARP cache is approximately 60 to 90 seconds. Therefore, this issue may occur if IP is recycled within 60 seconds. In particular, as there are few available IPs in the pod's subnet, the probability of this issue occurring increases as the frequency of IP reuse increases.

## How to solve this issue

When a SGPP pod is removed, VPC RC (Resource Controller) operating in the EKS control plane does not immediately delete the branch ENI used by the removed SGPP Pod, but waits for the IP cooldown time before deleting it. The reason for using the IP cooldown time is to prevent the IP of the removed SGPP pod from being immediately recycled.

Previously, the default IP cooldown time was 30 seconds and could not be set by the user. Currently, the default IP cooldown time has been increased to 60 seconds, and can be further increased through [user settings](https://github.com/aws/amazon-vpc-resource-controller-k8s/blob/master/docs/sgp/sgp_config_options.md). As the default IP Cooldown time has increased to 60 seconds, the probability of this issue occurring without separate settings has decreased. If you want to completely prevent the issue from occurring, you can set a value of 70 seconds or more.

## Issue Test

### How test

1. Create EKS cluster with this terraform
2. Run `test/test.sh`
3. Count `Error` status pods

### Result

* Total pod count : 200

|IP Cooldown Time|Error status pod count| 
|---|---|
|30s (Preview Default Cooldown Time)| 29|
|60s (Current Default Cooldown Time)|  2|
|70s|  0|
