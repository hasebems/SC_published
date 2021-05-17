//  Raspberry pi 上で、opencv にて顔認識させ、その結果を MIDI に送って音を出す

//  開始
s.boot
MIDIIn.connectAll;

//	終了
MIDIIn.disconnectAll;
s.quit

s.freeAll
//  Command + .（ピリオド) で音が消える


//	Define Saw Wave Oscillator & MouseY Filter
(
SynthDef("KindtsSaw",{
	arg freq=340, gate=1, amp=1, vib=0, pan=0;
	var x;
	freq = LFTri.kr(5, 0.0, vib/20.0, freq);
	x = Saw.ar(freq, Lag2.kr(amp,0.5));
	x = BLowPass4.ar(x, vib*(7000/127)+1000, 1.0, 1.0, 0);
	x = EnvGen.kr(Env.adsr(0.1, 0, 1, 0.1, 1, -4), gate, doneAction: 2) * x;
	Out.ar(0, Pan2.ar(x,pan));
}).add;
)


//	Play SineWave by MIDI Keyboard
(
var synth = "KindtsSaw";
var basePitch = 220.0;
~osc = Synth.new(synth, [\amp, 0]);
~noteOnFunc = {arg src, chan, num, vel;
	~osc.set(\freq, basePitch);
	~osc.set(\amp, 1);
	"noteon".postln;
};
MIDIIn.addFuncTo(\noteOn, ~noteOnFunc);

~noteOffFunc = {arg src, chan, num, vel;
	~osc.set(\amp, 0);
};
MIDIIn.addFuncTo(\noteOff, ~noteOffFunc);
~bendFunc = {arg src, chan, bend; // 0-8192-16383
	var cent = (bend-8192)/7.0;
	var pit = basePitch*(2**(cent/1200.0));
	~osc.set(\freq, pit);
	bend.postln;
};
MIDIIn.addFuncTo(\bend, ~bendFunc);
~controlFunc = {arg src, chan, cnum, value; // 0-127
	if ( cnum == 1 ){
		~osc.set(\vib, value);
	}
};
MIDIIn.addFuncTo(\control, ~controlFunc);
)

// cleanup
(
~osc.free;
MIDIIn.removeFuncFrom(\noteOn, ~noteOnFunc);
MIDIIn.removeFuncFrom(\noteOff, ~noteOffFunc);
MIDIIn.removeFuncFrom(\bend, ~bendFunc);
MIDIIn.removeFuncFrom(\control, ~controlFunc);
)

