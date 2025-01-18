---
layout:     post
title:      MyBatis系统总结—MyBatis映射器配置细则
date:       2017-12-22
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MyBatis
---  

前面两篇博客多次提到**Mapper映射器**，也做了一些简单讲解，实际中，映射器的元素还是非常多，
有`select、insert、update、delete、parameterMap、sql、resultMap、cache、cache-ref`等。

### select
select元素用来执行一条查询语句，Select可以算作是最常用，最复杂的元素之一，我们在使用Select的时候可以自定义元素自定义结果集等，非常灵活。

```
<select id="getUser" resultType="user" parameterType="Long">
    select * from user where id = #{id}
</select>
```

我们直接从user表中查询一条数据出来，查询的结果是一个user对象，即mybatis会自动帮我们把查询的结果转为一个user对象，
那么mybatis在转化的过程中怎么知道数据库的哪个字段对应JavaBean中的哪个属性呢？很简单，
**只要两者的名称一样，系统就能就能自动识别出来**，我们在前面博客中在数据库中创建的user表的字段分别为`id,username,password,address`这四个，
实体类的属性也是这四个一模一样，所以系统会自动将查询结果给我们转为User对象，那么在实际开发中，
JavaBean中的属性命名我们习惯于驼峰命名法，在数据库中我们更常用下划线命名法，比如我现在创建一个新的实体类User：

```
public class User {
    private Long id;
    private String userName;
    private String password;
    private String address;
    //省略getter/setter
}

# user表
# 注表中user_name字段信息与Javabean中的userName不一致
create table user(
id integer primary key auto_increment,
user_name varchar(32),
password varchar(64),
address varchar(512)
) default character set=utf8;
```
#### 对象映射
在实际开发中，数据库表中的字段信息与`Javabean`中的属性对应起来是常有的事情，
`mybatis`提供三种解决方案。

- 在`SQL`语句使用别名，将查询的字段信息转到与`Javabean`属性一致。

```
# 使用as关键字进行别名转化
<select id="getUser" resultType="u" parameterType="Long">
    select id,user_name as userName,password,address from user2 where id = #{id}
</select>
```

#### 使用mapUnderscoreToCamelCase属性，启用自动驼峰命名规则映射。

```
# 在mybatis-conf.xml配置文件中新增一下配置信息
# 开启之后，实现user_name与userName的映射关系转化
<settings>
    <setting name="mapUnderscoreToCamelCase" value="true"/>
</settings>
```

#### 使用resultMap来解决
`resultMap`是数据库表字段与Javabean属性映射问题的终极解决方案，但resultMap的意义不局限于此。
`resultMap`可以用来描述从数据库结果集中来加载对象，有的时候映射过于复杂，我们可以在`Mapper`中定义`resultMap`来解决映射问题。

```
# 设置resultMap的唯一ID，并通过ID引用该映射集合，type属性指明resultMap对应的JavaBean

# 设置Javabean属性与数据库字段的映射关系
##### id元素用于设置主键，result设置普通的映射关系
##### property设置JavaBean中的属性名称，column设置数据库中的字段名称，javaType设置JavaBean中该属性的类型，jdbcType设置数据库中字段数据类型
<resultMap id="userMap" type="org.timebusker.bean.User">
    <id property="id" column="id" javaType="long" jdbcType="NUMERIC"/>
    <result property="userName" column="user_name" javaType="string" jdbcType="VARCHAR"/>
    <result property="password" column="password" javaType="string" jdbcType="VARCHAR"/>
    <result property="address" column="address" javaType="string" jdbcType="VARCHAR"/>
</resultMap>

# SQL指定resultMap的ID完成映射
<select id="getUser" resultMap="userMap" parameterType="Long">
    select * from user2 where id = #{id}
</select>
```

### 多条件（参数）SQL封装

#### 使用Map集合传递参数
将参数装入`Map`集合中传入，并把`UserMapper`接口定义方法的参数设置为`Map`。
在开发中一般不推荐这种方式，因为key容易写错，且不直观。

```
# 定义接口
public List<User> queryUser(Map<String,Object> map);

# 编辑XML中的SQL语句
# #{address} 相当于使用Map中的Key获取Value
<select id="queryUser" resultMap="userMap">
    SELECT * FROM USER WHERE ADDRESS=#{address} AND USER_NAME LIKE concat(#{username},'%')
</select>
```

#### 使用@Param注解
在数据提交的过程中，`mybatis`会以`@Param`提供的名称为准，参数传递很直观。

```
# 使用@Param定义接口
public List<User> queryUser(@Param("address") String address,@Param("usernume") String username);

# 编辑XML中的SQL语句
# #{address}直接匹配名称获取
<select id="queryUser" resultMap="userMap">
    SELECT * FROM USER WHERE ADDRESS=#{address} AND USER_NAME LIKE concat(#{username},'%')
</select>
```

#### 使用JavaBean
使用@Param注解已经很完美的解决了参数直观的问题，但是对于参数特别多的时候，可以考虑使用JavaBean的方式。

```
# 使用JavaBean定义接口
public List<User> queryUser(User user);

# 编辑XML中的SQL语句
# 使用parameterType指定参数类型
<select id="queryUser" resultMap="userMap" parameterType="org.timebusker.bean.User">
    SELECT * FROM USER WHERE ADDRESS=#{address} AND USER_NAME LIKE concat(#{username},'%')
</select>
```

### insert中的主键回填
- 主键回填
在创建表的时候设置了表的`id`为自增长字段，在`Java`代码中先构建了一个`JavaBean`，其`id`属性是为`null`，
因为`id`不需要插入到数据库中去 ，那么当我将数据插入成功之后系统会自动给该对象的id属性赋值，值为刚刚插入那条数据的id，这就称作主键回填。

开发中也是非常常见的需求，我希望知道刚刚插入成功的数据的`id`是多少，而很多时候`id`可能都是**按照某种既定规则去生成**，
我们在插入之前并不知晓，插入之后又需要使用，这种时候就可以使用主键回填。

```
# Mapper接口定义
public int save(User user);

# SQL
<insert id="save" parameterType="org.timebusker.bean.User" useGeneratedKeys="true" keyProperty="id">
    INSERT INTO user(user_name,password,address) VALUES (#{userName},#{password},#{address})
</insert>

# 插入成功之后mybatis已经给id属性赋值了，值即为刚刚插入数据
```  

### insert中主键自定义
假设当我往数据库中插入一条数据的时候，如果此时表为空，则这条数据的id我设置为1，如果表不为空，
那我找到表中最大的id，然后给其加2作为即将添加数据的id，这种也算是较常见的需求，我们来看看怎么实现吧。 

SelectKey在Mybatis中是为了解决Insert数据时不支持主键自动生成的问题，他可以很随意的设置生成主键的方式。
不管SelectKey有多好，尽量不要遇到这种情况吧，毕竟很麻烦。   

```
# Mapper接口定义
public int save(User user);

# SQL 
# selectKey中的keyProperty属性表示selectKey中的sql语句的查询结果应该被设置的目标属性
# order=”BEFORE” 表示在执行 INSERT 语句之前进行选择主键
<insert id="insertUser2" parameterType="org.timebusker.bean.User" useGeneratedKeys="true" keyProperty="id">
    <selectKey keyProperty="id" resultType="long" order="BEFORE">
        SELECT if(max(id) is null,1,max(id)+2) as newId FROM user
    </selectKey>
    INSERT INTO user3(id,user_name,password,address) VALUES (#{id},#{userName},#{password},#{address})
</insert>
```

### 关于MyBatis映射取值的符号#/%
- **#{}:** 解析为一个JDBC预编译语句（prepared statement）的参数标记符，一个#{}被解析为一个参数占位符 。
- **${}:** 仅仅为一个纯碎的string替换，在动态 SQL 解析阶段将会进行变量替换。
- **最大在于：`#{}`传值解析时，参数是带引号，而`${}`传值解析时，参数是不带引号。**

> SQL语句预编译：对SQL语句进行预编译就是先使用`?(问号)`代替参数的位置，然后再通过`set方法`将参数值注入，最后再执行SQL。——可以有效防范SQL注入

```
# XML中的SQL
select id,name,age from student where id =#{id}
select id,name,age from student where id =${id}

# 解析后
select id,name,age from student where id ='1'
select id,name,age from student where id =1
```
