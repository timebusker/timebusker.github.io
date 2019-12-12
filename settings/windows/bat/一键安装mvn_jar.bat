::mvn install:install-file -Dfile=jar包的位置 -DgroupId=上面的groupId -DartifactId=上面的artifactId -Dversion=上面的version -Dpackaging=jar

mvn install:install-file -Dfile=D:/Workspaces/Eclipse-mars/sample-pay/sample-pay/sample-pay-Alipay/src/main/webapp/WEB-INF/lib/alipay-sdk-java20170307171631.jar -DgroupId=alipay -DartifactId=alipay-sdk-java20170307171631 -Dversion=1.0 -Dpackaging=jar

::mvn install:install-file -Dfile=D:/Workspaces/Eclipse-mars/roncoocom/roncoo-pay/roncoo-pay-service/src/lib/alipay-trade-sdk.jar -DgroupId=alipay -DartifactId=alipay-trade-sdk -Dversion=1.0 -Dpackaging=jar