//===============================
//   Timbre
//===============================
// Pulse*2(+LFO/AEG) & LPF(+FEG)
(
SynthDef("lonely", { arg nt = 60, amp = 1, gate = 1;
	var aeg = Env.adsr(0,0.5,0.5,0.1);
	var vib = SinOsc.kr(5, 0, 0.01, 1);
	// Oscilator with Vib/AEG
	var pulse1 = Pulse.ar(
		nt.midicps*vib*1.01,
		0.5,          // pulse duty
		mul:amp*EnvGen.kr(aeg, gate, doneAction: Done.freeSelf)
	);
	var pulse2 = Pulse.ar(
		nt.midicps*vib,
		0.5,          // pulse duty
		mul:amp*EnvGen.kr(aeg, gate, doneAction: Done.freeSelf)
	);
	// Filter with FEG
	var feg = Env.xyc([[0.1,1,\lin],[0.3,0.3,\lin],[0.5,0.1,\lin]]);
	var flt = LPF.ar( [pulse1,pulse2],
		3000*EnvGen.kr(feg, gate, doneAction:Done.none)
	);
	//  出力
	Out.ar(0, Pan2.ar(flt,0.0,0.1));
}).add;
)

//  for test
Synth("lonely");


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
		"lonely",
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