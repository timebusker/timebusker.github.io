---
layout:     post
title:      MyBatis系统总结—MyBatis缓存配置
date:       2017-12-25
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MyBatis
---  

#### 默认开启一级缓存

mybatis本身对缓存提供了支持，但是如果我们没有进行任何配置，那么默认情况下系统只开启了一级缓存，一级缓存就是同一个SqlSession执行的相同查询是会进行缓存的。

#### 配置二级缓存

一级缓存只能在同一个SqlSession中有效，脱离了同一个SqlSession就没法使用这个缓存了，有的时候我们可能希望能够跨SqlSession进行数据缓存。那么这个时候需要我们进行手动开启二级缓存。

二级缓存的开启方式其实很简单，只需要我们在`userMapper.xml`中配置`<cache/>`节点，以及实体类可以序列化，实现Serializable接口即可:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.sang.db.UserMapper">
    // 开启二级缓存
	// 如此使用的全是默认配置项：所有的select语句都会被缓存，所有的delete、insert和update则都会将缓存刷新，使用LRU算法进行内存回收等
    <cache/>
	
	// 自定义缓存机制
	// <cache eviction="LRU" flushInterval="20000" size="1024" readOnly="true"/>
	// eviction表示缓存策略，最近最少使用（LRU）、先进先出（FIFO）、软引用（SOFT）、弱引用（WEAK）
	// flushInterval则表示刷新时间
	// size表示缓存的对象个数
	// readOnly为true则表示缓存只可以读取不可以修改。 
    <select id="getUser" resultType="org.sang.bean.User" parameterType="Long">
        select * from user where id = #{id}
    </select>
    <insert id="insertUser" parameterType="org.sang.bean.User">
        INSERT INTO user(username,password,address) VALUES (#{username},#{password},#{address})
    </insert>
    <delete id="deleteUser" parameterType="Long">
        DELETE FROM user where id=#{id}
    </delete>
    <select id="getAll" resultType="u">
        SELECT * from user
    </select>
</mapper>
```