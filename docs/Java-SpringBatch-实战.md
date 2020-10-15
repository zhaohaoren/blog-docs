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

