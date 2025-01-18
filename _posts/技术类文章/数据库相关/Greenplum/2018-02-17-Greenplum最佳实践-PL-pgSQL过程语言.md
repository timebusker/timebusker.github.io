---
layout:     post
title:      Greenplum最佳实践-PL-pgSQL过程语言(存储过程)
date:       2019-02-17
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Greenplum
---

> [中文地址](https://gp-docs-cn.github.io/docs/)

#### 关于Greenplum数据库的PL/pgSQL
Greenplum数据库`PL/pgSQL`是一种可加载的过程语言，默认情况下安装并注册到Greenplum数据库。 用户可以使用SQL语句，函数和操作符创建用户定义的函数。

使用PL/pgSQL，用户可以在数据库服务器中对一组计算和一系列SQL查询进行分组，从而具有过程语言的强大功能和易于使用的SQL。 
此外，使用PL/pgSQL，用户可以使用Greenplum数据库SQL的所有数据类型，操作符和函数。

`PL/pgSQL`的语言是`Oracle的PL/SQL的一个子集`。Greenplum的数据库PL/pgSQL的基于Postgres的PL/pgSQL开发扩展得来。[【PL/pgSQL的 文档】](https://www.postgresql.org/docs/8.3/plpgsql.html)

当使用PL/pgSQL函数时，函数属性会影响Greenplum Database如何创建查询计划。
用户可以将属性`IMMUTABLE`,`STABLE`,或`VOLATILE`指定为`LANGUAGE`子句的一部分，以对功能属性进行分类。
 
#### Greenplum数据库的SQL限制
当使用Greenplum数据库的PL/pgSQL时，限制包括：

- 不支持触发器
- 光标仅向前移动（不可滚动）
- 不支持可更新游标( (UPDATE...WHERE CURRENT OF and DELETE...WHERE CURRENT OF)。

#### PL/pgSQL语言
PL/pgSQL是块结构语言。函数定义的完整文本必须是块。块被定义为:

```
[ label ]
[ DECLARE
   declarations ]
BEGIN
   statements
END [ label ];
```

块中的每个声明和每个语句都以分号（;）终止。出现在另一个块中的块必须在END后具有分号，`结束函数体的END 不需要分号`。

`不要将PL/pgSQL中的分组语句与用于事务控制的数据库命令的BEGIN 和 END 关键字混淆。 PL/pgSQL的BEGIN和 END 关键字仅用于分组; 它们不开始或结束一个事务。
函数总是在由外部查询建立的事务中执行 - 它们无法启动或提交该事务，因为它们不会执行上下文。 但是，包含 EXCEPTION 子句的PL/pgSQL块有效地形成可以回滚而不影响外部事务的子事务。`

所有关键词和标识符可以写成大小写混合，标识符隐式转换为小写。除非用双引号（“）括起来。

用户可以通过以下方式在PL/pgSQL中添加注释：  
- 双击 `(--)`对行尾的注释进行延伸   
- `/*`标志着块注开始，直到`*/`出现结束   
> 块注释不能被嵌套，但是双击注释可以被封装成块注释并且双击可以隐藏块注释分隔符`/*`和`*/`。      

块的语句部分中的任何语句都可以是子块。 子块可用于逻辑分组或将变量本地化为一小组语句。

```
CREATE FUNCTION testfunc() RETURNS integer AS $$
DECLARE
   quantity integer := 30;
BEGIN
   RAISE NOTICE 'Quantity here is %', quantity;  
   -- Quantity here is 30
   quantity := 50;
   --
   -- Create a subblock
   --
   DECLARE
      quantity integer := 80;
   BEGIN
      RAISE NOTICE 'Quantity here is %', quantity;  
      -- Quantity here is 80
   END;
   RAISE NOTICE 'Quantity here is %', quantity; 
   -- Quantity here is 50
   RETURN quantity;
END;
$$ LANGUAGE plpgsql;
```

#### PL/pgSQL计划缓存
当PL/pgSQL函数在数据库会话中首次执行时，`PL/pgSQL解释器`解析函数的SQL表达式和命令。解释器会为首次执行的函数中的每个表达式和SQL命令创建一个事先准备的执行计划。   

PL/pgSQL解释器在数据库连接的使用期间重新使用特定表达式和SQL命令的执行计划。虽然此重用显著减少了解析和生成计划所需的总时间，但是在函数此部分运行之前，
不能检测到特定表达式或命令中的错误。

如果对查询中使用的任何关系有任何模式更改，或者在查询中使用的任何用户自定义的函数被重新定义，Greenplum数据库将自动重新计划保存的查询计划。
这使得在大多数情况下，重新使用准备好的计划变成了透明的。

用户在PL/pgSQL函数中使用的SQL命令必须在每次执行时引用相同的表和列。用户不能将参数用作SQL命令中的表或列的名称。

PL/pgSQL为用户调用多态函数的实际参数类型的每个组合缓存单独的查询计划，以确保数据类型差异不会导致意外故障。

#### PL/pgSQL 示例

- 函数参数别名
传递给函数的参数以`$1, $2`等标识符命名。相应的，可以为`$n`参数名称声明别名以提高可读性，然后可以使用别名或数字标识符来引用参数值。

```
# 在 CREATE FUNCTION命令中为参数命名：
CREATE FUNCTION sales_tax(subtotal real) RETURNS real AS $$
BEGIN
   RETURN subtotal * 0.06;
END;
$$ LANGUAGE plpgsql;

# 示例使用DECLARE语法创建相同的函数。
CREATE FUNCTION sales_tax(real) RETURNS real AS $$
DECLARE
    subtotal ALIAS FOR $1;
BEGIN
    RETURN subtotal * 0.06;
END;
$$ LANGUAGE plpgsql;
```

- 使用表列的数据类型
当声明变量时，可以使用`%TYPE`来指定变量或表列的数据类型。 这是声明具有表列数据类型的变量的语法：

```
name table.column_name%TYPE;
```

用户可以使用它来声明将保存数据库值的变量。 例如，如果用户有一个名为 user_id 的列在用户的 users 表中。 要声明与users.user_id列具有相同数据类型 变量my_userid :

```
my_userid users.user_id%TYPE;
```

`%TYPE`在多态函数中特别有价值，因为内部变量所需的数据类型可能会从一个调用变为下一个调用。可以通过将%TYPE 应用于函数的参数或结果占位符来创建适当的变量。

- 基于表行的复合类型
根据表行声明一个复合变量:

```
name table_name%ROWTYPE;
```

这样一个行变量可以容纳整行SELECT或 FOR 查询结果，只要该查询列集合与声明的变量类型相匹配即可。
行值的各个字段使用通用的点符号进行访问，例如`rowvar.column`。

函数的参数可以是复合类型（完整的表行）。 在这种情况下，对应的标识符`$n`将是行变量，可以从中选择字段， 例如`$1.user_id.`

只有表行的用户定义的列可以在行类型变量中访问，而不是OID或其他系统列。 行类型的字段会继承数据类型（如char(n))的表的字段大小和精度。

```
# 定义表
CREATE TABLE table1 (
  f1 text,
  f2 numeric,
  f3 integer
) distributed by (f1);

# 插入数据
INSERT INTO table1 values 
('test1', 14.1, 3),
('test2', 52.5, 2),
('test3', 32.22, 6),
('test4', 12.1, 4);

#函数被归类为 VOLATILE函数是 因为在单个表的扫描中函数值可能会改变
CREATE OR REPLACE FUNCTION t1_calc( name text) RETURNS integer 
AS $$ 
DECLARE
    t1_row   table1%ROWTYPE;
    calc_int table1.f3%TYPE;
BEGIN
    SELECT * INTO t1_row FROM table1 WHERE table1.f1 = $1;
    calc_int = (t1_row.f2 * t1_row.f3)::integer ;
    RETURN calc_int ;
END;
$$ LANGUAGE plpgsql VOLATILE;

# 运行函数
select t1_calc( 'test1' );
```

- 使用可变数量的参数
只要所有可选参数的数据类型相同，就可以声明一个PL/pgSQL函数来接受可变数量的参数。
用户必须将函数的最后一个参数标记为 VARIADIC 并使用数组类型声明参数。 用户可以将包含`VARIADIC`参数的函数引用为可变函数。

```
# 可变函数返回数值变量数组的最小值
CREATE FUNCTION mleast (VARIADIC numeric[]) 
    RETURNS numeric AS $$
  DECLARE minval numeric;
  BEGIN
    SELECT min($1[i]) FROM generate_subscripts( $1, 1) g(i) INTO minval;
    RETURN minval;
END;
$$ LANGUAGE plpgsql;

# 测试函数
SELECT mleast(10, -1, 5, 4.4);
```

实际上，VARIADIC位置之外的所有实际参数都被收集成一维数组。   
用户可以将已构建的数组传递给可变函数。当用户想要在可变函数之间传递数组时，这是特别有用的。在函数调用中指定 VARIADIC如下所示:

```
SELECT mleast(VARIADIC ARRAY[10, -1, 5, 4.4]);
# 可以防止PL/pgSQL将函数的可变参数扩展到其元素类型中。
```

- 使用默认参数值
用户可以使用默认值声明一些或所有输入参数的PL/pgSQL的函数。无论调用的函数是否少于声明的参数的数量，每当调用的函数少于声明的参数数时，
就会插入默认值。因为参数只能从实际参数列表的末尾删除，所以必须在使用默认值定义的参数之后为所有参数提供默认值。

```
# 使用= 符号代替关键字DEFAULT
CREATE FUNCTION use_default_args(a int, b int DEFAULT 2, c int DEFAULT 3)
    RETURNS int AS $$
DECLARE
    sum int;
BEGIN
    sum := $1 + $2 + $3;
    RETURN sum;
END;
$$ LANGUAGE plpgsql;
```

- 使用多态数据类型
PL/pgSQL支持多态`anyelement`,`anyarray`,`anyenum`,和`anynonarray`类型。 使用这些类型，用户可以创建一个运行在多种数据类型上的PL/pgSQL函数。

当PL/pgSQL函数的返回类型被声明为多态类型时，将创建一个名为`$0`的特殊参数。 数据类型`$0`识别从实际输入类型推导的函数的返回类型。

```
CREATE FUNCTION add_two_values(v1 anyelement,v2 anyelement)
    RETURNS anyelement AS $$ 
DECLARE 
    sum ALIAS FOR $0;
BEGIN
    sum := v1 + v2;
    RETURN sum;
END;
$$ LANGUAGE plpgsql;
```

在这种情况下`add_two_values()`的返回类型为`float`，用户还可以在多态函数中指定VARIADIC 参数。

- 匿名块
此示例将使用 DO命令作为匿名块执行上一个示例中的函数。在该示例中，匿名块从临时表中检索输入值。

```
CREATE TEMP TABLE list AS VALUES ('test1') DISTRIBUTED RANDOMLY;
DO $$ 
DECLARE 
    t1_row   table1%ROWTYPE;
    calc_int table1.f3%TYPE;
BEGIN
    SELECT * INTO t1_row FROM table1, list WHERE table1.f1 = list.column1 ;
    calc_int = (t1_row.f2 * t1_row.f3)::integer ;
    RAISE NOTICE 'calculated value is %', calc_int ;
END $$ LANGUAGE plpgsql ;
```

```
CREATE OR REPLACE FUNCTION get_json_key(IN json_str text,IN key_str character varying,OUT value_str character varying) RETURNS character varying AS
$BODY$
declare
  tmp_str VARCHAR; 
  arry VARCHAR[];
  mark int;
  tmp_str2 VARCHAR; 
  str_len int;
  sub_len int;
BEGIN
select regexp_split_to_array(json_str,',') into arry;
--RAISE NOTICE 'arry -|- %', arry;
  FOR i IN 1..10 LOOP
     SELECT arry[i] INTO tmp_str;
     RAISE NOTICE 'tmp_str -|- %', tmp_str;
     IF tmp_str IS NOT NULL THEN
        SELECT POSITION(key_str IN tmp_str) INTO mark;
        --RAISE NOTICE 'mark -|- %', mark;
        IF  mark > 0 THEN
           SELECT POSITION(':' IN tmp_str)+2 INTO mark;
           RAISE NOTICE '截取的位置 -|- %', mark;
           SELECT length(tmp_str) INTO str_len;
		   RAISE NOTICE '字符串长度 -|- %', str_len;
	       SELECT (str_len-mark) INTO sub_len;
           RAISE NOTICE '截取字符串长度 -|- %', sub_len;
		   SELECT substring(tmp_str,mark,sub_len) into tmp_str2;
		   RAISE NOTICE '截取字符串 -|- %', tmp_str2;
           SELECT regexp_replace(tmp_str2,'("|{|}|:)','') into value_str;
           --RAISE NOTICE 'value_str -|- %', value_str;
           EXIT;
        END IF;   
     ELSE
        EXIT;
     END IF;
  END LOOP;
END
$BODY$ LANGUAGE plpgsql VOLATILE;
```

```
CREATE OR REPLACE FUNCTION PRO_DIRECT()
  RETURNS VARCHAR AS
$BODY$
declare
  v_sql TEXT;
  v_count int;
  v_row VARCHAR;
  v_tab_row VARCHAR;
BEGIN
	FOR v_tab_row in (select table_name from user_tables where table_name not like 'pg%') LOOP
		FOR v_row in (select node_name from pgxc_node where node_type='D') LOOP
			v_sql := 'execute direct on ('||v_row.node_name||') ''select count(*) from '||v_tab_row.table_name||''' ';
			EXECUTE v_sql into v_count;
			insert into tb_dn_cnt values (v_tab_row.table_name,v_row.node_name,v_count);
		END LOOP;
	END LOOP; 
END
$BODY$ LANGUAGE plpgsql VOLATILE;
```

