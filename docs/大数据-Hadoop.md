> 只是入门用的，详解后面会单独篇幅出。

# Hadoop-原理篇

Hadoop所提供的服务宏观来讲分为2个大块：HDFS负责数据的存储，YARN负责计算资源的管理调度。

## HDFS相关概念和原理

HDFS全称Hadoop Distributed File System。关于HDFS的相关原理，其实大部分和[GFS](https://juejin.im/post/5f15b440e51d45347e5c8b14)论文里面所提到的那些思想差不多。1

**使用场景**

一次写入，多次读取的场景。

**缺点**

1. 不适合低延时的数据访问，比如毫秒级存储数据。
2. 无法高效的对小文件进行存储。
3. 不支持并发写入、文件的随机修改，只支持文件的追加写。

### HDFS组成架构

HDFS是一个主从架构。一个HDFS集群包括一个NameNode节点和若干个DataNode节点组成。

NameNode相当于集群的Master，只有一个节点，主要用来管理HDFS的一些元数据。

DataNode相当于集群的Salve，通常集群中每个机器都会配置一个该节点。DataNode主要负责数据的存储。

客户端就是我们使用方，可以是我们使用的hdfs的shell，编码中使用的hadoop的包。相当于HDFS为我们封装的API，并为我们屏蔽了一些底层的工作细节。

![HDFS Architecture](D:\workspace\blog-docs\docs\大数据-Hadoop\11.png)

如图（官网图）HDFS工作流程中主要三个参与者：

- 客户端
- NameNode
- DataNode

该图片展示了客户端进行读写操作的时候，和HDFS集群的交互逻辑。

### NameNode工作原理

#### 职责

- 管理HDFS的namespace，即整个文件系统的文件目录树；
- 副本策略配置；
- 数据块的mapping信息，即文件和对应的块之间的映射信息以及文件目录的元信息；
- 处理来自于客户端的读写请求。

NameNode主要的功能是存储管理集群的元数据。

#### 元数据备份：FsImage和edits

NameNode整个HDFS的管理节点，他的核心功能就是存储元数据。这些元数据需要常驻内存中，来保证高效率的访问。

类似于Redis一样，这些元数据需要有有磁盘备份来保证数据的安全性。NameNode通过2个文件：

- FsImage文件：元数据镜像文件。NameNode内存中元数据序列化后形成的文件，存储着某一时段内存中元数据信息。（类似于Redis的RDB）
- Editlog：操作日志文件，记录客户端更新元数据信息的每一步操作，我们可通过Edits推演出元数据。（类似于Redis的AOF）

FsImage因为是镜像文件，这样加载到文件中比较快，但是当内存元数据更新的时候去更新FsImage文件效率很差，所以引入了Edits文件，每当元数据有更新或者添加元数据时，修改内存中的元数据并追加到Edits中。

长时间添加数据到Edits中，会导致该文件数据过大，效率降低，而且一旦断电，恢复元数据需要的时间过长。因此，需要定期将进行FsImage和Edits的合并。我们更新元数据的时候操作的是Editslog，但是当恢复元数据的时候我们希望操作的是FsImage吗，所以需要不断的合并Editslog到FsImage上去。这个合并的过程如果让NameNode做，将十分消耗内存和资源。所以引入了Secondary NameNode来做合并。

#### Secondary NameNode职责

- 辅助NameNode；
- 合并Fsimage和Edits，并推送给NameNode；
- 紧急情况下，辅助恢复NameNode。

Secondary NameNode并不是NameNode一个从节点，他们其实承担不同职责，如果NameNode挂掉，他不能马上顶替上去代替NameNode。

#### 工作机制

**NameNode启动及工作：**

![image-20200727235356246](D:\workspace\blog-docs\docs\大数据-Hadoop\14.png)

0. 如果是第一次启动NameNode，在NameNode格式化的时候会创建fsimage和edits文件。如果不是第一次启动则加载这2个文件到内存。
1. 客户端操作更新元数据；
2. 正在用于被追加的edits文件，名字是edits_inprogress_xxxxx。更新的命令操作会先写入该文件中；（因为Hadoop对文件安全要求很高，所以要先写文件再更新内存）
3. 更新内存中的元数据。

这些文件可以在你指定的NameNode文件存放目录下查看：

```shell
$ tree
├── current
│   ├── edits_0000000000000000001-0000000000000000002
│   ├── edits_0000000000000000003-0000000000000000003
│   ├── ...
│   ├── edits_0000000000000000XXX-0000000000000000XXX # 这些是已经被合并了的，之前旧的edits日志。
│   ├── edits_inprogress_0000000000000000620 # 这个当前滚动的edits日志。
│   ├── fsimage_0000000000000000617 # 第二新的fsimage
│   ├── fsimage_0000000000000000617.md5
│   ├── fsimage_0000000000000000619 # 最新fsimage
│   ├── fsimage_0000000000000000619.md5
│   ├── seen_txid
│   └── VERSION
└── in_use.lock
```

**Secondary NameNode参与合并**

![](D:\workspace\blog-docs\docs\大数据-Hadoop\15.png)



1. Secondary NameNode询问NameNode是否需要CheckPoint。直接带回NameNode是否检查结果。

2. Secondary NameNode请求执行CheckPoint。请求的时机：

   - 设置的定时时间到了。通常情况下，SecondaryNameNode每隔一小时执行一次。

     - 修改该时间：hdfs-site.xml

     - ```xml
       <property>
         <name>dfs.namenode.checkpoint.check.period</name>
         <value>60</value>
       </property >
       ```

   - edits文件大小到指定规模了

     - ```xml
       <property>
         <name>dfs.namenode.checkpoint.txns</name>
         <value>1000000</value>
       </property>
       ```

3. 将当前inprogress的edits文件归档，并创建新的edits_inprogress文件（这里举例edits_inprogress_02）。然后后续客户端的更新操作都更新在edits_inprogress_02中。(旧的edits文件都不会删除，在本地备份着。而fsimage只保留最新的2个版本)

4. 将归档的edits和fsimage拷贝到Secondary NameNode；

5. 将edits和fsimage加载到SecondaryNameNode内存中进行合并；

6. 生成新的fsimage文件：**fsimage.chkpoint**；

7. 将其拷贝回NameNode；

8. 将fsimage.chkpoint重命名为fsimage文件。

#### Tips

**查看fsimage文件**

会生成一个xml文件，里面存储的是元数据信息。

```shell
hdfs oiv -p XML -i fsimage_0000000000000000001
```

**查看edits文件**

也是生成一个xml文件。

```shell
hdfs oev -p XML -i edits_0000000000000000012-0000000000000000013 -o ./edits.xml
```

**NameNode故障处理**

1. 将SecondaryNameNode中数据拷贝到NameNode存储数据的目录。停止并删除原NameNode数据，重启NameNode。
2. 使用-importCheckpoint选项启动NameNode守护进程，从而将SecondaryNameNode中数据拷贝到NameNode目录中。

### DataNode工作原理

#### 职责

- 存储实际的数据块；
- 执行数据块的读写操作。

#### HDFS的块存储

HDFS中文件是按照块来存储的（hadoop叫block，GFS叫一个trunk），可以通过dfs.blocksize来配置。Hadoop2.X中默认为128M，老版本是64M（这和GFS一样）。

- 当上传文件大于128M的时候，文件会被分割为多个块，存储在不同的DataNode上。并且一个DataNode只会存储一个块的数据（即使副本设置了多个，某个DataNode也只会存一个）。
- 当文件小于128M的时候，Hadoop也不会为其进行字节对齐。实际存储的空间就是文件本身的大小。

一个Block块存储在DataNode上包含2个文件，如下：

```shell
blk_1073741825
blk_1073741825_1001.meta
```

- blk_1073741825是数据本身；
- blk_1073741825.meta是块的元数据内容，包括数据长度，校验和，时间戳。

#### 工作机制

![image-20200728010807082](D:\workspace\blog-docs\docs\大数据-Hadoop\16.png)



1. DataNode第一次加入集群，需要先向NameNode注册；

2. 注册成功，NameNode便包含了该DataNode上的元数据信息；

3. 每个DataNode需要周期性的（默认1h）向NameNode上报所有的块信息；

4. 所有的DataNode周期性(默认是3秒)向NameNode发送包含有该节点使用统计的心跳信息，该心跳信息，使NameNode知道可以向DataNode发送命令，如复制、删除等

   - 如果超过10分钟没有收到某个DataNode的心跳，则认为该节点不可用（实际上是10分+30秒）。

   - timeout = 2 * dfs.namenode.heartbeat.recheck-interval + 10 * dfs.heartbeat.interval。

   - 修改hdfs-site.xml 可以调整改时间：

     ```xml
     <property>
         <name>dfs.namenode.heartbeat.recheck-interval</name>
         <value>300000</value>
     </property>
     <property>
         <name> dfs.heartbeat.interval </name>
         <value>3</value>
     </property>
     ```

#### 增加新节点

1. 将hadoop包以及一些相关配置同步到新添加的机器；
2. 在该机器上手动启动NameNode和DataNode；
3. 如果数据不均衡，使用`./start-balancer.sh`实现集群的再平衡。

注意：添加新节点，不需要修改slave文件，只有群起的时候才用slave去找对应的机器上进行启动。我们添加一个节点，我们自己去那个节点上启动DataNode和NameNode 我们就不需要slave。

#### 剔除旧节点

##### 黑名单

我们用黑名单来做旧节点的退役。就是将要剔除的机器名添加到黑名单中。

1. 在某个位置，创建黑名单文件（路径文件名自己指定）。里面填写要加入黑名单的机器。

2. 配置`hdfs-site.xml`；

   ```xml
   <property>
   	<name>dfs.hosts.exclude</name>
   	<value>黑名单文件的路径</value>
   </property>
   ```

3. 刷新NameNode：`hdfs dfsadmin -refreshNodes`；

4. 刷新ResourceManager`yarn rmadmin -refreshNodes`；

5. 打开hadoop的web端，查看机器节点状态为`decommissioned`表明退役成功（这时候该节点数据已经复制其他节点上去，但是该节点还处于挂机状态，我们查看文件存储节点的时候还能查到该节点，属于假死状态）

6. 停止该节点的NameNode和DataNode；

7. 如果数据不均衡，可以用`start-balancer.sh`命令实现集群的再平衡。

**注意：**如果副本数是3，服役的节点小于等于3，是不能退役成功的，需要修改副本数后才能退役。

##### 白名单

白名单不是用来退役的，而是用来维护集群的安全性的。添加到白名单的主机节点，都允许访问NameNode，不在白名单的主机节点，都会被退出。

1. 某个位置创建白名单文件；

2. 配置`hdfs-site.xml`

   ```xml
   <property>
   	<name>dfs.hosts</name>
   	<value>白名单文件路径</value>
   </property>
   ```

3. 分发配置到集群所有节点

4. 刷新NameNode：`hdfs dfsadmin -refreshNodes`

5. 更新ResourceManager节点：`yarn rmadmin -refreshNodes`

6. 如果数据不均衡，可以用start-balancer.sh实现集群的再平衡。

不在白名单的机器会被立刻杀死，不像黑名单那样处于假死状态。

**注意**：不允许白名单和黑名单中同时出现同一个主机名称。

#### Datanode多目录配置

这个主要用于将来我们需要为机器添加新硬盘的时候，可以将该硬盘挂载到一个新的目录下面。

修改`hdfs-site.xml`:

```xml
<property>
	<name>dfs.datanode.data.dir</name>
	<value>file:///${hadoop.tmp.dir}/dfs/data1,file:///${hadoop.tmp.dir}/dfs/data2</value>
</property>
```

#### Tips

**为什么blockSize是128M？**

- 块的大小设置原则：最小化寻址开销。块太小，文件很碎，这样寻址就会很慢！

- 对block的寻址时间在10ms，当寻址时间为block传输时间的1%时认为是最佳状态。所以传输时间最好在1s。

- 目前的磁盘传输速度在100M/s左右。所以设置128M。

所以如果你的磁盘传输速率为200MB/s，可以设定block大小为256M，其他类推。

**为什么blockSize不能太大也不能太小？**

如果太小：

- NameNode是单节点的，内存资源有限，块太小NameNode就需要消耗更多内存存储这些mapping元数据。
- 文件太小也会增加寻址时间，让太多时间花费在寻找block上。

如果太大：

- 主要是上层MapReduce有关，块太大MapReduce处理会不方便；
- 数据块越大，加载的时间越长，处理的时候就会很慢。
- MapReduce中的map任务通常一次只处理一个块中的数据，块太大，则map的数量就会很少。
- 总之就是太大了会影响MapReduce的速度。



### HDFS写入流程

 ![image-20200727170809951](D:\workspace\blog-docs\docs\大数据-Hadoop\12.png)

1. 客户端请求NameNode，申请需要上传文件，告知需要上传文件的一些元信息。
2. NameNode判断是否可以上传，比如该请求路径文件是否存在，是否有权限等。回应客户端是否可上传。
3. 客户端对文件做逻辑切分：128M分割
4. 客户端请求NameNode上传第一个Block（128M以内）
5. NameNode返回给客户端一个DataNode的列表，表示你要存储的DataNode（返回的DataNode取决于你设置的副本数量，以及目前可用且距离客户端最近的DataNode）。
6. 这时候客户端会向离其最近的DataNode（这里是DN1）请求建立数据传输通道，然后DN1向DN2发起，DN2向DN3发起顺次下去，直到请求所有的DataNode。
7. 当最后一个DataNode接受请求后，再不断响应前面的DataNode响应成功，此时通道建立。
8. 客户端开始传输数据到DN1，DN1落盘数据并将数据再传输给DN2，依次传输下去。
9. DN3存储完成返回成功给DN2，DN2在确认DN3返回成功并且自己也落盘成功，才向DN1返回成功，直至全部成功。如果DN2,3失败，则不影响传输HDFS会后面再找2台机器进行备份。
10. 接着同上（4~9）传输第二个Block。
11. 客户端和DataNode数据传输完毕，通知个NameNode，NameNode更新元数据。

### HDFS读取流程

![image-20200727220414469](D:\workspace\blog-docs\docs\大数据-Hadoop\13.png)

1. 客户端请求NameNode申请下载文件；
2. NameNode响应客户端文件是否存在；
3. 客户端请求NameNode下载第一个Block；
4. NameNode返回存储了这个Block的DataNode节点列表；
5. 客户端请求DataNode列表里面第一个DataNode（这里是DN1）进行建立连接通道；
6. DN1返回建立通道成功；
7. 客户端和DN1传输数据。
8. 如果DN1请求失败，则尝试请求DN2，再失败则DN3，以此类推。
9. 客户端继续请求下一个Block，重复3~8；
10. 当所有的Block都传输完成，NameNode通知客户端传输完毕，则文件读取结束。



## YARN相关概念和原理























# Hadoop-配置篇

## Apache版本

打开你对应版本Hadoop的官方文档（这里是https://hadoop.apache.org/docs/r2.10.0/）。本节内容大部分来源于官方文档。

### 安装配置

1. Linux机器若干台（本文使用的是3台Centos7.6）
   1. 集群时间同步NTP（可以不要，但最好需要）。
   
   2. 配置JDK。
   
   3. 配置host。
   
   4. 安装必要软件：`ssh`（群起集群需要），`rsync`（同步集群配置需要）。
   
   5. 测试`$ssh localhost`，如果不成功：
   
       ```shell
       $ ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
       $ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
       $ chmod 0600 ~/.ssh/authorized_keys
       ```
   
2. Hadoop包（本文使用hadoop-2.10.0.tar.gz）

   1. 配置 `etc/hadoop/hadoop-env.sh`。（官方已经配置了`export JAVA_HOME=${JAVA_HOME}`，也需要替换，Hadoop在启动时候貌似无法加载系统配置的环境变量）

   2. 配置HADOOP_HOME（非必须，方便操作）

   3. ```shell
      export HADOOP_HOME=/home/justin/env/hadoop-2.10.0
      export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
      ```
      
   
3. 至此Hadoop的配置算是完成了（但是还没有启动），可以使用hadoop命令测试下：

```shell
[justin@hadoop01]$ hadoop
Usage: hadoop [--config confdir] [COMMAND | CLASSNAME]
  CLASSNAME            run the class named CLASSNAME
 or
  where COMMAND is one of:
  fs                   run a generic filesystem user client
....
```

### 启动Hadoop

Hadoop有三种启动模式：

- 单进程模式：Local (Standalone) Mode
- 伪分布式：Pseudo-Distributed Mode
- 完全分布式：Fully-Distributed Mode

#### 单进程模式

> 只起一个Hadoop节点，该部署方式一般用来debugging自己要部署到集群的程序。

该模式不需要其他配置，相当于配置好了环境用来执行写好的jar包。我们可以使用官方给的例子看环境是否OK?

##### 验证

```shell
$ mkdir input
$ cp etc/hadoop/*.xml input
$ bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.10.0.jar grep input output 'dfs[a-z.]+'
$ cat output/*
//执行正常说明基本环境OK
```

#### 伪分布式

> 在单机上启动Hadoop的相关后台服务，每个服务都在独立的进程中。

##### 配置HDFS

- 配置 etc/hadoop/core-site.xml

  - ```xml
    <!-- 配置HDFS中NameNode的地址 -->
    <property>
    	<name>fs.defaultFS</name>
    	<value>hdfs://hadoop01:9000</value>
    </property>
    <!-- 默认Hadoop执行的文件都会在系统tmp文件夹，这样在重启后就没了。需要重新指定文件夹 -->
    <property>
    	<name>hadoop.tmp.dir</name>
    	<value>/data/my/tmp</value>
    </property>
    ```
    
  - 具体有哪些配置可以查下：[core-default.xml](https://hadoop.apache.org/docs/r2.10.0/hadoop-project-dist/hadoop-common/core-default.xml)

- 配置 etc/hadoop/hdfs-site.xml

  - ```xml
    <!-- 指定HDFS副本的数量 -->
    <property>
    	<name>dfs.replication</name>
    	<value>1</value>
    </property>
    ```

  - 具体有哪些配置可以查下：[hdfs-default.xml](https://hadoop.apache.org/docs/r2.10.0/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml)

- 格式化NameNode（只在第一次启动时执行，后面不用格式化了）

  - ```shell
    $ bin/hdfs namenode -format
    ```

  - > 格式化NameNode，会产生新的集群id。导致NameNode和DataNode的集群id不一致，集群找不到已往数据。所以，格式NameNode时，一定要先删除data数据和log日志，然后再格式化NameNode。

- 启动NameNode&DataNode

  - ```shell
    $ sbin/start-dfs.sh
    // 也可以分开启动
    $ sbin/hadoop-daemon.sh start namenode
    $ sbin/hadoop-daemon.sh start datanode
    ```

- 停止

  - ```shell
    $ sbin/stop-dfs.sh
    ```

##### 验证HDFS

如果过程中发现namenode或者datanode启动失败，去logs文件夹下查看日志。

2种方式：

1. ```shell
   [justin@hadoop01]$ jps
   4899 DataNode
   5316 Jps
   5096 SecondaryNameNode
   4783 NameNode
   ```

2. 浏览器访问 http://hadoop01:50070/

![image-20200724011602972](D:\workspace\blog-docs\docs\大数据-Hadoop\01.png)

3. 直接使用HDFS来跑mapreduce例子测试

```shell
//上传测试文件到创建的input文件夹中,路径自定义
$ bin/hdfs dfs -mkdir /user
$ bin/hdfs dfs -mkdir /user/justin #只能这么一步步来
$ bin/hdfs dfs -mkdir /user/justin/input
$ bin/hdfs dfs -put etc/hadoop/*.xml /user/justin/input
//执行官方案例mr程序，output必须不存在
$ bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.10.0.jar grep /user/justin/input /user/justin/output 'dfs[a-z.]+'
//查看结果
$ bin/hdfs dfs -cat /user/justin/output/*
//删除结果
$ hdfs dfs -rm -r /user/justin/output
```

##### 配置YARN

1. 配置 etc/hadoop/mapred-site.xml（复制一份mapred-site.xml.template）

   ```xml
   <!-- 指定MR程序运行在YARN上 -->
   <property>
   	<name>mapreduce.framework.name</name>
   	<value>yarn</value>
   </property>
   ```
   
   - 具体有哪些配置可以查下：[mapred-default.xml](https://hadoop.apache.org/docs/r2.10.0/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml)

2. 配置 etc/hadoop/yarn-site.xml
   
   ```xml
   <!-- Reducer获取数据的方式 -->
   <property>
       <name>yarn.nodemanager.aux-services</name>
       <value>mapreduce_shuffle</value>
   </property>
   <!-- 指定YARN的ResourceManager的地址 -->
   <property>
 	<name>yarn.resourcemanager.hostname</name>
   	<value>hadoop01</value>
   </property>
   ```
   
   - 具体有哪些配置可以查下：[yarn-default.xml](https://hadoop.apache.org/docs/r2.10.0/hadoop-yarn/hadoop-yarn-common/yarn-default.xml)
   
3. 启动ResourceManager&NodeManager（必须保证NameNode和DataNode已经启动）

   - ```shell
     $ sbin/start-yarn.sh
     //或者分开启动
     $ sbin/yarn-daemon.sh start resourcemanager
     $ sbin/yarn-daemon.sh start nodemanager
     ```

4. 停止

   - ```shell
     $ sbin/stop-yarn.sh
     ```

##### 验证YARN

1. ```shell
   [justin@hadoop01]$ jps
   4899 DataNode
   6150 Jps
   5096 SecondaryNameNode
   5897 ResourceManager
   4783 NameNode
   5999 NodeManager
   ```

2. http://hadoop01:8088/cluster

![image-20200724015051779](D:\workspace\blog-docs\docs\大数据-Hadoop\02.png)

3. 使用YARN来跑mapreduce例子测试（执行上面MR一样的例子）

![image-20200724020618168](D:\workspace\blog-docs\docs\大数据-Hadoop\03.png)

4. 执行结果可以用命令行也可以使用浏览器查看。

#### 配置JobHistory

上面东西配妥当了，还存在一个问题：

![image-20200724121824866](D:\workspace\blog-docs\docs\大数据-Hadoop\04.png)

上面那个History是打不开的，因为还需要配置我们的`JobHistory`服务。

1. 配置 etc/hadoop/mapred-site.xml

   这里具体的IP地址可以随意指定（最好找相对空闲机器），但指定哪个IP地址的时候到时候就要到哪个机器上启动`JobHistory`，否则会启动失败！

   ```xml
   <!-- jobhistory服务地址 -->
   <property>
       <name>mapreduce.jobhistory.address</name>
       <value>hadoop01:10020</value>
   </property>
   <!-- jobhistory的web地址 -->
   <property>
       <name>mapreduce.jobhistory.webapp.address</name>
       <value>hadoop01:19888</value>
   </property>
   <!-- MR作业运行完了之后放在HDFS的路径 -->
   <property>
       <name>mapreduce.jobhistory.done-dir</name>
       <value>/history/done</value>
   </property>
   <!-- MR运行中的临时文件存放路径 -->
   <property>
       <name>mapreduce.jobhistory.intermediate-done-dir</name>
       <value>/history/done_intermediate</value>
   </property>
   ```

2. 重启yarn
 ```shell
$ sbin/stop-yarn.sh
$ sbin/start-yarn.sh
 ```
3. 启动`JobHistory`服务
 ```shell
$ sbin/mr-jobhistory-daemon.sh start historyserver
 ```


4. 查看 http://hadoop01:19888/jobhistory
5. 执行MapReduce任务，点击History验证（如果无法打开，查看下URL的域名的是否正确，去配下host）

#### 配置日志的聚集

日志服务器配置完成了，这时候点击某个Job的History面板里面查看logs的时候会报错：

```
Aggregation is not enabled. Try the nodemanager at hadoop01:27695
Or see application log at http://hadoop01:27695/node/application/application_1595579336183_0002
```

这个需要我们开启日志聚集，来方便我们查看程序运行详情，从而方便开发调试。

1. 配置 yarn-site.xml

   ```xml
   <!-- 日志聚集功能使能 -->
   <property>
   	<name>yarn.log-aggregation-enable</name>
   	<value>true</value>
   </property>
   <!-- 日志保留时间设置7天 -->
   <property>
   	<name>yarn.log-aggregation.retain-seconds</name>
   	<value>604800</value>
   </property>
   ```

2. 需要重启yarn和History服务。

#### 完全分布式

> 真正的集群，我们要将Hadoop的NameNode和DataNode部署在不同的机器上面。

配置前需要先规划好如果分布这些服务节点，本文例子：

|      | hadoop01           | hadoop02                     | hadoop03                    |
| ---- | ------------------ | ---------------------------- | --------------------------- |
| HDFS | NameNode、DataNode | DataNode                     | SecondaryNameNode、DataNode |
| YARN | NodeManager        | ResourceManager、NodeManager | NodeManager                 |

**尽量将节点分布均匀，不要堆积在某个机器上。DataNode和NodeManager默认都会在每台机器上配置一个分别管理Data和CPU。**

> 集群在启动的时候需要ssh联通，所以配置前确保（建议）三台机器hadoop01，hadoop02，hadoop03 以hadoop01为主可以SSH登录其他机器。
>
> 并且启动前都ssh登录一下：
> Are you sure you want to continue connecting (yes/no)?  确认下yes
>
> 我们ResourceManager配置在hadoop02上，那么也要求hadoop02可以ssh其他2个机器。
>
> 为了方便直接让3台机器互相联通就好了。

1. 先在hadoop01上将基本环境都配置好，具体过程参考伪分布式。

   1. `hadoop-env.sh`设置 `JAVA_HOME`。我测试情况是其他的`xxxx-env.sh`不设置`JAVA_HOME`都没有问题。

   2. core-site.xml

      ```xml
      <!-- 指定HDFS中NameNode的位置，这里指定Hadoop01 -->
      <property>
      	<name>fs.defaultFS</name>
      	<value>hdfs://hadoop01:9000</value>
      </property>
      <!--可选项目-->
      <!-- hdfs-site也会配置name和data就不需要这个了 -->
      <property>
      	<name>hadoop.tmp.dir</name>
      	<value>/data/my/tmp</value>
      </property>
      ```

   3. hdfs-site.xml

      ```xml
      <!-- 设置secondarynamenode的http通讯地址 -->
      <property>
      	<name>dfs.namenode.secondary.http-address</name>
      	<value>hadoop03:50090</value>
      </property>
      <!-- 设置namenode存放的路径 -->
      <property>
      	<name>dfs.namenode.name.dir</name>
      	<value>/home/justin/env/hadoop-2.10.0/tmp_dfs/name</value>
      </property>
      <!-- 设置datanode存放的路径 -->
      <property>
      	<name>dfs.datanode.data.dir</name>
      	<value>/home/justin/env/hadoop-2.10.0/tmp_dfs/data</value>
      </property>
      <!--可选项目-->
      <!-- 设置hdfs副本数量,因为默认是3所以可以省略 -->
      <property>
      	<name>dfs.replication</name>
      	<value>3</value>
      </property>
      ```

   4. yarn-site.xml

      ```xml
      <!-- reducer取数据的方式是mapreduce_shuffle -->
      <property>
      	<name>yarn.nodemanager.aux-services</name>
      	<value>mapreduce_shuffle</value>
      </property>
      <!-- 指定ResourceManager在哪个机器上 -->
      <property>
      	<name>yarn.resourcemanager.hostname</name>
      	<value>hadoop02</value>
      </property>
      <!-- 日志聚集功能使能 -->
      <property>
      	<name>yarn.log-aggregation-enable</name>
      	<value>true</value>
      </property>
      <!-- 日志保留时间设置7天 -->
      <property>
      	<name>yarn.log-aggregation.retain-seconds</name>
      	<value>604800</value>
      </property>
      ```

   5. mapred-site.xml

      ```xml
      <!--只是配置在yarn上运行MapReduce-->
      <property>
      	<name>mapreduce.framework.name</name>
      	<value>yarn</value>
      </property>
      <!-- jobhistory服务地址 -->
      <property>
          <name>mapreduce.jobhistory.address</name>
          <value>hadoop01:10020</value>
      </property>
      <!-- jobhistory的web地址 -->
      <property>
          <name>mapreduce.jobhistory.webapp.address</name>
          <value>hadoop01:19888</value>
      </property>
      <!-- MR作业运行完了之后放在HDFS的路径 -->
      <property>
          <name>mapreduce.jobhistory.done-dir</name>
          <value>/history/done</value>
      </property>
      <!-- MR运行中的临时文件存放路径 -->
      <property>
          <name>mapreduce.jobhistory.intermediate-done-dir</name>
          <value>/history/done_intermediate</value>
      </property>
      ```

   6. 配置salve：`vim etc/hadoop/slaves`。配置slave的目的，主要在群起集群的时候知道起哪些节点的Hadoop。

      ```properties
      hadoop01
      hadoop02
      hadoop03
      ```

2. 然后拷贝到其他的机器上去。

   ```shell
   scp -r /home/justin/env  justin@hadoop02:/home/justin/
   scp -r /home/justin/env  justin@hadoop03:/home/justin/
   # 或者使用xsync进行同步
   rsync -av /home/justin/env/hadoop-2.10.0/ hadoop0X:/home/justin/env/hadoop-2.10.0/
   ```

3. 如果第一次启动该集群，格式化NameNode（格式化之前清空之前生成的文件，tmp和logs里面的）

   ```shell
   bin/hdfs namenode -format
   ```

4. 群起集群

   > 注意：NameNode和ResourceManger如果不是同一台机器，不能在NameNode上启动 YARN，应该在ResouceManager所在的机器上启动YARN。

   ```shell
   # 因为我们 NameNode指定的hadoop01，ResourceManager指定在hadoop02上
   hadoop01: start-dfs.sh
   hadoop02: start-yarn.sh
   # 如果你NameNode和ResourceManger都指定在hadoop01上，则可以使用。不然ResourceManger会启动失败
   start-all.sh
   ```
   
5. 到对应的机器上启动`JobHistory`服务。

   ```shell
   $ sbin/mr-jobhistory-daemon.sh start historyserver
   ```

##### 验证

和规划的分布一毛一样：

```
[justin@hadoop01]$ jps
32176 Jps
32033 NodeManager
31064 NameNode
31208 DataNode

[justin@hadoop02]$ jps
10899 ResourceManager
11012 NodeManager
8581 DataNode
11421 Jps

[justin@hadoop03]$ jps
24960 DataNode
25953 NodeManager
25082 SecondaryNameNode
26124 Jps
```

浏览器访问：

http://hadoop01:50070/ （使用NameNode的IP）

![image-20200724163216698](D:\workspace\blog-docs\docs\大数据-Hadoop\05.png)

http://hadoop02:8088/cluster （使用ResourceManager的IP）

![image-20200724163257355](D:\workspace\blog-docs\docs\大数据-Hadoop\06.png)

http://hadoop03:50090/status.html （查看SecondaryNameNode）

![image-20200724165217367](D:\workspace\blog-docs\docs\大数据-Hadoop\07.png)

如果页面是空的，修改`share/hadoop/hdfs/webapps/static/dfs-dust.js` 第61行如下。然后rsync一下所有机器该文件，重启hdfs。清空缓存并刷新下。

```js
'date_tostring' : function (v) {
    //return moment(Number(v)).format('ddd MMM DD HH:mm:ss ZZ YYYY');
    return new Date(Number(v)).toLocaleString();
},
```



# Hadoop-使用篇

## Shell命令

一些常用命令：`hadoop fs` 和 `hdfs dfs` 是一样的。

### **最重要的命令**

帮助命令

```shell
hadoop fs -help CMD
```

### **文件上传命令**

从本地文件系统中拷贝文件到HDFS路径去

```shell 
hadoop fs -copyFromLocal README.txt /
#-put：等同于copyFromLocal
hadoop fs -put README.txt /
```

本地剪切到HDFS

```shell
hadoop fs  -moveFromLocal  ./file  /hdfs/path
```

追加一个本地文件到已经存在的HDFS文件末尾

```shell
 hadoop fs -appendToFile file2 /hdfs/file1
```

### **HDFS内部操作命令**

显示目录信息

```shell
hadoop fs -cat /
```

显示一个文件的末尾

```shell
hadoop fs -tail /hdfs/file
```

在HDFS上创建目录

```shell
hadoop fs -mkdir -p /home/justin
```

移动文件

```shell
hadoop fs -mv /hdfs/path1/file /hdfs/path2/
```

拷贝到HDFS的另一个路径

```shell
hadoop fs -cp /hdfs/path1/file /hdfs/path2/file2
```

删除文件或文件夹

```shell
hadoop fs -rm /hdfs/file
```

删除空目录

```shell
hadoop fs -rmdir /test
```

修改文件所属权限

```shell
hadoop fs  -chmod  666  /justin/file.txt
hadoop fs  -chown  justin:justin  /justin/file.txt
```

统计文件夹的大小信息

```shell
hadoop fs -du -s -h /hdfs/path
```

### 文件下载命令

从HDFS拷贝到本地

```shell
hadoop fs -copyToLocal /hdfs/file /local
```

等同于copyToLocal

```shell
hadoop fs -get  /hdfs/file /local
```

合并下载多个文件，比如HDFS的目录下有多个文件:log.1, log.2,log.3,...

```shell
hadoop fs -getmerge /hdfs/path/* ./merge.txt
```

### 集群相关

启动Hadoop集群

```shell
sbin/start-dfs.sh
sbin/start-yarn.sh
```

设置HDFS中文件的副本数量

```shell
hadoop fs -setrep 10 /hdfs/file
```



## Java API











待融合：

https://www.cnblogs.com/sky-chen/p/11346879.html

