---
title: 【JAVA】Java程序运行和对象创建过程简述
date: 2020-05-10 01:42:55
tags:
---

Java中一个对象创建分为两个步骤： **加载类，创建对象。**
加载类是将所写的程序.java文件编译生成的.class文件加载到内存中，保证了对象创建的预置环境。类加载完毕后才可以创建该类的对象。
<!-- more -->

# 第一步：加载类

1. 当开始运行一个类，虚拟机首先试图访问指定启动类的 .main() 方法，加载该类的 .class 文件。
2. 如果该类有父类，那么继续加载其父类，以此类推，直到加载出所有与main入口类相关的类（它的父类，父类的父类等）。
3. 接着，从其顶级父类开始，对其static域按照顺序进行初始化！直至初始化完所有类的static域。>将static域放到静态存储区。
4. 至此类的加载工作完毕了，下面就进入main函数，执行main函数。一般main函数中来创建类的对象，如果发现要创建的类没有被加载，则继续加载该类）

# 第二步：对象创建

1. 为对象获取内存，然后将内存全部置为0，此时对象中的所有属性都是被赋予0的默认值（内存为0时候的默认值：null-对象引用，0-int，false-boolean...）> 在堆中生成对象所需空间，全部初始化为0，具体成员属性值为堆上对应内存子块--正是因为这种机制，所以java可以保证所有的类对象的属性都会被初始化，但是局部不会被初始化。

* 这里需要注意的是：一个对象内部组合了另一个对象，那么在堆中其实存的也是一个引用，这个引用指向被组合对象的堆内存地址（另外再创建）。
  当引用在内存的二进制数据都为0的时候，他的表现形式是null；当他指向的数据内容内存区数据都是0的时候，他的值为0，""，False等初始标准值。所谓初始化就是修改内存区的二进制数据，因为对象在创建时候第一步就将内存清0，所以保证了所有属性都能至少被初始化为标准初值！
  但是局部变量不一样，你不初始化，只是申明，那么开辟的内存区在栈中值会是一个未知数据（一旦使用该引用的话，使用的可能是你没有初始化而瞎几把乱指的地址）所以Java会代码检验的时候发现你使用了未初始化的引用，直接给予不通过，直接杜绝了这种可能性的发生。
  综上，Java中使用任何变量或引用，必须初始化，初始化就是将内存中旧的二进制数据要么清0，要么赋予你要赋的值！

2. 从顶级父类开始，按照申明顺序将给顶级父类的非static的成员属性初始化（static的只初始化一次在类加载阶段）> 用属性定义的值覆盖0值。
3. 调用顶级父类的构造函数，如果有成员属性初始化则覆盖前一个申明时初始化值。> 构造函数再次初始化，覆盖前面申明时初始化。
4. 以此类推，将所有的父级（先初始化属性，在调用构造，一层一层的构造完毕） 构造完成
5. 最后，初始化当前类的非static属性，再调用当前类的构造函数，完成所有初始化工作。

# 注意：

1、类中static部分是发生在类加载时期的，并且只初始化一次。因为类只加载一次，加载完后创建对象过程中不会再去初始化static部分的东西，所以之后根本不会再走那块初始化代码，又怎么初始化第二次呢？

2、static的优先级是高于main函数执行的，因为它是在类加载时期初始化。当static作用的东西都加载完了才执行main，当然main是第一个被使用的static方法，但是虚拟机只是找到这个方法的位置，并不会先去执行里面的内容。

2、对于类的普通成员属性初始化三个步骤：先全初始化为0，再用申明时候初始化值进行初始化，再调用构造函数进行初始化。

实例程序：(来源于Thinking in Java)

```java
//: reusing/Beetle.java
// The full process of initialization.
import static net.mindview.util.Print.*;

class Insect {
  private int i = 9;
  protected int j;
  Insect() {
    print("i = " + i + ", j = " + j);
    j = 39;
  }
  private static int x1 =
    printInit("static Insect.x1 initialized");
  static int printInit(String s) {
    print(s);
    return 47;
  }
}

public class Beetle extends Insect {
  private int k = printInit("Beetle.k initialized");
  public Beetle() {
    print("k = " + k);
    print("j = " + j);
  }
  private static int x2 =
    printInit("static Beetle.x2 initialized");
  public static void main(String[] args) {
    print("Beetle constructor");
    Beetle b = new Beetle();
  }
} 
print("Beetle constructor");
    Beetle b = new Beetle();
  }
} 
/* Output:
static Insect.x1 initialized  
static Beetle.x2 initialized //1.类加载和初始化静态x1,x2：只会初始化一次！
Beetle constructor //2.进入main函数
i = 9, j = 0  
//3.new Beetle()，先初始化父类>申请父类内存>初始化为0>初始化i=9，j=0>调用Insect()构造函数>输出ij值>初始化j=39
Beetle.k initialized //4.初始化子类>申请子类内存>..>初始化k，输出改行>调用构造Beetle()>输出下面的k，j
k = 47
j = 39
*///:~
```





