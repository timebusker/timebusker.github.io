---
layout:     post
title:      Spring-MVC参数解析与前端数据提交
date:       2020-01-12
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spring相关
---

#### JQuery-Ajax定义和用法

`ajax()`方法通过`HTTP`请求加载远程数据。该方法是`jQuery`底层`AJAX`实现。简单易用的高层实现见`$.get`, `$.post`等。`$.ajax()`返回其创建的`XMLHttpRequest`对象。大多数情况下你无需直接操作该函数，除非你需要操作不常用的选项，以获得更多的灵活性。最简单的情况下，`$.ajax()`可以不带任何参数直接使用。

- `所有的选项都可以通过 $.ajaxSetup() 函数来全局设置。`

###### 语法

```
jQuery.ajax([settings])

// settings 可选。用于配置 Ajax 请求的键值对集合。可以通过 $.ajaxSetup() 设置任何选项的默认值。
```

###### 参数

参数 | 类型 |  值  
-|-|-
options | Object | 可选。AJAX 请求设置。所有选项都是可选的 |
`async` | Boolean | 默认值: true。默认设置下，所有请求均为异步请求。如果需要发送同步请求，请将此选项设置为 false。注意，同步请求将锁住浏览器，用户其它操作必须等待请求完成才可以执行。 |
beforeSend(XHR) | Function | 发送请求前可修改 XMLHttpRequest 对象的函数，如添加自定义 HTTP 头。XMLHttpRequest 对象是唯一的参数。这是一个 Ajax 事件。如果返回 false 可以取消本次 ajax 请求。 |
cache | Boolean | 默认值: true，dataType 为 script 和 jsonp 时默认为 false。设置为 false 将不缓存此页面。 |
`complete(XHR, TS)` | Function | 请求完成后回调函数 (请求成功或失败之后均调用)。参数： XMLHttpRequest 对象和一个描述请求类型的字符串。这是一个 Ajax 事件。 |
contentType | String | 默认值: "application/x-www-form-urlencoded"。发送信息至服务器时内容编码类型。默认值适合大多数情况。如果你明确地传递了一个 content-type 给 $.ajax() 那么它必定会发送给服务器（即使没有数据要发送）。 |
context | Object | 这个对象用于设置 Ajax 相关回调函数的上下文。也就是说，让回调函数内 this 指向这个对象（如果不设定这个参数，那么 this 就指向调用本次 AJAX 请求时传递的 options 参数）。比如指定一个 DOM 元素作为 context 参数，这样就设置了 success 回调函数的上下文为这个 DOM 元素。 |
`data` | String | 发送到服务器的数据。将自动转换为请求字符串格式。GET 请求中将附加在 URL 后。查看 processData 选项说明以禁止此自动转换。必须为 Key/Value 格式。如果为数组，jQuery 将自动为不同值对应同一个名称。如 {foo:["bar1", "bar2"]} 转换为 '&foo=bar1&foo=bar2'。 |
dataFilter | Function | 给 Ajax 返回的原始数据的进行预处理的函数。提供 data 和 type 两个参数：data 是 Ajax 返回的原始数据，type 是调用 jQuery.ajax 时提供的 dataType 参数。函数返回的值将由 jQuery 进一步处理。 |
`dataType` | String | 预期服务器返回的数据类型。如果不指定，jQuery 将自动根据 HTTP 包 MIME 信息来智能判断。随后服务器端返回的数据会根据这个值解析后，传递给回调函数。可用值:"xml": 返回 XML 文档，可用 jQuery 处理。"html": 返回纯文本 HTML 信息；包含的 script 标签会在插入 dom 时执行。"script": 返回纯文本 JavaScript 代码。不会自动缓存结果。除非设置了 "cache" 参数。注意：在远程请求时(不在同一个域下)，所有 POST 请求都将转为 GET 请求。（因为将使用 DOM 的 script标签来加载）"json": 返回 JSON 数据 。"jsonp": JSONP 格式。使用 JSONP 形式调用函数时，如 "myurl?callback=?" jQuery 将自动替换 ? 为正确的函数名，以执行回调函数。"text": 返回纯文本字符串 |
`error` | Function | 自动判断 (xml 或 html)。请求失败时调用此函数。有以下三个参数：XMLHttpRequest 对象、错误信息、（可选）捕获的异常对象。如果发生了错误，错误信息（第二个参数）除了得到 null 之外，还可能是 "timeout", "error", "notmodified" 和 "parsererror"。这是一个 Ajax 事件。 |
global | Boolean | 是否触发全局 AJAX 事件。默认值: true。设置为 false 将不会触发全局 AJAX 事件，如 ajaxStart 或 ajaxStop 可用于控制不同的 Ajax 事件。 |
ifModified | Boolean | 仅在服务器数据改变时获取新数据。默认值: false。使用 HTTP 包 Last-Modified 头信息判断。在 jQuery 1.4 中，它也会检查服务器指定的 'etag' 来确定数据没有被修改过。 |
jsonp | String | 在一个 jsonp 请求中重写回调函数的名字。这个值用来替代在 "callback=?" 这种 GET 或 POST 请求中 URL 参数里的 "callback" 部分，比如 {jsonp:'onJsonPLoad'} 会导致将 "onJsonPLoad=?" 传给服务器。 |
jsonpCallback | String | 为 jsonp 请求指定一个回调函数名。这个值将用来取代 jQuery 自动生成的随机函数名。这主要用来让 jQuery 生成度独特的函数名，这样管理请求更容易，也能方便地提供回调函数和错误处理。你也可以在想让浏览器缓存 GET 请求的时候，指定这个回调函数名。 |
password | String | 用于响应 HTTP 访问认证请求的密码 |
processData | Boolean | 默认值: true。默认情况下，通过data选项传递进来的数据，如果是一个对象(技术上讲只要不是字符串)，都会处理转化成一个查询字符串，以配合默认内容类型 "application/x-www-form-urlencoded"。如果要发送 DOM 树信息或其它不希望转换的信息，请设置为 false。 |
scriptCharset | String | 只有当请求时 dataType 为 "jsonp" 或 "script"，并且 type 是 "GET" 才会用于强制修改 charset。通常只在本地和远程的内容编码不同时使用。 |
`success` | Function | 请求成功后的回调函数。参数：由服务器返回，并根据 dataType 参数进行处理后的数据；描述状态的字符串。这是一个 Ajax 事件。 |
traditional | Boolean | 如果你想要用传统的方式来序列化数据，那么就设置为 true。请参考工具分类下面的 jQuery.param 方法。 |
timeout | Number | 设置请求超时时间（毫秒）。此设置将覆盖全局设置。 |
`type` | String | 默认值: "GET")。请求方式 ("POST" 或 "GET")， 默认为 "GET"。注意：其它 HTTP 请求方法，如 PUT 和 DELETE 也可以使用，但仅部分浏览器支持。 |
`url` | String | 默认值: 当前页地址。发送请求的地址。 |
username | String | 用于响应 HTTP 访问认证请求的用户名。 |
xhr | Function | 需要返回一个 XMLHttpRequest 对象。默认在 IE 下是 ActiveXObject 而其他情况下是 XMLHttpRequest 。用于重写或者提供一个增强的 XMLHttpRequest 对象。这个参数在 jQuery 1.3 以前不可用。 |

- 回调函数
如果要处理 `$.ajax()`得到的数据，则需要使用回调函数：`beforeSend`、`error`、`dataFilter`、`success`、`complete`。

函数 |  使用介绍  
-|- 
beforeSend | 在发送请求之前调用，并且传入一个 XMLHttpRequest 作为参数。 |
`error` | 在请求出错时调用。传入 XMLHttpRequest 对象，描述错误类型的字符串以及一个异常对象（如果有的话） |
dataFilter | 在请求成功之后调用。传入返回的数据以及 "dataType" 参数的值。并且必须返回新的数据（可能是处理过的）传递给 success 回调函数。 |
`success` | 当请求之后调用。传入返回后的数据，以及包含成功代码的字符串。 |
complete | 当请求完成之后调用这个函数，无论成功或失败。传入 XMLHttpRequest 对象，以及一个包含成功或错误代码的字符串。 |


#### @RequestParam与@RequestBody

[灵活运用的@RequestParam和@RequestBody](https://www.cnblogs.com/blogtech/p/11172168.html)

[@requestBody 与@requestparam；@requestBody的加与不加的区别](https://blog.csdn.net/jiashanshan521/article/details/88244735)


#### Spring MVC参数解析处理器

> HandlerMethodArgumentResolver

HandlerMethodArgumentResolver是用来为处理器解析参数的，主要用在前面讲过的InvocableHandler-Method中。每个Resolver对应一种类型的参数，所以它的实现类非常多，其继承结构如图13-5所示。

![image](img/older/spring-mvc/1.png)

这里有一个实现类比较特殊，那就是HandlerMethodArgumentResolverComposite，它不具体解析参数，而是可以将多个别的解析器包含在其中，解析时调用其所包含的解析器具体解析参数，
这种模式在前面已经见过好几次了，在此就不多说了。下面来看一下HandlerMethodArgumentResolver接口的定义：

![image](img/older/spring-mvc/2.png)

非常简单，只有两个方法，一个用于判断是否可以解析传入的参数，另一个就是用于实际解析参数。

HandlerMethodArgumentResolver实现类一般有两种命名方式，一种是XXXMethod-ArgumentResolver，另一种是XXXMethodProcessor。前者表示一个参数解析器，
后者除了可以解析参数外还可以处理相应类型的返回值，也就是同时还是后面要讲到的Handler-Method-ReturnValueHandle。
其中的XXX表示用于解析的参数的类型。另外，还有个Adapter，它也不是直接解析参数的，而是用来兼容WebArgumentResolver类型的参数解析器的适配器。

- AbstractMessageConverterMethodArgumentResolver：使用HttpMessageConverter解析request body类型参数的基类。

- AbstractMessageConverterMethodProcessor：定义相关工具，不直接解析参数。

- HttpEntityMethodProcessor：解析HttpEntity和RequestEntity类型的参数。

- RequestResponseBodyMethodProcessor：解析注释@RequestBody类型的参数。

- RequestPartMethodArgumentResolver：解析注释了@RequestPart、MultipartFile类型以及javax.servlet.http.Part类型的参数。

- AbstractNamedValueMethodArgumentResolver：解析namedValue类型的参数（有name的参数，如cookie、requestParam、requestHeader、pathVariable等）的基类，主要功能有：①获取name；②resolveDefaultValue、handleMissingValue、handleNullValue；③调用模板方法resolveName、handleResolvedValue具体解析。

- AbstractCookieValueMethodArgumentResolver：解析注释了@CookieValue的参数的基类。

- ServletCookieValueMethodArgumentResolver：实现resolveName方法，具体解析cookieValue。

- ExpressionValueMethodArgumentResolver：解析注释@Value表达式的参数，主要设置了beanFactory，并用它完成具体解析，解析过程在父类完成。

- MatrixVariableMethodArgumentResolver：解析注释@MatrixVariable而且不是Map类型的参数（Map类型使用MatrixVariableMapMethodArgumentResolver解析）。

- PathVariableMethodArgumentResolver：解析注释@PathVariable而且不是Map类型的参数（Map类型则使用PathVariableMapMethodArgumentResolver解析）。

- RequestHeaderMethodArgumentResolver：解析注释了@RequestHeader而且不是Map类型的参数（Map类型则使用RequestHeaderMapMethodArgumentResolver解析）。

- RequestParamMethodArgumentResolver：可以解析注释了@RequestParam的参数、MultipartFile类型的参数和没有注释的通用类型（如int、long等）的参数。如果是注释了@RequestParam的Map类型的参数，则注释必须有name值（否则使用RequestParamMapMethodArgumentResolver解析）。

- AbstractWebArgumentResolverAdapter：用作WebArgumentResolver解析器的适配器。

- ServletWebArgumentResolverAdapte：给父类提供了request。

- ErrorsMethodArgumentResolver：解析Errors类型的参数（一般是Errors或Binding-Result），当一个参数绑定出现异常时会自动将异常设置到其相邻的下一个Errors类型的参数，设置方法就是使用了这个解析器，内部是直接从model中获取的。

- HandlerMethodArgumentResolverComposite：argumentResolver的容器，可以封装多个Resolver，具体解析由封装的Resolver完成，主要为了方便调用。

- MapMethodProcessor：解析Map型参数（包括ModelMap类型），直接返回mav-Container中的model。

- MatrixVariableMapMethodArgumentResolver：解析注释了@MatrixVariable的Map类型参数。

- ModelAttributeMethodProcessor：解析注释了@ModelAttribute的参数，如果其中的annotationNotRequired属性为true还可以解析没有注释的非通用类型的参数（RequestParamMethodArgumentResolver解析没有注释的通用类型的参数）。

- ServletModelAttributeMethodProcessor：对父类添加了Servlet特性，使用Servlet-RequestDataBinder代替父类的WebDataBinder进行参数的绑定。

- ModelMethodProcessor：解析Model类型参数，直接返回mavContainer中的model。

- PathVariableMapMethodArgumentResolver：解析注释了@PathVariable的Map类型的参数。

- RedirectAttributesMethodArgumentResolver：解析RedirectAttributes类型的参数，新建RedirectAttributesModelMap类型的RedirectAttributes并设置到mavContainer中，然后返回给我们的参数。

- RequestHeaderMapMethodArgumentResolver：解析注释了@RequestHeader的Map类型的参数。

- RequestParamMapMethodArgumentResolver：解析注释了@RequestParam的Map类型，而且注释中有value的参数。

- ServletRequestMethodArgumentResolver：解析WebRequest、ServletRequest、Multipart-Request、HttpSession、Principal、Locale、TimeZone、InputStream、Reader、HttpMethod类型和"java.time.ZoneId"类型的参数，它们都是使用request获取的。

- ServletResponseMethodArgumentResolver：解析ServletResponse、OutputStream、Writer类型的参数。

- SessionStatusMethodArgumentResolver：解析SessionStatus类型参数，直接返回mavContainer中的SessionStatus。

- UriComponentsBuilderMethodArgumentResolver：解析UriComponentsBuilder类型的参数。

> Model类型参数的ModelMethodProcessor解析器和解析注释了@PathVariable的参数类型的PathVariableMethodArgumentResolver解析器，这两种类型的参数使用得非常多

- ModelMethodProcessor既可以解析参数也可以处理返回值

![image](img/older/spring-mvc/3.png)

这个实现非常简单，supportsParameter方法判断如果是Model类型就可以，resolveArgument方法是直接返回mavContainer里的Model。通过前面的分析知道，
这时的Model可能已经保存了一些值，如SessionAttribute中的值、FlashMap中的值等，所以在处理器中如果定义了Model类型的参数，给我们传的Model中可能已经保存的有值了。

- PathVariableMethodArgumentResolver

用于解析url路径中的值，它的实现比较复杂，它继承自AbstractNamedValueMethodArgumentResolver，前面介绍过这个解析器是处理namedValue类型参数的基类，
cookie、requestParam、requestHeader、pathVariable等类型参数的解析器都继承自它，
它跟我们之前讲过的很多组件一样，使用的也是模板模式。其中没有实现supportsParameter方法，只实现了resolveArgument方法，代码如下：

![image](img/older/spring-mvc/4.png)

通过注释大家可以看到，首先根据参数类型获取到NamedValueInfo，然后将它传入模板方法resolveName由子类具体解析，最后对解析的结果进行处理。
这里用到的Named-ValueInfo是一个内部类，其中包含的三个属性分别表示参数名、是否必须存在和默认值，定义如下：

![image](img/older/spring-mvc/5.png)

总结一下resolveArgument过程中所使用的方法，理解了这些方法这里的处理过程就容易理解了。

- getNamedValueInfo方法通过参数类型获取NamedValueInfo，具体过程是先从缓存中获取，如果获取不到则调用createNamedValueInfo方法根据参数创建，
createNamedValueInfo是一个模板方法，在子类实现，创建出来后调用updateNamedValueInfo更新NamedValueInfo，最后保存到缓存namedValueInfoCache中。
updateNamedValueInfo方法具有两个功能：①如果name为空则使用parameter的name；②如果默认值是代表没有的ValueConstants.DEFAULT_NONE类型则设置为null。

![image](img/older/spring-mvc/6.png)

createNamedValueInfo在子类PathVariableMethodArgumentResolver的实现是根据@PathVariable注释创建的，这里使用了继承自NamedValueInfo的内部类PathVariable-NamedValueInfo，
在PathVariableNamedValueInfo的构造方法里使用@PathVariable注释的value值创建了NamedValueInfo，默认required为true，也就是必须存在，
如果没解析到值会抛异常，defaultValue使用了ValueConstants.DEFAULT_NONE，这是一个专门用来代表空默认值的变量，代码如下：

![image](img/older/spring-mvc/7.png)

- resolveName，这个方法用于具体解析参数，是个模板方法，PathVariableMethodArgumentResolver中实现如下：

![image](img/older/spring-mvc/8.png)

可以看到它是直接从request里获取的HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE属性的值，这个值是在RequestMappingInfoHandlerMapping中的handleMatch中设置的，
也就是在HandlerMapping中根据lookupPath找到处理请求的处理器后设置的。

- resolveDefaultValue，这个方法是根据NamedValueInfo里的defaultValue设置默认值，如果包含占位符会将其设置为相应的值。

- handleMissingValue，如果参数是必须存在的，也就是NamedValueInfo的required为true，但是没有解析出参数，而且也没有默认值，
就会调用（如果是java1.8中的Optional类型则不调用），这也是个模板方法，PathVariableMethodArgumentResolver中直接抛出了异常，代码如下：

![image](img/older/spring-mvc/9.png)

- handleNullValue，如果解析结果为null，而且也没有默认值，并且handleMissingValue没调用或者调用了但没抛异常的情况下才会执行，可见这个方法执行的机会是比较小的，
主要用于没解析出参数值也没默认值，不过是Optional类型参数的情况。

首先判断所需的参数是不是Boolean类型，如果是则给它设置为false，
如果是其他原始的类型（原始类型共包含Boolean、Character、Byte、Short、Integer、Long、Float、Double和Void九个）则抛出异常，否则直接返回。代码如下：

![image](img/older/spring-mvc/10.png)

也就是说如果是原始类型（除了Boolean），即使是Optional类型（如Optional<Double>）也会抛出异常，这是因为原始类型不可以转换为null，
如果想不抛异常可以通过对应的包装类型进行声明，如Optional<double>，这样就不会抛异常了。

- handleResolvedValue，用于处理解析出的参数值，是模板方法，PathVariableMethodArgumentResolver中实现如下：

![image](img/older/spring-mvc/11.png)