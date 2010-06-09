package se.mowday.webservice 
{
	import adobe.utils.CustomActions;
	import flash.events.EventDispatcher;
	
	/**
	 * The  method constructor. It holds information about the
	 * webservice method, and it's this class that creates the
	 * call objects. This is an internal class because there is
	 * no need to access this from the outside. It completely
	 * handles itself.
	 * @see WebserviceCall
	 * @author Calle Mowday
	 */
	internal class WebserviceMethod extends EventDispatcher
	{
		private var _name:String;
		private var _wsdlURL:String;
		
		private var _requestXML:XML;
		private var _responseXML:XML;
		private var _complexTypes:Array;
		private var _controlRestrictions:Boolean = false;
		
		private var _decoder:WizardDecoder;
		
		private var _timeout:int = -1;
		
		private var _envelopeHeader:XML;
		
		/**
		 * The WebserviceMethod is intended only to be created by the WSDL!!!
		 * @param	name The name of the method
		 * @param	wsdlURL The URL to the webservice
		 * @param	requestXML The XML that defines how the request should look like
		 * @param	responseXML The XML that defines how the response looks like
		 */
		public function WebserviceMethod(name:String, wsdlURL:String, requestXML:XML, responseXML:XML) 
		{
			_name = name;
			_wsdlURL = wsdlURL;
			_requestXML = requestXML;
			_responseXML = responseXML;
		}
		
		/**
		 * Creates a new WebserviceCall depending on the parameters and
		 * returns it
		 * @param	parameters The parameters to use
		 * @return The new WebserviceCall
		 * @see WebserviceCall
		 */
		public function call(parameters:Array, callback:Function = null):WebserviceCall {
			var xmlString:String = '<?xml version="1.0" encoding="utf-8"?>';
			xmlString += '<soap:Envelope' + createNamespaceDeclerations() + '>';
			xmlString += createHeader();
			xmlString += createBody(parameters);
			xmlString += '</soap:Envelope>';
			
			
			var call:WebserviceCall = new WebserviceCall(_wsdlURL, _name, _requestXML.namespace("tns"), XML(xmlString), callback);
			
			if (_decoder != null)
				call.decoder = _decoder;
			
			call.timeout = _timeout;
			call.responseDecleration = XML(_responseXML.toXMLString());
			call.complexTypes = _complexTypes;
			call.name = _name;
			call.load();
			
			return call;
		}
		
		/**
		 * Creates a string with the namespace declerations in it
		 * @return Namespace declerations as a string
		 */
		private function createNamespaceDeclerations():String {
			//TODO: Ok att vara hårdkodad eller hämta?
			var tempString:String = ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"';
			return tempString;
		}
		
		/**
		 * Creates the body depending on the request definition XML
		 * and the parameters.
		 * @param	parameters The parameters to use
		 * @return The XML string.
		 */
		private function createBody(parameters:Array):String {
			var tempString:String = '<soap:Body>';
			tempString += '<' + _name + ' xmlns="' + _requestXML.namespace("tns").uri + '">';
			
			tempString += formBody(_requestXML, parameters);
			
			tempString += '</' + _name + '>';
			tempString += '</soap:Body>';
			
			return tempString;
		}
		
		/**
		 * Creates the innerpart of the body
		 * @param	The XML that describes the specific
		 * element type we are using in this request
		 * @param	parameters The parameters to send
		 * @return XML String
		 */
		private function formBody(elementXML:XML, parameters:Array):String {
			var s:Namespace = elementXML.namespace("s");
			
			var complexType:XMLList = elementXML.s::complexType;
			var sequence:XMLList = complexType.s::sequence;
			var elements:XMLList = sequence.s::element;
			
			var tempString:String = "";
			var iterator:int = 0;
			
			for each (var element:XML in elements) 
			{
				if (element.@type.split(":")[0] != "tns") {
					//Simple type
					tempString += "<" + element.@name + ">";
					tempString += parameters[iterator];
					tempString += "</" + element.@name + ">";
				} else {
					//Complex Type
					
					if (element.@type.indexOf("ArrayOf") != -1) {
							
						tempString += "<" + element.@name + ">";
						tempString += createArray(element.@type.split(":")[1], parameters[iterator]);
						tempString += "</" + element.@name + ">";
						
					} else {
						//Complex type
						tempString += "<" + element.@name + ">";
						tempString += serializeComplexType(element.@type.split(":")[1], parameters[iterator]);
						tempString += "</" + element.@name + ">";
					
					}
						
				}
				
				iterator++;
			}
			
			return tempString;
		}
		
		/**
		 * Takes any object and serialzises it based on the
		 * definition of the complex type in the WSDL.
		 * @param	complexNamespace The name of the complex Type
		 * @param	object The object to grab the values from
		 * @return XML String
		 */
		private function serializeComplexType(complexTypesName:String, object:*):String {
			var objectXML:XML = findComplexType(complexTypesName);
			var tempString:String = "";
			
			var s:Namespace = _requestXML.namespace("s");
			
			switch(objectXML.localName())
			{
				//Checks if it is as complex type
				case "complexType":
					var sequence:XMLList = objectXML.s::sequence;
					var elements:XMLList = sequence.s::element;
					for each (var element:XML in elements) 
					{
						if (object[element.@name] != null)
						{
							if (element.@type.split(":")[0] != "tns")
							{
								//Simple type
								tempString += "<" + element.@name + ">";
								tempString += object[element.@name];
								tempString += "</" + element.@name + ">";
							}
							else
							{
								
								if (element.@type.indexOf("ArrayOf") != -1)
								{
									
									tempString += "<" + element.@name + ">";
									tempString += createArray(element.@type.split(":")[1], object[element.@name]);
									tempString += "</" + element.@name + ">";
									
								}
								else
								{
								
									//Complex type
									tempString += "<" + element.@name + ">";
									tempString += serializeComplexType(element.@type.split(":")[1], object[element.@name]);
									tempString += "</" + element.@name + ">";
								
								}
								
							}
						}
					}
				break;
				
				//Or a simple type with restrictions
				case "simpleType":
					if(_controlRestrictions) {
						var restrictions:XMLList = objectXML.s::restriction;
						var enumerations:XMLList = restrictions.s::enumeration;
						var validValue:Boolean = false;
						
						//Check if calue is valid
						for each (var enumerationElement:XML in enumerations) 
						{
							if (String(enumerationElement.@value) == String(object))
							{
								validValue = true;
							}
						}
						
						//If it is valid, return string, otherwise cast exception
						if (validValue)
						{
							return String(object);
						}
						else
						{
							throw new Error(String(object) + " is not a valid value for the element " + complexTypesName);
						}
					}
					else
					{
						return String(object);
					}
					
				break;
				
				default:
					throw new Error("Unkown type of the element " + complexTypesName);
				break;
			}
			
			
			return tempString;
		}
		
		//Liknande den som finns i dekodern!
		private function createArray(elementType:String, object:Array):String {
			var objectXML:XML = findComplexType(elementType);
			var tempString:String = "";
			trace(objectXML);
			
			var s:Namespace = _requestXML.namespace("s");
			
			var sequence:XMLList = objectXML.s::sequence;
			var elements:XMLList = sequence.s::element;
			var element:XML = elements[0];
			var i:int;
			
			var iterator:int = object.length;
			
				if (element.@type.split(":")[0] != "tns") {
					for (i = 0; i < iterator; i++) 
					{
						tempString += "<" + element.@name + ">";
						tempString += object[i];
						tempString += "</" + element.@name + ">";
					}
				} else {
					for (i = 0; i < iterator; i++) 
					{
						tempString += "<" + element.@name + ">";
						tempString += serializeComplexType(element.@type.split(":")[1], object[i]);
						tempString += "</" + element.@name + ">";
					}
				}
			
			return tempString;
		}
		
		/**
		 * Finds the ComplexType defintion
		 * @param	name The name of the complex type
		 * @return The XML defining the type
		 */
		private function findComplexType(name:String):XML {
			for each (var complexType:XML in _complexTypes) 
			{
				if (complexType.@name == name)
					return complexType;
			}
			
			return new XML();
		}
		
		/**
		 * Creates the header including the envelope header
		 * @return XML String
		 */
		private function createHeader():String {
			var tempString:String = "";
			tempString += "<soap:Header>";
			
			if (_envelopeHeader != null) {
				var tempNS:Namespace = new Namespace(_requestXML.namespace("tns").uri);
				_envelopeHeader.setNamespace(tempNS)
				tempString += _envelopeHeader.toXMLString();
			}
				
			tempString += "</soap:Header>";
			return tempString;
		}
		
		/**
		 * The SOAP header to use when calling this method
		 */
		public function get envelopeHeader():XML { return _envelopeHeader; }
		
		public function set envelopeHeader(value:XML):void 
		{
			_envelopeHeader = value;
		}
		
		/**
		 * The name of the method
		 */
		public function get name():String { return _name; }
		
		/**
		 * An array filled with XML definitions of complex
		 * types.
		 */
		internal function set complexTypes(value:Array):void 
		{
			_complexTypes = value;
		}
		
		/**
		 * The time (in ms) it takes for the call to time out
		 * @default -1
		 */
		public function get timeout():int { return _timeout; }
		
		public function set timeout(value:int):void 
		{
			_timeout = value;
		}
		
		public function get decoder():WizardDecoder { return _decoder; }
		
		public function set decoder(value:WizardDecoder):void 
		{
			_decoder = value;
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