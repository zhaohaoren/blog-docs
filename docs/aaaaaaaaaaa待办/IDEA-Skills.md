---
title: IDEA 的一些技巧
categories: IDE
tags:
  - IDE
thumbnail: ../img/idea.png
date: 2019-06-05 10:38:53
---

记录一下个人平时用IDEA时一些比较好用的插件、用法、功能特性、快捷键......
<!-- more -->

## 使用代码块
这是之前VisualStudio很喜欢的一个功能，没想到IDEA也有。代码块可以在代码全部缩进的时候方便的定位代码位置。
使用方法：选中代码块 -> cmd+opt+t -> 用region注释包含代码块。
{% codeblock lang:java %}
public class Class {
    //region 描述信息
    public static void main(String[] args) {
        System.out.println("hi");
    }
    //endregion
}
{% endcodeblock %}

## 一键生成所有set方法
创建一个很多属性的对象，有时候不得不写set方法进行设置。这时候很容易乱了也很麻烦。
使用方法：下载插件 -> https://github.com/yoke233/genSets/releases -> 构建对象时候.allset会自动有提示然后帮你一键生成set方法。