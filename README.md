# Skyward for the Xiaomi 17 Pro (pandora)

小米 17 Pro 的 recovery。内核与分区布局沿用官方 `OS4.0.4.0.XBLCNXM`；
`device.toml` 与外壳取自一份能解密的成品镜像，只把 `system/bin/recovery` 换成新版。

## 解密

这份配置把 secure world 全链起起来（qseecomd → hlosminkdaemon → onekeymint →
gatekeeper → secure_element → weaver），`secure_element` 的 `ready_service` 等
`ISecureElement/eSE1` 注册。

17 Pro 的 weaver 是 **NXP** 的（`android.hardware.weaver-service.nxp-qti`），
与小米 17（Thales）不同，所以这里不需要绕开 secure element。
已知代价：`secure_element-service.qti` 注册约 12 秒，`brought up in` 约 14 秒。

## 刷入

    fastboot flash recovery_b <镜像>

只动 recovery 分区；刷前先备份原厂 recovery。

## 出包

    ./mk.sh <版本> <名字>

编译 skyward 0.3.1 源码树，把二进制换进 `rd_pandora` 外壳树，再 cpio + lz4 + AVB。
`rd_pandora` 需先从参考镜像解出来（`cpio -id` 到该目录）。