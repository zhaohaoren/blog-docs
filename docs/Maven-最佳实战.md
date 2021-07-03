# Maven 项目部署实践的一些思考

平时开发中最多的就是掌握一些maven的基本的生命周期的命令，再好一点可能会自己来用脚手架去搭建项目，网上通篇的其实也是这类的教学资料。但是在使用中还是有一些小的问题，本文就maven项目在日常开发和上线部署整个流程环节做一个整体的概述，以及阐述当前我自己开发和部署环节中摸索出来的一些方法论。

## 起因

触发我写本篇文章的原因也是新公司中使用maven的多模块来构建项目，模块如下：

- `service-module`是一个服务，因此他不需要deploy到服务上去。

```
project-parent
├── common-module
├── sdk-module
├── dao-module
└── service-module
```

但是，其他的如common这些module，在开发中会频繁的改动，一般我们都是使用`快照（-SNAPSHOT）版本`。这样做在dev和test环境没有问题，但是我们的线上是禁止使用Snapshot版本的，这就在**每次上线的时候，都要去每个module里面去修改下对应的version，然后再deploy提交到prod分支。然后上完线之后，test分支上又要重新将一些需要修改的module的版本再次变更为Snapshot。**这就有点难受了！

而且这种方式我们在使用中，还出现过如下问题：

1. 比如同事A对maven不是很熟，修改了common-module的一些代码，但是没有改版本号，结果上线之后运行中出错！A嚷嚷着我本地是好的啊！一样的代码为啥线上就错了？
2. service依赖了dao，然而dao又依赖了common，有人在service的pom里面又强制设置了一个老版本的common，他修改了common的代码，然后改了dao的依赖版本，既然dao改了common的依赖，那么dao其实也得改版本！不然就是deploy上去，Release版本的也是不能被重新拉的。这一联动就要改好多东西，有人总是忘了改了某处导致编译报错等等。
3. 还有一些其他的细碎问题，大多都是因为频繁的老去改动版本号，以及每个开发这都可以对版本号修改引发的冲突导致的。

本来就难以接受这种修改版本的方式了，再加上这种问题表示完全不能接受！所以希望能让流程更加可控一点，对开发友好一点，所以对开发和部署有这么几个要求点：

1. 测试环境和开发环境全部使用Snapshot版本，并且test和dev的分支中代码本身就是Snapshot的！让开发中不需要去关注版本号。
2. 修改版本号的方式要足够方便，或者是有什么方式能在不用关注代码修改版本Snapshot还是Release的情况下，自动完成测试和线上的隔离（线上自己打包Release的，依赖也自动去依赖Release的，测试开发用Snapshot），不过这个没找到比较好的方案。
3. 线上发布时候，需要能确保每个服务所依赖的包安全（不会存在有代码修改的包，但因为部署时有相同Release版本导致无法拉取而出现的问题）。

总之我们希望就是：开发不用关注版本号的情况下，开发，测试环境不会有任何因为版本导致的问题，上了生产环境有一种操作规范也能保证线上不会存在任何版本导致的问题。

## 实践

因为某些第三方的原因，运维能够对我们的支持有限，我们主要关注于解决下面几个点：

1. **开发者只需要业务代码开发，而不该涉及版本号修改**（这避免人人都可以随意改，且命名规则各有特色带来的一系列可能的问题）。
2. 测试分支和线上分支应该是**fast-forward型**的，不存在特地去线上分支单独修改下版本，而测试用另一套代码这种行为。
3. 还是防止存在上线后，Release包有人改了代码但是没有更新版本，我们每次上线都**强制全部基础包都升级一个版本**。

我们采用的策略如下：

![image-20210703201904961](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Maven-最佳实战/image-20210703201904961.png)

主要流程：

1. 项目在正常情况下，全部使用的是Snapshot版本，我们新建一个项目一般初始就是1.0.0-Snapshot；
2. 项目正常开发中，在开发环境和测试环境，都使用1.0.0-Snapshot版本的包，只要部署测试环境时deploy下变更的包就行；
3. 测试完成准备上线前，提交一个修改版本号的commit，将版本全部换成Release版本（借助于maven插件）；
4. 然后合并到prod分支；
5. deploy所有的基础包；
6. 部署生产服务，完成部署；
7. 切回测试环境，新增版本继续下面开发。（如果可以确定下次迭代不会修改基础包，可以不升级版本）

## 配置说明

为了实现这，我们对POM的配置需要如下修改：

- 针对parent

  1. 添加插件`versions-maven`插件，该插件可以统一修改parent所有的子包的parent依赖版本号。

     ```xml
     <plugin>
         <groupId>org.codehaus.mojo</groupId>
         <artifactId>versions-maven-plugin</artifactId>
         <configuration>
             <generateBackupPoms>false</generateBackupPoms>
         </configuration>
     </plugin>
     ```

  2. 统一在parent的依赖管理中设置默认的基础包依赖版本号和parent的版本号一样。

     ```xml
     <dependencyManagement>
         <dependencies>
             <dependency>
                 <groupId>com.x.x</groupId>
                 <artifactId>common-module</artifactId>
                 <version>${project.parent.version}</version>
             </dependency>
             <dependency>
                 <groupId>com.x.x</groupId>
                 <artifactId>sdk-module</artifactId>
                 <version>${project.parent.version}</version>
             </dependency>
             <dependency>
                 <groupId>com.x.x</groupId>
                 <artifactId>dao-module</artifactId>
                 <version>${project.parent.version}</version>
             </dependency>
         </dependencies>
     </dependencyManagement>
     ```

- 针对子module

  1. 所有的服务类型的包需要配置跳过install和deploy

     ```xml
     <properties>
         <maven.install.skip>true</maven.install.skip>
         <maven.deploy.skip>true</maven.deploy.skip>
     </properties>
     ```

  2. 所有的服务类型的包依赖的基础包不能有版本号，除非明确要老版本（老版本也不能为Snapshot版本，必须是Release的，不然线上无法引用）

  3. 所有的基础包的版本号统一设置为parent的版本：

     ```xml
     <artifactId>common-module</artifactId>
     <version>${project.parent.version}</version>
     ```

大致的原理就是：

1. 上线前通过parent配置的插件，统一修改一下版本号为Release版本。比如指定为`1.1.1-Release`。

   <img src="/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Maven-最佳实战/image-20210703204213098.png" alt="image-20210703204213098" style="zoom: 67%;" />

2. 执行完之后，所有子模块的parent的版本都会被更改为`1.1.1-Release`

3. 提交到线上去，执行所有基础包的deploy。

4. 而服务包中的基础包的依赖，因为parent包统一管理了默认版本为`${project.parent.version}`，所以所有的服务依赖的版本也是`1.1.1-Release`。这样就不会存在版本重复而无法拉新的问题。

回头看看整体带来了哪些好处：

1. 整体的流程缩减了很多手动操作，这主要借助于插件来统一修改pom的版本。
2. 测试开发的时候，我们完全就不用再管版本号了，版本控制由上线的人统一管理抉择。
3. 将版本调整纳入上线流程中，因为上线频次和测试部署的频次比较会很低，因此人力操作很少，甚至完全可以自动化完成。
4. 采用了比较悲观的态度去部署线上服务，可能会导致包比较多，但是因为频次的低，已经我们服务包还不多，这点影响可以忽略，可以保障所有的服务能用到最新的包，并且拉的也是最新的包。

## 总结

只是对目前的现状一点简单的改进，目前能较好的满足我们的需求，可能有更好的实现方式，比如是否能完全做到自动化，但是受限于运维资源以及我们的项目本身就不是很庞大，当前算是一个比较好的解决方案。当然应该有更好的方案，还原交流分享。





















