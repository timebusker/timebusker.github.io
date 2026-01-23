---
layout:     post
title:      MyBatis系统总结—MyBatis常用配置
date:       2017-12-21
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MyBatis
---  

#### Properties配置
在上文中，对于数据库的信息我们将之保存在一个db.properties文件中，然后在mybatis-conf.xml文件中通过properties节点将之引入。
实际上，mybatis给我们提供的properties的配置方式不止这一种，我们也可以在properties节点中添加property，然后再引用其中的值。

```
# 引入配置文件
<properties resource="db.properties"/>

# 改为引入配置项，其他不变
<properties>
    <property name="driver" value="com.mysql.jdbc.Driver"/>
    <property name="url" value="jdbc:mysql://localhost:3306/mybatis"/>
    <property name="username" value="root"/>
    <property name="password" value="timebusker"/>
</properties>
```

#### typeAliases配置
别名配置，实际开发中可以不定义，当使用到时需要全类名。**别名不区分大小写**。


#### 映射器引入

```
# 基于XML配置文件名称引入
<mappers>
    <mapper resource="userMapper.xml"/>
</mappers>

# 基于路径匹配引入
<mappers>
    <mapper resource="classpath:*.xml"/>
</mappers>

# 基于Mapper接口引入
<mappers>
    <mapper class="org.timebusker.db.UserMapper"/>
</mappers>
```

#### sql元素
sql元素有点像变量的定义，如果一个表的字段特别多，我们可能希望将一些通用的东西提取成`变量`然后单独`引用`.

```
# 定义SQL元素
<sql id="selectAll">
    SELECT * FROM user
</sql>
	
# 引用SQL元素
<select id="getUser2" resultType="user">
    <include refid="selectAll"/>
</select>
	
# 也可以只封装一部分查询语句
# 定义SQL元素
<sql id="selectAll3">
    id,username,address,password
</sql>
# 引用SQL元素
<select id="getUser3" resultType="user">
    SELECT <include refid="selectAll3"/> FROM user
</select>

# 还可以在封装的时候使用一些变量
<sql id="selectAll4">
    // 引用方式是$符号
    ${prefix}.id,${prefix}.username,${prefix}.address
</sql>

<select id="getUser4" resultType="user" parameterType="string">
    SELECT
    <include refid="selectAll4">
	    // 在property中设置prefix的值
        <property name="prefix" value="u"/>
    </include> FROM user u
</select>
```