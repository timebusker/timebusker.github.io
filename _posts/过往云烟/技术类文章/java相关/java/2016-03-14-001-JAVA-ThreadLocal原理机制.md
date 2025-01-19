---
layout:     post
title:      JAVA-多线程之隔离技术ThreadLocal源码详解
date:       2016-03-14
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - JAVA
---

> 对`ThreadLocal`和`InheritableThreadLocal`,`TransmittableThreadLocal`的原理和源码进行深入分析,并举例讲解,其中前两个是JDK自带的，
原理相对比较简单,其解决了单线程环境和在单线程中又创建线程(父子线程)中线程隔离的问题。`TransmittableThreadLocal`主要是解决,线程池中线程复用的场景。

#### ThreadLocal(`线程本地存储`)的原理
`ThreadLocal`其实就相当于一个Map集合,只不过这个Map 的Key是固定的,都是当前线程。
它`能够对线程隔离,让每个线程都能拥有属于自己的变量空间,线程之间互相不影响`。
之所以能起到线程隔离的作用,是因为`Key就是当前的线程`,所以每个线程的值都是隔离的。 

```
# 查看get/set方法
public T get() {
    // 使用当前线程从线程中获取属性
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null) {
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
            @SuppressWarnings("unchecked")
            T result = (T)e.value;
            return result;
        }
    }
    return setInitialValue();
}

public void set(T value) {
    // 使用当前线程作为KEY保存
    Thread t = Thread.currentThread();
	// 从Thread中拿到一个Map，然后把value放到这个线程的map中
	// 因为每个线程都有一个自己的Map，也就是threadLocals，从而起到了线程隔离的作用
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
}
```

#### ThreadLocal过程分析
在每个线程`Thread`内部有一个`ThreadLocal.ThreadLocalMap`类型的成员变量`threadLocals`，`threadLocals`就是用来`存储实际的变量副本`的，`键值为当前Thread变量`，value为变量副本（即T类型的变量）。
初始时，在Thread里面，threadLocals为空，当通过`ThreadLocal`变量调用`get()`方法或者`set()`方法，就会对`Thread类`中的`threadLocals`进行初始化，并且`以当前Thread变量`为键值，以ThreadLocal要保存的副本变量为value，存到threadLocals。

#### ThreadLocal使用场景
本地化隔离保存线程特有的变量信息。 

最常见的ThreadLocal使用场景为 用来解决 数据库连接、Session管理等。

#### 单线程隔离
所谓单线程隔离就是设置`ThreadLocal<Object>`的作用域。

单线程隔离，其实是为了和`父子线程`区分开来。

```
public class SingleThreadLocalTest {

    public static void main(String[] args) {
        SingleThreadLocalTest test = new SingleThreadLocalTest();
        test.thread1();
        test.thread2();
    }

    private void thread1() {
        ThreadLocal<Object> localObject = new ThreadLocal();
        localObject.set("++++++++++++++++++++++++");
        System.err.println(Thread.currentThread().getName() + "\t" + localObject.get());
    }

    private void thread2() {
        ThreadLocal<Object> localObject = new ThreadLocal();
        localObject.set("-------------------------");
        System.err.println(Thread.currentThread().getName() + "\t" + localObject.get());
    }
}
```

#### 父子线程隔离
父子线程：当我们创建一个线程,在线程内有去运行另一个线程的时候，视为父子线程关系。

```
public class ThreadLocalTest {

    private static ThreadLocal<Object> localObject = new ThreadLocal();

    /**
     * 父子线程控制
     *
     * @param args
     */
    public static void main(String[] args) {
        for (int i = 0; i < 5; i++) {
            final int key = i;
            localObject.set("B______" + key);
            Thread t = new Thread(new Runnable() {
                @Override
                public void run() {
                    localObject.set("A______" + key);
                    System.err.println(Thread.currentThread().getName() + "\t" + localObject.get().toString());
                }
            });
            t.start();
            System.err.println(Thread.currentThread().getName() + "\t" + localObject.get());
        }
        System.err.println(Thread.currentThread().getName() + "\t" + localObject.get());
    }
}
```

##### 父子线程变量继承
父子线程变量继承：即在子线程中使用父线程的私有变量。

在Thread类源码中有两个同类属性：

> ThreadLocal.ThreadLocalMap threadLocals = null; (不可继承)
> ThreadLocal.ThreadLocalMap inheritableThreadLocals = null; (可继承)

`inheritableThreadLocals`之所以可继承，是因为在`Thread.init()`方法中做了实现，在线程初始化时完成线程的继承传递，子线程继承父子线程属性后，`直接赋值到子线程的threadLocals中`。
![image](img/older/java-coding/5/1.png) 

```
public class InheritableThreadLocalsTest {

    private static ThreadLocal<Object> localObject = new InheritableThreadLocal<>();

    /**
     * 父子线程控制
     *
     * @param args
     */
    public static void main(String[] args) {
        for (int i = 0; i < 5; i++) {
            final int key = i;
            localObject.set("B______" + key);
            Thread t = new Thread(new Runnable() {
                @Override
                public void run() {
                    System.err.println(Thread.currentThread().getName() + "\t" + localObject.get().toString());
                }
            });
            t.start();
            System.err.println(Thread.currentThread().getName() + "\t" + localObject.get());
        }
        System.err.println(Thread.currentThread().getName() + "\t" + localObject.get());
    }
}
```

#### 线程池线程复用隔离
在线程池中核心线程用完，并不会直接被回收,而是返回到线程池中，既然是重新利用，
那么久不会重新创建线程，不会创建线程，父子之间就不会传递（`即不重新创建子线程，不能获取到最新父线程属性值`）。


#### 总结
- `ThreadLocal`基础实现 (原理: 保存着线程中)
- `inheritableThreadLocals`实现了父子直接的传递 （原理: 可继承的变量空间,在Thread初始化`init`方法时候给子赋值）
- `TransmittableThreadLocal`实现线程复用 (原理: 在每次线程执行时候重新给`ThreadLocal`赋值)

