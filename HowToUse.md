# Table of contents #


# How to use JAWS #
### Server side definition ###
In the following examples we have a webservice located at http://www.exampleurl.com/service.asmx. The webservice contains following methods:
  * HelloWorld():String
  * HelloName(name:String):String
  * getUser():User
  * insertUser(newUser:User):void

There is also a class called "User" defined like this:
  * username:String
  * password:String
  * desciple:User


### Setting up the objects in AS3 ###
First of all we need to create a new webservice object, connected to the URL above (http://www.exampleurl.com/service.asmx).
```
var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
```
There we go, easy huh!? But for now, it doesn't do anything. The webservice class is built to not do anything until has to. Everything is on-demand. Not even the WSDL is downloaded until it has to (unless you want it to). If you want to force the class to download and parse the WSDL you run the downloadWSDL function:
```
var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
webservice.downloadWSDL();
```


### Running a parameterless function ###
To run a method there are 2 alternatives. The first one is to run the makeCall function. This functions returns an integer flagging how the call went, which is declared as constants on the Webservice class. If we want to run the HelloWorld method the code beneth will do exactly this:
```
var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
webservice.makeCall("HelloWorld");  
```
The other way to run a method is to use the fact that Webservice is a proxy, wich means you can run the methods direclty on the object. Like this:
```
var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
webservice.HelloWorld();
```
Both methods works exactly the same. If the WSDL is not loaded when the method is called, the call is queued and then fired as soon as it is possible.


### Running a method with parameters ###
To run a method that requires parameters, you have the same choice of method to run it. The first method, makeCall, takes all the rest parameters as parameters to run. If we take HelloName as example, the code under will run the method and use "Calle" as parameter:
```
var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
webservice.makeCall("HelloName", "Calle");
```
And for the proxy version it's even easier!
```
var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
webservice.HelloName("Calle");
```


### Handling the response ###
The response from the server doesn't come directly. An event is fired asynchronical as soon as it's possible. Because of this you have to set listeners to the Webservice object. The code beneath creates a new webservice object, and then listens to the response and traces it depending on if it went well or not:
```
private var webservice:Webservice;
public function init():void {
	 webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 webservice.addEventListener(WebserviceEvent.RESPONSE, onResponse);
}
private function onResponse(event:WebserviceEvent):void {
	 if(event.success) {
		 trace("The call went well!");
	 } else {
		 trace("An error occured when the method was called");
		 trace(event.faultCode + ": " + event.faultDescription);
	 }
}
```
The following code will run the HelloWorld method and the trace out the response ("Hello World")
```
private var webservice:Webservice;
public function init():void {
	 webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 webservice.addEventListener(WebserviceEvent.RESPONSE, onResponse);
	 webservice.HelloWorld();
}
private function onResponse(event:WebserviceEvent):void {
	 if(event.success) {
		 trace(event.response); //HelloWorld
	 } else {
		 trace("An error occured when the method was called");
		 trace(event.faultCode + ": " + event.faultDescription);
	 }
}
```


### Running a method with a callback function ###
The other way to handle the response is to use a callback function. Both methods works almost the same. The reason for the both to be here is to provide a wide variety of ways to handle the response to best suite the need and style of the developer. The function that handles the response must have two parameters, success(Boolean) and returnObject(Object). The names can of course be changed, but there need to be one bool and one object. The bool specifies if the call went well, and the object is the returned object from the server (lazydecoded, ie. it will be a as3 object). When using this method all responses are lazydecoded. To make a call and handle the event with a function the code below can be used:
```
private var webservice:Webservice;
public function init():void {
	 webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 webservice.makeCallWithCallback("HelloWorld", helloWorldResponse);
}
private function helloWorldResponse(success:Boolean, returnObject:Object):void {
	 trace(success + ": " + returnObject);
}
```


### Complex Types ###
Sometimes you will have to deal with complex types. Complex types are objects that isn't simple (DUH!?), which means other than string, numbers and booleans. These are defined in the WSDL and the developer doesn't need to worry about this. In this example we have a complex type, the User object, and we are going to create a new User, fill in the username and password and then send the object to the server using the webservice method insertUser.
```
private var webservice:Webservice;
public function init():void {
	 webservice = new Webservice("http://www.exampleurl.com/service.asmx");

	 var user:Object = new Object();
	 user.username = "Calle";
	 user.password = "foo";

	 webservice.insertUser(user);
}
```
Easy isn't it? Next we will add so we first insert the user, then get all users and show the information about theese:
```
private var webservice:Webservice;
public function init():void {
	 webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 webservice.addEventListener(WebserviceEvent.RESPONSE, onResponse);

	 var user:Object = new Object();
	 user.username = "Calle";
	 user.password = "foo";

	 webservice.insertUser(user);
	 webservice.getUser();
}
private function onResponse(event:WebserviceEvent):void {
	 if(event.success) {
		 trace(event.name); //getUser
		 trace(event.response.username); //Calle
		 trace(event.response.password); //foo
		 trace(event.response.desciple); //null
		 if(desciple != null) {
			 trace(event.response.desciple.username);
			 trace(event.response.desciple.password);
			 trace(event.response.desciple.desciple);
		 }
	 } else {
		 trace("An error occured when the method was called");
		 trace(event.faultCode + ": " + event.faultDescription);
	 }
}
```
Great! Now then, lets try even more complex types, lets add a desciple to the user we insert:
```
private var webservice:Webservice;
public function init():void {
	 webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 webservice.addEventListener(WebserviceEvent.RESPONSE, onResponse);

	 var user:Object = new Object();
	 user.username = "Calle";
	 user.password = "foo";

	 var user2:Object = new Object();
	 user2.username = "Yoda"; //HAHA
	 user2.password = "foo2";

	 user.desciple = user2; //Yoda becomes Calles desciple, splendid!

	 webservice.insertUser(user);
	 webservice.getUser();
}
private function onResponse(event:WebserviceEvent):void {
	 if(event.success) {
		 trace(event.name); //getUser
		 trace(event.response.username); //Calle
		 trace(event.response.password); //foo
		 trace(event.response.desciple); //[Object object]
		 if(desciple != null) {
			 trace(event.response.desciple.username); //Yoda
			 trace(event.response.desciple.password); //foo2
			 trace(event.response.desciple.desciple); //null
		 }
	 } else {
		 trace("An error occured when the method was called");
		 trace(event.faultCode + ": " + event.faultDescription);
	 }
}
```

### Using the Wizarddecoder ###
Inside the package is a class called Wizarddecoder. This class is used to transform the XML responses from the webservice to native AS3 objects, and also transform AS3 objects to XML that will be sent to the Webservice.
This is done automaticlly and called lazydecoding. But the wizarddecoder offers another way to decode the incoming objects, casted directly into objects of classes.
The serverside has a user class (You can see it here [HowToUse#Server\_side\_definition](HowToUse#Server_side_definition.md)). We will now create an exact duplicate in AS3, the class will look like this:
```
package  
{
	public class User
	{
		private var _username:String;
		private var _password:String;
		private var _desciple:User;
		
		public function get username():String { return _username; }
		
		public function set username(value:String):void 
		{
			_username = value;
		}
		
		public function get password():String { return _password; }
		
		public function set password(value:String):void 
		{
			_password = value;
		}
		
		public function get desciple():User { return _desciple; }
		
		public function set desciple(value:User):void 
		{
			_desciple = value;
		}
		
	}

}
```
**NOTE**: I have removed the construct as I don't do anything in it, but the classes that will be used by the Wizarddecoder may **NEVER** have parameters in the construct (as these won't work then).

The next we thing we need to do is to get the instance of the wizarddecoder from the webservice instance. To do this we use the getDecoder function:
```
webservice = new Webservice("http://www.exampleurl.com/service.asmx");
var decoder:WizardDecoder = webservice.getDecoder();
```
The decoder has a function called "insertClass". It is this function that will allow you to map an AS3 class to a .NET webservice class, and that will be automatically casted when arrived from .NET.
The typeName parameter is optional. If the class has the exact same name this parameter does not need to be set. However if you or some reason can't use the same class name, this parameter should be set so it mirrors the class name on the .NET side.
Since User is same on both sides, I wont set typeName:
```
webservice = new Webservice("http://www.exampleurl.com/service.asmx");
var decoder:WizardDecoder = webservice.getDecoder();
decoder.insertClass(User);
```
And that's it. Next time User is sent from the server it will be casted into the User class. Like this:
```
private var webservice:Webservice;
public function init():void {
         webservice = new Webservice("http://www.exampleurl.com/service.asmx");
		 var decoder:WizardDecoder = webservice.getDecoder();
		 decoder.insertClass(User);
		
         webservice.addEventListener(WebserviceEvent.RESPONSE, onResponse);

         var user:User = new User();
         user.username = "Calle";
         user.password = "foo";

         var user2:User = new User();
         user2.username = "Yoda"; //HAHA
         user2.password = "foo2";

         user.desciple = user2; //Yoda becomes Calles desciple, splendid!

         webservice.insertUser(user);
         webservice.getUser();
}
private function onResponse(event:WebserviceEvent):void {
         if(event.success) {
                 trace(event.name); //getUser
				 var user:User = event.response as User;
                 trace(user.username); //Calle
                 trace(user.password); //foo
                 trace(user.desciple); //[Object object]
                 if(user.desciple != null) {
                         trace(user.desciple.username); //Yoda
                         trace(user.desciple.password); //foo2
                         trace(user.desciple.desciple); //null
                 }
         } else {
                 trace("An error occured when the method was called");
                 trace(event.faultCode + ": " + event.faultDescription);
         }
}
```

Requirements on classes that should be used by the Wizarddecoder:
  * No parameters on construct
  * All server side members must be public (either by public var or with getters and setters)