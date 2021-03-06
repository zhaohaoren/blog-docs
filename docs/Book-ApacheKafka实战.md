---
title: 【读书笔记】Apache Kafka实战
date: 2020-05-15 15:35:31
tags:
---

第1章 认识Apache Kafka 1
1.1 Kafka快速入门 1
1.1.1 下载并解压缩Kafka二进制代码压缩包文件 2
1.1.2 启动服务器 3
1.1.3 创建topic 3
1.1.4 发送消息 4
1.1.5 消费消息 4
1.2 消息引擎系统 5
1.2.1 消息设计 6
1.2.2 传输协议设计 6
1.2.3 消息引擎范型 6
1.2.4 Java消息服务 8
1.3 Kafka概要设计 8
1.3.1 吞吐量/延时 8
1.3.2 消息持久化 11
1.3.3 负载均衡和故障转移 12
1.3.4 伸缩性 13
1.4 Kafka基本概念与术语 13
1.4.1 消息 14
1.4.2 topic和partition 16
1.4.3 offset 17
1.4.4 replica 18
1.4.5 leader和follower 18
1.4.6 ISR 19
1.5 Kafka使用场景 20
1.5.1 消息传输 20
1.5.2 网站行为日志追踪 20
1.5.3 审计数据收集 20
1.5.4 日志收集 20
1.5.5 Event Sourcing 21
1.5.6 流式处理 21
1.6 本章小结 21
第2章 Kafka发展历史 22
2.1 Kafka的历史 22
2.1.1 背景 22
2.1.2 Kafka横空出世 23
2.1.3 Kafka开源 24
2.2 Kafka版本变迁 25
2.2.1 Kafka的版本演进 25
2.2.2 Kafka的版本格式 26
2.2.3 新版本功能简介 26
2.2.4 旧版本功能简介 31
2.3 如何选择Kafka版本 35
2.3.1 根据功能场景 35
2.3.2 根据客户端使用场景 35
2.4 Kafka与Confluent 36
2.5 本章小结 37
第3章 Kafka线上环境部署 38
3.1 集群环境规划 38
3.1.1 操作系统的选型 38
3.1.2 磁盘规划 40
3.1.3 磁盘容量规划 42
3.1.4 内存规划 43
3.1.5 CPU规划 43
3.1.6 带宽规划 44
3.1.7 典型线上环境配置 45
3.2 伪分布式环境安装 45
3.2.1 安装Java 46
3.2.2 安装ZooKeeper 47
3.2.3 安装单节点Kafka集群 48
3.3 多节点环境安装 49
3.3.1 安装多节点ZooKeeper集群 50
3.3.2 安装多节点Kafka 54
3.4 验证部署 55
3.4.1 测试topic创建与删除 55
3.4.2 测试消息发送与消费 57
3.4.3 生产者吞吐量测试 58
3.4.4 消费者吞吐量测试 58
3.5 参数设置 59
3.5.1 broker端参数 59
3.5.2 topic级别参数 62
3.5.3 GC参数 63
3.5.4 JVM参数 64
3.5.5 OS参数 64
3.6 本章小结 65
第4章 producer开发 66
4.1 producer概览 66
4.2 构造producer 69
4.2.1 producer程序实例 69
4.2.2 producer主要参数 75
4.3 消息分区机制 80
4.3.1 分区策略 80
4.3.2 自定义分区机制 80
4.4 消息序列化 83
4.4.1 默认序列化 83
4.4.2 自定义序列化 84
4.5 producer拦截器 87
4.6 无消息丢失配置 90
4.6.1 producer端配置 91
4.6.2 broker端配置 92
4.7 消息压缩 92
4.7.1 Kafka支持的压缩算法 93
4.7.2 算法性能比较与调优 93
4.8 多线程处理 95
4.9 旧版本producer 96
4.10 本章小结 98
第5章 consumer开发 99
5.1 consumer概览 99
5.1.1 消费者（consumer） 99
5.1.2 消费者组（consumer group） 101
5.1.3 位移（offset） 102
5.1.4 位移提交 103
5.1.5 __consumer_offsets 104


5.1.6 消费者组重平衡（consumer group rebalance） 106
5.2 构建consumer 106
5.2.1 consumer程序实例 106
5.2.2 consumer脚本命令 111
5.2.3 consumer主要参数 112
5.3 订阅topic 115
5.3.1 订阅topic列表 115
5.3.2 基于正则表达式订阅topic 115
5.4 消息轮询 115
5.4.1 poll内部原理 115
5.4.2 poll使用方法 116
5.5 位移管理 118
5.5.1 consumer位移 119
5.5.2 新版本consumer位移管理 120
5.5.3 自动提交与手动提交 121
5.5.4 旧版本consumer位移管理 123
5.6 重平衡（rebalance） 123
5.6.1 rebalance概览 123
5.6.2 rebalance触发条件 124
5.6.3 rebalance分区分配 124
5.6.4 rebalance generation 126
5.6.5 rebalance协议 126
5.6.6 rebalance流程 127
5.6.7 rebalance监听器 128
5.7 解序列化 130
5.7.1 默认解序列化器 130
5.7.2 自定义解序列化器 131
5.8 多线程消费实例 132
5.8.1 每个线程维护一个KafkaConsumer 133
5.8.2 单KafkaConsumer实例+多worker线程 135
5.8.3 两种方法对比 140
5.9 独立consumer 141
5.10 旧版本consumer 142
5.10.1 概览 142
5.10.2 high-level consumer 143
5.10.3 low-level consumer 147
5.11 本章小结 153
第6章 Kafka设计原理 154
6.1 broker端设计架构 154
6.1.1 消息设计 155
6.1.2 集群管理 166
6.1.3 副本与ISR设计 169
6.1.4 水印（watermark）和leader epoch 174
6.1.5 日志存储设计 185
6.1.6 通信协议（wire protocol） 194
6.1.7 controller设计 205
6.1.8 broker请求处理 216
6.2 producer端设计 219
6.2.1 producer端基本数据结构 219
6.2.2 工作流程 220
6.3 consumer端设计 223
6.3.1 consumer group状态机 223
6.3.2 group管理协议 226
6.3.3 rebalance场景剖析 227
6.4 实现精确一次处理语义 230
6.4.1 消息交付语义 230
6.4.2 幂等性producer（idempotent producer） 231
6.4.3 事务（transaction） 232
6.5 本章小结 234
第7章 管理Kafka集群 235
7.1 集群管理 235
7.1.1 启动broker 235
7.1.2 关闭broker 236
7.1.3 设置JMX端口 237
7.1.4 增加broker 238
7.1.5 升级broker版本 238
7.2 topic管理 241
7.2.1 创建topic 241
7.2.2 删除topic 243
7.2.3 查询topic列表 244
7.2.4 查询topic详情 244
7.2.5 修改topic 245
7.3 topic动态配置管理 246
7.3.1 增加topic配置 246
7.3.2 查看topic配置 247
7.3.3 删除topic配置 248
7.4 consumer相关管理 248
7.4.1 查询消费者组 248
7.4.2 重设消费者组位移 251
7.4.3 删除消费者组 256
7.4.4 kafka-consumer-offset-checker 257
7.5 topic分区管理 258
7.5.1 preferred leader选举 258
7.5.2 分区重分配 260
7.5.3 增加副本因子 263
7.6 Kafka常见脚本工具 264
7.6.1 kafka-console-producer脚本 264
7.6.2 kafka-console-consumer脚本 265
7.6.3 kafka-run-class脚本 267
7.6.4 查看消息元数据 268
7.6.5 获取topic当前消息数 270
7.6.6 查询_ _consumer_offsets 271
7.7 API方式管理集群 273
7.7.1 服务器端API管理topic 273
7.7.2 服务器端API管理位移 275
7.7.3 客户端API管理topic 276
7.7.4 客户端API查看位移 280
7.7.5 0.11.0.0版本客户端API 281
7.8 MirrorMaker 285
7.8.1 概要介绍 285
7.8.2 主要参数 286
7.8.3 使用实例 287
7.9 Kafka安全 288
7.9.1 SASL+ACL 289
7.9.2 SSL加密 297
7.10 常见问题 301
7.11 本章小结 304
第8章 监控Kafka集群 305
8.1 集群健康度检查 305
8.2 MBean监控 306
8.2.1 监控指标 306
8.2.2 指标分类 308
8.2.3 定义和查询JMX端口 309
8.3 broker端JMX监控 310
8.3.1 消息入站/出站速率 310
8.3.2 controller存活JMX指标 311
8.3.3 备份不足的分区数 312
8.3.4 leader分区数 312
8.3.5 ISR变化速率 313
8.3.6 broker I/O工作处理线程空闲率 313
8.3.7 broker网络处理线程空闲率 314
8.3.8 单个topic总字节数 314
8.4 clients端JMX监控 314
8.4.1 producer端JMX监控 314
8.4.2 consumer端JMX监控 316
8.5 JVM监控 317
8.5.1 进程状态 318
8.5.2 GC性能 318
8.6 OS监控 318
8.7 主流监控框架 319
8.7.1 JmxTool 320
8.7.2 kafka-manager 320
8.7.3 Kafka Monitor 325
8.7.4 Kafka Offset Monitor 327
8.7.5 CruiseControl 329
8.8 本章小结 330
第9章 调优Kafka集群 331
9.1 引言 331
9.2 确定调优目标 333
9.3 集群基础调优 334
9.3.1 禁止atime更新 335
9.3.2 文件系统选择 335
9.3.3 设置swapiness 336
9.3.4 JVM设置 337
9.3.5 其他调优 337
9.4 调优吞吐量 338
9.5 调优延时 342
9.6 调优持久性 343
9.7 调优可用性 347
9.8 本章小结 349
第10章 Kafka Connect与Kafka Streams 350
10.1 引言 350
10.2 Kafka Connect 351
10.2.1 概要介绍 351
10.2.2 standalone Connect 353
10.2.3 distributed Connect 356
10.2.4 开发connector 359
10.3 Kafka Streams 362
10.3.1 流处理 362
10.3.2 Kafka Streams核心概念 364
10.3.3 Kafka Streams与其他框架的异同 368
10.3.4 Word Count实例 369
10.3.5 Kafka Streams应用开发 372
10.3.6 Kafka Streams状态查询 382
10.4 本章小结 386