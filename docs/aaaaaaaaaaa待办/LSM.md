---
title: LSM-Tree
categories: 数据结构
tags:
  - 数据库
date: 2020-02-10 18:09:29
---

简单学习下LSM-Tree。

<!-- more -->

我们都知道Mysql使用的是B-Tree在作为其InnoDB还是MyIsam存储引擎的数据结构，使用该类Tree的结构的问题就是无论对于读写都会有大量的随机IO（一个page一个page的存储，每个page大概16k），这会严重影响到程序的性能，所以Mysql等数据库会采用一些策略来尽量减少随机IO的高频发生。

因为这方面的需求，所以有人便想有没有一种模型，可以将这些随机IO全部都转为顺序IO？这就是LSM-Tree（Log-Structured Merge-Tree）。

我们采用B-Tree来做Mysql的存储引擎的时候，更多的还是考虑到了HHD的存储结构的局限性，但是随着SSD的崛起（HHD其实在我看来，退出舞台其实是早晚的事情了），B-Tree所能带来的优越性就很鸡肋了。而LSM对于SSD可以更加充分的发挥其性能。





LSM-Tree就是将所有的写都转为顺序写，

## 历史

- Log-structured merge-tree (简称 LSM tree) 可以追溯到1996年 Patrick O'Neil等人的论文。最简单的LSM tree是两层树状结构C0,C1。 C0比较小，驻留在内存，当C0超过一定的大小， 一些连续的片段会从C0移动到磁盘中的C1中，这是一次merge的过程。在实际的应用中， 一般会分为更多的层级(level)， 而层级C0都会驻留在内存中。

![](/Users/zhaohaoren/workspace/blog/hexo/source/img/lsm/lsm-tree.png)

- 2006年， Google发表了它的那篇著名的文章: Bigtable: A Distributed Storage System for Structured Data, 不但催生了 HBase这样的项目的诞生， 而且广泛地引起了大家对 LSM tree这种数据结构重视。



- 之后， 2007 HBase, 2010年 Cassandra， 2011年 LevelDB, 2013年 RocksDB, 2015年 InfluxDB的 LSM tree引擎等众多的 基于LSM tree的k/v数据库(引擎)诞生。

- LevelDB 也是由Google的牛人 Jeffrey Dean 和 Sanjay Ghemawat创建的，被多个NoSql数据库用作底层的存储引擎。 RocksDB fork自LevelDB，但为多核和SSD做了很多的优化， 增加了一些有用的特性，比如Bloom filters、事务、TTL等，被Facebook、Yahoo!和Linkedin等公司使用。









写很多，读很少（比如历史表单的数据）。

levelDB和rocksDB对其优化，设计为level的结构











## LSM-Tree

首先分为2个部分：内存，磁盘

然后就是compaction



## read

## compaction

2种compaction：tiered和leveled







现在很多数据库或者引擎对LSM做了很多优化，这个后面有空再整理。

