package se.mowday.webservice 
{
	import flash.utils.Dictionary;
	
	/**
	* The wizard decoder is a complex version of the lazydecoder, but doesn't
	* sacrifice performance. It allows the developer to add classes that is used
	* by the server, wich will then be casted correctly when recieved from the server.
	* By doing so the server and client side can have exact replicas of each others classes
	* and they can be used on the same manner on both sides.
	* @author Calle Mowday
	*/
	public class WizardDecoder
	{
		private var _complexTypes	:	Array;
		private var s				:	Namespace;
		private var _mappedClasses	:	Dictionary;
		
		public function WizardDecoder() { _mappedClasses = new Dictionary(); }
		
		/**
		 * Decodes the answer using the WSDL declerations
		 * @param	xml The response XML
		 * @param	decleration The decleration of the response from the WSDL
		 * @param	methodName The method called
		 * @return
		 */
		internal function decode(xml:XML, decleration:XML, methodName:String):*
		{
			var soap:Namespace	= xml.namespace("soap");
			var body:XMLList	= xml.soap::Body;
			var response:XML	= body.children()[0];
			var result:XML		= response.children()[0];
			
			s = decleration.namespace("s");
			
			var complexType:XMLList = decleration.s::complexType;
			
			//If the return value is void
			if (complexType.s::sequence == undefined)
			{
				return null;
			}
			
			var sequence:XMLList		= complexType.s::sequence;
			var elementDescription:XML	= sequence.children()[0];
			var type:String				= elementDescription.@type;
			
			return newObject(result, type);
		}
		
		/**
		 * Returns the class if it has been mapped, otherwise it returns null
		 * @param	typeName The class name searched for
		 * @return The class if it exists, otherwise null
		 */
		private function getMappedClass(typeName:String):Class {
			if (typeName.indexOf("tns:") > -1)
				typeName = typeName.split(":")[1];

			return _mappedClasses[typeName];
		}
		
		/**
		 * Maps a class to be casted when returned from the server
		 * @param	mappedClass The class to mapped
		 * @param	typeName [OPTIONAL] The name of the class if it differs from the class on the server
		 * (ie: server classname is Client, but called User on the client side);
		 */
		public function insertClass(mappedClass:Class, typeName:String = ""):void {
			if (mappedClass == null)
				throw new Error("Mapped class cannot be null");
			
			if (typeName == "") {
				var reg:RegExp = new RegExp("\\[ [^\\s]* \\  (?P<name> [^\\s]*) \\]", "mx");
				typeName = reg.exec(String(mappedClass)).name
			}
			
			_mappedClasses[typeName] = mappedClass;
		}
		
		/**
		 * Creates a new casted object and returns it
		 * @param	valueXML The xml containing the values to be set.
		 * @param	type The type of the object
		 * @return Correctly casted object
		 */
		private function newObject(valueXML:XML, type:String):* {
			if (valueXML == null)
				return null;
				
			if (valueXML.hasSimpleContent() && type.indexOf("ArrayOf") == -1) {
				return createSimpleObject(valueXML, type);
			} else {
				if (type.indexOf("ArrayOf") > -1) {
					return createArray(valueXML, getComplexType(type));
				} else {
					return createObject(valueXML, getComplexType(type));
				}
				
			}
		}
		
		/**
		 * Creates a new complex object. It will also try to find a mapped class
		 * based on the name of the description.
		 * @param	valueXML The values to be set
		 * @param	descriptionalXML The xml describing how the object should look
		 * @return The correclty casted object,
		 */
		private function createObject(valueXML:XML, descriptionalXML:XML):* {
			var tempObject:*;
			if(getMappedClass(descriptionalXML.@name) == null)
				tempObject = new Object();
			else {
				var myClass:Class = getMappedClass(descriptionalXML.@name) as Class;
				tempObject = new myClass();
			}
			
			//If the return value is void
			if (descriptionalXML.s::sequence == undefined)
				return void;
			
			//Loop all data in sequence tag
			var sequence:XMLList = descriptionalXML.s::sequence;
			var ns:Namespace = valueXML.namespace();
			
			for each (var elementXML:XML in sequence.children()) 
			{
				var currentValue:XML = valueXML.ns::[elementXML.@name][0];
				
				if(currentValue != null) {
					
					tempObject[elementXML.@name] = newObject(currentValue, elementXML.@type );
				
				} else {
					tempObject[elementXML.@name] = null;
				}
				
				
			}
			
			//Loop all data in attributes tag
			var attributes:XMLList = descriptionalXML.s::attribute;
			
			for each (var attributeXML:XML in attributes) 
			{
				tempObject[attributeXML.@name] = 
					createSimpleObject(valueXML["@" + attributeXML.@name], attributeXML.@type);
			}
			
			return tempObject;
		}
		
		/**
		 * Creates an array, either typed or untyped.
		 * @param	valueXML The values to be set
		 * @param	descriptionalXML The xml describing the array
		 * @return The correctly casted Array
		 */
		private function createArray(valueXML:XML, descriptionalXML:XML):Array {
			if (descriptionalXML.@name != "ArrayOfAnyType")
				return createTypedArray(valueXML, descriptionalXML);
			else
				return createUntypedArray(valueXML);
				
		}
		
		/**
		 * Creates a typed Array
		 * @param	valueXML The values to be set
		 * @param	descriptionalXML The xml describing the array
		 * @return The correctly casted Array
		 */
		private function createTypedArray(valueXML:XML, descriptionalXML:XML):Array {
			var tempArr:Array = new Array;
			
			//If the return value is void
			if (descriptionalXML.s::sequence == undefined)
				return null;
			
			var sequence:XMLList = descriptionalXML.s::sequence;
			var elementXML:XML = sequence.children()[0];
			
			for each (var currentValue:XML in valueXML.children()) 
			{
				var newPost:* = newObject(currentValue, elementXML.@type);
				tempArr.push(newPost);
			}
			
			return tempArr;
			
		}
		
		/**
		 * Creates an untyped array
		 * @param	valueXML The values to be set
		 * @return The correctly casted Array
		 */
		private function createUntypedArray(valueXML:XML):Array {
			var tempArr:Array = new Array;
			var xsi:Namespace = valueXML.namespace("xsi");
			for each (var nod:XML in valueXML.children()) 
			{
				var type:String = nod.@xsi::type;
				
				if(type.indexOf("xsd:") > -1)
					type = nod.@xsi::type.split(":")[1];
					
				tempArr.push(newObject(nod, type));
			}
			return tempArr;
		}
		
		
		/**
		 * Creates a "simple object" (string, number, bool)
		 * @param	value The value
		 * @param	type The type of object (s:string|s:int|s:boolean etc)
		 * @return The correctly casted object
		 */
		private function createSimpleObject(value:String, type:String):* {
			if (type.indexOf("s:") > -1)
				type = type.split(":")[1];
			
			switch(type) {
				case "string":
					return String(value);
				break;
				
				case "boolean":
					return value == "true";
				break;
				
				default:
					var toReturn:Number = Number(value);
					//if (isNaN(toReturn))
					//	return String(value);
						
					return toReturn;
				break;
			}
		}
		
		/**
		 * Inserts the array of complex types that can occur
		 * @param	complexTypes
		 */
		public function insertComplexTypes(complexTypes:Array):void
		{
			_complexTypes = complexTypes.concat();
		}
		
		
		/**
		 * Gets the XML definition of a complex type. If
		 * none is found null is returned.
		 * @param	typeName The name of the complex type
		 * @return The XML definition or null
		 */
		private function getComplexType(typeName:String):XML {
			if (typeName.indexOf("tns:") > -1)
				typeName = typeName.split(":")[1];
			
			for each (var element:XML in _complexTypes) 
			{
				if (element.@name == typeName) {
					
					if (element.s::complexContent != undefined)
					{
						//Has complex content
						var cc:XML = element.s::complexContent[0];
						if (cc.s::extension != undefined)
						{
							//Extends another class
							var newElement:XML = element.copy();
							newElement.setChildren( "" );
							
							var extension:XML = cc.s::extension[0].copy();
							var baseDefinition:XML = getComplexType(extension.@base);
							
							mergeXML(newElement, extension);
							mergeXML(newElement, baseDefinition);
							
							element = newElement;
						}
					}
					
					return element;
				}
			}
			
			trace("Not found!");
			return null;
		}
		
		/**
		 * Merges one xml into another xml. Only children tags are merged.
		 * (This is used in the getComplexType function)
		 * @param	baseXML The xml to start of from
		 * @param	additionXML  The xml whos children tags should be added to the base
		 */
		private function mergeXML(baseXML:XML, additionXML:XML):void
		{
			var tags:XMLList = additionXML.s::*;
			for each (var tag:XML in tags) 
			{
				baseXML.appendChild(tag);
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