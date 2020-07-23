---
title: 【PaperReading】MapReduce（个人翻译）
date: 2020-05-10 01:06:26
tags:
---

> Google三驾马车的第二篇论文，最先发表于2004年OSDI（操作系统领域的顶会）上。也是大数据最重要的一个数据处理方案。

## MapReduce: Simplified Data Processing on Large Clusters

Jeffrey Dean and Sanjay Ghemawat

## 摘要（Abstract）

MapReduce准确的来说应该是一个编程模型，或者说是一个用来处理和生产大量数据集的相关实现。用户通过指定一个map函数来处理一个K/V键值对，这个键值对会被map生成一系列的中间键值对集。通过reduce函数，我们再将那些相同的中间key所关联的value值合并。这篇论文会展示在该模型下的一些真实场景下的任务。

那些用函数式的编写的程序会被自动的，并行的执行在一个很大的集群上。这个运行时系统会自己处理好如何分割输入的数据，程序执行资源的调度，机器失败的处理，管理必要的机器间的通信等这些细节问题。这让那些没有任何并行计算和分布式系统工作经验的程序员可以轻松的利用好一个很大的分布式系统的资源。

我们的集群是高度可扩展的：一个典型的MapReduce程序可以在上千台机器上来处理TB级的数据。程序员会觉得这个系统非常好用：在Google的每天都有数百个MapReduce程序被实现，并且上千个MapReduce任务运行在集群上。

## 1. 简介（Introduction）

在过去的五年中，作者和许多Google的其他人已经实现了数百个用于特殊目的的计算：这些计算来处理大量原始数据，如爬虫抓取的文档，Web请求日志等，从而计算各种衍生的数据，例如倒排索引，Web文档的各种分析图像表示，每个主机爬取的页面数的结果汇总，在给定日期中最频繁请求的集合等。大多数此类计算从概念上讲是很直接。但是，输入数据量通常很大，为了在合理的时间内完成，这些计算必须分布在数百或数千台机器上。如何并行化计算，数据分布以及故障处理这些问题需要大量复杂的代码来处理他，这就让原来的简单的计算不那么容易了。

为了应对这种复杂性，我们设计了一个新的抽象，它允许我们只需要表达我想要执行的最简单的计算，但是隐藏了底层中对计算并行化，容错，数据分发和负载均衡的复杂的实现细节。这种抽象的灵感来自于Lisp和许多其他函数语言中的map和reduce原语。我们意识到，大部分我们的计算都涉及到使用map操作来作用于输入数据中每一个逻辑上的“记录”来生成一些列中间临时的kv键值对，然后我们在对这些键值对中相同key的值做reduce操作来适当的组合出派生数据。使用一个由用户来指定的map和reduce操作的这样一个函数式模型，让我们可以容易的并行化处理大型计算并可以使用重新执行来作为主要容错机制。

我们这项工作的主要贡献点是提供了简单而强大的接口，可以让大规模计算的自动并行化和分发，并通过此接口的实现，可以在大量的商用PC集群上获取高性能。

本文第2节描述了基本的编程模型，并给出了几个例子。第3节描述了一个针对基于群集的计算环境定制的MapReduce接口的实现。第4节描述了几个我们发现比较有用的编程模型。第5节使用各种任务的对我们的实现进行性能测试。第6节探讨了MapReduce在Google中的使用，包括我们使用它来重写生产索引系统的经验。第7节讨论相关以及未来的工作。

## 2. 编程模型（Programming Model）

计算通过输入一系列键值对，然后生成一些列键值对。MapReduce库的使用者将计算的表示为2种函数：Map和Reduce。

Map，由用户编写通过输入的键值对来生成新的一系列中间键值对。MapReduce库会将有相同中间Key：`I`的中间value全部都分组在一起，并将它们传递给Reduce函数。

Reduce函数也是由用户编写。它接受一个中间Key：`I`以及该key对应的一系列的的值。它会合并这些值的集合并大可能生成更小的集合。通常每次reduce调用后都只生成0个或者1个输出结果。这些中间值会通过迭代器提供给用户的reduce函数。这就可以使得我们处理那些太大而无法全部存储在内存中的值列表。

### 2.1 例子（Example）

思考下计算大量文档中每个单词出现次数的问题。用户可能会编写类似于以下伪代码的代码：

```pseudocode
map(String key, String value):
// key: document name
// value: document contents
for each word w in value:
EmitIntermediate(w, "1");

reduce(String key, Iterator values):
// key: a word
// values: a list of counts
int result = 0;
for each v in values:
result += ParseInt(v);
Emit(AsString(result));
```

map函数将每个单词都加上一个关联数：该词出现的次数（这个简单的例子中就是1）。reduce函数将给定的单词的所有计数结果汇众求和。

此外，用户使用输入和输出文件名称以及一些可选的调参来编写的代码将数据写入MapReduce约定的对象中，然后用户就可以直接调用MapReduce的方法，并将上面生成好的特定对象传给MapReduce。这样用户的代码和MapReduce库（C++实现的）就可以连接起来了。附录A包含此示例的完整程序。

### 2.2 类型（Types）

尽管先前的伪代码是根据输入和输出都是以字符串类型进行编写的，但从概念上讲，用户提供的map和reduce函数的有下面的类型关联：

```pseudocode
map (k1,v1) → list(k2,v2)
reduce (k2,list(v2)) → list(v2)
```

也就是说，输入的keys和values和输出的keys和values的值不是同一个域【这里没太翻译明白】【就是说k2和v2和k1，v1不是同一个域？】。此外，中间的keys和values和结果的keys和values是属于同一个域。【v2】

我们C++实现的是使用字符串来和用户定义函数进行交互的，字符串转换为用户自己想要的类型是交给用户自己的代码去转换的。

### 2.3 更多例子（More Examples）

这里有一些有趣程序的简单示例，可以很容易地表现MapReduce计算。

**分布式的grep**：如果一行数据匹配所给定的模式map函数就会将改行发出来，然后reduce函数是一个标识函数只负责将中间的数据拷贝到结果输出。

**计算URL访问频率**：map函数处理web网页的请求日志并输出{URL,1}。然后reduce函数对一样的URL的值相加，并发出{URL,总和}的键值对。

**反转Web链接图**：map函数将一个页面中所有能找到的叫source的链接和它的目标URL输出成{target，source}。然后reduce函数对相同target的source们聚合然后发出这个新的键值对{target, list(source)}。

**每个主机的Term-向量**：【这里的term是搜索的概念，term就是一句话中的词组的意思】Term-向量是一个{word, frequency}键值对的一个列表，它总结了一个文档或者一组文档里面出现的最重要的单词。map函数对每个输入文档（其主机名是从文档的URL中抽取出来的）处理为{hostname, term vector}并发  出去。reduce函数传递一个主机所有文档的term-向量，然后将这些向量累加起来，丢弃不常用的term，最后发出{hostname, term vector}键值对。

**倒排索引**：map函数解析每个文档，并发出一系列{word, 文档ID}的键值对，reduce函数会对一个给定的单词接受所有的键值对，然后对该单词的  文档ID进行排序并发出{word, list(文档ID)}的键值对。所有输出的键值对集合就形成了一个简单的倒排索引。通过增加这个计算来跟踪单词的位置是很容易的。

**分布式排序**：map函数从每个记录中提取key，并发出{key，记录}这个键值对。 reduce函数会不做修改的发送所有的键值对。此计算要依赖第4.1节中描述的分区工具和第4.2节中描述的排序属性。

## 3 实现（Implementation）

MapReduce接口的可以有很多不同的实现。正确的选择取决于环境。例如，一种实现方式可能适用于小型共享存储器机器，另一种实现方式适用于大型NUMA多处理器，而另一种实现方式适用于甚至更大的联网机器集。

本节描述了一个在Google被广泛使用的计算环境的实现：一天用交换式以太网连接在一起的大型商用PC集群[4]。在我们的环境中：

（1）一般机器都是运行了Linux系统的双处理器x86处理器，每台机器有2-4 GB的内存。

（2）使用商用网络硬件 - 一般在单机器级别上为100M/秒或1G/秒，但在整体上带宽的平均值来要比这个带宽中位数要少得多。

（3）集群由数百或数千台机器组成，因此机器故障很常见。

（4）存储由廉价的直连在各个机器上的IDE磁盘提供。内部开发的分布式文件系统[8]用于管理存储在这些磁盘上的数据。文件系统通过复制在不可靠的硬件之上提供可用性和可靠性。

（5）用户将作业提交给调度系统。每个作业由一组任务组成，并由调度程序映射到集群中的一组可用计算机。

### 3.1 执行概述（Execution Overview）

Map函数的调用将被分布在多太机器上来自动将输入的数据分割为M份。这些被分割的输入可以在不同的机器上被并行处理。Reduce函数的调用也会被分布在多台机子上，它通过一个分区函数（比如hash(key) mod R）将map中生成的临时key来分片为R个片段。分区数量（R）以及分区函数由用户来指定。

图1显示了我们实现中MapReduce操作的总体流程。当用户程序调用MapReduce函数时，会发生以下一系列操作（图1中的编号标签对应于下面列表中的数字）：

![image-20200425145657218](:paper-mapreduce/image-20200425145657218.png)

1. 用户程序中的MapReduce库首先将输入文件分成每块通常16M到64MB的M个块（这个可由用户通过可选参数控制）。然后，MapReduce会在一组计算机上启动该程序的许多副本【fork的过程】。
2. 该程序的其中一个副本是特殊的-master。其余都是由主人分配工作的worker。有M个map任务和R个reduce任务要分配。master会挑选闲置的worker并为每个人分配一个map任务或reduce任务。
3. 被分配了Map任务的worker要读取相应的被拆分的输入块的内容。它从输入数据中解析出键/值对，并将该键值对传递给用户定义的Map函数。Map函数生成的中间键/值对是缓存在内存中的。

4. 周期性地，缓存的键值对会被写入本地磁盘，通过分区函数将数据划分为R个区域。这些被缓存的数据序列化到本地磁盘上这的磁盘位置将传回给master，master再负责将这些位置转发给reduce的workers。

5. 当主服务器通知reduce workers这些位置时，它使用远程过程调用（RPC）从map的workers的本地磁盘读取缓冲数据。当reduce工作者读取了所有中间数据时，它会通过键来对这些数据进行排序，以便将所有出现的相同键组合在一起。之所以需要排序，因为通常很多不同的键都被映射到同一个reduce任务上。如果中间数据量太大而无法全存储在内存中，则使用外部排序。

6. reduce的worker对已排序的中间数据进行迭代，并且对于每个遇到的唯一key，它将key相应的中间value值集合传递给用户的Reduce函数。Reduce函数的输出结果被附加到这部分reduce分区上的一个最终输出文件上去。

7. 当完成所有map任务和reduce任务后，master会唤醒用户程序。此时，用户程序中的MapReduce调用会return返回到用户代码中。

成功完成后，MapReduce的执行结果就在那R个输出文件中（每个reduce任务一个，文件名由用户指定）。通常，用户不需要将这R个输出文件合并成一个文件，它们通常将这些文件作为输入传递给另一个MapReduce过程的调用，或者从另一个能够处理被分区为多个文件的来作为输入的分布式应用程序中使用它们。

### 3.2 Master的数据结构（Master Data Structures）

master拥有几中数据结构。对于每个map任务和reduce任务，它存储他们的状态（空闲，正在进行或已完成）以及正在工作机器的标识（用于非空闲任务）。

master是将这些文件区域的位置从map任务传播到reduce任务的管道。因此，对每一个完成的map任务，master会存储这些由map任务生成的R个中间文件块的位置和大小。当map任务完成是，这些文件位置和大小的变更也会被master接受。信息将逐步推送给正在进行reduce任务的workers。

### 3.3 容错（Fault Tolerance）

由于MapReduce库旨在帮助使用数百或数千台计算机处理大量数据，因此程序库必须能够优雅地容忍计算机故障。

#### Worker失败

master会周期性的ping每个worker。如果在一个指定的时间范围内没有收到worker响应，master将把这个worker节点标记为失效。所有由这个失效的worker完成的Map任务被设回到初始的空闲状态，这样这些任务才能再被安排给其他的worker。同样的，失效worker上正在运行的Map或Reduce任务也将被重新置为空闲状态，等待重新调度。

当worker故障时，之所以要重新执行已经完成的map任务是因为这些任务的输出都存储在这台机器上，因此这些输出变成不可访问的了。已经完成的Reduce任务的输出存储在全局文件系统上【类似于GFS这样的系统上，是安全的】，因此不需要再次执行。

当一个Map任务先被worker A执行，之后又被调度到worker B执行（因为worker A失效了），这个重新执行的动作会被通知给所有执行Reduce任务的workers。任何还没有从worker A读取数据的Reduce任务将改为从worker B读取数据。

MapReduce可以适应大规模worker失效的情况。比如，在一个MapReduce操作中，在一个正在运行的集群上进行网络维护导致了80台机器在同一时间几分钟内无法访问了，MapReduce的master简单的再次执行下那些不可访问的worker已经完成的工作，之后继续向前执行，最终来完成这个MapReduce操作。

#### Master失败

master可以很容易的周期性的讲上面所描述的数据结构【master存储的那些信息】写入磁盘生成checkpoint检查点。如果master任务挂了，可以从最新的一个checkpoint来启动一个新的副本master进程。然而，鉴于只有一个master进程，master失败的可能性不大【这里笔误吧？"its failure is unlikely"应该表达的意思是如果master失败的结果是难以想象的】；因此我们当前的实现中如果master失效，就中止MapReduce计算。客户端可以检查此状态，并根据需要重新执行MapReduce操作。

#### 存在失败的语义【这段没怎么明白标题什么意思，这一段都不太明白】

当用户提供的Map和Reduce算子是输入值确定的函数时，我们的分布式实现下的输出结果和整个程序没有任何错误并顺序执行产生的输出结果是一样的。【同样的输入应该同样的输出】

我们靠原子提交Map和Reduce任务的输出来完成这个特性。每个执行中的任务把它的输出写到私有临时文件中。一个Reduce任务会生成一个这样的文件，而一个Map任务则会生成R个这样的文件（每个Reduce任务对应一个）。当一个Map任务完成的时，worker发送一个包含了R个临时文件名的消息给master。如果master从一个已经完成的Map任务再次接收到到一个完成消息，master直接忽略这个消息；否则，master将这R个文件的名称记录在起一个数据结构中。

当reduce任务完成时，reduce worker会原子的把临时输出文件重命名为最终的输出文件。如果同一个Reduce任务在多台机器上执行，多个重命名操作会作用在同一个最终的输出文件上。我们依赖底层文件系统提供的原子性重命名操作的来保证最终的文件系统状态只是一个reduce任务产生的数据。

绝大多数的Map和Reduce**算子**【感觉这个翻译更好】是确定性的，以及在这种情况下我们在语义上和顺序执行情况下是等同的这样一个事实，让程序员们很容易推断他们程序的行为。当Map和/或Reduce算子是不确定性的时候，我们提供虽然弱但是依然合理的处理机制。当使用非确定算子情况下，一个特定reduce任务R1的输出和一个非确定性程序顺序执行产生时的输出是等价的。但是，另一个Reduce任务R2的输出也许对应着一个不同的非确定顺序程序执行产生的R2的输出。

考虑Map任务M和Reduce任务R1、R2的情况。设e(Ri)为Ri已经提交的执行（有且只有一个这样的执行）。较弱的语义会在当e(R1)读取了由M一次执行产生的输出，而e(R2)读取了由M的另一次执行产生的输出时出现。

### 3.4 存储位置（Locality）

在我们的计算环境中网络带宽是一个相对稀缺的资源。我们通过尽量把输入数据(由GFS管理)存储在集群中机器的本地磁盘上来节省网络带宽。GFS将每个文件分割为64MB的小块，每个块有多个副本（一般是3个拷贝）保存在多台机器上。MapReduce的master在准备调度map任务时会考虑到输入文件的位置信息，尽量在存储了输入数据备份的机器上执行map任务；如果上面没有成功【比如存储的那个机器无法分配任务】，master将尝试在靠近有输入数据备份的机器上执行Map任务(例如，在一个和含有输入数据的机器在一个交换机里的worker机器上执行)。当在一个足够大的cluster集群上运行大型MapReduce操作的时候，大部分的输入数据都能从本地机器读取，因此基本不会消耗网络带宽。

### 3.5 任务粒度（Task Granularity）

如上所述，我们把map拆分成了M个片段、把Reduce拆分成R个片段执行。理想情况下，M和R要比集群中worker的机器数量大的多。在每个worker机器执行大量的不同任务有助于集群的动态的负载均衡，并且一个worker失败是可以加快恢复速度：该失效机器上已经完成的许多map任务可以分布到任意其他的worker机器上去执行。

我们的具体实现中M和R可以取多大是有一定的实际界限的，因为master必须执行复杂度为O(M+R)次调度，并且在内存中保存O(MxR)个状态（但是对内存使用的影响因子还是很小的：O(MxR)块状态，大概每对Map任务/Reduce任务差不多只有1个字节）。此外，R值通常是用户指定的，因为每个Reduce任务最终都会生成一个单独的输出文件。实践中，我们也倾向于选择合适的M值，以便每一个独立任务处理的都是大约16M到64M的输入数据（这样上面说的存储位置优化才最有效），并且我们让R设为我们打算使用的worker机器数比较小的倍数。我们通常会用这样的比例来执行MapReduce计算：M=200,000，R=5,000，使用2000台worker机器。

### 3.6 备份任务（Backup Tasks）

一个延长MapReduce总执行时间的常见原因是因为一个“落伍者”：在计算过程中一台机器花了很长的时间才完成最后几个Map或Reduce任务。出现“落伍者”的原因有很多。比如：如果一个机器的硬盘有问题就可能导致频繁的纠错操作，而让读取数据的速度从30M/s降低到1M/s。集群的调度系统可能给这台机器上又调度了其他的任务，由于CPU、内存、本地硬盘和网络带宽等问题，导致这台机器执行MapReduce代码的更慢。我们最近遇到的一个问题是因为机器的初始化代码有bug，导致处理器缓存被禁用：受影响的计算机的计算速度减慢了一百多倍。

我们有一个通用的机制来减少“落伍者”出现。当一个MapReduce操作快要完成的时候，master调度备份任务进程来执行剩下的还在处理中的任务。无论是最初的执行、还是备份任务执行结束都标记这个任务已经完成。我们已经调整了这个机制，让它所带来额外的计算资源不会超过几个百分点。我们发现这显着缩短了完成大型MapReduce操作的时间。例如，在5.3节描述的排序任务，在关闭掉备用任务的情况下要多花44%的时间才能完成排序任务。

## 4 改进（Refinements）

尽管通过编写简单的Map和Reduce函数所能提供的基本功能已经满足大部分的需求，我们还是发掘出了一些有用的功能扩展。本节将描述这些扩展。【标题叫扩展是不是更好？】

### 4.1 分区功能（Partitioning Function）

MapReduce的使用者通常会指定他们想要的Reduce任务以及输出文件的数量（R）。数据会使用中间key通过分区函数被分区。一个默认的分区函数是使用hash分区(比如，`hash(key) mod R`)进行分区。hash分区能产生十分平衡的分区。然而，在某些情况下，使用其它的一些分区函数对key值进行的分区也非常有用。比如，输出的key结果是URLs，我们希望每个主机的所有记录都保存到同一个输出文件中。为了支持类似的情况，MapReduce库的用户可以提供一个专门的分区函数。例如，使用`hash(Hostname(urlkey)) mod R`作为分区函数让来自所有的来自同一个主机的URLs最终保存在同一个输出文件中。

### 4.2 排序保证（Ordering Guarantees）

我们保证在给定的分区中，中间键值对数据会按照key值增量顺序来处理。这个顺序处理保证了可以很容易的让每个分区生成的输出文件也是有序的，当输出文件的格式需要能够支持高效的按key的随机访问查找的时候，将会变得很有用，亦或者是输出文件的使用者会发现对结果的数据集进行排序会很方便。

### 4.3 组合功能（Combiner Function）

在某些情况下，map函数产生的中间key值的重复数据会占很大的比重，并且用户给定的reduce函数满足交换律和结合律。2.1节中统计词频的例子就是个很好的例子。由于词频倾向于一个Zipf分布(齐夫分布)，每个map任务将产生成百上千<the,1>格式的记录。所有的这些计数将通过网络被发送到一个单独的reduce任务，然后通过reduce函数将这些值累加起来生成一个数字。我们允许用户指定一个可选的Combiner函数，可以让这些数据在发送到网络之前可以先部分进行合并。

Combiner函数是在每台执行Map任务的机器上执行的。通常Combiner和Reduce函数的实现使用的代码是一样的。唯一的区别是MapReduce库怎样处理函数的输出。reduce函数的输出被写入到最终输出文件里，而Combiner函数的输出是被写到中间文件里，然后会再被发送给一个reduce任务。

部分合并可以显著的加速一些MapReduce操作。附录A包含一个使用combiner函数的例子。

### 4.4 输入输出类型（Input and Output Types）

MapReduce库支持几种不同的输入数据的格式。比如，文本模式下输入数据的每一行被视为是一个键值对：key是该行在文件中偏移量，value是那一行的内容。另外一种常见的格式是存储了一个按照key排序的键值对序列。每种输入类型的实现都需要能够把输入数据分割成数据片段，以使得可以让单独的map任务来进行后续处理（例如，文本模式分割的后范围必须确保只会在每行的边界进行范围分割）。尽管大多数使用者大部分情况下都只需要使用MapReduce预定义的少部分输入类型中的一个，但是使用者依然可以通过提供一个Reader接口简单的实现就可以对一个新的输入类型提供支持。

一个reader并不一定要从文件中读取数据，比如，我们可以很容易定义一个reader，让他从一个数据库里读取记录，或者从内存中的数据结构读取数据。

以类似的方式，我们提供了一系列预定义的输出数据的类型用来可以产生不同格式的数据，并且用户代码可以很容易增加对新的输出类型的支持。

### 4.5 副作用（Side-effects）

在某些情况下，MapReduce的使用者发现，如果在Map和/或Reduce操作过程中增加辅助的输出文件会比较省事。我们依靠程序writer把这种“副作用”变成原子的和幂等的3。通常应用程序首先把输出结果写到一个临时文件中，在输出全部数据之后，在使用系统级的原子操作rename重新命名这个临时文件。如果一个任务产生了多个输出文件，我们没有提供类似两阶段提交的原子操作支持这种情况。因此，对于会产生多个输出文件、并且对于跨文件有一致性要求的任务，都必须是确定性的任务。但是在实际应用过程中，这个限制还没有给我们带来过麻烦。

### 4.6 跳过不好的记录（Skipping Bad Records）

**有时候，用户代码中的bug会导致Map或Reduce函数在处理某些记录的时候奔溃掉，这些bug让MapReduce操作无法完成。通常的做法是修复bug后再次执行MapReduce操作，但有时候这是不可行的；这些bug可能是在第三方依赖库里边，我们无法获取到源码。同时，我们可以接受跳过一些有问题的记录，比如在一个巨大的数据集上进行统计分析的时候。我们提供了一种可选的执行模式，在这种模式下，为了保证保证整个处理能继续进行，MapReduce会检测哪些记录导致确定性的crash，并且跳过这些记录不处理。**【replace here new】

每个worker进程都配备了一个信号处理器用来捕获内存段异常（segmentation violation）和总线错误（bus error）。在调用一个用户的Map或Reduce操作之前，MapReduce库在一个全局变量中保存执行参数的序号【这里应该就是处理记录的序号】。如果用户程序产生了一个信号，消息处理器将发送“最后一发”包含了该序号的UDP包给master。当master看到在处理某条特定记录出现不止失败一次时，意味着下次重新执行相关的Map或者Reduce任务这条记录需要被跳过。

### 4.7 本地执行（Local Execution）

调试Map和Reduce函数的问题可能非常的棘手，因为实际计算是在分布式系统中执行的，通常在几千台计算机上执行，具体执行任务的分配是由master进行动态调度决定的。为了简化调试、分析和小规模测试，我们额外开发了一套MapReduce库，可以让MapReduce任务在本机上顺序执行所有任务。控制权交给用户，让用户可以把计算限制到特定的Map任务上。用户通过设定特殊的标志来本地调用他们的程序，这样可以很容易的使用任意调试和测试工具（比如gdb）。

### 4.8 状态信息（Status Information）

master运行了一个内嵌的HTTP服务器并暴露一组状态信息页供人监控。状态页显示着计算的进度，比如已经完成了多少任务、有多少任务正在处理、输入的字节数、中间数据的字节数、输出的字节数、处理百分比等等。页面还包含了每个任务所生成的标准错误和标准输出文件的链接。用户利用这些数据预测计算需要执行大约多长时间、是否需要增加额外的计算资源。这些页面也可以被用来分析什么时候计算执行的比预期的要慢。

另外，处于最顶层的状态页显示了哪些worker失效了，以及他们失效的时候正在运行的Map和Reduce任务。这些信息在用户尝试诊断用户代码中的bug的时候十分有用。

### 4.9 计数器（Counters）

MapReduce库提供了一个计数器来统计各种事件发生次数。比如，用户可能想统计已经处理单词的总数、或者已经索引的德国文档的数量等等。

为了使用这个功能，用户要在程序中创建并命名一个的计数器对象，并在适当的时候在Map和Reduce函数中增加计数器的值。例如：

```pseudocode
Counter * uppercase;
uppercase = GetCounter("uppercase");
map(String name, String contents):
    for each word w in contents:
    if (IsCapitalized(w)):
        uppercase - > Increment();
EmitIntermediate(w, "1");
```

这些计数器的值周期性的从各个单独的worker机器上传送到master（附加在ping的响应包中）。master将成功的Map和Reduce任务的计数器值聚合，并在MapReduce操作完成之后，返回给用户代码。当前计数器的值也会显示在master的状态页面上，这样用户就可以观察当前活着的计算的进度。在聚合计数器的值时，master要消除重复运行的Map或者Reduce任务的影响，避免重复累加（备份任务的使用和失效后重新执行任务这两种情况会导致重复执行）。

有些计数器的值是由MapReduce库自动维持的，比如已经处理的输入的键值对数量、输出的键值对的数量等。

使用者会发现计数器功能对于检查MapReduce操作的行为非常有用。比如，在某些MapReduce操作中，用户需要确保输出的键值对数量完全等于输入的键值对数量，或者处理的德国文档数量在处理的整个文档数量在可容忍的范围。

## 5 性能（Performance）

在这节我们在一个大型集群上运行的两个计算来测量MapReduce的性能。一个计算来在大约1TB的数据中搜索出特定模式匹配的数据，另一个计算对大约1TB的数据进行排序。

这两个程序在大量MapReduce使用者的真实程序中是很有代表性 — 一类是将数据从一种表现形式转换为另外一种表现形式；另一类是从大的数据集中抽取少量用户感兴趣的数据。

### 5.1 集群配置（Cluster Configuration）

所有的程序都是在一个由大约1800台机器组成的集群上执行的。每个机器都配备两个2GHz的Intel Xeon处理器，支持超线程，4GB内存，两个160GB的IDE磁盘和一个千兆以太网卡。这些机器被部署在一个两层的树形交换网络中，在根节点大约有100-200 Gbps的总带宽可用。所有这些机器都采用相同的部署，因此任何一对机器之间的网络往返时间小于1毫秒。

在4GB的内存中，大约有1-1.5GB是由集群上运行的其他任务保留的。测试的程序是在周末下午执行的，这时的cpu、磁盘和网络大部分处于空闲状态。

### 5.2 测试1 - 查找（Grep）

grep程序会扫描大概10的10次方个单个100个字节组成的记录，查找一个相对少见的3个字符的模式（这个模式在92337个记录有出现）。输入数据被分为差不多64M一片的若干分片（M=15000），整个输出数据存放在一个文件中（R=1）。

![image-20200425220049080](D:\BLOG\hexo\source\_posts\PaperMapReduce\image-20200425220049080.png)

图2显示了这个运算随时间的处理过程。Y轴表示输入数据的处理速度。处理速度随着分配给MapReduce计算的机器数量的增加而增加，当1764台worker被分配参与计算的时，处理速度达到了30GB/s。当Map任务结束的时候，即在计算开始后80秒，输入的处理速度降到0。整个计算从开始到结束一共花了大概150秒。这包括了大概一分钟的初始启动阶段。初始启动阶段时间是因为要把这个程序传送到各个worker机器上的时间、等待GFS文件系统打开1000个输入文件集合的时间、获取相关的文件本地位置优化信息的时间。

### 5.3 测试2 - 排序（Sort）

排序程序会排序10的10次方单个100个字节组成的记录（大概1TB的数据）。这个程序是模仿TeraSort的benchmark[10]。

排序程序由不到50行代码组成。只有三行的Map函数从文本行中抽取出一个10字节的key值作为排序的key，并且把这个key和原始文本行作为中间的键值对输出。我们使用了一个内置的恒等函数作为Reduce操作函数。这个函数把中间的键值对不作任何改变输出。最终排序结果输出到两路复制的GFS系统文件中（也就是说，程序输出2TB的数据）。

如前面提到的，输入数据被了分成64MB的片（M=15000）。我们把排序后的输出结果分区后存储到4000个文件中（R=4000）。分区函数使用key的原始字节来把数据分区到R个片段中。

我们这个benchmark测试中分区函数知道key的分布情况。对于一个通常的排序程序来说，我们会增加一个预处理的MapReduce操作来采样key的分布情况，通过采样key的分布来计算对最终排序处理的分区点。

![image-20200425220159910](D:\BLOG\hexo\source\_posts\PaperMapReduce\image-20200425220159910.png)

图三（a）显示了这个排序程序一个正常的执行过程。左上图显示的是输入数据读取的速度。数据读取速度峰值会达到13GB/s，并且所有Map任务完成之后，即大约200秒之后迅速滑落到0。注意一点，排序程序输入数据读取速度小于上面的grep程序。这是因为排序程序的Map任务花了大约一半的处理时间和I/O带宽把中间输出结果写到本地硬盘。而对应的分布式grep程序的中间结果输出几乎可以忽略不计。

左边中间的图显示了中间数据从Map任务发送到Reduce任务的网络速度。这个过程从第一个Map任务完成之后就开始缓慢启动了。图中的第一个峰值是启动了第一批大概1700个Reduce任务（整个MapReduce分配到大概1700台机器上，每台机器1次最多执行1个reduce任务）。计算运行差不多300秒后，一些第一批启动的Reduce任务完成了，我们开始为剩下的Reduce任务shuffle数据。所有的处理在大约600秒后结束。

左下图表示Reduce任务把排序后的数据写到最终的输出文件的速度。在第一个排序阶段结束和数据开始写入磁盘之间有一个小的延时，这是因为worker机器正在忙于排序中间数据。写入的速度在2-4GB/s持续一段时间。整个写入时间大约持续850秒。再包括初始启动时间，整个运算消耗了891秒。这和TeraSort benchmark[18]的最好纪录1057秒很接近了。

还有一些东西要提一下：输入数据的读取速度比数据shuffle速度和输出数据写入磁盘速度要高，这是因为我们的输入数据本地化优化策略—大部分数据都是从本地硬盘读取的，从而绕过了网络带宽的限制。排序速度比输出数据写入到磁盘的速度快，这是因为输出数据写了两份（为了保证数据可靠性和可用性我们使用了双备份的GFS文件系统）。我们把输出数据写入到两个复制节点的原因是因为这是底层文件系统的保证数据可靠性和可用性的实现机制。在输出数据写入磁盘的时候如果底层文件系统使用编码容错技术(erasure coding)[14]的方式而不是复制的方式保证数据的可靠性和可用性，那么就可以减少对网络带宽的需求。

### 5.4 备份任务的影响（Effect of Backup Tasks）

图三（b）显示了关闭备份任务后排序程序执行情况。执行的过程和图3（a）很相似，除了输出数据写磁盘的动作在时间上拖了一个很长的尾巴，而且在这段时间里，几乎没有什么写入动作。在960秒后，除了5个reduce任务其他任务都完成。这些拖后腿的任务又执行了300秒才完成。整个计算消耗了1283秒，多了44%的执行时间。

### 5.5 机器故障（Machine Failures）

在图三（c）中演示的排序程序执行的过程中，在几分钟中内我们故意的杀死了1746个worker中的200个。集群底层的调度立刻在这些机器上重新开始新的worker处理进程（因为只是worker机器上的worker进程被kill了，机器本身还在工作）。

worker的死亡显示了一个负的输入数据读取率，因为一些以前完成的map任务丢失了了(因为相应的map任务的worker被kill了)，需要重新执行这些任务。这些Map任务很快就被会被重新执行。整个计算过程在933秒内完成，这包括启动开销(只比正常执行时间增加5%)。

## 6 经验（Experience）

我们在2003年1月写了首个版本的MapReduce库，在2003年8月做了有了显著的增强，这包括了数据本地优化、worker机器之间任务的动态负载均衡等等。从那以后，我们惊讶的发现，MapReduce库能广泛应用于我们日常工作中遇到的各类问题。它现在广泛的被Google内部各个领域广泛的使用，包括：

- 大规模机器学习问题，
- Google News和Froogle产品的集群问题，
- 从流行的查询记录中抽取数据来生成报告（比如Google的Zeitgeist），
- 从大量的新应用和新产品的网页中提取有用信息（比如，从大量的位置搜索网页中抽取地理位置信息）,
- 大规模的图计算。

![image-20200425220359033](D:\BLOG\hexo\source\_posts\PaperMapReduce\image-20200425220359033.png)

图四显示了在我们的源代码管理系统中，这段时间内独立的MapReduce程序数量的巨大增长。从2003年早些时候的0个增长到2004年9月份的差不多900个不同的实例。MapReduce的成功是因为MapReduce库可以在不到半个小时时间内写出一个简单的程序，并能够有效的在上千台机器的组成的集群上运行，这大大的加速了开发和原形制作的周期。另外，MapReduce让完全没有分布式和/或并行系统开发经验的程序员很容易的利用大量的资源。

![image-20200425220450179](D:\BLOG\hexo\source\_posts\PaperMapReduce\image-20200425220450179.png)

在每个任务结束的时候，MapReduce库日志分析出计算资源的使用状况。在表1，我们展示了2004年8月份在Google运行的MapReduce任务所占用的统计数据的一部分子集数据。

### 6.1 大规模的索引（Large-Scale Indexing）

目前MapReduce一个最成功的使用就是重写了Google网络搜索服务所使用到的索引构建系统。索引系统通过网络爬虫抓取回来的海量的文档作为输入数据，这些数据保存在GFS中。这些文档的原始内容有超过20TB的数据。索引程序是通过一系列大约5到10次的MapReduce操作来建立索引。使用MapReduce（而不是先前版本的分布式索引系统）带来了这些好处：

- 索引的代码更加简单、小巧、并且容易理解，因为处理容错、分布式以及并行计算的代码都隐藏在MapReduce库中。例如，使用MapReduce库，一个计算阶段的代码行数从原来的3800行C++代码减少到大概700行代码。
- MapReduce库的性能已经足够好了，因此我们可以把在概念上不相关的计算步骤分开，而不是混在一起来避免额外传递数据的开销。这样做也使得我们可以很容易去改变索引处理方式。比如，对之前的索引系统的一个修改可能要花好几个月的时间，但MapReduce只需要花几天时间就可以实现了。
- 索引过程变得更容易操作，因为由机器、机器运行缓慢和网络故障引起的问题都是由MapRe- duce库自动处理的，不需要操作员的干预。此外，通过向in- dexing集群中添加新机器，可以很容易地提高索引过程的性能。
- 构建索引的过程也变得更加容易操作了。因为大多数由机器故障、机器运行速度缓慢、以及网络故障阻塞等引起的问题都已经由MapReduce库解决了，不需要操作员的干预。此外，我们只需要通过向索引集群中添加新机器，就可以很容易地提高索引构建的性能。

## 7 相关工作（Related Work）

很多系统都提供了严格的编程模式，并且通过对编程的严格限制来实现并行计算的自动化。比如，一个结合函数可以把N个元素的数组的前缀在N个处理器上在log N的时间内使用并行前缀算法计算完[6，9，13]【没懂这个啥例子】。MapReduce可以被认为是我们基于现实世界下海量计算的经验总结的这些模型的简化和萃取。更重要的是，我们还提供了基于上千台处理器的规模的容错实现。相对而言，大多数并行处理系统都只实现了小规模的集群的并行，并将处理机器失败的具体细节交给程序员来处理。

Bulk Synchronous Programming[17]和一些MPI原语[11]提供了更高级别的抽象来让程序员更容易写出并行处理程序。MapReduce和这些系统一个关键的不同之处在于，MapReduce利用受限的编程模型来让用户程序的自动并发处理，并且提供了透明的容错处理。

我们数据本地优化策略的灵感来自于如active  disks[12,15]这样的技术，这些技术尽量将处理中的数据元素推送到里距离计算处理节点本地磁盘的地方，来减少网络和IO子系统的吞吐量。我们在挂载几个硬盘的普通机器上执行我们的运算，而不是在磁盘处理器上执行我们的工作，但是这两种一般方法是相似的。

我们的备用任务机制和Charlotte系统[3]使用的eager调度机制比较类似。该机制的一个缺点是如果一个任务反复失效，那么整个计算就无法完成。我们通过跳过不好的记录的方式在某种程度上解决了这个问题。

MapReduce的实现依赖于一个内部的集群管理系统，这个管理系统负责在一个超大的共享机器的集群上分布并运行用户任务。虽然这个不是本论文的关注点，但有必要提下，这个集群管理系统在理念上和其它如Condor[16]系统是一样。

排序机制是MapReduce库的一部分，这个排序机制和NOW-Sort[1]在操作上很类似。源机器（map的workers）把待排序的数据进行分区后，发送到那R个Reduce workers中的一个进行处理。每个Reduce worker在本地对数据进行排序（尽可能在内存中排序）。当然，NOW-Sort没有MapReduce那样可以用户自定义的Map和Reduce函数所带来的广泛的适用性。

River[2]提供了一个处理进程通过分布式队列传送数据的方式进行互相通讯的编程模型。和MapReduce类似，River系统尝试在异构的硬件环境下，或者在系统扰动的情况下也试图提供良好的平均性能。River是通过精心调度硬盘和网络的通讯来平衡任务的完成时间。MapReduce库采用了其它的方法。通过限制编程模型，MapReduce框架把问题分解成为大量的细粒度的任务。这些任务在可用的worker集群上动态的调度，这样快速的worker可以执行更多的任务。通过对编程模型进行限制，我们可用在工作接近完成的时候调度冗余任务，这大大的缩短在硬件异构的情况下缩小整个操作完成的时间（比如慢的或者阻塞住的worker）。

BAD-FS[5]有一个和MapReduce完全不同的编程模式，它是面向广域网的任务执行。但是，这两个系统有两个基础功能很类似。（1）两个系统采用重新执行的方式来防止由于失效导致的数据丢失。（2）两个都使用数据本地化调度策略，减少网络通讯的数据量。

TACC[7]是一个设计用于简化构造高可用网络服务的系统。和MapReduce一样，它也依赖重新执行机制来实现的容错处理。

## 8 结束语（Conclusions）

MapReduce编程模型在Google内部成功应用于多个领域。我们把这成功归结为几个原因：首先，模型使用简单，即便对于完全没有并行或者分布式系统开发经验的程序员而言很很容易上手，因为MapReduce封装隐藏了并行处理、容错处理、数据本地化优化、负载均衡等底层实现细节。其次，大量各种类型的问题都可以通过MapReduce的计算形式来表示。比如，MapReduce用于在Google的web搜索服务所需的数据生成、用于排序、用于数据挖掘、用于机器学习，以及很多其它的系统；第三，我们开发了一·个MapReduce的实现，可以运行在一个包含了数千台机器组成的大规模集群。这个实现可以更加充分的利用这些丰富的计算资源，因此很适合用来解决Google遇到的那些需要大量计算的问题。

我们也从这份工作中学到了一些东西。首先，约束编程模式可以使并行和分布式计算变得容易，也易于让这样的计算可以容错；其次，网络带宽是稀有资源。我们系统中大量的系统都是为了减少网络的数据传输：本地优化策略使大量的数据从本地磁盘读取，并且写一份中间文件的副本在本地磁盘上也节省了网络带宽；第三，冗余的执行任务可以减少性能慢的机器带来的负面影响，并且解决由于机器失败导致的数据丢失问题。

## 致谢（Acknowledgements）

Josh Levenberg has been instrumental in revising and extending the user-level MapReduce API with a number of new features based on his experience with using MapReduce and other people’s suggestions for enhancements. MapReduce reads its input from and writes its output to the Google File System [8]. We would like to thank Mohit Aron, Howard Gobioff, Markus Gutschke, David Kramer, Shun-Tak Leung, and Josh Redstone for their work in developing GFS. We would also like to thank Percy Liang and Olcan Sercinoglu for their work in developing the cluster management system used by MapReduce. Mike Burrows, Wilson Hsieh, Josh Levenberg, Sharon Perl, Rob Pike, and Debby Wallach provided helpful comments on earlier drafts of this paper. The anonymous OSDI reviewers, and our shepherd, Eric Brewer, provided many useful suggestions of areas where the paper could be improved. Finally, we thank all the users of MapReduce within Google’s engineering organization for providing helpful feedback, suggestions, and bug reports.

## 参考（References）

 [1]  Andrea C. Arpaci-Dusseau, Remzi H. Arpaci-Dusseau,David E. Culler, Joseph M. Hellerstein, and David A. Pat-terson. High-performance sorting on networks of work-stations. In Proceedings of the 1997 ACM SIGMOD In-ternational Conference on Management of Data, Tucson,Arizona, May 1997.

[2] Remzi H. Arpaci-Dusseau, Eric Anderson, Noah Treuhaft, David E. Culler, Joseph M. Hellerstein, David Patterson, and Kathy Yelick. Cluster I/O with River: Making the fast casecommon. InProceedings of the Sixth Workshop on Input/Output in Parallel and Distributed Systems (IOPADS ’99), pages 10–22, Atlanta, Georgia,
May 1999.

[3] Arash Baratloo, Mehmet Karaul, Zvi Kedem, and Peter Wyckoff. Charlotte: Metacomputing on the web. In Pro-ceedings of the 9th International Conference on Parallel and Distributed Computing Systems, 1996.
[4] Luiz A. Barroso, Jeffrey Dean, and Urs Hölzle. Web searchfor aplanet: TheGooglecluster architecture. IEEE Micro, 23(2):22–28, April 2003.

[5] John Bent, Douglas Thain, Andrea C.Arpaci-Dusseau,Remzi H. Arpaci-Dusseau, and Miron Livny. Explicit control in a batch-aware distributed file system. In Pro-ceedings of the 1st USENIX Symposium on Networked Systems Design and Implementation NSDI, March 2004.

[6] Guy E. Blelloch. Scans as primitive parallel operations.IEEE Transactions on Computers, C-38(11), November 1989.

[7] Armando Fox, Steven D. Gribble, Yatin Chawathe, Eric A. Brewer, and Paul Gauthier. Cluster-based scal-
able network services. In Proceedings of the 16th ACM Symposium on Operating System Principles, pages 78–91, Saint-Malo, France, 1997.

[8] Sanjay Ghemawat, Howard Gobioff, and Shun-Tak Le-ung. The Google file system. In 19th Symposium on Op-erating Systems Principles, pages 29–43, Lake George, New York, 2003

[9] S. Gorlatch. Systematic efficient parallelization of scan and other list homomorphisms. In L. Bouge, P. Fraigni-aud, A. Mignotte, and Y. Robert, editors, Euro-Par’96. Parallel Processing, Lecture Notes in Computer Science 1124, pages 401–408. Springer-Verlag, 1996.

[10] Jim Gray. Sort benchmark home page. http://research.microsoft.com/barc/SortBenchmark/.

[11] William Gropp, Ewing Lusk, and Anthony Skjellum. Using MPI: Portable Parallel Programming with the
Message-Passing Interface. MIT Press, Cambridge, MA, 1999.

[12] L. Huston, R. Sukthankar, R. Wickremesinghe, M. Satya-narayanan, G. R. Ganger, E. Riedel, and A. Ailamaki. Di-amond: A storage architecture for early discard in inter-active search. In Proceedings of the 2004 USENIX File and Storage Technologies FAST Conference, April 2004.

[13] Richard E. Ladner and Michael J. Fischer. Parallel prefix computation. Journal of the ACM, 27(4):831–838, 1980.

[14] Michael O. Rabin. Efficient dispersal of information for security, load balancing and fault tolerance. Journal of the ACM, 36(2):335–348, 1989.

[15] Erik Riedel, Christos Faloutsos, Garth A. Gibson, and David Nagle. Active disks for large-scale data process-ing. IEEE Computer, pages 68–74, June 2001.

[16] Douglas Thain, Todd Tannenbaum, and Miron Livny. Distributed computing in practice: The Condor experi-ence. Concurrency and Computation: Practice and Ex-perience, 2004.

[17] L. G. Valiant. A bridging model for parallel computation.Communications of the ACM, 33(8):103–111, 1997.

[18] Jim Wyllie. Spsort: How to sort a terabyte quickly. http://alme1.almaden.ibm.com/cs/spsort.pdf..

## 单词频率统计（A Word Frequency）

本节包含了一个完整的程序：统计命令行中敲入的一系列输入文件中，每个唯一单词出现的次数。

```C++
#include "mapreduce/mapreduce.h"
 // User’s map function
class WordCounter: public Mapper {
    public: virtual void Map(const MapInput & input) {
        const string & text = input.value();
        const int n = text.size();
        for (int i = 0; i < n;) {
            // Skip past leading whitespace
            while ((i < n) && isspace(text[i]))
                i++;
            // Find word end
            int start = i;
            while ((i < n) && !isspace(text[i]))
                i++;
            if (start < i)
                Emit(text.substr(start, i - start), "1");
        }
    }
};
REGISTER_MAPPER(WordCounter);
// User’s reduce function
class Adder: public Reducer {
    virtual void Reduce(ReduceInput * input) {
        // Iterate over all entries with the
        // same key and add the values
        int64 value = 0;
        while (!input - > done()) {
            value += StringToInt(input - > value());
            input - > NextValue();
        }
        // Emit sum for input->key()
        Emit(IntToString(value));
    }
};
REGISTER_REDUCER(Adder);
int main(int argc, char ** argv) {
    ParseCommandLineFlags(argc, argv);
    MapReduceSpecification spec;
    // Store list of input files into "spec"
    for (int i = 1; i < argc; i++) {
        MapReduceInput * input = spec.add_input();
        input - > set_format("text");
        input - > set_filepattern(argv[i]);
        input - > set_mapper_class("WordCounter");
    }
    // Specify the output files:
    // /gfs/test/freq-00000-of-00100
    // /gfs/test/freq-00001-of-00100
    // ...
    MapReduceOutput * out = spec.output();
    out - > set_filebase("/gfs/test/freq");
    out - > set_num_tasks(100);
    out - > set_format("text");
    out - > set_reducer_class("Adder");
    // Optional: do partial sums within map
    // tasks to save network bandwidth
    out - > set_combiner_class("Adder");
    // Tuning parameters: use at most 2000
    // machines and 100 MB of memory per task
    spec.set_machines(2000);
    spec.set_map_megabytes(100);
    spec.set_reduce_megabytes(100);
    // Now run it
    MapReduceResult result;
    if (!MapReduce(spec, & result)) abort();
    // Done: ’result’ structure contains info
    // about counters, time taken, number of
    // machines used, etc.
    return 0;
}
```













