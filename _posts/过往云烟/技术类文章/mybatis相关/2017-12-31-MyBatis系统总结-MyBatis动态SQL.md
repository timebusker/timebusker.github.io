---
layout:     post
title:      MyBatis系统总结—MyBatis动态SQL
date:       2017-12-26
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MyBatis
---  

> mybaits 中没有else要用chose when otherwise 代替

mybatis给我们提供了动态SQL，可以让我们根据具体的业务逻辑来拼接不同的SQL语句。

#### if

`if`是mybatis动态SQL中的判断元素

```
<select id="getUser" resultMap="u" parameterType="String">
    select * from user2 
    <if test="address!=null and address !=''">
        WHERE address LIKE concat('%',#{address},'%')
    </if>
</select>
```

#### choose

`choose`类似于Java中的`switch`，常常配合`when`和`otherwise`一起来使用。

```
<select id="getUser2" resultMap="u">
    SELECT * FROM user2 WHERE 1=1 
    <choose>
        <when test="id!=null">
            AND id=#{id}
        </when>
        <when test="address!=null">
            AND address=#{address}
        </when>
        <when test="username!=null">
            AND user_name LIKE concat(#{username},'%')
        </when>
        <otherwise>
            AND 10>id
        </otherwise>
    </choose>
</select>
```

#### where

只有where元素中有条件成立，才会将where关键字组装到SQL中.

```
<select id="getUser3" resultMap="u">
    SELECT * FROM user2
    <where>
        <choose>
            <when test="id!=null">
                AND id=#{id}
            </when>
            <when test="address!=null">
                AND address=#{address}
            </when>
            <when test="username!=null">
                AND user_name LIKE concat(#{username},'%')
            </when>
            <otherwise>
                AND 10>id
            </otherwise>
        </choose>
    </where>
</select>
```

#### trim元素替换

```
<select id="getUser4" resultMap="u">
    SELECT * FROM user2
    <trim prefix="where" prefixOverrides="and">
        AND id=1
    </trim>
</select>

# 最终执行SQL:SELECT * FROM user2 where id=1
```

#### set

set是我们在更新表的时候使用的元素，通过set元素，我们可以逐字段的修改一条数据。在set元素中，如果遇到了逗号，系统会自动将之去除。

```
<update id="update">
    UPDATE user2
    <set>
        <if test="username!=null">
            user_name=#{username},
        </if>
        <if test="password!=null">
            password=#{password}
        </if>
    </set>
    WHERE id=#{id}
</update>
```

#### foreach

foreach元素用来遍历集合

```
<select id="getUserInCities" resultMap="u">
    SELECT * FROM user2
    WHERE address IN
	// collection表示传入的参数中集合的名称
	// index表示是当前元素在集合中的下标
	// open和close则表示如何将集合中的数据包装起来
	// separator表示分隔符
	// item则表示循环时的当前元素。
    <foreach collection="cities" index="city" open="(" separator="," close=")" item="city">
        #{city}
    </foreach>
</select>
```

#### bind

使用bind元素我们可以预先定义一些变量，然后在查询语句中使用

```
<select id="getUserByName" resultMap="u">
    <bind name="un" value="username+'%'"></bind>
    SELECT* FROM user2 WHERE user_name LIKE #{un}
</select>
```