//===============================
//   Timbre
//===============================
// Pulse & reverb
(
SynthDef("pulse", { arg nt = 60, amp = 1, gate = 1;
	var aeg = Env.adsr(0,0.5,0.5,0.1);
	var pulse = Pulse.ar(
		nt.midicps,
		0.2,          // pulse duty
		mul:amp*EnvGen.kr(aeg, gate, doneAction: Done.freeSelf )
	);
	Out.ar(0, FreeVerb.ar(
		pulse,
		mix:0.3, room:0.5, damp:0.5));
}).add;
)

//  for test
Synth("pulse");


//===============================
//   MIDI
//===============================
MIDIIn.connectAll;
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
	node = Synth.tail(nil,
		"pulse",
		["nt",num,"amp",vel/127]);
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
)

// cleanup MIDI
(
MIDIIn.removeFuncFrom(\noteOn, ~noteOnFunc);
MIDIIn.removeFuncFrom(\noteOff, ~noteOffFunc);
)