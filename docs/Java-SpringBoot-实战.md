# SpringBoot 开发指南



## 日志配置 



## 配置多数据源





### 主流策略

目前市面上的主流策略有：

1. 基于分包方式
2. 基于ThreadLocal方式



N种策略



使用dynamic-datasource-spring-boot-starter







### dynamic-datasource-spring-boot-starter源码分析

作为spring boot 的启动器，首先看该starter主要帮我们自动配置了什么，查看META-INF/spring.factories文件

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.baomidou.dynamic.datasource.spring.boot.autoconfigure.DynamicDataSourceAutoConfiguration
```



先创建Bean：DynamicDataSourceProvider

这是一个用来创建数据源的Provider类，传入了从配置类中获取的数据源的配置信息（一个DataSourceProperty的map）里面封装了创建数据源的方法。

(baomidou只提供了yml配置中获取数据源，想要从别的地方获取需要自己实现)



然后创建Bean：DynamicRoutingDataSource

这是苞米豆自己定义的动态数据源的DataSource，主要就是讲上面的DynamicDataSourceProvider 传到`provider`属性里面。然后就一些其他的配置





**为什么MP不支持 这种分包的方式的多数据源？**

因为MP的MybatisPlusAutoConfiguration 在配置SqlSession的时候，就只认一个数据源。一个数据源 一个sqlsession。没有说查出所有的数据源，然后为其进行都配置好SqlSession操作。

所以我们只能在多数据源这个项目里面来配置全了，不能指望MP给我们配置。



https://blog.csdn.net/mooodo/article/details/83137461： sqlsession 可以不动 不同线程不断去修改该sqlsession单例的datasource！这也是一种方案

苞米豆的也是 线程间切换数据源来解决的。



那么我分包的方式 是不是也是可以这样呢？ 没必要使用多个数据源对象。





















## 集成Mybatis-plus



## 集成Mybatis

官方提供了 `mybatis-spring-boot-starter `方便集成。





## 解决跨域

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







# 自定义SpringBoot-Starter

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