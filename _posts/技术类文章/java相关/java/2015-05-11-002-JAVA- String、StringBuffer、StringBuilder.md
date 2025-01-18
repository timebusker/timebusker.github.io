---
layout:     post
title:      JAVA- String、StringBuffer、StringBuilder
date:       2015-05-11
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - JAVA
---

> 理解 Java 的字符串，String、StringBuffer、StringBuilder 有什么区别？

#### 典型回答
`String`是 Java 语言非常基础和重要的类，提供了构造和管理字符串的各种基本逻辑。它是典型
的 Immutable(不可改变的) 类，被声明成为 final class，所有属性也都是 final 的。也由于它的不可变性，
类似拼接、裁剪字符串等动作，都会产生新的 String 对象。由于字符串操作的普遍性，所以相
关操作的效率往往对应用性能有明显影响。

`StringBuffer`是为解决上面提到拼接产生太多中间对象的问题而提供的一个类，它是 Java 1.5
中新增的，我们可以用 append 或者 add 方法，把字符串添加到已有序列的末尾或者指定位
置。StringBuffer 本质是一个线程安全的可修改字符序列，它保证了线程安全，也随之带来了额
外的性能开销，所以除非有线程安全的需要，不然还是推荐使用它的后继者，也就是
StringBuilder。

`StringBuilder`在能力上和 StringBuffer 没有本质区别，但是它去掉了线程安全的部分，有效减
小了开销，是绝大部分情况下进行字符串拼接的首选。

### 分析
#### 封装字符数组
String类内部用一个字符数组表示字符串，实例变量定义为：`private final char value[];`

String有两个构造方法，可以根据char数组创建String。

```
public String(char value[])
public String(char value[], int offset, int count)
```
需要说明的是，String会根据参数新创建一个数组，并拷贝内容，而不会直接用参数中的字符数组。
String中的大部分方法，内部也都是操作的这个字符数组。

- length()方法返回的就是这个数组的长度
- substring()方法就是根据参数，调用构造方法String(char value[], int offset, int count)新建了一个字符串
- indexOf查找字符或子字符串时就是在这个数组中进行查

#### 字符串池
在字符串中存在一个非常特殊的地方，那就是字符串池。每当我们创建一个字符串对象时，首先就会检查字符串池中是否存在面值相等的字符串，如果有，
则不再创建，直接放回字符串池中对该对象的引用，若没有则创建然后放入到字符串池中并且返回新建对象的引用。这个机制是非常有用的，因为可以提高效率，
减少了内存空间的占用。所以在使用字符串的过程中，推荐使用直接赋值（即String s=”aa”），除非有必要才会新建一个String对象（即String s = new String(”aa”)）。

#### String类的不可变性
与包装类类似，String类也是不可变类，即对象一旦创建，就没有办法修改了。String类也声明为了final，不能被继承，内部char数组value也是final的，初始化后就不能再变了。

String类中提供了很多看似修改的方法，其实是通过创建新的String对象来实现的，原来的String对象不会被修改。

```
public String concat(String str) {
    int otherLen = str.length();
    if (otherLen == 0) {
        return this;
    }
    int len = value.length;
    char buf[] = Arrays.copyOf(value, len + otherLen);
    str.getChars(buf, len);
    return new String(buf, true);
}
```

通过Arrays.copyOf方法创建了一块`新的字符数组`，拷贝原内容，然后通过new创建了一个新的String。

#### StringBuffer
StringBuffer和String一样都是用来存储字符串的，只不过由于他们内部的实现方式不同，导致他们所使用的范围不同，对于StringBuffer而言，
他在处理字符串时，若是对其进行修改操作，它并不会产生一个新的字符串对象，所以说在内存使用方面它是优于String的。

其实在使用方法，StringBuffer的许多方法和String类都差不多，所表示的功能几乎一模一样，只不过在修改时StringBuffer都是修改自身，而String类则是产生一个新的对象，
这是他们之间最大的区别。同时StringBuffer是不能使用=进行初始化的，它必须要产生StringBuffer实例，也就是说你必须通过它的构造方法进行初始化。

#### StringBuilder
StringBuilder也是一个可变的字符串对象，他与StringBuffer不同之处就在于它是线程不安全的，基于这点，它的速度一般都比StringBuffer快。
与StringBuffer一样，StringBuider的主要操作也是append与insert方法。这两个方法都能有效地将给定的数据转换成字符串，然后将该字符串的字符添加或插入到字符串生成器中。

#### 正确使用String、StringBuffer、StringBuilder
对于String是否为线程安全，鄙人也不是很清楚，原因：String不可变，所有的操作都是不可能改变其值的，是否存在线程安全一说还真不好说？
但是如果硬要说线程是否安全的话，因为内容不可变，永远都是安全的。

在使用方面由于String每次修改都需要产生一个新的对象，所以对于经常需要改变内容的字符串最好选择StringBuffer或者StringBuilder.
而对于StringBuffer，每次操作都是对StringBuffer对象本身，它不会生成新的对象，所以StringBuffer特别适用于字符串内容经常改变的情况下。

但是并不是所有的String字符串操作都会比StringBuffer慢，在某些特殊的情况下，String字符串的拼接会被JVM解析成StringBuilder对象拼接，
在这种情况下String的速度比StringBuffer的速度快。

```
# 编译前
String name = ”I  ” + ”am ” + timebusker ” ;

# 编译后
StringBuffer name = new StringBuffer(”I ”).append(” am ”).append(” timebusker ”);
```

##### 三者使用的场景做如下概括
- String：在字符串不经常变化的场景中可以使用String类，如：常量的声明、少量的变量运算等。

- StringBuffer：在频繁进行字符串的运算（拼接、替换、删除等），并且运行在多线程的环境中，则可以考虑使用StringBuffer，例如XML解析、HTTP参数解析和封装等。

- StringBuilder：在频繁进行字符串的运算（拼接、替换、删除等），非线程安全安全要求，则可以考虑使用。