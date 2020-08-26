# MyBatis开发指南

- 什么是Mybatis

MyBatis is a first class persistence framework with support for custom SQL, stored procedures and advanced mappings. MyBatis eliminates almost **all of the JDBC code and manual setting of parameters and retrieval of results.** MyBatis can use simple XML or Annotations for configuration and map primitives, Map interfaces and Java POJOs (Plain Old Java Objects) to database records.



加粗部分指的MyBatis的主要作用就是将参数设置进入SQL，然后查出来的数据映射到对象上去。

- JDBC的对比



Mybatis Generator

Example类

这东西方便我们不需要自己去写SQL的方式来查询，但是这东西用起来生成了乱七八糟一堆东西，而且没有SQL我们无法清晰的知道对哪些字段来建立索引，后期说SQL优化啥的就更头疼了（我们去找代码看哪里需要用索引吧，如果直接都SQL多方便）。

注解方式使用Mybatis

看源码可以知道，Mybatis是先loadXML然后再获取Mapper文件来处理注解的，所以如果两边同时都写了SQL，我们以注解的为准。





- TypeHandler 将JDBC的数据类型转为我们Java的数据类型，Mybatis已经内置了一些类型转换器。
  - https://mybatis.org/mybatis-3/configuration.html#typeHandlers
  - 作用：Java存数据库怎么存，数据库数据读到Java什么形式。





SqlSessionFactory生成SqlSession，SqlSession创建SqlTemplate，SqlTemplate会加载Mapper，所以Mapper不需要加注解也能注入。

SqlSessionFactory作用域是全局的，SqlSession是线程级的，在请求的单词线程中。











