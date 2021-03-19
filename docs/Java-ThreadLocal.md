# ThreadLocal 使用及原理

这算是日常处理并发问题中，比较常见和易用一个技术点了。无论框架中还是平时业务开发中，有时候就特别适合使用ThreadLocal来解决一些问题。

ThreadLocal（又被称为线程本地变量）。字面意思，每个线程拥有本地变量的副本，各个线程之间的变量互不干扰。相对很多线程同步代码执行块的方式，ThreadLocal采用的则是空间换时间来保证线程安全：**如果我们保证每个线程访问的都是自己的变量（线程资源隔离），那么就不会存在共享的并发问题了**。我们通过ThreadLocal相当于可以为每个线程创建自己的缓存，之后在本线程中需要的变量，都从该缓存中获取即可。

## 简单使用

源码中就注释了一段demo：

```java
public class ThreadId {
    // Atomic integer containing the next thread ID to be assigned
    private static final AtomicInteger nextId = new AtomicInteger(0);
    // 一般在一个类中都定义为private static遍历
    private static final ThreadLocal<Integer> threadId =
        new ThreadLocal<Integer>() {
            @Override protected Integer initialValue() {
                return nextId.getAndIncrement();
        }
    };
    // Returns the current thread's unique ID, assigning it if necessary
    public static int get() {
        return threadId.get();
    }
}
```

这个Demo就是对每个线程分配了一个自增id。

- 当我们需要需要在这个线程后面使用某个变量和对象的时候，我们就通过定义的这个ThreadLocal的`set`方法，将值保存在当前线程本地；
- 当需要使用的时候调用`get`方法获取；
- 如果确定不再使用了，再通过`remove`方法移除。【这是容易被忽略但是又很重要的步骤】

## 原理

### 为什么使用？

**首先思考一下，我们为什么要使用ThreadLocal？**

设定一个场景，我们有一个巨长的业务逻辑链，方法A-B-C-D-E-F-....。 这时候A处创建了一个对象XX，然后这个对象需要给B，然后B要给C，C要给D。我们就要在这些方法上每一个都加上一个参数XX。 这样你一定也觉得很烦！ 所以在单线程的环境下，我们一定是定义了一个全局的变量XX，A创建完赋值后，BCD这些都直接从XX上获取就好了。

但是多线程下，就存在并发安全问题了，2个或者多个线程互相赋值和获取，到时候结果一定会有问题。

所以问题来了：

1. 我想放在全局上，不要每个方法上都带着参数。
2. 我又想这个在多线程环境下是安全的，这该咋整？

如果没有ThreadLocal的话，你大可能会将XX定义成一个Map这样的，然后这个Map的key存放线程的ID，然后往这个Map里面存数据，需要的时候再取是不是（其实ThreadLocal原理基本也是这个思想）？Java帮你get到了这个需求，为你创建了ThreadLocal的这个类（看下面原理就明白了这本质上就是一个工具类），这部分工作不需要你来完成，JDK帮你做。



### 适用场景

一般业务开发中，个人认为存在2种很适用场景：

1. 为了独享对象安全更新：每个线程创建自己独立的副本，然后后续业务操作中修改副本的属性值等，不会影响其他的线程。
2. 为了独享对象全局使用：在业务逻辑的某个点处，创建了一个对象，这个对象希望在后面很多方法中使用，但是又不希望通过方法参数名一层层的往下传递。

注意：ThreadLocal并不是满足所有的并发场景，不要滥用它来解决所有并发问题。

分别举2个场景的具体例子：

**场景1：**

- 在项目中使用多数据源的时候，我们通过反射注解来获取当前数据源应该切到哪个数据源上。这时候可以定义一个ThreadLocal\<Queue\<String>>来存放当前线程下数据源切换的顺序：比如DataSourceA -> DataSourceB -> DataSourceC 当C使用完了，就弹出C，后面的逻辑继续使用B数据源。
- 如果不使用ThreadLocal的话，那么就全乱套了，别的线程切了会影响到当前线程的数据源判断。

**场景2：**

- 这个场景是使用最多的，比如Java中SimpleDateFormat是线程不安全的，我们想要使用，就可以为每个线程创建一个自己的SimpleDateFormat对象。再比如Spring的事务管理，会在事务逻辑前，先将一个数据库Connection放入到ThreadLocal中，后续的所有操作都使用该Connection。
- 这类场景其实，更多的是为了用一个线程不安全的工具类，并不会修改它。

可以看到，ThreadLocal的重点不是为了对象的**共享安全**。对于这类的场景ThreadLocal是帮不上什么忙的。我们有些并发场景是通过共享对象来做线程之间的交互的（比如统计网页接口的访问量，需要只对一个共享的变量进行加1），这种场景不是ThreadLocal服务的场景。ThreadLocal服务的一定是**独享变量**。

> 个人觉得，使用ThreadLocal给我们带来的遍历性在于：**避免某个对象需要在多线程环境下调用的方法链上进行巨长链条的传参链 **。



### 源码分析

我们使用ThreadLocal的时候一般就是那几个方法，而这屏蔽了底层具体如何保证线程安全的实现细节。其实ThreadLocal的源码比较简单，主体结构如下：

```java
public class ThreadLocal<T> {
    private final int threadLocalHashCode = nextHashCode();
    private static AtomicInteger nextHashCode =
        new AtomicInteger();
    private static final int HASH_INCREMENT = 0x61c88647;
  	// 核心方法
    public ThreadLocal() {}
    public T get() {}
    public void set(T value) {}
    public void remove() {}
  	// 核心内部类
    static class ThreadLocalMap {
        static class Entry extends WeakReference<ThreadLocal<?>> {
            Object value;
            Entry(ThreadLocal<?> k, Object v) {
                super(k);
                value = v;
            }
        }
    }
}
```

我们可以看到ThreadLocal中只是提供了一些方法，和一个内部类。而它本身是不存放任何对象的。所以关键点就是看我们常用的get和set方法：

#### set方法

```java
public void set(T value) {
 //获取当前线程，然后获取到当前线程里面的ThreadLocalMap引用，
 //判断当前线程里面是创建该Map对象，有则直接set，没有就初始化一个Map,再将值放入。
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);// 以ThreadLocal对象为key 传入value为value
    else
        createMap(t, value);
}
```

只是通过`Thread.currentThread()`拿到当前的线程对象，然后通过getMap获取了一个`ThreadLocalMap`对象，而value是放在这个map中的。我们看看getMap做了啥？

```java
ThreadLocalMap getMap(Thread t) {
    // 只是返回了Thread的一个属性值
    return t.threadLocals;
}
```

getMap的作用其实就是获取Thread线程中的属性值：`ThreadLocal.ThreadLocalMap threadLocals = null`。也就是说，ThreadLocalMap的类定义在ThreadLocal中，但是具体的map是在Thread对象中的。这个map是Thread对象持有的，这也就是为什么叫线程本地变量了，这个map相当于是这个线程私有的一块缓存区。

#### get方法

```java
public T get() {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    //存在Map就找到当前线程Map中该ThreadLocal对象的value
    if (map != null) {
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
            @SuppressWarnings("unchecked")
            T result = (T)e.value;
            return result;
        }
    }
    //没有就初始化它
    return setInitialValue();
}
```

#### remove方法

```java
public void remove() {
    ThreadLocalMap m = getMap(Thread.currentThread());
    if (m != null)
        // 就是map删除这个ThreadLocal对象为key的值
        m.remove(this);
}
```

get和remove方法就很简单了，就是正常的map操作。所以ThreadLocal的重点在于这个`ThreadLocalMap`。

#### ThreadLocalMap

```java
static class ThreadLocalMap {
    static class Entry extends WeakReference<ThreadLocal<?>> {
        Object value;
        Entry(ThreadLocal<?> k, Object v) {
            super(k);
            value = v;
        }
    }
    private static final int INITIAL_CAPACITY = 16;
    private Entry[] table;
    private int size = 0;
    private int threshold; // Default to 0
    
    ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {}
    private ThreadLocalMap(ThreadLocalMap parentMap) {}
    
    private void set(ThreadLocal<?> key, Object value) {}
    private void remove(ThreadLocal<?> key) {}
    private static int nextIndex(int i, int len) {}
    private static int prevIndex(int i, int len) {}

	private void setThreshold(int len) {}
    private void rehash() {}
    private void resize() {}
}
```

这个Map的具体方法实现细节，没有什么好说的，可以理解就是做了一个小型的HashMap。（后面部分详细操作在内存泄漏里面讲）

#### 图解

 ![image-20210319235640529](D:\workspace\blog-docs\docs\Java-ThreadLocal\image-20210319235640529.png)


上图描述Thread和ThreadLocal之间的关系，从此就能得出很多基础结论了：

- 线程内部持有一个Map存放着自己的局部变量，这些变量的key是ThreadLocal对象（可以理解为什么叫做线程局部变量了吧）；
- 有一个变量想放入线程的局部变量的你就需要创建一个ThreadLocal对象；
- ThreadLocal本身没有什么存储结构，只是提供了方法，所以变量不是存在ThreadLocal中的，ThreadLocal负责搬运。

----



## 内存泄漏

一般来说有GC的语言不会存在内存泄漏的问题的，所有的对象释放的操作都应该是GC去做，不用我们去手动释放。但是ThreadLocal因为底层对我们的上层的一些细节屏蔽，会导致GC无法正确的回收已经不再使用的对象。

### 为什么会内存泄漏？

我们上面得知Thread中存放了一个ThreadLocalMap，key是ThreadLocal对象，value是我们需要后面使用的对象（这里还是举例XX）。

在一般程序中创建一个XX使用完了，GC从Root出发去发现可达，会发现XX没有被任何引用，此时就会回收XX，这是没有使用ThreadLocal下的GC过程。但是











### 为什么用虚引用而非强引用

其实就一句话：强引用一样内存泄露！







一些误区

- ThreadLocal的内存泄露是因为虚引用导致的。
  - 泄露的本质原因是：我们程序中虽然不再引用了，但是在你不知道的地方（线程对象内部map），存在着引用关系。而ThreadLocal的key是虚引用，所以key可以被回收，但是value是无法被回收的。
  - 内存泄露是ThreadLocal自身原因导致的，和虚引用还是强引用没有关系。虚引用反而是减少了内存泄露的泄露量。
  - 如果本着GC应该帮我们做到这种垃圾回收的心态的话，那么内存泄露和虚引用也只能扯上一点点关系。（我不用了你GC就应该帮我回收了啊，）想象一下，如果想要实现这个功能，那么要么value也是用虚引用（这肯定不行的）。要么就是线程要知道你什么时候这个对象是真的不用了，然后帮你进行remove操作（这好像也没得行的样子）。





对于Java程序员来说，很少关注对象的回收，所有对象使用完了都放心的全部都交给垃圾回收器来处理。我个人觉得这才是导致内存泄露的主要原因 🐶。然而ThreadLocal这一神物，却刚好钻了空子。我们程序中可能已经不再使用某个ThreadLocal对象了，但是线程中会一直持有该ThreadLocal的相关引用（虽然key会被GC成功回收）。



> 综上：使用ThreadLocal一定要注意一点，当我们使用完了线程本地对象后，一定要调用remove方法！！！来避免内存泄漏。



https://www.jianshu.com/p/d225dde8c23c

https://blog.csdn.net/Y0Q2T57s/article/details/83247430



疑问： 我们定义ThreadLocal对象的时候 是不是一定官方demo那样定义成static的？ 只要我们不再指向null，ThreadLocal对象就 永远都不会被回收？

弱引用到底和内存泄漏 是否有关？







































