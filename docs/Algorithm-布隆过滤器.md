---
title: 布隆过滤器
date: 2020-05-10 00:56:02
tags:
---

聊聊bloom filters。

<!-- more -->

# 背景

我们想要判断一个集合中是否存在某个元素，该怎么做？

我们大概想出的解决方案，就是定义map或者类似的hash结构，然后判断该元素存不存在。

但是这个集合数据集太大，内存中放不下呢？我们也可能想到放到数据库或者文件中去一个个遍历。但是这种效率实在太低了！而且对于某些场景，比如推荐系统，我们需要尽可能实时的判断下有个内容是否已经被推送过给某个用户。这时候明显上面2种方案都不可行了。

布隆过滤器就是为了解决那种去重，而又不需要太过精确的场景的。

# 简介

布隆过滤器是由巴顿.布隆于1970年提出的，其作用：

> 布隆过滤器判断某个值是存在的，那么这个值有可能不存在。当他判断某个值不存在的时候，那么这个值一定不存在。（可以确定某个元素我真的没有）。

# 原理

布隆过滤器有2个核心的东西

- 位数组
- 若干hash函数

其工作原理就是，将集合的元素（比如下图的{x, y, z}），通过若干个hash函数计算出一个位置值，然后就将位数组上该位置值由0变为1。

![image-20200121210420661](:bloom-filter/bloom.png)

这样新来一个数，我们只要将该数 同样走下这hash函数，然后看hash出来的值位置上是不是全是1。

- 如果全是1，那么只能说明原来集合里面**可能存在该元素**。
- 如果不全为1，那么**可以确定一定不存在该元素**。



布隆过滤器器不支持删除的，因为删除该位置上的1，我们不确定这个位置会不会是由其他值计算占位的。当然可以对每个位加一个计数器来记住该1位有多少个元素引用了它，那么也是可以支持删除的。



# 简单实现

```java
import java.util.BitSet;

public class BloomFilter {
		// 定义一个位数组
    private static final int DEFAULT_SIZE = 2 << 24;
  	// 原集合
    private static final int[] seeds = new int[] {7, 11, 13, 31, 37, 61,};

    private BitSet bits = new BitSet(DEFAULT_SIZE);
    private SimpleHash[] func = new SimpleHash[seeds.length];

    public static void main(String[] args) {
        String value = "hello beijing";
        BloomFilter filter = new BloomFilter();
        System.out.println(filter.contains(value));
        filter.add(value);
        System.out.println(filter.contains(value));
    }

    public BloomFilter() {
        for (int i = 0; i < seeds.length; i++) {
            func[i] = new SimpleHash(DEFAULT_SIZE, seeds[i]);
        }
    }

    public void add(String value) {
        for (SimpleHash f : func) {
            bits.set(f.hash(value), true);
        }
    }

    public boolean contains(String value) {
        if (value == null) {
            return false;
        }
        boolean ret = true;
        for (SimpleHash f : func) {
            ret = ret && bits.get(f.hash(value));
        }
        return ret;
    }

    public static class SimpleHash {

        private int cap;
        private int seed;

        public SimpleHash(int cap, int seed) {
            this.cap = cap;
            this.seed = seed;
        }

        public int hash(String value) {
            int result = 0;
            int len = value.length();
            for (int i = 0; i < len; i++) {
                result = seed * result + value.charAt(i);
            }
            return (cap - 1) & result;
        }

    }
}

```



# 应用

爬虫的时候URL去重，避免重复爬取，等等用来去重。