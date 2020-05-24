
//  開始
s.boot
MIDIIn.connectAll;

//	終了
MIDIIn.disconnectAll;
s.quit

s.freeAll
//  Command + .（ピリオド) で音が消える

//	Define SineWave Oscillator
(
SynthDef("KindtsSine",{
	arg freq=340, gate=1, amp=1, pan=0;
	var x;
	x = SinOsc.ar(freq, 0, Lag2.kr(amp,0.5));
	x = EnvGen.kr(Env.adsr(0.1, 0, 1, 0.1, 1, -4), gate, doneAction: 2) * x;
	Out.ar(0, Pan2.ar(x,pan));
}).add;
)

//	Play SineWave by MIDI Keyboard
(
var note = 0;
~osc = Synth.new("KindtsSine", [\amp, 0]);
~noteOnFunc = {arg src, chan, num, vel;
	~osc.set(\freq, num.midicps);
	~osc.set(\amp, 1);
	[num.midicps].postln;
	note = num;
};
MIDIIn.addFuncTo(\noteOn, ~noteOnFunc);

~noteOffFunc = {arg src, chan, num, vel;
	if ( num == note,
		{~osc.set(\amp, 0);}
	)
};
MIDIIn.addFuncTo(\noteOff, ~noteOffFunc);
)

// cleanup
(
~osc.free;
MIDIIn.removeFuncFrom(\noteOn, ~noteOnFunc);
MIDIIn.removeFuncFrom(\noteOff, ~noteOffFunc);
)

