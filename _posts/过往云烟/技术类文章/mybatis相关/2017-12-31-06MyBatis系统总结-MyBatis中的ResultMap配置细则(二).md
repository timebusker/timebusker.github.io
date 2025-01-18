---
layout:     post
title:      MyBatis中的ResultMap配置细则(二)
date:       2017-12-24
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MyBatis
---  

> 关于Mybatis关联查询：使用关联查询器，如本文；；另外一种在元素内配置集合。[【详见】](https://github.com/timebusker/spring-boot-vue/tree/master/spring-boot-vue-web-server)

ResultMap配置属性较多，属于MyBatis映射器中最为复杂的元素。

#### discriminator

discriminator既不是一对多也不是一对一，这个我们称之为`鉴别器级联`，使用它我们可以在不同的条件下执行不同的查询匹配不同的实体类。

要根据查询结果动态匹配查询语句的需求，我们就可以通过discriminator来实现。

以上文的例子为例，不同的省份分别属于南北方，南北方的人有不同的饮食习惯，北方人吃面、南方人吃米饭，据此，
我来新创建三个类，分别是`Food、Rice、Noodle`三个类，其中Food是Rice和Noodle的父类，将两者之间的一些共性抽取出来，这三个类如下：

```java
public class Food {
    // ID
    protected Long id;
	// 食物名称
    protected String name;
    //省略getter/setter
}
public class Noodle extends Food{
    //每天吃几次
    private int times;

    //省略getter/setter
}
public class Rice extends Food {
    //烹饪方法
    private String way;
    //省略getter/setter

}

# 对应建表
create table tb_rice(
id int primary key auto_increment,
name varchar(32),
way varchar(32)
)

create table tb_noodel(
id int primary key auto_increment,
name varchar(32),
times int
)

# 修改我的Province实体类
public class Province {
    private Long id;
    private String name;
    private Alias alias;
    private List<City> cities;
	// 多了一个foods属性,如果查到这个省份是北方省份，那么就自动去查询noodle表，将查到的结果赋值给foods属性，
	// 如果这个省份是南方省份，那么就自动去查询rice表，将查到的结果赋值给foods属性
    private List<Food> foods;
   //省略getter/setter
}

# 创建Mapper
public interface RiceMapper {
    List<Rice> findRiceByArea();
}
public interface NoodleMapper {
    List<Noodle> findNoodleByArea();
}
```

```xml
# noodleMapper.xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.timebusker.db.NoodleMapper">
    <select id="findNoodleByArea" resultType="org.timebusker.bean.Noodle">
        SELECT * FROM noodle
    </select>
</mapper>

# riceMapper.xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.timebusker.db.RiceMapper">
    <select id="findRiceByArea" resultType="org.timebusker.bean.Rice">
        SELECT * FROM rice
    </select>
</mapper>

# mybaits-conf.xml
<mappers>
    <mapper resource="provinceMapper.xml"/>
    <mapper resource="aliasMapper.xml"/>
    <mapper resource="cityMapper.xml"/>
    <mapper resource="riceMapper.xml"/>
    <mapper resource="noodleMapper.xml"/>
</mappers>

# 修改provinceMapper.xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.timebusker.db.ProvinceMapper">
    <resultMap id="provinceResultMapper" type="org.timebusker.bean.Province">
        <id column="id" property="id"/>
        <association property="alias" column="id" select="org.timebusker.db.AliasMapper.findAliasByPid"/>
        <collection property="cities" column="id" select="org.timebusker.db.CityMapper.findCityByPid"/>
		# 类似于switch语句
		# column表示用哪个字段值参与比较
        <discriminator javaType="int" column="area">
		    // 1代表北方
            <case value="1" resultMap="noodleResultMap"></case>
			// 2代表南方
            <case value="2" resultMap="riceResultMap"></case>
        </discriminator>
    </resultMap>
	
	// 返回值类型是Province，且继承自provinceResultMapper
    <resultMap id="noodleResultMap" type="org.timebusker.bean.Province" extends="provinceResultMapper">
        <collection property="foods" column="area" select="org.timebusker.db.NoodleMapper.findNoodleByArea"/>
    </resultMap>
	// 返回值类型是Province，且继承自provinceResultMapper
    <resultMap id="riceResultMap" type="org.timebusker.bean.Province" extends="provinceResultMapper">
        <collection property="foods" column="area" select="org.timebusker.db.RiceMapper.findRiceByArea"/>
    </resultMap>
	
    <select id="getProvince" resultMap="provinceResultMapper">
      SELECT * FROM province
    </select>

</mapper>
```

#### 延迟加载问题

上文我们介绍的方式，每次查询省份的时候都会去查询别名食物等表，有的时候我们可能并不需要这些数据但是却无可避免的要调用这个方法，
那么在mybatis中，针对这个问题也提出了相应的解决方案，那就是延迟加载，延迟加载就是当我需要调用这条数据的时候mybatis再去数据库中查询这条数据，
比如Province的foods属性，当我调用Province的getFoods()方法来获取这条数据的时候系统再去执行相应的查询操作

##### 在mybatis的配置文件中进行配置

类似于全局配置，配置成功之后，所有的查询操作都开启了延迟加载。

```xml
<settings>
    // lazyLoadingEnabled表示是否开启延迟加载，默认为false表示没有开启，true表示开启延迟加载。 
    <setting name="lazyLoadingEnabled" value="true"/>
	// aggressiveLazyLoading表示延迟加载的时候内容是按照层级来延迟加载还是按照需求来延迟加载
	// 默认为true表示按照层级来延迟加载
	// false表示按照需求来延迟加载
	// 以我们上文查询食物的需求为例，去查询rice表或者noodle表是属于同一级的，但是在我查询到陕西省的时候，这个时候只需要去查询noodle表就可以了，当我查询到广东省的时候再去查询rice表，
	// 但是如果aggressiveLazyLoading为true的话，即使我只查询到陕西省，系统也会去把rice和noodle都查一遍，因为它俩属于同一级
    <setting name="aggressiveLazyLoading" value="false"/>
</settings>
```

##### 在针对不同的查询进行配置

`在association和collection中配置fetchType属性即可`。fetchType有两个属性值，`eager`表示即时加载，`lazy`表示延迟加载。

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.timebusker.db.ProvinceMapper">
    <resultMap id="provinceResultMapper" type="org.timebusker.bean.Province">
        <id column="id" property="id"/>
        <association property="alias" column="id" select="org.timebusker.db.AliasMapper.findAliasByPid" fetchType="eager"/>
        <collection property="cities" column="id" select="org.timebusker.db.CityMapper.findCityByPid" fetchType="lazy"/>
        <discriminator javaType="int" column="area">
            <case value="1" resultMap="noodleResultMap"></case>
            <case value="2" resultMap="riceResultMap"></case>
        </discriminator>
    </resultMap>
    <resultMap id="noodleResultMap" type="org.timebusker.bean.Province" extends="provinceResultMapper">
        <collection property="foods" column="area" select="org.timebusker.db.NoodleMapper.findNoodleByArea"/>
    </resultMap>
    <resultMap id="riceResultMap" type="org.timebusker.bean.Province" extends="provinceResultMapper">
        <collection property="foods" column="area" select="org.timebusker.db.RiceMapper.findRiceByArea"/>
    </resultMap>
    <select id="getProvince" resultMap="provinceResultMapper">
      SELECT * FROM province
    </select>
</mapper>
```