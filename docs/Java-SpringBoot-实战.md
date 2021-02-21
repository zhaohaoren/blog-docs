# SpringBoot 最佳实践





## 集成Mybatis-plus



## 集成Mybatis

官方提供了 `mybatis-spring-boot-starter `方便集成。



---



## 解决跨域问题

在和前端联调的时候，时不时的就会冒出一个跨域问题，如下所示：

```
Access to XMLHttpRequest at 'http://xxxx:xxx/hello' from origin 'http://vvvvv:vvvv' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

### 什么是跨域？

浏览器为了页面安全，设置了**同源策略：即本域脚本只能读写本域内的资源，而无法访问其它域的资源。**所谓同源就是**“协议+域名+端口”三者相同**，当在一个站点内访问非该同源的资源，浏览器就会报跨域错误。浏览器的两种同源策略会造成跨域问题：

- **DOM同源策略**。禁止对不同源的页面的DOM进行操作，主要包括iframe、canvas之类的。不同源的iframe禁止数据交互的，含有不同源数据的canvas会受到污染而无法进行操作。
- **XmlHttpRequest同源策略**。简单来说就禁止不同源的AJAX请求，主要用来防止CSRF攻击。

<u>同源策略是**浏览器的行为**，所以不要再说我自己调接口调通了啊或者我用PostMan调没有问题啊。</u>

### 模拟一个跨域

新建2个SpringBoot项目：A和B。A端口8080，B端口8081。

项目A建一个AController

```java
@RestController
public class AController {
    @GetMapping("/hello")
    public String hello() {
        return "hello";
    }
}
```

项目B建立static/index.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <script src="https://cdn.bootcss.com/jquery/3.4.1/jquery.js"></script>
    <title>Hello</title>
</head>
<body>
<div id="show"></div>
<input type="button" onclick="btnClick()" value="get_button">
<script>
    function btnClick() {
        $.get('http://localhost:8080/hello', function (msg) {
            $("#show").html(msg);
        });
    }
</script>
</body>
</html>
```

然后启动项目后访问localhost:8081/index.html，点击button会触发跨域。

![image-20200824194753083](/Users/zhaohaoren/Library/Application Support/typora-user-images/image-20200824194753083.png)

### 跨域解决

跨域网上有很多解决方法，我只说说一些常用的。跨域问题，不仅仅是前端的事情，也是后端的事情。传统的跨域方案是JSONP，但是JSONP只支持GET请求。我们后端目前都是用的CORS来解决跨域的。

<u>**什么是CORS**</u>

CORS是一个W3C标准，全称是"跨域资源共享"（Cross-origin resource sharing）。 它允许浏览器向跨源服务器，发出XMLHttpRequest请求，从而克服了AJAX只能同源使用的限制。

CORS需要浏览器和服务端同时支持，即浏览器和服务端都需要有对应的技术支撑才能使用CORS。

<u>**CORS原理**</u>

浏览器将CORS请求分成两类：**简单请求**和**非简单请求**。**针对这2种不同的请求浏览器的请求流程不同。**

**Tips：**满足下面2个条件的就就是简单请求：

1. 请求方法是以下三种方法之一
   - HEAD、GET、POST

2. HTTP的头信息不超出以下几种字段：
   - Accept、Accept-Language、Content-Language、Last-Event-ID、Content-Type：只限于三个值`application/x-www-form-urlencoded`、`multipart/form-data`、`text/plain`。

**简单请求流程：**

1. 浏览器发现这次跨源AJAX请求是简单请求，就自动在Header添加一个`Origin`字段：`Origin: http://localhost:8081`。

2. 服务器接收到该请求，查看是否在白名单中。如果在，Response的Header会多几条：

   ```yml
   Access-Control-Allow-Origin: http://localhost:8081 #这个是核心
   Access-Control-Allow-Credentials: true  #该字段可选。它的值是一个布尔值，表示是否允许发送Cookie。
   Access-Control-Expose-Headers: FooBar #该字段可选。CORS请求时，XMLHttpRequest对象的getResponseHeader()方法只能拿到6个基本字段，如果想拿到其他字段，就必须在Access-Control-Expose-Headers里面指定。
   ```

3. 浏览器依据返回的有没有这个Header来判断是否出错。

**非简单请求流程：**（比如请求方法是`PUT`或`DELETE`，或者`Content-Type`字段的类型是`application/json`。）

1. 在正式通信之前，增加一次HTTP查询请求，称为"预检"请求（preflight）其请求用的请求方法是`OPTIONS`，头信息里面添加了`Origin`。你在控制台可以发现一个接口请求了2次。
2. 浏览器先询问服务器，当前网页所在的域名是否在服务器的许可名单之中，以及可以使用哪些HTTP动词和头信息字段。只有得到肯定答复，浏览器才会发出正式的`XMLHttpRequest`请求，否则就报错。
3. 同样的，服务端发现在白名单时候，返回`Access-Control-Allow-Origin`等Header信息。此时预检算完成。
4. 在设置的预检有效期内，预检只会执行一次，后面的请求就和简单请求一样了。当超时了才会再发一次。

<u>**使用**</u>

Spring和SpringBoot都堆CORS提供了支持，下面说说SpringBoot是怎么做的：

1. 使用`@CrossOrigin(origins = "http://localhost:8081")`注解，可以注解在Controller方法上，表示这个接口允许跨域。也可以注解在Class上，表示该Controller下面所有的接口都支持该跨域。

   - ```java
     @GetMapping("/hello")
     @CrossOrigin(origins = "http://localhost:8081")
     public String hello() {
         return "hello";
     }
     ```

2. 如果很多地方都需要处理这么就很麻烦了，我们可以使用WebMvcConfigurerAdapter来全局做配置。

   - ```java
     @Configuration
     public class CorsConfig extends WebMvcConfigurerAdapter {
         @Override
         public void addCorsMappings(CorsRegistry registry) {
             registry.addMapping("/**") //可以被跨域的路径
                 .allowedOrigins("*") //域名的白名单
                 .allowedMethods("*")/*"GET", "POST", "DELETE", "PUT"*/
                 .allowedHeaders("*") //允许所有的请求header访问，可以自定义设置任意请求头信息
                 .maxAge(3600); //这个复杂请求是预检用的，设置预检多久失效
         }
     }
     ```

   - 具体其他的一些配置以及说明可以参考源码注释。
   
 3. 还可以使用Filter也是可以的，我用的不多，就不写了。

这么写了并不是就安全了，存在CSRF危险。浏览器在实际操作中，会对请求进行分类，分为简单请求，预先请求，**带凭证的请求**等，预先请求会首先发送一个options探测请求，和浏览器进行协商是否接受请求。默认情况下跨域请求是不需要凭证的，但是服务端可以配置要求客户端提供凭证，这样就可以有效避免csrf攻击。

> 参考：[跨域资源共享 CORS 详解](http://www.ruanyifeng.com/blog/2016/04/cors.html)| [Spring Boot中通过CORS解决跨域问题](http://springboot.javaboy.org/2019/0412/springboot-cors)



----



## 多数据源方案一些思考

目前微服务大行其道，大部分的架构都已经转为单服务单库来最大程度的解耦数据源的业务关联性。但是依然存在少数场景会遇到需要使用多数据源的场景。再则，撇开微服务来说，单体的SpringBoot服务在我们开发中，多数据源的情况就更加普遍了。本文主要聊聊多数据源的一些方案即对应的实现。

### 主流的多数据源方案

目前主流的多数据源方案宏观上来讲，主要就分为2种：

1. 基于分包的方式
   - 分包的方式很好理解，就是讲多个数据源的XXMapper文件分在不同的包中，然后针对每一个数据源都会向Spring容器注入一个DataSource以及对应的SqlSessionFactory实例。这样如果有4个数据源，那么Spring最后容器中就会有4个独立的DataSource，以及4个独立的SqlSessionFactory实例。这样设计保证了数据源在dao层是完全隔离的，这是最简单直接且不容易出错的方法。
2. 基于AOP切面拦截的方式
   - AOP的实现方案就很多了，但是他们大部分的结构是只有一个SqlSessionFactory实例，但是有多个DataSource，在需要切换的时候，切换当前线程下SqlSessionFactory对应的DataSource。
   - 这里列举一些方法：
     - 基于约定：定义mapper的规范，比如统一以什么开头，然后让AOP去拦截这些类或者方法，从而从类名方法名中获取数据源的信息。
     - 基于注解：在需要使用地方加上自定义的数据源注解，通过AOP拦截这些带注解的类和方法，从而进行数据源的切换。

#### 优缺点

##### 分包

- 优点
  - 实现简单，直接，而且一定不会出错。
  - 定位sql等很清晰，一眼就能知道这个sql的方法是在哪个库上执行的。
- 缺点
  - 不够灵活，即我需要做对Mapper分文件夹的额外工作。
  - Mapper类文件会很臃肿，我们可能会需要管理大量的Mapper类。
  - 在某些场景下，这种方式是完全不可取的（或者说，单纯只使用分包方法是不可取的，下面会给出这样的场景）。

##### AOP

- 优点
  - 灵活，基本满足所有的场景（只要你需要什么场景，通过AOP都能整出适合它的方案）
- 缺点
  - 每个使用的地方都需要加上注解，或者一个标识，还是比较麻烦的，而且不敢保证不会出现忘记或者写错的情况。
  - 太灵活了，用的好还行，使用不当的话，代码会很恶心。（来自实际工作经验，有了这个东西，很多写代码不注重质量的人，SQL乱放，数据源乱切，代码极乱）
  - 对代码的侵入性很高。这也是我们不是很喜欢他的一点。有些注解的方法，需要在代码里面到处加上数据源的注解，这些东西对业务开发本身毫无意义，更有甚者，在代码逻辑里面进行数据源切换的。（这其实对代码的侵入性太高了，你总不会喜欢看着项目的业务代码逻辑呢，突然给你来一段代码只是用来做数据源切换的吧，而且Spring为我们提供一系列的机制其实都是希望对我们自己写代码能够最小侵入性）。

### 如何选型

首先，考察你所使用的数据源场景。我个人建议是**能不用AOP方式就不要使用AOP方式**。如果你多个数据源之间彼此都相互独立，完全没有什么关联性，那么我推荐你采用分包方式。（这里的没有关联性，比如你场景需要订单库，用户库，商品库，这些业务属性相互区分的库）这种方式，虽然需要安装包分类，但是可以让代码结构十分清晰，sql的管理也变得容易。

如果你的数据源很多，比如一个项目里面有二三十个，你可能觉得分包很麻烦，可以考虑使用AOP来使用的时候切换。但是慎重考虑，到时候sql和mapper文件以及数据源在后期不断使用中的混乱程度。分包虽然多，但是很清晰，并且100%不会出问题（我遇到的实际开发中，经常有人切错数据源）。

针对AOP方式，我觉得唯一让我必须使用的理由就是：项目依赖的多个库，里面的表结构大致相同，或者完全就是主从关系（这是分包方式最大的缺点）。这时候，对于这种库，分多个包，可能造成有大量的sql都是重复的。代码冗余就很高。 使用AOP切换就很方便。***（举个例子，一个出租车公司，依据城市进行分库，具体使用的数据源是城市的id来区分的，每个城市都有一个库，那么如果分包方式，我们对每个城市都要分1个包？然后每个包里面的代码逻辑还都一样？这显然不可取的，这种场景通过AOP可以特别优雅的解决）***。

### 实现

#### 分包



#### AOP

##### 自定义



##### 苞米豆

我们可以使用苞米豆提供的[动态数据源方案](https://dynamic-datasource.github.io/dynamic-datasource-doc/)。他是一个基于AOP+ThreadLocal方式，通过注解标记方法或者类来完成数据源切换，还支持了很多其他的特性，详细可以阅读官方文档。

### 思考

其实分包和AOP是可以结合起来使用的，分包的方式更快一点是肯定的（因为不需要很多切换数据源的操作），但是这点性能影响不计，我可以通过AOP拦截不同的包，然后做不同的数据源切换，也能实现等效于分包的方式的数据源切面。其实我们可以对自己的场景通过AOP方式可以定制出很多最适合自己的方案。



----



## 自定义SpringBoot-Starter

Spring官方已经实现了很多的场景启动器（spring boot starters）。但是实际使用中，还是存在一些场景需要我们自己去定义starters。（比如现有的starters不能满足你的需求，spring官方没有你需要的starters等情况）



实现步骤

1. 依赖配置
2. 配置属性Properties
3. 自动配置类
4. 配置配置类到META-INF/spring.factories文件中，让自动配置类自动加载（核心）



项目结构规范：

starter空项目引入autoconfiguration项目。

但是对于写一个简单的启动器，我们可以把自动配置的代码写在starter里面。



命名规范：

Spring官方的 `spring-boot-starter-xxx`

我们野生的 `xxx-spring-boot-starter`



实操一个











## 日志配置 







## 定时任务

#### 注意事项

1. Spring的 `@Scheduled` 默认配置下是开了一个单独的线程去运行的，所有的`Scheduled` 任务都会在一个线程中被执行，所以当某个任务没有执行结束，其他的任务会阻塞到任务执行后才执行。如果想要这些任务互不影响需要自定义`Scheduled` 的线程池：

   ```java
       @Bean
       public TaskScheduler taskScheduler() {
           ThreadPoolTaskScheduler taskScheduler = new ThreadPoolTaskScheduler();
         	// 这里开了5个线程
           taskScheduler.setPoolSize(5);
           return taskScheduler;
       }
   ```
   
2. 我们可能在本地启动的时候，不希望定时任务启动，只有线上才执行。这时候需要让`@EnableScheduling`依据环境来生效。我们可以但是配置下：

   ```java
   @Configuration
   @EnableScheduling
   @EnableConfigurationProperties
   @ConditionalOnProperty(prefix = "spring.scheduling", name = "enabled", havingValue = "true")
   public class SchedulingConfig {}
   ```
   

配置文件 application-XXX.yml：

   ```yml
   spring:
     #是否启动定时任务
     scheduling:
       enabled: false
   ```





## 并发

线程池配置





## 统一前缀

https://blog.csdn.net/gzt19881123/article/details/104530561

因为健康检查，所以不能使用serlvet那个





