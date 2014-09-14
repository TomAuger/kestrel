package com.zeitguys.audio.generator {
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	
	public class SimpleSine extends EventDispatcher {
		public static const PAN_LEFT:int = -1;
		public static const PAN_CENTER:int = 0;
		public static const PAN_CENTRE:int = 0; // for us Canadians.
		public static const PAN_RIGHT:int = 1;
		
		private const AMP_MULTIPLIER:Number = 1;
		private const SAMPLING_RATE:uint = 44100;
		private const TWO_PI:Number = 2 * Math.PI;
		private const TWO_PI_OVER_SR:Number  = TWO_PI / SAMPLING_RATE;
		private const SAMPLE_BUFFER:uint = 8192;
		
		private var _sound:Sound = new Sound;
		private var _soundChannel:SoundChannel = new SoundChannel;
		private var _currentFrequency:Number;
		
		private var _leftPeak:Number = 1;
		private var _rightPeak:Number = 1;
		
		private var _currentPeak:Number = 1.0;
		private var _currentGain:Number = 1.0;
		
		public function SimpleSine() {
			
		}
		
		public function playTone(frequency:Number, maxAmplitude:Number = 1.0, gain:Number = 1.0, pan:Number = PAN_CENTRE):uint {
			_currentFrequency = frequency;
			_currentPeak = maxAmplitude;
			_currentGain = gain;
			this.pan = pan;
			
			_sound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			_soundChannel = _sound.play();
			
			this.gain = _currentGain;
			
			return 0; // eventually return a tone ID
		}
		
		public function stopTone(toneID:uint = 0):void {
			_sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			_soundChannel.stop();
		}
		
		public function set leftPeak(peak:Number):void {
			_leftPeak = peak;
		}
		
		public function get leftPeak():Number {
			return _leftPeak;
		}
		
		public function set rightPeak(peak:Number):void {
			_rightPeak = peak;
		}
		
		public function get rightPeak():Number {
			return _rightPeak;
		}
		
		public function set pan(pan:Number):void {
			pan = Math.max(Math.min(pan, 1), -1);
			
			leftPeak = .5 - (pan * .5);
			rightPeak = .5 + (pan * .5);
		}
		
		public function set gain(volume:Number):void {
			if (_soundChannel) {
				var st:SoundTransform = _soundChannel.soundTransform;
				st.volume = volume;
				_soundChannel.soundTransform = st;
			}
			
			_currentGain = volume;
		}
		
		public function get soundChannel():SoundChannel {
			if (_soundChannel) {
				return _soundChannel;
			} else {
				return null;
			}
		}
		
		private function onSampleData(event:SampleDataEvent):void {
			var sample:Number;
			for (var i:uint = 0; i< SAMPLE_BUFFER; ++i ){
				sample = Math.sin((i + event.position ) * TWO_PI_OVER_SR * _currentFrequency);
				event.data.writeFloat(sample * _currentPeak * _leftPeak); // left
				event.data.writeFloat(sample * _currentPeak * _rightPeak); // right
			}
		}
	}
	
}
