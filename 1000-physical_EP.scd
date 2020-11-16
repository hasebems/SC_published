//===============================
//   Timbre
//===============================
(
SynthDef(\ks_EP,
{
  arg nt, amp, pan=0, delayTime=2, noiseType=1;
  var x, y, env;
  env = Env.new(#[1, 1, 0],#[2, 0.001]);

  x = Decay.ar(
		Impulse.ar(0, 0, amp),         // input
		0.1+amp,                       // decay Time
  );

  x = CombL.ar(
	  LPF.ar(x, (amp*2000)),       // input
		0.05,                        // maxdelaytime
    nt.midicps.reciprocal,       // delaytime
    delayTime,                   // decaytime
    EnvGen.ar(env, doneAction:2) // mul
  );

	x = Pan2.ar(x, pan);
  Out.ar(0, LeakDC.ar(x));
}).add;
)



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
		"\ks_EP",
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
