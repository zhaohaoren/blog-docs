---
title: mysql索引失效记录
categories: 文章分类
tags:
  - mysql
  - 索引
date: 2019-11-04 20:03:02
---

记录一些在日常遇到过的，那些比较坑的，mysql索引失效的情况。

<!-- more -->

# is null 和 is not null

问题起因：

我需要找表A存在但是表B不存在的某个字段的数据。于是有了下面sql：

```mysql
SELECT a.xx
FROM a LEFT JOIN b ON a.xx = b.xx
WHERE b.xx IS NULL;
```

但是explain却是:

| select_type | table | type |
| ----------- | ----- | ---- |
| SIMPLE      | a     | ALL  |
| SIMPLE      | b     | ref  |

索引失效了！

https://blog.csdn.net/leige_ge/article/details/81975408

在使用的时候要注意该索引的生效和字段的设置有关系：

- 一个字段如果设置了NotNull，那么is null 和 is not null 都会失效。
- 一个字段如果没有设置，则生效但是生效范围不一样，not null是range，is null是ref。

再看这篇：https://www.jb51.net/article/29122.htm

oh~~，好像是我犯了大忌！