---
title: 【JAVA】HashMap的负载因子为什么是0.75
date: 2020-05-10 00:45:03
tags: [java,hashmap]
mathjax: true
---

起初看hashmap源码的时候，最让我困惑的地方就是这里。相信很多人也有过这样的问题，相信很多人和我一样也是网上百度了一通，相信很多人和我一样百度，google一通后，发现答案就那么几个，然后就默认了他们是对的，但是实际上还是很懵逼。这篇文章就来详细聊聊这0.75。

<!-- more -->

# 最原始的回答

这是jdk1.7源码上的注释

```
As a general rule, the default load factor (.75) offers a good tradeoff between time 
and space costs. Higher values decrease the space overhead but increase the lookup
cost (reflected in most of the operations of the HashMap class, including get
and put).The expected number of entries in the map and its load factor should be
taken into account when setting its initial capacity, so as to minimize the number 
of rehash operations. If the initial capacity is greater than the maximum 
number of entriesdivided by the load factor, no rehash operations will ever occur.
```

大概意思就是：**一般而言**，默认负载因子为0.75的时候在时间和空间成本上提供了很好的折衷。太高了可以减少空间开销，但是会增加查找复杂度。我们设置负载因子尽量减少rehash的操作，但是查找元素的也要有性能保证。

网上通天彻尾的基本都是这个言论，毕竟官方的注释。只是这注释回答的未免也太过敷衍，就像我加粗的那4个字：“一般而言”。？(╯￣Д￣)╯╘═╛这个0.75的原因就是因为一个一般而言？这显然不够让人信服。所以很多小伙伴也就继续深究下去了。（注意加粗的字体，很鸡肋，但是却有很强的提示性）

这种回答就是：“嗯，你说的很有道理样子，也没什么错，但是为什么是0.75呢？这数怎么就出来了呢？”

# 最扯淡的回答

这是网上流行的第二个流行版本了，也来自官方，不过是jdk1.8的。

```
Because TreeNodes are about twice the size of regular nodes, we
use them only when bins contain enough nodes to warrant use
(see TREEIFY_THRESHOLD). And when they become too small (due to
removal or resizing) they are converted back to plain bins.  In
usages with well-distributed user hashCodes, tree bins are
rarely used.  Ideally, under random hashCodes, the frequency of
nodes in bins follows a Poisson distribution
(http://en.wikipedia.org/wiki/Poisson_distribution) with a
parameter of about 0.5 on average for the default resizing
threshold of 0.75, although with a large variance because of
resizing granularity. Ignoring variance, the expected
occurrences of list size k are (exp(-0.5) * pow(0.5, k) /
factorial(k)). The first values are:
0:    0.60653066
1:    0.30326533
2:    0.07581633
3:    0.01263606
4:    0.00157952
5:    0.00015795
6:    0.00001316
7:    0.00000094
8:    0.00000006
more: less than 1 in ten million
```

简单翻一下：

```
因为TreeNode的大小约为链表节点的两倍，所以我们只有在一个拉链已经拉了足够节点的时候才会转为tree（参考TREEIFY_THRESHOLD）。并且，当这个hash桶的节点因为移除或者扩容后resize数量变小的时候，我们会将树再转为拉链。如果一个用户的数据他的hashcode值分布十分好的情况下，就会很少使用到tree结构。在理想情况下，我们使用随机的hashcode值，loadfactor为0.75情况，尽管由于粒度调整会产生较大的方差，桶中的Node的分布频率服从参数为0.5的泊松分布。下面就是计算的结果：桶里出现1个的概率到为8的概率。桶里面大于8的概率已经小于一千万分之一了。
```

这个东西因为来自jdk1.8，而且提到了0.75，没有好好理解这段话的意思的话，很容易就认为这是在阐释0.75是怎么来的，然后就简单的把泊松分布给强关联到了0.75上去。然而，**这段话的本意其实更多的是表示jdk1.8中为什么拉链长度超过8的时候进行红黑树转换。**这个泊松分布的模型其实是基于已经默认因子就是0.75的模型去模拟演算的。

我其实很长一段时间也认为这就是标准答案了，虽然不懂，但是以后有人问直接甩他一个泊松分布就行了，直到--我忘了泊松分布的知识点了😂。其实也好理解，红黑树是1.8之后加进来的，所以jdk源码者并没有特地为我们解释下为啥当时设计了0.75，而是更多是想解释一些关于加入红黑树之后一些设计的原因。

# 最深挖的回答

其实很高兴有人能挖掘到这里，我也以为这可以解答我这个问题了。

https://stackoverflow.com/questions/10901752/what-is-the-significance-of-load-factor-in-hashmap/31401836#31401836

这是stackoverflow上的一个帖子。Answers中top1其实就是最原始的回答，top2用了数学的一套理论推演出了 log(2)，然后来近似于0.75。我以为找到了真理，可惜写的太潦草了，没看懂这些公式罗列出来分别代表的意义。后来网上找到一篇有人详细[推演](https://wafer.li/Interview/hashmap-%E7%9A%84-loadfactor-%E4%B8%BA%E4%BB%80%E4%B9%88%E6%98%AF-0-75/)了计算过程，可以参考参考，说的也不是很清楚，但是相对来说还是有很大的借鉴意义的。不否认，该思路的亮点将问题转变为了碰撞的概率问题。

唯一我存在疑问的点，就是这种概率问题真的服从二项分布吗？我自己给自己解释感觉也说的通，感觉也说不通。

# 总结的回答1

首先我们了解下概率论的相关东西（本人大学概率论没学好，选修课，还是早上的课，所以你懂得。）

<u>**二项分布**</u>

- 什么是二项分布
  - 在做一件事情的时候，其结果的概率只有2中情况，和抛硬币一样，不是正面就是反面。这些实验做了n次，其所有成功的case离散概率的分布。
- 特性
  - 在每次试验中只有两种可能的结果
  - 每次实验是独立的，不同实验之间互不影响
  - 每次实验成功的概率都是一样的
- 公式
  - $ binom(n,k) = C_n^k \times (p)^k \times (1 - p)^{n - k} $
  - n为实验的次数，k为成功的次数。上面公式就是描述该成功概率为p的情况下，n次实验，k次成功的概率为多少。

更具体的二项分布的内容，不懂的可以去学习下相关内容。

**<u>hashmap的二项分布</u>**

那么，这个和我们的这个负载因子有什么关系呢？我们先针对一下特性，来做一下思路的转换类比：

- 实验只有2种结果
  - 我们往hash表put数据可以转换为key是否会碰撞？碰撞就失败，不碰撞就成功。
- 实验相互独立
  - **我们可以设想，实验的hash值是随机的，并且他们经过hash运算都会映射到hash表的长度的地址空间上，那么这个结果也是随机的。所以，每次put的时候就相当于我们在扔一个16面（我们先假设默认长度为16）的骰子，扔骰子实验那肯定是相互独立的。碰撞发生即扔了n次有出现重复数字。**

- 成功的概率都是一样的
  - 这就是我难以理解的地方，这个地方可以说的过去，也可以说不过去。
  - 说的过去
    - 每次一put的前面的位置我们不知道会在哪！可能前面一直都在一个位置上，那么我们理论上的概率一直都是 $\frac{1}{16}$。我们可以姑且抽象的认为概率p为$\frac{1}{s}$（设长度为s）。
    - 需要说明的是：这里我并不确定是否合理，这也是过程中我认为不太严谨的地方。
  - 说不过去
    - 但是每次扔的大可能不会在同一个位置上，所以概率每次都会不一样，但是这个不一样又是我们无法估量和猜测的。

然后，**我们的目的是啥呢？**

就是掷了k次骰子，没有一次是相同的概率，需要尽可能的大些，一般意义上我们肯定要大于0.5（这个数是个理想数，但是我是能接受的）。

于是，n次事件里面，碰撞为0的概率，由上面公式得：

$$
\begin{aligned} 
binom(n,0) & = C_n^0 \times (\frac{1}{s})^0 \times (1 - \frac{1}{s})^{n - 0}  = (1 - \frac{1}{s})^n &
\end{aligned}
$$

这个概率值需要大于0.5，我们认为这样的hashmap可以提供很低的碰撞率。所以：

$$
(1 - \frac{1}{s})^n  \ge \frac{1}{2}
$$

这时候，我们对于该公式其实最想求的时候长度s的时候，n为多少次就应该进行扩容了？**而负载因子则是$n/s$的值**。所以推导如下：

$$
\begin{aligned} 
n\ln(1 - \frac{1}{s}) & \ge -\ln2 ····两边取对数\\
n & \le \frac{-\ln2}{\ln(1 - \frac{1}{s})} \rightarrow n \le \frac{\ln2}{\ln\frac{s}{s-1}}  ····提取n \\
\frac{n}{s} &  \le \frac{\ln2}{s\ln\frac{s}{s-1}}  ····两边除以s \end{aligned}
$$

所以可以得到

$$
\begin{aligned} 
loadFactor & = \lim_{s \to \infty}\frac{\ln2}{s\ln\frac{s}{s-1}} \end{aligned}
$$

其中 
$$
\begin{aligned} 
\lim_{s \to \infty}s\ln\frac{s}{s-1} 
\end{aligned}
$$
这就是一个求  $$\infty \cdot 0$$ 函数极限问题，这里我们先令$s = m+1（m \to \infty）$则转化为

$$
\begin{aligned} 
\lim_{m \to \infty}(m+1)\ln(1+\frac{1}{m}) 
\end{aligned} 
$$
我们再令 $x = \frac{1}{m} （x \to 0）$ 则有，
$$
\begin{aligned} 
\lim_{s \to \infty}s\ln\frac{s}{s-1} & = \lim_{x \to 0}（\frac{1}{x}+1）\ln(1+x) \\
&= \lim_{x \to 0} （\frac{1}{x}+1） x ····无穷小等价替换有\ln(1 + x) \sim x （证明去百度）\\
&= \lim_{x \to 0}(1+x) \\ 
& \sim 1
\end{aligned}
$$
所以，
$$
\begin{aligned} 
loadFactor & = \lim_{s \to \infty}\frac{\ln2}{s\ln\frac{s}{s-1}} \\ 
&\sim \ln2 \\ 
& \sim 0.693 
\end{aligned}
$$

这也就是为什么stackoverflow上说接近于ln2的原因了。然后再去考虑hashmap一些内置的要求：

- **乘16可以最好一个整数。**

那么在0.5~1之间找一个小数，满足这要求的只有0.625（5/8），0.75（3/4），0.875（7/8）。这三个数让我选，从审美角度，还是从**中位数**角度，我都会挑0.75。毕竟碰撞是个概率问题，这个0.75我觉得不错，我没办法预知使用者的数据到底什么样子的，0.75是最为折中的一个选择。

# 总结的回答2

事先申明，我否认了上面的一些答案，不代表我就很支持我总结的答案1，很坦白的说，我目前的看法还是保留着这只是作者的一个心理衡量出来的一个值的猜想。只是上面的那个答案1目前还算能让我心里把自己说得过去的。

我猜想也许从源头上，就是最原始的回答上我们被误导了，总觉得这个0.75不是简简单单来了，就觉得这个数一定是经过某种数理逻辑推演出来的。可以像上面那个回答一样可以用公式完美的一步步可以推算出来。但是，事实呢？我们从设计者的角度复演一下当时设计者的考虑：

如果要设值，这个值，在心理合理的范围应该是0.5~1之间的某个数。原因很简单：

- 小于0.5，空着一半就扩容了，这在心理上很多人都会觉得不合理吧，空间肯定会很浪费。
- 但是如果是1的话，只能说有超级大的概率，会发生碰撞，这不符合我们的初衷。

然后就为什么是0.75呢？我的猜想是这样：当时因为已经设置了hash table的长度为16。其实负载因子并不重要，重要的其实是那个阈值。负载因子也是为了计算那个阈值的。**上面也提到了0.5~1之间找一个小数，乘16可以是一个整数时候0.75很合适。（这也正如1.7注释里面说的。所以也许作者也没法和我们准确交代0.75到底怎么来的，不妨换位思考下，如果这个0.75是你经过精密推演得出来的数字，注释肯定会详细解释说明，怎么可能"一般而言"就简单带过了呢？）**

所以我还是保留这个答案2，这个数字就是作者感觉差不多满足他想要的一些条件，感觉上也差不多的一个值，不会太浪费空间，也不会高碰撞概率。并且这是一个调优参数，用户可以根据自己的数据去动态调整这些参数来实现最优。所以就设了个这么个值。

但还是要提一下：

> **C#中的类似于Java的HashMap的类叫HashTable，而它的负载因子是0.72。这也是让我为什么一直要钻这个牛角尖的主要原因。取的数不同只是相似，这个数肯定没那么简单。**

# 总结

这个问题，困扰了我很久，其实每次回头看hashmap的时候，我都会想这个问题，也和周围的人讨论过，得到的回答基本是："不要钻牛角尖"，"面试问这个就太过分了"，""知道有啥用，记住数字就行"。可是不明所以，就如鲠在喉，希望这文章可以帮助和我有同样的感觉的人，也希望有什么异议可以告诉我。

其实几个回答分析下来，发现整个过程是：简单→复杂→简单的过程。如果面试我直接回答最后一个的结论，我觉得面试官也听的很没劲。需要一步步趟过来，这种返璞归真才有意思。

当然，对这个问题，也确实可能没必要钻这牛角尖。就和讨论P和NP问题一样，可以讨论，没实际多大意义。没准就如我所猜想，就是作者心理选了这么个数字呢？特别是网上看到的一些乱七八糟，逻辑都站不住脚的回答，我觉得就是有点强行了。仿佛世间一切的因果必是很强的逻辑性，没有因果就乱设因果，容易造成就是硬造也要造一个让自己满意的答案（这在学术圈屡见不鲜：很多从根上错的东西含糊其辞的说过去了，就开始继续往下推演）。

最后还是要提一句，如果你真的有严密的推演逻辑，还请告诉我。

# 引用

还是感谢下，没有2篇文章，我可能很长时间都无从下手。

https://stackoverflow.com/questions/10901752/what-is-the-significance-of-load-factor-in-hashmap/31401836#31401836

[HashMap 的 loadFactor 为什么是 0.75]([https://wafer.li/Interview/hashmap-%E7%9A%84-loadfactor-%E4%B8%BA%E4%BB%80%E4%B9%88%E6%98%AF-0-75/](https://wafer.li/Interview/hashmap-的-loadfactor-为什么是-0-75/))

