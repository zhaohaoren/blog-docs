---
title: 【读书笔记】Spring揭秘
date: 2020-05-14 21:49:01
tags:
---

# 第一部分 掀起Spring的盖头来

## 第1章 Spring框架的由来

- EJB属于重量级的企业应用开发，Spring是轻量级的
- 目的是为了简化javaEE企业级应用开发

### 1.1 Spring之崛起 2

- EJB有诸多不好的地方，主要是其复杂性，以及其配套的设施大多都是商业性的。
- EJB只有在分布式场景中才能给我们带来最大的益处，我们一般的项目用不着，很杀鸡用牛刀。

### 1.2 Spring框架概述 3

- Spring立足于最简单的POJO（简单java对象）的轻量级开发理念
- Spring的本质提供服务从而简化那些基于POJO的Java应用程序开发。
- 下面是一个Spring框架总体结构图（一棵生命之树）
  - ![Spring框架总体结构](/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200517175832492.png)
    - **Core**：核心模块，是框架基础。该模块提供了IOC实现，还包含框架内部使用的各种工具类。
    - **AOP**：可以使用AOP形式增强各个POJO的能力，弥补OOP/OOSD的缺憾，与IOC结合很强大。
    - **数据访问**，事务处理：构建在Core和AOP之上，极大简化对API的使用。集成诸多ORM框架。
    - **服务集成**：javaEE中对其他的一些服务的集成支持。
    - **Web**：Spring提供了一套自己的WebMVC框架。
- 	不要简单认为Spring只是IOC或者AOP，可以说**它是一个简化java应用开发的框架。**

### 1.3 Spring大观园 5

主要介绍了Spring家族中的一些成员，这里只挑了我感兴趣但还没听过的。

- Spring Batch：处理企业应用中的批处理业务的，一款批处理框架。

### 1.4 小结 8

都是概念性的东西。

# 第二部分 Spring的IoC容器

## 第2章 IoC的基本概念 10

### 2.1 我们的理念是：让别人为你服务 10

- IOC（Inversion of Control）控制反转，还有一个别名叫DI（依赖注入），也有些地方把DI看做是IOC的一种实现方式。这些概念都无所谓，没什么纠结的地方。
- 传统做法下，我们在编程中，一个类需要依赖一个类或者服务的时候，一般就是在该类构造函数中new需要依赖的对象。**这种都是我们主动获取依赖对象。**
- 其实没必要主动获取，我们只是要该对象的某项服务罢了，new一个对象出来只用其中小部分功能太浪费了。所以应该是**我们需要某个对象的时候，它能准备就绪的就行了**。不用在乎是主动的，还是别人送来的。这就是IOC干的事情。
- IOC的理念：让别人为你服务！

![image-20200517185237800](/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200517185237800.png)

- 需要被注入对象和依赖对象都通过**IOCService Provider**来打交道，由其来进行管理。

### 2.2 手语，呼喊，还是心有灵犀 13

我需要注入哪些依赖，应该怎么像IOC容器表达我需要的服务？Martin Fowler有篇文章提到了3种依赖注入方式：

- 构造方法注入
- setter注入
- 接口注入

#### 2.2.1 构造方法注入 13

- 将需要注入的对象写在**构造的参数列表**上。IOC会扫描构造来获取依赖的对象进行注入。
- 优点：直观，构造完成后，被注入的对象就进入就绪状态可以直接使用。

#### 2.2.2 setter方法注入 13

- 使用**set方法**进行注入，特别适合javaBean。
- 可以对象构造完成后再进行注入，注入比较宽松，可以按需随意的选择需要自己想要注入的东西。

#### 2.2.3 接口注入 14

- 想要IOC能注入，就必须实现某个接口。该接口提供一个方法让IOC知道怎么为其注入对象。
- 比较死板和繁琐，不是很推荐。

#### 2.2.4 三种注入方式的比较 15

- 接口注入（不提倡）

- 构造注入（一般推荐）依赖很多，参数列表就很长。
- set注入（推荐）缺点就是不能立刻进入就绪状态。

### 2.3 IoC的附加值 15

上面是IOC给我带来的功能：帮我们管理依赖的注入。这里点了一些他所带来的附加的好处。

IOC可以帮助我们解耦各业务对象间依赖关系的绑定方式。

### 2.4 小结 17

主要解决如何申明依赖的问题，介绍几种依赖注入方式。

## 第3章 掌管大局的IoC Service Provider 18

可以粗糙的理解这个IOC Service Provider就是IOC容器。

### 3.1 IoC Service Provider的职责

主要职责就2个：

- 业务对象的构建和管理
- 业务对象的依赖绑定

### 3.2 运筹帷幄的秘密——IoC Service Provider如何管理对象间的依赖关系 

IOC Service Provider需要有地方能记录业务对象之间的依赖关系，才能准确的注入。

有下面几种方式可以来存储到这些依赖管理的配置信息：

#### 3.2.1 直接编码方式 19

直接代码中将对象注册到容器中。

#### 3.2.2 配置文件方式 20

通过配置文件（主要是XML）方式配置依赖关系。

#### 3.2.3 元数据方式 21

代表实现是Google Guice。其实也就是相当于后面的Spring的注解方式。

### 3.3 小结 21

IOC容器的主要职责2个：1. 创建bean 2. 绑定bean之间的依赖关系

## 第4章 Spring的IoC容器之BeanFactory 22

- Spring的IOC容器其实就是一个IOC Service Provider
- Spring提供了两种容器类型：**BeanFactory和ApplicationContext**。
  - BeanFactory
    - **顾名思义，就是生产Bean的工厂。是一个工厂！**
    - 完整的IOC服务支持
    - 默认bean是**延迟加载**的
    - 所以容器启动速度快，资源消耗比较小。
  - ApplicationContext
    - 基于BeanFactory构建，更高级的容器实现
    - 提供了其他高级特性，比如事件发布、国际化信息支持等
    - **不是懒加载的**，容器启动了，那么所有的对象都是已经就绪的。
    - 所以容器启动时间长，占用的系统资源高。

### 4.1 拥有BeanFactory之后的生活 24

我们只需要**配好图纸**（xml配置依赖关系或者其他的方式），然后让BeanFactory依据图纸来创建bean和注入依赖即可，**需要某个对象的时候，我们可以直接向BeanFactory索取。**

### 4.2 BeanFactory的对象注册与依赖绑定方式 26

BeanFactory就是一个IOC Service Provider，所以BeanFactory也支持那三种方式来管理注入配置信息。

#### 4.2.1 直接编码方式 26

BeanFactory底层是怎么运作的：

![image-20200519135244225](/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200519135244225.png)

- BeanFactory是一个接口，只是提供了如何访问容器内Bean的方法。
- BeanDefinitionRegistry接口定义了Bean的抽象的注册逻辑。就是容器注册Bean需要的信息的一个抽象。
- 类比：BeanFactory是一个图书馆，书就是Bean。书要放在书架上，书架就是BeanDefinitionRegistry。（**这个比喻不是很好，应该说BeanDefinitionRegistry相当于图书馆的一个名册，名册里面的每一条记录都是一个BeanDefinition**）
- **BeanDefinition的实例负责保存对象的所有必要信息，包括其对应的对象的class类型、是否是抽象 类、构造方法参数以及其他属性等**

#### 4.2.2 外部配置文件方式 28

- Spring的IOC容器支持两种配置文件格式：Properties文件格式和XML文件格式
- 具体流程
  - 需要一个BeanDefinitionReader实现类，来将配置文件的内容读取并映射到BeanDefinition中。
  - 生成的BeanDefinition再注册到一个BeanDefinitionRegistry完成Bean的注册和加载。

##### Properties配置格式的加载

Spring提供了 org.springframework.beans.factory.support.PropertiesBeanDefinitionReader类用于Properties格式配置文件的加载，我们不用自己去实现BeanDefinitionReader。

##### XML配置格式的加载

XML配置格式是Spring支持最完整，功能最强大的表达方式。因为XML良好的语义表达能力。

Spring提供了XmlBeanDefinitionReader来支持XML的Reader实现。

```java
public static BeanFactory bindViaXMLFile(BeanDefinitionRegistry registry) {
    XmlBeanDefinitionReader reader = new XmlBeanDefinitionReader(registry);
    reader.loadBeanDefinitions("classpath:../news-config.xml");
    return (BeanFactory) registry;
    // 或者直接 //return new XmlBeanFactory(new ClassPathResource("../news-config.xml")); 
}
```
- **如上所提过的：BeanDefinitionRegistry其实就是保存了所有Bean的地方了，所以我们可以理解具有工厂最核心的东西了，而BeanFactory只是提供了访问Bean的方法实现。所以(BeanFactory) registry 可以强转。**

#### 4.2.3 注解方式 31

- Spring 2.5之前没有正式支持基于注解方式的依赖注入
- 注解是Java 5之后才引入的
- 只适用于应用程序使用了Spring 2.5以及Java 5及更高版本。

```java
@Component
public class FXNewsProvider {
    @Autowired private IFXNewsListener newsListener;
    @Autowired private IFXNewsPersister newPersistener;
    public FXNewsProvider(IFXNewsListener newsListner, IFXNewsPersister newsPersister) {
            this.newsListener = newsListner;
            this.newPersistener = newsPersister;
        }...
}
@Component public class DowJonesNewsListener implements IFXNewsListener {
    ...
}
@Component public class DowJonesNewsPersister implements IFXNewsPersister {
    ...
}
```

- @Autowired 告诉Spring容器需要为当前对象注入哪些对象。
- @Component则是配合Spring 2.5中新的classpath-scanning功能使用的，配置扫描bean的路径的。

### 4.3 BeanFactory的XML之旅 33

平时我已经不怎么使用XML了，这节简单过过了。

#### 4.3.1 beans和bean 33

- `<beans> `是XML配置文件中最顶层的元素，是所有`<bean>`的“统帅”。
- 有一堆可配置项：default-lazy-init，default-autowire 等等。

#### 4.3.2 孤孤单单一个人 35

一个单独bean的配置：

```xml
<bean id="djNewsListener" class="..impl.DowJonesNewsListener">
</bean>
```

可配置：

- id，bean区分的唯一标识，也可以省略。
- name的作用跟使用alias为id指定多个别名基本相同
- class指定其类型，大部分是必须的。

#### 4.3.3 Help Me， Help You 36

如何表达对象之间的依赖性。

- 构造注入

  - ```xml
    <bean id="djNewsProvider" class="..FXNewsProvider">
    	<constructor-arg>
    		<ref bean="djNewsListener"/>
    	</constructor-arg>
    	<constructor-arg>
    		<ref bean="djNewsPersister"/>
    	</constructor-arg>
    </bean>
    ```

  - type：有多个构造函数的时候，可以通过type指定参数类型，来确定使用哪个构造函数。

    - ```java
      public MockBusinessObject(String dependency) {
          this.dependency1 = dependency;
      }
      public MockBusinessObject(int dependency) {
          this.dependency2 = dependency;
      }
      <bean id="mockBO" class="..MockBusinessObject">
      	<constructor-arg type="int">
      		<value>111111</value>
      	</constructor-arg>
      </bean>
      ```

  - index：构造方法同时传入了多个类型相同的参数，使用index来确定顺序。

    - ```xml
      public MockBusinessObject(String dependency1,String dependency2)
      ---
      <bean id="mockBO" class="..MockBusinessObject">
      	<constructor-arg index="1" value="11111"/>
      	<constructor-arg index="0" value="22222"/>
      </bean>
      ```

-  setter注入
  
  - Spring为setter方法注入提供了`<property>`元素。
  
  - ```xml
      <bean id="djNewsProvider" class="..FXNewsProvider">
      	<property name="newsListener">
          //name 就是变量名称
      		<ref bean="djNewsListener"/>
      	</property>
      	<property name="newPersistener">
      		<ref bean="djNewsPersister"/>
      	</property>
      </bean>
      ```
  
  - 如果只是使用`<property>`进行依赖注入的话，请确保你的对象提供了**默认的构造方法**。
  
- `<property>`和`<constructor-arg>`中可用的配置项
  
    - 一堆可用配置项，这里只挑选重点
    - depends-on
      - 当用ref时候让A依赖于B，需要这个保证B先于A实例化。
    - autowire
      - 通过ref这些都是明确的进行bean的绑定，autowire是可以自动绑定。
      - 有5种绑定方式
        - no：就是手动ref来绑定，不采用自动绑定
        - byName：按照声明的实例变量的名来绑定
        - byType：依赖对象的类型进行绑定
        - constructor：针对构造方法参数的类型而进行的自动绑定，采用的是byType类型的绑定模式。按照参数的类型。
        - autodetect：如果对象拥有默认无参数的构造方法，容器会优先考虑byType的自动绑定模式。否则，会使用constructor模式。
    - dependency-check
      - 帮我们检查每个对象某种类型的所有依赖是否全部已经注入完成
    - lazy-init
      - 主要针对ApplicationContext容器，让bean延迟加载。

#### 4.3.4 继承？我也会！ 50

```xml
<bean id="superNewsProvider" parent="newsProviderTemplate" class="..FXNewsProvider">
	<property name="newsListener">
		<ref bean="djNewsListener"/>
	</property>
</bean>
```

使用parent标签来指定父类。

#### 4.3.5 bean的scope 51

scope用来声明容器中的对象所应该处的限定场景或者说该对象的存活时间，即容器在对象进入其 相应的scope之前，生成并装配这些对象，在该对象不再处于这些scope的限定之后，容器通常会销毁这些对象。

**singleton**

默认的scope，与IoC容器“几乎”拥有相同的“寿命”。同一个容器中只存在一个共享实例。

**prototype**

在接到该类型对象的请求的时候，会每次都重新 生成一个新的对象实例给请求方。请求方需要自己负责当前返回对象的后继生命周期的管理工作，包括该对象的销毁。

**request、session和global session**

只适用于Web应用程序，通常是与XmlWebApplicationContext共同使用。

- request

  - ```xml
    <bean id="requestProcessor" class="...RequestProcessor" scope="request"/>
    ```

  - 为每个HTTP请求创建一个全新的 RequestProcessor对象供当前请求使用，当请求结束后，该对象实例的生命周期即告结束。

- session

  - ```xml
    <bean id="userPreferences" class="com.foo.UserPreferences" scope="session"/>
    ```

  - 为每个独立的session创建属于它们自己的全新的 UserPreferences对象实例。比request scope的bean可能更长的存活时间，其他方面没什么差别。

- global session

  - ```xml
    <bean id="userPreferences" class="com.foo.UserPreferences" scope="globalSession"/>
    ```

  - global session只有应用在基于portlet的Web应用程序中才有意义，它映射到portlet的global范围的 session。如果在普通的基于servlet的Web应用中使用了这个类型的scope，容器会将其作为普通的session 类型的scope对待。

##### 自定义scope类型

需要给出一个Scope接口的实现类，接口定义中的4个方法并非都 是必须的，但get和remove方法必须实现。

#### 4.3.6 工厂方法与FactoryBean 56

**我们为什么要工厂方法？**看例子：

```java
public class Foo {
    private BarInterface barInstance;
    public Foo() {
        // 我们应该避免这样做
        // instance = new BarInterfaceImpl(); } // ..
    }
}
```

这里面存在耦合关系，虽然我们使用接口BarInterface的引用避免了对某个具体实现类的耦合，但是实例化的时候，还是没有避免对具体实现类BarInterfaceImpl的依赖。

这如果是我们自己写的代码中的类倒也没有多大的问题，但是如果是第三方的，实例化第三方的相关类，这种耦合就应该避免。这时候就应该使用工厂方法来代替实例化。而业务类依赖工厂就行了，从而实现解耦。

Spring对工厂方法来实例化Bean也提供了支持：

**静态工厂方法**

```xml
<bean id="bar" class="...StaticBarInterfaceFactory" factory-method="getInstance"/>
```

getInstance的返回值就是这个bean。

**非静态工厂方法**

```xml
<bean id="barFactory" class="...NonStaticBarInterfaceFactory"/>
<bean id="bar" factory-bean="barFactory" factory-method="getInstance"/>
```

先创建工厂这个Bean。然后通过工厂这个Bean来指定方法返回我们需要的Bean。

> 原因也好理解。静态的工厂方法，我们可以使用类直接调用，所有不需要先创建工厂Bean。

##### FactoryBean

是一个Bean，是Spring容器提供的一种可以扩展容器对象实例化逻辑的接口。

当我们配置宁愿Java代码来实例化Bean也不愿意用xml来配置（XML配置过于繁杂）。或者，某些第三方库不能直接注册到Spring容器中时候，我们就可以自己实现FactoryBean来自己手动实例化对象。上面的直接写工厂方法也是可以的，但是FactoryBean接口是Spring专门定制的。

使用：

实现FactoryBean接口即可。

```java
public interface FactoryBean {
  Object getObject() throws Exception; 
  Class getObjectType(); 
  boolean isSingleton();
}
```

- getObject()
  - 返回该FactoryBean“生产”的对象实例，我们需要实现该方法以给出自己 的对象实例化逻辑；
- getObjectType()
  - 返回的对象的类型
- isSingleton()
  - 是否单例

然后配置xml，这个FactoryBean就将getObject的Bean注入到容器中了。

```xml
<bean id="nextDayDate" class="...NextDayDateFactoryBean"> </bean>
```

> 一定要取得FactoryBean本身的话，可以通过在bean定义的id之前加前缀&来达到目的。
> container.getBean("&nextDayDate");

##### **FactoryBean和BeanFactory**

所以FactoryBean和BeanFactory的区别：

FactoryBean是Spring提供的一个接口，为了方便我们自己代码来实例化某些Bean的。他的本质是一个Bean。

BeanFactory也是一个接口，但是它的实现类是Spring的容器。他不是Bean而是容器。

#### 4.3.7 偷梁换柱之术 61

当一个Bean A 引用Bean B的时候，如果Bean B配置多例，Bean A配置单例那么每次获取A的时候，A里面的B是不会变的。为了解决这个问题，Spring提供了一些方案：

##### 方法注入

解决方案就是保证getNewBean调用的时候每次都返回新的对象，spring通过方法注入是通过CGLib代理为我们生成子类，来修改返回的逻辑，所以getNewBean函数需要符合下面规范：

```java
<public|protected> [abstract] <return-type> theMethodName(no-arguments);
```

然后对应xml配置下就行了

```xml
<bean id="newsBean" class="..domain.FXNewsBean" singleton="false"> </bean> 
<bean id="mockPersister" class="..impl.MockNewsPersister"> 
  <lookup-method name="getNewsBean" bean="newsBean"/> 
</bean>
```

lookup-method标签来方法注入。

让每次调用都让容器返回新的对象实例，除了方法注入还有下面2中方式：

**使用BeanFactoryAware接口**

Spring框架提供了一个BeanFactoryAware接口，容器在实例化实现了该接口的bean定义的过程中，会自动将容器本身注入该bean。【**就是让改Bean内部持有BeanFactory容器引用**】

这样我们可以通过Bean获取容器，然后再走容器去getNewBean。

**使用ObjectFactoryCreatingFactoryBean**

ObjectFactoryCreatingFactoryBean 是Spring提供的一个 FactoryBean 实现。

实际上，ObjectFactoryCreatingFactoryBean实现了BeanFactoryAware接口，它返回的ObjectFactory实例只是特定于与Spring容器进行交互的一个实现。使用它的好处就是，隔离了客户端对象对BeanFactory的直接引用。

不详细讲了。

**方法替换**

方法替换可以帮助我们实现简单的方法拦截功能。

实现org.springframework.beans.factory.support.MethodReplacer接口，配置xml方法替换

```xml
<bean id="djNewsProvider" class="..FXNewsProvider">
<replaced-method name="getAndPersistNews" replacer="providerReplacer"></replaced-method> </bean>
<bean id="providerReplacer" class="..FXNewsProviderMethodReplacer"> </bean>
```

### 4.4 容器背后的秘密 66【重要】

#### 4.4.1 “战略性观望” 66

Spring的IOC容器实现可以分为两个阶段：**容器启动阶**段和**Bean实例化阶段**。

![image-20200527011124369](/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200527011124369.png)

充分运用这2个阶段的不同特点，Spring在每个阶段都为我们提供了扩展点。以便我们可以根据具体场景的需要加入自定义的扩展逻辑。

**容器启动阶段**

- 通过某种途径加载Configuration元数据。
- BeanDefinitionReader对这些配置元数据进行解析成BeanDefinition。
- 将BeanDefinition注册到BeanDefinitionRegistry

所以容器启动阶段主要就是抽取Bean信息的。【理解为准备好图纸】

**Bean实例化阶段**

- getBean或者Bean依赖需要的时候触发实例化。
- 根据注册的 BeanDefinition所提供的信息实例化被请求对象。
- 为其注入依赖。
- 如果该对象实现了某些回调接口，也会根据回调接口的要求来装配它。

【可以理解为按照图纸来生产Bean】

#### 4.4.2 插手“容器的启动” 67

前面说了Spring给我们在每个阶段都提供了扩展（主要就是提供了各种PostProcessor）。容器启动阶段是BeanFactoryPostProcessor。

【这些都是我们插手进Spring一些内部过程中了，一般场景用不到，属于定制自己的容器实现了，别乱玩】

##### BeanFactoryPostProcessor【重要】

【注意是BeanFactory，之所以重要这个东西是源码中比较核心的东西】

让我们在**实例化对象之前**，容器启动过程中对注册到容器的BeanDefinition所保存的信息做相应的修改，比如修改其中bean定义的某些属性，为bean定义增加其他信息等。

自定义自己的逻辑只需要实现`org.springframework. beans.factory.config.BeanFactoryPostProcessor`接口即可。

一个容器可能拥有多个BeanFactoryPostProcessor，可以通过**Ordered接口**来控制这些PostProcessor的执行顺序。

**应用**

针对创建的容器是BeanFactory还是ApplicationContext不同，使用方式也有差异：

- BeanFactory

  - 需要我们手动应用所有的BeanFactoryPostProcessor

  - ```java
    // 声明将被后处理的BeanFactory实例 
    ConfigurableListableBeanFactory beanFactory = new XmlBeanFactory(...); 
    // 声明要使用的BeanFactoryPostProcessor:PropertyPlaceholderConfigurer 
    propertyPostProcessor = new PropertyPlaceholderConfigurer(); propertyPostProcessor.setLocation(new ClassPathResource("...")); 
    // 执行后处理操作!!!
    propertyPostProcessor.postProcessBeanFactory(beanFactory);
    ```

  - 因为BeanFactory相当于只有容器启动阶段，是ApplicationContext的一部分，所以Spring不会自动扫描需要我们手动配置

- ApplicationContext

  - 会自动识别配置文件中的BeanFactoryPostProcessor并应用。所以只要注册到容器中，Spring就可以扫描并执行。

**Spring自己的一些实现**

- PropertyPlaceholderConfigurer
  - 允许我们在XML配置文件中使用占位符。在被应用时候，会使用properties配置文件中的配置信息来替换相应BeanDefinition中占位符所表示的属性值。
- PropertyOverrideConfigurer
  - 容器中配置的任何你想处理的bean定义的property信 息进行覆盖替换。
  - 就是可以覆盖BeanDefinition中配置的property属性值（如user.age原来设置100，改成200）
- CustomEditorConfigurer
  - 对BeanDefinition没有做任何变动。
  - 只是辅助性地将后期会用到的信息注册到容器。比如传达xml中String类型映射到Bean对象中具体对象的转换信息（具体转换操作它不管，比如下面PropertyEditor是负责转换的）。

**PropertyEditor**

- Spring内部通过JavaBean的PropertyEditor来帮助进行String类型到其他类型的转换工作。

- 大部分位于`org.springframework.beans.propertyeditors`包。

- Spring自身实现的一些PropertyEditor：StringArrayPropertyEditor，ClassEditor等。

- **自定义PropertyEditor**【用的比较多】

  - 比如系统这个部分需要yyyy-MM-dd的形式，那个部分又需要以yyyyMMdd的形式。还有一个对象日期给的是2007/10/16格式配置，我们Spring内部是没有支持这种字符串转为Date类型的，就需要我们来定义PropertyEditor。

  - 可以直接实现java.beans.PropertyEditor接口，通常直接继承java.beans.PropertyEditorSupport以避免要实现PropertyEditor接口所有的方法。

  - ```java
    public class DatePropertyEditor extends PropertyEditorSupport {
        private String datePattern;
        @Override
        public void setAsText(String text) throws IllegalArgumentException {
            DateTimeFormatter dateTimeFormatter = DateTimeFormat.forPattern(getDatePattern());
            Date dateValue = dateTimeFormatter.parseDateTime(text).toDate();
            setValue(dateValue);
        }
        public String getDatePattern() {
            return datePattern;
        }
        public void setDatePattern(String datePattern) {
            th is.datePattern = datePattern;
        }
    }
    // 注入到CustomEditorConfigurer这个Processor上
    <bean class="org.springframework.bean s.factory.config.CustomEditorConfigurer">
    	<property name="customEditors">
    		<map>
    			<entry key="java.util.Date">
    				<ref bean="datePropertyEditor"/>
    			</entry>
    		</map>
    	</property>
    </bean>
    ```

  - 我们自己实现的PropertyEditor还需要注入到CustomEditorConfigurer的customEditors属性中（Spring2.0之前这么使用，之后提倡使用propertyEditorRegistrars属性来指定自定义的PropertyEditor）。

  - ```java
    public class DatePropertyEditorRegistrar implements PropertyEditorRegistrar 
    ```

  - 【这个用到时候参考书吧，主要就是类型转换的时候想到这个东西就行。】

#### 4.4.3 了解bean的一生 74

getBean()方法是触发Bean实例化阶段的开端，ApplicationContext也是在内部调用getBean完成所有的实例化的（可以看AbstractApplicationContext的refresh方法）。

##### Bean的一生【重要】

**实例化过程如图：【重要】**

![image-20200527021701642](/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200527021701642.png)

- 采用策略模式决定何种方式实例化bean。【注意区分实例化和初始化，在Spring需要区分开来】
  - 通过反射或者CGLIB动态字节码生成来初始化相应的bean实例或者动态生成其子类。
    - InstantiationStrategy定义是实例化策略抽象接口。
    - 子类SimpleInstantiationStrategy实现了简单的对象实例化功能，通过反射来实例化，但不支持方法注入方式的对象实例化。
    - CglibSubclassingInstantiationStrategy继承SimpleInstantiationStrategy通过CGLIB 的动态字节码生成子类满足了方法注入所需的对象实例化需求。
    - **默认**情况下，容器内部**采用的是CglibSubclassingInstantiationStrategy**。
- 不返回构造的实例，而返回包装类：BeanWrapper，到此都还是**处于实例化阶段**。我们后面的都是通过其实现类BeanWrapperImpl来对Bean进行各种操作，比如CustomEditorConfigurer进行配置属性值的类型转换。【这步骤应该主要就是BeanFactoryPostProcessor的操作】
- 设置Aware接口
  - 检查当前对象实例是否实 现了一系列的以Aware命名结尾的接口定义。
  - 如果有，将这些Aware接口定义中规定的依赖注入给当前对象实例。【Aware就是向Spring要一些底层的组件】
  - 一些内部Aware：
    - BeanNameAware，BeanClassLoaderAware，BeanFactoryAware（BeanFactory的）。
    - ResourceLoaderAware，ApplicationEventPublisherAware，ApplicationContextAware（App的）。
- **BeanPostProcessor【重要】**
  - BeanPostProcessor是存在于对象初始化阶段。即对Bean的初始化前后（如init-method）进行拦截。
  - 使用BeanPostProcessor的场景，是处理标记接口实现类，或者为当前对象提供代理实现。
  - **ApplicationContext对应的那些Aware接口实际上就是通过BeanPostProcessor的方式进行处理的。**
  - 【这一步和设置Aware其实是交融的】
  - **自定义BeanPostProcessor**
    - 最好写一个接口，标注下来区分这个Processor要处理的Bean类
    - implements BeanPostProcessor
    - 注册到容器
- InitializingBean和init-method【这两个是同等功能，推荐init-method这种方式】
  - InitializingBean接口在对象实例化过程调用过“BeanPostProcessor的前置处理” 之后，会接着检测当前对象是否实现了InitializingBean接口，如果是，则会调用其afterPropertiesSet()方法进一步调整对象实例的状态。【该接口在Spring容器内部广泛使用，但是我们外部使用就有侵入性】
  - bean的init-method就为了减少侵入性的
  - 【主要就是对bean的初始化方法，比如一些环境需要值的设置】
- DisposableBean与destroy-method
  - 一切完毕后，检查是否实现了DisposableBean接口或者指定了destroy-method方法

### 4.5 小结 85

这就对Bean一生进行总结吧：怎么记：

1. getBean先调用构造进行实例化
2. 应用各种BeanPostProcessor
3. 调用init-method
4. 调用destroy-method

## 第5章 Spring IoC容器ApplicationContext 86

ApplicationContext除了拥有 BeanFactory支持的所有功能之外，还进一步扩展了基本容器的功能。包括BeanFactoryPostProcessor、BeanPostProcessor以及其他特殊类型bean的自动识别、容器启动后bean实例的自动初始化、 国际化的信息支持、容器内事件发布等。

Spring为ApplicationContext提供了一些实现：

- FileSystemXmlApplicationContext：文件系统中加载配置
- ClassPathXmlApplicationContext：classpath下加载配置
- XmlWebApplicationContext：用于Web应用程序

### 5.1 统一资源加载策略 86

java提供的java.net.URL只限于网络形式发布的资源的查找和定位工作，不能叫做统一资源定位器。并且资源的查找和资源的表示没有一个清晰的界限。所Spring提出了一套基于 org.springframework.core.io.Resource和 org.springframework.core.io.ResourceLoader接口的资源抽象和加载策略。

#### 5.1.1 Spring中的Resource 87

Resource接口作为所有资源的抽象和访 问接口

Resource接口可以根据资源的不同类型，或者资源所处的不同场合，给出相应的具体实现。这些实现类在org.springframework.core.io包下。

自己定义就实现Resource接口就行了

#### 5.1.2 ResourceLoader，“更广义的URL” 88

查找和定位这些资源的统一抽象

#### 5.1.3 ApplicationContext与ResourceLoader 91

ApplicationContext继承了ResourcePatternResolver，就间接实现了ResourceLoader接口。

所以任何的ApplicationContext实现都可以看作是一个 ResourceLoader甚至ResourcePatternResolver。而这就是ApplicationContext支持Spring内统一资源加载策略的真相。

### 5.2 国际化信息支持(I18n MessageSource) 97

应用程序需要支持它所面向的国家和地区的语言文字，为不同的国家和地区的用户提供他们各自的语言文字信息。这就要国际化支持。

#### 5.2.1 Java SE提供的国际化支持 97

JavaSE国际化信息处理主要就是2个类：

- java.util.Locale
  - 不同的Locale代表不同的国家和地区
- java.util.ResourceBundle。
  - 保存特定于某个Locale的信息

#### 5.2.2 MessageSource与ApplicationContext 98

Spring在Java SE的国际化支持的基础上，进一步抽象了国际化信息的访问接口，提供了org.springframework.context.MessageSource接口。

### 5.3 容器内部事件发布 102

Spring的ApplicationContext容器提供的容器内事件发布功能

#### 5.3.1 自定义事件发布 102

Java SE提供了实现自定义事件发布功能的基础类：java.util.EventObject类和java.util.EventListener接口，我们可以通过扩展EventObject来实现，而事件的监听器则扩展自EventListener。

#### 5.3.2 Spring的容器内事件发布类结构分析 105

Spring的ApplicationContext容器内部以 org.springframework.context.ApplicationEvent的形式发布事件。注册了ApplicationListener类型的Bean会被容器自动识别来监听ApplicationEvent类型的事件。

#### 5.3.3 Spring容器内事件发布的应用 107

Spring的ApplicationContext容器内的事件发布机制，主要用于单一容器内的简单消息通知和处理，并不适合分布式、多进程、多容器之间的事件通知。

### 5.4 多配置模块加载的简化 109

就讲了ApplicationContext对有多个配置文件，加载很方便，只要传入String[]数组就行了。

### 5.5 小结 110

【这章节都不咋重要，用到的时候再看！】

## 第6章 Spring IoC容器之扩展篇 111

### 6.1 Spring 2.5的基于注解的依赖注入 111

#### 6.1.1 注解版的自动绑定(@Autowired) 111

- @Autowired
  - 放在属性上
  - 放在构造函数上
  - 放在方法上
    - 只要该方法定义了需要被注入的参数
- @Qualifier
  - @Qualifier实际上是byName自动绑定的注解版

#### 6.1.2 @Autowired之外的选择——使用JSR250标注依赖注入关系 115

JSR250的@Resource和@PostConstruct以及@PreDestroy

- @Resource
  - 相当于@Autowired+@Qualifier
- @PostConstruct
  - 相当于InitializingBean/init-method
- @PreDestroy
  - 相当于DisposableBean/destroy-method

#### 6.1.3 将革命进行得更彻底一些(class-path-scanning功能介绍) 116

classpath-scanning功能可以从某一顶层 包（base package）开始扫描。当扫描到某个类标注了相应的注解之后，就会提取该类的相关信息，构 建对应的BeanDefinition，然后把构建完的BeanDefinition注册到容器。

### 6.2 Spring 3.0展望 119

现在看都过时了

### 6.3 小结 120

这一章也不重要！

# 第三部分 Spring AOP框架

## 第7章 一起来看AOP 122

Aop是对OOP的一种补足，对于一些系统需求关注的是系统中的横切，比如日志记录，安全检查，事务管理。

OOP看重class，AOP看重Aspect。两者结合才能建立完美的系统。

### 7.1 AOP的尴尬 124

现时代AOP都需要寄生在OOP的体制内。

### 7.2 AOP走向现实 125

AOP是一种理念，和OOP一样，想要实现它也需要某种语言，这些语言统称为AOL。当然这个语言可以和系统实现语言相同。

AspectJ是扩展自Java的一种AOL。还有AspectC/C++等

#### 7.2.1 静态AOP时代 125

就是第一代AOP，**最初的AspectJ**为代表。将Aspect直接以字节码的方式编译进Java类中。但是灵活性差，每次修改就得重新编译。

#### 7.2.2 动态AOP时代 126

第二代AOP，大多都是通过Java提供的各种动态特性来实现Aspect织入到当前系统中。如SpringAOP，JBossAOP，以及**AspectJ融入了AspectWerkz框架后也引入了动态织入**。

这代AOP大多java实现的，并且让Aspect以class的形式融入系统中，便于维护。而织入信息一般都xml形式在外部维护。

### 7.3 Java平台上的AOP实现机制 126

**有哪些方法可以实现AOP**，主要还是前2个。

#### 7.3.1 动态代理 126

JDK1.3之后引入了动态代理机制。

缺点：**类需要实现接口**。

SpringAOP默认采用这种机制。

#### 7.3.2 动态字节码增强 126

为其生成子类，将横切的逻辑加入到这些子类中去。

不需要接口。但是里面申明了final将不能增强。

SpringAOP在无法使用动态代理的时候，会使用CGLIB库的动态字节码增强方式来实现AOP。

#### 7.3.3 Java代码生成 127

EJB使用的，已退休。

#### 7.3.4 自定义类加载器 127

使用自定义类加载器，将横切逻辑加入到class中去。

JBossAOP和AspectJ融入的AspectWerkz就是采用这种方式。

#### 7.3.5 AOL扩展 127

最强大，也最难掌握，【你要是想自己开发个AspectJ，你就去研究吧】

### 7.4 AOP国家的公民 128

AOP框架的一些概念，这里都是以AspectJ的概念。

【这一章都讲的复杂了，好理解的知识点都被讲的本来懂得，被他解释的反而不懂了】

#### 7.4.1 Joinpoint 128

需要进行织入操作的系统执行点叫做JoinPoint

【这里感觉讲的复杂了，系统就是你现在写的业务方法，这些方法有可能需要织入一些逻辑，所以所有的方法都可以说是JoinPoint】

#### 7.4.2 Pointcut 130

一个表达式，这个表达式用来表达，我们在上面的JoinPoint上那些地方进行织入。

#### 7.4.3 Advice 131

这就需要被织入的逻辑了。有多种形式：（这个概念就不需要多解释了）

- Before
- After
- AfterReturning
- AfterThrowing
- Around

#### 7.4.4 Aspect 133

将PointCut和这些Advice联系起来，可以联系是在业务逻辑上横切的一个面。这就是一个概念上的东西，开发时候不会在乎这个。

#### 7.4.5 织入和织入器 133

AspectJ专门的织入器，将逻辑织入到class中，叫做`ajc`。

#### 7.4.6 目标对象 133

被织入的对象就是目标对象。

### 7.5 小结 134

<img src="/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200527175822844.png" alt="image-20200527175822844" style="zoom:67%;" />

## 第8章 Spring AOP概述及其实现机制 135

### 8.1 Spring AOP概述 135

SpringAOP可以完成80%的AOP需求，一般够用了，如果还不能满足你的需求可以使用AspectJ

### 8.2 Spring AOP的实现机制 136

SpringAOP采用的是动态代理机制+字节码生成技术。系统最终使用的是代理后的代理对象。

#### 8.2.1 设计模式之代理模式 136

<img src="/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200527185203012.png" alt="image-20200527185203012" style="zoom: 67%;" />

- ISubject，接口非必须，但是一般意义上得有，更符合代理模式
- SubjectImpl，需要被代理的对象
- SubjectProxy，代理对象，内部持有ISubjec的引用，引用SubjectImpl对象。

这种代理如果实现AOP可想而知多少类，多少代码去实现。

#### 8.2.2 动态代理 139

JDK的动态代理：java.lang.reflect.Proxy和java.lang.reflect.InvocationHandler2个接口。

缺点：必须要有Interface，不然无法使用动态代理。

**SpringAOP发现目标对象实现了接口，就会采用动态代理的方式为其生成代理对象。如果目标对象没有实现任何接口会采用CGLIB方式。**

#### 8.2.3 动态字节码生成 141

为目标对象类生成子类的方式，将横切逻辑放到子类中。

唯一的限制就是无法对final方法进行覆写。

### 8.3 小结 142

## 第9章 Spring AOP一世 143

### 9.1 Spring AOP中的Joinpoint 143

SpringAOP仅支持方法级别的JoinPoint

原因：

- 方法就基本满足我们AOP需求了。
- 字段级别的JointPoint就破坏了面向对象的封装。

### 9.2 Spring AOP中的Pointcut 144

Pointcut接口定义如下：

```java
public interface Pointcut {
    Pointcut TRUE = TruePointcut.INSTANCE;
    ClassFilter getClassFilter();
    MethodMatcher getMethodMatcher();
}
```

该接口定义了2个方法来捕捉系统中的JoinPoint，并提供了一个TruePointcut实例。

**ClassFilter接口**

对JoinPoint所处的对象进行class级别类型匹配

```java
public interface ClassFilter {
    ClassFilter TRUE = TrueClassFilter.INSTANCE;
    boolean matches(Class<?> var1);
}
```

Pointcut的实现类如果getClassFilter返回的是TrueClassFilter，那么就是针对对所有的目标类

**MethodMatcher接口**

对JoinPoint所处的对象进行方法级别类型匹配

```java
public interface MethodMatcher {
    MethodMatcher TRUE = TrueMethodMatcher.INSTANCE;
    boolean matches(Method var1, Class<?> var2);
    boolean isRuntime();
    boolean matches(Method var1, Class<?> var2, Object... var3);
}
```

有2个matches方法。区别就是拦截的时候是否检查传入的参数。这2个通过isRuntime来区分：

- isRuntime返回false，表示不考虑参数，这种类型的MethodMatcher称为StaticMethodMatcher。
  - 该matcher不用每次都检查参数（执行第一个match），所以匹配的结果可以被缓存，性能高.
- isRuntime返回true，表示不考虑参数，这种类型的MethodMatcher称为DynamicMethodMatcher。
  - 该matcher结果不能缓存，性能差，所以避免使用
  - 先判断isRuntime，然后先执行第一个matches，如果返回true，进一步执行第二个mathes。

在MethodMatcher类型的基础上，Pointcut也可以被分为2类：

- StaticMethodMatcherPointcut
- DynamicMethodMatcherPointcut

族谱图：

<img src="/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200528030355566.png" alt="image-20200528030355566" style="zoom:67%;" />

#### 9.2.1 常见的Pointcut 146

##### NameMatchMethodPointcut

- StaticMethodMatcherPointcut
- 只对方法名字进行匹配，可以使用统配符

##### JdkRegexpMethodPointcut

- StaticMethodMatcherPointcut
- 正则进行匹配，正则匹配的是带方法的全限定类名，不是只匹配方法名

##### AnnotationMatchingPointcut

- 依据目标对象中是否有指定注解来匹配Joinpoint

##### ComposablePointcut

- 进行Pointcut逻辑运算的实现

##### ControlFlowPointcut

- 匹配程序的调用流程，就是只有一系列方法执行流程满足的时候才匹配。
- 不是很常用。

#### 9.2.2 扩展Pointcut(Customize Pointcut) 151

自定义Pointcut只需要按照需要实现StaticMethodMatcherPointcut和DynamicMethodMatcherPointcut即可

#### 9.2.3 IoC容器中的Pointcut 152

Pointcut如果需要依赖，或者别人需要他，也要注入到容器中，但是SpringAOP一般不会直接将其注入容器，公开给容器对象使用！后面会解释。

### 9.3 Spring AOP中的Advice 153

<img src="/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200529015748206.png" alt="image-20200529015748206" style="zoom:67%;" />

根据Advice实例能否在目标对象类的所有实例中共享，分为2大类：per-class类型和per-instance类型

#### 9.3.1 per-class类型的Advice 153

该类Advice的实例可以在目标对象类的所有实例中共享。该类Advice通常只提供方法拦截功能，不会为目标对象保存状态或者添加新特性。

上图的所有Advice都是pre-class的Advice。

- BeforeAdvice

我们实现BeforeAdvice只需要实现MethodBeforeAdvice接口就行，BeforeAdvice是一个空接口（考虑将来的扩展，可以对属性级别进行BeforeAdvice）

```java
public interface MethodBeforeAdvice extends BeforeAdvice {
    void before(Method var1, Object[] var2, @Nullable Object var3) throws Throwable;
}
```

我们可以使用该Advice来做资源初始化或者其他的一些准备工作。

- ThrowsAdvice

ThrowsAdvice也是一个空接口，但是我们实现的时候定义方法要满足

```java
void afterThrowing(Method, args, target, ThrowableSubclass) //参数表明了ThrowsAdvice可以获取到目标放的参数
```

前面三个参数可以省略，一个实现类里面可以定义多个afterThrowing方法，框架会反射去调用。

ThrowsAdvice一般用于对系统中特定异常进行监控。

- AfterReturningAdvice

```java
public interface AfterReturningAdvice extends AfterAdvice {
    void afterReturning(@Nullable Object returnValue, Method method, Object[] args, @Nullable Object target) throws Throwable;
}
```

可以访问方法返回值，方法，方法参数，目标对象。虽然可以访问到方法的返回值，但是不能修改。

- AroundAdvice

SpringAOP没有提供AfterAdvice【?新的有了？】使用的AOP联盟的：

```java
package org.aopalliance.intercept;
public interface MethodInterceptor extends Interceptor {
    Object invoke(MethodInvocation var1) throws Throwable;
}
```

#### 9.3.2 per-instance类型的Advice 159

该类Advice不会在目标类所有对象上共享，而是每个对象都有自己的一个，并未每个对象保存他们各自的状态以及相关逻辑。

SpringAOP中，Introduction是唯一的pre-instance型Advice。

Introduction可以在不改变目标类情况下，为目标类添加新的属性和行为。

```java
package org.springframework.aop;
import org.aopalliance.intercept.MethodInterceptor;
public interface IntroductionInterceptor extends MethodInterceptor, DynamicIntroductionAdvice {
}
```

我们很少去实现这个接口，多数直接用Spring给我们提供的2个接口即可：

- DelegatingIntroductionInterceptor
- DelegatePerTargetObjectIntroductionInterceptor

【这个不咋用，就先过了】

### 9.4 Spring AOP中的Aspect 163

在Pointcut和Advice都准备好了，就应该分门别类的装进Aspect中。

Spring最初没有Aspect概念，而是Advisor，但是Advisor通常只持有一个Pointcut和一个Advice，而Aspect是多个，所以Advisor是一种特殊的Aspect。

#### 9.4.1 PointcutAdvisor家族 164

PointcutAdvisor接口是实际定义了一个Pointcut和一个Advice的Advisor。

<img src="/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200529025154735.png" alt="image-20200529025154735" style="zoom:67%;" />

几个常用的Advisor实现：

**DefaultPointcutAdvisor**

最通用实现，任何类型的Pointcut和Advice都可以由其来指定。

```java
public DefaultPointcutAdvisor(Pointcut pointcut, Advice advice) 
public void setPointcut(@Nullable Pointcut pointcut)
public void setAdvice(Advice advice)
```

**NameMatchMethodPointcut**

细化后的DefaultPointcutAdvisor。限定Pointcut类型只能是NameMatchMethodPointcut。

**RegexpMethodPointcutAdvisor**

限定了Pointcut类型只能是AbstractRegexpMethodPointcut

**DefaultBeanFactoryPointcutAdvisor**

使用较少，主要作用：我们可以通过Advice注册到IOC容器的beanName来关联Advice，只有在Pointcut匹配成功后才去实例化对应Advice。

#### 9.4.2 IntroductionAdvisor分支 167

和PointcutAdvisor本质不同，就是它只能应用类级别的拦截，并且只能使用Introduction型的Advice。

#### 9.4.3 Ordered的作用 168

如果不为Advisor指定顺序，那么Spring的默认顺序可能导致一些意外发生。

这里举了个例子：权限校验和异常拦截的例子，挺好的，可以去仔细看看。

使用Order来设置Advisor优先级，**Order值越大，优先级越低**。

### 9.5 Spring AOP的织入 170

上面讲了我们已经准备好了Pointcut以及Advice并将其拼装到了Aspect中。下面就是如何注入到目标的对象中。

AspectJ采用的是ajc编译器进行织入，JBOSSAOP采用的是ClassLoader，**SpringAOP使用的是ProxyFactory作为织入器**。

#### 9.5.1 如何与ProxyFactory打交道 170

ProxyFactory是SpringAop最基本的一个织入器实现（但不是唯一一个）。

使用：

```java
ProxyFactory weaver = new ProxyFactory();
weaver.setTarget(targetObj);
Advisor advisor = ...;
weaver.addAdvisor(advisor);
Object proxy = weaver.getProxy();
```

传入目标对象，指定advisor就可以获取到代理类（SpringAop是基于代理的，所以返回的都是代理类对象）。

- 基于接口的代理
  - ProxyFactory有个setInterfaces()可以明确对目标类使用哪个接口进行代理。
  - 但是，实际如果目标类只要实现接口，并且我们没有将optimize和proxy-TargetClass两 个属性设置为true，那么都会使用接口代理方式。

> 注意动态代理：A为接口，B为实现类，C为代理B的代理类，那么C是无法强转B的。可以打印C的class是Proxyxxx的，B和C都可以墙砖为A

- 基于类的代理
  - 如果没有实现任何接口，默认采用CGLIB代理。最后的代理对象的class是基于CGLIB的
  - 如果实现了接口，我们也可以强制使用基于类的代理方式，可以setProxyTargetClass为true或者设置optimize设置为true。
  - 总结：什么时候使用GCLIB代理（下面满足任何一个即可）
    - 没有实现接口
    - setProxyTargetClass为true
    - optimize为true

#### 9.5.2 看清ProxyFactory的本质 175

看看ProxyFactory是如何工作的：

![image-20200531165856520](/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200531165856520.png)

结合上面这个图来说话：

**先从根说起**：org.springframework.aop.framework.AopProxy：

```java
public interface AopProxy {
    Object getProxy();
    Object getProxy(@Nullable ClassLoader var1);
}
```

这个接口是Spring框架为不同代理实现机制的抽象，SpringAOP框架内部提供了两种实现：

- CglibAopProxy：针对CGLIB代理的实现
- JdkDynamicAopProxy：针对JDK动态代理的实现

而这2种实现的**实例化的过程是由AopProxyFactory完成**的（具体是其实现类DefaultAopProxyFactory来做的）。

```java
public interface AopProxyFactory {
	AopProxy createAopProxy(AdvisedSupport config) throws AopConfigException;
}
```

AopProxyFactory依据AdvisedSupport实例提供相关信息来决定生成什么类型的AopProxy。它只有一个实现类：DefaultAopProxyFactory。

```java
public class DefaultAopProxyFactory implements AopProxyFactory, Serializable {
  public AopProxy createAopProxy(AdvisedSupport config) throws AopConfigException {
      if (config.isOptimize() || config.isProxyTargetClass() || hasNoUserSuppliedProxyInterfaces(config)) {    
         	//创建CGLIB代理
          return new ObjenesisCglibAopProxy(config);  //ObjenesisCglibAopProxy extends CglibAopProxy 
      }
      else {
         //创建JDK动态代理
         return new JdkDynamicAopProxy(config);
      }
   }
}
```

这个类的实现逻辑就是，判断config的isOptimize，isProxyTargetClass，还有有没有实现接口，然后决定使用什么进行代理。

这里面主要依靠AdvisedSupport来决定使用什么代理，所以**进一步看AdvisedSupport：**

![image-20200601155444236](/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200601155444236.png)

AdvisedSupport是生成代理对象所需要的信息载体，主要分2个部分：

- ProxyConfig：记载生成代理对象的控制信息
  - ProxyConfig其实就是一个简单POJO的javaBean，里面有5个属性：
  
  -  ```java
  public class ProxyConfig implements Serializable {
     //如果设置true，ProxyFactory会使用CGLIB代理
     private boolean proxyTargetClass = false;
     //告诉代理对象是否采取进一步优化措施，并且如果设置true，ProxyFactory会使用CGLIB代理
     private boolean optimize = false;
     //控制代理对象是否可以强转为Advised类型，默认false表示可以。
   boolean opaque = false;
     //让SpringAOP生成代理对象的时候，将该对象绑定到ThreadLocal。如果目标对象需要访问当前代理对象可以通过AopContext.currentProxy()获得
     boolean exposeProxy = false;
     //生成代理对象的一些配置一旦完成就不允许更改
     private boolean frozen = false;
    }
    ```
    
  - 这些就是控制代理对象生成的一些属性。


- Advised：记载生成对象所需要的必要信息，比如目标类，Advice，Advisor等。

  - 这个才是关键，并且默认情况下，我们的代理对象都可以强转为Advised来查询代理对象的相关信息。
  -  我们可以通过这个接口访问代理对象的所有持有的Advisor并操作（一般都在测试场景）。

理一下这些关系：【这个类图并不是实际的类图，而是便于理解的】

<img src="/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200601163919202.png" alt="image-20200601163919202" style="zoom:67%;" />

- ProxyFactory是生成代理Bean的工厂，客户端直接使用的工厂。
- 我们将一些信息设置给ProxyFactory，ProxyFactory就将这些信息封装到AopProxy和AdvisedSupport两个大块
- AopProxy负责什么方式生成代理
- AdvisedSupport负责代理生成的必须信息
- ProxyFactory继承ProxyCreatorSupport，ProxyCreatorSupport是将生成代理公用逻辑抽取出来的一个类。也就是ProxyFactory的主要实现还是看ProxyCreatorSupport。

ProxyFactory只是最基本的织入器。它还要一些兄弟，下图可见，这些兄弟一些也是继承了ProxyCreatorSupport的。

![image-20200601164505606](/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200601164505606.png)

#### 9.5.3 容器中的织入器——ProxyFactoryBean 179

**ProxyFactory**是让我们**脱离容器**来使用SpringAOP功能的，而IOC**容器中**我们使用**ProxyFactoryBean**作为织入器。

**ProxyFactoryBean的本质**

**ProxyFactoryBean是一个生产Proxy的FactoryBean**，他是一个FactoryBean。所以当IOC容器依赖ProxyFactoryBean的时候，返回的是getObject的返回值对象（就是目标类的代理对象）。

#### 9.5.4 加快织入的自动化进程 185

如果目标对象很多，那么我们一个个配置ProxyFactoryBean很累，很麻烦，所以要找到更简洁的方式。

SpringAOP提供了自动代理机制简化这配置流程：原理是正在IOC容器的BeanPostProcessor上，我们提供一个BeanPostProcessor，让对象实例化的时候为其生成代理对象并返回。（所以，这个自动化机制一定是基于在IOC容器之上）

两个常用的AutoProxyCreator：BeanNameAutoProxyCreator和DefaultAdvisorAutoProxyCreator

- BeanNameAutoProxyCreator
  - 指定容器中一组beanName作为目标对象，然后将拦截器作用在上面。
- DefaultAdvisorAutoProxyCreator
  - 会自动搜寻容器中所有的Advisor，然后根据Advisor提供的拦截信息为符合条件的目标对象生成代理bean。

如果这些AutoProxyCreator都不满足，可以自己扩展AutoProxyCreator，主要参考上面2个的实现方式。

### 9.6 TargetSource 190

ProxyFactory可以使用setTarget方式来设置目标对象，ProxyFactoryBean还可以通过setTargetName来设置beanName为目标对象。

除此以外，还有一种方式就是使用TargetSource方式设置目标对象。

原理图：

<img src="/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200602125539603.png" alt="image-20200602125539603" style="zoom:67%;" />

相当于在目标对象外面加了一层壳（使TargetSource对目标对象进行包装），外部的调用经过外部层层拦截，最终调用目标对象的方法。SpringAOP就让调用先走TargetSource，然后通过TargetSource来调用目标类的方法。

无论是哪种方式设置目标对象，Spring内部都会对目标对象用一个TargetSource实现类进行包装。

#### 9.6.1 可用的TargetSource实现类 191

- SingletonTargetSource
  - 使用最多的TargetSource
  - ProxyFactoryBean在setTarget的时候，就会自动包一个SingletonTargetSource
  - 内部值持有一个目标对象

- PrototypeTargetSource
  - 每次都返回一个新的目标对象

- HotSwappableTargetSource
  - 依据某种条件，动态替换目标对象类的具体实现

- CommonsPool2TargetSource
  - 不是每次都返回同一个，也不是都返回新的，而是像连接池一样，有多个从里面取的。

- ThreadLocalTargetSource
  - 为不同线程调用返回不同目标对象。

#### 9.6.2 自定义TargetSource 195

上面的不满足的时候，自己可以扩展：实现TargetSource接口，自己填充逻辑就行了。

### 9.7 小结 197

> 这节看的很没意思！！！这应该是远古时期使用SpringAOP的方式了吧！感觉更适合结合源码来看，我先知道了这些类的职能，然后更加方便我对源码进行理解。但是面试问这些就过分了，很无意义的东西。

## 第10章 Spring AOP二世 198

这个才是我平时使用的SpringAOP

### 10.1 @AspectJ形式的Spring AOP 198

Spring2.0之后发布的新的特性：

- @AspectJ注解到POJO来定义Aspect以及Advice。
- xml配置的简化，引入aop独有的命名空间方式，来配置aop。

Spring会搜索注解了@AspectJ的类，然后将他们织入系统中。

#### 10.1.1 @AspectJ形式AOP使用之先睹为快 199

定义一个Aspect如下：

```java
@Aspect
public class PerformanceTraceAspect {
    private final Log logger = LogFactory.getLog(PerformanceTraceAspect.class);

    @Pointcut("execution(public void *.method1()) || execution(public void *.method2())")
    public void pt() {}

    @Around("pt()")
    public Object performanceTrace(ProceedingJoinPoint joinPoint) throws Throwable {
        StopWatch watch = new StopWatch();
        try {
            watch.start();
            return joinPoint.proceed();
        } finally {
            watch.stop();
            if (logger.isInfoEnabled()) {
                logger.info("PT in method[" + joinPoint.getSignature().getName() + "]>>>" + watch.toString());
            }
        }

    }
}
```

如何将这个Aspect织入到我们的目标对象中？有2种方式：

##### 编程织入方式

使用AspectJProxyFactory：

```java
AspectJProxyFactory weaver = new AspectJProxyFactory();
weaver.setProxyTargetClass(true);
weaver.setTarget(new Foo());
weaver.addAspect(PerformanceTraceAspect.class); //将切面添加进去
Object proxy = weaver.getProxy();
```

##### 自动代理织入方式

使用AutoProxyCreator：AnnotationAwareAspectJAutoProxyCreator。它会自动收集IOC容器中注册的Aspect，并作用到目标对象上。

只需要在配置文件中注入AnnotationAwareAspectJAutoProxyCreator，spring2.x之后提供了更简单的配置：

```xml
<aop:aspectj-autoproxy proxy-target-clas="true">
</aop:aspectj-autoproxy>
```

#### 10.1.2 @AspectJ形式的Pointcut 201

```java
@Pointcut("execution(public void *.method1()) || execution(public void *.method2())")
public void pt() {}
```

SpringAOP只集成了AspectJ的Pointcut的部分功能，其中包括Pointcut的语言支持。

@Aspect的pointcut申明方式主要包含2个部分：

- Pointcut Expression
  - 真正指定Pointcut的地方。
  - 表达式中可以&& || ！这些逻辑运算符
- Pointcut Signature
  - 需要一个定义的方法做为载体，这个方法必须是void类型
  - 如果该方法是public的，那么这个pointcut可以被其他的Aspect引用，如果是private那么只能被当前Aspect类引用。

Aspectj的pointcut表述语言中有很多标志符，但是SpringAOP只能是用少数的几种，因为Spring只对方法级别的pointcut。

- execution
  - 规定格式：`execution(<修饰符模式>?<返回类型模式><方法名模式>(<参数模式>)<异常模式>?) `
  - 只有返回类型，方法名，参数模式是必须的，其他的可以省略。
  - 这里面我们可以使用2种通配符
    - `*` 匹配任意的意思
    - `..`当前包以及子包里面所有的类
- within
  - 只接受类型的声明，会匹配指定类型下面所有的Jointpoint。对SpringAOP来说及，匹配这个类下面所有的方法。
- this和target
  - this指代方法调用方，target指被调用方。
  - this(o1) && this(o2) 即表示当o1类型对象，调用o2类型对象的方法的时候，才会匹配。
- args
  - 指定参数的类型，当调用方法的参数类型匹配就会捕捉到。
- @within
  - 指定某些注解，如果某些类上面有指定的注解，那么这个类里面所有的方法都将被匹配。
- @target
  - 目标类是指定注解的时候，就会被匹配，SpringAOP中和@within没什么区别，只不过@within是静态匹配，@target是运行时动态匹配。
- @args
  - 如果传入的参数的类型 有其指定的注解类型，那么就被匹配。
- @annotation
  - 系统中所有的对象的类方法中，有注解了指定注解的方法，都会被匹配。

这些注解的pointcut在spring内部最终都会转为具体的pointcut对象。

#### 10.1.3 @AspectJ形式的Advice 211

主要就是一些Advice的注解：

- @Before
  - 想要获取方法的参数等信息：可以2种方法
    - 第一个参数设置为JoinPoint，这个参数必须要放在第一个位置，并且除了Around Advice和Introduction不可以用它，其他的Advice都可以使用。
    - args标志符绑定（不常用）
- @AfterReturning
  - 有一个独特属性：returning，可以获取到方法返回值。
- @AfterThrowing
  - 有一个独特属性：throwing 可以接受抛出的异常对象。
- @After（也叫finally）
  - 一般做资源的释放工作的
- @Around
  - 它的第一个参数必须是ProceedingJoinPoint类型，且必须指定。通过ProceedingJoinPoint的proceed()方法执行原方法的调用。
  - proceed()方法需要传入参数，则传入一个Object[]数组。
- @DeclareParents
  - 处理Introduction的，不多描述了。

#### 10.1.4 @AspectJ中的Aspect更多话题 220

##### advice的执行顺序

- 如果这些advice都在一个aspect类里面：

相同的advice按照申明顺序做优先级，但是注意一点，**BeforeAdvice先申明优先级高，则先执行。而AfterReturningAdvice则是先申明优先级高，但是优先级高的越后执行。**

```
before1
before2
task
after returning 2
after returning 1
```

- 如果这些Advice在不同的Aspect里面：

借助于Ordered接口，否则Advice的执行顺序是无法确定的。

##### Aspect的实例化模式

有3种：singleton，perthis，pertarget。【用的时候详细去了解下吧】

### 10.2 基于Schema的AOP 223

配置文件xml方式来配置AOP，没什么可展述的。

### 10.3 小结 235

第一代的SpringAOP 已经太久远了，只对我们看源码有点帮助，第二代的Spring接近我们现在使用的AOP。

## 第11章 AOP应用案例 237

### 11.1 异常处理 237

一个有趣的术语：fault barrier

#### 11.1.1 Java异常处理 237

先从java的异常聊，java异常可以分为2类：

- unchecked exception
  - 不会做编译期检查
  - Error和RuntimeException及其子类
  - 是面向人的，我们无法预料什么时候程序出错，所以程序出错的时候抛出异常，我们可以理解到程序中出现哪些问题。
  - 《Effective Java Exception》文章也称其为 fault
- checked exception
  - 编译器就会检查，程序调用必须处理
  - java.lang.Exception及其子类（除去RuntimeException的分支）
  - 是面向程序的，我们人已经知道什么状态下会出现什么异常，所以程序就能知道该怎么处理，怎么接受的。
  - 《Effective Java Exception》文章也称其为 contingency

fault barrier就是专门处理fault情况的，即unchecked exception

#### 11.1.2 Fault Barrier 238

将散落在系统各处所有的异常信息集中到一处进行拦截然后处理。

### 11.2 安全检查 239

spring security

### 11.3 缓存 240

spring cache

### 11.4 小结 240

大多都是在用的，没有讲啥原理这章。

## 第12章 Spring AOP之扩展篇 241

### 12.1 有关公开当前调用的代理对象的探讨 241

对一个嵌套的方法进行拦截的问题。

#### 12.1.1 问题的现象 241

列如下面这个实体类：

```java
public class NestableInvocationBO {
    public void method1(){
        method2();
        System.out.println("method1 executed!");
    }

    public void method2(){
        System.out.println("method2 executed!");
    }
}
```

method1嵌套调用了method2，如果AOP对method1和method2添加了一个拦截。

我们定义切面，最后发现**执行method1的时候，里面method2不会走切面的拦截逻辑！**

#### 12.1.2 原因的分析 242

归根结底是因为SpringAOP的实现机制导致的，是基于代理模式实现的AOP，横切的逻辑是加入到代理对象中的。但是无论怎么代理，最终的逻辑都是调用目标对象的方法。即：

```java
proxy.method1{
    //横切逻辑
    target.method2
    //横切逻辑
}
```

![image-20200604015012831](/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200604015012831.png)

如图，所以没有能够拦截method1中的method2方法。

#### 12.1.3 解决方案 243

问题的根源是我们调用method2的时候，走的目标对象的method1，如果是一个其他的对象，我们可以通过注入依赖的代理对象，则也能走拦截。

所以这个的解决办法就是讲自身的代理对象公开给目标对象。Spring提供了AopContext，可以让目标对象使用到其代理对象：

```java
public class NestableInvocationBO {
    public void method1(){
        //修改如下
        ((NestableInvocationBO) AopContext.currentProxy()).method2();
        System.out.println("method1 executed!");
    }

    public void method2(){
        System.out.println("method2 executed!");
    }
}
//并且织入器的setExposeProxy需要设置为true
```

不过这方式不太雅观，侵入性很强！我们应该最好让IOC帮我们注入AopContext.currentProxy()这个代理的依赖。具体实现可以用到再看书里面提到几种的方案。

### 12.2 小结 245

解决方法的嵌套导致被嵌套的方法不被拦截的问题。

# 第四部分 使用Spring访问数据

第13章 统一的数据访问异常层次体系 249
13.1 DAO模式的背景 249
13.2 梦想照进现实 251
13.3 发现问题，解决问题 252
13.4 不重新发明轮子 254
13.5 小结 257
第14章 JDBC API的最佳实践 258
14.1 基于Template的JDBC使用方式 258
14.1.1 JDBC的尴尬 258
14.1.2 JdbcTemplate的诞生 261
14.1.3 JdbcTemplate和它的兄弟们 274
14.1.4 Spring中的DataSource 296
14.1.5 JdbcDaoSupport 301
14.2 基于操作对象的JDBC使用方式 302
14.2.1 基于操作对象的查询 303
14.2.2 基于操作对象的更新 310
14.2.3 基于操作对象的存储过程调用 313
14.3 小结 316
第15章 Spring对各种ORM的集成 317
15.1 Spring对Hibernate的集成 318
15.1.1 旧日“冬眠”时光 318
15.1.2 “春天”里的“冬眠” 321
15.2 Spring对iBATIS的集成 329
15.2.1 iBATIS实践之“前生”篇 329
15.2.2 iBATIS实践之“今世”篇 331
15.3 Spring中对其他ORM方案的集成概述 337
15.3.1 Spring对JDO的集成 337
15.3.2 Spring对TopLink的集成 340
15.3.3 Spring对JPA的集成 341
15.4 小结 344
第16章 Spring数据访问之扩展篇 345
16.1 活用模板方法模式及Callback 345
16.1.1 FTPClientTemplate 345
16.1.2 HttpClientTemplate 349
16.2 数据访问中的多数据源 350
16.2.1 “主权独立”的多数据源 350
16.2.2 “合纵连横”的多数据源 352
16.2.3 结束语 354
16.3 Spring 3.0展望 356
16.4 小结 356

# 第五部分 事务管理

## 第17章 有关事务的楔子 358

### 17.1 认识事务本身 358

4个特性：

- 原子性
- 一致性
- 隔离性
  - 隔离性又4个隔离级别：
    - 读未提交RU
      - 脏读问题
      - 不可重复读
      - 幻读
    - 读已提交RC
      - 不可重复读
      - 幻读
    - 可重复读RR
      - 幻读
    - 串行化
- 持久性

具体概念都熟了不记了。

### 17.2 初识事务家族成员 360

一个典型的事务场景中有这么几个参与者：

- Resource Manager：存储并管理系统数据资源的状态。可以理解为代表一个资源，比如一个服务器就是一个资源就一个RM。
- Transaction Processing Monitor：分布式事物场景中协调多个RM进行事务处理，一般都是中间件。
- Transaction Manager：TPM的核心模块
- Application：就我们使用的应用程序，事务的使用方。

依据参与的RM，也就是服务的数量，事务可以分为2类：

- 全局事务（分布式事物）
  - <img src="/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200604145108897.png" alt="image-20200604145108897" style="zoom: 33%;" />

- 局部事务（单机事务）
  - 不需要TPM来进行RM之间的协调了，只需要TM进行事务管理。
  - <img src="/Users/zhaohaoren/workspace/MyBlog/myblog/source/_posts/book-spring揭秘/image-20200604145209621.png" alt="image-20200604145209621" style="zoom:33%;" />

### 17.3 小结 362

## 第18章 群雄逐鹿下的Java事务管理 363

### 18.1 Java平台的局部事务支持 363

jdbc提供的事务支持的核心就是：

```java
connection.setAutoCommit(false);
connection.commit();
```

### 18.2 Java平台的分布式事务支持 365

主要通过JTA（Java Transaction API）或者JCA（Java Connector Architecture）提供支持。

#### 18.2.1 基于JTA的分布式事务管理 366

SUN提出的标准化分布式事务的Java接口规范。只是一套接口规范，具体的实现留给提供商去实现。JavaEE应用服务器需要对JTA支持。

使用JTA有2中方式

- 直接使用JTA接口编程的事务管理方式
  - 我们编码底层还是调用的服务容器的事务实现。
- 基于应用服务器的声明式事务管理方式
  - 服务容器帮我们处理事务，我们申明使用就行。

#### 18.2.2 基于JCA的分布式事务管理 367

主要面向EIS（也不知道是啥）

### 18.3 继续前行之前的反思 367

一堆java平台所能提供给我的事务支持的缺陷。

### 18.4 小结 369

Java平台对我们的事务有一定的支持，以及规范设定。

## 第19章 Spring事务王国的架构 370

Spring事务框架设计理念基本原则：**让事务管理的关注点和数据访问的关注点分离。**

就是事务的管理，和数据的访问业务逻辑，不要放在一起。

### 19.1 统一中原的过程 371

PlatformTransactionManager是Spring事务抽象架构的核心接口，为应用程序提供事务界定的统一方式。

```java
public interface PlatformTransactionManager {
  TransactionStatus getTransaction(TransactionDefinition definition) throws TransactionException;
  void commit(TransactionStatus status) throws TransactionException;
  void rollback(TransactionStatus status) throws TransactionException;
}
```

可以看看这个接口，就是定义了事务的关键的方法。开启事务，提交事务，回滚事务。这是我们整个事务抽象策略的顶级接口。具体的各种策略就交给其实现类来完成了。

我们实现这个来控制事务的时候，主要问题是数据库的connection，一个事务必须要使用一个连接。以前我们是通过传递这个connection在dao和service完成，但这样明显感觉很不好。所以最好就是用ThreadLocal，让一个事务就是一个线程，只是用同一个连接。

我们可以定义一个专门负责一个线程只获取一个连接的TransactionResouceManager：

```java
public class TransactionResouceManager {
    private static ThreadLocal resources = new ThreadLocal();

    public static Object getResource() {
        return resources.get();
    }

    public static void bindResource(Object resource) {
        resources.set(resource);
    }

    public static Object unbindResource() {
        Object resource = getResource();
        resources.set(null);
        return resource;
    }
}
```

这样就可以保存我们调用TransactionResouceManager的bind和unbind方法，一个事务中保证了是同一个connection。

这里给出一个事务管理器的实现（只是一个原型，不是给生产环境使用的）

```java
public class JdbcTransactionManager implements PlatformTransactionManager {
    private DataSource dataSource;
    public JdbcTransactionManager(DataSource dataSource) {
        this.dataSource = dataSource;
    }
    @Override
    public TransactionStatus getTransaction(TransactionDefinition transactionDefinition) throws TransactionException {
        Connection connection;
        try {
            connection = dataSource.getConnection();
            TransactionResouceManager.bindResource(connection);
            return new DefaultTransactionStatus(connection, true, true, false, true, null);
        } catch (SQLException e) {
            throw new CannotCreateTransactionException("cannot get connection for tx", e);
        }
    }

    @Override
    public void commit(TransactionStatus transactionStatus) throws TransactionException {
        Connection connection = (Connection) TransactionResouceManager.unbindResource();
        try {
            connection.commit();
        } catch (SQLException e) {
            throw new TransactionSystemException("commit failed with SQLException", e);
        } finally {
            try {
                connection.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void rollback(TransactionStatus transactionStatus) throws TransactionException {
        Connection connection = (Connection) TransactionResouceManager.unbindResource();
        try {
            connection.rollback();
        } catch (SQLException e) {
            throw new TransactionSystemException("rollback failed with SQLException", e);
        } finally {
            try {
                connection.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
}
```

### 19.2 和平年代 376

Spring的事务抽象包括3个主要接口：（就是上面PlatformTransactionManager接口里面涉及到的类）

- PlatformTransactionManager
  - 负责界定事务边界
- TransactionDefinition
  - 定义事务的相关属性，包括隔离级别，传播行为等
- TransactionStatus
  - 负责事务开启到事务结束之间的状态

#### 19.2.1 TransactionDefinition 376

```java
public interface TransactionDefinition {
    int PROPAGATION_REQUIRED = 0;
    int PROPAGATION_SUPPORTS = 1;
    int PROPAGATION_MANDATORY = 2;
    int PROPAGATION_REQUIRES_NEW = 3;
    int PROPAGATION_NOT_SUPPORTED = 4;
    int PROPAGATION_NEVER = 5;
    int PROPAGATION_NESTED = 6;
    int ISOLATION_DEFAULT = -1;
    int ISOLATION_READ_UNCOMMITTED = 1;
    int ISOLATION_READ_COMMITTED = 2;
    int ISOLATION_REPEATABLE_READ = 4;
    int ISOLATION_SERIALIZABLE = 8;
    int TIMEOUT_DEFAULT = -1;
    int getPropagationBehavior();
    int getIsolationLevel();
    int getTimeout();
    boolean isReadOnly();
    @Nullable
    String getName();
}
```

定义了事务可以指定的属性。包括

##### 隔离级别

提供了5个常亮标志可选的隔离级别

- ISOLATION_DEFAULT：使用数据库默认的隔离级别
- ISOLATION_READ_UNCOMMITTED：RU隔离级别
- ISOLATION_READ_COMMITTED：RC隔离级别
- ISOLATION_REPEATABLE_READ：RR隔离级别
- ISOLATION_SERIALIZABLE：串行化隔离级别

##### 传播行为

传播行为表示整个事务处理过程中所跨越的业务对象，将以怎样的行为参与事务。

![image-20200607152342445](D:\workspace\blog-docs\_posts\book-spring揭秘\image-20200607152342445.png)

简要的来讲，就是当前事务调用其他也有事务的业务对象的时候，这2个事务该如何处理。如图：FoobarService调用FooService和BarService都有各自的事务，我们需要控制这些事务的传播。

- PROPAGATION_REQUIRED = 0;
  - 如果当前存在事务，那么直接加入该事务。如果当前没有事务，则新创建事务。（默认）
  - 如FoobarService已经有事务1了，那么调用FooService和BarService则都使用事务1。
- PROPAGATION_SUPPORTS = 1;
  - 如果当前存在事务，加入该事务。如果没有，直接执行，不走事务。
  - 适合查询方法。可以让查询方法在一个写事务后面，这样也能帮助其读到写的内容。
- PROPAGATION_MANDATORY = 2;
  - 强制要求当前必须有一个事务，否则抛出异常。
- PROPAGATION_REQUIRES_NEW = 3;
  - 不管当前是否存在事务，都会直接创建事务。外层的事务会被挂起。
  - 适合那些执行不希望会影响到外层事务的方法。比如一些方法失败了，希望不影响到外层事务提交。
- PROPAGATION_NOT_SUPPORTED = 4;
  - 不支持当前事务，如果存在事务，这个事务会被挂起。然后以无事务的方式执行。
- PROPAGATION_NEVER = 5;
  - 永远都不要事务，如果有实物就抛出异常
- PROPAGATION_NESTED = 6;
  - 如果当前有事务，则在当前事务中嵌套事务中执行。否则就创建新事务，在新事物中执行。
  - 并不是所有的PlatformTransactionManager都支持该传播行为。

##### 超时时间

指定事务的超时时间。TIMEOUT_DEFAULT默认值-1，表示采用当前事务系统默认超时时间。

##### 是否只读事务

这个设置只是给ResourceManager的一个优化，具体是否优化，还是看ResourceManager决定。

##### TransactionDefinition相关实现

其实现可以按照场景分为2派：

- 声明式事务
- 编程式事务

DefaultTransactionDefinition是其默认实现，主要设置了上面那些属性的默认值，我们也可以通过set方法修改这些默认值。默认设置如下：

```properties
propagationBehavior = PROPAGATION_REQUIRED;
isolationLevel = ISOLATION_DEFAULT;
timeout = TIMEOUT_DEFAULT;
readOnly = false;
```

<img src="D:\workspace\blog-docs\_posts\book-spring揭秘\image-20200607203716426.png" alt="image-20200607203716426" style="zoom:80%;" />

**TransactionTemplate**

spring提供的进行编程式事务管理的模板方法类，直接继承DefaultTransactionDefinition。

**TransactionAttribute**

面向使用AOP进行声明式事务管理的场合。继承TransactionDefinition的一个接口，添加了一个rollbackOn的方法。、

**DefaultTransactionAttribute**

TransactionAttribute的默认实现类，同时继承了DefaultTransactionDefinition，提供了rollbackOn的实现。

**DelegatingTransactionAttribute**

是一个抽象类。

#### 19.2.2 TransactionStatus 382

这个接口表示整个事务处理过程中的事务状态。我们大多在编程式事务的时候使用该接口。

我们在事务处理过程中使用TransactionStatus进行如下工作：

- 查询事务的状态
- 通过rollbackOnly()方法标记当前事务以使其回滚
- 如果相应的PlatformTransactionManager支持savepoint，可以在当前事务中创建内嵌事务。

![image-20200607205347837](D:\workspace\blog-docs\_posts\book-spring揭秘\image-20200607205347837.png)

DefaultTransactionStatus是框架内部主要使用的TransactionStatus。SimpleTransactionStatus目前看来主要是为了测试目的用的，其他地方没用到。

#### 19.2.3 PlatformTransactionManager 382

PlatformTransactionManager是Spring事务抽象框架核心组件，**整个抽象体系是基于策略模式**。具体的策略由其实现类来实现。

其实现类可以分为面向局部事务和面向全局事务两个分支。

**面向局部事务的PlatformTransactionManager实现类**

<img src="D:\workspace\blog-docs\_posts\book-spring揭秘\image-20200607205846371.png" alt="image-20200607205846371" style="zoom:67%;" />

**面向全局事务的PlatformTransactionManager实现类**

JtaTransactionManager是Spring提供的分布式事务支持的实现类。

PlatformTransactionManager的实现类大多都遵循一样的结构和理念，以DatasourceTransactionManager这个实现类为例看看PlatformTransactionManager的实现类的奥秘。

具体的流程太细了就不好描述了：

![image-20200607220853003](D:\workspace\blog-docs\_posts\book-spring揭秘\image-20200607220853003.png)

### 19.3 小结 392

事务的框架成员，以及一些实现原理。

## 第20章 使用Spring进行事务管理 393

事务管理的实施通常2种方式：编程式，声明式

### 20.1 编程式事务管理 393

可以直接使用PlatformTransactionManager，或者使用更方便的TransactionTemplate，推荐TransactionTemplate。

#### 20.1.1 直接使用PlatformTransactionManager进行编程式事务管理 393

```java
DefaultTransactionDefinition definition = new DefaultTransactionDefinition();
definition.setTimeout(20);
TransactionStatus txStatus = transactionManager.getTransaction(definition);
try{
    //业务逻辑实现
}catch (ApplicationException e){
    transactionManager.rollback(txStatus);
    throw e;
}catch (RuntimeException e){
    transactionManager.rollback(txStatus);
    throw e;
}catch (Error e){
    transactionManager.rollback(txStatus);
    throw e;
}
transactionManager.commit(txStatus);
```

这个缺点很明显，所有的业务都这么写个事务，代码量太大了。

#### 20.1.2 使用TransactionTemplate进行编程式事务管理 394

```java
TransactionTemplate txTemplate;
txTemplate.execute(new TransactionCallback<>() {
    @Override
    public Object doInTransaction(TransactionStatus transactionStatus) {
        Object result = null;
        //事务操作...
        return result;
    }
});
txTemplate.execute(new TransactionCallbackWithoutResult(){
    @Override
    protected void doInTransactionWithoutResult(TransactionStatus transactionStatus) {
        //事务操作1
        //事务操作2
        //...
    }
});
```

让我们只专注于callback里面的开发，有TransactionCallback和TransactionCallbackWithoutResult两个接口。区别在于有无返回结果。

这种方式会捕捉事务操作中抛出的unchecked exception异常并回滚事务。

#### 20.1.3 编程创建基于Savepoint的嵌套事务 396

不知道说的啥，嵌套事务的，这个不就是回滚到设置的savepoint的点吗？扯了一堆不知道啥玩意的东西。

### 20.2 声明式事务管理 397

#### 20.2.1 引子 397

使用springAOP实现

#### 20.2.2 XML元数据驱动的声明式事务 399

忽略了。。。

#### 20.2.3 注解元数据驱动的声明式事务 410

提供了@Transactional注解的方式。

1. 对业务标注@Transactional注解

2. ```xml
   <tx:annotation-driven transaction-manager="txManager" />
   ```

### 20.3 小结 413

怎么用Spring的事务。

## 第21章 Spring事务管理之扩展篇 414

### 21.1 理解并活用ThreadLocal 414

事务管理框架中使用threadlocal避免了使用connection-passing的方式来传递connection保证在一个事务。

#### 21.1.1 理解ThreadLocal的存在背景 414

ThreadLocal是Java语言提供的支持线程局部变量的标准实现类。目的是避免对象共享来保证应用程序实现的线程安全。

#### 21.1.2 理解ThreadLocal的实现 415

ThreadLocal自己不会保存这些对象资源，这些对象属于特定线程，所以就让线程自己管理。每个Thread都有一个内置的ThreadLocal.ThreadLocalMap类型的实例变量。通过set(data)会将当前的ThreadLocal作为key设置到当前线程的map中。

ThreadLocal就像一个窗口，通过这个窗口，我们可以将对象绑定到当前线程上。

就是一个线程有个map，这个map的key是ThreadLocal（一个线程可能有多个ThreadLocal对象）。然后get也是，获取当前ThreadLocal对应的值。

#### 21.1.3 ThreadLocal的应用场景 416

- 管理应用程序实现中的线程安全。
  - 有状态的对象，或者线程不安全的对象，为多个线程分配多个副本。就比如事务的connection。
- 实现当前程序执行流程内的数据传递
  - 比如讲该线程中执行的日志序列保存在里面，用的时候取出来。
- 某些情况性能优化
- pre-thread Singleton
  - 都一个意思，分的这些场景都不知所云，表达的都一个东西，完全就是强行码字。

#### 21.1.4 使用ThreadLocal管理多数据源切换的条件 417

多数据源的时候，我们可能一个线程使用的数据源A，这时候另外一个线程切换成B了，所以用ThreadLocal保存一个标识，让一个线程访问自己的当前的源标识。

### 21.2 谈Strategy模式在开发过程中的应用 420

策略模式的重点在于通过统一的抽象，向客户端屏蔽其所依赖的具体行为，但该模式没有关注客户端应该如何使用这个行为。

### 21.3 Spring与JTA背后的奥秘 423

JTA获取dataSource需要从应用服务器的JNDI服务获取。不能使用本地配置的DataSource。

![image-20200608005649978](D:\workspace\blog-docs\_posts\book-spring揭秘\image-20200608005649978.png)

### 21.4 小结 427

over

# 第六部分 Spring的Web MVC框架

第22章 迈向Spring MVC的旅程 430
22.1 Servlet独行天下的时代 430
22.2 繁盛一时的JSP时代 433
22.3 Servlet与JSP的联盟 436
22.4 数英雄人物，还看今朝 438
22.5 小结 440
第23章 Spring MVC初体验 441
23.1 鸟瞰Spring MVC 442
23.2 实践出真知 446
23.2.1 Spring MVC应用的物理结构 447
23.2.2 按部就班地开始工作 451
23.3 小结 459
第24章 近距离接触Spring MVC主要角色 460
24.1 忙碌的协调人HandlerMapping 460
24.1.1 可用的HandlerMapping 461
24.1.2 HandlerMapping执行序列(Chain Of HandlerMapping) 463
24.2 我们的亲密伙伴Controller 464
24.2.1 AbstractController 465
24.2.2 MultiActionController 468
24.2.3 SimpleFormController 476
24.2.4 AbstractWizard-FormController 496
24.2.5 其他可用的Controller实现 503
24.3 ModelAndView 505
24.3.1 ModelAndView中的视图信息 505
24.3.2 ModelAndView中的模型数据 506
24.4 视图定位器ViewResolver 506
24.4.1 可用的ViewResolver实现类 507
24.4.2 ViewResolver查找序列(Chain Of ViewResolver) 511
24.5 各司其职的View 511
24.5.1 View实现原理回顾 512
24.5.2 可用的View实现类 515
24.5.3 自定义View实现 521
24.6 小结 523
第25章 认识更多Spring MVC家族成员 524
25.1 文件上传与MultipartResolver 525
25.1.1 使用MultipartResolver进行文件上传的简单分析 526
25.1.2 文件上传实践 527
25.2 Handler与HandlerAdaptor 530
25.2.1 问题的起源 530
25.2.2 深入了解Handler 531
25.2.3 近看HandlerAdaptor的奥秘 533
25.2.4 告知Handler与Handler-Adaptor的存在 535
25.3 框架内处理流程拦截与Handler-Interceptor 536
25.3.1 可用的Handler-Interceptor实现 537
25.3.2 自定义实现Handler-Interceptor 538
25.3.3 HandlerInterceptor寻根 540
25.3.4 HandlerInterceptor之外的选择 541
25.4 框架内的异常处理与Handler-ExceptionResolver 544
25.5 国际化视图与LocalResolver 548
25.5.1 可用的LocaleResolver 549
25.5.2 LocaleResolver的足迹 550
25.5.3 Locale的变更与LocaleChangeHandler 551
25.6 主题(Theme)与ThemeResolver 552
25.6.1 提供主题资源的ThemeSource 552
25.6.2 管理主题的ThemeResolver 554
25.6.3 切换主题的ThemeChange-Interceptor 555
25.7 小结 556
第26章 Spring MVC中基于注解的Controller 557
26.1 初识基于注解的Controller 557
26.2 基于注解的Controller原型分析 558
26.2.1 自定义用于基于注解的Contro-ller的HandlerMapping 558
26.2.2 自定义用于基于注解的Contro-ller的HandlerAdaptor 560
26.3 近看基于注解的Controller 563
26.3.1 声明基于注解的Controller 563
26.3.2 请求参数到方法参数的绑定 569
26.3.3 使用@ModelAttribute访问模型数据 572
26.3.4 通过@SessionAttribute管理Session数据 574
26.4 小结 576
第27章 Spring MVC之扩展篇 577
27.1 Spring MVC也Convention Over Configuration 577
27.1.1 Convention Over Configuration简介 577
27.1.2 Spring MVC中的Convention Over Configuration 578
27.2 Spring 3.0展望 581
27.3 小结 582

# 第七部分 Spring框架对J2EE服务的集成和支持

第28章 Spring框架内的JNDI支持 584
28.1 JNDI简单回顾 584
28.2 Spring框架内JNDI访问的基石——JndiTemplate 585
28.3 JNDI对象的依赖注入——JndiObjectFactoryBean 587
28.4 小结 588
第29章 Spring框架对JMS的集成 589
29.1 说说JMS的身世 589
29.2 使用JMS API进行应用开发的传统套路 590
29.3 Spring改进后的JMS实战格斗术 592
29.3.1 消息发送和同步接收 592
29.3.2 异步消息接收 601
29.3.3 JMS相关异常处理 607
29.3.4 框架内的事务管理支持 608
29.4 小结 609
第30章 使用Spring发送E-mail 610
30.1 思甜前，先忆苦 610
30.2 Spring的E-mail抽象层分析 612
30.2.1 直接创建邮件消息并发送 614
30.2.2 使用MimeMessage-Preparator发送邮件 615
30.3 Spring的E-mail支持在实际开发中的应用 616
30.4 小结 622
第31章 Spring中的任务调度和线程池支持 623
31.1 Spring与Quartz 623
31.1.1 初识Quartz 623
31.1.2 融入Spring大家庭的Quartz 626
31.2 Spring对JDK Timer的集成 631
31.2.1 JDK Timer小记 631
31.2.2 Spring集成后的JDK Timer 632
31.3 Executor的孪生兄弟TaskExecutor 634
31.3.1 可用的TaskExecutor 635
31.3.2 TaskExecutor使用实例 637
31.4 小结 639
第32章 Spring框架对J2EE服务的集成之扩展篇 640
32.1 MailMonitor的延伸 640
32.2 Spring 3.0展望 642
32.3 小结 642
第33章 Spring远程方案 643
33.1 从“对面交谈”到“千里传声” 643
33.2 Spring Remoting架构分析 645
33.2.1 Spring Remoting之远程访问异常体系 645
33.2.2 统一风格的远程服务公开与访问方式 646
33.3 Spring Remoting提供的远程服务支持 648
33.3.1 基于RMI的Remoting方案 648
33.3.2 基于HTTP的轻量级Remoting方案 651
33.3.3 基于Web服务的远程方案 655
33.3.4 基于JMS的远程方案 658
33.4 扩展Spring Remoting 660
33.5 Spring Remoting之扩展篇 663
33.5.1 拉开JMX演出的序幕 663
33.5.2 Spring 3.0展望 664
参考文献 665

