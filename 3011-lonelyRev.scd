//===============================
//   Timbre
//===============================
// Pulse*2(+LFO/AEG) & LPF(+FEG) , Reverb
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

// Reverb
~grp = Group.basicNew(s,1);
SynthDef(\reverb0, {arg delaytime=0.01, decaytime=1;
	var input;
	var numc,numa,temp;
	input=In.ar(0,2);//get two channels of input starting (and ending) on bus 0
	numc = 4; // number of comb delays
	numa = 6; // number of allpass delays
	// reverb predelay time :
	temp = DelayN.ar(input, 0.048,0.048);
	temp=Mix.fill(numc,{CombL.ar(temp,0.1,rrand(0.01, 0.1),5)});
	// chain of 4 allpass delays on each of two channels (8 total) :
	numa.do({
		temp = AllpassN.ar(
			temp, 0.051, [rrand(0.01, 0.05),rrand(0.01, 0.05)], 1)
	});
	// add original sound to reverb and play it :
	Out.ar(0,(0.2*temp));
}).add;
)  // (1)

//  for test
Synth("lonely");

s.queryAllNodes;

SynthDescLib.global.browse;  // new window appears.

//===============================
//   MIDI
//===============================
MIDIIn.connectAll;  // (2)
MIDIIn.disconnectAll;

//  begin reverb
Synth.tail(~grp, \reverb0); // (3)

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
)  // (4)

// cleanup MIDI
(
MIDIIn.removeFuncFrom(\noteOn, ~noteOnFunc);
MIDIIn.removeFuncFrom(\noteOff, ~noteOffFunc);
)