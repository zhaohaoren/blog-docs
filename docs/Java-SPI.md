# 深入理解SPI机制

> 突然看到的新词汇，了解一下！词感觉很高端，实际并不是什么高深的技术。

SPI，全称Service Provider Interface，是Java内置的服务发现机制（这个服务发现不是微服务里面注册中心那个服务发现）。

简单的来讲，Java的SPI机制就是指：**针对一个接口**，我们**需要加载外部对该接口的实现**，只要约定好**将该实现配置在classPath路径下的META-INF/services文件夹的文件**，使用放就可以自动加载文件里所定义的类。

SPI中三个重要的角色：

- 接口
- 配置文件
- ServiceLoader反射获取

我们可以直观的理解：SPI就是JDK提供的一个功能，JDK中提供的`ServiceLoader`可以读取第三方在META-INF/services文件夹中配置的文件，然后自动加载文件里所定义的类，这样我们引入第三方包的时候，无需任何硬编码就可以使用到第三方包中提供的实现类。

具体为什么有该机制见下文：jdbc案例。

SPI给人的感觉有点像Spring的IOC，指定一个接口，通过JDK的ServiceLoader就可以自动装配该接口的实现类。而装配的控制权移到了程序之外（在第三方包中），并且实现在模块装配的时候不用在程序中动态指明。所以SPI的核心思想就是解耦，这在模块化设计中尤其重要。

SPI为**很多框架**扩展提供了可能，比如在Dubbo、Spring、SpringBoot相关starter组件、JDBC中都使用到了SPI机制。注意重点词是：**框架**！我们一般使用SPI的也是框架中使用，因为框架有些东西只需要定义标准，然后具体的实现需要依据不同的场景来选取最时候的实现，这时候框架中可以使用SPI接口来扩展自己的功能。

BTW，JDK的SPI机制有一些缺点，类似于Dubbo这些框架有自己的SPI实现。

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

这里以JDBC为例子。

### JDBC

JDBC4.0以前， 在使用mysql的时候还需要写`Class.forName("xxx")`的方式来装载mysql方提供驱动实现，JDBC4.0之后基于spi的机制来发现驱动提供商了，JDK通过`METAINF/services/java.sql.Driver`文件里指定实现类的方式来加载驱动的实现类。

- JDBC4.0之前

```java
Class.forName("com.mysql.cj.jdbc.Driver");
conn = DriverManager.getConnection(DB_URL, USER, PASS);
//....
```
这里面的forName就是硬编码了，不是很优雅。我们追求的是面向接口编程，像下面这样：

- JDBC4.0之后

```java
//Class.forName("com.mysql.cj.jdbc.Driver");
conn = DriverManager.getConnection(DB_URL, USER, PASS);
//....
```
主要的加载逻辑在`DriverManager`里面，我们可以看到DriverManager有一个静态代码块：

```java
static {
    loadInitialDrivers();
    println("JDBC DriverManager initialized");
}
```

在`loadInitialDrivers`方法通过SPI机制加载驱动实现类：

```java
private static void loadInitialDrivers() {
//...
  					//spi调用加载Driver.class在METAINF/services/java.sql.Driver指定的类
            ServiceLoader<Driver> loadedDrivers = ServiceLoader.load(Driver.class);
            Iterator<Driver> driversIterator = loadedDrivers.iterator();
//...
    println("DriverManager.initialize: jdbc.drivers = " + drivers);

    if (drivers == null || drivers.equals("")) {
        return;
    }
    String[] driversList = drivers.split(":");
    println("number of Drivers:" + driversList.length);
    for (String aDriver : driversList) {
        try {
            println("DriverManager.Initialize: loading " + aDriver);
            Class.forName(aDriver, true,
                    ClassLoader.getSystemClassLoader());
        } catch (Exception ex) {
            println("DriverManager.Initialize: load failed: " + ex);
        }
    }
}
```

而我们的`mysql-connector-java.jar` 指定了

![image-20201104195828105](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-SPI/image-20201104194557695.png)

本质上也就相当于`DriverManager` 帮我们从`mysql-connector-java.jar` 中`forName`了配置的驱动类。

#### 思考

JDK是标准的制定方，他指定了使用Java程序读取数据库这类的东西，都需要符合JDBC的标准。标准出来了，各大数据厂商就需要针对这个标准提供自己数据库的实现， `mysql-connector-java.jar`就是mysql数据库厂商为了实现JDK的JDBC标准的mysql实现。（JDK不可能提供Driver的实现，他只能提供一个规范，不然不可能把各个数据库厂商的实现都放在JDK里面吧！）

在没有**SPI机制之前**，我们写一个Java程序没有办法去自动发现mysql方给我们提供的实现的，或者说我们想加载mysql驱动的时候，就必须要知道mysql给我们提供的驱动的全限定类名（即`com.mysql.cj.jdbc.Driver`）是啥才能去加载。

有了**SPI机制之后**，在JDK程序方，我们不需要手动指定了，这个指定交给mysql提供方jar包来完成，我们只要双方统一一个约定：**指定的配置必须要放在METAINF/services/下面。**这样，JDK自己就能加载该目录的实现类了。

所以SPI给我们带来的好处：引入第三方包如 `mysql-connector-java.jar`，我们可以不用任何硬编码如`Class.forName("com.mysql.cj.jdbc.Driver");`就可以使用`com.mysql.cj.jdbc.Driver`了。JDK自己可以找到那个实现类。



## 破坏双亲委派？

先回忆下什么是双亲委派：当某个类加载器需要加载某个`.class`文件时，它首先把这个任务委托给他的上级类加载器，递归这个操作，如果上级的类加载器没有加载，自己才会去加载这个类。

再以JDBC为例：`Driver`和`DriverManager`都是在JDK中的，他们是BootstrapClassLoader启动类加载器进行加载的，而`com.mysql.cj.jdbc.Driver`是第三方的实现，他是AppClassLoader系统类加载器进行加载的。

我们可以执行：

```java
System.out.println(DriverManager.class.getClassLoader());
System.out.println(Driver.class.getClassLoader());
System.out.println(Connection.class.getClassLoader());
System.out.println(conn.getClass().getClassLoader());
//返回结果
null
null
null
sun.misc.Launcher$AppClassLoader@18b4aac2
```

可以看到Driver和DriverManager和Connection这些都是通过BootstrapClassLoader加载的（java无法获取该加载器所以返回null）。但是`conn.getClass()`的类加载器是AppClassLoader。

理一下流程：JVM首先会接受到了DriverManager的类加载请求，于是向上委派到了BootstrapClassLoader进行了加载，以及Connection和Driver这些都是该加载器进行加载的。但是Driver的具体的实现类都是由各个厂商提供的，如果这些实现类放在JDK里面自然没有问题，都是BootstrapClassLoader来加载。但是这些不在jdk的lib下面，BootstrapClassLoader是无法加载的。

这时候BootstrapClassLoader在加载DriverManager的时候，DriverManager其实内部使用的都是jdk目录里面的的类，所以DriverManager相关的类都应该是BootstrapClassLoader来加载的（即整个加载DriverManager的过程应该都是在BootstrapClassLoader下完成的，因为这些类都在jdk的lib下面）。但是我们获取到的Connection却是AppClassLoader来加载的。这意味着：**BootstrapClassLoader在加载DriverManager的过程中，又委派了其子级AppClassLoader来加载第三方的驱动类。**所以说SPI破坏了双亲委派机制（只能下级委派给上级，上级不行再由下级加载，而这里是上级加载的过程中委托下级App加载器去加载第三方包的类，即**上级委托了下级**！）。

但是，我们输出：

```java
System.out.println(conn.getClass());
// 输出
class com.mysql.cj.jdbc.ConnectionImpl
```

发现这个Connection类其实本质上是com.mysql的类！“AppClassLoader加载一个第三方类看起来并没有违反模型 [知乎](https://www.zhihu.com/question/49667892) ”，这是SPI破坏委派的争议点。这么说也是有道理的。

但是从类加载的角度将，按照双亲委派的说法，我觉得还是破坏了！原因如下：

- DriverManager是JDK的东西，是BootstrapClassLoader加载的。BootstrapClassLoader加载的 DriverManager 是不可能拿到AppClassLoader加载的实现类的，对于BootstrapClassLoader加载器，他是不可见的。
- 我们可以想象一下这些类加载器就是一个套娃，最里面是BootstrapClassLoader，然后最里面娃娃里面存放的是DriverManager这些类，他在加载DriverManager的时候，只会加载自己能看到的jdk/lib下的东西。但是SPI不同，在加载DriverManager的时候，还加载了第三方包的东西，而这部分东西在套娃的最外层。这明显不符合套娃的规则。
- 双亲委派的目的是为了重复加载类，同时防止核心类被覆盖了。显然使用了SPI在外观上讲，JDK核心的Driver和Connection似乎就是被外层的第三方实现给覆盖了。
- 而且主要因为双亲委派模型并非强制模型，Java通过一个线程上下文类加载器，通过`setContextClassLoader()`默认情况就是应用程序类加载器然后`Thread.current.currentThread().getContextClassLoader()`获得类加载器来加载。

```java
public static <S> ServiceLoader<S> load(Class<S> service) {
    // 设置上下文类加载器
    ClassLoader cl = Thread.currentThread().getContextClassLoader();
    return ServiceLoader.load(service, cl);
}
```

我们就可以通过从线程上下文（ThreadContext）来获取 classloader去加载class。这就是相当于套娃上掏了一个洞，这个洞是个管子，管子里面只有这个加载器（一般就是AppClassLoader）。



【参考】

- https://www.zhihu.com/question/49667892
- https://segmentfault.com/a/1190000020422160?utm_source=tag-newest