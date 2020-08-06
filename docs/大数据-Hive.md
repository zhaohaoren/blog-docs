# Hive



## 安装配置



```shell
hive> show databases;
FAILED: SemanticException org.apache.hadoop.hive.ql.metadata.HiveException: java.lang.RuntimeException: Unable to instantiate org.apache.hadoop.hive.ql.metadata.SessionHiveMetaStoreClient
```

解决：

```shell
bin/schematool -dbType mysql -initSchema
```







Hive的数据主要看2点：**HDFS数据**+**MySQL元数据**。只要两者齐全了，我们任意的方式将数据创建上去（hdfs的put，hive的load等）都是可以查到的。