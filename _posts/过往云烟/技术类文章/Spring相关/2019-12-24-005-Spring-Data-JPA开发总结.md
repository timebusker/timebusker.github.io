---
layout:     post
title:      Spring-Data-JPA开发总结 
date:       2019-12-24
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spring相关
---

#### 前言

Spring Data Jpa框架的目标是显著减少实现各种持久性存储的数据访问层所需的样板代码量。
Spring Data Jpa存储库抽象中的中央接口是Repository。它需要领域实体类以及领域实体ID类型作为类型参数来进行管理。
该接口主要用作标记接口，以捕获要使用的类型并帮助您发现扩展该接口的接口。CrudRepository、JpaRepository是更具体的数据操作抽象，
一般我们在项目中使用的时候定义我们的领域接口然后继承CrudRepository或JpaRepository即可实现实现基础的CURD方法了，但是这种用法有局限性，
不能处理超复杂的查询，而且稍微复杂的查询代码写起来也不是很优雅，所以下面看看怎么最优雅的解决这个问题。

#### 扩展接口用法

```java
@Repository
public interface SendLogRepository extends JpaRepository<SendLog,Integer> {

    /**
     * 派生的通过解析方法名称的查询
     * @param templateName
     * @return
     */
    List<SendLog> findSendLogByTemplateName(String templateName);

    /**
     * HQL
     * @param templateName
     * @return
     */
    @Query(value ="select SendLog from  SendLog s where s.templateName = :templateName")
    List<SendLog> findByTempLateName(String templateName);

    /**
     * 原生sql
     * @param templateName
     * @return
     */
    @Query(value ="select s.* from  sms_sendlog s where s.templateName = :templateName",nativeQuery = true)
    List<SendLog> findByTempLateNameNative(String templateName);
}
```

- **优点**
	+ 这种扩展接口的方式是最常见的用法，继承JpaRepository接口后，立马拥有基础的CURD功能
	+ 还可以通过特定的方法名做解析查询，这个可以算spring Data Jpa的最特殊的特性了。而且主流的IDE对这种使用方式都有比较好的自动化支持，在输入要解析的方法名时会给出提示。
	+ 可以非常方便的以注解的形式支持HQL和原生SQL
	
- **缺陷**
	+ 复杂的分页查询支持不好
	
缺陷就一条，这种扩展接口的方式要实现复杂的分页查询，有两种方式,而且这两种方式代码写起来都不怎么优雅，
而且会把大量的条件拼接逻辑写在调用查询的service层。

> 第一种实例查询(Example Query)方式:

```java
public void testExampleQuery() {
    SendLog log = new SendLog();
    log.setTemplateName("kl");
    /*
     * 注意：withMatcher方法的propertyPath参数值填写领域对象的字段值，而不是实际的表字段
     */
    ExampleMatcher matcher = ExampleMatcher.matching().withMatcher("templateName", match -> match.contains());
    Example example = Example.of(log, matcher);

    Pageable pageable = PageRequest.of(0, 10);
    Page<SendLog> logPage = repository.findAll(example, pageable);
}
```

上面代码实现的语义是模糊查询templateName等于"kl"的记录并分页，乍一看这个代码还过得去哈，其实当查询的条件多一点，
这种代码就会变得又臭又长，而且只支持基础的字符串类型的字段查询，如果查询条件有时间筛选的话就不支持了，在复杂点多表关联的话就更GG了，
所以这种方式不合格直接上黑名单了。

> 第二种继承JpaSpecificationExecutor方式：

JPA 2引入了一个标准API，您可以使用它来以编程方式构建查询。Spring Data JPA提供了使用JPA标准API定义此类规范的API。
这种方式首先需要继承JpaSpecificationExecutor接口，下面我们用这种方式实现和上面相同语义的查询：

```java
public void testJpaSpecificationQuery() {
    String templateName = "kk";
    Specification specification = (Specification) (root, query, criteriaBuilder) -> {
        Predicate predicate = criteriaBuilder.like(root.get("templateName"),templateName);
        query.where(predicate);
        return predicate;
    };

    Pageable pageable = PageRequest.of(0, 2);
    Page<SendLog> logPage = sendLogRepository.findAll(specification, pageable);
}
```

这种方式显然更对味口了吧，而且也支持复杂的查询条件拼接，比如日期等。唯一的缺憾是领袖对象的属性字符串需要手写了，
而且接口只会提供`findAll(@Nullable Specification spec, Pageable pageable)`方法，各种复杂查询逻辑拼接都要写在service层。
对于架构分层思想流行了这么多年外加强迫症的人来说实在是不能忍，如果单独封装一个Dao类编写复杂的查询又显的有点多余和臃肿

#### 最佳实践

在详细介绍最佳实践前，先思考和了解一个东西，Spring Data Jpa是怎么做到继承一个接口就能实现各种复杂查询的呢？
这里其实是一个典型的代理模式的应用，只要继承了最底层的Repository接口，在应用启动时就会帮你生成一个代理实例，
而真正的目标类才是最终执行查询的类，这个类就是:`SimpleJpaRepository`,它实现了`JpaRepository`、`JpaSpecificationExecutor`的所有接口，
所以只要基于`SimpleJpaRepository`定制`Repository`基类，就能拥有继承接口一样的查询功能，而且可以在实现类里编写复杂的查询方法了。

###### **继承SimpleJpaRepository实现类**

```java
public abstract class BaseJpaRepository<T, ID> extends SimpleJpaRepository<T, ID> {

    public EntityManager em;

    BaseJpaRepository(Class<T> domainClass, EntityManager em) {
        super(domainClass, em);
        this.em = em;
    }
}
```

构造一个SimpleJpaRepository实例，只需要一个领域对象的类型和EntityManager 实例即可，EntityManager在Spring的上下文中已经有了，
会自动注入。领域对象类型在具体的实现类中注入即可。如：

```java
@Repository
public class SendLogJpaRepository extends BaseJpaRepository<SendLog,Integer> {

    public SendLogJpaRepository(EntityManager em) {
        super(SendLog.class, em);
    }
    /**
     * 原生查询
     * @param templateName
     * @return
     */
    public SendLog findByTemplateName(String templateName){
        String sql = "select * from send_log where templateName = :templateName";
        Query query =em.createNativeQuery(sql);
        query.setParameter("templateName",templateName);
        return (SendLog) query.getSingleResult();
    }

    /**
     * hql查询
     * @param templateName
     * @return
     */
    public SendLog findByTemplateNameNative(String templateName){
        String hql = "from SendLog where templateName = :templateName";
        TypedQuery<SendLog> query =em.createQuery(hql,SendLog.class);
        query.setParameter("templateName",templateName);
       return query.getSingleResult();
    }

    /**
     *  JPASpecification 实现复杂分页查询
     * @param logDto
     * @param pageable
     * @return
     */
    public Page<SendLog> findAll(SendLogDto logDto,Pageable pageable) {
        Specification specification = (Specification) (root, query, criteriaBuilder) -> {
            Predicate predicate = criteriaBuilder.conjunction();
            if(!StringUtils.isEmpty(logDto.getTemplateName())){
                predicate.getExpressions().add( criteriaBuilder.like(root.get("templateName"),logDto.getTemplateName()));
            }
            if(logDto.getStartTime() !=null){
                predicate.getExpressions().add(criteriaBuilder.greaterThanOrEqualTo(root.get("createTime").as(Timestamp.class),logDto.getStartTime()));
            }
            query.where(predicate);
            return predicate;
        };
        return  findAll(specification, pageable);
    }
}
```

通过继承`BaseJpaRepository`，使`SendLogJpaRepository`拥有了`JpaRepository`、`JpaSpecificationExecutor`接口中定义的所有方法功能。
而且基于抽象基类中EntityManager实例，也可以非常方便的编写HQL和原生SQL查询等。最赏心悦目的是不仅拥有了最基本的CURD等功能，而且超复杂的分页查询也不分家了。
只是JpaSpecification查询方式还不是特别出彩，下面继续最佳实践

###### **集成QueryDSL结构化查询**

QueryDSL是一个框架，可通过其流畅的API来构造`静态类型`的类似SQL的查询。这是Spring Data Jpa文档中对QueryDSL的描述。
Spring Data Jpa对QueryDSL的扩展支持的比较好，基本可以无缝集成使用。QueryDSL定义了一套和JpaSpecification类似的接口，
使用方式上也类似，由于QueryDSL多了一个maven插件，可以在编译期间生成领域对象操作实体，
所以在拼接复杂的查询条件时相比较JpaSpecification显的更灵活好用，特别在关联到多表查询的时候。下面看下怎么集成：


- 丰富BaseJpaRepository基类

```java
public abstract class BaseJpaRepository<T, ID> extends SimpleJpaRepository<T, ID> {

    public EntityManager em;
	
    protected final QuerydslJpaPredicateExecutor<T> jpaPredicateExecutor;

    BaseJpaRepository(Class<T> domainClass, EntityManager em) {
        super(domainClass, em);
        this.em = em;
        this.jpaPredicateExecutor = new QuerydslJpaPredicateExecutor<>(JpaEntityInformationSupport.getEntityInformation(domainClass, em), em, SimpleEntityPathResolver.INSTANCE, getRepositoryMethodMetadata());
    }
}
```

在BaseJpaRepository基类中新增了QuerydslJpaPredicateExecutor实例，它是Spring Data Jpa基于QueryDsl的一个实现。
用来执行QueryDsl的Predicate相关查询。集成QueryDsl后，复杂分页查询的画风就变的更加清爽了，如：

```java
/**
 * QSendLog实体是QueryDsl插件自动生成的，插件会自动扫描加了@Entity的实体，生成一个用于查询的EntityPath类
 */
private  final  static QSendLog sendLog = QSendLog.sendLog;

public Page<SendLog> findAll(SendLogDto logDto, Pageable pageable) {
    BooleanExpression expression = sendLog.isNotNull();
    if (logDto.getStartTime() != null) {
        expression = expression.and(sendLog.createTime.gt(logDto.getStartTime()));
    }
    if (!StringUtils.isEmpty(logDto.getTemplateName())) {
        expression = expression.and(sendLog.templateName.like("%"+logDto.getTemplateName()+"%"));
    }
    return jpaPredicateExecutor.findAll(expression, pageable);
}
```

到目前为止，实现相同的复杂分页查询，代码已经非常的清爽和优雅了，在复杂的查询在这种模式下也变的非常的清晰。
但是，这还不是十分完美的。还有两个问题需要解决下：

> QuerydslJpaPredicateExecutor实现的方法不支持分页查询同时又有字段排序。下面是它的接口定义，可以看到，要么分页查询一步到位但是没有排序，要么排序查询返回List列表自己封装分页。

```java
public interface QuerydslPredicateExecutor<T> {
    Optional<T> findOne(Predicate predicate);
    Iterable<T> findAll(Predicate predicate);
    Iterable<T> findAll(Predicate predicate, Sort sort);
    Iterable<T> findAll(Predicate predicate, OrderSpecifier<?>... orders);
    Iterable<T> findAll(OrderSpecifier<?>... orders);
    Page<T> findAll(Predicate predicate, Pageable pageable);
    long count(Predicate predicate);
    boolean exists(Predicate predicate);
}
```

> 复杂的多表关联查询QuerydslJpaPredicateExecutor不支持

- **最终的BaseJpaRepository形态**

Spring Data Jpa对QuerDsl的支持毕竟有限，但是QueryDsl是有这种功能的，像上面的场景就需要特别处理了。最终改造的BaseJpaRepository如下：

```java
public abstract class BaseJpaRepository<T, ID> extends SimpleJpaRepository<T, ID> {

    protected final JPAQueryFactory jpaQueryFactory;
    protected final QuerydslJpaPredicateExecutor<T> jpaPredicateExecutor;
    protected final EntityManager em;
    private final EntityPath<T> path;
    protected final Querydsl querydsl;

    BaseJpaRepository(Class<T> domainClass, EntityManager em) {
        super(domainClass, em);
        this.em = em;
        this.jpaPredicateExecutor = new QuerydslJpaPredicateExecutor<>(JpaEntityInformationSupport.getEntityInformation(domainClass, em), em, SimpleEntityPathResolver.INSTANCE, getRepositoryMethodMetadata());
        this.jpaQueryFactory = new JPAQueryFactory(em);
        this.path = SimpleEntityPathResolver.INSTANCE.createPath(domainClass);
        this.querydsl = new Querydsl(em, new PathBuilder<T>(path.getType(), path.getMetadata()));
    }

    protected Page<T> findAll(Predicate predicate, Pageable pageable, OrderSpecifier<?>... orders) {
        final JPAQuery countQuery = jpaQueryFactory.selectFrom(path);
        countQuery.where(predicate);
        JPQLQuery<T> query = querydsl.applyPagination(pageable, countQuery);
        query.orderBy(orders);
        return PageableExecutionUtils.getPage(query.fetch(), pageable, countQuery::fetchCount);
    }
}
```

新增了findAll(Predicate predicate, Pageable pageable, OrderSpecifier… orders)方法，用于支持复杂分页查询的同时又有字段排序的查询场景。
其次的改动是引入了JPAQueryFactory实例，用于多表关联的复杂查询。使用方式如下：

```java
/**
 * QSendLog实体是QueryDsl插件自动生成的，插件会自动扫描加了@Entity的实体，生成一个用于查询的EntityPath类
 */
private  final  static QSendLog qSendLog = QSendLog.sendLog;
private  final static QTemplate qTemplate = QTemplate.template;

public Page<SendLog> findAll(SendLogDto logDto, Template template, Pageable pageable) {
    JPAQuery  countQuery = jpaQueryFactory.selectFrom(qSendLog).leftJoin(qTemplate);
    countQuery.where(qSendLog.templateCode.eq(qTemplate.code));
    if(!StringUtils.isEmpty(template.getName())){
        countQuery.where(qTemplate.name.eq(template.getName()));
    }
    JPQLQuery query = querydsl.applyPagination(pageable, countQuery);
    return PageableExecutionUtils.getPage(query.fetch(), pageable, countQuery::fetchCount);
}
```

#### 打印执行的sql

在使用Jpa的结构化语义构建复杂查询时，经常会因为各种原因导致查询的结果集不是自己想要的，但是又没法排查，
因为不知道最终执行的sql是怎么样的。Spring Data Jpa也有打印sql的功能，但是比较鸡肋，它打印的是没有替换查询参数的sql，
没法直接复制执行。所以这里推荐一个工具p6spy，p6spy是一个打印最终执行sql的工具，而且可以记录sql的执行耗时。使用起来也比较方便，简单三步集成：

- 引入依赖

```xml
<dependency>
    <groupId>p6spy</groupId>
    <artifactId>p6spy</artifactId>
    <version>3.8.6</version>
</dependency>
```

- 修改数据源链接字符串

```
jdbc:mysql://127.0.0.1:3306 

改成 

jdbc:p6spy:mysql://127.0.0.1:3306
```

- 添加配置spy.propertis配置

```
appender=com.p6spy.engine.spy.appender.Slf4JLogger
logMessageFormat=com.p6spy.engine.spy.appender.CustomLineFormat
customLogMessageFormat = executionTime:%(executionTime)| sql:%(sqlSingleLine)
```

