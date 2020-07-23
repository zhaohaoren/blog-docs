---
title: Elasticsearch问题汇总
categories: 遇到的问题
tags:
  - Elasticsearch
date: 2019-12-12 17:28:30
---

收录一些ES在使用中的问题。

<!-- more -->

# MatchPhrase 搜不出来了？

## 描述

今天搜了一个公司名：“长沙远卓电子科技有限公司”，我搜索词是“远卓电子”。结果意外的发现结果是null。

## 原因

match_phrase的查询规则是：

- 经过分词后的所有词都要出现在字段中。
- 字段中词项的顺序要一致。





## 解决