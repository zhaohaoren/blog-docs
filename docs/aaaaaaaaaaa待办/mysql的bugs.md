---
title: mysql的bugs
categories: 文章分类
tags:
  - 标签1
date: 2019-12-27 14:20:54
---

这里记录一些日常使用mysql遇到的问题，有些是mysql的bug，有些是使用要注意的事项。

<!-- more -->

## 谨慎使用limit offset,size，不止是偏移性能问题！

- 问题描述

  - mysql 5.7

  - ```sql
    select * from tb limit 10000,5000;	
    ```

  - 正常条件下我们需要分页是一定禁止使用offset,size这种方法的。但是这次情况特殊，数仓给了一个表，数据不大，但是没有一个字段是有索引的，所有就直接使用offset,size遍历这个表进行处理。但是后来测试发现获得到的数据量变小了。做了很多测试：一个13000条数据，我0-5000,5000-10000的数据是ok的，但是10000-13000的数据里面和前2个数据集有大量的重复！

  - 考虑使用order by，但是我表是没有索引的，所以我觉得使用order by还增加了一次排序损耗，就一开始没考虑使用。

  - 还有一个有意思的现象：如果只select一个索引字段，和select非只有索引字段，他们的结果也是不一致的。mysql的底层为了更快的显示结果会依据不同存储引擎采用不同的筛选数据策略。

- 说明

  - 参考https://forums.mysql.com/read.php?21,239471,239688#msg-239688

- 注意

  - 使用最好加order by，并且最好order by 一个不重复字段。
    - 后来查该问题的时候，又得知了order by一个字段，如果该字段重复数据比较多，那么分页的数据也是会不准确的（这个网上解释很多）。
  - 能不用就不用。

