package se.mowday.webservice 
{
	import flash.events.Event;
	
	/**
	 * WebserviceEvent class is used with all calls to the webserivce.
	 * It stores more information than a usual event to give the user
	 * a fast and simple way of accessing the relevent information about
	 * the call. This class is used despite if the call was successfull
	 * or not.
	 * 
	 * @example
	 * Depending on the responseMethod set on the webservice object
	 * the event typename differs. This is to allow the developer to
	 * use the event that suits him the most. If the responseMethod
	 * is set to Webservice.RESPONSE_METHOD_CONSTANT (Default) the
	 * typename of the event will be WebserviceEvent.RESPONSE.
	 * Therefore the listeners can be set like this:
	 * <listing version="3.0">webservice.addEventListener(WebserviceEvent.RESPONSE, eventHandlingFunction);</listing>
	 * The other way is to set the responseMethod to
	 * Webservice.RESPONSE_METHOD_NAME. In this mode the event typename
	 * will be the name of the module + "Response".
	 * For example if you are calling a method called HelloWorld the listener
	 * will be:
	 * <listing version="3.0">webservice.addEventListener("HelloWorldResponse", eventHandlingFunction);</listing>
	 * Either way you use the event object returned has a flag on it called
	 * success. This will tell you if the call was successfull or not.<br>
	 * On the event object there is also a property called response.
	 * Response is the lazy decoded object from the response. The lazy
	 * decoding dosn't start until you call for this property, but once you
	 * have decoded the answer, you won't have to do it again. It's kinda
	 * like a singelton.<br>
	 * If the response is a very very large one, the lazy decoding might not
	 * be the best way to access the response. This is because it takes time
	 * for the webservice class to decode the answer depending on the definition
	 * provided by the WSDL. Under the WebserviceCall object there is a property
	 * called rawResponse(XML). This is the raw response XML, undecoded. To reach
	 * it from the event object the following code may be used:
	 * <listing version="3.0">event.callObject.rawResponse;</listing>
	 * @see Webservice
	 * @see WebserviceCall
	 * @author Calle Mowday
	 */
	public class WebserviceEvent extends Event 
	{
		private var _faultCode:int;
		private var _faultDescription:String;
		private var _faultObject:*;
		
		private var _callObject:WebserviceCall;
		private var _response:*;
		private var _name:String;
		
		private var _success:Boolean;
		
		/**
		 * The typename given to the event if the
		 * responseMethod on the Webservice object is set to
		 * Webservice.RESPONSE_METHOD_CONSTANT (this is
		 * the default value of the responseMethod)
		 */
		public static const RESPONSE:String = "response_event";
		
		/**
		 * Creates a new WebserviceEvent with right name, and success flags
		 * @param	the name of the event, either RESPONSE or the methodname + "Response"
		 * @param	bubbles If the event should bubble
		 * @param	cancelable If the event is cancelable
		 * @see RESPONSE
		 */
		public function WebserviceEvent(type:String, success:Boolean, name:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			_success = success;
			_name = name;
		} 
		
		/**
		 * Creates an exakt clone of the event
		 * @return The clone
		 */
		public override function clone():Event 
		{ 
			var event:WebserviceEvent = new WebserviceEvent(type, _success, _name, bubbles, cancelable);
			event.callObject 		= _callObject;
			event.faultCode 		= _faultCode;
			event.faultDescription 	= _faultDescription;
			event.faultObject 		= _faultObject;
			return event;
		} 
		
		/**
		 * Used to easier write the events properties
		 * @return A string with the properties on the event
		 */
		public override function toString():String 
		{ 
			return formatToString("WebserviceEvent", "type", "success", "name",  "faultCode", "faultDescription"); 
		}
		
		/**
		 * HTTP Status code. This is 200 if the event went well.
		 */
		public function get faultCode():int { return _faultCode; }
		
		public function set faultCode(value:int):void 
		{
			_faultCode = value;
		}
		
		/**
		 * A description of the error that occured.
		 */
		public function get faultDescription():String { return _faultDescription; }
		
		public function set faultDescription(value:String):void 
		{
			_faultDescription = value;
		}
		
		/**
		 * The object that contains the information about the call
		 */
		public function get callObject():WebserviceCall { return _callObject; }
		
		public function set callObject(value:WebserviceCall):void 
		{
			_callObject = value;
		}
		
		/**
		 * The object that threw the error
		 */
		public function get faultObject():* { return _faultObject; }
		
		public function set faultObject(value:*):void 
		{
			_faultObject = value;
		}
		
		/**
		 * The lazy decoded response object. When this is called the
		 * response xml will be decoded by using the decleration of
		 * the WSDL. This can take som time on very large responses,
		 * and you should then access the raw XML instead (see the
		 * example above)
		 * @see WebserviceEvent
		 */
		public function get response():* { return _callObject.decodedObject; }
		
		/**
		 * A flag that says if the call was successfull(true) or not (false)
		 */
		public function get success():Boolean { return _success; }
		
		/**
		 * The name of the method that was called. If the sender has
		 * to do with the WSDL the name will be "Unkown".
		 */
		public function get name():String { return _name; }
		
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