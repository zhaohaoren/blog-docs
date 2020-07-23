---
title: 【JAVA】ConcurrentHashMap源码分析
date: 2020-05-10 00:59:49
tags:
---

ConcurrentHashMap源码分析

<!-- more -->

# 前言

JDK中提供了HashTable和ConcurrentHashMap两个类面向并发情况下使用HashMap的结构（或者使用Collections提供的synchronizedMap方法）。其中HashTable是通过对关键的操作全部加上synchronize同步锁来解决并发问题的，这种做法使用锁的粒度太大了，操作的时候基本就是串行化并发操作来保证并发安全，性能自然十分的差。所以JDK在1.5版本提供了ConcurrentHashMap来解决高并发场景下使用HashMap的问题。

JDK从1.7 到1.8引入了很多东西，HashMap发生了很多的变化，同时ConcurrentHashMap也做了较大的改动，本文就2个版本分别做分析及对比。

# 预备

## Unsafe

ConcurrentHashMap里面大量使用了Unsafe的东西，所以先了解下Unsafe。

Unsafe是位于`sun.misc`包下的一个类，主要提供一些用于执行**低级别、不安全**操作的方法，如直接访问系统内存资源、自主管理内存资源等。Unsafe类使Java语言拥有了类似C语言指针一样操作内存空间的能力。不正确使用Unsafe类会使得程序出错的概率变大，使得Java这种安全的语言变得不安全，所以一定要慎重使用Unsafe。

java的Unsafe主要提供的功能有：

![img](https://p1.meituan.net/travelcube/f182555953e29cec76497ebaec526fd1297846.png)

在ConcurrentHashMap中的CAS功能就是通过Unsafe来实现的，当然ConcurrentHashMap不止就使用其CAS的功能。

我们自己平时一般不会使用Unsafe里面的东西，而是用JDK为我们包装好的工具，但如果使用Unsafe提供的方法。但是注意一点：

我们使用Unsafe类去getUnsafe实例的时候是获取不到的。因为我们get的时候：

```java
private static final sun.misc.Unsafe UNSAFE; 
UNSAFE = sun.misc.Unsafe.getUnsafe();
```

可以查看下getUnsafe()这个方法：

```java
@CallerSensitive
public static Unsafe getUnsafe() {
    Class var0 = Reflection.getCallerClass();
    if (var0.getClassLoader() != null) {
        throw new SecurityException("Unsafe");
    } else {
        return theUnsafe;
    }
}
```

其中var0其实就是调用这个getUnsafe的类。

注意一点：我们正常代码是无法使用这个getUnsafe方法的，因为我们一般代码的类的ClassLoader都是ApplicationClassLoader，所以var0.getClassLoader() != null判断为true会直接抛异常。而ConcurrentHashMap的类加载器是BootStrapClassLoader，而java代码中是无法获取到BootStrapClassLoader的（BootStrap是C实现的），所以会直接返回theUnsafe对象。

所以只有BootStrap加载的那些类才能直接使用Unsafe，其他的都不能直接使用，我们可以通过2种方法去使用它：

1. 可以通过反射来获取theUnsafe对象。
2. 使用`-Xbootclasspath/a`把调用Unsafe相关方法的类A所在jar包路径追加到默认的bootstrap路径

Unsafe的各种功能这里不多赘述，[网上资料很多](https://tech.meituan.com/2019/02/14/talk-about-java-magic-class-unsafe.html)。

## HashMap

ConcurrentHashMap里面很多小细节都和其对应版本的HashMap是一样的，这里就不做赘述了。

# JDK1.7实现

## 结构

先看看结构

### 类结构

![ConcurrentHashMap](:java-jdk-concurrenthashmap/ConcurrentHashMap.png)

### 内部结构

 ![image-20200219111015592](:java-jdk-concurrenthashmap/struct.png)

存储结构和1.7的HashMap一样采用了**数组+链表**的方式；

并发控制采用的是**分段锁**的结构，每个Segment就是一把锁（ReentrantLock）。相对于HashTable来说，ConcurrentHashMap对于并发控制的锁的细粒度更细。

ConcurrentHashMap的一个kv存储单元叫**HashEntry**（类似于HashMap的Entry），Segment相当于一个仓库房间，HashEntry就是房间中的货物。多个线程访问同一个房间只能排队，但是整个ConcurrentHashMap可以排Segment.length个队伍。

## 源码

### 重要结构类

#### Segment

```java
static final class Segment<K,V> extends ReentrantLock implements Serializable {

    transient volatile HashEntry<K,V>[] table;
    transient int threshold;
    final float loadFactor;

    Segment(float lf, int threshold, HashEntry<K,V>[] tab) {
        this.loadFactor = lf;
        this.threshold = threshold;
        this.table = tab;
    }
  	//方法体略
    final V put(K key, int hash, V value, boolean onlyIfAbsent){};
    private void rehash(HashEntry<K,V> node) {};
    private void scanAndLock(Object key, int hash) {};
    final V remove(Object key, int hash, Object value) {};
    final boolean replace(K key, int hash, V oldValue, V newValue) {};
    final V replace(K key, int hash, V value) {};
    final void clear() {};
}
```

因为Segment是继承了ReentrantLock，所以Segment也是一个可重入锁。每个Segment自带了一把锁。我们从代码可见：**Segment不仅仅是一把锁，其内部自成一个小型的HashMap**。

#### HashEntry

```java
static final class HashEntry<K,V> {
    final int hash;
    final K key;
    volatile V value;
    volatile HashEntry<K,V> next;

    HashEntry(int hash, K key, V value, HashEntry<K,V> next) {
        this.hash = hash;
        this.key = key;
        this.value = value;
        this.next = next;
    }

    final void setNext(HashEntry<K,V> n) {
        UNSAFE.putOrderedObject(this, nextOffset, n);
    }
    //....
}
```

HashEntry是实际封装key/value对的类。其结构就是一个简单的**链表结构**。

### 构造函数

```java
public ConcurrentHashMap(int initialCapacity,
                             float loadFactor, int concurrencyLevel) {
        if (!(loadFactor > 0) || initialCapacity < 0 || concurrencyLevel <= 0)
            throw new IllegalArgumentException();
        if (concurrencyLevel > MAX_SEGMENTS)
            concurrencyLevel = MAX_SEGMENTS;
        // Find power-of-two sizes best matching arguments
        int sshift = 0; //位移的次数，也是ssize 2的次幂数
        int ssize = 1;
        //ssize就是segment数组大小，这里将传来的concurrencyLevel变为2的次幂数（因为put的时候也是要&来计算放在哪个segment）
        while (ssize < concurrencyLevel) {
            ++sshift;
            ssize <<= 1;
        }
        this.segmentShift = 32 - sshift; //这个在put的时候使用，为了将key的hashcode右移多少位，然后计算位于哪个segment中。32是因为hashcode是int的是32位
        this.segmentMask = ssize - 1;//segment掩码
        if (initialCapacity > MAXIMUM_CAPACITY)
            initialCapacity = MAXIMUM_CAPACITY;
        int c = initialCapacity / ssize;//每个segment存放entry数量
        //防止除法是去尾的，总和可能会小于initialCapacity。比如17/16=1 16*1<17
        if (c * ssize < initialCapacity)
            ++c;
        int cap = MIN_SEGMENT_TABLE_CAPACITY; //每个segment存放entry数量有个最小值为2，如果小于2就*2，也必须是2的倍数
        while (cap < c)
            cap <<= 1;
        // create segments and segments[0]
        // 创建segment的数组和单个segment内部带entry数组的s0
        // -- 所以1.7 不是懒加载的
        Segment<K,V> s0 =
            new Segment<K,V>(loadFactor, (int)(cap * loadFactor),
                             (HashEntry<K,V>[])new HashEntry[cap]);//segment内部其实又相当于是一个小的hashmap
        Segment<K,V>[] ss = (Segment<K,V>[])new Segment[ssize];
        UNSAFE.putOrderedObject(ss, SBASE, s0); // ordered write of segments[0]
        this.segments = ss;
    }
```

#### 三个构造参数

```java
int initialCapacity; 	//设定entry的个数，默认16
float loadFactor; 		//负载因子，默认0.75f
int concurrencyLevel; //segment的个数，默认16
```

上面2个参数和HashMap的一样，concurrencyLevel（并发等级）就是上面结构图中Segment的个数，即Segment多少个就能支持多少个线程并发的访问。

#### 执行流程

1. 参数校验和再次调整，具体做了下面的操作

- concurrencyLevel 调整为2次幂数
- 计算每个Segment中应该分配的HashEntry数组长度（**每个Segment中HashEntry的长度不能小于2**）
  - 首先通过计算公式：initialCapacity / ssize计算初步长度
  - MIN_SEGMENT_TABLE_CAPACITY=2是系统指定的每个Segment最小分配的HashEntry长度
  - 长度小于2就乘以2（也要保证是2的倍数）

2. 先创建一个Segment，并初始化好内部HashEntry数组
3. 再创建Segment数组，并将创建好的Segment放入Segment[0]

#### 构造总结

- 每个Segment中HashEntry的长度不能小于2，并且是2的倍数
- 1.7的ConcurrentHashMap不是懒加载的，而是先初始化了Segment数组以及Segment数组中第一个位置的HashEntry数组

我们这里不要将ConcurrentHashMap的结果给理解为以segment为单位的，而是还是按照HashMap一样以entry为单位，而segment只是在entry上的一个修饰。

### put函数

```java
public V put(K key, V value) {
    Segment<K,V> s;
    if (value == null)
        throw new NullPointerException();
    int hash = hash(key);
    //将hash值右移保留高位，因为要和segment长度&计算，所以hashcode保留位数和segment长度的位数应该一致。
    int j = (hash >>> segmentShift) & segmentMask;
    if ((s = (Segment<K,V>)UNSAFE.getObject          // nonvolatile; recheck
         (segments, (j << SSHIFT) + SBASE)) == null) //  in ensureSegment
        //segment为空就去生成一个
        s = ensureSegment(j);
    return s.put(key, hash, value, false);
}
```

#### 执行流程

1. 参数校验，**key和value都不能为null**。
2. 计算key的hash值，并确定该key存放在哪个Segment中。
3. 判断需要放入Segment位置是否初始化？如果没有使用ensureSegment进行初始化
4. 调用Segment的put存入元素

#### 如何确定存储Segment位置？

主要理解代码中的：

```java
(hash >>> segmentShift) & segmentMask;
```

segmentShift和segmentMask是我们在构造过程中计算出来的：

```java
this.segmentShift = 32 - sshift;
this.segmentMask = ssize - 1;
```

- ssize就是Segment数组的长度
- sshift是Segment长度对应2的次幂的次幂数，比如ssize为8，那么sshift就为3

segmentMask掩码很好理解，HashMap都是和掩码&运算来确定位置的。

`32-sshift` **则相当于HashMap的位干扰，具体作用是保留hash值的高位来和掩码&运算。**

因为int是32个字节，减去sshift其实就是相当于保留高sshift的位数，这样和ssize的二进制位的掩码&运算可以保证位置落在0~ssize中。

#### ensureSegment

上面put函数确定了我们的k/v应该存放在哪个Segment中去了，但是我们构造的时候只是初始化了第一个位置的Segment。所以如果为空需要先初始化一下Segment。

```java
private Segment<K,V> ensureSegment(int k) {
    final Segment<K,V>[] ss = this.segments;
    long u = (k << SSHIFT) + SBASE; // raw offset
    Segment<K,V> seg;
    if ((seg = (Segment<K,V>)UNSAFE.getObjectVolatile(ss, u)) == null) {
        Segment<K,V> proto = ss[0]; // use segment 0 as prototype 复用segment0的对象来创建新的segment
        int cap = proto.table.length;
        float lf = proto.loadFactor;
        int threshold = (int)(cap * lf);
        HashEntry<K,V>[] tab = (HashEntry<K,V>[])new HashEntry[cap];
        if ((seg = (Segment<K,V>)UNSAFE.getObjectVolatile(ss, u))
            == null) { // recheck
            Segment<K,V> s = new Segment<K,V>(lf, threshold, tab);
            //自旋，不断的判断操作过程中是否有其他线程的修改
            while ((seg = (Segment<K,V>)UNSAFE.getObjectVolatile(ss, u))
                   == null) {
                //cas操作
                if (UNSAFE.compareAndSwapObject(ss, u, null, seg = s))
                    break;
            }
        }
    }
    return seg;
}
```

##### 执行流程

1. 都是使用的Unsafe的方法来判断需要put的位置上的Segment是否为null。
2. 如果为null，复用Segment[0]位置上的（构造函数已经初始化的）属性来构建一个Segment对象。

上面步骤基本上没到关键的涉及真实内存操作的时候都会走Unsafe调用，是为了保证在执行的时候，没有其他线程的操作影响。

#### Segment的put函数

上面确定了所在元素是位于哪个Segment了，最后一步就是调用Segment的put方法，将元素放入HashEntry数组里面。

```java
final V put(K key, int hash, V value, boolean onlyIfAbsent) {
    //尝试获取锁，node返回可能是null就在下面put的时候初始化，
    //不是null说明在获取锁的时候，scanAndLockForPut帮我们预热完成
    HashEntry<K,V> node = tryLock() ? null :
        scanAndLockForPut(key, hash, value);
    V oldValue;
    try {
        // Segment内部的HashEntry数组
        HashEntry<K,V>[] tab = table;
        // 定位该hash值需要存储的HashEntry数组位置
        int index = (tab.length - 1) & hash;
        // 获取需要存入的数组位置上拉链的头结点
        HashEntry<K,V> first = entryAt(tab, index);
        // 遍历链表
        for (HashEntry<K,V> e = first;;) {
            // 如果当前位置上有值
            if (e != null) {
                K k;
                // 有值并且key和hash都相等。直接替换旧值
                if ((k = e.key) == key ||
                    (e.hash == hash && key.equals(k))) {
                    oldValue = e.value;
                    if (!onlyIfAbsent) {
                        e.value = value;
                        ++modCount;
                    }
                    break;
                }
                // 有值，但是key不等就往下遍历
                e = e.next;
            }
            else { //当前位置为null了，说明要么就是链表是空的，要么就是遍历到尾部了。
                if (node != null)
                   // 如果当前node在获取锁的已经初始化完成了，那么就直接头插法，将其next指向原来的头结点
                    node.setNext(first);
                else
                    // 如果node还为null，就在这里进行创建HashEntry对象并头插。
                    node = new HashEntry<K,V>(hash, key, value, first);
                int c = count + 1;
                // 判断是否需要扩容，ConcurrentHashMap只扩Segment的容量
                if (c > threshold && tab.length < MAXIMUM_CAPACITY)
                    rehash(node);
                else
                    //设置为头节点
                    setEntryAt(tab, index, node);
                ++modCount;
                count = c;
                oldValue = null;
                break;
            }
        }
    } finally {
        // 不要忘了解锁
        unlock();
    }
    return oldValue;
}
```

##### 执行流程

1. 获取锁
2. 扫描链表，采用头插法插入元素，或者key存在就更新元素
3. 判断是否需要扩容

#### rehash扩容

这个没什么好交代的，和1.7的HashMap一样，双倍扩容，链表重新分配位置。

#### scanAndLockForPut函数

这个函数的主要作用就是不断的尝试去获取锁，并且帮我们做了很多预热工作。

```java
private HashEntry<K,V> scanAndLockForPut(K key, int hash, V value) {
    //获取链表的头部
    HashEntry<K,V> first = entryForHash(this, hash);
    HashEntry<K,V> e = first;
    HashEntry<K,V> node = null;
    int retries = -1; // negative while locating node
    //循环尝试获取锁，如果获取到了就返回node
    while (!tryLock()) {
        HashEntry<K,V> f; // to recheck first below
        // 这里和0判断，主要保证创建node只会走一次
        if (retries < 0) {
            if (e == null) {
                // 遍历发现该链表没有key，就大胆的先初始化好它备用。
                if (node == null) // speculatively create node
                    node = new HashEntry<K,V>(hash, key, value, null);
                // 后面就不再执行这里了。
                retries = 0;
            }
            // 如果发现有key相同的node，那么代表要覆盖，就不创建新node
            else if (key.equals(e.key))
                retries = 0;
            else
                //继续往下遍历节点
                e = e.next;
        }
        //MAX_SCAN_RETRIES：单核是1，多核是64，
        //如果尝试的次数大于MAX_SCAN_RETRIES，则调用lock()方法阻塞，使当前线程进入同步队列中等待被唤醒
        else if (++retries > MAX_SCAN_RETRIES) {
            lock();
            break;
        }
        // 链表发生了变化，就需要重新遍历了
        else if ((retries & 1) == 0 &&
                 (f = entryForHash(this, hash)) != first) {
            e = first = f; // re-traverse if entry changed
            retries = -1;
        }
    }
    // 返回node，可能是null（获取到锁的时候，没有发现满足node的条件）也可能不是null。
    return node;
}
```

##### 做了哪些预热工作？

- 在不断尝试获取锁的过程中，扫描当前链表，判断该链表是否包含该key。
- 如果不包含就这里先初始化好HashEntry返回。否则还是返回null。

### get函数

get函数就比较简单：

```java
public V get(Object key) {
    Segment<K,V> s; // manually integrate access methods to reduce overhead
    HashEntry<K,V>[] tab;
    int h = hash(key);
    //定位Segment的位置
    long u = (((h >>> segmentShift) & segmentMask) << SSHIFT) + SBASE;
    if ((s = (Segment<K,V>)UNSAFE.getObjectVolatile(segments, u)) != null &&
        (tab = s.table) != null) {
        // 定义HashEntry数组中位置，并遍历该位置的链表判断是否有该key
        for (HashEntry<K,V> e = (HashEntry<K,V>) UNSAFE.getObjectVolatile
                 (tab, ((long)(((tab.length - 1) & h)) << TSHIFT) + TBASE);
             e != null; e = e.next) {
            K k;
            if ((k = e.key) == key || (e.hash == h && key.equals(k)))
                return e.value;
        }
    }
    return null;
}
```

#### 执行流程

1. 获取Segment位置
2. 获取HashEntry的位置
3. 遍历链表查看是否有元素，有则返回，无则返null

### remove函数

逻辑也很清晰和简单，直接看代码很清楚。

```java
public V remove(Object key) {
    int hash = hash(key);
    //定位Segment
    Segment<K,V> s = segmentForHash(hash);
    return s == null ? null : s.remove(key, hash, null);
}
```

```java
final V remove(Object key, int hash, Object value) {
    //进入Segment先获取锁
    if (!tryLock())
        scanAndLock(key, hash);
    V oldValue = null;
    try {
        HashEntry<K,V>[] tab = table;
        //定位HashEntry
        int index = (tab.length - 1) & hash;
        HashEntry<K,V> e = entryAt(tab, index);
        HashEntry<K,V> pred = null;
        while (e != null) {
            K k;
            HashEntry<K,V> next = e.next;
            //找到了待删除节点，进行删除
            if ((k = e.key) == key ||
                (e.hash == hash && key.equals(k))) {
                V v = e.value;
                if (value == null || value == v || value.equals(v)) {
                    if (pred == null)
                        setEntryAt(tab, index, next);
                    else
                        pred.setNext(next);
                    ++modCount;
                    --count;
                    oldValue = v;
                }
                break;
            }
            pred = e;
            e = next;
        }
    } finally {
        unlock();
    }
    return oldValue;
}
```

### size 方法

看很多博客都加了size分析，我也掺一脚吧。

```java
public int size() {
    // Try a few times to get accurate count. On failure due to
    // continuous async changes in table, resort to locking.
    final Segment<K,V>[] segments = this.segments;
    int size;
    boolean overflow; // size大小是否溢出
    long sum;         // 当前modCount数量
    long last = 0L;   // 上次modCount数量
    int retries = -1; // first iteration isn't retry
    try {
        for (;;) {
            //RETRIES_BEFORE_LOCK=2
            //先不走锁的方案
            if (retries++ == RETRIES_BEFORE_LOCK) {
                // 如果试了2次发现，两个modCount数量不一样，说明有修改，就将所有Segment进行加锁计算
                for (int j = 0; j < segments.length; ++j)
                    ensureSegment(j).lock(); // force creation
            }
            sum = 0L;
            size = 0;
            overflow = false;
            //不加锁计算出所有Segment的count和modCount
            for (int j = 0; j < segments.length; ++j) {
                Segment<K,V> seg = segmentAt(segments, j);
                if (seg != null) {
                    sum += seg.modCount;
                    int c = seg.count;
                    if (c < 0 || (size += c) < 0)
                        overflow = true;
                }
            }
            // 如果2次比较相同，说明期间没有修改，size是准确的。
            if (sum == last)
                break;
            last = sum;
        }
    } finally {
        // 如果是加锁的话，最后记得解锁
        if (retries > RETRIES_BEFORE_LOCK) {
            for (int j = 0; j < segments.length; ++j)
                segmentAt(segments, j).unlock();
        }
    }
    return overflow ? Integer.MAX_VALUE : size;
}
```

因为并发操作获取size的过程中可能有修改的操作，所以获取的可能不准，想要精确的值就需要将所有的Segment的加锁，然后分别求出每个Segment中HashEntry的数量。但是全部加锁会严重影响ConcurrentHashMap的性能。所有作者提出了另外一种解决方案：在不加锁的情况下先求出所有modCount的总和2次，比对2次结果，如果相同，则认为在获取期间ConcurrentHashMap没有发生变化。否则，就只能走加锁的模式。



# JDK1.8实现

JDK1.8 的类就很复杂了，一大堆的内部类就看晕了(✖人✖)。

## 结构图

### 内部结构

![](/Users/zhaohaoren/workspace/blog/hexo/source/img/hashmap/ds.png)

其底层结构和HashMap是一样的，采用**数组+链表/红黑树**来存储数据。只是不再使用分段锁，而是采用了**CAS + synchronized**来保证并发安全。

## 源码

### 内部类

![img](https://images2018.cnblogs.com/blog/1394959/201806/1394959-20180606194916727-1631558402.png)

![img](https://images2018.cnblogs.com/blog/1394959/201806/1394959-20180606194941108-1310305878.png)

### 重要结构类


#### Node

ConcurrentHashMap中最基本的类，最终包装存入的key和value的对象。

```java
static class Node<K,V> implements Map.Entry<K,V> {
    final int hash;
    final K key;
    volatile V val;
    volatile Node<K,V> next;
}

```

可以看出这是一个链表结构，还需要注意的是hash这个在ConcurrentHashMap中有更多的作用：

```java
//hash值为-1的时候代表节点是fwd
static final int MOVED     = -1; // hash for forwarding nodes 
//hash值为-2的时候，代表这是一个树的根
static final int TREEBIN   = -2; // hash for roots of trees
//hash值为-3的，代表是保留节点，用于computeIfAbsent等
static final int RESERVED  = -3; // hash for transient reservations

```

#### TreeNode

红黑树的节点，当链表转为树的时候Node节点会转为树节点

```java
static final class TreeNode<K,V> extends Node<K,V> {
    TreeNode<K,V> parent;  // red-black tree links
    TreeNode<K,V> left;
    TreeNode<K,V> right;
    TreeNode<K,V> prev;    // needed to unlink next upon deletion
    boolean red;
}

```

#### TreeBin

ConcurrentHashMap内部的Hash表不是直接存储TreeNode节点的，而是存储的TreeBin，通过TreeBin来维护这棵红黑树

```java
static final class TreeBin<K,V> extends Node<K,V> {
    TreeNode<K,V> root;
    volatile TreeNode<K,V> first;
}

```

#### ForwardingNode

扩容时候用到的类，在扩容时候，操作的Node会变为该Node状态，这时候有put操作，遇到该节点就会去先协助扩容。

ForwardingNode对象来源有两个：

1. 原来的位置为null，但是此时复制操作已经到当前位置的后面了，会将这个原来的桶的这个位置置为ForwardingNode对象；
2. 2.原来位置不为null，但是已经操作过这个位置了。

```java
static final class ForwardingNode<K,V> extends Node<K,V> {
    final Node<K,V>[] nextTable;
    ForwardingNode(Node<K,V>[] tab) {
        super(MOVED, null, null, null);
        this.nextTable = tab;
    }
}

```

### 重要属性

#### table

hash表

```java
transient volatile Node<K,V>[] table;

```

#### nextTable

当扩容的时候，新的hash表，其他时候该表为null

```java
private transient volatile Node<K,V>[] nextTable;

```

#### baseCount

基本计数器，主要在没有多线程并发竞争更新的时候使用，CAS原子更新。ConcurrentHashMap不希望并发的时候再更新计数器的时候也阻塞住，所以计数方式采用了baseCount+counterCells。

```java
private transient volatile long baseCount;

```

#### counterCells

并发情况下，计数通过更新这个数组来增加计数，这是一个数组，并且长度是2的次幂

```java
private transient volatile CounterCell[] counterCells;

```

#### sizeCtl

最核心的一个属性，控制这表的扩容初始化等。后面会详细介绍各个状态及作用。

```java
private transient volatile int sizeCtl;

```



### 构造函数

1.8中无论是HashMap还是ConcurrentHashMap都是采用了懒加载的方式，即在构造函数调用的时候，并不会初始化内部table，而是在第一次put的时候才会申请内存。

```java
// 使用默认参数构造
// 初始容量 (16)、加载因子 (0.75)  concurrencyLevel (16) 
public ConcurrentHashMap() {
}
public ConcurrentHashMap(int initialCapacity,float loadFactor, int concurrencyLevel) {
        if (!(loadFactor > 0.0f) || initialCapacity < 0 || concurrencyLevel <= 0)
            throw new IllegalArgumentException();
        //initialCapacity和concurrencyLevel取最大的使用
        if (initialCapacity < concurrencyLevel)   // Use at least as many bins
            initialCapacity = concurrencyLevel;   // as estimated threads
        long size = (long)(1.0 + (long)initialCapacity / loadFactor);
        int cap = (size >= (long)MAXIMUM_CAPACITY) ?
            MAXIMUM_CAPACITY : tableSizeFor((int)size); //确保表是2的次幂
        this.sizeCtl = cap;
}

```

这里只选择了2个构造函数，其他的构造函数和这个类似，我们可以看到构造函数的主要作用就是计算sizeCtl这个值。

#### sizeCtl（表初始化和扩容的控制位）

sizeCtl是很重要的一个属性，它用于table的初始化和扩容，有几种情况（from注释）：

1. 0，表示未指定初始容量
2. -1，表示table正在初始化
3. -N，表示有N-1个线程正在进行扩容操作
4. 其他情况
   1. 如果table未初始化，表示table需要初始化的大小
   2. 如果table初始化完成，表示扩容阈值（0.75*容量），当实际容量>=sizeCtl，则扩容

#### 注意点

- `loadFactor` 如果指定这个值只会在构造的时候起作用，在后面的操作中将不再起作用（构造里面并没有赋值给内部属性）。
- 计算公式是先计算`(1.0 + (long)initialCapacity / loadFactor);`然后取这个值的最近2次幂数来作为初始容量的。具体缘由，个人认为因为这里负载因子是一次性的，作者认为用户指定的`initialCapacity`是用户估算出要存储的数量。所以依据这个值，为了尽量避免扩容，所以就反向求出一个size来保证这个size的在该负载因子下，存储`initialCapacity`个元素都不会扩容。
- **这里的`concurrencyLevel`和jdk1.7的含义已经不一样了**，他表示估计的参与并发更新的线程数量。其实和并发控制没啥太大关系，只有在构造函数中使用了它和initialCapacity比较下，如果初始容量小于估计并发数情况下，我们则选用并发数作为初始容量。

### put函数

put只是简单调用了下putVal方法

```java
public V put(K key, V value) {
    return putVal(key, value, false);
}

```

我们主要来看putVal

```java
final V putVal(K key, V value, boolean onlyIfAbsent) {
    // key和value都不能为空
    if (key == null || value == null) throw new NullPointerException();
    // 使用位干扰计算hash值
    int hash = spread(key.hashCode());
    //用来计算在这个table[index]（也可以称为一个bin）已经有多少个元素，用来控制扩容或者转移为树
    int binCount = 0;
    for (Node<K,V>[] tab = table;;) {
        Node<K,V> f; int n, i, fh;
        if (tab == null || (n = tab.length) == 0) //如果table为null就初始化table
            tab = initTable();
        else if ((f = tabAt(tab, i = (n - 1) & hash)) == null) { //定位该key存放table的位置，判断该位置是否有值
            // 如果没有值就CAS插入该key的Node，就结束了（该node就是该table位置上头结点，这里没有使用锁方式）
            if (casTabAt(tab, i, null,
                         new Node<K,V>(hash, key, value, null)))
                break;                   // no lock when adding to empty bin
        }
        //f是table[index]的头结点，这里检测该节点是否是MOVE的状态，MOVE表示正在进行数组扩张的数据复制阶段
        else if ((fh = f.hash) == MOVED)
            //当前线程也会去帮助参与扩容的复制
            tab = helpTransfer(tab, f);
        else {
            /*
            上面排除了table为空，table[index]为空，数组正在扩容的情况，这些情况处理的时候都不需要同步来控制并发的。
            但是如果该位置上有值（可能是链表可能是红黑树），那么该put操作就需要走同步。
             */
            V oldVal = null;
            // *core:
            synchronized (f) {
                if (tabAt(tab, i) == f) {
                    //fh为f.hash值。
                    if (fh >= 0) { //fh>=0 说明是链表
                        binCount = 1;
                        for (Node<K,V> e = f;; ++binCount) { //遍历链表
                            K ek;
                            if (e.hash == hash &&
                                ((ek = e.key) == key ||
                                 (ek != null && key.equals(ek)))) { //如果已存在该key就替换
                                oldVal = e.val;
                                if (!onlyIfAbsent) ////当是putIfAbsent的时候，只有在这个key没有设置值得时候才设置
                                    e.val = value;
                                break;
                            }
                            Node<K,V> pred = e;
                            if ((e = e.next) == null) { //遍历到了尾结点就将该Node添加到最后
                                pred.next = new Node<K,V>(hash, key,
                                                          value, null);
                                break;
                            }
                        }
                    }
                    //table上该位置是已经转为红黑树了
                    else if (f instanceof TreeBin) {
                        Node<K,V> p;
                        binCount = 2;
                        //走树的put逻辑
                        if ((p = ((TreeBin<K,V>)f).putTreeVal(hash, key,
                                                       value)) != null) {
                            oldVal = p.val;
                            if (!onlyIfAbsent)
                                p.val = value;
                        }
                    }
                }
            }
            //处理完成后看看是否符合树化条件
            if (binCount != 0) {
                if (binCount >= TREEIFY_THRESHOLD) //个数大于8就树化
                    treeifyBin(tab, i);
                if (oldVal != null)
                    return oldVal;
                break;
            }
        }
    }
    //计数
    addCount(1L, binCount);
    return null;
}

```

#### 执行流程

1. 定位该key在`table`中位置，判断hash表是否为null及定位的位置上是否有数据。
2. 当上面条件都不是的时候，则进入`synchronized`同步块，对树或者链表遍历并插入或者更新该key。
3. 然后判断下当前bin位置上节点数量是否需要转为红黑树。

#### 表初始化

1.8的内部的Hash表是在put的时候才进行初始化的，就是调用上面代码的`initTable`方法。

```java
private final Node<K,V>[] initTable() {
    Node<K,V>[] tab; int sc;
    while ((tab = table) == null || tab.length == 0) { //table还没被初始化，进入while
        if ((sc = sizeCtl) < 0) //sizeCtl小于0的时候表示在别的线程在初始化表或扩展表
        	Thread.yield(); // lost initialization race; just spin
        else if (U.compareAndSwapInt(this, SIZECTL, sc, -1)) { //开始准备初始化表，先用CAS将sizeCtrl设置为-1
            try {
                if ((tab = table) == null || tab.length == 0) {
                    //如果指定了大小的时候就创建指定大小的Node数组，否则创建默认大小(16)的Node数组
                    int n = (sc > 0) ? sc : DEFAULT_CAPACITY;
                    @SuppressWarnings("unchecked")
                    Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n];
                    table = tab = nt;
                    sc = n - (n >>> 2);
                }
            } finally {
                sizeCtl = sc; //初始化完成后，sizeCtl长度为数组长度的3/4【n-(n >>> 2)】
            }
            break;
        }
    }
    return tab;
}

```

代码里面看出，除了初始化表之外，就是不断的调整sizeCtrl的值，来标识当前的状态。如果当前线程发现有线程已经对其初始化了，就让出CPU空闲。最后初始化完成后，sizeCtrl的值设置为table数组大小的0.75倍（`n-(n >>> 2)`）。

#### 多线程扩容

当ConcurrentHashMap并发地添加元素时，如果发现map正在扩容（当前hash 值对应的槽位有值了，且如果这个值是 -1:MOVED），其他线程还会帮助其扩容，以加快速度，这就是1.8添加的多线程扩容。这部分就是上面调用的helpTransfer方法，主要是在扩容时将table表中的结点转移到nextTable中。

```java
final Node<K,V>[] helpTransfer(Node<K,V>[] tab, Node<K,V> f) {
    Node<K,V>[] nextTab; int sc;
    // 表不为空 && 结点类型使ForwardingNode转移类型 && 结点的nextTable不为空
    if (tab != null && (f instanceof ForwardingNode) &&
        (nextTab = ((ForwardingNode<K,V>)f).nextTable) != null) {

        int rs = resizeStamp(tab.length);
        // 如果nextTab没有被并发修改且tab也没有被并发修改且sizeCtl<0（说明还在扩容）
        while (nextTab == nextTable && table == tab &&
               (sc = sizeCtl) < 0) {
            // 扩容结束的条件
            // 如果 sizeCtl 无符号右移  16 不等于 rs （ sc前 16 位如果不等于标识符，则标识符变化了）
            // 或者 sizeCtl == rs + 1  （扩容结束了，不再有线程进行扩容）（默认第一个线程设置 sc ==rs 左移 16 位 + 2，当第一个线程结束扩容了，就会将 sc 减一。这个时候，sc 就等于 rs + 1）
            // 或者 sizeCtl == rs + 65535  （如果达到最大帮助线程的数量，即 65535）
            // 或者转移下标正在调整 （扩容结束）
            if ((sc >>> RESIZE_STAMP_SHIFT) != rs || sc == rs + 1 ||
                sc == rs + MAX_RESIZERS || transferIndex <= 0)
                break;
            // 每有一个线程来帮助迁移，sizeCtl就+1
            if (U.compareAndSwapInt(this, SIZECTL, sc, sc + 1)) {
                //转移
                transfer(tab, nextTab);
                break;
            }
        }
        return nextTab;
    }
    return table;
}

```

#### 更新count

在put完成的最后，表示添加了一个Node操作完成了，这时候需要调用addCount来更新baseCount。该方法主要作用：

1. 就是CAS增加baseCount的值，增加值为x。
   1. 如果更新失败，或者counterCells为null会调用fullAddCount方法进行循环更新。
2. 判断当前bin桶是否需要扩容，判断依据check值。

详细分析注释如下：

```java
private final void addCount(long x /*需要增加的数*/, int check /*一个bin下node的个数*/) {
        CounterCell[] as; long b, s;
        // 如果计数盒子counterCell不是空 ||  CAS更新baseCount的值失败
        if ((as = counterCells) != null ||
            !U.compareAndSwapLong(this, BASECOUNT, b = baseCount, s = b + x)) {
            CounterCell a; long v; int m;
            boolean uncontended = true;
            // 如果counterCells是空，表示尚未出现并发
            // || 如果counterCells数组上随机取余一个位置为空
            // || 修改这个cell的变量失败，代表出现并发
            // 就调用fullAddCount 来将将数字加到counterCells上去。
            if (as == null || (m = as.length - 1) < 0 ||
                (a = as[ThreadLocalRandom.getProbe() & m]) == null ||
                !(uncontended =
                  U.compareAndSwapLong(a, CELLVALUE, v = a.value, v + x))) {
                //fullAddCount方法的作用就是去更新cell的value值。来保证元素个数正确的更新
                fullAddCount(x, uncontended);
                return;
            }
            // 如果check还小于1的话，就这了退出
            if (check <= 1)
                return;
            s = sumCount();
        }
        //如果check值大于等于0，则需要检验是否需要进行扩容操作
        if (check >= 0) {
            Node<K,V>[] tab, nt; int n, sc;
            while (s >= (long)(sc = sizeCtl) && (tab = table) != null &&
                   (n = tab.length) < MAXIMUM_CAPACITY) {
                int rs = resizeStamp(n);
                if (sc < 0) {
                    if ((sc >>> RESIZE_STAMP_SHIFT) != rs || sc == rs + 1 ||
                        sc == rs + MAX_RESIZERS || (nt = nextTable) == null ||
                        transferIndex <= 0)
                        break;
                    //是否已经有其他线程在执行扩容操作
                    if (U.compareAndSwapInt(this, SIZECTL, sc, sc + 1))
                        transfer(tab, nt);
                }
                //当前线程是唯一的或是第一个发起扩容的线程  此时nextTable=null
                else if (U.compareAndSwapInt(this, SIZECTL, sc,
                                             (rs << RESIZE_STAMP_SHIFT) + 2))
                    transfer(tab, null);
                s = sumCount();
            }
        }
    }

```

put这个流程到这里就先结束了，这个流程中还有一些比较重要点先不扯到这个流程里面了，后面会单独分析。

### 扩容操作

我们在put的最后一步addCount的时候，会去check一下是否需要进行扩容操作。其调用的就是transfer方法。该扩容有2种情况：

1. sizeCtl<0，即有别的线程正在进行扩容，此时当前这个线程需要参与帮助扩容的任务中来；
2. 该线程是唯一的扩容线程。

扩容代码应该算是ConcurrentHashMap里面最复杂的部分了，扩容主要是2个步骤，首先创建扩容后的2倍数组，然后将老table的数据移动到新的table上去。

`transfer`方法很复杂，这里先总结下大概步骤：

- 通过当期机器CPU核心数及Hash表长度得到每个线程（CPU）要帮助处理多少个桶，确定每个线程可以处理的数量
- 如果发现扩容后的数据没有初始化就初始化
- 开始进入循环，多线程扩容的逻辑主要都在这里面
  - 先计算i和bound，即分配一个线程处理Hash表的区间范围
  - 里面还有许多的判断逻辑用来处理各种情况，比如该桶其他线程已经处理过了等。
- 链表扩容节点转移
  - 为了加速扩容，将链表节点分为2个部分，链表尾部连续相同的节点我们可以直接拽过来，然后再从头开始一直到刚在拽的那个点，遍历链表，头插的方式分为2个链表。
  - 然后将2个链表存储到新table的新位置上去。
- 树扩容节点转移

详细代码注释如下：

```java
private final void transfer(Node<K,V>[] tab, Node<K,V>[] nextTab) {
    int n = tab.length, stride;
    // 这里主要意思是单个线程允许处理的最少table桶数量不能小于16，如果小于16就设置为16
    if ((stride = (NCPU > 1) ? (n >>> 3) / NCPU : n) < MIN_TRANSFER_STRIDE/*=16*/)
        stride = MIN_TRANSFER_STRIDE; // subdivide range
    // 如果是首次扩容，需要初始化扩容后的数组
    if (nextTab == null) {            // initiating
        try {
            // 扩容2倍
            @SuppressWarnings("unchecked")
            Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n << 1];
            nextTab = nt;
        } catch (Throwable ex) {      // try to cope with OOME
            sizeCtl = Integer.MAX_VALUE;
            return;
        }
        nextTable = nextTab;
        // 指向最后一个桶，方便从后向前遍历
        transferIndex = n;
    }
    int nextn = nextTab.length;
    //定义ForwardingNode来标记迁移完成的桶
    ForwardingNode<K,V> fwd = new ForwardingNode<K,V>(nextTab);
    boolean advance = true; //是否继续向前查找下一个桶
    boolean finishing = false; //控制扩容何时结束，以及完成前重新扫描下数组，查看有没有完成的
    // 该for循环用于处理一个 stride 长度的任务
    // i后面会被赋值为该 stride 内最大的下标，而 bound 后面会被赋值为该 stride 内最小的下标
    for (int i = 0, bound = 0;;) {
        Node<K,V> f; int fh;
       // 如果当前线程可以向后推进，主要是控制i递减。且每个线程都会进入这里取得自己需处理的桶的区间
       // 从table最后一个位置开始，主要就是为了计算当前线程需要处理的桶区间
        while (advance) {
            int nextIndex, nextBound;
            if (--i >= bound || finishing)
                advance = false;
            else if ((nextIndex = transferIndex) <= 0) {
                i = -1;
                advance = false;
            }
            else if (U.compareAndSwapInt
                     (this, TRANSFERINDEX, nextIndex,
                      nextBound = (nextIndex > stride ?
                                   nextIndex - stride : 0))) {
                bound = nextBound;
                i = nextIndex - 1;
                advance = false;
            }
        }
        if (i < 0 || i >= n || i + n >= nextn) {
            //当前线程所有任务完成
            int sc;
            //扩容结束后做后续工作，将 nextTable 设置为 null，表示扩容已结束，将 table 指向新数组，sizeCtl 设置为扩容阈值
            if (finishing) {
                nextTable = null;
                table = nextTab;
                sizeCtl = (n << 1) - (n >>> 1);
                return;
            }
            //每当一条线程扩容结束就会更新一次 sizeCtl 的值，进行减 1 操作
            if (U.compareAndSwapInt(this, SIZECTL, sc = sizeCtl, sc - 1)) {
                if ((sc - 2) != resizeStamp(n) << RESIZE_STAMP_SHIFT)
                    return;
                finishing = advance = true;
                //除了修改结束标识之外，还得设置 i = n; 以便重新检查一遍数组，防止有遗漏未成功迁移的桶
                i = n; // recheck before commit
            }
        }
        else if ((f = tabAt(tab, i)) == null)
            // 如果当前槽没有Node，CAS插入fwd表示该槽已经处理过了
            advance = casTabAt(tab, i, null, fwd);
        else if ((fh = f.hash) == MOVED)
            // 遇到了别的线程已经处理过的线程，直接跳过
            advance = true; // already processed
        else {
            // 移动节点的操作
            synchronized (f) {
                if (tabAt(tab, i) == f) {
                    //ln 新数组原来位置上的节点list
                    //hn 新数组原来位置+n的的节点list
                    Node<K,V> ln, hn;
                    // 对链表进行迁移
                    if (fh >= 0) {
                        // 这里我迷了一阵子，这里不是计算原来的table中的位置（应该是fh&(n-1)）
                        // 这里和数组长度来&，计算出的结果就2个：0和非0，因为数组的长度是2的次幂，即判断依据就是hash值在那个位上的bit是0还是1。
                        // 保留最后一个连续相同链的首节点的hash&n值
                        int runBit = fh & n;
                        // 保留最后一个连续相同链的首节点
                        Node<K,V> lastRun = f;
                        /* 第一次遍历整个链表
                         * 这里是很有意思的一个地方，解释了runBit和lastRun的作用：
                         * 这里把一个链表分为了2种：1个是需要移动的，一个是还会在原来位置的
                         * 这个循环就是找出该链表最后一个位置，在该位置（lastRun）往后所有的节点，都和该位置节点hash & n值一样
                         * */
                        for (Node<K,V> p = f.next; p != null; p = p.next) {
                            int b = p.hash & n;
                            if (b != runBit) {
                                // 每次不一样就重新设置一下
                                runBit = b;
                                lastRun = p;
                            }
                        }
                        // 如果runBit为0，将lastRun 设置为ln的首节点，表示这往后的链表不需要移动
                        if (runBit == 0) {
                            ln = lastRun;
                            hn = null;
                        }
                        // 不为0，说明要移动到+n位置，先放入hn
                        else {
                            hn = lastRun;
                            ln = null;
                        }
                        // 第二次遍历链表，只遍历到lastRun位置
                        for (Node<K,V> p = f; p != lastRun; p = p.next) {
                            int ph = p.hash; K pk = p.key; V pv = p.val;
                            if ((ph & n) == 0)
                                // 采用的是头插法，也就是说遍历这个链表的时候，这些头插的元素都是反转的。
                                ln = new Node<K,V>(ph, pk, pv, ln);
                            else
                                hn = new Node<K,V>(ph, pk, pv, hn);
                        }
                        //ln设置新数组原来位置
                        setTabAt(nextTab, i, ln);
                        //hn设置新数组+n位置
                        setTabAt(nextTab, i + n, hn);
                        //原来表该位置都设置为fwd
                        setTabAt(tab, i, fwd);
                        advance = true;
                    }
                    else if (f instanceof TreeBin) {
                        // 对红黑树进行迁移，这里就不多交代了
                        // ........
                    }
                }
            }
        }
    }
}

```

### size方法

ConcurrentHashMap中针对并发通过baseCount和CounterCell来计算获取size的大小，在`addCount()` CAS 更新 baseCount的时候，可能因为并发问题更新失败，会调用 fullAddCount 将这些失败的结点包装成一个 CounterCell 对象，保存在 CounterCell 数组中。那么整张表实际的 size 其实是 baseCount 加上 CounterCell 数组中元素的个数。

```java
public int size() {
    long n = sumCount();
    return ((n < 0L) ? 0 :
            (n > (long)Integer.MAX_VALUE) ? Integer.MAX_VALUE :
            (int)n);
}
final long sumCount() {
    CounterCell[] as = counterCells; CounterCell a;
    long sum = baseCount;
    if (as != null) {
        for (int i = 0; i < as.length; ++i) {
            if ((a = as[i]) != null)
                sum += a.value;
        }
    }
    return sum;
}

```

### remove函数

remove比较简单，简单说下流程：

1. 如果表还未初始化或者通过key无法hash定位表的位置则返回null。
2. 如果该位置桶结点类型是ForwardingNode节点，则执行helpTransfer 协助扩容。
3. 如果一切ok，就给桶加锁，并删除一个节点。
4. 最后调用addCount 方法去CAS更新baseCount 的值。

### get函数

很简单，直接上代码

```java
public V get(Object key) {
    Node<K,V>[] tab; Node<K,V> e, p; int n, eh; K ek;
    // 确定key的数组位置
    int h = spread(key.hashCode());
    if ((tab = table) != null && (n = tab.length) > 0 &&
        (e = tabAt(tab, (n - 1) & h)) != null) {
        if ((eh = e.hash) == h) {
            if ((ek = e.key) == key || (ek != null && key.equals(ek)))
                return e.val;
        }
        else if (eh < 0)
            return (p = e.find(h, key)) != null ? p.val : null;
        // 遍历该位置的所有节点
        while ((e = e.next) != null) {
            if (e.hash == h &&
                ((ek = e.key) == key || (ek != null && key.equals(ek))))
                return e.val;
        }
    }
    //找不到就返回null
    return null;
}

```

# 总结

## 1.7和1.8的区别

### 结构上

两者都大量使用Unsafe的方法进行元素的操作。并发控制上：

- 1.7：Segment + HashEntry，通过Segment的分段锁来获取Segment粒度的并发。
- 1.8：Bin+CAS+Synchronize，通过CAS+Synchronize将粒度缩减到Bin（Hash槽）级别。
- 为什么要使用CAS+Synchronized取代Segment+ReentrantLock？
  - 减少内存资源消耗：表如何很大的话，就会有很多ReentrantLock对象
  - synchronized底层做了优化，性能不差
  - 锁的粒度可以控制的更细

初始状态：

- 1.7：有初始化一个Segment和hash表
- 1.8：采用懒加载，第一次put的时候才会初始化hash表。

存储结构：

- 1.7：数组+链表
- 1.8：数组+链表、红黑树

### size上

- 1.7：不加锁计算2次，对比是否相同，如果不同则加锁来统计总数。
- 1.8：使用baseCounter+CellCounter来计数。

# 参考

https://blog.csdn.net/ZOKEKAI/article/details/90051567

https://tech.meituan.com/2019/02/14/talk-about-java-magic-class-unsafe.html

https://www.cnblogs.com/banjinbaijiu/p/9147434.html