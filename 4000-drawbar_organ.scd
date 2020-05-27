//===============================
//   Timbre
//===============================
(
SynthDef("DrawbarOrgan", { arg nt = 60, amp = 1, gate = 1;
	var drawbar = [0.5, 0, 0.2, 0.1, 0.1];
	var aeg = Env.adsr(0,0.08,0.7,0);
	var sig;
	f = nt.midicps;
	sig=SinOsc.ar(  // 8
		freq:f,
		mul:amp*drawbar[0]*EnvGen.kr(aeg, gate, doneAction: Done.freeSelf)
	);
	sig=sig+SinOsc.ar(  // 4
		freq:f*2,
		mul:amp*drawbar[1]*EnvGen.kr(aeg, gate, doneAction: Done.freeSelf)
	);
	sig=sig+SinOsc.ar(  // 2 2/3
		freq:f*3,
		mul:amp*drawbar[2]*EnvGen.kr(aeg, gate, doneAction: Done.freeSelf)
	);
	sig=sig+SinOsc.ar(  // 2
		freq:f*4,
		mul:amp*drawbar[3]*EnvGen.kr(aeg, gate, doneAction: Done.freeSelf)
	);
	sig=sig+SinOsc.ar(  // 1 3/5
		freq:f*5,
		mul:amp*drawbar[4]*EnvGen.kr(aeg, gate, doneAction: Done.freeSelf)
	);
	Out.ar(0,sig*0.3);
}).add;
)


//===============================
//   MIDI
//===============================
MIDIIn.connectAll;  // (2)
MIDIIn.disconnectAll;


//  begin to play by MIDI
(
var keys;
keys = Array.newClear(128);

~noteOnFunc = {arg src, chan, num, vel;
	var node;
	node = keys.at(num);
	if (node.notNil, {
		node.release;
		keys.put(num, nil);
	});
	node = Synth.head(~grp,
		"DrawbarOrgan",
		["nt",num]);
	keys.put(num, node);
	[chan,num,vel].postln;
};
MIDIIn.addFuncTo(\noteOn, ~noteOnFunc);

~noteOffFunc = {arg src, chan, num, vel;
	var node;
	node = keys.at(num);
	if (node.notNil, {
		node.release;
		keys.put(num, nil);
	});
};
MIDIIn.addFuncTo(\noteOff, ~noteOffFunc);
)  // (3)

// cleanup MIDI
(
MIDIIn.removeFuncFrom(\noteOn, ~noteOnFunc);
MIDIIn.removeFuncFrom(\noteOff, ~noteOffFunc);
)