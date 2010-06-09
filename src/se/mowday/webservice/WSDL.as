package se.mowday.webservice 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	/**
	 * The class that handles the WSDL.
	 * If the WSDL class dosen't get the WSDL inserted by
	 * the user, by the time a method is called, the WSDL
	 * will be downloaded from here. After the download is
	 * complete OR a WSDL has been inserted by the user,
	 * the WSDL XML will be parsed through for easy access
	 * of the methods and attributes of the Webservice.
	 * @author Calle Mowday
	 */
	internal class WSDL extends EventDispatcher
	{
		private var _wsdlURL:String;
		
		private var _ready:Boolean = false;
		private var _downloading:Boolean = false;
		
		private var _rawWSDL:XML;
		private var _decoder:WizardDecoder;
		
		private var _complexTypes:Array;
		
		private var _downloader:URLLoader;
		private var _errorHandler:ErrorHandler;
		
		/**
		 * This class should only be instantiated
		 * from the Webservice class.
		 * @param	wsdlURL The URL to the webservice
		 */
		public function WSDL(wsdlURL:String) 
		{
			_wsdlURL = wsdlURL;
			_errorHandler = new ErrorHandler(this);
		}
		
		/**
		 * Inserts a WSDL XML and starts parsing it
		 * @param	wsdl The WSDL XML downloaded from the server
		 */
		public function insertWSDL(wsdl:XML):void {
			_rawWSDL = wsdl;
			_complexTypes = null;
			
			_ready = true;
			
			if(_decoder != null)
				_decoder.insertComplexTypes(complexTypes);
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 * Starts downloading a WSDL from the URL inserted
		 * earlier in the construct.
		 */
		public function downloadWSDL():void {
			_downloader = new URLLoader();
			
			_downloader.addEventListener(Event.COMPLETE, wsdlDownloaded);
			_errorHandler.handle(_downloader);
			
			_downloader.load( new URLRequest(_wsdlURL + "?WSDL") );
			
			_downloading = true;
		}
		
		/**
		 * Runs when WSDL has been downloaded from the server.
		 * @param	event The event fired by the URLLoader
		 */
		private function wsdlDownloaded(event:Event):void {
			var data:String = _downloader.data;
			
			if (data.indexOf("<") != 0)
			{
				data = data.substr(data.indexOf("<"), data.length);
			}
			
			if (data.lastIndexOf(">") != data.length - 1)
			{
				data = data.substr(0, data.lastIndexOf(">") + 1);
			}
			
			insertWSDL( XML(data) );
		}
		
		/**
		 * Creates a new WebserviceMethod object based on the WSDL.
		 * @param	methodName The name of the method to be created
		 * @return A method with all the correct attributes inserted
		 * @see WebserviceMethod
		 */
		public function createMetod(methodName:String):WebserviceMethod {
			var requestXML:XML = getRequestXML(methodName);
			var responseXML:XML = getResponseXML(methodName);
			
			var method:WebserviceMethod = new WebserviceMethod(methodName, _wsdlURL, requestXML, responseXML);
			method.complexTypes = complexTypes;
			
			method.decoder = _decoder;
			
			return method;
		}
		
		/**
		 * Creates and returns an array of complex type
		 * definitions.
		 * @return An array of compelx types
		 */
		private function getComplexTypes():Array {
			var tempArr:Array = new Array();
			
			var wsdl:Namespace = _rawWSDL.namespace("wsdl");
			var s:Namespace = _rawWSDL.namespace("s");
			
			var types:XMLList = _rawWSDL.wsdl::types;
			var schema:XMLList = types.s::schema;
			var complexTypes:XMLList = schema.s::complexType;
			
			for each (var complexType:XML in complexTypes) 
			{
				tempArr.push(complexType);
			}
			
			var simpleTypes:XMLList = schema.s::simpleType;
			
			for each (var simpleType:XML in simpleTypes) 
			{
				tempArr.push(simpleType);
			}
			
			return tempArr.concat();
		}
		
		/*********************[ GETTERS AND SETTERS ]*********************/
		
		/**
		 * If the WSDL is ready or not
		 * @default false
		 */
		public function get ready():Boolean { return _ready; }
		
		/**
		 * Returns the array of complex type definitions
		 */
		public function get complexTypes():Array {
			if (_complexTypes == null)
				_complexTypes = getComplexTypes();
				
			return _complexTypes;
		}
		
		/**
		 * If the WSDL is downloading right now
		 * @default false
		 */
		public function get downloading():Boolean { return _downloading; }
		
		public function get decoder():WizardDecoder { return _decoder; }
		
		public function set decoder(value:WizardDecoder):void 
		{
			_decoder = value;
		}
		
		/**
		 * The raw WSDL XMl
		 */
		public function get rawWSDL():XML { return _rawWSDL; }
		
		/*********************[ WEBSERVICE RELATERADE FUNKTIONER ]*********************/
		/**
		 * Returns an array of strings with method available
		 * in the WSDL.
		 * @return
		 */
		public function getMethods():Array {
			var wsdl : Namespace = _rawWSDL.namespace("wsdl");
			var portType : XMLList = _rawWSDL.wsdl::portType;
			
			//Hämtar endast portType med ett namn som slutar med "Soap". Alla andra är ointressanta
			for each (var port:XML in portType) 
			{
				if (new RegExp("Soap$").test(port.@name))
					break;
			}
			
			
			var operations : XMLList = port.wsdl::operation;
			
			var methodArray : Array = new Array();
			
			for each (var operation : XML in operations) 
			{
				methodArray.push(operation.@name);
			}
			
			return methodArray;
		}
		
		/**
		 * Finds and returns the XML to define how the
		 * request should be built up
		 * @param	methodName The name of the method
		 * @return The definition of the request
		 */
		public function getRequestXML(methodName:String):XML {
			
			var s : Namespace = _rawWSDL.namespace("s");
			var wsdl : Namespace = _rawWSDL.namespace("wsdl");
			
			var types:XMLList = _rawWSDL.wsdl::types;
			
			var schema : XMLList = types.s::schema;
			var elements : XMLList = schema.s::element;
			
			//Looping every element looking for the right one
			
			for each (var element:XML in elements) 
			{
				if (element.@name == methodName) {
					return element;
				}
			}
			
			throw new Error("Method not found");
		}
		
		/**
		 * The same thing as getRequestXML but this adds
		 * "Response" at the end, which returns the response
		 * definition instead.
		 * @param	methodName The name of the method
		 * @return The definition of this methods response
		 */
		public function getResponseXML(methodName:String):XML {
			methodName += "Response";
			return getRequestXML(methodName);
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