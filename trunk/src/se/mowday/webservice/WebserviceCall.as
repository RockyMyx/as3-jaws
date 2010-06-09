package se.mowday.webservice 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.Timer;
	
	/**
	 * This class is used to store information about a
	 * specific call. It has information about
	 * what to do before, under and after the call
	 * is made. It's also here the lazy decoding takes
	 * place.
	 * @example
	 * The webservice call is automatically created within
	 * the webservice when you make a method call.
	 * As soon as the WebserviceCall object is created the
	 * correct properties are set and the the call is loaded.
	 * If an error occurs within the call the faultCode
	 * (HTTP Stats Code) is returned with a fault description.
	 * When the call is completed however this is also dispatched.
	 * It is dispatched from the call object, and then the Webservice
	 * class listens to this and handles it accordingly.
	 * <br><br><b>Lazy decoding</b><br>
	 * The lazy decoding of the response XML takes place automatically
	 * when you try to access the property decodedObject. If the object
	 * is not decoded it will decode it, however if it is already decoded
	 * it will just return the decoded object.
	 * @author Calle Mowday
	 */
	public class WebserviceCall extends EventDispatcher
	{
		private var _rawResponse:XML;
		private var _rawRequest:XML;
		
		private var _callback:Function;
		
		private var _responseDecleration:XML;
		
		private var _name:String;
		
		private var _decoder:WizardDecoder;
		
		private var _errorHandler:ErrorHandler;
		
		private var _decodedObject:*;
		
		private var _timeout:int = -1;
		private var _timeoutTimer:Timer;
		
		private var _urlLoader:URLLoader;
		private var _request:URLRequest;
		
		private var _complexTypes:Array;
		
		/**
		 * This class should only be created from within the Webservice class.
		 * @param	wsdlURL The URL to the Webservice
		 * @param	name The name of the method to be called
		 * @param	targetNamespace The targetnamespace the request should be in
		 * @param	requestXML The XML that is to be parsed by the server
		 * @see Webservice
		 */
		
		public function WebserviceCall(wsdlURL:String, name:String, targetNamespace:String, requestXML:XML, callback:Function = null) 
		{
			_urlLoader = new URLLoader();
			_errorHandler = new ErrorHandler(this);
			
			_callback = callback;
			
			_request = new URLRequest(wsdlURL);
			_request.method = "POST";
			_request.data = requestXML;
			
			//Skyddar mot buggen om namespacet inte har ett slash i slutet
			if (targetNamespace.charAt(targetNamespace.length -1) != "/")
				targetNamespace += "/";
			
			var headers:Array = new Array();
			headers.push(new URLRequestHeader("SOAPAction", targetNamespace + name));
			headers.push(new URLRequestHeader("Content-Type", "text/xml; charset=utf-8"));
			_request.requestHeaders = headers;
			
			_rawRequest = requestXML;
			
			_urlLoader.addEventListener(Event.COMPLETE, callComplete);
			_errorHandler.handle(_urlLoader);
		}
		
		/**
		 * Fires the call. As soon as the function is called
		 * the Webservice method is called.
		 */
		internal function load():void {
			_urlLoader.load(_request);
			
			if (_timeoutTimer != null)
				_timeoutTimer.start();
		}
		
		/**
		 * This function is used when the call was succesfull
		 * @param	event The event from the URLLoader
		 */
		private function callComplete(event:Event):void {
			_rawResponse = XML(_urlLoader.data);
				
			dispatchEvent(new WebserviceEvent(WebserviceEvent.RESPONSE, true, _name));
		}
		
		/**
		 * Closes the connection to server (if connected)
		 */
		public function close():void {
			_urlLoader.close();
		}
		
		/**
		 * The lazy decoded object. When this is called the raw response XML is parsed
		 * using the definition from the WSDL. From this an object is created with correctly
		 * casted values and objects on itself and it's childrens.
		 */
		public function get decodedObject():* {
			if (_decodedObject == null) {
				_decodedObject = _decoder.decode(_rawResponse, _responseDecleration, _name);
			}
			
			return _decodedObject;
		}
		
		/**
		 * The time (in ms) before the call should be timed out. To set this value, use
		 * getMethod on the webservice class to retrieve the method, then set the timout
		 * value on that object.
		 * @example <listing version="3.0">var method:WebserviceMethod = webservice.getMethod("HelloWorld");
		 * method.timeout = 1000; //1 second before timeout</listing>
		 * @see Webservice.getMethod
		 * @see WebserviceMethod
		 * @default -1
		 */
		public function get timeout():int { return _timeout; }
		
		public function set timeout(value:int):void 
		{
			_timeout = value;
			
			if (_timeout > 0) {
				if (_timeoutTimer == null) {
					_timeoutTimer = new Timer(_timeout);
					_timeoutTimer.addEventListener(TimerEvent.TIMER, timedOut, false, 0, true);
				}
				_timeoutTimer.delay = _timeout;
				
			} else {
				if (_timeoutTimer != null) {
					if (_timeoutTimer.running)
						_timeoutTimer.stop();
				}
			}
		}
		
		/**
		 * The decleration of the response XML
		 */
		public function get responseDecleration():XML { return _responseDecleration; }
		
		public function set responseDecleration(value:XML):void 
		{
			_responseDecleration = value;
		}
		
		/**
		 * Saves the array containg all the complex types definition XML:s
		 */
		internal function set complexTypes(value:Array):void 
		{
			if(_decoder != null)
				_decoder.insertComplexTypes(value.concat());
		}
		
		/**
		 * The name of the method that is called.
		 */
		public function get name():String { return _name; }
		
		public function set name(value:String):void 
		{
			_name = value;
		}
		
		/**
		 * The raw response in XML format
		 */
		public function get rawResponse():XML { return _rawResponse; }
		
		public function set rawResponse(value:XML):void 
		{
			_rawResponse = value;
		}
		
		/**
		 * The function that is to run when the call gets a response,
		 * successfull or not.
		 */
		internal function get callback():Function { return _callback; }
		
		public function get decoder():WizardDecoder { return _decoder; }
		
		public function set decoder(value:WizardDecoder):void 
		{
			_decoder = value;
		}
		
		/**
		 * Runs when the call timesout
		 * @param	event The event fired by the Timer
		 */
		private function timedOut(event:TimerEvent):void {
			close();
			_timeoutTimer.stop();
			
			var newEvent:WebserviceEvent = new WebserviceEvent(WebserviceEvent.RESPONSE, false, _name);
			newEvent.faultCode = 408;
			newEvent.faultDescription = "Client timedout (" + _timeout + " ms passed)";
			newEvent.faultObject = this;
			
			dispatchEvent(newEvent);
		}
		
	}
	
}

/**
 * Copyright 2008-2009 Carl Mowday. All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 * 
 *    1. Source code must retain the above copyright notice, this 
 * 			list of conditions and the following disclaimer.
 * 
 *    2. Redistributions in binary form must reproduce the above copyright notice, 
 * 			this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * 
 * 
 * THIS SOFTWARE IS PROVIDED BY CARL MOWDAY "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CARL MOWDAY OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */