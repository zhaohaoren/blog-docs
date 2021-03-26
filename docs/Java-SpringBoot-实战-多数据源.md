





# 分包的方式

注意点：

1.  配置文件url 需要为 jdbc-url
2. 如果使用mybatis-plus 需要指定 SqlSessionFactoryBean 为 mybatis的 `MybatisSqlSessionFactoryBean`

不然会报 `*invalid bound statement* (*not found*)` 问题





分包的方式好处， 我想知道操作这个数据库有哪些sql。或者说我想知道这个方法到底调用的什么库的sql，通过包名就可以一眼看出来了。而如果使用注解的方式，在滥用的情况下项目中会这样：一个人把所有的sql都杂七杂八的放在了一个Mapper中去，然后通过一对注解来区分sql的执行。

一旦重构或者说做微服务切分的时候，那这坨Mapper就是一坨屎。