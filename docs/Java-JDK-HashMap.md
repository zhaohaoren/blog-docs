---
title: 【JAVA】HashMap源码分析
date: 2020-05-10 00:39:07
tags: 
---

HashMap虽然常用，但是内部隐藏了很多实现细节，有太多值得推敲的东西，这里尽量去收录HashMap所有涉及的相关知识点。

<!-- more -->

# 数据结构-散列表

先从数据结构说起，HashMap对照的是数据结构中的**散列表**结构。在数据结构中有一种结构叫**字典**。有的书上定义：“以集合为基础的一些元素的集合，每个元素都有一个对应的key。支持元素的存在判断，插入和删除三种运算的的抽象数据类型就叫做字典“。散列表是字典的一个形式。散列表将元素的key使用一个**hash函数**映射到一个表上去（可以理解为一个地址连续的数组）来存储元素。获取数据时，只需要将key使用同样的hash函数映射对应的位置获取数据就行了。

```
Address = Hash(key)
```

但是key的数量要比计算机地址空间大很多，我们使用的hash函数必须是收敛的（即将一堆数据映射到限定大小范围内的地址空间中），因此肯定会存在冲突（2个不同的key使用hash method计算出同一个结果，有的地方也叫hash碰撞）。所以实现这样的一个散列表引出2个问题：

1. 对于给定的k-v对，找出一个合适的hash函数，能够使得k计算结果分布均匀，并且这个函数还不能太复杂。
2. hash冲突不可以避免，那在发生冲突时如何解决冲突。

## 常用的散列函数

1. 除留余数法
2. 数字分析法
3. 平方取中法
4. 折叠法

这里面只列举了一些简单的常见的hash函数，具体使用什么样的hash函数取决于你的数据性质。我们应当针对我们的数据选用合适的hash函数。

## 常见的冲突解决策略

### 闭散列

发生冲突的关键码存储在表中另一个槽内。具体方法有：

1. 线性探查法
2. 二次探查法
3. 双散列法

### 开散列

发生冲突的关键码存储在散列表主表之外。具体方法有：

1. 拉链法
2. 桶式散列

# HashMap源码

HashMap在jdk集合中算一个很重要的知识点，面试也老爱问，在阅读HashMap的源码中，发现了很多亮点（算法的巧妙运用以及一些思想），但是不是总能久记不忘，这里写一篇记录下所有的分析过程，以及那些亮点。本文主要就JDK1.8做的分析，1.7只是面试可能需要对比做的捎带，本着对技术偏喜新厌旧的原则，就不分析1.7的了，对比的那些就是网上搜罗的，反正也没多少，个人觉得看1.8的完全不要再管1.7了。

**HashMap的特性**

- key和value可以为null
- 线程不安全。如果需要满足线程安全，可以用 Collections的synchronizedMap方法使HashMap具有线程安全的能力，或者使用ConcurrentHashMap。

**数据结构概览**

hashmap基本结构是基于散列表这一数据结构。采用的是数组+链表的方式存储元素。jdk8之后，引入了红黑树来优化链表过长的情况。

![](:java-jdk-hashmap/ds.png)

如图所示，我们将1-16这个数组成为哈希表（hash table，不是jdk里面的HashTable！），数组的每一块地址空间称为一个槽（bin）。

## 源码分析（基于1.8）

### 类图

![HashMap](:java-jdk-hashmap/HashMap.png)

### 构造

这是使用hashmap的第一步，hashmap有4个构造函数。

```java
public HashMap(int initialCapacity, float loadFactor);
public HashMap(int initialCapacity);
public HashMap();
public HashMap(Map<? extends K, ? extends V> m);
```

通过构造函数我们可以看到hashmap的几个很重要的属性（也可以称为参数，更贴切）。这些参数对hashmap的性能有很大的影响。在分析构造函数之前我们有必要先了解这些参数：

```java
//初始容量 默认16
static final int DEFAULT_INITIAL_CAPACITY = 1 << 4; // aka 16
//负载因子 默认0.75
static final float DEFAULT_LOAD_FACTOR = 0.75f;
//阈值
int threshold;
```

#### 性能因子

##### 初始容量initial capacity

- 默认值为**`16`**，并且源码注释特别指出：**<u>该数必须是2的次幂！</u>**（原因后面会分析到）

初始容量就是hashmap中上图那个哈希表的长度。如果该长度过长，则会浪费空间，如果该长度过短，则会造成大量的hash冲突，降低put和get的效率。

##### 负载因子loadFactor

- **默认值为`0.75`。**

描述hashmap被填满的程度的系数。该负载因子越大，在每次扩容前所能容纳的键值对个数越多。而越多则可能会导致碰撞越多。但是太小，会导致频繁的扩容内存操作，性能更差。所以需要一个折中的值。

负载因子的存在其实是为了让hashmap的hash表可以更加均匀的存放存入的元素（最理想的结果是一个拉链也没有，每个槽刚好就一个元素）。这样查询的时候可以提供最高的性能O(1)级别，时间复杂度是最低的。

**<u>至于该值为什么是0.75?</u>** 因为篇幅比较长，我在另一篇[《hashmap负载因子为什么是0.75》]()做了解答。<u>***【#1. 为什么是0.75】***</u>

##### 阈值threshold

- 该值为 **`capacity * load factor`**

表示当hashmap存入多少元素的时候，就需要该对hash表进行扩容。

#### 最简单的构造函数

```java
public HashMap() {
    this.loadFactor = DEFAULT_LOAD_FACTOR; // DEFAULT_LOAD_FACTOR = 0.75f;
}
```

只设置了一下负载因子，其他的都是使用的默认值。

#### 带调优参数的构造函数

```java
public HashMap(int initialCapacity, float loadFactor) {
    if (initialCapacity < 0)
        throw new IllegalArgumentException("Illegal initial capacity: " +
                                           initialCapacity);
    if (initialCapacity > MAXIMUM_CAPACITY)
        initialCapacity = MAXIMUM_CAPACITY;
    if (loadFactor <= 0 || Float.isNaN(loadFactor))
        throw new IllegalArgumentException("Illegal load factor: " +
                                           loadFactor);
    //主要是这里                                       
    this.loadFactor = loadFactor;
    this.threshold = tableSizeFor(initialCapacity);
}
```

主要校验了一下传来参数：初始容量，负载因子，并设置到hashmap的属性上。并且在设置阈值的时候，并不是直接赋值的，而是使用通过tableSizeFor方法计算后的值。

注意一点：我们这里并没有设置初始容量直接到内部的属性上，而是**预先设置到了阈值上**。这是为啥呢？因为我们构造函数的时候是不会申请内存的，申请内存的操作是在put的时候resize里面进行的，但是我们hashmap中又没有定义一个属性来存储我们设置的值，所以就使用暂存在threshold上。这么写估计是作者希望减少一个内置的属性，毕竟如果去单独定义这个属性使用的频率会比较低，而且在初始化完成后，我们也不需要再通过属性来获取，而是直接通过数组的length来获取。<u>***【#2. 为什么构造函数预先设置到阈值】***</u>

##### **tableSizeFor解析**

```java
static final int tableSizeFor(int cap) {
    int n = cap - 1;
    n |= n >>> 1;
    n |= n >>> 2;
    n |= n >>> 4;
    n |= n >>> 8;
    n |= n >>> 16;
    return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
}
```

该函数的作用其实就是依据给定值，返回大于等于该给定值，并距离最近的2的次幂数。（比如给1返2，给3返4，给5返8等）。

上面具体的计算逻辑使用一个例子可以很清楚的看到这些位运算做了什么：

| 编码                                                         | 操作                    |
| ------------------------------------------------------------ | ----------------------- |
| 0100 0000 0000 0000 0000 0000 0000 1000                      | 假设用户设置了该cap     |
| 0**<u><font color='red'>10</font></u>**0 0000 0000 0000 0000 0000 0000 0111 | -1操作，n = cap -1      |
| 0**<u><font color='red'>01</font></u>**0 0000 0000 0000 0000 0000 0000 0011 | 无符号右移一位，n >>> 1 |
| 0**<u><font color='red'>11</font></u>**0 0000 0000 0000 0000 0000 0000 0111 | n &#124;= n>>>1         |
| 0**<u><font color='red'>001 1</font></u>**000 0000 0000 0000 0000 0000 0001 | n>>>2                   |
| 0**<u><font color='red'>111 1</font></u>**000 0000 0000 0000 0000 0000 0111 | n &#124;= n >>> 2       |
| 0<u>**<font color='red'>000 0111 1</font>**</u>000 0000 0000 0000 0000 0000 | n >>> 4                 |
| 0**<u><font color='red'>111 1111 1</font></u>**000 0000 0000 0000 0000 0111 | n &#124;= n >>> 4       |
| 0**<u><font color='red'>000 0000 0111 1111 1</font></u>**000 0000 0000 0000 | n >>> 8                 |
| 0**<u><font color='red'>111 1111 1111 1111 1</font></u>**000 0000 0000 0111 | n &#124;= n >>> 8       |
| 0**<u><font color='red'>000 0000 0000 0000 0111 1111 1111 1111</font></u>** | n >>> 16                |
| 0**<u><font color='red'>111 1111 1111 1111 1111 1111 1111 1111</font></u>** | n &#124;= n >>> 16      |
| 1000 0000 0000 0000 0000 0000 0000 0000                      | n+1                     |

可以看出来，每一次右移都是为了让第一个出现1的高位后面都变成1，从1开始变位2个，然后再以这2个的基础变位4个，4个变8个，直到16则可以**将一个4字节的int数字从它的第一个高位开始后面的位置全部的变成1**。这时候我们再加1就得到了给定值离它最近的那个2的次幂数，其幂就是原来数的最高位的前一位或者自身（如果本书就是2的次幂的话）。

其中，第一步我们先做了减一的操作，这是为了让本身就是2的次幂的数，返回的就是自己，比如给值8，如果不减一那么结果就是16，这显然不是我们想要的。<u>***【#3. 为什么tableSizeFor的cap要先减一】***</u>

最后return的时候，我们会判断是否大于了hashmap内置的最大容量，如果大于了则就设置为最大容量。

<u>***【#4. tableSizeFor做了什么？】***</u>

#### 设置初始容量的构造函数

```java
public HashMap(int initialCapacity) {
    this(initialCapacity, DEFAULT_LOAD_FACTOR);
}
```

其本质也是调用的是上面那个，只是负载因子使用的是默认的0.75。

这本应该是hashmap应该最常用的构造函数，阿里巴巴代码规范里面有相应的说明：

![](:java-jdk-hashmap/al.png)

至于为什么是那个公式，后面我们也会介绍。这里可以去看下一个[有趣的小实验](https://zhuanlan.zhihu.com/p/39924972)。

#### map构造新map的构造

```java
public HashMap(Map<? extends K, ? extends V> m) {
    this.loadFactor = DEFAULT_LOAD_FACTOR;
    putMapEntries(m, false);
}
```

这个构造使用频率相对较低。

#### 小结

通过上面的构造可以发现，HashMap对于内部的hash表示**采用懒加载的**，在没有开始存入元素前，只是定义了一下内部的一些设置参数。

### put流程

put方法如下

```java
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}
```

#### HashMap的hash()函数

```java
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```

通过该hash函数主要的目的是将hashcode进一步进行`位干扰`。hashcode对于Object来说是物理地址转换来的一个整数，但是考虑到用户重写了hashcode方法，但不是很好的情况的话，那么会严重增大key的碰撞率。

**具体做法：**将key的hashcode值的高16位和低16位进行亦或。

<u>***【#5. 为什么要进行位干扰？】***</u>

这首先取决于我们hashmap的取模算法：(len - 1) & hash，即将hashcode值和hash表长度-1做与运算。那么对于最后取模的结果影响因子永远都是hashcode值的低位。我们希望我们使用的hashcode值能充分利用好高位和低位的特性，所以将高位16位和低位做了一个亦或。这样新的hash值低16位也能保有了高位的信息了。

举个例子：

| 原HashCode     | 111 0100 1000 0110 1000 1001 1000 0000 |
| -------------- | -------------------------------------- |
| 无符号右移16位 | 000 0000 0000 0000 0111 0100 1000 0110 |
| 异或运算       | 111 0100 1000 0110 1111 1101 0000 0110 |
| len-1          | 000 0000 0000 0000 0000 0000 0000 1111 |
| 没干绕的运算   | 000 0000 0000 0000 0000 0000 0000 0000 |
| 干扰后的与运算 | 000 0000 0000 0000 0000 0000 0000 0110 |

干扰后高位的信息就影响到了最后的取模结果了。

**总的来说，干扰主要就是能充分利用好hashcode的整体信息，将高位的信息传播到低位上去（因为hashmap取模算法的限制）。这样做可以进一步降低碰撞的几率。**

#### 再看看putVal

```java
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
               boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    // 如果hash表为空，初始化下表
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
    // hash值和hash表长度-1 做与运算 计算出来的位置，判断上面有没有元素
    if ((p = tab[i = (n - 1) & hash]) == null)
        //没有元素，直接插入节点
        tab[i] = newNode(hash, key, value, null);
    else {
        //已经存在元素，则走判断逻辑。// p 为该table位置上已经存在的元素
        Node<K,V> e; K k;
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            // 判断得插入的元素key和当前位置上的元素相同。则让e引用 原位置上的node
            e = p;
        else if (p instanceof TreeNode)
            // 如果发现table处位置已经是TreeNode了，就按照树的形式put
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        else {
            // 如果和hash表元素不一样，则开始拉链以及后面可能的树化
            for (int binCount = 0; ; ++binCount) { // 一个死循环，遍历当前位置上的拉链。当前判断节点为e
                if ((e = p.next) == null) {
                    // 如果遍历到链条的末尾了，就创建新node加进去
                    p.next = newNode(hash, key, value, null);
                    // 此时我们判断下，遍历了多少次了，如果大于等于8-1，那么说明就要转为红黑树
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        treeifyBin(tab, hash);
                    //完成
                    break;
                }
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    // 如果在这中间发现了key重复的，就退出。
                    break;
                //处理下一个
                p = e;
            }
        }
        // 上面处理完了，此时的e指向的是该元素所应该在的位置。
        if (e != null) { // existing mapping for key
            V oldValue = e.value;
            // 如果设置了替换老的值 或者 老的值为null
            if (!onlyIfAbsent || oldValue == null)
                //将新值替换
                e.value = value;

            afterNodeAccess(e);
            // 返回旧的值
            return oldValue;
        }
    }
    //hashmap变化计数器+1
    ++modCount;
    //这时候检验hashmap是否超过阈值了，超过就扩容
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict);
    return null;
}
```

大致流程如下

![](:java-jdk-hashmap/flow.png)

这里面有下面几个重点：

##### **hashmap取模算法**

```java
p = tab[i = (n - 1) & hash] //n为当前hash表的长度
```

n-1和hash做与运算可以保证，最后的结果等会散列到0-n的地址空间上。并且位运算的计算效率高。

##### resize()扩容&初始化方法

```java
final Node<K,V>[] resize() {
    Node<K,V>[] oldTab = table;
    //因为要进行初始化/扩容，所以这两个是原始的初始容量和阈值
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    int oldThr = threshold;
    int newCap, newThr = 0;
    if (oldCap > 0) {
        // 如果原始容量大于0 说明这次是扩容操作
        if (oldCap >= MAXIMUM_CAPACITY) {
            //检验下是否达到了最大的容量，达到就不扩容了。
            threshold = Integer.MAX_VALUE;
            return oldTab;
        }
        // 检验下扩容2倍后是否达到最大容量，如果没有达到就扩容2倍
        else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                 oldCap >= DEFAULT_INITIAL_CAPACITY)
            //扩容2倍
            newThr = oldThr << 1; // double threshold
    }
    // 如果原来的阈值大于0 就将其设置为新的容量大小（这里主要来源是构造函数里面tableSizeFor设置的是该值）
    else if (oldThr > 0) // initial capacity was placed in threshold
        newCap = oldThr;
    else {               // zero initial threshold signifies using defaults
        //如果该值为0，那么全部使用默认去构造他，因为他一定使用了无参的默认构造
        newCap = DEFAULT_INITIAL_CAPACITY;
        newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
    }
    if (newThr == 0) {
        // 如果上面走了一轮了 发现没有设置新的阈值，那么就是上面oldThr > 0的情况了，这时候这里设置下新的阈值。
        float ft = (float)newCap * loadFactor;
        newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                  (int)ft : Integer.MAX_VALUE);
    }

    threshold = newThr;
    //申请新的内存空间
    @SuppressWarnings({"rawtypes","unchecked"})
    Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
    table = newTab;
    if (oldTab != null) {
        // 如果原来有表，那么久开始迁移表里面的数据
        for (int j = 0; j < oldCap; ++j) {
            Node<K,V> e;
            if ((e = oldTab[j]) != null) {
                oldTab[j] = null;
                if (e.next == null)
                    //该位置原来只有一个node，直接重新散列到新位置
                    newTab[e.hash & (newCap - 1)] = e;
                else if (e instanceof TreeNode)
                    //如果是树，就使用树的散列操作。分成2个树，而且如果树里面node小于6的时候会再转为链表。
                    ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                else { // preserve order
                    //原来位置上是一个链表，就要将该链表拆成2份，一份还是在原来位置，一份会在其2倍便宜的高位。
                    // l 代表低位
                    Node<K,V> loHead = null, loTail = null;
                    // h 代表高位
                    Node<K,V> hiHead = null, hiTail = null;
                    Node<K,V> next;
                    //遍历链表
                    do {
                        next = e.next;
                        //这个其实就是判断该节点是在原位置还是在下一个便宜位置的。
                        if ((e.hash & oldCap) == 0) {
                            //在原位置
                            if (loTail == null)
                                loHead = e;
                            else
                                loTail.next = e;
                            loTail = e;
                        }
                        else {
                            //不在原位置，在其偏移位置
                            if (hiTail == null)
                                hiHead = e;
                            else
                                hiTail.next = e;
                            hiTail = e;
                        }
                    } while ((e = next) != null);
                    //拆分后的链表放到新的位置上去
                    if (loTail != null) {
                        loTail.next = null;
                        newTab[j] = loHead;
                    }
                    if (hiTail != null) {
                        hiTail.next = null;
                        newTab[j + oldCap] = hiHead;
                    }
                }
            }
        }
    }
    return newTab;
}
```

这也是一个很关键的函数。其主要目的是初始化内部的hash表，或者做2倍扩容。并且设置好初始化或者扩容后的初始容量和阈值的值。

这里面有下面几个关键的地方

###### 设置 threshold和newCap

在这里面我们先计算出我们扩容后这些属性的值之后才申请数组内存的。在计算过程中，要考虑到边界问题（是否超过了最大的容量）。

###### 链表的再散列

当我们扩容后需要对原来的链表再散列。这里主要说下原来是链表的情况（红黑树后期会单独讲，其他的很简单看代码就明白了）。

首先明白一点：扩容后，因为我们设计的原因，原来的拉链里面的node会重新散列的位置也只有2处：原来的位置，原来位置2倍的偏移位置。

为什么呢？举个例子：

扩容前：

    1010 1001 

& 0000 1111 （16-1）

=  0000 1001 

扩容后：

    101**<font color='red'>0</font>** 1001 

& 000**<font color='red'>1</font>** 1111 （32-1）

=  0000 1001 

我们可以看到扩容后，其实和数组长度掩码做运算其实就是多了一个1位（红色加粗）。这个1位和原来的hash值的&结果，决定了答案只有2种：0000 1001 / 0001 10001。这2个值差的就是一个2倍偏移位置（即原来的位置+扩容扩大的长度）

所以影响到位置变不变的是原来的hash值中的绿色加粗的那一位（如果这个位置是0，那么位置就不变，如果那个位置是1，那么就偏移）。

###### 什么时候进行树化

红黑树相关的内容我们这里不多讲，但是hashmap什么时候转为红黑树有需要注意的点。

先看下树化的方法

```java
final void treeifyBin(Node<K,V>[] tab, int hash) {
    int n, index; Node<K,V> e;
    //1
    if (tab == null || (n = tab.length) < MIN_TREEIFY_CAPACITY) //MIN_TREEIFY_CAPACITY =64
        resize();
    else if ((e = tab[index = (n - 1) & hash]) != null) {
        ...
    }
}
```

从上面可以看出，链表转为红黑树需要满足2个条件

- 链表长度超过8个（这是HashMap内部定义的一个边界值，至于为什么是8注释里面有介绍，即在0.75的负载因子下，根据泊松分布公式计算出来一个bin中node超过8个的概率已经很低了（0.00000006），所以设置为8）
- map中存储的元素总数大于等于64个的时候，如果小于64会优先考虑先去扩容

###### 什么时候树转为链表

若桶中链表元素个数小于等于6时，树结构还原成链表。

```java
final void split(HashMap<K,V> map, Node<K,V>[] tab, int index, int bit) {
    ....
    // 树的拆分
    if (loHead != null) {
        if (lc <= UNTREEIFY_THRESHOLD)
            tab[index] = loHead.untreeify(map);
        else {
            tab[index] = loHead;
            if (hiHead != null) // (else is already treeified)
                loHead.treeify(tab);
        }
    }
    if (hiHead != null) {
        if (hc <= UNTREEIFY_THRESHOLD)
            tab[index + bit] = hiHead.untreeify(map);
        else {
            tab[index + bit] = hiHead;
            if (loHead != null)
                hiHead.treeify(tab);
        }
    }
}
```

在树的拆分中，会判断拆分后的数是不是小到可以转为链表了。如果可以转为就转成链表。

因为红黑树的平均查找长度是log(n)，长度为8的时候，平均查找长度为3，如果继续使用链表，平均查找长度为8/2=4，这才有转换为树的必要。链表长度如果是小于等于6，6/2=3，虽然速度也很快的，但是转化为树结构和生成树的时间并不会太短。

还有选择6和8，中间有个差值7可以有效防止链表和树频繁转换。假设一下，如果设计成链表个数超过8则链表转换成树结构，链表个数小于8则树结构转换成链表，如果一个HashMap不停的插入、删除元素，链表个数在8左右徘徊，就会频繁的发生树转链表、链表转树，效率会很低。[参考]([https://www.cnblogs.com/xc-chejj/p/10825676.html])

### get流程

hashmap有2种常用的get方法：

```java
public V get(Object key)  //依据key 获取值
public V getOrDefault(Object key, V defaultValue) //依据key获取值，如果没有key，返回用户给定的默认值
```

get的流程就很简单了，主要的逻辑都在这里面：

```java
final Node<K,V> getNode(int hash, Object key) {
    Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
    if ((tab = table) != null && (n = tab.length) > 0 &&
        (first = tab[(n - 1) & hash]) != null) {
        if (first.hash == hash && // always check first node
            ((k = first.key) == key || (key != null && key.equals(k))))
            return first;
        if ((e = first.next) != null) {
            if (first instanceof TreeNode)
                return ((TreeNode<K,V>)first).getTreeNode(hash, key);
            do {
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    return e;
            } while ((e = e.next) != null);
        }
    }
    return null;
}
```

主要就是计算key所在的位置，然后看所在位置上是链表还是树。然后使用不同的策略去查询出对应key的node。

### remove流程

remove的主要逻辑在

```java
final Node<K,V> removeNode(int hash, Object key, Object value,
                           boolean matchValue, boolean movable) {
    Node<K,V>[] tab; Node<K,V> p; int n, index;
    // 判断数组不为空，并且该key的hash值不为散列的位置上bin不为空
    if ((tab = table) != null && (n = tab.length) > 0 &&
        (p = tab[index = (n - 1) & hash]) != null) {
        Node<K,V> node = null, e; K k; V v;
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            // 如果第一个位置就相同 就指向第一个
            node = p;
        else if ((e = p.next) != null) {
            // 第一个位置不相同，但是后面有拉链
            if (p instanceof TreeNode)
                //如果是树，去遍历树查看是否有该key
                node = ((TreeNode<K,V>)p).getTreeNode(hash, key);
            else {
                //如果是拉链，遍历他
                do {
                    if (e.hash == hash &&
                        ((k = e.key) == key ||
                         (key != null && key.equals(k)))) {
                        node = e;
                        break;
                    }
                    p = e;
                } while ((e = e.next) != null);
            }
        }
        //上面主要是查找，并node标记位置。下面是开始删除
        if (node != null && (!matchValue || (v = node.value) == value ||
                             (value != null && value.equals(v)))) {
            if (node instanceof TreeNode)
                ((TreeNode<K,V>)node).removeTreeNode(this, tab, movable);
            else if (node == p)
                // 如果是第一个就相同就让该位置指向p的下一个节点
                tab[index] = node.next;
            else
                //p是node的前节点，p的next执行node的下一个，就删除了node。
                p.next = node.next;
            ++modCount;
            --size;
            afterNodeRemoval(node);
            return node;
        }
    }
    return null;
}
```

## 使用

先列举一些经常使用的方法：

```java
Map<K,V> map = new HashMap<>(16 /*initialCapacity*/); //申明，建议构造指定初始散列表大小
map.put(k,v); //存放，k和v都可以为null
map.get(k); //获取
map.getOrDefault(k,v2); //获取，没有值则返回v2
map.containsKey(k); //判断key是否存在
map.keySet(); //获取所有的key，同理还有values()获取所有的值
```

这里强调下，在初始化一个HashMap的时候，最好指定下初始化初始容量。具体的规则（Alibaba代码规范）：

- 如果不确定元素的个数，指定16，也就是内置默认值；
- 如果确定：initialCapacity=(需要存储的元素个数 / 负载因子) + 1； 负载因子默认0.75



## 并发存在问题

hashmap是线程不安全的，所以put和get的时候本身就存在并发的常见问题，写未读，重复写等，不过有一个特殊的线程不安全的行为是发生在hash表扩容的时候的。

在jdk1.7的时候，因为扩容后节点的rehash过程会导致，hash表的拉链出现一个死环（尾结点指向头节点）。不过在jdk1.8中已经不存在了，这块逻辑后面后期整理。(导致的原因主要是jdk1.7的rehash过程)

此时线程1和线程2此时都走到了rehash这一步。jdk的rehash代码如下：

```java
void transfer(Entry[] newTable) {
    Entry[] src = table;
    int newCapacity = newTable.length;
    for (int j = 0; j < src.length; j++) {
        Entry<K,V> e = src[j];
        if (e != null) {
            src[j] = null;
          	//就是遍历链表，判断是否需要移位，如果需要移位就摘出该元素放到新的位置上去。
            do {
                Entry<K,V> next = e.next; // * 假设此时线程1被挂起
                int i = indexFor(e.hash, newCapacity);
                e.next = newTable[i];
                newTable[i] = e;
                e = next;
            } while (e != null);
        }
    }
}
```

假设当前HashMap结构如图（图片来自网络）：

![image-20200215220430888](:java-jdk-hashmap/hashmap_cycle.png)

此时老的表长度为2，在1位置上有3，7，5三个节点，现在扩容长度为4，需要将3，5，7节点进行偏移。

此时【线程1：e->3，next->7】【线程2将链表已经完全处理结束：将位置1处的3和7全部移动到了位置3处。】

这时候我们可以发现此时3和7的顺序是颠倒的（线程2上e和next是线程1当前的e和next指向）。这时候线程1开始执行。

```java
e.next = newTable[i];
newTable[i] = e;
e = next;
```

这时候执行到最后一行next=e。此时【线程1：e->7】。继续下一次循环。此时更新了next【线程1：e->7，next->e.next->3】如下图：

![hashmap_cycle2](:java-jdk-hashmap/hashmap_cycle2.png)



循环继续：当前e指向了7。table[3]执行了3。这时候我们按照线程1的要求会应该将7摘下放入table[3]位置，然后e和next后移后如图：

![hashmap_cycle3](:java-jdk-hashmap/hashmap_cycle3.png)

之后继续，线程1将3摘下来放入table[3]位置。

![hashmap_cycle4](:java-jdk-hashmap/hashmap_cycle4.png)

e的next=newTable[i]=7，newTable[i]=e=3，e=next=null遍历到此结束。此时3头插入7，7的next是3，3的next再指向了7构成了死环。

其实主要原因就是1.7中，rehash的时候遍历列表需要移位的元素是采用**头部插入**的方式进行插入的，当另外的一个线程将当前线程已经指定了但是还没有进行偏移的节点给插入新位置了，那么当前线程原来的e和next的顺序是颠倒的，这在当前线程后面的操作中会导致死循环。



# 附全部源码和注释

todo