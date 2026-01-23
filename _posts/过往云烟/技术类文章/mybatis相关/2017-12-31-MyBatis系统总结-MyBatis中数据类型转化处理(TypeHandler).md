---
layout:     post
title:      MyBatis中数据类型转化处理(TypeHandler)
date:       2017-12-23
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MyBatis
---  

实际开发中我们可能会遇到一类问题，如`JavaBean`中需要使用***格式化的时间格式***，但是存储在数据库的是***时间戳***；
再如JavaBean中使用的`List<String>`列表对象，但数据库中是`{A,B,C,D}`。

事实上，`MyBatis`本身已经为我们提供了许多`TypeHandler`，特殊需求我们可以自定义`TypeHandler`。

自定义`TypeHandler`：   

- 实现TypeHandler接口

- 继承自BaseTypeHandler类（更简单）

### 日期的转换（示例）

```
# 建表语句
create table tb_date_time(
id integer primary key auto_increment,
add_time varchar(32)
) default character set=utf8;

# JavaBean对象
public class DateTime {
    private Long id;
    private String addTime;
    //省略getter/setter
}

# 自定义TypeHandler
# 使用@MappedJdbcTypes与@MappedTypes指定拦截转化，使用中可以只指定类型或TypeHandler或两者同时指定，完成数据转化
# @MappedJdbcTypes定义的是JdbcType类型，这里的类型不可自己随意定义，必须要是枚举类org.apache.ibatis.type.JdbcType所枚举的数据类型。 
# @MappedTypes定义的是JavaType的数据类型，描述了哪些Java类型可被拦截。 
@MappedJdbcTypes({JdbcType.VARCHAR})
@MappedTypes({Date.class})
public class DateTypeHandler extends BaseTypeHandler<Date> {

    // 写库时数据转化
    public void setNonNullParameter(PreparedStatement preparedStatement, int i, Date date, JdbcType jdbcType) throws SQLException {
        preparedStatement.setString(i, String.valueOf(date.getTime()));
    }
    // 读库时数据转化
    public Date getNullableResult(ResultSet resultSet, String s) throws SQLException {
        return new Date(resultSet.getLong(s));
    }
    // 读库时数据转化
    public Date getNullableResult(ResultSet resultSet, int i) throws SQLException {
        return new Date(resultSet.getLong(i));
    }
    // 读库时数据转化
    public Date getNullableResult(CallableStatement callableStatement, int i) throws SQLException {
        return callableStatement.getDate(i);
    }
}

# 使用TypeHandler

# Mapper中使用
# 查询语句
# 配置resultMap时指定处理的TypeHandler，在select中直接正常使用
<resultMap id="resultMap" type="org.timebusker.bean.DateTime">
    ......
    <result typeHandler="org.timebusker.db.DateTypeHandler" column="add_time" javaType="java.util.Date" jdbcType="VARCHAR" property="addTime"/>
</resultMap>

# 插入语句(三种方式都可以)
<insert id="insert">
    INSERT INTO tb_date_time(addTime) VALUES (#{addTime,javaType=Date,jdbcType=VARCHAR})
</insert>

<insert id="insert">
    INSERT INTO tb_date_time(addTime) VALUES (#{addTime,typeHandler=org.timebusker.db.DateTypeHandler})
</insert>

<insert id="insert">
    INSERT INTO tb_date_time(addTime) VALUES (#{addTime,javaType=Date,jdbcType=VARCHAR,typeHandler=org.timebusker.db.DateTypeHandler})
</insert>

# 上述方法具有局限性,需要在使用的每一地方指定
# 在MyBatis配置文件中注册TypeHandler
<typeHandlers>
    <typeHandler handler="org.timebusker.db.DateTypeHandler"/>
</typeHandlers>

# 但上述方式也只局限于读取数据时，写数据时仍需要指定TypeHandler
```