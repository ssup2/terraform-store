# aws-eks-net-sgp-issue 

## About issue

In an environment where SGPP (Security Group per Pod) pods are created and repeated quickly, there is an issue where some SGPP pods that have just been created temporarily cannot communicate with other Pods. Due to this issue, the just created SGPP pod may temporarily fail to communicate with the CoreDNS pod, resulting in DNS query failure.

## Cause of issue

When SGPP pods are repeatedly created and deleted, some pods can be used by recycling the IP of previously deleted pods. However, even if the IP is the same, Mac address is very likely to be different from before. This is because SGPP pod does not currently provide warm IP feature in Linux environment.

Linux kernel manages the ARP cache, which stores IP and Mac Address mapping information to minimize frequent ARP requests. The problem is that in an environment where IP and Mac address mapping can change due to the creation or deletion of SGPP pods, there is a high probability that the ARP cache information stored by Linux kernel is invalid. 

This issue occurs when there is a mismatch between the actual IP and Mac address mapping information and the IP and Mac address stored in the ARP cache. The timeout of ARP cache is approximately 60 to 90 seconds. Therefore, this issue may occur if IP is recycled within 60 seconds. In particular, as there are few available IPs in the Pod's subnet, the probability of this issue occurring increases as the frequency of IP reuse increases.

## How to solve this issue

## Issue Test

* IP Cooldown 30s (Preview Default Cooldown Time)
  ```
  ```

* IP Cooldown 60s (Current Default Cooldown Time)

* IP Cooldown 70s (Modify with )
