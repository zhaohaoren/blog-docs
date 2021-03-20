# ThreadLocal 使用及原理详解

这算是日常处理并发问题中，比较常见和易用一个技术点了。无论框架中还是平时业务开发中，有时候就特别适合使用ThreadLocal来解决一些问题。

ThreadLocal（又被称为线程本地变量）。字面意思，每个线程拥有本地变量的副本，各个线程之间的变量互不干扰。相对很多线程同步代码执行块的方式，ThreadLocal采用的则是空间换时间来保证线程安全：**如果我们保证每个线程访问的都是自己的变量（线程资源隔离），那么就不会存在共享的并发问题了**。我们通过ThreadLocal相当于可以为每个线程创建自己的缓存，之后在本线程中需要的变量，都从该缓存中获取即可。

## 简单使用

源码中就注释了一段demo：

```java
public class ThreadId {
    // Atomic integer containing the next thread ID to be assigned
    private static final AtomicInteger nextId = new AtomicInteger(0);
    // 一般在一个类中都定义为private static方便引用
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

这个Map的具体方法实现细节，这里就不细说了，可以理解就是做了一个小型的HashMap。（只是他们的get、set、remove操作和下面的内存泄漏有关联）

#### 图解

 ![image-20210319235640529](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-ThreadLocal/image-20210319235640529.png)


上图描述Thread和ThreadLocal之间的关系，从此就能得出很多基础结论了：

- 线程内部持有一个Map存放着自己的局部变量，这些变量的key是ThreadLocal对象（可以理解为什么叫做线程局部变量了吧）；
- 有一个变量想放入线程的局部变量的你就需要创建一个ThreadLocal对象；
- ThreadLocal本身没有什么存储结构，只是提供了方法，所以变量不是存在ThreadLocal中的，ThreadLocal负责搬运。

----



## 内存泄漏

什么是内存泄露？

> 内存泄漏（Memory Leak）是指程序中已动态分配的堆内存由于某种原因程序未释放或无法释放，造成系统内存的浪费，导致程序运行速度减慢甚至系统崩溃等严重后果。【百度百科】

简单来说，就是你申请的内存后面程序已经不会再使用了，但是没有被释放，一直在内存中造成占用的浪费。对于C++这类没有GC的语言来说，程序员需要手动调用析构函数去主动释放内存。但是一般来说有GC的语言不会存在内存泄漏的问题的，所有的对象释放的操作都应该是GC去做，不用我们去手动释放。但是ThreadLocal因为底层对我们的上层的一些细节屏蔽，会导致GC无法正确的回收已经不再使用的对象，下面通过一个例子示例ThreadLocal的内存泄露。

### 内存泄露示例

```java
public class ThreadLocalMemoryLeakDemo {

    static class LocalVariable {
        //构建一个比较大的对象，方便监测内存
        private Long[] value = new Long[1024 * 1024];
    }

    final static ThreadPoolExecutor EXECUTOR = ThreadUtil.newExecutor(5, 5);

    final static ThreadLocal<LocalVariable> LOCAL_VAL_HOLDER = new ThreadLocal<>();

    public static void main(String[] args) throws InterruptedException {
      	//提交50个任务，每个任务都使用ThreadLocal进行set和get操作
        for (int i = 0; i < 50; i++) {
            EXECUTOR.execute(() -> {
                LocalVariable localVariable = new LocalVariable();
                localVariable.value[0] = Thread.currentThread().getId();
                LOCAL_VAL_HOLDER.set(localVariable);
                System.out.println(Thread.currentThread().getId() + "使用本地变量" + LOCAL_VAL_HOLDER.get().value[0]);
                //验证每次用完remove和每次用完没有remove的区别
                //LOCAL_VAL_HOLDER.remove();
            });
          	// 添加休眠时间，方便监控jvm内存波动
            Thread.sleep(1000);
        }
        System.out.println("END");
    }
}
```

说明：

这里创建一个有5个固定线程的线程池，然后向这个线程池提交50个任务，我们通过每次使用完ThreadLocal后使用`LOCAL_VAL_HOLDER.remove();`清除和不使用这2种方式来执行该程序，对比2者的运行内存来分析内存是否泄漏。

- **没有调用remove方法的堆内存状态**

![image-20210320193301283](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-ThreadLocal/image-20210320192109631.png)

- **调用了remove方法的堆内存状态**

![image-20210320192639838](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-ThreadLocal/image-20210320192639838.png)

**观察可以看到，没有使用`remove`在系统GC以及我手动执行GC后，常驻的内存再25M左右。而使用了`remove`的内存在GC后则很低。这说明有一部分内存没有被GC，这就是内存发生了泄露！**

### 为什么会内存泄漏？

我们上面得知Thread中存放了一个ThreadLocalMap，key是ThreadLocal对象，value是我们需要后面使用的对象（这里还是举例XX）。

在正常的Java代码中，创建一个XX使用完了，GC从Root出发去发现堆内对象的可达性，会发现XX没有被任何引用，此时就会回收XX。但是使用了ThreadLocal就不太一样了。我们通过下图阐述为什么XX使用ThreadLocal后就不能被GC了（这个图为了方便理解做了一些调整，不代表真实情况，但不影响原理的理解）。



![image-20210320201919034](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-ThreadLocal/image-20210320161207039.png)

1. 这里`Thread1 Stack`相当于线程池其中一个线程Thread1的程序栈。我们可以这么理解一个Thread其实也是一个对象，处于堆中。
2. Thread内部持有一个map【06】，这个map的生命周期等同于这个线程的生命周期，因为使用的线程池，并且没有shutdown，那么这个map其实会一直处于堆中。【05-06这条引用链和线程池生命周期一样】
3. 此时我们创建了一个Object：XX，即上面关系线【01】。**通过ThreadLocal将XX放入到Thread的map中，就会产生2个新的引用【02-03】。**--这就是内存泄露的关键。
4. 此时我们假设Thread1任务执行完成了，那么【01】这条链就会断裂了。一般情况下，我们就会认为XX已经没有地方引用它了，**但其实还存在着【03】这个链，而【03】这个链因为【05-06】这2个链和线程池的生命周期一致，所以他也会跟着一致存在！**
5. 所以导致内存泄露的原因就是因为下面这条引用链：

> Thread Pool > Thread Ref > Thread > ThreaLocalMap > Entry > value
> 对应图片的：05 > 06 > 03

对于Java程序员来说，因为很少关注对象的回收，所有对象使用完了都放心的全部都交给垃圾回收器来处理。我个人觉得这才是导致内存泄露的主要原因 🐶。然而ThreadLocal这一神物，却刚好钻了空子。我们程序中可能已经不再使用某个ThreadLocal进行set的对象了，但是线程中会一直持有该对象的相关引用。

综上，**<u>`内存泄露的真实原因是：线程内部也会引用所创建的对象，而这层引用对我们来说是透明的！而调用remove方法会将这个引用给清除，所以如果使用得当，ThreadLocal是不会导致内存泄露的。`</u>**



### 为什么用弱引用而非强引用

上面有一个特别的点：【02】这条引用是虚线，因为ThreadLocalMap里面的Entry中，持有的是ThreadLocal对象的弱引用（只要GC就会被立即回收）：

```java
static class Entry extends WeakReference<ThreadLocal<?>> {
    Object value;
    Entry(ThreadLocal<?> k, Object v) {
      	// k 弱引用了构造传来的Thread对象
        super(k);
        value = v;
    }
}
```

那么，为啥需要使用弱引用呢？说这点之前先明确一个立场：

> 内存泄露是不规范使用ThreadLocal必然结果，和弱引用毫无关系。弱引用是对ThreadLocal内存泄露做的一定的优化。

（当时囫囵吞枣我自己为了应对面试没咋仔细看，但是抓这些关键词倒是很厉害，我自己莫名其妙吧内存泄露和弱引用关联起来了 😂。）

- 首先，使用强引用，不仅value无法被释放！Entry的key即使用完了也无法被释放！即new的ThreadLocal对象无法被回收。
- 然后，**使用弱引用有下面几个好处**：
  - 当外面ThreadLocal不需要再被使用之后，下次GC就会直接回收，可以减少ThreadLocal这部分的内存泄露。
  - 当ThreadLocal对象被回收之后，Entry的key就是null了。然后ThreadLocal就在这方便做了优化：**在下一次ThreadLocalMap调用set()，get()，remove()方法的时候会去清除这些key为null的value的值（这个可以自己去看看ThreadLocalMap源码）。**  特别提醒一点：这个get，set，remove操作是你在外部操作其他的ThreadLocal对象触发的。
  - 所以GC了让key变成null，是有利于下次map做操作的时候，清除无用value的。这样可以再进一步的减少内存泄露的量。

**综上：使用弱引用，只是为了减少内存泄露的量！但是他还是不能解决内存泄露的问题。所以我们使用ThreadLocal的时候还是必须在用完了后调用remove方法避免内存泄露。**



> 重要的话多说几遍：使用ThreadLocal一定要注意一点，当我们使用完了线程本地对象后，一定要调用remove方法！！！来避免内存泄漏。



【参考】

https://www.jianshu.com/p/d225dde8c23c

https://blog.csdn.net/Y0Q2T57s/article/details/83247430





































