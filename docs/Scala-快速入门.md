# Scala 快速入门

因为Spark和Kafka这些源码都是Scala，大数据用的也比较多。所以快速的过一下Scala的所有相关知识点，目的只是在于会用。









## 环境搭建

### 安装

Scaladoc：www.scala-lang.org/api

### 

### Hello World





- Scala不需要封号结尾，但如果想要单行中写下多个语句， 就要以分号隔开。





和Java一样，Scala也有七种基本数据类型：Byte、Char、Short、Int、Long、Float、Double、Boolean。但是他没有Java基本数据类型（int）和引用类型（Integer）区别，对于Scala来说都是类。









### 变量



#### 数据类型

##### String

Scala底层的String就是`java.lang.String`。

StringOps提供了很多对String的操作方法。

##### RichInt

##### RichDouble

##### RichChar

##### Bigint

##### BigDecimal

可以以常规的方式使用那些数学操作符。不需要和Java一样需要走该类的方法。



### 算术操作

支持Java所支持的那些操作符：+、-、*、/、%、&、|、^、>>、<<。

Scala的这些**操作符运算本质上是方法的调用**：

```scala
val = a + b
// 等价于
val = a.+(b)
```

Scala对方法名没有特殊的约束，几乎可以使用任何符号来做方法名。

<u>**注意**</u>：**Scala 不支持 `++`  `--` 操作**，只能使用 `a+=1`这种方式来操作。





### 块

Scala中 `{}` 表示一个块，块也是有返回值的（应该说是有结果的），结果为块中最后一个表达式的值。

```scala
val distance = {
  val dx = x - xO
  val dy = y - yO
  sqrt(dx * dx + dy * dy) // distance为该值
}
```

如果最后一个表达式没有返回值，那其实也是返回的一个Unit类型值。







### 数组



### 控制结构

#### 分支

##### if-else

Scala的`if-else`可以使用条件表达式，且表达式有值（写法和python一样）：

```scala
var s = if (x > 0) 1 else 0 
// x = 1, s = 1; x = -1, s = 0; 
// 等价于（但还是推荐上面写法）
if (x > 0) s = 1 else s = -1
```



##### for 

##### while



#### 循环

### 方法



如果方法没有参数，可以不写括号：

```scala
"justin".sorted
// res1: String = ijnstu
```





#### 一些系统函数

##### 输入输出

print println

```scala
StdIn.readLine("name:")
```





## 包







## 面向对象



Any类 等于 Java中的Object类



Unit 相当于Java中的void







































##### 