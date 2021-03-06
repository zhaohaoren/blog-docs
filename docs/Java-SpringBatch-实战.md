# Spring Batch





![Figure 2.1: Batch Stereotypes](https://docs.spring.io/spring-batch/docs/4.2.x/reference/html/images/spring-batch-reference-model.png)

一个job有一个到多个step，而一个step只会有一个reader，processor和writer。





## Job

JobInstance

JobParameters

## Step

一个job可以包含多个Step

Step 可以 简单 可以 复杂

StepExecution



## ExecutionContext

执行上下文，是一个键/值对的集合，和Quartz的JobDataMap相似。

存储一些状态，防止意外中断执行，用来恢复。



## JobRepository



## JobLauncher



## Item Reader/Writer/Processor

Reader 一次获取一个item交给下游去处理

writer 输出的处理，可以单个一批，也可以按照chunck的方法进行一批处理。

SpringBatch提供了很多这些实现。 如果处理发现 数据不对，应该返回null表示不应该去被write或者下游处理。





## 配置一个Job

```java
@Bean
public Job footballJob() {
    return this.jobBuilderFactory.get("footballJob")
                     .start(playerLoad())
                     .next(gameLoad())
                     .next(playerSummarization())
                     .end()
                     .build();
}
// start next 每一个都代表一个step
```

Job是一个接口，有很多实现。但是我们一般使用jobBuilderFactory来构建job

### job重启

如果一个JobInstance已经存在一个JobExecution，这时候启动一个job认为这个job是一个重启了。

### job监听器



## 配置一个JobRepository



## 配置一个JobLauncher

JobLauncher 通过 JobRepository 创建一个新的 JobExecution 对象 并运行他们。





## 配置一个Step

配置Step有2种方式： 

1. 通过stepBuilderFactory来构建一个step
2. 通过自己实现类的方式来创建一个step

Step 可以很简单，也可以定义的很复杂，取决于用户自己怎么设计。

一个简单的step可以不用写任何代码，比如读文件 写入数据库（使用系统已经提供的内置实现就可以完成）

而一个复杂的step可能有很多的业务逻辑。

### 面向Chunk的Step

![Chunk Oriented Processing](https://docs.spring.io/spring-batch/docs/4.2.x/reference/html/images/chunk-oriented-processing.png)

读一个处理一个，当处理结束的数据达到write的临界值的时候，执行写入。

#### step的监听器



### taskletStep

如果一个step必须要包含一个简单的储存过程的调用。那么这个step可以在reader里面去调用它，而writer就是一个空实现了。对于这种形式的任务特别适合使用taskletStep来操作。

### 





## 运行一个Job





## @StepScope

## @JobScope











# 为什么用SpringBatch?

1. 他没有很强的约束，但是会多很多批处理场景给我们做警醒和指导性意见。比如自己写一个批处理任务，很可能不会考虑到，处理结果批量插入等，使用SpringBatch，这些俗成的api会提示我们这么去做。



































































# 分享







Spring Batch的一些特性

- Transaction management（支持事务）
- Chunk based processing（基于块的处理）
- Declarative I/O（申明式IO） 
  - 内置了一些输入/输出的组件支持，让我们更专注于业务逻辑的开发
- Start/Stop/Restart
  - 支持任务的开始，停止，重启的状态控制
- Retry/Skip
  - 任务重试与跳过
- Web based administration interface (Spring Cloud Data Flow)
  - web操作接口



一些重要的概念

Job  =  类

JobInstance = 对象   是一个逻辑上的概念

JobExecution = 具体执行任务的   每一次尝试运行一个job的时候执行， 这个执行可能成功还可能失败。每次执行都会创建一个Execution。



job就是你定义的任务，jobInstance就是你定义的任务如果是每天定时的，那么每天就还会创建一个实例，JobExecution就是这个实例执行job的执行人



JobParameters  用来区分不同的JobInstance，我们启动一个Job的时候传递不同的参数就可以创建不同的JobInstance





Step 一个Job是多个Step构成的

- tasklet
- chunk-based 一个一个处理，然后一批写出
  - itemReader
  - itemProcessor（可选的）
  - itemWriter

StepExecution 和JobExecution一个概念 每次执行都会创建一个新的StepExecution



ExecutionContext 执行上下文，一个kV集合，可以持久化的

每个JobExection或者StepExecution都至少会有一个ExecutionContext，在Step每次提交或者Job的Step和Step切换的时候会保存持久化





JobLauncher  作业启动器

启动job

JobOperation

封装了JObLauncher，比JobLauncher提供了更多的功能



## Schedule

作业调度





JobParameters

传入kv对作为参数给程序 可以从Execution中获取到参数





JobFlow

一连串的step







优点

在最后一个成功步骤之后重新启动作业

获取作业的信息：例如读取的项目数，提交计数等 .







## 并发

Split

并行执行多个flow 或者step

执行那么没有状态的task

## 决策器

Flow的那些next等逻辑无法满足 流程的转向需求的时候，我们就可以使用自定义决策器



## 监听器

自带了很多listener，从JOb级别到Item级别都有

可以使用注解、实现接口的方式，在之前和之后 写逻辑

# 嵌套job

子job不会自己执行，而是需要parentjob去launch



spring.batch.job.names 指定启动job，让子job不会项目启动就自启动





# 错误处理

Spring Batch 在Job执行过程中发生异常默认会终止这个Job，重启会从上次失败的地方开始执行

### retry重试机制

默认终止job执行，如果想重试的话 使用faultTolerant方法

### Skip 跳过机制

指定跳过的异常，这个异常可以跳过的次数。超过多少次就停止个job

### skip listener 

记录一下跳过的时候，这些错误的item





PPT 

干啥的 原理 怎么用的







再来看虎鲸



先查出期，再查出班 群 

然后 又要一些关联的数据 



- 能遇见的，理代码逻辑会更加的复杂，对于虎鲸这种数据处理来说
- 和写MapReduce的感觉一样，很复杂，



batch是说 因为外部原因或者是数据原因，导致任务失败的重启， 但是虎鲸项目很多都是因为逻辑的原因，就是需要重跑，batch对他没有用处



# 虎鲸问题思考

1. CRM端
2. 数据端







MyBatisPagingItemReader源码分析



整体流程

1. read 会读出一批数据 list(Object) 然后 Object一个个的交给processor执行，再交给writer（这个时候再用chunk做批）
2. 分页读取的Reader 有这么几点：  读了多少数量？  读了 多少数量？  
3. 如何断点续上？ ---》  currentItemCount 的数量会记录下来 ！  除以页码 就知道应该偏移第几页。 取余单页量，就知道应该单页中处理到第几条了。



```java
@Override
protected T doRead() throws Exception {
    synchronized (lock) {
        // 如果读取数据的result缓存为空，或者
        if (results == null || current >= pageSize) {
            if (logger.isDebugEnabled()) {
                logger.debug("Reading page " + getPage());
            }
            // 读一个page
            doReadPage();
            // page编号+1
            page++;
            // 
            if (current >= pageSize) {
                current = 0;
            }
        }
        // 当前的不断后移 每次doRead会从result的list取出一个数据，不断后移  current其实list中的偏移量。
        int next = current++;
        if (next < results.size()) {
            return results.get(next);
        } else {
            return null;
        }
    }
}
```

`doReadPage` 方法其实就是那个抽象类留给我们去实现的钩子方法。 主要作用就是读取list批量数据到 result结果集里面。



我看reader  currentItemCount 就是代表分页阅读的次数啊？？？？

```java
@Override
public T read() throws Exception, UnexpectedInputException, ParseException {
   if (currentItemCount >= maxItemCount) {
      return null;
   }
   currentItemCount++;
   T item = doRead();
   if(item instanceof ItemCountAware) {
      ((ItemCountAware) item).setItemCount(currentItemCount);
   }
   return item;
}
```





```java
@Override
protected void jumpToItem(int itemIndex) throws Exception {
   // itemIndex是 已经读到的item数量
   synchronized (lock) {
      // item 除以单页数量 = 需要开是的 页编号
      page = itemIndex / pageSize;
      // 如果不能整除，的话，current item在一页中的便宜量
     // 对的： 因为最后还是一条一条的处理的， 所以 某条处理可能失败。  
      current = itemIndex % pageSize; 
   }
   // 这里mybatis 是个空实现
   doJumpToPage(itemIndex);
   if (logger.isDebugEnabled()) {
      logger.debug("Jumping to page " + getPage() + " and index " + current);
   }
}
```





Open 方法就是流被打开的时候初始化的方法（我猜的）

```java
@Override
public void open(ExecutionContext executionContext) throws ItemStreamException {
   super.open(executionContext);
   try {
      // 标记一下任务状态为开始
      doOpen();
   }
   catch (Exception e) {
      throw new ItemStreamException("Failed to initialize the reader", e);
   }
   if (!isSaveState()) {
      return;
   }
   
   // 设置最大读取的item数量  超过这个数，就返回null，默认为Intger最大值
   if (executionContext.containsKey(getExecutionContextKey(READ_COUNT_MAX))) {
      maxItemCount = executionContext.getInt(getExecutionContextKey(READ_COUNT_MAX));
   }
   int itemCount = 0;
   // 同上，获取当前reader已经 read的item的数量，如果有就从缓存取出来设置itemCount
   if (executionContext.containsKey(getExecutionContextKey(READ_COUNT))) {
      itemCount = executionContext.getInt(getExecutionContextKey(READ_COUNT));
   }
   else if(currentItemCount > 0) {
      // 如果缓存没有（缓存可能来自于重启），就使用当前的 currentItemCount，表明从来没有放入过数据库？还没有放入缓存？ 一直在内存中操作的
      itemCount = currentItemCount;
   }
   // 如果 已经读取的数据量> 0 并且， 小于最大的数量 表示要断点续上
   if (itemCount > 0 && itemCount < maxItemCount) {
      try {
         // 十分重要的一个方法：   断点续上 主要的逻辑就在这里面了
         jumpToItem(itemCount);
      }
      catch (Exception e) {
         throw new ItemStreamException("Could not move to stored position on restart", e);
      }
   }
   // 到此其实 就是重新设置了下 page 的页码开始位置  和 current 在一页中的偏移量
  // currentItemCount就是代表已经读取的itemCOunt 让这2个相等。 毕竟currentItemCount 这个才是 read过程中 一直被用的 itemCount 只是临时的
   currentItemCount = itemCount;
}
```





![image-20210225181628651](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-SpringBatch-实战/image-20210225181628651.png)