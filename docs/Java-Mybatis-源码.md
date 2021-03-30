# 环境搭建

github下载源码：





首先，mybatis的官网写的不错，很多问题及用法的学习可以直接参考官网的。













因为前阵子做过mybatis相关的定制开发，对mybatis有了个大致了解，现在要准备面试啦，没什么时间写文章，就花几天时间把mybatis的源码快速过一下，快速记下线索，只是方便面试用的。没准对大家阅读源码有一定的帮助。

# 解析过程

使用mybatis的流程中整体分2大块：解析和使用

## 解析

1. 首先需要一个Mybatis的配置文件：mybatis-config.xml
2. 通过`SqlSessionFactoryBuilder`来解析config.xml来创建`SqlSessionFactory`
   1. `XMLConfigBuilder.parseConfiguration()`方法先去解析`mybatis-config.xml`文件，将所有的配置封装到`Configuration`类中。
   2. `parseConfiguration`方法会按照一定顺序来解析`mybatis-config.xml`中所有的配置项（具体配置可以看官网）主要几个常用的：plugins，typeHandlers，mappers。
      1. 解析plugins：会按照顺序将所有的插件添加到`configuration`的`interceptorChain`中，`interceptorChain`是个list。
      2. 也是解析typeHandlers然后注册到`configuration`的`typeHandlerRegistry`中。
      3. 最终要的就是解析这个mappers：
         1. 针对配置的每一个Mapper.xml，使用`XMLMapperBuilder`来构建，会将Mapper.xml里面所有的信息添加到configuration中
         2. 针对增删改查的没一条SQL语句：会使用`XMLStatementBuilder`来创建`MappedStatement`，封装了这条SQL从XML中获得的所有相关的信息。
         3. 每条SQL会被解析成`MappedStatement`然后添加到`configuration`的`mappedStatements`这个map中。（这个我们debug的时候应该注意到过），同时Sql也会被`XMLScriptBuilder`进一步解析到`sqlSource`中，`#{}`这些都会变成`?`占位符。
         4. 在Mapper.xml解析完成，并且每个SQL的`MappedStatement`都添加到`configuration`之后，会调用`bindMapperForNamespace()`方法来找Mapper.xml对应接扣进行绑定。
         5. 通过反射读取XML中`namespace`指定的Mapper全限定类名，加载这个接口然后添加到`configuration`的`MapperRegistry`中
         6. 重点看这个`MapperRegistry`，他其实内部就是一个Map:knownMappers类型为`Map<Class<?>, MapperProxyFactory<?>>`。所有的Mapper接口都会被`MapperProxyFactory`包装并放入到`knownMappers`中（key是接口的类）。所以我们使用接口，其实使用的都是被这个`Proxy`代理的类。
   3. mappers下所有的Mapper都被解析完成，解析差不多就完成了。所有解析出来的配置都放到了`configuration`中。而里面最重要的2个就是：`MapperRegistry`和`mappedStatements` 一个对应着接口类，一个对应的xml配置的sql信息。
3. 此时我们就有了`SqlSessionFactory`对象（默认就是`DefaultSqlSessionFactory`），也就是说一个`SqlSessionFactory`对象其实对应着一个`mybatis-config.xml`

## 使用

1. 然后我们可以通过`DefaultSqlSessionFactory`对象的`openSession()`方法来开启一个`SqlSession`（默认的是`DefaultSqlSession`）。
2. 在
3. 最终调用的是 `MapperMethod`的`execute()`方法
4. 最终的最终 调用 SqlSession的selectList或者其他的一些方法，然后通过Executor来执行





## 一些重要类的职责

- **Configuration**
  - mappedStatements：map，存放xml中sql语句，key为每个sql配置的id
  - mapperRegistry：map，存放反射获取的Mapper接口
  - sqlFragments：map，存放xml中\<sql>标签存放的内容
  - resultMaps：map，存放xml中配置的resultMap信息
- **SqlSessionFactoryBuilder**
  - 
- **SqlSession**
  - 
- 
- **XMLConfigBuilder**
  - 负责解析`mybatis-config.xml`文件，里面封装了可以配置的节点的各种解析方法。
- **XMLMapperBuilder**
- **MapperProxyFactory**
  - mapperRegistry中包装Mapper接口的类
- **MapperProxy**
  - 最终Mapper接口文件的代理类，代理的逻辑也在该类中
- **DefaultSqlSession**
- **MapperMethod**
  - 构造创建 SqlCommand 和 MethodSignature 对象
  - `execute()`核心方法
- **SqlCommand**
  - MapperMethod的内部类，决定SqlCommand类型
- **MethodSignature**
- **Executor**
  - 默认的类型是：CachingExecutor，但是该类又是SimpleExecutor的一个装饰类，只是添加了二级缓存的支持。
- **SqlSource**
  - xml解析过程中，会将每个要执行的Sql解析成SqlSource对象，然后绑定到MappedStatement中，依据Sql的特性分为DynamicSqlSource，StaticSqlSource等，比如sql中用来很多动态sql标签的配置就会使用DynamicSqlSource。
- **BoundSql**
- **StatementHandler**
- **Statement**
- **PlainMethodInvoker**
  - 调用接口的方法为什么能够执行sql的逻辑主要在这里
- **SqlNode**
  - xml中配置的sql在解析中会被分为多个片段。每个片段对应着一种类型，如：xml配置的sql中`<if>`的内容会对应一个片段`IfSqlNode`，这些标签他们的顶级接口类就是SqlNode







![image-20210329205248161](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-Mybatis-源码/image-20210329205248161.png)



![image-20210329205100559](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-Mybatis-源码/image-20210329205100559.png)



Mapper接口大概流程：

`session.getMapper(BlogMapper.class);` -> `mapperProxyFactory.newInstance(sqlSession);`创建`MapperProxy`代理mapper类 -> ` cachedInvoker(method).invoke(proxy, method, args, sqlSession);` -> ` new PlainMethodInvoker(new MapperMethod(mapperInterface, method, sqlSession.getConfiguration()));` ->  `MapperMethod.execute` 



DefaultSqlSessionFactory创建SqlSession的过程中创建Executor实例





建议顺序

1. 学习mybatis的常用用法，用的差不多熟练了
2. 去源码中寻找对应的用法的位置及原理
3. 从源码学习中，再去思考之前使用中哪些不恰当行为，还有哪些知识盲点。
4. 一直到至少说，mybatis整体的核心流程在你面前就像光屁股一样，mybatis算是了结了。
5. 后面提升点就是玄学问题了：设计的初衷？设计模式？为什么这么做？为什么不那么做？





自己设想原理



我们程序想要访问数据库方式



connection -> mysql

Mybatis -> connection -> mysql

XXXX -> MybatisPlus -> connection -> mysql



老千层饼了



所以 mybaits的源码最终肯定有JDBC的代码的





一定要记住 Mybatis的主体结构，这样出了问题，以及自己二次开发，可以知道问题出在那一块，在哪里更适合去扩展自己的需求





# 插件

MyBatis 允许你在映射语句执行过程中的某一点进行拦截调用。默认情况下，MyBatis 允许使用插件来拦截的方法调用包括：

- Executor (update, query, flushStatements, commit, rollback, getTransaction, close, isClosed)
- ParameterHandler (getParameterObject, setParameters)
- ResultSetHandler (handleResultSets, handleOutputParameters)
- StatementHandler (prepare, parameterize, batch, update, query)





真正执行Sql的是四大对象：Executor，StatementHandler，ParameterHandler，ResultSetHandler。



大概就是JDBC不足，有了JPA和Hibernate，这些有些不足，有了Mybatis

| annotations | mybatis提供的注解                           |
| ----------- | ------------------------------------------- |
| binding     |                                             |
| builder     |                                             |
| cache       | mybatis提供的一些Cache的实现                |
| cursor      | mybatis定义的游标Cursor                     |
| datasource  |                                             |
| exceptions  | mybatis的异常                               |
| executor    |                                             |
| io          |                                             |
| jdbc        |                                             |
| lang        | JDK支持注解，就@UsesJava7@UsesJava8两个注解 |
| logging     | mybatis的日志系统                           |
| mapping     |                                             |
| parsing     |                                             |
| plugin      | mybatis的插件相关接口                       |
| reflection  |                                             |
| scripting   |                                             |
| session     | sqlSession相关                              |
| transaction | 事务                                        |
| type        | mybatis自定义的一些typeHandler              |

## 编译mybatis









statement： 用来和mysql交互的一个东西





Cannot find class: javassist.util.proxy.ProxyFactory

```xml
<dependency>
  <groupId>org.javassist</groupId>
  <artifactId>javassist</artifactId>
  <version>3.27.0-GA</version>
  <optional>false</optional> <!-- MODIFY THIS -->
</dependency>
```









XMLConfigBuilder 来解析 config.xml 文件

XMLMapperBuilder 来解析  mapper.xml文件

configurationElement 方法，将所有的xml中的配置解析成MappedStatement然后放入到map中

bindMapperForNamespace  通过namespace属性 反射获取到对应的mapper接口类



每一个xml中配置的sql 都会被解析成一个MappedStatement对象。然后configuration.addMappedStatement(statement); 加入到config的`Map<String, MappedStatement> mappedStatements`中去



MapperRegistry 的作用



MappedStatement 的结构很重要





配置文件解析  DONE



mybatis操作的时候跟数据库的每一次连接,都需要创建一个会话,我们用openSession()方法来创建。这个会话里面需要包含一个Executor用来执行 SQL。Executor又要指定事务类型和执行器的类型。



也就是 每执行一次SQL，其实都会打开一个SqlSession来进行操作。





执行SQL是通过执行器来执行的：

三种执行器

Executor

simple reuse batch 默认simple



缓存

一级缓存是默认开启的，

spring整合后一级缓存会失效？ 













就不看spring的整合了，直接来看看 SpringBoot 玩了哪些蛇吧



从mapper中获取的啥？ 获取的是 MapperProxy 代理，这是一个被jdk动态代理的

看到MapperMethod的execute方法。



在从select触发



BoundSql  最重要的对象



MyBatis 提供了一、二级缓存，其中一级缓存是 SqlSession 级别的，默认为开启状态。 二级缓存配置在映射文件中，使用者需要显示配置才能开启。二级缓存的 配置很简单。如下：

```xml
<cache/>
```



SQL 语句节点可以定义很多属性，这些属性和属性值最终存储在 MappedStatement



# Mybatis Plus

网上有很多人对使用纯ORM框架如Hibernate和Mybatis这种半自动ORM框架来做对比，其实没什么可比性。Hibernate学习成本和使用成本的高昂，自由度不如Mybatis这点显而易见，但是他对于快速开发一个简单的项目Mybatis又逊色许多，而且如今应该人人都讨厌XML吧，Mybatis这点也为Hibernate所诟病。实际开发中，Mybatis让所有的SQL都需要我们自己去写，这确实也是一大缺点：项目中什么查询都要有SQL，一旦多了xml会看着很臃肿，对于很多简单的SQL其实完全可以自动化的方式生成SQL。MybatisPlus（MP）的出现其实就是为了填补这块缺陷，让Mybatis更加强大！（有人说MP搞起来就不伦不类了，但是开发中到底爽不爽只有自己用了才知道）





[插件原理-写的不错](https://zhuanlan.zhihu.com/p/163863114)