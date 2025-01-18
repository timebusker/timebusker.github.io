---
layout:     post
title:      JAVA-Object中所有方法简介
date:       2015-05-11
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - JAVA
---

我们知道所有的类都是继承于`Object`，所以我们编写的类默认都具有这些方法，究竟这些方法做什么用，
需要让所有的对象都拥有，我将一一来解释。 

首先了解回调`callback`方法，所谓回调方法就是程序在运行特定功能时`JVM`会自动调动这些方法，
假设你使用`System.out.print(obj)`打印出对象`obj`信息，则运行时`JVM`会自动调用`obj`对象的`toString()`方法，
`toString()`方法就是回调方法。理解回调方法后，下面我们来看这些方法： 

#### clone()
`clone`方法主要用于克隆当前对象，`制作本地对象`，这肯定需要在`所有对象中所拥有`，在讲解参数按值传递和按引用传递时再讲解它的用法；
但`clone()`在`Object`中`protected`方法，所以子类实现需要覆盖此方法并实现`Cloneable`接口，那样才能在外部实现`clone`功能。

```
@Override
protected Object clone() throws CloneNotSupportedException {
    return super.clone();
}
```

#### equals()
主要用于比较两个对象是否相等，查看Object源代码(要多查看源代码便于自己理解)知道，默认的equals()是：

```
@Override
public boolean equals(Object obj) {
    return super.equals(obj);
}
```

只有当两个对象地址相同时才返回true，所以默认的equals()方法根本没什么用，因为对象在内存中的地址(基本类型不同)肯定不同的。


#### hashCode()
散列码（hash code）是由对象导出的一个整型值，散列码是没有规律的。默认的hashCode()返回的值就是对象在内存中的地址。

```
@Override
public int hashCode() {
    return super.hashCode();
}
```

#### toString()
默认的toString()方法就是打印出对象的地址。

```
@Override
public String toString() {
    return super.toString();
}
```


> `toString()`和`equals()`方法内部是通过`hashCode()`的返回值来实现的，`hashCode()`是本地(`native`)方法。
> 所谓本地方法就是使用其他语言(C或C++)编写的，我们可以通过本地接口(JNI)编写本地方法。

#### finalize()
是GC清理对象之前所调用的清理方法，是回调方法，我们可以覆盖这个方法写一些清理的代码，GC会自动扫描没有引用的对象，
即对象赋值为null；可以通过调用System.runFinalization()或System.runFinalizersOnExit()强制GC清理该对象前调用finalize()方法，
GC有时不会调用对象的finalize()方法(由JVM决定)。

```
@Override
protected void finalize() throws Throwable {
    super.finalize();
}
```

#### wait()
执行了该方法的线程`释放对象的锁`，JVM会把该线程放到对象的等待池中。该线程等待其它线程唤醒。

#### notify()
执行该方法的线程`唤醒`在对象的等待池中等待的一个线程，JVM从对象的等待池中`随机选择一个线程`，把它转到对象的锁池中。

> 通常可以使用synchronized和notify，notifyAll以及wait方法来实现线程之间的数据传递及控制。

对于对象obj来说：
- `obj.wait()：`该方法的调用，使得调用该方法的执行线程（T1）`放弃`obj的对象锁并阻塞，直到别的线程调用了
`obj的notifyAll方法`、或者别的线程调用了`obj的notify方法`且JVM选择唤醒（T1），被唤醒的线程（T1）依旧阻塞在wait方法中，
与其它的线程一起争夺obj的对象锁，直到它再次获得了obj的对象锁之后，才能从wait方法中返回。
（除了notify方法，wait还有`带有时间参数`的版本，在等待了超过所设时间之后，T1线程一样会被唤醒，进入到争夺obj对象锁的行列；
另外`中断`可以`直接跳出wait方法`）。

- `obj.notify()：`该方法的调用，会从所有正在等待obj对象锁的线程中，唤醒其中的一个（选择算法依赖于不同实现），
被唤醒的线程此时加入到了obj对象锁的争夺之中，然而该notify方法的执行线程此时并未释放obj的对象锁，
而是离开`synchronized`代码块时释放。因此在notify方法之后，synchronized代码块结束之前，所有其他被唤醒的，
等待obj对象锁的线程依旧被阻塞。

- `obj.notifyAll()：`与notify的区别是，该方法会唤醒所有正在等待obj对象锁的线程。（不过同一时刻，也只有一个线程可以拥有obj的对象锁）

> 方法调用一定要处于synchronized关键字包含的代码中，即锁控制的区域。

```
int nsize=5;
synchronized(obj){
   if(nsize>=5){
      nsize--;
      //该句执行后，当前线程阻塞，后面代码不会执行
      obj.wait(); 
   }
   nsize++;
   //释放当前对象锁
   obj.notify(); 
}
# 代码使得nszie始终会小于等于5，超过5时自动阻塞
```