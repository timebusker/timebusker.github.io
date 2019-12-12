// 懒加载
$(document).ready(function(){
     var sqid = Math.floor((Math.random()*40)+1);
     console.log(sqid);
	 $(".intro-header").attr({
	     "position" : "relative",
         "href" : "http://www.timebusker.top",
         "title" : "timebusker",
		 "style" : "background-image: url("+"'/img/top-photo/"+sqid+".jpg')"
     });
});

// 预加载
// (function($) {
//   $.preLoadImages = function() {
// 	 var sqid = Math.floor((Math.random()*40)+1);
//      console.log(sqid);
// 	 $(".intro-header").attr({
// 	     "position" : "relative",
//          "href" : "http://www.timebusker.top",
//          "title" : "timebusker",
// 	     "style" : "background-image: url("+"'/img/top-photo/"+sqid+".jpg')"
//      });
//   }
// })(jQuery)
// $.preLoadImages();
