/**
 * Licensed under the MIT License
 * 
 * Copyright (c) 2009 Sweatless Team 
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 * http://code.google.com/p/sweatless/
 * http://www.opensource.org/licenses/mit-license.php
 * 
 * @author Valério Oliveira (valck)
 * 
 */

package sweatless.media{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.utils.Dictionary;
	
	import sweatless.events.CustomEvent;
	
	public class VideoTrack extends Sprite{
		
		public static const CUEPOINT : String = "cuepoint";
		public static const COMPLETE : String = "complete";
		
		private var _width : Number;
		private var _height : Number;
		
		private var _deblocking : int = 3;
		private var _smoothing : Boolean;
		
		private var _rewind : Boolean;
		private var _playing : Boolean;
		private var _looping : Boolean;
		private var _mute : Boolean;
		
		private var _cuepoints : Dictionary;
		private var properties : Dictionary;
		
		private var stream : NetStream;
		private var video : Video;
		
		private var currentVolume : Number = 1;
		private var currentPan : Number = 0;
		
		private var count : uint;
		
		private var object : DisplayObject;
		
		
		public function VideoTrack(){
			video = new Video();
			addChild(video);
		}
		
		public function get autoRewind():Boolean{
			return _rewind;
		}
		
		public function set autoRewind(value:Boolean):void{
			_rewind = value;
		}
		
		public function get isMute():Boolean{
			return _mute;
		}
		
		public function set isMute(value:Boolean):void{
			_mute = value;
		}
		
		public function get isLooping():Boolean{
			return _looping;
		}
		
		public function set isLooping(value:Boolean):void{
			_looping = value;
		}
		
		public function get isPlaying():Boolean{
			return _playing;
		}
		
		public function set isPlaying(value:Boolean):void{
			_playing = value;
		}
		
		public function get deblocking():int{
			return _deblocking;
		}
		
		public function set deblocking(value:int):void{
			_deblocking = video.deblocking = value;
		}
		
		public function get smoothing():Boolean{
			return _smoothing;
		}
		
		public function set smoothing(value:Boolean):void{
			_smoothing = video.smoothing = value;
		}
		
		public function set track(p_netstream:NetStream):void{
			stream = p_netstream;
			video.attachNetStream(stream);
			stream.client.onCuePoint = onCuePoint;
		}
		
		public function get track():NetStream{
			return stream;
		}
		
		public function get percentLoaded():Number{
			return stream.bytesLoaded/stream.bytesTotal;
		}
	
		
		public function set seek(p_offset:Number):void{
			stream.seek(p_offset);
		}
		
		public function get seek():Number{
			return stream.time;
		}
		
		public function seekToCuepoint(p_name:String):void{
			if(!_cuepoints) throw new Error("No metadata was assigned to this VideoTrack");
			if(!_cuepoints[p_name]) throw new Error("The requested cuepoint does not exist");
			
			seek = Number(_cuepoints[p_name].time);
		}
		
		public function get duration():Number{
			return properties ? Number(properties["duration"]) : NaN;
		}
		
		public function set metadata(p_object:*):void{
			properties = new Dictionary();
			
			for(var prop:String in p_object) {
				properties[String(prop)] = String(p_object[prop]);
			}
			
			if(!p_object["cuePoints"]) return;
			
			_cuepoints = new Dictionary();
			
			for(prop in p_object["cuePoints"]) {
				_cuepoints[p_object["cuePoints"][prop].name] = new CuePoint(p_object["cuePoints"][prop].name, p_object["cuePoints"][prop].time);
			}
		}
		
		public function play(p_loops:uint=0):void{
			isPlaying = true;
			
			stream.addEventListener(NetStatusEvent.NET_STATUS, status);
			
			p_loops>0 ? count = p_loops : null;
			
			stream.seek(0);
			stream.resume();
			
			volume = currentVolume;
		}
		
		public function stop():void{
			isPlaying = false;
			
			stream.removeEventListener(NetStatusEvent.NET_STATUS, status);
			stream.seek(0);
			stream.pause();
		}
		
		public function pause():void {
			if(!isPlaying) {
				isPlaying = true;
				stream.addEventListener(NetStatusEvent.NET_STATUS, status);
				stream.resume();
			}else {
				isPlaying = false;
				stream.removeEventListener(NetStatusEvent.NET_STATUS, status);
				stream.pause();
			}
		}
		
		public function set pan(p_pan:Number):void {
			var transform : SoundTransform = new SoundTransform(currentVolume, p_pan);
			
			transform.pan = p_pan;
			stream.soundTransform = transform;
			currentPan = transform.pan;            
		}
		
		public function get pan():Number {
			return currentPan;
		}
		
		public function set volume(p_volume:Number):void {
			var transform : SoundTransform = new SoundTransform(p_volume, currentPan);
			
			transform.volume = p_volume;
			stream.soundTransform = transform;
			currentVolume = transform.volume;            
		}
		
		public function get volume():Number {
			return currentVolume;
		}
		
		public function mute():void {
			var transform : SoundTransform;
			
			if(!isMute){
				isMute = true
				
				transform = new SoundTransform(0, currentPan);
				transform.volume = 0;
				
				stream.soundTransform = transform;				
			}else{
				isMute = false
				
				transform = new SoundTransform(currentVolume, currentPan);
				transform.volume = currentVolume;
				
				stream.soundTransform = transform;
			}
		}
		
		private function status(evt:NetStatusEvent):void{
			if(evt.info.code == "NetStream.Play.Stop"){
				if(count>0){
					isLooping = true;
					count--;
					play(count);
				}else{
					isPlaying = false;
					isLooping = false;
					stream.removeEventListener(NetStatusEvent.NET_STATUS, status);
					_rewind ? stop() : null;
				}
				!isPlaying ? dispatchEvent(new Event(VideoTrack.COMPLETE)) : null;
			}else if(evt.info.code == "NetStream.Seek.Notify"){
				
			}else if(evt.info.code == "NetStream.Seek.InvalidTime"){
				
			} 
		}
		
		private function move(evt:MouseEvent):void{
			if(!object && !stream) return;
			
			var value : Number = 0;
			
			if (evt.stageX>(object.width/2)) {
				value = (evt.stageX/(object.width/2))-1;
			} else if (evt.stageX<(object.width/2)){
				value = (evt.stageX-(object.width/2))/(object.width/2);
			}
			
			if(value>1) value = 0;
			
			volume = 1-(evt.stageY/object.width);
			pan = value;
		}        
		
		public function addMousePan(p_target:DisplayObject):void{
			object = p_target;
			object.stage.addEventListener(MouseEvent.MOUSE_MOVE, move);
		}
		
		public function removeMousePan():void {
			if(!object) return;
			
			object.stage.removeEventListener(MouseEvent.MOUSE_MOVE, move);
			
			volume = 1;
			pan = 0;
		}
		
		private function onCuePoint(p_object:Object):void {
			//trace(p_object.name + "\t" + p_object.time);
			
			if(!_cuepoints) _cuepoints = new Dictionary();
			if(!_cuepoints[p_object.name]) _cuepoints[p_object.name] = p_object.time;
			
			dispatchEvent(new CustomEvent(CUEPOINT, p_object));
		}
		
		public function get cuepoints():Vector.<CuePoint>{
			var result:Vector.<CuePoint> = new Vector.<CuePoint>;
			if(!_cuepoints) return result;
			for(var prop:String in _cuepoints) result.push(new CuePoint(prop, _cuepoints[prop].time));
			return result.sort(cuePointSort);
		}
		
		private function cuePointSort(a:CuePoint, b:CuePoint):int{
			if(int(a.time) > int(b.time)){
				return 1;
			}else if(int(a.time) == int(b.time)){
				return 0;
			}else{
				return -1;
			}
		}
		
		override public function set width(p_value:Number):void{
			_width = video.width = int(p_value);
		}
		
		override public function set height(p_value:Number):void{
			_height = video.height = int(p_value);
		}
		
		override public function get width():Number{
			return properties ? properties["width"] : _width;
		}
		
		override public function get height():Number{
			return properties ? properties["height"] : _height;
		}
		
		public function destroy(p_close_netstream:Boolean=true):void{
			stop();
			p_close_netstream ? stream.close() : stream = null;
			video.clear();
			removeMousePan();
		}
	}
}