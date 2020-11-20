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









