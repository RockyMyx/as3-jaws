package se.mowday.webservice 
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	
	import flash.utils.setTimeout;
	
	/**
	 * This class is used to handle or the errors that can occur.
	 * @author Calle Mowday
	 */
	internal class ErrorHandler 
	{
		private var _collaborator:IEventDispatcher;
		
		public function ErrorHandler(collaborator:IEventDispatcher) 
		{
			_collaborator = collaborator;
		}
		
		public function handle(downloader:URLLoader):void {
			downloader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusError);
			downloader.addEventListener(IOErrorEvent.IO_ERROR, ioError);
			downloader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		}
		
		private function dispatchEvent(event:Event):void {
			if(_collaborator.hasEventListener(event.type))
				_collaborator.dispatchEvent(event);
			else
				if (event is ErrorEvent)
					throw new Error("Unhandled error: " + ErrorEvent(event).text);
				else
					throw new Error("Unhandled error: " + event.toString());
		}
		
		private function ioError(event:IOErrorEvent):void
		{
			if (_collaborator is WSDL)
			{
				dispatchEvent(event);
			}
		}
		
		private function resendHttpStatus(event:HTTPStatusEvent):void {
			//Checks to see if the data is null. If it is something was wrong. Otherwise
			//the call was successfull and this event should not be fired
			if (event.target.data == null) {
				event = new HTTPStatusEvent(event.type, event.bubbles, event.cancelable, 600);
				httpStatusError(event);
			}
		}
		
		private function httpStatusError(event:HTTPStatusEvent):void {
			if (event.status != 200) {
				var name:String = _collaborator is WebserviceCall ? WebserviceCall(_collaborator).name : "Unknown";
				
				//Protection against the Flash Player Plugin bug (always returns 0)
				if (event.status == 0) {
					setTimeout(resendHttpStatus, 50, event);
					return;
				}
				
				var newEvent:WebserviceEvent = new WebserviceEvent(WebserviceEvent.RESPONSE, false, name);
				newEvent.faultCode = event.status;
				switch(event.status) {
					case 500:
						newEvent.faultDescription = "Internal Server Error";
					break;
					
					case 501:
						newEvent.faultDescription = "Not Implemented";
					break;
					
					case 502:
						newEvent.faultDescription = "Bad Gateway";
					break;
					
					case 503:
						newEvent.faultDescription = "Service Unavailable";
					break;
					
					case 504:
						newEvent.faultDescription = "Gateway Timeout";
					break;
					
					case 600:
						newEvent.faultDescription = "Flash Player Plugin Error. You're using Flash Player plugin, all status codes are returned as 0.";
						newEvent.faultDescription += " No more information about the error is available";
						newEvent.faultCode = 0;
					break;
					
					default:
						newEvent.faultDescription = "HTTP Status Error";
					break;
				}
				newEvent.faultObject = _collaborator;
				
				dispatchEvent(newEvent);
			}
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			var name:String = _collaborator is WebserviceCall ? WebserviceCall(_collaborator).name : "Unknown";
			var newEvent:WebserviceEvent = new WebserviceEvent(WebserviceEvent.RESPONSE, false, name);
			
			newEvent.faultCode = 401;
			newEvent.faultDescription = "Security " + event.text;
			newEvent.faultObject = _collaborator;
			
			dispatchEvent(newEvent);
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