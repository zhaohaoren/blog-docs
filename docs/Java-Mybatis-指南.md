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





## JDBC

- SPI





Mybatis-config.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE configuration PUBLIC "-//mybatis.org//DTD Config 3.0//EN" "http://mybatis.org/dtd/mybatis-3-config.dtd">
<!-- 配置 -->
<configuration>
    <!-- 属性 -->
    <properties resource="org/mybatis/example/config.properties">
        <property name="username" value="dev_user"/>
        <property name="password" value="F2Fa3!33TYyg"/>
    </properties>
    <!-- 设置 -->
    <settings>
        <!--https://mybatis.org/mybatis-3/zh/configuration.html#settings-->
        <setting name="cacheEnabled" value="true"/>
        <setting name="mapUnderscoreToCamelCase" value="false"/>
    </settings>
    <!-- 类型命名 -->
    <typeAliases>
        <!--可以配置包/类-->
        <typeAlias alias="Author" type="domain.blog.Author"/>
        <package name="domain.blog"/>
    </typeAliases>
    <!-- 类型处理器 -->
    <typeHandlers>
        <!--指定具体的类-->
        <typeHandler handler="org.mybatis.example.ExampleTypeHandler"/>
        <!--让mybatis查询包下面的typeHandler-->
        <package name="org.mybatis.example"/>
    </typeHandlers>
    <!-- 对象工厂 -->
    <objectFactory type="org.mybatis.example.ExampleObjectFactory">
        <property name="someProperty" value="100"/>
    </objectFactory>
    <!-- 插件 -->
    <plugins>
        <plugin interceptor="org.mybatis.example.ExamplePlugin">
            <property name="someProperty" value="100"/>
        </plugin>
    </plugins>
    <!-- 配置环境 -->
    <environments default="development">
        <!-- 环境变量 -->
        <environment id="development">
            <!-- 事务管理器 -->
            <transactionManager type="JDBC">
                <property name="..." value="..."/>
            </transactionManager>
            <!-- 数据源 -->
            <dataSource type="POOLED">
                <property name="driver" value="${driver}"/>
                <property name="url" value="${url}"/>
                <property name="username" value="${username}"/>
                <property name="password" value="${password}"/>
            </dataSource>
        </environment>
    </environments>

    <!-- 数据库厂商标识 -->
    <databaseIdProvider type="DB_VENDOR">
        <property name="SQL Server" value="sqlserver"/>
        <property name="DB2" value="db2"/>
        <property name="Oracle" value="oracle"/>
    </databaseIdProvider>

    <!-- 映射器 -->
    <mappers>
        <mapper resource="org/mybatis/builder/AuthorMapper.xml"/>
        <!--可以指定包-->
        <package name="org.mybatis.builder"/>
    </mappers>
</configuration>
```



Mapper文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.mybatis.mapper.xxMapper">
    <select id="selectAll" resultType="org.mybatis.mapper.Entity">
    </select>
</mapper>
```





# MyBatis - 插件

是干嘛的？

怎么写？





2中方式设置插件

- config.xml中配置
- @Configuration中配置

原理 







# JDBC

# DataSource



