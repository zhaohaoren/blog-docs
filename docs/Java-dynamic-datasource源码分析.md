# dynamic-datasource 源码分析

新公司很多地方使用了多数据源，之前老公司一直都是通过配置多个DataSource来解决的，在公司发现都喜欢用这个框架，就简单看看源码。[源码地址](https://github.com/baomidou/dynamic-datasource-spring-boot-starter)

这是MP（Mybatis-plus）的组织苞米豆出品的一个多数据源方案，用的人还比较多。

## 分析步骤

### 自动配置

1. 首先，这是一个SpringBoot启动器，所以我们先从`spring.factories` 入手。

   - 发现帮我们自动配置了`DynamicDataSourceAutoConfiguration`

2. 查看`DynamicDataSourceAutoConfiguration`配置类。

   - 先看看比较重要的注解

    ```java
   @EnableConfigurationProperties(DynamicDataSourceProperties.class)
   @AutoConfigureBefore(DataSourceAutoConfiguration.class)
   @Import(value = {DruidDynamicDataSourceConfiguration.class, DynamicDataSourceCreatorAutoConfiguration.class})
   @ConditionalOnProperty(prefix = DynamicDataSourceProperties.PREFIX, name = "enabled", havingValue = "true", matchIfMissing = true)
    ```
	- 我们依次来看
	
	  - DynamicDataSourceProperties 就是我们在yml可以配置的属性值，这些配置会被映射到该类对象中。
	  - AutoConfigureBefore，为了防止和SpringBoot默认的启动器`DataSourceAutoConfiguration`冲突，设置该配置要在其自动配置之前进行配置。
	  - Import，像容器中注入2个配置的BeanDefinition：
	    - DruidDynamicDataSourceConfiguration：复用Druid的自动配置
	    - DynamicDataSourceCreatorAutoConfiguration：该配置类，主要为了往容器注入DataSource创建器的bean。有4种创建器（默认，JNDI，Druid，Hikari）
	  - ConditionalOnProperty 表明了可以通过配置`spring.datasource.dynamic.enable=false`来关闭动态数据源配置
	
	- 然后改配置类往容器注入了以下beans：
	
	  - `DynamicDataSourceProvider`：该provider接受配置文件中多个数据源的配置信息，并提供一个方法`loadDataSources`用于加载多个数据源。
	
	    ```java
	    @AllArgsConstructor
	    public class YmlDynamicDataSourceProvider extends AbstractDataSourceProvider {
	        /**
	         * 配置文件中数据源的配置信息
	         */
	        private final Map<String, DataSourceProperty> dataSourcePropertiesMap;
	      	// 可以调用该方法，来加载DataSource对象。具体的创建是由creator来创建的
	      	// 这个creator是DynamicDataSourceCreatorAutoConfiguration注入的
	        @Override
	        public Map<String, DataSource> loadDataSources() {
	            return createDataSourceMap(dataSourcePropertiesMap);
	        }
	    }
	    ```
	
	  - `DataSource`：这就是该动态数据源的实现方案，该方案中全局只有一个DataSource，是一个自定义的DataSource：`DynamicRoutingDataSource`。
	
	    - 该自定义DataSource本质就是内部一个Map保存所有的DataSource，然后通过primary来确定默认使用的是哪个DataSource。
	    - 创建该DataSource依赖上面创建的provider。在DynamicRoutingDataSource的属性都设置完成后，将会调用其`loadDataSources`方法获取数据源。
	
	  - `DynamicDataSourceAnnotationAdvisor`：往容器注入AOP切面：主要就是Interceptor和指定PointCut，数据源的切换的核心逻辑就在这里面。
	
	  - `Advisor`：`dynamicTransactionAdvisor`，多数据源下的事务支持，早期该多数据源是不支持事务的：如果想要事务就要使用seata做分布式事务。这个下面详细讲讲。
	
	  - `DsProcessor`：数据源的处理器，主要是解析配置的注解内容来决定使用什么数据源。
	
	- 至此自动配置完成。
	
3.  我们捋一下，自动配置几个重要的参与对象
	
	1. creator：真正创建数据源DataSource对象的创建者，封装了将DataSourceProperty解析并创建成DataSource对象的方法。
	2. provider：数据源提供者，它内部持有creator来创建对象，并暴露`loadDataSources`方法返回所有的数据源。
	3. AOP切面：一个用来拦截数据源切换的，一个用来处理事务的。
	4. processor：处理器，主要是从注解上解析出，需要切换的数据源信息。
	

### 数据源切换原理

苞米豆的数据源切换，主要是通过@DS注解的方式来切换数据源的。这部分逻辑主要走的就是AOP的切面逻辑。我们入口主要在上面自动配置中说的第一个切面类中，主要涉及2个类：`DynamicDataSourceAnnotationAdvisor`, `DynamicDataSourceAnnotationInterceptor`。

#### DynamicDataSourceAnnotationAdvisor

该类主要定义了切入点：

```java
    private Pointcut buildPointcut() {
        Pointcut cpc = new AnnotationMatchingPointcut(DS.class, true);
        Pointcut mpc = new AnnotationMethodPoint(DS.class);
        return new ComposablePointcut(cpc).union(mpc);
    }
```

可以看到这里就是对@DS注解做了拦截。（苞米豆的AOP切面实现采用的非注解方式，而是Advisor方式）

具体的拦截处理方法在下面`DynamicDataSourceAnnotationInterceptor`里面。

#### DynamicDataSourceAnnotationInterceptor

包含2个重要的属性：

```java
//加入扩展, 给外部一个修改aop条件的机会 （这个机会其实就是让我们可以配置是否只处理public的方法）
private final DataSourceClassResolver dataSourceClassResolver;
// 这是我们上面提到的，主要为了解析@DS里面内容的（因为DS可能是个表达式）
private final DsProcessor dsProcessor;
```

该类实现了`MethodInterceptor`,所以我们核心的切入逻辑就在`invoke`方法。

```java
@Override
public Object invoke(MethodInvocation invocation) throws Throwable {
  	// 拿到需要切换数据源的key
    String dsKey = determineDatasourceKey(invocation);
  	// 设置当前线程使用的DataSource为该key的DataSource
    DynamicDataSourceContextHolder.push(dsKey);
    try {
      	// 执行原逻辑
        return invocation.proceed();
    } finally {
        // 使用完了，弹出，因为@DS是可以嵌套的，我们应该将数据源设置为之前的数据源
        DynamicDataSourceContextHolder.poll();
    }
}
```

这里是切换数据源的核心！！！

##### 重点逻辑

###### 如何决定数据源的

```java
private String determineDatasourceKey(MethodInvocation invocation) {
    String key = dataSourceClassResolver.findDSKey(invocation.getMethod(), invocation.getThis());
    return (!key.isEmpty() && key.startsWith(DYNAMIC_PREFIX)) ? dsProcessor.determineDatasource(invocation, key) : key;
}
```

可以看到，我们使用的`dataSourceClassResolver`去获取DataSource的key（这个key就是你在yml中配置的数据源名称）。

key解析的逻辑：

```java
public String findDSKey(Method method, Object targetObject) {
    if (method.getDeclaringClass() == Object.class) {
        return "";
    }
    Object cacheKey = new MethodClassKey(method, targetObject.getClass());
    String ds = this.dsCache.get(cacheKey);
    if (ds == null) {
        ds = computeDatasource(method, targetObject);
        if (ds == null) {
            ds = "";
        }
        this.dsCache.put(cacheKey, ds);
    }
    return ds;
}
```

可以看到，核心在于`ds = computeDatasource(method, targetObject);`这段。并且，苞米豆为了解析key的效率，对所有的方法做了缓存。

`computeDatasource`方法比较简单，就是一级一级的找（从当前方法一直到Object）找到@DS注解，然后反射拿出注解的值。

最后，如果key是一些特殊表达式，就调用对应的processor去解析他们获取对应的DataSource的key。这就是key的解析逻辑。

###### 数据源是如何切换的

切换的核心在`DynamicDataSourceContextHolder`类中！该类内部持有一个ThreadLocal：

```java
private static final ThreadLocal<Deque<String>> LOOKUP_KEY_HOLDER = new NamedThreadLocal<Deque<String>>("dynamic-datasource") {
    @Override
    protected Deque<String> initialValue() {
        return new ArrayDeque<>();
    }
};
```

该ThreadLocal相当于为每个线程分配了一个ArrayDeque队列，虽然是队列，但是它是拿来当栈使用的。至于[原因](https://blog.csdn.net/qq_44013629/article/details/106461200)，因为ArrayDeque的效率比Stack要高。

###### 为什么必须是栈

因为我们的调用往往是嵌套的：A->B->C 当C执行完了，数据源就应该切回B的数据源了，所以应该用栈结构实现。

### 事务处理

早先版本，该动态数据源只支持单库事务，也就是说，整个调用链里面，不允许有其他的数据源切换操作，一旦有就报错。因为开启了事务后，spring事物管理器会保证在事务下整个线程后续拿到的都是同一个connection。如果想要都支持事务就要整合seata做分布式事物。但是整合seata又比较重量级。

在新的版本中，添加了@DSTransactional注解解决了本地事务。缺点就是脱离了Spring事务的机制，并且不能[混合使用](https://dynamic-datasource.com/guide/tx/Local.html#%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9)。这是单独的一套事务处理机制，和Spring没有任何关系，看看他是怎么做的吧。

> 区分好分布式事务，和本地事务。
> 本地事务：指的单个服务，下面有多个数据库，我们这一系列数据库操作事务的ACID属性就行。
> 分布式事物：指的多个服务，每个服务的接口又可能对应着1+个库，这时候保证的是这些服务间的，所以实现难度会比本地事务更大，也因此seata比较重量级

```java
@Role(value = BeanDefinition.ROLE_INFRASTRUCTURE)
@ConditionalOnProperty(prefix = DynamicDataSourceProperties.PREFIX, name = "seata", havingValue = "false", matchIfMissing = true)
@Bean
public Advisor dynamicTransactionAdvisor() {
    AspectJExpressionPointcut pointcut = new AspectJExpressionPointcut();
    pointcut.setExpression("@annotation(com.baomidou.dynamic.datasource.annotation.DSTransactional)");
    return new DefaultPointcutAdvisor(pointcut, new DynamicTransactionAdvisor());
}
```

首先，他对数据源做了一些修改：

```java
public Connection getConnection() throws SQLException {
    String xid = TransactionContext.getXID();
    // 当前线程 LOCAL_XID 为空，说明不处于事务中
    if (StringUtils.isEmpty(xid)) {
        // 返回 不带事务的原始connection
        return determineDataSource().getConnection();
    } else {
        // 处于事务中，则获取一个该数据源的 代理connection
        String ds = DynamicDataSourceContextHolder.peek();
        ConnectionProxy connection = ConnectionFactory.getConnection(ds);
        // 该线程已经有了，就直接获取，没有则创建
        return connection == null ? getConnectionProxy(ds, determineDataSource().getConnection()) : connection;
    }
}
```

在每一个getConnection的时候，通过TransactionContext这个类判断执行该sql的时候，是不是处于事务中，如果不是，则使用原始的connection，如果是就返回代理的connection。

然后在切入点：

```java
public Object invoke(MethodInvocation methodInvocation) throws Throwable {
    if (!StringUtils.isEmpty(TransactionContext.getXID())) {
        //注解了@DSTransaction的 有xid 直接执行
        return methodInvocation.proceed();
    }
    // 注解了@DSTransaction的 还没有xid的 加上xid
    boolean state = true;
    Object o;
    String xid = UUID.randomUUID().toString();
    TransactionContext.bind(xid);
    try {
        o = methodInvocation.proceed();
    } catch (Exception e) {
        state = false;
        throw e;
    } finally {
        // 执行失败，通知所有进行回滚
        ConnectionFactory.notify(state);
        TransactionContext.remove();
    }
    return o;
}
```

如果执行到了注解了`DSTransactional`注解的方法，但是TransactionContext此时感知到状态还没有处于事务中，那么就会生成一个xid然后绑定到TransactionContext中，标记当前线程处于事务中。也就在此，标记了后面的逻辑都是有事务的，后面获取的所有的代理connection。

如果方法执行中发生了异常，那么就对该线程当前的所有的代理connection进行回滚`ConnectionFactory.notify(state);`。

> 官网说这目前是个临时版本，建议本地好好测试才用在线上。我其实对这种实现方式看的感觉不对劲的，逻辑似乎写复杂了。我完全一个ThreadLocal存储一个Map，里面存放所有需要的connection就可以了。然后这个代理connection其实好像也没有必要。

#### Spring事务为什么不行

Spring事务AOP的时候，会将事务管理器和一个Connection强制绑定在一起。它在开启一个新事务的同时，会从连接池中获取一个connection实例，并将transaction和connection互为绑定。

此后transaction中只会使用此connection，此connection此时只会在一个transaction中使用。因此,在此事务中无论操作了多少次DB，实际上只会是一个connection实例，直到事务提交或者回滚。当事务提交或者回滚时,将会解除transaction与connection的绑定关系，同时将connection归还到pool中。

## 总结

该动态数据源的实现方式简单说来就是：AOP+注解+ThreadLocal栈的方式来解决的。

总体来说，整体思路还是比较简单的，只不过缺乏我们希望的一些小功能点，它并没有提供我们想要的一些实现方式，（当然，作为设计者来讲肯定是通用性优先，我们这些小场景后续肯定也不会专门为其支持）后续我会写一篇文章对其定制化的方案。



事务下为什么不能切换数据源

```
TransactionSynchronizationManager
  private static final ThreadLocal<Map<Object, Object>> resources = new NamedThreadLocal("Transactional resources");
  这个ThreadLocal里面存放了一个Map， Map 里面是datasource和一个connection 后面执行的操作其实都会从map中获取connection。
  所以切换数据源也没用，他一直使用的就是一个connection。
  
  
  获取方法
    @Nullable
    private static Object doGetResource(Object actualKey) {
        Map<Object, Object> map = (Map)resources.get();
        if (map == null) {
            return null;
        } else {
            Object value = map.get(actualKey);
            if (value instanceof ResourceHolder && ((ResourceHolder)value).isVoid()) {
                map.remove(actualKey);
                if (map.isEmpty()) {
                    resources.remove();
                }

                value = null;
            }

            return value;
        }
    }
```



# dynamic-datasource 定制化

## 添加分包方式

## 数据源自动读写分离

