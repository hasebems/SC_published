//===============================
// Explanation
//	MIDI ch : 1-5
//	tone :	part 1,2 : sinePhong
//			part 3,4,5 : pulsePhone
//	Controller Change :
//			#1 mod, #7 volume,
//			#10 pan, #11 exp, #73 eg
//===============================
s.boot

s.plotTree

//===============================
//   Timbre
//===============================
(
SynthDef("sinePhong", {
	arg nt = 60, gate = 1, vel = 1, vol = 1, pan = 0, eg = 1;
	var vib = SinOsc.kr(5, 0, 0.02, 1);
	var scale = (128-nt)/128;  // 0-1
	var softeg = 0.4*(1-eg);
	var scaleeg = 0.4 + scale;
	var aeg = Env.adsr(softeg,scaleeg-softeg,0,scaleeg-softeg);

	// Oscilator with Vib/AEG
	var pulse1 = SinOsc.ar(
		nt.midicps*vib*1.01,
		mul:((scale/2)+0.5)*vel*EnvGen.kr(aeg, gate, doneAction: Done.freeSelf)
	);
	var pulse2 = SinOsc.ar(
		nt.midicps*vib,
		mul:((scale/2)+0.5)*vel*EnvGen.kr(aeg, gate, doneAction: Done.freeSelf)
	);
	//  出力
	Out.ar(0, Pan2.ar([pulse1,pulse2],pan,0.1*vol));
}).add;

SynthDef("pulsePhong", {
	arg nt = 60, gate = 1, vel = 1, vol = 1, mod = 1, pan = 0, eg = 0.5;
	var vib = SinOsc.kr(2, 0, 0.01, 1);
	var scale = (128-nt)/128;  // 0-1
	var softeg = 0.2*(1-eg);
	var scaleeg = 0.4 + scale;
	var aegcnt = Env.adsr(softeg,scaleeg-softeg,0,scaleeg-softeg);
	var pwm = mod/2;

	// Oscilator with Vib/AEG
	var pulse1 = Pulse.ar(
		nt.midicps*vib*1.01,
		width:pwm,
		mul:((scale/2)+0.5)*vel*EnvGen.kr(aegcnt, gate, doneAction: Done.freeSelf)
	);
	var pulse2 = Pulse.ar(
		nt.midicps*vib,
		width:pwm,
		mul:((scale/2)+0.5)*vel*EnvGen.kr(aegcnt, gate, doneAction: Done.freeSelf)
	);
	//  出力
	Out.ar(0, Pan2.ar([pulse1,pulse2],pan,0.1*vol));
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

//  begin to play by MIDI(5part)
(
var keys, cnts, tone, egtbl;
keys = Array2D.new(128,5);  // row, col
cnts = Array2D.fromArray(96,5,{1}.dup(96*5));
tone = ["sinePhong","sinePhong","pulsePhong","pulsePhong","pulsePhong"];
egtbl = [1,1,0.5,0.5,0.5];
for (0,5,{arg i; cnts[73,i]=egtbl[i];});
for (0,5,{arg i; cnts[10,i]=0.0;});

~noteOnFunc = {arg src, chan, num, vel;
	var node;
	node = keys.at(num,chan);
	if (node.notNil, {node.release; keys.put(num, chan, nil); });
	node = Synth.head(~grp,tone[chan],[
		"nt",num,
		"vel",vel/127,
		"vol",cnts[7,chan],
		"pan",cnts[10,chan],
		"eg",cnts[73,chan],
		"mod",cnts[1,chan]]);
	keys.put(num, chan, node);
	[chan,num,vel].postln;
};
MIDIIn.addFuncTo(\noteOn, ~noteOnFunc);

~noteOffFunc = {arg src, chan, num, vel;
	var node;
	node = keys.at(num,chan);
	if (node.notNil, {node.release;keys.put(num, chan, nil);});
};
MIDIIn.addFuncTo(\noteOff, ~noteOffFunc);

~controlFunc = {arg src, chan, ccnum, value;
	if( ccnum==10,
		{cnts[10,chan] = (value/64)-1;},
		{cnts[ccnum,chan] = value/127;});
	[chan,ccnum,value].postln;
};
MIDIIn.addFuncTo(\control, ~controlFunc);
)  // (4)