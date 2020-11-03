# 深入理解SPI机制

> 突然看到的新词汇，了解一下！词感觉很高端，实际并不是什么高深的技术。



全称为 Service Provider Interface，是一种服务发现机制。



它通过在ClassPath路径下的META-INF/services文件夹查找文件，自动加载文件里所定义的类。



为很多框架扩展提供了可能，比如在Dubbo、JDBC中都使用到了SPI机制。



Java SPI 实际上是“基于接口的编程＋策略模式＋配置文件”组合实现的动态加载机制，在JDK中提供了工具类：“java.util.ServiceLoader”来实现服务查找。



意思我 有一接口，然后就 获取这个是 接口的具体实现类的时候 可以通过 

（注意 这里我们可没有使用Spring这类的东西，纯粹的JDK所有的东西）





## JDK SPI实战

1. 需要一个接口

   ```java
   public interface SpiService {
       void exe();
   }
   ```

2. 定义多个实现

   ```java
   public class SpiServiceImplA implements SpiService {
       public void exe() {
           System.out.println("I am A...");
       }
   }
   ```

3. 配置/META-INF/services/work.lollipops.tutorial.java.SpiService

   ```java
   work.lollipops.tutorial.java.SpiServiceImplA
   work.lollipops.tutorial.java.SpiServiceImplB
   ```

4. 测试

   ```java
   ServiceLoader<SpiService> spiServices = ServiceLoader.load(SpiService.class);
   spiServices.forEach(SpiService::exe);
   ```

输出：

```
I am A...
I am B...
I am A...
I am B...
```



## ServiceLoader源码分析

`sun.misc.Service` 源码属于sun的，我们无法看到，所以分析下`ServiceLoader`。

这个类的实现很简单，可以分为三个大块来看：

```java
public final class ServiceLoader<S> implements Iterable<S>{
    // 属性值
    private static final String PREFIX = "META-INF/services/";
    // The class or interface representing the service being loaded
    private final Class<S> service;
    // The class loader used to locate, load, and instantiate providers
    private final ClassLoader loader;
    // The access control context taken when the ServiceLoader is created
    private final AccessControlContext acc;
    // Cached providers, in instantiation order
    private LinkedHashMap<String,S> providers = new LinkedHashMap<>();
    // The current lazy-lookup iterator
    private LazyIterator lookupIterator;
    // 初始化这个Loader
  	public static <S> ServiceLoader<S> load(Class<S> service) {...}
   	private ServiceLoader(Class<S> svc, ClassLoader cl) {...}
    // LazyIterator迭代器类
    private class LazyIterator implements Iterator<S> {...}
  	// iterator迭代方法
  	public Iterator<S> iterator() {...}
}
```

### 初始化

`ServiceLoader.load(SpiService.class)` 本质是调用：

```java
private ServiceLoader(Class<S> svc, ClassLoader cl) {
    // 需要加载的接口
    service = Objects.requireNonNull(svc, "Service interface cannot be null");
    // 配置类加载器
    loader = (cl == null) ? ClassLoader.getSystemClassLoader() : cl;
    // 访问权限控制
    acc = (System.getSecurityManager() != null) ? AccessController.getContext() : null;
    // 清空lookupIterator 并初始化 LazyIterator：new LazyIterator(service, loader);
    reload();
}
```

`SpiService.class`接口需要加载的类对象，是采用懒加载的方式。初始化完成后，`ServiceLoader`内部`lookupIterator`持有这个懒加载迭代器。

### 调用迭代

```java
public Iterator<S> iterator() {
    return new Iterator<S>() {
        //...
          public boolean hasNext() {
        if (acc == null) {
            return hasNextService();
        } else {
            PrivilegedAction<Boolean> action = new PrivilegedAction<Boolean>() {
                public Boolean run() { return hasNextService(); }
            };
            return AccessController.doPrivileged(action, acc);
        }
    }

    public S next() {
        if (acc == null) {
            return nextService();
        } else {
            PrivilegedAction<S> action = new PrivilegedAction<S>() {
                public S run() { return nextService(); }
            };
            return AccessController.doPrivileged(action, acc);
        }
    }
        public boolean hasNext() {
            if (knownProviders.hasNext())
                return true;
            // 转去调用LazyIterator迭代器的方法
            return lookupIterator.hasNext();
        }
        public S next() {
            if (knownProviders.hasNext())
                return knownProviders.next().getValue();
            return lookupIterator.next();
        }
        //...
    };
}
```

这里就是一个转发，实际调用的是`LazyIterator`的迭代方法。

### 开始迭代获取（核心）

`LazyIterator`的`hasNext` 和 `next` 实际分别对应调用的是 `hasNextService` 以及 `nextService`。

```java
  private boolean hasNextService() {
      // nextName 用来存储接口实现类的全限定类名
      if (nextName != null) {
          return true;
      }
      if (configs == null) {
          try {
              String fullName = PREFIX + service.getName();
              // 如果没有获取到类加载器
              if (loader == null)
                  // 从指定的路径<//META-INF/services/work.lollipops.tutorial.java.SpiService>下面加载配置
                  configs = ClassLoader.getSystemResources(fullName);
              else
                  configs = loader.getResources(fullName);
          } catch (IOException x) {
              fail(service, "Error locating configuration files", x);
          }
      }
      while ((pending == null) || !pending.hasNext()) {
          if (!configs.hasMoreElements()) {
              return false;
          }
          // pending也是一个迭代器，parse就是解析文件，返回文件中读取的内容
          pending = parse(service, configs.nextElement());
      }
      // 接口的实现类全限定类名
      nextName = pending.next();
      return true;
  }
```

`hasNextService `就是读取我们配置的//META-INF/services/work.lollipops.tutorial.java.SpiService文件，迭代的读取里面配置的全限定类名。

```java
   private S nextService() {
       if (!hasNextService())
           throw new NoSuchElementException();
       String cn = nextName;
       nextName = null;
       Class < ? > c = null;
       try {
           // 反射加载类
           c = Class.forName(cn, false, loader);
       } catch (ClassNotFoundException x) {
           fail(service,
               "Provider " + cn + " not found");
       }
       if (!service.isAssignableFrom(c)) {
           fail(service,
               "Provider " + cn + " not a subtype");
       }
       try {
           S p = service.cast(c.newInstance());
           providers.put(cn, p);
           return p;
       } catch (Throwable x) {
           fail(service,
               "Provider " + cn + " could not be instantiated",
               x);
       }
       throw new Error(); // This cannot happen
   }
```

`nextService` 通过反射创建具体的实现类并返回。

> 本质上就是通过反射加载指定了固定位置下配置的类



## SPI 应用场景

### JDBC

jdbc4.0以前， 开发人员还需要基于Class.forName("xxx")的方式来装载驱动，jdbc4也基于spi的机制来发现驱动提供商了，可以通过METAINF/services/java.sql.Driver文件里指定实现类的方式来暴露驱动提供者.



常见的 SPI 有 JDBC、日志门面接口、Spring、SpringBoot相关starter组件、Dubbo、JNDI等。

https://segmentfault.com/a/1190000020422160?utm_source=tag-newest





## 破坏双亲委派

https://www.cnblogs.com/joemsu/p/9310226.html#_caption_2



DriverManager 这个类 存在在 rt.jar里面由启动类加载器加载,而它里面需要用到外部引入的jar,比如说 mysql-connect.jar里面的Driver,***\*于是DriverManager这个类不得不使用 Thread ContextClassLoader 去加载外部的具体实现\****.