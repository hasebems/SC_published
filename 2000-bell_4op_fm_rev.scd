//===============================
//   Timbre
//===============================
// FM (4op.) & reverb
(
SynthDef("fm-bell", { arg nt = 60, fmul = 1, idx = 1, amp = 1, detune = 1;
	var modEnv = Env.pairs([[0,1],[0.5,0.3],[1.5,0]],\lin); // Mod. EG
	var carEnv = Env.pairs([[0,1],[2,0]],\lin);             // Car. EG
	var mod1 = SinOsc.ar(
		nt.midicps * fmul,
		0,
		idx*EnvGen.kr(modEnv, doneAction: Done.none )
  );
	var car1 = SinOsc.ar(
		nt.midicps + mod1,
		0,
		amp*EnvGen.kr(carEnv, doneAction: Done.freeSelf )
	);
	var mod2 = SinOsc.ar(
		nt.midicps * fmul * detune,
		0,
		idx*EnvGen.kr(modEnv, doneAction: Done.none )
  );
	var car2 = SinOsc.ar(
		nt.midicps * detune + mod2,
		0,
		amp*EnvGen.kr(carEnv, doneAction: Done.freeSelf )
	);
	Out.ar(0, FreeVerb.ar(
		Balance2.ar(car1,car2),
		mix:0.6, room:0.8, damp:0.5));
}).add;
)

//  for test
Synth("fm-bell")

//  for test with arg
Synth("fm-bell",["nt", 72, "fmul", 6, "idx", 6000, "detune", 1.007]);


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
		"fm-bell",
		["nt",num,"amp",vel/127,"fmul",6,"idx",6000,"detune",1.007]);
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