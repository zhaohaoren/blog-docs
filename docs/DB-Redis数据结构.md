---
title: 【Redis】基本数据结构及原理
date: 2020-05-10 00:54:48
tags:
---

简要记录下redis基本数据结构及内部实现的原理。这里面其实每种结构都可以单独写一篇，后期有时间做拆分详细说明。

<!-- more -->

# String

等同于Java中的**ArrayList**。内部是一个字符数组（动态数组）。

C中定义一个字符串数组“redis”。数组的结构如下：

```c
[‘r’, ‘e’, ‘d’, ‘i’, ‘s’, ‘\0’]
```

最后的一个’\0’是空字符，表示字符串的结尾。

Redis没有直接使用了C语言的字符串结构，而是对其做了一些封装，使用了简单动态字符串(simple dynamic string, SDS)的抽象类型。

Redis中，默认以SDS作为自己的字符串表示。只有在一些字符串不可能出现变化的地方使用C字符串。

## SDS

定义如下：

```c
struct sdshdr {
    // 字符串的长度
    int len;
    // 空闲字节的数目
    int free;
    // 字节数组，用于储存字符串
    char buf[];
};
```

**多出了 len 属性以及 free 属性。**

**注意**：buf的大小等于len+free+1，其中多余的1个字节是用来存储’\0’的。

这时候存储的结构为：

![string1](:redis-ds/string1.png)

为什么不使用C语言字符串实现，而是使用 SDS呢？这样实现有什么好处？

- 常数复杂度获取字符串长度。直接从len获取长度。让获取太长的数组不会成为redis的瓶颈。
- 杜绝缓冲区溢出。字符串在修改的时候，通过free判断空间是否足够，不够就扩容。
- 减少修改字符串的内存重新分配次数。
  - C语言由于不记录字符串的长度，所以如果要修改字符串，必须要重新分配内存（先释放再申请），因为如果没有重新分配，字符串长度增大时会造成内存缓冲区溢出，字符串长度减小时会造成内存泄露。
  - 而对于SDS，由于len属性和free属性的存在，对于修改字符串SDS实现了空间预分配和惰性空间释放两种策略
    - 空间预分配：对字符串进行空间扩展的时候，扩展的内存比实际需要的多，这样可以减少连续执行字符串增长操作所需的内存重分配次数。
    - 惰性空间释放：对字符串进行缩短操作时，程序不立即使用内存重新分配来回收缩短后多余的字节，而是使用 free 属性将这些字节的数量记录下来，等待后续使用。
- 二进制安全，C字符串以空字符为字符串结束的标识，一些特殊的二进制文件内容里面可能就包含空字符，因此C字符串无法正确存取。而SDS是通过len判断是否最后的。
- 兼容部分 C 字符串函数
  - 虽然 SDS 是二进制安全的，但是一样遵从每个字符串都是以空字符串结尾的惯例，这样可以重用 C 语言库<string.h> 中的一部分函数。

## 扩容

当数据小于1M，双倍扩容当前空间。

当数据大于1M，每次只扩容1M的空间。

字符串最大的长度为512M，即最大扩容到512M。



# List

类似于Java中的**LinkedList**。内部是一个**双向链表**。

链表节点的定义如下：

```c
typedef  struct listNode{
       //前置节点
       struct listNode *prev;
       //后置节点
       struct listNode *next;
       //节点的值
       void *value;  
}listNode
```

双向链表定义：

```c
typedef struct list{
     //表头节点
     listNode *head;
     //表尾节点
     listNode *tail;
     //链表所包含的节点数量
     unsigned long len;
     //节点值复制函数
     void (*free) (void *ptr);
     //节点值释放函数
     void (*free) (void *ptr);
     //节点值对比函数
     int (*match) (void *ptr,void *key);
}list
```

双向链表没什么好说的，<u>但实际上Redis内部存储的不是一个简单的LinkedList</u>。而是一种**QuickList**的结构。并且对于列表元素较少的时候，还将其优化为**ZipList（压缩列表）**的结构。

## ZipList（压缩列表）

在元素少的情况下，为了节省空间，会使用一个连续的内存空间来存储这个链表，这就是ziplist。

ziplist是由一系列特殊编码的连续内存块组成的顺序存储结构，类似于数组，ziplist在内存中是连续存储的，但是不同于数组，**为了节省内存 ziplist的每个元素所占的内存大小可以不同**。

ziplist结构如图:

![](:redis-ds/ziplist.png)

- zlbytes: ziplist的长度（单位: 字节)，是一个32位无符号整数

- zltail: ziplist最后一个节点的偏移量，<u>反向遍历</u>ziplist或者pop尾部节点的时候有用。

- zllen: ziplist的节点（entry）个数

- entry: 节点。存储元素的地方。

- zlend: 值为0xFF，用于标记ziplist的结尾

这里面最重点的实现还是entry的实现。

#### entry

entry的结构如图。

<img src=":redis-ds/ziplist2.png" style="zoom: 67%;" />

- previous_entry_length字段表示前一个元素的字节长度，占1个或者5个字节；
  - 当前一个元素的长度小于254字节时，previous_entry_length字段用一个字节表示；
  - 当前一个元素的长度大于等于254字节时，无法用一个字节来表示，就在该直接加4个字节用该4个字节来表示。

![image-20200120135142710](:redis-ds/ziplist3.png)

- encoding：节点的encoding保存的是节点的content的内容类型以及长度，encoding类型一共有两种，一种字节数组一种是整数，encoding区域长度为1字节、2字节或者5字节长。
- content：content区域用于保存节点的内容，节点内容类型和长度由encoding决定。

## QuickList（快速列表）

QuickList 其实就是将上面一系列的ziplist再使用双向指针给链接起来。

其内部结构为：

![image-20200120135356336](:redis-ds/quicklist.png)



# Hash

类似于Java中的HashMap。内部是数组+拉链的方式。只是Redis中的字典的值只能是字符串。

Hash类型在redis中一般用来存对象的。

hash表定义如下

```c
typedef struct dictht{
     //哈希表数组
     dictEntry **table;
     //哈希表大小
     unsigned long size;
     //哈希表大小掩码，用于计算索引值
     //总是等于 size-1
     unsigned long sizemask;
     //该哈希表已有节点的数量
     unsigned long used;
 
}dictht
```

哈希表是由数组 table 组成，table 中每个元素都是指向 dict.h/dictEntry 结构，dictEntry 结构定义如下：

```c
typedef struct dictEntry{
     void *key;
     union{
          void *val;
          uint64_tu64;
          int64_ts64;
     }v;
     //下一个
     struct dictEntry *next;
}dictEntry
```

内部结构如图:

![image-20200120140954903](:redis-ds/hash.png)

下面就是一些和hashmap一样比较重要的点了。

## hash算法

```c
#1、使用字典设置的哈希函数，计算键 key 的哈希值
hash = dict->type->hashFunction(key);
#2、使用哈希表的sizemask属性和第一步得到的哈希值，计算索引值
index = hash & dict->ht[x].sizemask;
```

将key的hash值和数组的长度掩码与运算。

## 扩容&收缩

### 扩容

**触发条件：**当以下条件满足任意一个时，程序就会对哈希表进行扩展操作：

- 服务器目前没有执行bgsave或bgrewriteaof命令，哈希表的负载因子>=1
- 服务器目前正在执行bgsave或bgrewriteaof命令，哈希表的负载因子>=5

每次扩展都是根据原哈希表已使用的空间扩大一倍创建另一个哈希表。

### 收缩

**触发条件：**当负载因子的值小于0.1时，程序就会对哈希表进行收缩操作

每次收缩是根据已使用空间缩小一倍创建一个新的哈希表。

## 渐近式 rehash

这个是和hashmap很不相同的一个点。redis采用的是渐进式hash。

因为rehash是一个十分耗时的操作，如果该字典很大在rehash的时候就会阻塞后面的操作。渐进的rehash会保留新旧两个hash结构。查询的时候也会同时去查这两个，在后续的定时任务以及hash操作命令中，慢慢的将旧的hash表上的数据迁移到新的hash结构中。

hash过程如图。

![在这里插入图片描述](:redis-ds/rehash0.png)

创建了一个新的hash table，ht[1]。

![](:redis-ds/rehash1.png)

在后期一步步的将老表的数据迁移到新表，然后老表会被自动回收。

在此过程中，字典的增删改查操作会同时在ht[0],ht[1]两个表上进行，比如：

- 查找一个键，会先在ht[0]中查找，没找到再到ht[1]中找。
- **新添加到字典的键值对一律会被保存到ht[1]中而不是ht[0]。**



# Set

类似于Java中的HashSet。内部相当于是一个特殊的字典，只不过该字典的值都是null。



# ZSet

类似于Java中的HashMap和SortSet的结合体。

ZSet 保证了集合的元素唯一，且可以保证一定顺序。ZSet对每个值，并给该值赋予了一个score值，我们就按照score值来进行排序。

**<u>Redis中ZSet的底层存储结构有2种：ziplist（压缩链表）和skiplist（跳表）</u>**

## ziplist

当满足下面2个条件的时候使用的是ziplist来存储元素的。

- 保存的元素数量小于128个
- 保存的所有元素的长度小于64字节

因为我们要按分数顺序插入链表中，所以空间和时间折中的考虑中，此时空间的优势>时间的优势。

![image-20200120194103161](:redis-ds/zset.png)

## skiplist

当上面2个条件不满足的时候，我们就要使用skiplist（此时空间优势<时间优势）。

**zset的skiplist其核心点主要是包括一个dict对象和一个skiplist对象。**

结构体定义：

```c
typedef struct zset{
     //跳跃表
     zskiplist *zsl;
     //字典
     dict *dice;
} zset
```

- 字典用来保存 value和score之间的映射关系。

- skiplist是个保存了排好顺序的元素的链表（跳表）。

这两种数据结构会**通过指针来共享相同元素的成员和分值**，所以不会产生重复成员和分值，造成内存的浪费。

跳表的结构图：

![skiplist上的查找路径展示](:redis-ds/skiplist.png)

跳表是数据结构中一个方便与查找有序链表的数据结构。查找单个key，skiplist和平衡树的时间复杂度都为O(log n)，大体相当。

创建跳表的流程：

![skiplist插入形成过程](http://zhangtielei.com/assets/photos_redis/skiplist/skiplist_insertions.png)



# 参考

- 《Redis设计实现》
- 《Redis深度历险》

- https://blog.csdn.net/weixin_38008100/article/details/94629753