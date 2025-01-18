---
date: 2017-08-13 16:40
status: public
title: 02-CountDownLatch
---

### CountDownLatch
#### 定义
[CountDownLatch](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/CountDownLatch.html)是一个同步工具类，它允许一个或多个线程一直等待，直到其他线程的操作执行完后再执行。比如，创建一个数量为10的ContDownLatch，当10个线程都完成任务后，再执行其它操作。  
CountDownLatch是在java1.5被引入的，跟它一起被引入的并发工具类还有CyclicBarrier、Semaphore、[ConcurrentHashMap](http://howtodoinjava.com/core-java/multi-threading/best-practices-for-using-concurrenthashmap/)和[BlockingQueue](http://howtodoinjava.com/core-java/multi-threading/how-to-use-blockingqueue-and-threadpoolexecutor-in-java/)，它们都存在于java.util.concurrent包下。CountDownLatch这个类能够使一个线程等待其他线程完成各自的工作后再执行。例如，应用程序的主线程希望在负责启动框架服务的线程已经启动所有的框架服务之后再执行。
CountDownLatch是通过一个计数器来实现的，计数器的初始值为线程的数量。每当一个线程完成了自己的任务后，计数器的值就会减1。当计数器值到达0时，它表示所有的线程已经完成了任务，然后在闭锁上等待的线程就可以恢复执行任务。
![CountDownLatch](/_image/CountDownLatch-1.png)    

#### 原理
CountDownLatch.java类中定义的构造函数：
```
//Constructs a CountDownLatch initialized with the given count.
public void CountDownLatch(int count) {...}
```  
构造器中的计数值（count）实际上就是闭锁需要等待的线程数量。这个值只能被设置一次，而且CountDownLatch没有提供任何机制去重新设置这个计数值。  
与CountDownLatch的第一次交互是主线程等待其他线程。主线程必须在启动其他线程后立即调用**CountDownLatch.await()**方法。这样主线程的操作就会在这个方法上阻塞，直到其他线程完成各自的任务。  
其他N 个线程必须引用闭锁对象，因为他们需要通知CountDownLatch对象，他们已经完成了各自的任务。这种通知机制是通过 CountDownLatch.countDown()方法来完成的；每调用一次这个方法，在构造函数中初始化的count值就减1。所以当N个线程都调 用了这个方法，count的值等于0，然后主线程就能通过await()方法，恢复执行自己的任务。

#### 使用场景 
1、**实现最大的并行性**：有时我们想同时启动多个线程，实现最大程度的并行性。例如，我们想测试一个单例类。如果我们创建一个初始计数为1的CountDownLatch，并让所有线程都在这个锁上等待，那么我们可以很轻松地完成测试。我们只需调用 一次countDown()方法就可以让所有的等待线程同时恢复执行。  
2、**开始执行前等待n个线程完成各自任务**：例如应用程序启动类要确保在处理用户请求前，所有N个外部系统已经启动和运行了。  
3、**死锁检测**：一个非常方便的使用场景是，你可以使用n个线程访问共享资源，在每次测试阶段的线程数目是不同的，并尝试产生死锁。    

#### 示例程序
[示例代码](https://github.com/Imayman/java-core-learning-example/tree/master/src/main/java/org/javacore/concurrent/countdownlatch)  

#### 源代码分析
##### 构造函数
1.CountDownLatch(int count),内部采用了AQS的实现Sync  
```
public boolean tryReleaseShared(int releases) {
       // Decrement count; signal when transition to zero
        for (;;) {
            int c = getState();
            if (c == 0)
                return false;
            int nextc = c-1;
            if (compareAndSetState(c, nextc))
                return nextc == 0;
        }
}
```     

2.通过无线循环以及原子操作CAS来做资源的释放。      
tryAcquireShared用于await()方法中，await()调用tryAcquireShared方法判断当前技术是否为0，否则一直等待，直到为0.  
```  
public int tryAcquireShared(int acquires) {
        return getState() == 0 ? 1 : -1;
}
```   

##### 主要方法  
1.	**countDown()** 递减计数，当为0后，则唤醒所有等待的线程  
2.	await() 在计数器为0前一直等待  
3.	await(long timeout, TimeUnit unit) 在计数器为0前一直等待，除非过了指定的时间  
4.	getCount() 返回当前计数  

#### 参考资料
[深入浅出 Java Concurrency (10): 锁机制 part 5 闭锁 (CountDownLatch)](http://www.blogjava.net/xylz/archive/2010/07/09/325612.html)