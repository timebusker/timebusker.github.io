---
layout:     post
title:      HikariCP源码解读
date:       2019-02-15
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - JAVA杂记
---

#### 简介
HikariCP是一款高效稳定的数据库连接池，性能方面与其他同类产品相比能高出近10倍，尤其连接取用的设计极大的提高可靠性，
对于数据库连接中断的情况，通过测试getConnection()，各种CP的不相同处理方法如下： 
- HikariCP：等待5秒钟后，如果连接还是没有恢复，则抛出一个SQLExceptions 异常；后续的getConnection()也是一样处理
- C3P0：完全没有反应，没有提示，也不会在“CheckoutTimeout”配置的时长超时后有任何通知给调用者；然后等待2分钟后终于醒来了，返回一个error 
- Tomcat：返回一个connection，然后……调用者如果利用这个无效的connection执行SQL语句……结果可想而知；大约55秒之后终于醒来了，这时候的getConnection()终于可以返回一个error，但没有等待参数配置的5秒钟，而是立即返回error 
- BoneCP：跟Tomcat的处理方法一样；也是大约55秒之后才醒来，有了正常的反应，并且终于会等待5秒钟之后返回error了

##### HikariCP的优势： 
- 字节码精简：优化代码，直到编译后的字节码最少，这样，CPU缓存可以加载更多的程序代码； 
- 优化代理和拦截器：减少代码，例如HikariCP的Statement proxy只有100行代码，只有BoneCP的十分之一； 
- 自定义数组类型（FastList）代替ArrayList：避免每次get()调用都要进行range check，避免调用remove()时的从头到尾的扫描； 
- 自定义集合类型（ConcurrentBag）：提高并发读写的效率； 
- 其他针对BoneCP缺陷的优化，比如对于耗时超过一个CPU时间片的方法调用的研究

#### 配置介绍及对应源码
##### 配置使用
HikariCP的配置类HikariConfig对Properties有很好的兼容，可通过配置环境变量hikaricp.configurationFile设置配置文件路径。

```
// 通过设置hikaricp.configurationFile环境变量，即可无参加载配置文件
public HikariConfig() {
   dataSourceProperties = new Properties();
   healthCheckProperties = new Properties();

   minIdle = -1;
   maxPoolSize = -1;
   maxLifetime = MAX_LIFETIME;
   connectionTimeout = CONNECTION_TIMEOUT;
   validationTimeout = VALIDATION_TIMEOUT;
   idleTimeout = IDLE_TIMEOUT;
   initializationFailTimeout = 1;
   isAutoCommit = true;

   String systemProp = System.getProperty("hikaricp.configurationFile");
   if (systemProp != null) {
      loadProperties(systemProp);
   }
}
```

或

```
// 或者传入Properties属性配置对象初始化
public HikariConfig(Properties properties) {
   this();
   PropertyElf.setTargetFromProperties(this, properties);
}
```

或

```
// 或者 指定Porperty类型文件加载
public HikariConfig(String propertyFileName){
   this();
   loadProperties(propertyFileName);
}
```

##### 参数配置
- poolName : 连接池的名称，用于唯一标识一个连接池，通常作用于`jmx监控`和`日志分析`等场合。 
- dataSourceClassName ：用于指定连接池使用的`DataSource`的类，使用`dataSourceProperties`的参数变量进行辅助 
- jdbcUrl ：和`dataSourceClassName`二者选一进行使用（出现`dataSourceClassName`时，当前参数不生效！）,搭配 `driverClassName`进行使用。 
- driverClassName ：用于旧式连接，指定driver的class，源码如下：
- autoCommit ：是否自动提交，**默认是true**
- username ：用户名
- password ：密码
- connectionTimeout ：获取连接的超时时间，超过后会报SQLException，**默认值为30s**
- idleTimeout ：连接空闲时间，housekeeper使用
- maxLifetime ：连接最大存活时间，超出时间后后台会对连接进行关闭，**默认30min（对正在使用的连接不会立即处理）**
- validationTimeout ：验证超时时间（connection.isVaild(validationTimeout)）
- minimumIdle ：连接池最小空闲数量
- maximumPoolSize ：连接池最大数量
- registerMbeans ：是否注册jmx监控（HikariConfig和HikariPool都实现了MXBean接口）

#### [ConcurrentBag——HikariCP连接管理快速的关键点之一](https://mp.weixin.qq.com/s?__biz=MzUzNTY4NTYxMA==&mid=2247483799&idx=1&sn=73794ef10f6c1b529d50657a2f975598&chksm=fa80f112cdf77804a4aa3418c89400f90a32954873aa0701ebb784cc2d082be16d80ce539f1b&scene=21#wechat_redirect)
HikariCP连接池是基于自主实现的ConcurrentBag完成的数据连接的多线程共享交互，是HikariCP连接管理快速的其中一个关键点。

ConcurrentBag是一个专门的并发类，在连接池（多线程数据交互）的实现上具有比`LinkedBlockingQueue`和`LinkedTransferQueue`更优越的性能。 
ConcurrentBag采用了queue-stealing的机制获取元素：首先尝试从ThreadLocal中获取属于当前线程的元素来避免锁竞争，如果没有可用元素则扫描公共集合、再次从共享的CopyOnWriteArrayList中获取。


其通过同时使用 CopyOnWriteArrayList、ThreadLocal和SynchronousQueue进行并发数据交互。 
- CopyOnWriteArrayList：负责存放ConcurrentBag中全部用于出借的资源 
- ThreadLocal：用于加速线程本地化资源访问 
- SynchronousQueue：用于存在资源等待线程时的第一手资源交接

```
private final CopyOnWriteArrayList<T> sharedList;

private final ThreadLocal<List<Object>> threadList;

private final SynchronousQueue<T> handoffQueue;
```

ConcurrentBag中全部的资源均只能通过add方法进行添加，只能通过remove方法进行移出。

其中，Java线程中的Thread.yield( )方法，译为线程让步。顾名思义，就是说当一个线程使用了这个方法之后，它就会把自己CPU执行的时间让掉，`让自己或者其它的线程运行`。
yield()的作用是让步，它能让当前线程由`运行状态`进入到`就绪状态`，从而让其它具有相同优先级的等待线程获取执行权；
但是，并不能保证在当前线程调用yield()之后，其它具有相同优先级的线程就一定能获得执行权；

```
public void add(final T bagEntry) {
   if (closed) {
      LOGGER.info("ConcurrentBag has been closed, ignoring add()");
      throw new IllegalStateException("ConcurrentBag has been closed, ignoring add()");
   }
   //新添加的资源优先放入CopyOnWriteArrayList
   sharedList.add(bagEntry);
   // 当有等待资源的线程时，将资源交到某个等待线程后才返回（SynchronousQueue）
   // spin until a thread takes it or none are waiting
   while (waiters.get() > 0 && bagEntry.getState() == STATE_NOT_IN_USE && !handoffQueue.offer(bagEntry)) {
      // yield()只是使当前线程重新回到可执行状态，所以执行yield()的线程有可能在进入到可执行状态后马上又被执行。
      // yield()只能使同优先级或更高优先级的线程有执行的机会。 
      yield();
   }
}

public boolean remove(final T bagEntry) {
   if (!bagEntry.compareAndSet(STATE_IN_USE, STATE_REMOVED) && !bagEntry.compareAndSet(STATE_RESERVED, STATE_REMOVED) && !closed) {
      LOGGER.warn("Attempt to remove an object from the bag that was not borrowed or reserved: {}", bagEntry);
      return false;
   }
   final boolean removed = sharedList.remove(bagEntry);
   if (!removed && !closed) {
      LOGGER.warn("Attempt to remove an object from the bag that does not exist: {}", bagEntry);
   }
   return removed;
}
```

ConcurrentBag中通过`borrow方法进行数据资源借用`，`通过requite方法进行资源回收`，注意其中borrow方法只提供对象引用，不移除对象，
因此使用时通过borrow取出的对象必须通过requite方法进行放回，否则容易导致内存泄露！

```
public T borrow(long timeout, final TimeUnit timeUnit) throws InterruptedException {
   // 优先查看有没有可用的本地化的资源
   final List<Object> list = threadList.get();
   for (int i = list.size() - 1; i >= 0; i--) {
      final Object entry = list.remove(i);
      @SuppressWarnings("unchecked")
      final T bagEntry = weakThreadLocals ? ((WeakReference<T>) entry).get() : (T) entry;
      if (bagEntry != null && bagEntry.compareAndSet(STATE_NOT_IN_USE, STATE_IN_USE)) {
         return bagEntry;
      }
   }

   // 然后再查看sharedList，最后看handoffQueue有无可用资源
   final int waiting = waiters.incrementAndGet();
   try {
      for (T bagEntry : sharedList) {
         if (bagEntry.compareAndSet(STATE_NOT_IN_USE, STATE_IN_USE)) {
            // If we may have stolen another waiter's connection, request another bag add.
            if (waiting > 1) {
               listener.addBagItem(waiting - 1);
            }
			// 因为可能“抢走”了其他线程的资源，因此提醒包裹进行资源添加
            return bagEntry;
         }
      }
      listener.addBagItem(waiting);
      timeout = timeUnit.toNanos(timeout);
      do {
         final long start = currentTime();
		 // 当现有全部资源全部在使用中，等待一个被释放的资源或者一个新资源
         final T bagEntry = handoffQueue.poll(timeout, NANOSECONDS);
         if (bagEntry == null || bagEntry.compareAndSet(STATE_NOT_IN_USE, STATE_IN_USE)) {
            return bagEntry;
         }
         timeout -= elapsedNanos(start);
      } while (timeout > 10_000);

      return null;
   } finally {
      waiters.decrementAndGet();
   }
}

public void requite(final T bagEntry) {
   // 将状态转为未在使用
   bagEntry.setState(STATE_NOT_IN_USE);
   // 判断是否存在等待线程，若存在，则直接转手资源
   for (int i = 0; waiters.get() > 0; i++) {
      if (bagEntry.getState() != STATE_NOT_IN_USE || handoffQueue.offer(bagEntry)) {
         return;
      } else if ((i & 0xff) == 0xff) {
         parkNanos(MICROSECONDS.toNanos(10));
      } else {
         yield();
      }
   }
   // 否则，进行资源本地化
   final List<Object> threadLocalList = threadList.get();
   if (threadLocalList.size() < 50) {
      // weakThreadLocals 是用来判断是否使用弱引用
      threadLocalList.add(weakThreadLocals ? new WeakReference<>(bagEntry) : bagEntry);
   }
}
// 设置弱引用属性
private boolean useWeakThreadLocals() {
   try {
      // 人工指定是否使用弱引用，但是官方不推荐进行自主设置
      if (System.getProperty("com.zaxxer.hikari.useWeakReferences") != null) {   // undocumented manual override of WeakReference behavior
         return Boolean.getBoolean("com.zaxxer.hikari.useWeakReferences");
      }
      // 默认通过判断初始化的ClassLoader是否是系统的ClassLoader来确定
      return getClass().getClassLoader() != ClassLoader.getSystemClassLoader();
   } catch (SecurityException se) {
      return true;
   }
}
```

#### FastList——HikariCP连接管理快速的关键点之二
`FastList`是一个`List`接口的精简实现，只实现了接口中必要的几个方法。`JDK ArrayList`每次调用`get()`方法时都会进行`rangeCheck`检查索引是否越界，
FastList的实现中去除了这一检查，只要保证索引合法那么rangeCheck就成为了不必要的计算开销(当然开销极小)。
此外，`HikariCP`使用`List`来保存打开的`Statement`，当Statement关闭或Connection关闭时需要将对应的Statement从List中移除。
通常情况下，同一个Connection创建了多个Statement时，后打开的Statement会先关闭。
`ArrayList`的`remove(Object)`方法是从头开始遍历数组，而`FastList是从数组的尾部开始遍历`，因此更为高效。

简而言之就是：**自定义数组类型（FastList）代替ArrayList：避免每次get()调用都要进行range check，避免调用remove()时的从头到尾的扫描**

```
# java.util.ArrayList的get方法
public E get(int index) {
    rangeCheck(index);
    return elementData(index);
}
# rangeCheck
private void rangeCheck(int index) {
     if (index >= size)
         throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
}

# com.zaxxer.hikari.util.FastList的get方法
public T get(int index) {
    return elementData[index];
}


# ArrayList的remove(Object)方法
public boolean remove(Object o) {
    if (o == null) {
        for (int index = 0; index < size; index++)
            if (elementData[index] == null) {
                fastRemove(index);
                return true;
            }
    } else {
        for (int index = 0; index < size; index++)
            if (o.equals(elementData[index])) {
                fastRemove(index);
                return true;
            }
    }
    return false;
}

# FastList的remove(Object方法)
public boolean remove(Object element) {
   for (int index = size - 1; index >= 0; index--) {
      if (element == elementData[index]) {
         final int numMoved = size - index - 1;
         if (numMoved > 0) {
            System.arraycopy(elementData, index + 1, elementData, index, numMoved);
         }
         elementData[--size] = null;
         return true;
      }
   }
   return false;
}
```

#### Proxy*代理类——Javassist委托实现动态代理
- **ProxyConnection：**(proxy class for java.sql.Connection)
- **ProxyStatement：**(proxy class for java.sql.Statement)
- **ProxyPreparedStatement：**(proxy class for java.sql.PreparedStatement)
- **ProxyCallableStatement：**(proxy class for java.sql.CallableStatement)
- **ProxyResultSet：**(proxy class for java.sql.ResultSet)

- **ProxyFactory**这个工厂类，对上面的五个代理类提供的方法只有一行直接抛异常`IllegalStateException`的代码，
并且提示`You need to run the CLI build and you need target/classes in your classpath to run。`
注释写着`Body is replaced (injected) by JavassistProxyFactory`，其实方法body中的代码是在`编译时调用` `JavassistProxyFactory`才生成的。

- **JavassistProxyFactory**使用Javassist生成动态代理，是因为其速度更快，相比于JDK Proxy生成的字节码更少，精简了很多不必要的字节码。  

`javassist`是一个字节码类库，可以用他来`动态生成类`，`动态修改类`等等，还有一个比较常见的用途是`AOP`，比如对一些类`统一加权限过滤`，`加日志监控`等等。
Javassist 不仅是一个处理字节码的库，还有一项优点：可以用 Javassist 改变 Java 类的字节码，而无需真正了解关于字节码或者 Java 虚拟机(Java virtual machine JVM)结构的任何内容。比起在单条指令水平上工作的框架，它确实使字节码操作更可具有可行性了。

Javassist 使您可以检查、编辑以及创建 Java 二进制类。检查方面基本上与通过 Reflection API 直接在 Java 中进行的一样，但是当想要修改类而不只是执行它们时，则另一种访问这些信息的方法就很有用了。这是因为 JVM 设计上并没有提供在类装载到 JVM 中后访问原始类数据的任何方法，这项工作需要在 JVM 之外完成。

Javassist 使用 javassist.ClassPool 类跟踪和控制所操作的类。这个类的工作方式与 JVM 类装载器非常相似，但是有一个重要的区别是它不是将装载的、要执行的类作为应用程序的一部分链接，类池使所装载的类可以通过 Javassist API 作为数据使用。可以使用默认的类池，它是从 JVM 搜索路径中装载的，也可以定义一个搜索您自己的路径列表的类池。甚至可以直接从字节数组或者流中装载二进制类，以及从头开始创建新类。

装载到类池中的类由 javassist.CtClass 实例表示。与标准的 Java java.lang.Class 类一样， CtClass 提供了检查类数据（如字段和方法）的方法。不过，这只是 CtClass 的部分内容，它还定义了在类中添加新字段、方法和构造函数、以及改变类、父类和接口的方法。奇怪的是，Javassist 没有提供删除一个类中字段、方法或者构造函数的任何方法。

字段、方法和构造函数分别由 javassist.CtField、javassist.CtMethod 和 javassist.CtConstructor 的实例表示。这些类定义了修改由它们所表示的对象的所有方法的方法，包括方法或者构造函数中的实际字节码内容。

###### 动态代理的性能对比
- ASM和JAVAASSIST字节码生成方式不相上下，都很快，是CGLIB的5倍。
- CGLIB次之，是JDK自带的两倍。
- JDK自带的再次之，因JDK1.6对动态代理做了优化，如果用低版本JDK更慢，要注意的是JDK也是通过字节码生成来实现动态代理的，而不是反射。
- JAVAASSIST提供者动态代理接口最慢，比JDK自带的还慢。  (这也是为什么网上有人说JAVAASSIST比JDK还慢的原因，用JAVAASSIST最好别用它提供的动态代理接口，而可以考虑用它的字节码生成方式)

##### 源码解析
generateProxyClass负责生成实际使用的代理类字节码，modifyProxyFactory对应修改工厂类中的代理类获取方法。

#### 物理连接生命周期介绍
- HikariCP中的连接取用流程如下： 
![image](/img/older/java-coding/hikaricp-1.png)    

其中HikariPool负责对资源连接进行管理，而ConcurrentBag则是作为物理连接的共享资源站，PoolEntry则是对物理连接的1-1封装。   

PoolEntry通过borrow方法从bag中取出，之后通过PoolEntry.createProxyConnection调用工厂类生成HikariProxyConnection返回。

![image](/img/older/java-coding/hikaricp-2.png)

HikariProxyConnection调用close方法时调用了PooleEntry的recycle方法，之后通过HikariPool调用了ConcurrentBag的requite放回。
（poolEntry通过borrow从bag中取出，再通过requite放回。资源成功回收）。

- HikariCP中的连接生成流程如下： 
![image](/img/older/java-coding/hikaricp-3.png) 

HikariCP中通过独立的线程池addConnectionExecutor进行新连接的生成，连接生成方法为PoolEntryCreator。

物理链接的生成只由PoolBase的newConnection()实现，之后封装成PoolEntry，通过Bag的add方法加入ConcurrentBag。

当ConcurrentBag存在等待线程，或者有连接被关闭时，会触发IBagItemListener的addBagItem(wait)方法，调用PoolEntryCreator进行新连接的生成。

- HikariCP中的连接关闭流程如下：
![image](/img/older/java-coding/hikaricp-4.png) 

HikariCP中通过独立的线程池closeConnectionExecutor进行物理连接的关闭。出现以下三种情况时会触发连接的自动关闭： 
- 连接断开； 
- 连接存活时间超出最大生存时间(maxLifeTime) 
- 连接空闲时间超出最大空闲时间(idleTimeout)

同时HikariPool提供evictConnection(Connection)方法对物理连接进行手动关闭。

- 以下是简要的整理连接变化导向图 
![image](/img/older/java-coding/hikaricp-5.png)
