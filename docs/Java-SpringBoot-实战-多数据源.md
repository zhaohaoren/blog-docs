





# 分包的方式

注意点：

1.  配置文件url 需要为 jdbc-url
2. 如果使用mybatis-plus 需要指定 SqlSessionFactoryBean 为 mybatis的 `MybatisSqlSessionFactoryBean`

不然会报 `*invalid bound statement* (*not found*)` 问题

