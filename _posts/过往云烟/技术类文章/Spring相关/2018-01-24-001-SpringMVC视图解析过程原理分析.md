---
layout:     post
title:      SpringMVC视图解析过程原理分析
date:       2018-05-04
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spring相关
---

#### 角色解析 
在一个web项目中，典型的MVC架构将后台分为`Controller、Service、DAO`三层，分别实现不同的逻辑功能，下面是一个web请求过程中，我们后台的处理过程：  
![SpringMVC视图解析过程原理分析](img/older/spring/1.png)   
 
#### 方法入参灵活绑定
在原生`Servlet`中，我们通过在`doGet`和`doPost`方法绑定web资源访问接口：`HttpServletRequest`和`HttpServletResponse`到入参来进一步
通过`request.getParameter()`等方法获取我们的web资源。在SpringMVC中，我们一样可以将`HttpServletRequest`和`HttpServletResponse`绑定到入参中使用，
但除此之外，`SpringMVC`还能进一步分析我们处理方法的入参信息，将各类请求资源绑定到我们的方法入参上，并将数据类型转化为我们定义的类型，
为我们可以节省了大量的参数获取、初始化工作。    

##### 简单名称对应绑定参数    
```
# /test?id=111  
@RequestMapping("/test")
public void test8(Integer id ){
    System.out.println(id);
}
# /test?id=aaa则服务器会响应400错误。这是因为类型转换异常“aaa”不能转换java.lang.Integer  
```  

##### 使用`@RequestParam`绑定参数   
在方法入参上使用注解`@RequestParam`能为我们完成更灵活的参数绑定工作，在上一个实例中，我们通过名称对应简单地完成了参数绑定，假如我们现在有需求：   
 - 某个关键参数必须传入（比如登陆，我们要求必须有用户名和密码）。   
 - 某个参数可以不传，但必须要有默认值。    

```
@RequestMapping("/login")
public void login(@RequestParam(value = "userName",required = true) String name,//绑定userName,要求必须
        @RequestParam(value = "password",required = true) String pwd){//绑定password,因为在value上对应了，所以方法入参名称可以为其他字符串
	// 其中userName、password均为也面值
    System.out.println(userName + "-" + pwd);
}

@RequestMapping("/list")
public void list(@RequestParam(value = "pageNow",required = false , defaultValue = "1") Integer pageNow){//模拟分页查询，当前页码可以不传，默认为第一页
    System.out.println(pageNow);
}
```    

![SpringMVC视图解析过程原理分析](img/older/spring/2.png)   

##### 使用`@CookieValue`绑定`cookie`  
在一般情况下，我们要获取cookie信息，需要使用`request.getHeader("cookie")`或`request.getCookies()`等方法来获取，
而使用`@CookieValue`能将我们需要的特定cookie信息绑定到方法入参中。     

```
@RequestMapping("cookie")
public void cookie(@CookieValue(value = "JSESSIONID",required = false) String cookie ){
    System.out.println(cookie);
}
```    

value指定了对应`cookie`的名称，`required`设置为`false`表示非必须的，它还有一个属性`defaultValue`设置不存在时的默认值。  
 
##### 使用@RequestHeader绑定头信息  
浏览器请求头完整信息：      

```
Accept text/html,application/xhtml+xml,application/xml;q=0.9,/;q=0.8 
Accept-Encoding gzip, deflate 
Accept-Language en-US,en;q=0.5 
Connection keep-alive 
Host localhost:8080 
User-Agent Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:45.0) Gecko/20100101 Firefox/45.0

@RequestMapping("headerInfo")
public void headerInfo(@RequestHeader("Accept-Encoding") String Encoding,
        @RequestHeader("Accept-Language") String Language,
        @RequestHeader("Cache-Control") String Cache,
        @RequestHeader("Connection") String Connection,
        @RequestHeader("Cookie") String Cookie,
        @RequestHeader("Host") String Host,
        @RequestHeader("User-Agent") String Agent
        ){
        ......    
}
```    

- 需要注意的是，如果我们这里缺少对应的头信息，而尝试获取的话，而抛出异常类似：`Missing header ‘xxxxx’ of type [java.lang.String]`   

##### 使用`IO`对象作为入参     
在`HttpServlet`中，我们可以通过`request.getReader()`方法读取请求信息，使用`response.getOutputStream(),getWriter()`方法输出响应信息，同样的，
在springMVC中，我们可以将上述IO对象绑定到方法入参中使用,spring完成IO**包装和绑定**,输入输出各一个，如果同类超过一个，就会报错。      
 
```   
@RequestMapping(/file)
public void IO(BufferedReader reader,PrintWriter printWriter ){
    //输出org.apache.catalina.connector.CoyoteReader@368433b8
    System.out.println(reader);
	//输出org.apache.catalina.connector.CoyoteWriter@215f90fe
    System.out.println(printWriter);
}
@RequestMapping("/files")
public void IO2(InputStream inputStream,OutputStream outputStream){
    //输出org.apache.catalina.connector.CoyoteInputStream@3c37a4ed
    System.out.println(inputStream);
	//输出org.apache.catalina.connector.CoyoteOutputStream@692ce27d
    System.out.println(outputStream);
}
```     

#### 请求响应数据转换器-JSON与对象互转   
`HttpMessageConveter`为我们提供了强大的数据转换功能，将我们的请求数据转换为一个java对象，或将java对象转化为特定格式输出等。
比如我们常见的从前端注册表单获取json数据并转化为User对象，或前端获取用户信息，后端输出User对象转换为json格式传输给前端等。    

Spring 为我们提供了众多的HttpMessageConveter实现类，其中我们可能用得最多的三个实现类是：   
![SpringMVC视图解析过程原理分析](img/older/spring/3.png)     

转换器的装配方式有两种，一种是通过注册`org.springframework.web.servlet.mvc.annotation.AnnotationMethodHandlerAdapter`来装配`messageConverters`，如下所示：    
 
```  
<bean class="org.springframework.web.servlet.mvc.annotation.AnnotationMethodHandlerAdapter">
    <property name="messageConverters"><!-- 装配数据转换器 -->
        <list>
            <ref bean="jsonConverter" /><!-- 指定装配json格式的数据转换器 -->
        </list>
    </property>
</bean>

<bean id="jsonConverter" class="org.springframework.http.converter.json.MappingJacksonHttpMessageConverter">
    <!-- 使用MappingJacksonHttpMessageConverter完成json数据转换 -->
    <property name="supportedMediaTypes" value="application/json" />
    <!-- 设置转换的media类型为application/json -->
</bean>
```    

另一种是启用注解`<mvc:annotation-driven /> `，该注解会会初始化7个转换器：       
   - ByteArrayHttpMessageConverter 
   - StringHttpMessageConverter 
   - ResourceHttpMessageConverter 
   - SourceHttpMessageConverter 
   - XmlAwareFormHttpMessageConverter 
   - Jaxb2RootElementHttpMessageConverter 
   - MappingJacksonHttpMessageConverter   
   
但我们想要在**控制层**完成数据的输入输出转换，需要通过下列途径：    
  - 使用`@RequestBody`和`@ResponseBody`对处理方法进行标注。其中`@RequestBody`通过合适的`HttpMessageConverter`将HTTP请求正文转换为我们需要的对象内容。
    而`@ResponseBody`则将我们的对象内容通过合适的`HttpMessageConverter`转换后作为HTTP响应的正文输出。   
  - 使用HttpEntity、ResponseEntity作为处理方法的入参或返回值。

##### 选择合适的数据转换器
通过AnnotationMethodHandlerAdapter注册了众多的数据转换器，而spring会针对不同的请求响应媒体类型，
Spring会为我们选择最恰当的数据转换器，它是按以下流程进行寻找的：    
  - 首先获取注册的所有HttpMessageConverter集合   
  - 然后客户端的请求header中寻找客户端可接收的类型，比如 `Accept application/json,application/xml`等，组成一个集合
  - 所有的HttpMessageConverter 都有canRead和canWrite方法 返回值都是boolean，
    看这个HttpMessageConverter是否支持当前请求的读与写，读对应@RequestBody注解, 写对应@ResponseBody注解
  - 遍历HttpMessageConverter集合与前面获取可接受类型进行匹配，如果匹配直接使用当前第一个匹配的HttpMessageConverter，
    然后return（一般是通过Accept和返回值对象的类型进行匹配）
  
#### [Spring-RestTemplate(非常强大的功能)](https://blog.csdn.net/u013161431/article/details/78750727)  
REST（RepresentationalState Transfer）是Roy Fielding 提出的一个描述互联系统架构风格的名词。REST定义了一组体系架构原则，
您可以根据这些原则设计以系统资源为中心的Web 服务，包括使用不同语言编写的客户端如何通过 HTTP处理和传输资源状态。     
  
**而`Spring-RestTemplate`简化了发起HTTP请求以及处理响应的过程，并且支持REST。**       

#### 模型视图方法源码分析   
在完整web开发中，springMVC主要充当了控制层的角色。它接受视图层的请求，获取视图层请求数据，
再对数据进行业务逻辑处理，然后封装成视图层需要的模型数据，再将数据导向到jsp等视图界面。   

通过对@RequestMapping和方法入参绑定的分析，完成了视图层->控制层的数据交接，然后业务逻辑处理主要由Service层进行。
那么接下来很关键的就是，**如何将视图数据导向到特定的视图中？**   

广泛意义上，视图，并非是单指前端界面如jsp\html等，我们可能需要给安卓、IOS等写后台接口、因前后端分离而放弃视图界面导向如对前端ajax请求的纯数据流输出等。
这时，我们的视图可以为json视图、xml视图、乃至PDF视图、Excel视图等。   

SpringMVC为我们提供了多种途径输出模型数据：     
![SpringMVC视图解析过程原理分析](img/older/spring/4.png)     

##### Model  
model是一个接口，我们可以简单地将model的实现类理解成一个Map,将模型数据以键值对的形式返回给视图层使用。
在springMVC中，每个方法被前端请求触发调用前，都会创建一个隐含的模型对象，作为模型数据的存储容器。
这是一个Request级别的模型数据，我们可以在前端页面如jsp中通过HttpServletRequest等相关API读取到这些模型数据。 
在model中，定义有如下常用接口方法：      

```
//添加键值属性对
Model addAttribute(String attributeName, Object attributeValue);

//以属性的类型为键添加属
Model addAttribute(Object attributeValue);

//以属性和集合的类型构造键名添加集合属性，如果有同类型会存在覆盖现象
Model addAllAttributes(Collection<?> attributeValues);

//将attributes中的内容复制到当前的model中,如果当前model存在相同内容，会被覆盖
Model addAllAttributes(Map<String, ?> attributes);

//将attributes中的内容复制到当前的model中,如果当前model存在相同内容，不会被覆盖
Model mergeAttributes(Map<String, ?> attributes);

//判断是否有相应的属性值
boolean containsAttribute(String attributeName);

//将当前的model转换成Map
Map<String, Object> asMap();
```  

##### View  
view也是一个接口，它表示一个响应给用户的视图如jsp文件，pdf文件，html文件。Spring为我们提供`ViewResolver`实现类用来解析不同的View。  

在我们最开始配置springMVC核心文件时，就用到了InternalResourceViewResolver,它是一个内部资源视图解析器。
会把返回的视图名称都解析为`InternalResourceView`对象，`InternalResourceView`会把`Controller`处理器方法返回的模型属性都存放到对应的`request`属性中，
然后通过`RequestDispatcher`在服务器端把请求`forword`重定向到目标URL。     
  
```
<bean id="viewResolver"
    class="org.springframework.web.servlet.view.InternalResourceViewResolver">
    <property name="prefix" value="/WEB-INF/views/"></property><!-- 前缀，在springMVC控制层处理好的请求后，转发配置目录下的视图文件 -->
    <property name="suffix" value=".jsp"></property><!-- 文件后缀，表示转发到的视图文件后缀为.jsp -->
</bean>
```   

##### ModelAndView     

```
public class ModelAndView {
    //视图成员
    private Object view;

    //模型成员
    private ModelMap model;

    //是否调用clear()方法清空视图和模型
    private boolean cleared = false;
	
    //空构造方法
    public ModelAndView() {
    }
	
    //简便地使用视图名生成视图，具体解析由DispatcherServlet的视图解析器进行
    public ModelAndView(String viewName) {
        this.view = viewName;
    }
	
    //指定一个视图对象生成视图
    public ModelAndView(View view) {
        this.view = view;
    }
	
    //指定视图名同时绑定模型数据，这里模型数据以追加的形式添加在原来的视图数据中
    public ModelAndView(String viewName, Map<String, ?> model) {
        this.view = viewName;
        if (model != null) {
            getModelMap().addAllAttributes(model);
        }
    }
	
    //指定一个视图对象同时绑定模型数据，这里模型数据以追加的形式添加在原来的视图数据中
    public ModelAndView(View view, Map<String, ?> model) {
        this.view = view;
        if (model != null) {
            getModelMap().addAllAttributes(model);
        }
    }
	
    //简便配置：指定视图名，同时添加单个属性
    public ModelAndView(String viewName, String modelName, Object modelObject) {
        this.view = viewName;
        addObject(modelName, modelObject);
    }
	
    //简便配置：指定一个视图对象，同时添加单个属性
    public ModelAndView(View view, String modelName, Object modelObject) {
        this.view = view;
        addObject(modelName, modelObject);
    }
	
    //设置当前视图名
    public void setViewName(String viewName) {
        this.view = viewName;
    }
	
    //获取视图名，如果当前视图属性为view而非名字（String)则返回null
    public String getViewName() {
        return (this.view instanceof String ? (String) this.view : null);
    }
	
    //设置当前视图对象
    public void setView(View view) {
        this.view = view;
    }
	
    //获取视图,如果非view实例，则返回null
    public View getView() {
        return (this.view instanceof View ? (View) this.view : null);
    }
	
    //判断当前视图是否存在
    public boolean hasView() {
        return (this.view != null);
    }
	
    //获取模型Map，如果为空,则新建一个
    public ModelMap getModelMap() {
        if (this.model == null) {
            this.model = new ModelMap();
        }
        return this.model;
    }
	
    //同getModelMap
    public Map<String, Object> getModel() {
        return getModelMap();
    }
	
    //添加单个键值对属性
    public ModelAndView addObject(String attributeName, Object attributeValue) {
        getModelMap().addAttribute(attributeName, attributeValue);
        return this;
    }
	
    //以属性类型为键添加属性
    public ModelAndView addObject(Object attributeValue) {
        getModelMap().addAttribute(attributeValue);
        return this;
    }
	
    //将Map中的所有属性添加到成员属性ModelMap中
    public ModelAndView addAllObjects(Map<String, ?> modelMap) {
        getModelMap().addAllAttributes(modelMap);
        return this;
    }
	
    //清空视图模型，并设为清空状态
    public void clear() {
        this.view = null;
        this.model = null;
        this.cleared = true;
    }
	
    //判断是否为不含视图和模型
    public boolean isEmpty() {
        return (this.view == null && CollectionUtils.isEmpty(this.model));
    }
}
```

#### 模型数据绑定分析
使用@ModelAttribute、Model、Map、@SessionAttributes能便捷地将我们的业务数据封装到模型里并交由视图解析调用。   

##### 在方法入参上使用@ModelAttribute    
  
```
# SpringMVC核心文件配置  

<!-- 扫描com.mvc.controller包下所有的类，使spring注解生效 -->
<context:component-scan base-package="com.mvc.controller" />

<bean id="viewResolver"
    class="org.springframework.web.servlet.view.InternalResourceViewResolver">
    <property name="prefix" value="/WEB-INF/views/"></property><!-- 前缀，在springMVC控制层处理好的请求后，转发配置目录下的视图文件 -->
    <property name="suffix" value=".jsp"></property><!-- 文件后缀，表示转发到的视图文件后缀为.jsp -->
</bean>

# 编写控制器
@RequestMapping("/model")
public String model(@ModelAttribute User model){//绑定user属性到视图中
    model.setId(1);
    model.setPassword("123456");
    model.setUserName("timebusker");
    return "model1";
    //直接返回视图名，SpringMVC根据viewResolver会帮我们解析成/WEB-INF/views/model.jsp视图文件
	//返回字符串直接为视图名称，解析器会找到名称对应的视图Bean解析视图
}

# 编写视图层文件（JSP）
<body>
  用户id:${user.id }
  <br>
  用户名：${user.userName }
  <br>
  用户密码：${user.password }
</body>
```    

##### 在方法定义上使用@ModelAttribute     
在SpringMVC调用**任何方法**前，被`@ModelAttribute`注解的方法都会先被依次调用，并且这些注解方法的返回值都会被添加到模型中。     
  
```
@ModelAttribute
public User getUser1(){
    System.out.println("getUser1方法被调用");
    return new User(1,"AAA","AAA");
}
@ModelAttribute
public User getUser2(){
    System.out.println("getUser2方法被调用");
    return new User(2,"BBB","BBB");
}

@RequestMapping("model")
public String model(){//绑定user属性到视图中
    return "model";//直接返回视图名，springMVC会帮我们解析成/WEB-INF/views/model.jsp视图文件
}
```    

需要注意的是，这里两个方法都会被调用且不会被覆盖，但当存在多个同类型的模型数据切未指定参数名称（使用匿名属性）时，第一个才是有效的显示。   

##### 使用@ModelAttribute完成数据准备工作   
在实际开发中，我们常常需要在控制器每个方法调用前做些资源准备工作，如获取当次请求的ServletAPI，输入输出流等，
我们可以直接在方法入参上注明，springMVC会帮我们完成注入，如下所示：    
  
```
@RequestMapping("/")
public void doSomeThing(HttpServletRequest request,HttpServletResponse response,BufferedReader bufferedReader,PrintWriter printWriter){
    //可以直接调用ServletAPI，spring已帮我们完成注入
    System.out.println("do something....");
}
```

但现在问题来了，如果我们很多个方法都要使用到这些web资源，是否都要在方法入参上一一写明呢？这未免过于繁琐，
事实上，我们可以**结合被@ModelAttribute注解的方法会在控制器每个方法调用前执行的特点**来完成全局资源统一准备工作。     
   
```
@Controller
public abstract class BaseController {
    //准备web资源
    protected ServletContext servletContext;//声明为protected方便子类继承使用
    protected HttpSession session;
    protected HttpServletRequest request;
    protected HttpServletResponse response;
    //可以用来读取上传的IO流
    protected BufferedReader bufferedReader;
    //可以用来给安卓、IOS或网页ajax调用输出数据
    protected PrintWriter printWriter;

    @ModelAttribute
    protected void servletApi(HttpServletRequest request,HttpServletResponse response) throws IOException {
        this.request = request;
        this.response = response;
        this.session = request.getSession();
        this.servletContext = session.getServletContext();
        this.bufferedReader = request.getReader();
        this.printWriter = response.getWriter();
    }
}
```   

##### 使用Model和Map操作模型数据   
在springMVC中Model、ModelMap、Map（及其实现类）三者的地位是等价的，都可以将数据绑定到模型中供前端视图获取使用。    
  
```
@ModelAttribute
public void getUser(Map map){//我们使用map类型存储的数据一样会被绑定到model中
    System.out.println("getUser方法被调用");
    map.put("user1",new User(1,"AAA","AAA"));
    map.put("user2",new User(2,"BBB","BBB"));
}
@RequestMapping("model3")
public String model3(Model model){//我们可以在这绑定入参model读取前面的数据
    System.out.println(model.asMap().get("user1"));
    System.out.println(model.asMap().get("user2"));
    return "model3";
}
@RequestMapping("model4")
public String model4(HashMap map){//我们可以在这绑定入参map的任意实现类读取前面的数据
    System.out.println(map.get("user1"));
    System.out.println(map.get("user2"));
    return "model3";
}
@RequestMapping("model5")
public String model4(ModelMap map){//我们可以在这绑定入参modelMap读取前面的数据
    System.out.println(map.get("user1"));
    System.out.println(map.get("user2"));
    return "model3";
}
```    

##### @SessionAttribute和SessionStatus   
在项目中，我们可能需要将登陆用户的信息存储到Session中,使用@SessionAttribute我们可以将特定的模型属性存储到一个Session域的隐含模型中，
然后可以在同一个会话多个请求内共享这些信息。   

@SessionAttribute(“val”)会自动查找模型中名称对应为”val”的数据，并将其存储到一个Session域的隐含模型中（并且可以直接通过HttpSession API获取），
在以后的相同会话请求中，SessionAttribute会自动将其存放在调用方法的模型中。
但是，如果我们直接将数据存到Session中，在下次请求中，springMVC不会将改数据放到当次调用方法的模型里。    

@SessionAttribute相关的还有一个SessionStatus接口，它有唯一的实现类：    

```
public class SimpleSessionStatus implements SessionStatus {
    //判断当前会话是否结束，如果为true,则sprng会清空我们使用@SessionAttributes注册的Session数据
    //但它不会清空我们手动设置到Session域隐含模型中的数据。
    private boolean complete = false;

    //设置会话结束
    @Override
    public void setComplete() {
        this.complete = true;
    }
    //判断会话是否结束
    @Override
    public boolean isComplete() {
        return this.complete;
    }
}
```

通过SessionStatus,能灵活控制我们在@SessionAttributes注册的会话属性。    

##### 理解@ModelAttribute和@SessionAttributes的交互流程  
![SpringMVC视图解析过程原理分析](img/older/spring/5.png)     

#### 属性编辑器入参类型转换原理(类型转换器)
通过Http请求提交的参数都以字符串的形式呈现，但最终在springMVC的方法入参中，
我们却能得到各种类型的数据，包括Number、Boolean、复杂对象类型、集合类型、Map类型等，
这些都是SpringMVC内置的数据类型转换器完成的。SpringMVC的将请求数据绑定到方法入参的流程如下所示：   
![SpringMVC视图解析过程原理分析](img/older/spring/6.png)    

#### 使用注解完成数据格式化    

```  
public class Person {
    private String name;
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    private Date birthday;
    @NumberFormat(pattern = "#.###k")
    private Long salary;
}
``` 

#### 视图解析器分类详解
ModelAndView会在控制层方法调用完毕后作为返回值返回，里面封装好业务逻辑数据和视图对象或视图名。
视图对象往往会对模型进一步渲染，再由视图解析器进一步解析并向前端发出响应。在View接口中，定义了一个核心方法是：   
  
```
void render(Map<String, ?> model, HttpServletRequest request, HttpServletResponse response) throws Exception;
``` 

它的作用主要是渲染模型数据，整合web资源，并以特定形式响应给客户，这些形式可以是复杂JSP页面，也可以是简单的json、xml字符串。   
针对不同的响应形式，spring为我们设计了不同的View实现类：   
![SpringMVC视图解析过程原理分析](img/older/spring/7.png)      
针对不同的视图对象，我们使用不同的视图解析器来完成实例化工作。我们可以在Spring上下文配置多个视图解析器，
并通过order属性来指定他们之间的解析优先级顺序，order 越小，对应的 ViewResolver 将有越高的解析视图的权利。
当一个 ViewResolver 在进行视图解析后返回的 View 对象是 null 的话就表示该 ViewResolver 不能解析该视图，这时候就交给优先级更低的进行解析，
直到解析工作完成，如果所有视图解析器都不能完成将解析，则会抛出异常。      
类似于视图，Spring也为我们提供了众多的视图解析器实现类：    
![SpringMVC视图解析过程原理分析](img/older/spring/8.png)  

#### [各类视图输出实例分析](https://blog.csdn.net/qwe6112071/article/details/51080813)   

#### [Restful多视图混合输出](https://blog.csdn.net/qwe6112071/article/details/51081917)  
使用ContentNegotiatingViewResolver视图解析器来完成多种视图混合解析，
它是一个视图协调器，负责根据请求信息从当前环境选择一个最合适的解析器进行解析，也即是说，它本身并不负责解析视图。    

它有3个关键属性：   
  - favorPathExtension:如果设置为true(默认为true),则根据URL中的文件拓展名来确定MIME类型 
  - favorParameter:如果设置为true(默认为false),可以指定一个请求参数确定MIME类型，默认的请求参数为format,可以通过parameterName属性指定一个自定义属性。 
  - ignoreAcceptHeader(默认为false):则采用Accept请求报文头的值确定MIME类型。由于不同游览器产生的Accept头不一致，不建议采用Accept确定MIME类型。 
  - mediaTypes:用来配置不同拓展名或参数值映射到不同的MIME类型      

```
<!-- 根据确定出的不同MIME名，使用不同视图解析器解析视图 -->
<bean class="org.springframework.web.servlet.view.ContentNegotiatingViewResolver">
    <!-- 设置优先级 -->
    <property name="order" value="1" />
    <!-- 设置默认的MIME类型，如果没有指定拓展名或请求参数，则使用此默认MIME类型解析视图 -->
    <property name="defaultContentType" value="text/html" />
    <!-- 是否不适用请求头确定MIME类型 -->
    <property name="ignoreAcceptHeader" value="true" />
     <!-- 是否根据路径拓展名确定MIME类型 -->
    <property name="favorPathExtension" value="false" />
   <!-- 是否使用参数来确定MIME类型 -->
    <property name="favorParameter" value="true" /> 
    <!-- 上一个属性配置为true,我们指定type请求参数判断MIME类型 -->
    <property name="parameterName" value="type" />
    <!-- 根据请求参数或拓展名映射到相应的MIME类型 -->
    <property name="mediaTypes">
        <map>
            <entry key="html" value="text/html" />
            <entry key="xml" value="application/xml" />
            <entry key="json" value="application/json" />
            <entry key="excel" value="application/vnd.ms-excel"></entry>
        </map>
    </property>
    <!-- 设置默认的候选视图，如果有合适的MIME类型，将优先从以下选择视图，找不到再在整个Spring容器里寻找已注册的合适视图 -->
    <property name="defaultViews">
        <list>
            <bean class="org.springframework.web.servlet.view.InternalResourceView">
                <property name="url" value="WEB-INF/views/hello.jsp"></property>
            </bean>
            <bean
                class="org.springframework.web.servlet.view.json.MappingJacksonJsonView" />
            <ref local="myXmlView" />
            <bean class="com.mvc.view.ExcelView" />

        </list>
    </property>
</bean>
<!-- Excel视图 -->
<bean class="com.mvc.view.ExcelView" id="excelView" /><!-- 注册自定义视图 -->
<bean class="org.springframework.web.servlet.view.xml.MarshallingView"
    id="myXmlView">
    <property name="modelKey" value="articles" />
    <property name="marshaller" ref="xmlMarshaller" />
</bean>
<bean class="org.springframework.oxm.xstream.XStreamMarshaller"
    id="xmlMarshaller"><!-- 将模型数据转换为XML格式 -->
    <property name="streamDriver">
        <bean class="com.thoughtworks.xstream.io.xml.StaxDriver" />
    </property>
</bean>
```  