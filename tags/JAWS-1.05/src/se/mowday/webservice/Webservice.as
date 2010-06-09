package se.mowday.webservice 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	/**
	 * The Webservice class is used to easily communicate with
	 * a webservice.
	 * @version 1.04
	 * @example In the following examples we have a webservice located at
	 * http://www.exampleurl.com/service.asmx. The webservice contains
	 * following methods:
	 * <listing version="3.0">
	 * HelloWorld():String
	 * HelloName(name:String):String
	 * getUser():User
	 * insertUser(newUser:User):void</listing>
	 * The class User looks like this:
	 * <listing version="3.0">
	 * username:String
	 * password:String
	 * desciple:User</listing>
	 * 
	 * <br><br><b>Create the object</b><br>
	 * First of all we need to create a new webservice object, connected to
	 * the URL above (http://www.exampleurl.com/service.asmx). The following
	 * code does this:
	 * 
	 * <listing version="3.0">
	 * var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * </listing>
	 * 
	 * There we go, easy huh!? But for now, it doesn't do anything. The webservice
	 * class is built to not do anything until has to. Everything is on-demand. Not even the WSDL
	 * is downloaded until it has to (unless you want it to).
	 * If you want to force the class to download and parse the WSDL you run the
	 * downloadWSDL function:
	 * 
	 * <listing version="3.0">
	 * var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * webservice.downloadWSDL();
	 * </listing>
	 * I just wanted to show how to do this, we are not going to use ourselves in this example.
	 * 
	 * 
	 * <br><br><b>Run a parameterless method</b><br>
	 * To run a method there are 2 alternatives. The first one is to run the makeCall function.
	 * This functions returns an integer flagging how the call went. This response is also
	 * declared as constants on the Webservice class. If we want to run the HelloWorld method
	 * the code beneth will do exactly this:
	 * 
	 * <listing version="3.0">
	 * var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * webservice.makeCall("HelloWorld");
	 * </listing>
	 * 
	 * <br>The other way to run a method is to use the fact that Webservice is a proxy,
	 * wich means you can run the methods direclty on the object. Like this:
	 * 
	 * <listing version="3.0">
	 * var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * webservice.HelloWorld();
	 * </listing>
	 * 
	 * Both methods works exaclty the same. If the WSDL is not loaded when the method is called,
	 * the call is queued and then fired as soon as it is possible.
	 * 
	 * 
	 * <br><br><b>Run a method with parameters</b><br>
	 * To run a method that requires parameters, you have the same choice of method to run it.
	 * The first method, makeCall, takes all the rest parameters as parameters to run.
	 * If we take HelloName as example, the code under will run the method and use "Calle" as
	 * parameter:
	 * 
	 * <listing version="3.0">
	 * var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * webservice.makeCall("HelloName", "Calle");
	 * </listing>
	 * 
	 * And for the proxy version it's even easier!
	 * 
	 * <listing version="3.0">
	 * var webservice:Webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * webservice.HelloName("Calle");
	 * </listing>
	 * 
	 * 
	 * <br><br><b>Handling the response</b><br>
	 * The response from the server doesn't come directly. An event is fired asynchronicle
	 * as soon as it's possible. Because of this you have to set listeners to the Webservice object.
	 * The code beneth creates a new webservice object, and then listens to the response and
	 * traces it depending on if it went well or not:
	 * 
	 * <listing version="3.0">
	 * private var webservice:Webservice;
	 * public function init():void {
	 * 		webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * 		webservice.addEventListener(WebserviceEvent.RESPONSE, onResponse);
	 * }
	 * private function onResponse(event:WebserviceEvent):void {
	 * 		if(event.success) {
	 * 			trace("The call went well!");
	 * 		} else {
	 * 			trace("An error occured when the method was called");
	 * 			trace(event.faultCode + ": " + event.faultDescription);
	 * 		}
	 * }
	 * </listing>
	 * The following code will run the HelloWorld method and the trace out the
	 * response ("Hello World")
	 * 
	 * <listing version="3.0">
	 * private var webservice:Webservice;
	 * public function init():void {
	 * 		webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * 		webservice.addEventListener(WebserviceEvent.RESPONSE, onResponse);
	 * 		webservice.HelloWorld();
	 * }
	 * private function onResponse(event:WebserviceEvent):void {
	 * 		if(event.success) {
	 * 			trace(event.response); //HelloWorld
	 * 		} else {
	 * 			trace("An error occured when the method was called");
	 * 			trace(event.faultCode + ": " + event.faultDescription);
	 * 		}
	 * }
	 * </listing>
	 * 
	 * <br><br><b>Running a method with a callback function</b><br>
	 * The other way to handle the response is to use a callback function.
	 * Both methods works almost the same. The reason for the both to be here is to provide
	 * a wide variety of ways to handle the response to best suite the need
	 * and style of the developer.<br>
	 * The function that handles the response must have two parameters,
	 * success(Boolean) and returnObject(Object). The names can of course
	 * be changed, but there need to be one bool and one object.
	 * The bool specifies if the call went well, and the object is the
	 * returned object from the server (lazydecoded). When using this method
	 * all responses are lazydecoded.
	 * To make a call and handle the event with a function the code below can be used:
	 * 
	 * <listing version="3.0">
	 * private var webservice:Webservice;
	 * public function init():void {
	 * 		webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * 		webservice.makeCallWithCallback("HelloWorld", helloWorldResponse);
	 * }
	 * private function helloWorldResponse(success:Boolean, returnObject:Object):void {
	 * 		trace(success + ": " + returnObject);
	 * }
	 * </listing>
	 * 
	 * 
	 * <br><br><b>Complex types</b><br>
	 * Sometimes you will have to deal with complex types.
	 * Complex types are objects that aint simple (DUH!?),
	 * wich means other than string, numbers and booleans.
	 * Theese are defined in the WSDL and the developer doesn't need
	 * to worry about this. In this example we have a complex type,
	 * the User object. In this example we are going to create a
	 * new User, fill in the username and password and then send
	 * the object to the server using the webservice method insertUser.
	 * 
	 * <listing version="3.0">
	 * private var webservice:Webservice;
	 * public function init():void {
	 * 		webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * 
	 * 		var user:Object = new Object();
	 * 		user.username = "Calle";
	 * 		user.password = "foo";
	 * 
	 * 		webservice.insertUser(user);
	 * }
	 * </listing>
	 * 
	 * Easy isn't it? Next we will add so we first insert the user, then
	 * get all users and show the information about theese:
	 * 
	 * <listing version="3.0">
	 * private var webservice:Webservice;
	 * public function init():void {
	 * 		webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * 		webservice.addEventListener(WebserviceEvent.RESPONSE, onResponse);
	 * 
	 * 		var user:Object = new Object();
	 * 		user.username = "Calle";
	 * 		user.password = "foo";
	 * 
	 * 		webservice.insertUser(user);
	 * 		webservice.getUser();
	 * }
	 * private function onResponse(event:WebserviceEvent):void {
	 * 		if(event.success) {
	 * 			trace(event.name); //getUser
	 * 			trace(event.response.username); //Calle
	 * 			trace(event.response.password); //foo
	 * 			trace(event.response.desciple); //null
	 * 			if(desciple != null) {
	 * 				trace(event.response.desciple.username);
	 * 				trace(event.response.desciple.password);
	 * 				trace(event.response.desciple.desciple);
	 * 			}
	 * 		} else {
	 * 			trace("An error occured when the method was called");
	 * 			trace(event.faultCode + ": " + event.faultDescription);
	 * 		}
	 * }
	 * </listing>
	 * 
	 * Great! Now then, lets try even more complex types, lets add a desciple to the
	 * user we insert:
	 * 
	 * <listing version="3.0">
	 * private var webservice:Webservice;
	 * public function init():void {
	 * 		webservice = new Webservice("http://www.exampleurl.com/service.asmx");
	 * 		webservice.addEventListener(WebserviceEvent.RESPONSE, onResponse);
	 * 
	 * 		var user:Object = new Object();
	 * 		user.username = "Calle";
	 * 		user.password = "foo";
	 * 
	 * 		var user2:Object = new Object();
	 * 		user2.username = "Yoda"; //HAHA
	 * 		user2.password = "foo2";
	 * 
	 * 		user.desciple = user2; //Yoda becomes Calles desciple, splendid!
	 * 
	 * 		webservice.insertUser(user);
	 * 		webservice.getUser();
	 * }
	 * private function onResponse(event:WebserviceEvent):void {
	 * 		if(event.success) {
	 * 			trace(event.name); //getUser
	 * 			trace(event.response.username); //Calle
	 * 			trace(event.response.password); //foo
	 * 			trace(event.response.desciple); //[Object object]
	 * 			if(desciple != null) {
	 * 				trace(event.response.desciple.username); //Yoda
	 * 				trace(event.response.desciple.password); //foo2
	 * 				trace(event.response.desciple.desciple); //null
	 * 			}
	 * 		} else {
	 * 			trace("An error occured when the method was called");
	 * 			trace(event.faultCode + ": " + event.faultDescription);
	 * 		}
	 * }
	 * </listing>
	 * 
	 * The objects can have as many sublevels as they want, the only
	 * thing that is crucial is that the types are defined by the WSDL,
	 * wich means they need to be defined by the Webservice. As long as
	 * there are classes on the server side that can define how the objects
	 * should look, wich variables they should have and what types thees
	 * should be the complexity of an object is endless!
	 * 
	 * @see WebserviceEvent
	 * @author Calle Mowday
	 */
	public dynamic class Webservice extends Proxy implements IEventDispatcher
	{
		private var _envelopeHeader:XML;
		private var _methods:Array;
		private var _availableMethods:Array;
		private var _wsdl:WSDL;
		
		private var _wsdlURL:String;
		
		private var _eventDispatcher:EventDispatcher;
		
		private var _methodQueue:Array;
		private var _headerQueue:Array;
		private var _controlRestrictions:Boolean = false;
		
		private var _responseMethod:String = RESPONSE_METHOD_CONSTANT;
		
		/**
		 * If the responseMethod is set to this, the event
		 * type name will be method name + "Response".
		 * @see WebserviceEvent
		 */
		public static const RESPONSE_METHOD_NAME:String		= "response_name";
		/**
		 * If responseMethod is set to this, the event type
		 * name will be WebserviceEvent.RESPONSE
		 * @see WebserviceEvent.RESPONSE
		 */
		public static const RESPONSE_METHOD_CONSTANT:String	= "response_constant";
		
		/**
		 * WSDL URL should be the url to the root .asmx. It should not include
		 * "?WSDL", although if it does it will be stripped away.
		 * @param	wsdlURL URL:en till den webservice som ska anropas
		 */
		public function Webservice(wsdlURL:String)
		{
			_eventDispatcher = new EventDispatcher(this);
			
			_methods		= new Array();
			_methodQueue	= new Array();
			_headerQueue	= new Array();
			
			//Removes the ending ?WSDL if it was inputted
			_wsdlURL		= wsdlURL.substr(wsdlURL.length - 5) == "?WSDL" ? wsdlURL.substring(0, wsdlURL.length - 5) : wsdlURL;
			
			//Creates a new WSDL handler and points it to the URL
			_wsdl = new WSDL(_wsdlURL);
			_wsdl.addEventListener(Event.COMPLETE, wsdlInserted);
			_wsdl.addEventListener(WebserviceEvent.RESPONSE, handleDataEvent);
			
			_wsdl.decoder = new WizardDecoder();
		}
		
		/**
		 * Runs a method. If the WSDL is not loaded, the call is queued and then
		 * it runs again when the WSDL is ready. Therefore you can start running
		 * functions directly, no need to wait for the WSDL to load.
		 * @param	methodName The name of the method you want to run
		 * @param	...parameters The rest is all the parameters you want to
		 * insert when calling the method.
		 * @return The call object that was made, or null if it wasn't found or
		 * was queued.
		 */
		public function makeCall(methodName:String, ...params):WebserviceCall {
			return makeCallCore(methodName, null, params);
		}
		/**
		 * The core function that actually makes the callobject.
		 * This is private because the other functions wrap this
		 * and insert the parameters they need.
		 * @param	methodName The name of the method to run
		 * @param	callback The function to run when completer
		 * @param	parameters The parameters to pass
		 * @return
		 */
		private function makeCallCore(methodName:String, callback:Function=null, parameters:Array=null):WebserviceCall {
			//Creates an empty array if none was submitted
			if (parameters == null)
				parameters = new Array();
			
			if (_wsdl.ready) {
				
				//Check to see that there really is a method called this
				if (methodExists(methodName)) {
					
					//Gets the method and makes a call
					var method:WebserviceMethod = getMethod(methodName);
					var call:WebserviceCall = method.call(parameters, callback);
					
					//Sets the listeners to the call object
					if(callback == null) {
						
						call.addEventListener(WebserviceEvent.RESPONSE, handleDataEvent);
					
					} else {
						
						call.addEventListener(WebserviceEvent.RESPONSE, runCallback);
						
					}
					
					
					return call;
					
				} else {
					//If the method was not found, create an error object and dispatch it
					var newEvent:WebserviceEvent = new WebserviceEvent(WebserviceEvent.RESPONSE, false, methodName);
					newEvent.faultCode = 501;
					newEvent.faultDescription = "Method not found";
					
					dispatchEvent(newEvent);
					
					return null;
				}
				
			} else {
				//If the WSDL is not ready, queue this method
				var saveArray:Array = new Array();
				saveArray.push(methodName);
				saveArray.push(callback);
				saveArray.push(parameters);
				_methodQueue.push( { argumentArray: saveArray } );
				
				if (!_wsdl.downloading)
					_wsdl.downloadWSDL();
				
				return null;
			}
		}
		
		/**
		 * Runs a method on the webservice, and then runs a function in flash
		 * instead of firing an event.
		 * @param	methodName The name of the method to run
		 * @param	callback The function to run on completion
		 * @param	...params The rest are the parameters to run
		 */
		public function makeCallWithCallback(methodName:String, callback:Function, ...params):void {
			var call:WebserviceCall = makeCallCore(methodName, callback, params);
		}
		
		/**
		 * Runs the callback function after a call has got an answer,
		 * successfull or not
		 * @param	event The event fired by the WebserviceCall objecct
		 */
		private function runCallback(event:WebserviceEvent):void {
			var call:WebserviceCall = WebserviceCall(event.target);
			var returnObject:Object;
			
			if (event.success) {
				returnObject = call.decodedObject;
			} else {
				returnObject = new Object();
				returnObject.faultCode = event.faultCode;
				returnObject.faultDescription = event.faultDescription;
			}
			
			call.callback.call(call, event.success, returnObject);
		}
		
		/**
		 * Allows the developer to manually insert the WSDL XML.
		 * @param	wsdl The XML
		 */
		public function insertWSDL(wsdl:XML):void {
			_wsdl.insertWSDL(wsdl);
		}
		
		/**
		 * Returns the decoder object
		 * @return Wizard decoder
		 * @see WizardDecoder
		 */
		public function getDecoder():WizardDecoder
		{
			return _wsdl.decoder;
		}
		
		/**
		 * Handles the responses from the calls
		 * @param	event The event fired by the call object
		 * @see WebserviceCall
		 */
		private function handleDataEvent(event:WebserviceEvent):void {
			
			//The name of the event is based on what constant is set to the response method
			var typNamn:String = _responseMethod == RESPONSE_METHOD_CONSTANT ? WebserviceEvent.RESPONSE : event.name + "Response";
			var newEvent:WebserviceEvent;
			
			if (event.success) {
				
				newEvent = new WebserviceEvent(typNamn, true, event.name);
				newEvent.callObject = WebserviceCall(event.target);
				newEvent.faultCode = 200;
				
			} else {
				
				newEvent = new WebserviceEvent(typNamn, false, event.name);
				newEvent.faultObject = event.faultObject;
				newEvent.faultCode = event.faultCode;
				newEvent.faultDescription = event.faultDescription;
				
			}
			
			dispatchEvent(newEvent);
			
		}
		
		/**
		 * Requests a certain method object. If the method doesn't
		 * exist, an error is thrown.
		 * @param	methodName The name of the method you want to get
		 * @return The WebserviceMethod object
		 * @see WebserviceMethod
		 */
		internal function getMethod(methodName:String):WebserviceMethod {
			//Checks to see that this method actually exists
			if (methodExists(methodName)) {
				
				//Loops the methods that have already been created and tries to find the right one
				for each (var method:WebserviceMethod in _methods) 
				{
					
					if (method.name == methodName)
						return method;
						
				}
				
				//If the method was not found in the list, create it and put it in the list
				var newMethod:WebserviceMethod = _wsdl.createMetod(methodName);
				_methods.push(newMethod);
				newMethod.envelopeHeader		= envelopeHeader;
				newMethod.controlRestrictions	= _controlRestrictions;
				
				
				return newMethod;
				
			} else {
				//If the method was not found, throw an error
				throw new Error("Method not found!", 501);
				
			}
			
		}
		
		/**
		 * Returns true or false depending on if the method
		 * exists in the WSDL decleration or not. If the
		 * WSDL is not loaded or not parsed, this will
		 * always return false!!!
		 * @param	methodName The methodname to check
		 * @return true if it exists, otherwise false
		 */
		public function methodExists(methodName:String):Boolean {
			
			//Loops through all the methodnames derieved from the WSDL
			//and tries to find one with a matching name
			for each (var method:String in _availableMethods) 
			{
				
				if (method == methodName)
					return true;
					
			}
			
			return false;
		
		}
		
		/**
		 * Set a header on a specific method. If the WSDL
		 * is not loaded, this is then queued and runs
		 * automaticaly when it is ready.
		 * @param	methodName The name of the method to
		 * set the header on
		 * @param	header The header to set
		 */
		public function setHeader(methodName:String, header:XML):void {
			if (_wsdl.ready) {
				getMethod(methodName).envelopeHeader = header;
			} else {
				_headerQueue.push( { argumentArray: [methodName, header] } );
			}
		}
		
		/**
		 * Runs when the WSDL has been inserted.
		 * @param	event The event fired by the WSDL
		 */
		private function wsdlInserted(event:Event):void {
			_availableMethods = _wsdl.getMethods();
			var queuedObject:Object;
				
			//purge header queue
			for each (queuedObject in _headerQueue) 
				setHeader.apply(this, queuedObject.argumentArray);
			
			//purge method queue
			for each (queuedObject in _methodQueue) 
				makeCallCore.apply(this, queuedObject.argumentArray);
			
			_methodQueue	= new Array();
			_headerQueue	= new Array();
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 * The method that allows us to capture all
		 * functions that has not been declared here.
		 * Theese should be methods on the Webservice.
		 * @private
		 */
		override flash_proxy function callProperty(name:*, ...rest):* 
		{
			if (rest == null)
				rest = [];
			rest.unshift(name);
			
			return makeCall.apply(this, rest);
		}
		
		/* INTERFACE flash.events.IEventDispatcher */
		
		/**
		 * Implements the IEventDispatcher interface
		 * @private
		 */
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			_eventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		/**
		 * Implements the IEventDispatcher interface
		 * @private
		 */
		public function dispatchEvent(event:Event):Boolean
		{
			return _eventDispatcher.dispatchEvent(event);
		}
		
		/**
		 * Implements the IEventDispatcher interface
		 * @private
		 */
		public function hasEventListener(type:String):Boolean
		{
			return _eventDispatcher.hasEventListener(type);
		}
		
		/**
		 * Implements the IEventDispatcher interface
		 * @private
		 */
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			_eventDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		/**
		 * Implements the IEventDispatcher interface
		 * @private
		 */
		public function willTrigger(type:String):Boolean
		{
			return _eventDispatcher.willTrigger(type);
		}
		
		/**
		 * Sets the SOAP header used by all the calls to the server.
		 * @example If the Webservice expects a header called
		 * UserHeader that contains the username and password of the
		 * user, we would set that like this:
		 * <listing version="3.0">
		 * var webservice:Webservice = new Webservice("http://tempurl.com/service.asmx");
		 * webservice.envelopeHeader(&lt;UserHeader&gt;&lt;username&gt;Calle&lt;/username&gt;&lt;password&gt;lol&lt;/password&gt;&lt;/UserHeader&gt;);
		 * </listing>
		 */
		public function get envelopeHeader():XML { return _envelopeHeader; }
		
		public function set envelopeHeader(value:XML):void 
		{
			_envelopeHeader = value;			
			
			for each (var method:String in _availableMethods) {
				getMethod(method).envelopeHeader = value;
			}
				
				
		}
		
		/**
		 * Whether or not the WSDL is ready (loaded and parsed)
		 */
		public function get wsdlReady():Boolean {
			return _wsdl.ready;
		}
		
		public function get wsdl():XML {
			return _wsdl.rawWSDL;
		}
		
		/**
		 * Returns the method names (strings) avaliable in
		 * webservice.
		 */
		public function get availableMethods():Array { return _availableMethods; }
		
		/**
		 * What method to use when sending an event about the calls
		 * or WSDL.<br>
		 * For more information see WebserviceEvent!
		 * @see WebserviceEvent
		 * @see RESPONSE_METHOD_NAME
		 * @see RESPONSE_METHOD_CONSTANT
		 * @see WebserviceEvent.RESPONSE
		 */
		public function get responseMethod():String { return _responseMethod; }
		
		public function set responseMethod(value:String):void 
		{
			if(_responseMethod == RESPONSE_METHOD_CONSTANT || _responseMethod == RESPONSE_METHOD_NAME)
				_responseMethod = value;
			else
				throw new Error("The response method must be set to either the RESPONSE_METHOD_CONSTANT or RESPONSE_METHOD_NAME");
		}
		
		/**
		 * Starts the downloading of the WSDL if it's not
		 * already downloading or ready.
		 */
		public function downloadWSDL():void {
			if (!_wsdl.ready && !_wsdl.downloading)
				_wsdl.downloadWSDL();
		}
		
		/**
		 * Sets a timeout on alla available methods.
		 */
		public function set timeout(value:int):void {
			for each (var methodName:String in availableMethods) 
			{
				getMethod(methodName).timeout = value;
			}
		}
		
		/**
		 * If this is set to true, and a simple element has restrictions on what the
		 * value can be set to, the value that is inserted is checked. If it is valid,
		 * the request is sent. If it is invalid an error is thrown.
		 */
		public function get controlRestrictions():Boolean { return _controlRestrictions; }
		
		public function set controlRestrictions(value:Boolean):void 
		{
			_controlRestrictions = value;
			for each (var methodName:String in availableMethods) 
			{
				getMethod(methodName).controlRestrictions = value;
			}
		}
	}
}

/**
 * Copyright (c) 2008-2010, Carl Mowday
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the 
 * 			documentation and/or other materials provided with the distribution.
 *   * Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to endorse or promote products derived from this 
 * 			software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */