# MapReduce入门

关于MapReduce只想简单的了解下，因为之所以学习大数据是因为想了解了解Flink，而老旧的MapReduce并不想太深入。





## MapReduce思想



## MapReduce编程

所有的类似于这种MR的编程Schema，基本入门的程序都是WordCount。



### 编程步骤

1.  一个MapReduce程序分为3个部分：Mapper、Reducer和Driver。所以我们最好也创建三个对应的类。

   1. 编写Mapper

      ```java
      public class WordCountMapper extends Mapper<LongWritable, Text, Text, IntWritable> {
      
          private Text k = new Text();
          private IntWritable v = new IntWritable();
      
          /**
           * map方法会将所有的键值对都调用一次
           */
          @Override
          protected void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
              // 这里面的key应该是一些可能的id吧
      
              //mapper过程：获取一行，再分割，然后context写入
              String line = value.toString();
              String[] words = line.split(" ");
              for (String word : words) {
                  k.set(word);
                  v.set(1);
                  context.write(k, v);
              }
          }
      }
      ```

   2. 编写Reducer

      ```java
      public class WordCountReducer extends Reducer<Text, IntWritable, Text, IntWritable> {
      
          private int count = 0;
          private IntWritable v = new IntWritable();
      
          /**
           * @param key 这个key是什么东东？干啥的? todo:
           * @param values： 所有的map计算的结果值
           * @param context
           */
          @Override
          protected void reduce(Text key, Iterable<IntWritable> values, Context context) throws IOException, InterruptedException {
              count = 0;
              for (IntWritable value : values) {
                  count += value.get();
              }
              v.set(count);
              context.write(key, v);
          }
      }
      ```

   3. 编写Driver

      ```java
      public class WordCountDriver {
      
          public static void main(String[] args) throws IOException, ClassNotFoundException, InterruptedException {
              // 1 获取配置信息以及封装任务
              Configuration conf = new Configuration();
              Job job = Job.getInstance(conf);
      
              // 2 设置jar加载路径
              job.setJarByClass(WordCountDriver.class);
      
              // 3 设置map和reduce类
              job.setMapperClass(WordCountMapper.class);
              job.setReducerClass(WordCountReducer.class);
      
              // 4 设置map输出kv类型
              job.setMapOutputKeyClass(Text.class);
              job.setMapOutputValueClass(IntWritable.class);
      
              // 5 设置最终输出kv类型
              job.setOutputKeyClass(Text.class);
              job.setOutputValueClass(IntWritable.class);
      
              // 6 设置输入和输出路径
              FileInputFormat.setInputPaths(job, new Path(args[0]));
              FileOutputFormat.setOutputPath(job, new Path(args[1]));
      
              // 7 提交
              // job.submit(); 不使用
              boolean result = job.waitForCompletion(true);
      
              System.exit(result ? 0 : 1);
          }
      }
      ```

2. 

### 测试运行

#### 本地执行

windows

需要在本地环境配置HADOOP_HOME。PATH=%HADOOP_HOME%/bin

网上找2.x编译的hadoop.dll，winutils.exe两个文件放在bin下面，包还是官方下的包。（亲测可以，如果不信就得自己在windows下编译下hadoop了）





mac&linux



#### 集群执行

打包，不需要依赖包的打包。

```shell
#执行mr
hadoop jar original-map_reduce-1.0-SNAPSHOT.jar top.zhaohaoren.mr.wordcount.WordCountDriver /content /output
#查看结果
hdfs dfs -cat /output/*
```





## MapReduce原理

只看到day05 -02节。 不继续看了，后面再补上。 毕竟我不是想学MapReduce的