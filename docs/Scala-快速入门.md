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



#### 循环

##### for 

Scala的for循环格式为： `for(i <- 表达式)`：`i` 遍历表达式后面所有的值。

Scala的`for`相当于Java中的`for.in`，没有`for(int i=0;i<10;i++)` 这种类似结构。

**例**

```scala
//等价于 for(i in s)
val s = "hello world"
for (i <- s) print(i)
//如果想要下标或者index值的话：i 就代表数组 s 的下标
for (i <- 0 to 0 to s.length-l) { 
  println(i)
}
```

###### **break&continue**

Scala**没有break和continue保留字来退出循环**！而是采用的其他的方式：

`break`写法：

```scala
Breaks.breakable(
  for (i <- 0 until 10) {
    println(i)
    if (i == 5) {
      Breaks.break() // 使用Breaks对象中的break方法
    }
  }
)
```

`continue`写法：

```scala
for (i <- 0 to 10) {
  breakable {
    if (i == 3 || i == 6) {
      break // 引入包可以简写，for内部break，不执行下面继续下一次for
    }
    println(i)
  }
}
```

###### **高级用法**

`for-for`写法：

```scala
for (i <- 1 to 3; j <- 1 to 3) print(f"${10 * i + j}%3d")
//11 12 13 21 22 23 31 32 33
```

结合`yield`：

循环体后加`yield`该循环体会构造出一个集合，这种写法叫做for推导式（for comprehension）

```scala
for (i <- 1 to 10) yield i % 3
//res0: scala.collection.immutable.IndexedSeq[Int] = Vector(1, 2, 0, 1, 2, 0, 1, 2, 0, 1)
```

一些简化写法：

- 循环中定义变量

```scala
for (i <- 1 to 3; from = 4 - i; j <- from to 3) print(f"${10 * i + j}%3d")
//13 22 23 31 32 33
// 等于下面简写
for (i <- 1 to 3) {
  form = 4 - i
  for (j <- from to 3) {
    print(f"${10 * i + j}%3d")
  }
}
```

- 使用生成器守卫（就是if判断）

```scala
for (i <- 1 to 3; j <- 1 to 3 if i != j) print(f"${10 * i + j}%3d")
//12 13 21 23 31 32
//等价于下面的简写
for (i <- 1 to 3; j <- 1 to 3) {
  if (i != j) {
    print(f"${10 * i + j}%3d")
  }
}
```

> Scala的for循环的`for(表达式)` 的表达式可以有很强的表达力：对于一些循环中需要的条件判断，可以抽取到该表达式中书写。当然这只是简写，会增加传统写Java程序者的理解复杂度，如果只专注于逻辑这种写法的表现力就很强，从最后2个简化写法可以看出：**(表达式)里面写的都是循环相关的，{表达式}都是需要被循环的逻辑，**区分开表现力更好。

##### while

while的写法就和其他的语言差不多了，但是我们日常用的最多的还是for循环。

```scala
while(表达式) { 表达式 }
```



### 函数

首先区别一下方法和函数：**方法对对象进行操作， 而函数则不是。**

**定义函数：**







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