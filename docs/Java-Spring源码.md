# 环境搭建

学习源码个人建议还是当一份源码下来，自己编译运行一下，也方便做笔记等。虽然过程中会有一点磕绊，但整体来说，Spring的源码环境搭建还是比较容易的。

## 准备环境

- 源码
  - https://github.com/spring-projects/spring-framework
  - master等其他版本可能为spring内部开发人员使用的，会包含一些他们内部仓库才有的东西，所以最好切到某个relase的tag下。
  - 我们这里选择当前最新的relase版本
   ![image-20210218102628168](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-Spring源码/image-20210218102628168.png)
  
- gradle
  
  - 目前最新的spring使用了gradle作为系统构建器
  - 虽然源码说内置了一个gradle环境，不需要我们在自己环境中配置gradle，但是我在编译时候出现了一些问题，所以建议还是自己环境配一个。
  - spring对gradle的版本也有要求，但是官网没有说，我最终使用的gradle版本是`gradle-5.6.4`。(在编译过程中，spring也会自动下载需要的版本)
  
- jdk

  - 官方上说jdk8就行，但是如果直接使用Oracle的jdk8是有问题的，会有部分类缺失。

  - 网上查阅有人使用Orcale的jdk11解决了，但是我们配置了依然不好使，最后使用的是官方给的链接的[open-jdk](https://adoptopenjdk.net/)。

     >  To build you will need [Git](https://help.github.com/set-up-git-redirect) and [JDK 8 update 262 or later](https://adoptopenjdk.net/). 

  - 我使用的jdk版本为
  ![image-20210218103928991](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-Spring源码/image-20210218103928991.png)



## 开始编译

为了防止意外，最好紧跟spring文档的步骤来：[官方指导](https://github.com/spring-projects/spring-framework/wiki/Build-from-Source)

### 一些调整

因为我单独下了一个open-jdk，但是我系统当前环境默认的jdk版本还是jdk8，所以我们需要修改下编译脚本，让它使用我们指定的jdk的版本。

主要就是修改`gradlew`脚本下面这段：(如果你是windows系统就修改`gradlew.bat`)

![image-20210218105257472](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-Spring源码/image-20210218105257472.png)

我的修改如下：

```shell
# 这里指定你配置的jdk位置
JAVA_TMP_HOME=/Users/***/workspace/env/jdk/open-jdk-11.0.10
# Determine the Java command to use to start the JVM.
if [ -n "$JAVA_TMP_HOME" ] ; then
    if [ -x "$JAVA_TMP_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_TMP_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_TMP_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_TMP_HOME
```

### 官网步骤

- `./gradlew build`
  - 下载需要的gradle版本以及相关 依赖，并且会执行所有的测试case。这个步骤会花费比较长时间。
  - 一般情况下，就能编译通过了，如下：
![image-20210218131637568](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-Spring源码/image-20210218131637568.png)
- 导入idea
  - 参考[官方文档](https://github.com/spring-projects/spring-framework/blob/master/import-into-idea.md)
  - 注意设置下Project对应的JDK版本，以及Gradle版本。
  - 具体步骤
    - 预编译：`./gradlew :spring-oxm:compileTestJava`
![image-20210218132547596](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-Spring源码/image-20210218132547596.png)
    - 导入gradle项目，等待idea 下载依赖以及index过程
    - 排除`spring-aspects` 模块
  - 最终导入完成如图：
![image-20210218133018324](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-Spring源码/image-20210218133018324.png)



## 测试

我们添加一个新的gradle模块：`spring-samples`

1. 添加相关的依赖，修改`build.gradle`添加如下：

   ```yaml
   dependencies {
       compile(project(":spring-context"))
       testCompile group: 'junit', name: 'junit', version: '4.12'
   }
   
   jar.enabled(true)
   ```

2. 添加一个启动类MainApplication以及一个HelloWorld的bean实体，如图

   ![image-20210218134432056](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-Spring源码/image-20210218134432056.png)

3. 里面内容如下：

   1. MainApplication 
   ```java
   @Configuration
   // 扫描路径
   @ComponentScan("org.springframework.samples")
   public class MainApplication {
   	public static void main(String[] args) {
       // 基于注解的容器
   		AnnotationConfigApplicationContext applicationContext =
   				new AnnotationConfigApplicationContext(MainApplication.class);
   		String[] beanDefinitionNames = applicationContext.getBeanDefinitionNames();
   		Stream.of(beanDefinitionNames).forEach(System.out::println);
   		// 获取helloworld bean
   		HelloService helloServiceImpl = applicationContext.getBean("helloServiceImpl", HelloService.class);
   		helloServiceImpl.sayHello();
   	}
   }
   ```
   
   2. HelloWorld Bean
   ```java
   public interface HelloService {
   	String sayHello();
   }
   @Service
   public class HelloServiceImpl implements HelloService {
   	@Override
   	public String sayHello() {
   		System.out.println("Hello World !");
   		return "HelloWorld!";
   	}
   }
   ```
   
4. 运行`main`方法，环境搭建完毕。
![image-20210218134900913](/Users/zhaohaoren/workspace/mycode/blog-docs/docs/Java-Spring源码/image-20210218134900913.png)



# 成员概览

大白话说下Spring的一些重要的成员，清晰的理解这些类的职责作用，可以帮我们更好的理解源码。

## 元类

之所以，我叫他们元类，因为他们属于参与Spring源码中存储一些源数据信息。

### BeanDefinition

该类是一个接口，主要作用是描述一个bean的元数据信息。Spring在容器启动时，会先将所有Bean相关的信息封装到BeanDefinition中缓存住，然后创建对象的时候，通过BeanDefinition来创建。

我们可以这样想：一个普通的Java类（不带任何spring的东西），我们可以直接new就行了，但是**使用了Spring之后，我们类中就有很多Spring特性的东西，比如一些注解，实现了一些Spring接口等等，那么BeanDefinition其实就是存储这些信息的。**

大致描述下其存储的内容：

- Scope信息 -- @Scope注解值
- 是否懒加载 -- @Lazy注解值
- bean的Spring的继承信息
- bean对应的类的全限定类名，可以用来反射创建类
- 该bean依赖的所有bean -- @DependsOn注解值
- 该bean被哪些bean依赖
- 是否可以让其他bean按照类型注入该bean -- isAutowireCandidate
- bean是否primary -- 一个接口多个实现，可以通过这个来决定优先注入哪个
- 生成该bean的工厂类，以及工厂方法 -- 针对那些通过工厂生成的bean，而不是反射。
- 该bean构造器的参数
- bean中属性值信息
- bean的初始化和销毁方法 -- PostConstruct，PreDestroy注解，DisposableBean ,initilzingBean接口， @Bean(initMethod = "",destroyMethod="") 注解

可以看到，一个纯粹的Java类，和Spring有关的和该类本身的所有的相关信息都几乎被保存在了BeanDefinition中。





## 容器家族





# IOC



容器启动流程

创建Bean

getBean流程

Bean生命周期

循环依赖



# AOP







