s.boot

s.plotTree

//===============================
//   Timbre
//===============================
// Sine Pulse*2(+LFO/AEG) , Reverb
(
SynthDef("pulsePhong", { arg nt = 60, amp = 0.5, gate = 1, pwm = 1, aeg = 0.5;
	var vib = SinOsc.kr(2, 0, 0.01, 1);
	var scale = (128-nt)/128;  // 0-1
	var softeg = 0.2*(1-aeg);
	var scaleeg = 0.4 + scale;
	var aegcnt = Env.adsr(softeg,scaleeg-softeg,0,scaleeg-softeg);

	// Oscilator with Vib/AEG
	var pulse1 = Pulse.ar(
		nt.midicps*vib*1.01,
		width:pwm/2,
		mul:((scale/2)+0.5)*amp*EnvGen.kr(aegcnt, gate, doneAction: Done.freeSelf)
	);
	var pulse2 = Pulse.ar(
		nt.midicps*vib,
		width:pwm/2,
		mul:((scale/2)+0.5)*amp*EnvGen.kr(aegcnt, gate, doneAction: Done.freeSelf)
	);
	//  出力
	Out.ar(0, Pan2.ar([pulse1,pulse2],0.0,0.2*amp));
}).add;

// Reverb
~grp = Group.basicNew(s,1);
SynthDef(\reverb_pulse, {arg delaytime=0.01, decaytime=1;
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
	Out.ar(0,(0.1*temp));  // Dry/Wet
}).add;
)  // (1)


//===============================
//   MIDI
//===============================
MIDIIn.connectAll;  // (2)
MIDIIn.disconnectAll;

//  reverb on
r = Synth.tail(~grp, \reverb_pulse); // (3)
//  reverb off
r.free

//  begin to play by MIDI(16part)
(
var keys;
keys = Array2D.new(128,16);

~noteOnFunc = {arg src, chan, num, vel;
	var node;
	node = keys.at(num,chan);
	if (node.notNil, {
		node.release;
		keys.put(num, chan, nil);
	});
	node = Synth.head(~grp,
		"pulsePhong",
		["nt",num,"pwm",vel/127]);
	keys.put(num, chan, node);
	[chan,num,vel].postln;
};
MIDIIn.addFuncTo(\noteOn, ~noteOnFunc);

~noteOffFunc = {arg src, chan, num, vel;
	var node;
	node = keys.at(num,chan);
	if (node.notNil, {
		node.release;
		keys.put(num, chan, nil);
	});
};
MIDIIn.addFuncTo(\noteOff, ~noteOffFunc);



)  // (4)
