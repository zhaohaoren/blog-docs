---
title: 【JAVA】ThreadLocal理解-结合连接池
date: 2020-05-10 01:26:02
tags:
---

本想看看博客理解下ThreadLocal，看了几篇看的似懂非懂，还看出一堆疑问。从很多博客中也看出了ThreadLocal感觉没表面那么简单，但是表述貌似也不好。

<!-- more -->

## ThreadLocal和Thread关系

先来图说话（说半天源码真不如来张图）

![20171107163254061](:java-threadlocal/20171107163254061.png)


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