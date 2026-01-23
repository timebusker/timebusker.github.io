---
layout:     post
title:      MyBatis系统总结—初识MyBatis
date:       2017-12-20
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MyBatis
---  

说道`JavaWeb`，很多人都知道`SSH`，这里的`H`代表了`hibernate`，这是一个数据库访问框架，`hibernate`在Java开发中的地位也是相当高，
众所周知的`JPA`标准就是由`hibernate`主导完成的。然而，数据库访问框架除了`hibernate`之外，还有另外一个大名鼎鼎的数据库框架，那就是`mybatis`，
`mybatis`的前身`ibatis`早在2001年就发布了，那么这里我不想过多的去比较这两个东西孰优孰劣，因为当你真正了解了这两个框架之后自然就知道在什么情况下该用什么框架。
OK，废话不多说，那么今天我们就来看看mybatis的基本使用吧。 

`mybatis`在使用的过程中，我们可以通过`XML`的方式来构建，也可以通过`Java`代码来构建，本文我先用`Java`代码来创建，下一篇博客我们再来介绍如何用XML来构建。 

#### MyBatis基本的组件
- **SqlSessionFactoryBuilder：**这是一个`SqlSessionFactory`的构造器，它根据我们的xml配置文件或者Java代码来生成`SqlSessionFactory`。 
- **SqlSessionFactory：**这个有点类似于我们在JDBC中使用的`Connection`，我们到时候要根据`SqlSessionFactory`来生成是一个会话，也就是`SqlSession`。 
- **SqlSession：**它可以发送一条`SQL`语句去执行，并返回结果，从这个角度来说，它有点类似于`PrepareStatement`，当然，我们也可以利用`SqlSession`获取Mapper的接口，这个算是`SqlSession`的一个核心用法了。 
- **Mapper：**`Mapper`也可以发送一条SQL语句并返回执行结果，Mapper由两部分组成，一部分是Java接口，另一部分是XML配置文件或者注解。

#### 开始使用MyBatis
##### 创建配置类并获取SqlSessionFactory
一般情况下一个数据库只需要有一个`SqlSessionFactory`实例，过多的`SqlSessionFactory`会导致数据库有过多的连接，
从而消耗过多的数据库资源，因此`SqlSessionFactory`需要我们将之做成一个单例模式。

```
public class DBUtils {

    private static SqlSessionFactory sqlSessionFactory = null;
    private static final Class CLASS_LOCK = DBUtils.class;

	//初始化SessionFactory
    public static SqlSessionFactory initSqlSessionFactory() {
        synchronized (CLASS_LOCK) {
            if (sqlSessionFactory == null) {
			    // PooledDataSource实例设置数据库配置项，此处使用池化数据源配置链接，对应的还有一个UnpooledDataSource
				// UnpooledDataSource 意味每次访问数据都会进行链接创建与释放
                PooledDataSource dataSource = new PooledDataSource();
                dataSource.setDriver("com.mysql.jdbc.Driver");
                dataSource.setUrl("jdbc:mysql://localhost:3306/mybatis");
                dataSource.setUsername("root");
                dataSource.setPassword("timebusker");
				// MyBatis事务工厂的创建，此处使用其中一种事务机制：JDBC事务管理机制
                TransactionFactory transactionFactory = new JdbcTransactionFactory();
				// 创建了数据库的运行环境，并将这个环境命名为dev
                Environment environment = new Environment("dev", transactionFactory, dataSource);
                Configuration configuration = new Configuration(environment);
				// 添加映射器Mapper
                configuration.addMapper(UserMapper.class);
				// 基于数据配置环境和映射器创建SessionFactory
                sqlSessionFactory = new SqlSessionFactoryBuilder().build(configuration);
            }
        }
        return sqlSessionFactory;
    }

	// 通过SessionFactory获取session
    public static SqlSession openSqlSession() {
        if(sqlSessionFactory==null)
            initSqlSessionFactory();
        return sqlSessionFactory.openSession();
    }
}
```

##### 构建Mapper
Mapper可以通过Java接口+xml文件来构成，也可以通过Java接口+注解来构成。

```
public interface UserMapper {
    @Select(value = "select * from user where id=#{id}")
    public User getUser(Long id);
}

# 当我调用getUser方法时实际上就执行了@Select注解中的SQL语句，
# 在执行SQL语句的时候会将getUser方法的参数id传入SQL 语句中

public class User {
    private Long id;
    private String username;
    private String password;
    private String address;

    //省略getter/setter
}
```

##### 测试

```
public void test() {
    # 先获取一个SqlSession，然后通过SqlSession获取我们刚刚创建的Mapper对象，调用Mapper中的方法就可以执行查询操作
    SqlSession sqlSession = null;
    try {
        sqlSession = DBUtils.openSqlSession();
        UserMapper userMapper = sqlSession.getMapper(UserMapper.class);
        User user = userMapper.getUser(3l);
        System.out.println(user.toString());
        sqlSession.commit();
    } catch (Exception e) {
        e.printStackTrace();
        sqlSession.rollback();
    } finally {
        if (sqlSession != null) {
            sqlSession.close();
        }
    }
}

public void test2() {
    # 不用获取Mapper对象，直接去调用方法
    SqlSession sqlSession = null;
    try {
        sqlSession = DBUtils.openSqlSession();
        User user = (User) sqlSession.selectOne("getUser", 1l);
        System.out.println(user.toString());
        sqlSession.commit();
    } catch (Exception e) {
        e.printStackTrace();
        sqlSession.rollback();
    } finally {
        if (sqlSession != null) {
            sqlSession.close();
        }
    }
}
```

#### 基于XML文件配置开发
上面介绍通过Java代码来创建mybatis的环境，但这种方式看起来有意思实际在开发中用的并不多。

```
#配置db.properties文件
driver=com.mysql.jdbc.Driver
url=jdbc:mysql://localhost:3306/mybatis
username=root
password=timebusker


# 配置mybatis-conf.xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration PUBLIC "-//mybatis.org//DTD Config 3.0//EN" "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>
    <!-- 加载配置配置 -->
    <properties resource="db.properties"/>
    <typeAliases>
	    <!-- 实体类取一个别名，可以在Mapper映射文件中直接使用别名，不需要使用类全名 （根据开发配置）-->
        <typeAlias type="org.timebusker.bean.User" alias="user"/>
    </typeAliases>
	<!-- 配置数据源环境，可以区分开发、生产、测试，并通过default属性设置默认 -->
    <environments default="development">
        <environment id="development">
		    <!-- 指定事务事务管理机制 -->
            <transactionManager type="JDBC"/>
			<!-- 指定使用池化数据源 -->
            <dataSource type="POOLED">
                <property name="driver" value="${driver}"/>
                <property name="url" value="${url}"/>
                <property name="username" value="${username}"/>
                <property name="password" value="${password}"/>
            </dataSource>
        </environment>
    </environments>
	<!-- 配置映射器 -->
    <mappers>
        <mapper resource="userMapper.xml"/>
    </mappers>
</configuration>

# 加载配置文件创建SessionFactory
public class DBUtils {
    private static SqlSessionFactory sqlSessionFactory = null;
    private static final Class CLASS_LOCK = DBUtils.class;

    public static SqlSessionFactory initSqlSessionFactory() {
        InputStream is = null;
        try {
            is = Resources.getResourceAsStream("mybatis-conf.xml");
        } catch (IOException e) {
            e.printStackTrace();
        }
        synchronized (CLASS_LOCK) {
            if (sqlSessionFactory == null) {
                sqlSessionFactory = new SqlSessionFactoryBuilder().build(is);
            }
        }
        return sqlSessionFactory;
    }

    public static SqlSession openSqlSession() {
        if(sqlSessionFactory==null)
            initSqlSessionFactory();
        return sqlSessionFactory.openSession();
    }
}

# java接口
public interface UserMapper {
    public User getUser(Long id);

    public int insertUser(User user);

    public int deleteUser(Long id);
}

# XML 映射文件
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.timebusker.db.UserMapper">
    <select id="getUser" resultType="user" parameterType="Long">
        select * from user where id = #{id}
    </select>
    <insert id="insertUser" parameterType="user">
        INSERT INTO user(username,password,address) VALUES (#{username},#{password},#{address})
    </insert>
    <delete id="deleteUser" parameterType="Long">
        DELETE FROM user where id=#{id}
    </delete>
</mapper>

# 其他测试、bean与注解一样
```
