# SpringBoot与多数据源

目前微服务大行其道，大部分的架构都已经转为单服务单库来最大程度的解耦数据源的业务关联性。但是依然存在少数场景会遇到需要使用多数据源的场景。再则，撇开微服务来说，单体的SpringBoot服务在我们开发中，多数据源的情况就更加普遍了。本文主要聊聊多数据源的一些方案即对应的实现。

## 主流的多数据源方案

目前主流的多数据源方案宏观上来讲，主要就分为2种：

1. 基于分包的方式
   - 分包的方式很好理解，就是讲多个数据源的XXMapper文件分在不同的包中，然后针对每一个数据源都会向Spring容器注入一个DataSource以及对应的SqlSessionFactory实例。这样如果有4个数据源，那么Spring最后容器中就会有4个独立的DataSource，以及4个独立的SqlSessionFactory实例。这样设计保证了数据源在dao层是完全隔离的，这是最简单直接且不容易出错的方法。
2. 基于AOP切面拦截的方式
   - AOP的实现方案就很多了，但是他们大部分的结构是只有一个SqlSessionFactory实例，但是有多个DataSource，在需要切换的时候，切换当前线程下SqlSessionFactory对应的DataSource。
   - 这里列举一些方法：
     - 基于约定：定义mapper的规范，比如统一以什么开头，然后让AOP去拦截这些类或者方法，从而从类名方法名中获取数据源的信息。
     - 基于注解：在需要使用地方加上自定义的数据源注解，通过AOP拦截这些带注解的类和方法，从而进行数据源的切换。

### 优缺点

#### 分包

- 优点
  - 实现简单，直接，而且一定不会出错。
  - 定位sql等很清晰，一眼就能知道这个sql的方法是在哪个库上执行的。
- 缺点
  - 不够灵活，即我需要做对Mapper分文件夹的额外工作。
  - Mapper类文件会很臃肿，我们可能会需要管理大量的Mapper类。
  - 在某些场景下，这种方式是完全不可取的（或者说，单纯只使用分包方法是不可取的，下面会给出这样的场景）。

#### AOP

- 优点
  - 灵活，基本满足所有的场景（只要你需要什么场景，通过AOP都能整出适合它的方案）
- 缺点
  - 每个使用的地方都需要加上注解，或者一个标识，还是比较麻烦的，而且不敢保证不会出现忘记或者写错的情况。
  - 太灵活了，用的好还行，代码会很恶心。（来自实际工作经验，有了这个东西，很多写代码不注重质量的人，SQL乱放，数据源乱切，代码极乱）
  - 对代码的侵入性很高。这也是我们不是很喜欢他的一点。有些注解的方法，需要在代码里面到处加上数据源的注解，这些东西对业务开发本身毫无意义，更有甚者，在代码逻辑里面进行数据源切换的。（这其实对代码的侵入性太高了，你总不会喜欢看着项目的业务代码逻辑呢，突然给你来一段代码只是用来做数据源切换的吧，而且Spring为我们提供一系列的机制其实都是希望对我们自己写代码能够最小侵入性）。

### 如何选型



## 实现

### 分包



### AOP

我们可以使用苞米豆提供的[动态数据源方案](https://dynamic-datasource.github.io/dynamic-datasource-doc/)。他是一个基于AOP+ThreadLocal方式，通过注解标记方法或者类来完成数据源切换，详细可以阅读官方文档。







其实分包和AOP是可以结合起来使用的，我们针对我们当前的场景可以定制出很多最适合自己的方案。

# 分享

1.  主流多数据源方案（优缺点）

- 分包方式
  - 优点：约定规范，对业务代码的侵入性低
  - 缺点：数据库多了，维护成本大，有些场景是完全不适应的
- AOP方式
  - 优点：灵活
  - 缺点：侵入性高



1.  苞米豆的实现方式
2. 我的修改
3. 使用（注意事项）



# dynamic-datasource-spring-boot-starter

概览

![image-20201108200852295](D:\workspace\blog-docs\docs\Java-SpringBoot-实战-多数据源\image-20201108200852295.png)

```powershell
> annotation
> aop
> creator
> ds
> enums
> exception
> plugin
> processor
> provider
> autoconfigure
> strategy
> support
> toolkit
> > DynamicRoutingDataSource
```





整体分为2个块：

- 加载数据源
- 数据源切换

### 加载数据源

这里的逻辑很简单，大致有三个参与对象，如图展示：

![image-20201108224512018](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20201108224512018.png)

**其基本思想就是`DataSourceProvider`通过`DataSourceCreator`去创建`DynamicRoutingDataSource`对象。**

先说说这三个对象承担的职责：

- provider：提供对从何处解析数据源提供支持。
  - 默认是从`yml`中解析数据源。可以自己定义实现来决定你要从哪里选择数据源
- creator：依据配置创建对应的数据源，封装真正创建数据源的方法。
  - 内置了`Druid`，`Hikari`等连接池的创建方式。

- DynamicRoutingDataSource：自定义的数据源，内持一个map存储所有的数据源。







使用的是自定义的数据源 `DynamicRoutingDataSource`

里面的核心属性

```java
private String primary = "master";
private final Map<String, DataSource> dataSourceMap = new LinkedHashMap<>();
```

其实就是讲将多个数据源对象放在一个Map中，key是配置文件中配置的数据源名称。





有2个`DataSourceProperties`:

- DynamicDataSourceProperties：配置动态数据源最外部的那些项目
- DataSourceProperties：针对每个数据源的配置项目



#### 详细流程

1. 先自动配置`DataSourceCreator`,这些creator都是封装了创建各种数据源的方法。
2. 拿到各个数据源的配置属性 `Map<String, DataSourceProperty>`。
3. 交给`YmlDynamicDataSourceProvider`并创建该provider的bean实体，同时会注入creator进provider。
4. 创建`DynamicRoutingDataSource`，将provider实体set进去。
5. 将`DynamicRoutingDataSource`注入Spring的时候进行初始化（`afterPropertiesSet`方法）
6. 调用provider的`loadDataSources()`方法，创建好数据源Map。
7. 所有数据源加载完毕。



### 数据源切换

数据源的切换是通过AOP+ThreadLocal实现的。



AOP 两个切面相关的

- DynamicDataSourceAnnotationAdvisor
  - 定义拦截规则`PointCut`
- DynamicDataSourceAnnotationInterceptor
  - 



#### 详细流程

1. 自动配置数据源加载完成后，还会继续注入`DynamicDataSourceAnnotationAdvisor`这么一个切面。

2. 这个切面拦截所有`@DS`注解的方法和类。

3. 在被拦截的切入点的方法调用织入了切换数据源的逻辑。

   ```java
   public Object invoke(MethodInvocation invocation) throws Throwable {
       try {
           // 反射获取到调用者注解上的配置的数据源信息
           String dsKey = determineDatasourceKey(invocation);
           // 切换数据源
           DynamicDataSourceContextHolder.push(dsKey);
           return invocation.proceed();
       } finally {
           // 切回数据源
           DynamicDataSourceContextHolder.poll();
       }
   }
   ```

4. 主要通过`DataSourceClassResolver `解析获取执行方法所配置的注解信息。 

5. 如果数据源的key是以`#`开头的，说明需要动态数据源进行解析，那么会走`DsProcessor`进行处理（`DsProcessor`是解析`@DS`上配置的内容的处理器，可以自定义）。

数据源切换的核心是：`DynamicDataSourceContextHolder`

通过ThrealLocal 存储一个栈，因为baomidou采用的就近原则来切换数据源的，所以在一个调用链的不同层上，是一个栈结构，后切的数据源用完了需要切回上一级的数据源。



### 自动读写分离

提供了插件，但是没有自动配置，需要我们自己手动去配置。



### 数据源组

一个库 多实例，负载均衡的去读。









