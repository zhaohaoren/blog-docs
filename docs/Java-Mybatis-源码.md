建议顺序

1. 学习mybatis的常用用法，用的差不多熟练了
2. 去源码中寻找对应的用法的位置及原理
3. 从源码学习中，再去思考之前使用中哪些不恰当行为，还有哪些知识盲点。
4. 一直到至少说，mybatis整体的核心流程在你面前就像光屁股一样，mybatis算是了结了。
5. 后面提升点就是玄学问题了：设计的初衷？设计模式？为什么这么做？为什么不那么做？













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















就不看spring的整合了，直接来看看 SpringBoot 玩了哪些蛇吧



从mapper中获取的啥？ 获取的是 MapperProxy 代理，这是一个被jdk动态代理的

看到MapperMethod的execute方法。



在从select触发



BoundSql  最重要的对象