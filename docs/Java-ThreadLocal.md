# ThreadLocal 使用及原理

在并发编程中，我们知道单线程中创建的处于栈上的变量是不会存在线程安全问题的，存在问题的是那些会被共享的变量。Java提供了很多保证线程安全的方法，ThreadLocal便是其中之一。

ThreadLocal（又被称为线程本地变量）。相对很多线程同步代码执行块的方式，ThreadLocal采用的则是空间换时间来保证线程安全：**如果我们保证每个线程访问的都是自己的变量（线程资源隔离），那么就不会存在共享的并发问题了**。我们通过ThreadLocal相当于可以为每个线程创建自己的缓存，之后在本线程中需要的变量，都从该缓存中获取即可。

## 使用

源码中注释了一段demo：

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

这里就是对每个线程分配了一个自增id。

### 使用场景

一般业务开发中有2种场景：

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

---



## 源码

ThreadLocal的源码比较简单，主体结构如下：

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

我们可以看到ThreadLocal中只是提供了一些方法，和一个内部类。它是不存放任何副本对象的。








上面图描述Thread和ThreadLocal之间的关系，从此就能得出很多基础结论了：

- 线程内部持有一个Map存放着自己的局部变量，这些变量的key是ThreadLocal对象（可以理解为什么叫做线程局部变量了吧）；
- 有一个变量想放入线程的局部变量的你就需要创建一个ThreadLocal对象；
- ThreadLocal本身没有什么存储结构，只是提供了方法，所以变量不是存在ThreadLocal中的，ThreadLocal负责搬运。

## 源码：

就两个重要方法：

### set方法

```
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

### get方法

```
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



> ThreadLocal不是用来解决对象共享访问问题的，而主要是提供了线程保持对象的方法和避免参数传递的方便的对象访问方式 （网上一段话，我没看明白，但是我知道作者想表达的get到的那个点，并且很有道理的样子）连接：[文章](http://www.iteye.com/topic/103804)



### 先理清下ThreadLocal的作用到底是什么？

它并不是为了自带了线程安全，并发控制这些机制，它是通过牺牲空间（创建额外更多的对象来），它的目的仅仅就是为了让线程使用自己的变量。---让同一个线程上的所有代码块都是使用的该变量。
就拿数据库连接来说，如果没有使用ThreadLocal，那么势必我们会定义的一个数据库Connection，然后所有的线程共享它！但是这样是线程不安全的（connection控制着事物，会导致事物混乱）！那么我们就需要同步，但是同步是很耗性能的。所以使用ThreadLocal，可以理解为为每一个线程都创建一个Connection对象（当然实际不会这样）。这个Conncetion对象只被该线程使用。--所以，不是说有一个共享变量我们为了让他线程安全就将该变量放入ThreadLocal中就安全了，这样其实还是不安全的因为引用传递，ThreadLocal做法是为每个线程创建一个对象。 
这本身就是一种空间换时间的机制，没有什么屌的优化机制在里面。

那你或许又问 这有什么用？
空间换时间-- 我们不需要使用同步块了，线程的局部中存的每个对象都是不一样的，所以不会有线程安全问题。所以之前不理解的将一个变量引用传入到ThreadLocal中这种场景本身对于ThreadLocal来讲没有意义，也就是说ThreadLocal不是用来干这个的（看了好多博客写着的意思就是讲一个Connection放入到ThreadLocal中就线程安全了？开玩笑！）

### 连接池的应用

第一次接触这个就是因为连接池

### 始终记得：

ThreadLocal 将一些线程不安全的变量，将用同步的方式转为为每个线程创建一个对象来实现线程安全。

文章也是自己理解的，可能有不对的地方，请指正。



## 内存泄漏

内存泄露发生在什么情况下？







### 为什么用虚引用而非强引用

其实就一句话：强引用一样内存泄露！







一些误区

- ThreadLocal的内存泄露是因为虚引用导致的。
  - 泄露的本质原因是：我们程序中虽然不再引用了，但是在你不知道的地方（线程对象内部map），存在着引用关系。而ThreadLocal的key是虚引用，所以key可以被回收，但是value是无法被回收的。
  - 内存泄露是ThreadLocal自身原因导致的，和虚引用还是强引用没有关系。虚引用反而是减少了内存泄露的泄露量。
  - 如果本着GC应该帮我们做到这种垃圾回收的心态的话，那么内存泄露和虚引用也只能扯上一点点关系。（我不用了你GC就应该帮我回收了啊，）想象一下，如果想要实现这个功能，那么要么value也是用虚引用（这肯定不行的）。要么就是线程要知道你什么时候这个对象是真的不用了，然后帮你进行remove操作（这好像也没得行的样子）。





对于Java程序员来说，很少关注对象的回收，所有对象使用完了都放心的全部都交给垃圾回收器来处理。我个人觉得这才是导致内存泄露的主要原因 🐶。然而ThreadLocal这一神物，却刚好钻了空子。我们程序中可能已经不再使用某个ThreadLocal对象了，但是线程中会一直持有该ThreadLocal的相关引用（虽然key会被GC成功回收）。















































