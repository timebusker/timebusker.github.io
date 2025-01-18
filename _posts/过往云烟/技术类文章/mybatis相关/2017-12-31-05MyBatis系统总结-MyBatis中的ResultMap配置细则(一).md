---
layout:     post
title:      MyBatis中的ResultMap配置细则(一)
date:       2017-12-24
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MyBatis
---  

> 关于Mybatis关联查询：使用关联查询器，如本文；；另外一种在元素内配置集合。[【详见】](https://github.com/timebusker/spring-boot-vue/tree/master/spring-boot-vue-web-server)

ResultMap配置属性较多，属于MyBatis映射器中最为复杂的元素。

#### ResultMap元素属性概览

```
<resultMap>
    <constructor>
        <idArg/>
        <arg/>
    </constructor>
    <id/>
    <result/>
    <association property=""/>
    <collection property=""/>
    <discriminator javaType="">
        <case value=""></case>
    </discriminator>
</resultMap>
```

除了`id`和`result`我们在[mybatis映射器配置细则](http://www.timebusker.top/2017/12/22/MyBatis%E7%B3%BB%E7%BB%9F%E6%80%BB%E7%BB%93-MyBatis%E6%98%A0%E5%B0%84%E5%99%A8%E9%85%8D%E7%BD%AE%E7%BB%86%E5%88%99/)
这篇博客中已经介绍过了之外，还剩下四个，本文我们就来一个一个看一下。

#### constructor

`constructor`主要是用来配置构造方法，默认情况下`MyBatis`会调用实体类的无参构造方法创建一个实体类，然后再给各个属性赋值。
但当我们为实体类生成**有参的构造方法**，且类中无**无参的构造方法**，如果不配置`constructor`元素，`MyBatis`在初始化实体类映射属性时会抛异常。

```
# 实体类构造方法
public User(Long id, String username, String password, String address) {
    this.id = id;
    this.username = username;
    this.password = password;
    this.address = address;
}

# 配置构造函数
<resultMap id="userResultMap" type="org.timebusker.bean.User">
    <constructor>
        <idArg column="id" javaType="long"/>
        <arg column="username" javaType="string"/>
        <arg column="password" javaType="string"/>
        <arg column="address" javaType="string"/>
    </constructor>
</resultMap>
```

在constructor中指定相应的参数，这样resultMap在构造实体类的时候就会按照这里的指定的参数寻找相应的构造方法去完成了。

#### association

`association`是`MyBatis`支持**一对一**级联查询的重要元素。

以`省份`与`省份代号`作为例子，一个省份对应一个省份代号，如***云南省-->>--云***。

```
# 建表
create table tb_province(
    id int primary key auto_increment,
	name varchar(32),
	area int
);

create table tb_alias(
    id int primary key auto_increment,
	name varchar(32),
	pid int
); 

# 创建实体

//Alias实体类
public class Alias {
    private Long id;
    private String name;
    //省略getter/setter
}
//Province实体类
public class Province {
    private Long id;
    private String name;
    private Alias alias;
    //省略getter/setter
}

# 创建Mapper类
public interface AliasMapper {
    Alias findAliasByPid(Long id);
}
public interface ProvinceMapper {
    List<Province> getProvince();
}

#创建MapperXML
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.timebusker.db.AliasMapper">
    <select id="findAliasByPid" parameterType="long" resultType="org.timebusker.bean.Alias">
        SELECT * FROM alias WHERE pid=#{id}
    </select>
</mapper>

<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.timebusker.db.ProvinceMapper">
    <resultMap id="provinceResultMapper" type="org.timebusker.bean.Province">
        <id column="id" property="id"/>
		// select:属性表示要执行的方法,实际上指向了一条SQL语句
		// column:表示给方法传入的参数的字段
		// property:表示select查询的结果要赋值给JavaBean的那个属性
        <association property="alias" column="id" select="org.timebusker.db.AliasMapper.findAliasByPid"/>
    </resultMap>
	
    <select id="getProvince" resultMap="provinceResultMapper">
      SELECT * FROM province
    </select>
</mapper>

# 在mybatis-conf.xml中配置mapper
<mappers>
    <mapper resource="provinceMapper.xml"/>
    <mapper resource="aliasMapper.xml"/>
</mappers>
```

#### collection

collection是用来解决一对多级联的，还是上面那个例子，每个省份下面都会有很多城市，于是，我来创建一张城市表，如下： 

```
create table tb_city(
id int primary key auto_increment,
name varchar(32),
pid int
)
```

市表中有一个`pid`字段，该字段表示这个城市是属于哪个省份的。假设我现在`Province`实体类中多了一个属性叫做`cities`，数据类型是一个`Set`集合，
这个集合中放的所有的数据就是这个省份的，我希望查询结束之后这个属性的值就会被自动填充。

```
# 创建City实体类
public class City {
    private Long id;
    private Long pid;
    private String name;
    //省略getter/setter
}

# 为Province类添加属性
public class Province {
    private Long id;
    private String name;
    private Alias alias;
    private Set<City> cities;
    //省略getter/setter
}

# 创建CityMapper
public interface CityMapper {
    List<City> findCityByPid(Long id);
}

# 创建cityMapper.xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.timebusker.db.CityMapper">
    <select id="findCityByPid" parameterType="long" resultType="org.timebusker.bean.City">
        SELECT * FROM city WHERE pid=#{id}
    </select>
</mapper>

# 在mybatis-conf.xml中配置mapper
<mappers>
    <mapper resource="provinceMapper.xml"/>
    <mapper resource="aliasMapper.xml"/>
    <mapper resource="cityMapper.xml"/>
</mappers>

# 修改provinceMapper.xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.timebusker.db.ProvinceMapper">
    <resultMap id="provinceResultMapper" type="org.timebusker.bean.Province">
        <id column="id" property="id"/>
        <association property="alias" column="id" select="org.timebusker.db.AliasMapper.findAliasByPid"/>
        // select:属性表示要执行的方法,实际上指向了一条SQL语句
		// column:表示给方法传入的参数的字段
		// property:表示select查询的结果要赋值给JavaBean的那个属性
        <collection property="cities" column="id" select="org.timebusker.db.CityMapper.findCityByPid"/>
    </resultMap>
    <select id="getProvince" resultMap="provinceResultMapper">
      SELECT * FROM province
    </select>
</mapper>
```

