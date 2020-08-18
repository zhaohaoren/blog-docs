# Elasticsearch简介

啦啦啦啦啦啦啦

集群、节点、分片

[分片选择](https://www.elastic.co/guide/en/elasticsearch/reference/current/scalability.html#it-depends)

平均每个分片大小在几个G或者几十个G左右，比如时序型索引（例如日志或安全分析）通常在20-40G

避免有太多的分片，一个节点的分片数受限于对空间的大小，通用的规则：每GB的堆空间应该小于20个分片。具体怎么弄配置来优化查看 [testing with your own data and queries](https://www.elastic.co/elasticon/conf/2016/sf/quantitative-cluster-sizing).

*如果某个节点拥有 30GB 的堆内存，那其最多可有 600 个分片，但是在此限值范围内，您设置的分片数量越少，效果就越好。一般而言，这可以帮助集群保持良好的运行状态。*

*避免分片过大，因为这样会对集群从故障中恢复造成不利影响。尽管并没有关于分片大小的固定限值，但是人们通常将 50GB 作为分片上限，而且这一限值在各种用例中都已得到验证。*

分片是 Elasticsearch 在集群内分发数据的单位。Elasticsearch 在对数据进行再平衡（例如发生故障后）时移动分片的速度取决于分片的大小和数量，以及网络和磁盘性能。



# 部署

## 单机部署

```sh
curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.3.1-linux-x86_64.tar.gz;
tar -xvf elasticsearch-7.3.1-linux-x86_64.tar.gz;
elasticsearch-7.3.1/bin/elasticsearch -Epath.data=data2 -Epath.logs=log2;
curl -X GET "localhost:9200/_cat/health?v&pretty";
```

## 集群配置

Elasticsearch 主要有3个配置文件
- `elasticsearch.yml` 
- `jvm.options` 
- `log4j2.properties` 

### es配置

[Important Elasticsearch configuration](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html)

[`network.host`](https://www.elastic.co/guide/en/elasticsearch/reference/current/network.host.html)

[Discovery and cluster formation settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/discovery-settings.html)

### jvm配置

### 日志配置

es使用的是log4j

## 安全设置

https://blog.csdn.net/zhen_6137/article/details/86133747

还是不知道这玩意到底有啥用

## CCR

## 访问IP白名单黑名单

## [HTTP/REST clients and security](https://www.elastic.co/guide/en/elastic-stack-overview/7.3/http-clients.html)

[Add the built-in user to Kibana](https://www.elastic.co/guide/en/elastic-stack-overview/7.3/get-started-kibana-user.html)

## Important System Configuration生产环境必须要配置的东西

- [Disable swapping](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html)
- [Increase file descriptors](https://www.elastic.co/guide/en/elasticsearch/reference/current/file-descriptors.html)
- [Ensure sufficient virtual memory](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html)
- [Ensure sufficient threads](https://www.elastic.co/guide/en/elasticsearch/reference/current/max-number-of-threads.html)
- [JVM DNS cache settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/networkaddress-cache-ttl.html)
- [Temporary directory not mounted with `noexec`](https://www.elastic.co/guide/en/elasticsearch/reference/current/executable-jna-tmpdir.html)

Memery 那个为true的时候需要 打开lock权限

：* soft memlock unlimited

/etc/security/limits.con

```
* soft memlock unlimited
* hard memlock unlimited
```



这个就好了



 groupadd elastic

useradd elastic -g elastic

echo 'elastic' | passwd --stdin elastic

chown -Rf elastic.elastic  /data1/elastic/ 







# 聚合

ES有很多种聚合类型，分别针对不同的用途和目的。为了更好的理解这些聚合类型，将它们分为四个主要类型来更好理解：
- Bucketing 桶聚合
  - 该类型的聚合会创建若干个桶。每个桶都和一个key和一个文档条件相关联。当聚合被执行的时候，会对每个文档执行每个桶的文档条件，并将满足条件的文档放到对应的桶中。聚合结束后，我们获得了一系列的桶，每个桶包含一系列属于他的文档。
- Metric 指标聚合
  - 在一个文档集上跟踪并计算指标的聚合。
- Matrix 矩阵聚合
  - 在多个fields上操作并基于请求的文档字段抽取出来的值生成一个矩阵结果。不同于指标和桶聚合。这种聚合还不支持脚本。
- Pipeline 管道聚合
  - 聚合其他聚合的结果以及他们相关的指标。

聚合最强大的地方在于：**他可以进行嵌套聚合**，就是在bucket级别上对bucket再进行关联聚合。

> 注意：嵌套聚合并没有一个强制的限定嵌套的深度。

## 聚合的结构

下面是一个基本的聚合请求：

```json
"aggregations" : {
    "<aggregation_name>" : {
        "<aggregation_type>" : {
            <aggregation_body>
        }
        [,"meta" : {  [<meta_data_body>] } ]?
        [,"aggregations" : { [<sub_aggregation>]+ } ]?
    }
    [,"<aggregation_name_2>" : { ... } ]*
}
```

- 上面是一个聚合对象，aggregations也可以使用agg代替。
- 每个聚合都起了一个逻辑上的名字（用户自己定义，比如：求价格的平均值可以定义aggregation_name为price_avg）。该名字还会被作为返回的聚合结果的唯一标识。
- 每个聚合都会指定一个聚合类型（aggregation_type），通常是聚合请求体的第一个元素的key。具体什么类型需要看你想要进行什么聚合。
- 和聚合类型同级可以定义一系列的额外的聚合。当计算该聚合的时候会将所有的子聚合都进行计算。

## 值的来源

有些聚合需要从聚合的文档中抽取出值来进行计算。通常，我们是会抽取聚合中指定的文档的key用来聚合，也有可能是通过定义一个脚本来生成需要的值。

当field和脚本在聚合请求中都被配置了，脚本就会被处理为value script。通常的脚本都是作用在文档级别的，value script是作用在value级别的。在该模式下，脚本会被用作为从配置的field抽取出来的值作转换用处。

> 当使用脚本的时候，脚本的语言（lang）和参数（params）设置也可以被定义。前者定义脚本所使用的语言(假设在Elasticsearch是默认支持的，或者可以使用插件完成的)。后者支持将脚本中的所有“动态”表达式定义为参数，从而使脚本在调用时保证自身的静态(这将确保Elasticsearch会使用缓存编译好的脚本)。

ES 使用mapping中field的类型来猜测如何执行聚合操作以及返回的结果格式。但是有两种情况ES无法猜测出来：无映射字段（unmapped fields- 请求中无法找到mapping对应映射的字段）和纯脚本（pure scripts）。在这些情况下，可以使用value_type 选项给ES一个提示，该选项支持string,long（处理所有整型数据类型）,double（处理所有带小数类型）,data,ip和bool类型。

## [Metrics Aggregations](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/search-aggregations-metrics.html)



### Avg Aggregation

### Cardinality Aggregation

### Extended Stats Aggregation

### Geo Bounds Aggregation

### Geo Centroid Aggregation

### Max Aggregation

### Min Aggregation

### Percentiles Aggregation

### Percentile Ranks Aggregation

### Scripted Metric Aggregation

### Stats Aggregation

### Sum Aggregation

### Top hits Aggregation

### Value Count Aggregation





Low-level

# [Java High Level REST Client](https://www.elastic.co/guide/en/elasticsearch/client/java-rest/current/java-rest-high.html)



 requires Java 1.8 and depends on the Elasticsearch core project

client version is the same as the Elasticsearch version that the client was developed for.

 It accepts the same request arguments as the `TransportClient` and returns the same response objects. 



该Client是向前兼容的（官网文档有误，这不是向前兼容【新的可以旧的打开，旧的可以新的打开】是向后兼容【旧的不能打开新的，但是新的可以打开旧的】）：也就是说6.0可以使用6.x所有版本，但是6.1可以使用6.1之后所有版本，但是6.0-6.1的版本兼容可能有兼容问题。（6.1中新加功能的话，6.0就可能没有这个东西）

## Index-api

构建索引时候使用的api

### Index API【索引一个doc】

```java
IndexRequest request = new IndexRequest("index_name");
String jsonString = "{\"user\":\"kimchy\"}";
IndexRequest indexRequest = new IndexRequest("posts").id("1")
  .source(jsonString, XContentType.JSON); 
IndexResponse response = client.index(request, RequestOptions.DEFAULT);
```

主要参数：

- 索引名称
- 文档id
- 文档数据

文档数据可以通过4种方式传入：

- json字符串

- ```java
  String jsonString = "{\"user\":\"kimchy\"}";
  request.source(jsonString, XContentType.JSON);
  ```

- map对象

  ```java
  Map<String, Object> jsonMap = new HashMap<>();
  request.source(jsonMap); //map内部会自动转为json对象
  ```

- XContentBuilder 构建

- ```java
  XContentBuilder builder = XContentFactory.jsonBuilder();
  builder.startObject();
  {
      builder.field("user", "kimchy");
  }
  builder.endObject();
  request.source(builder); 
  ```

- 直接传值按照k-v处理

- ```java
  request.source("user", "kimchy", "postDate", new Date()); 
  ```

还有一些在构建索引的时候一些可选的参数

```java
request.routing("routing");
。。。。 具体看文档去吧
```

Client.index 提供两种创建索引的方式：同步和异步

- 下面是异步方式

- ```java
  client.indexAsync(request, RequestOptions.DEFAULT, listener); 
  listener = new ActionListener<IndexResponse>() {
      @Override
      public void onResponse(IndexResponse indexResponse) {
      }
      @Override
      public void onFailure(Exception e) {   
      }
  };
  ```

### Get API【获取一个doc】

```java
GetRequest getRequest = new GetRequest("index_name", "doc_id"); 
```

 可选参数

配置source获取，由FetchSourceContext来确定。

```java
//不获取source，默认是enable
request.fetchSourceContext(FetchSourceContext.DO_NOT_FETCH_SOURCE); 
//指定字段获取
String[] includes = Strings.EMPTY_ARRAY; //empty的就不需要管，就当没设置。
String[] excludes = new String[]{"不需要的字段"};
FetchSourceContext fetchSourceContext =
        new FetchSourceContext(true, includes, excludes);
request.fetchSourceContext(fetchSourceContext); 

```







### Exists API

### Delete API

### Update API

### Term Vectors API

### Bulk API

### Multi-Get API

### Reindex API

### Update By Query API

### Delete By Query API

### Rethrottle API

### Multi Term Vectors API

## Doc-api

## Search-api 









