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

