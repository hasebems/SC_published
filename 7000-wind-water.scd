s.boot
s.freeAll

// waterflow
({
({RHPF.ar(OnePole.ar(BrownNoise.ar, 0.99),
		LPF.ar(BrownNoise.ar, 14) * 400 + 500,
		0.03, 0.003)}!2)
+ ({RHPF.ar(OnePole.ar(BrownNoise.ar, 0.99),
		LPF.ar(BrownNoise.ar, 20)* 800 + 1000,
		0.03, 0.005)}!2)
* 4
}.play)  // ◀︎◀︎◀︎


// waterflow Loud, Low
({
({RHPF.ar(OnePole.ar(BrownNoise.ar, 0.99),
		LPF.ar(BrownNoise.ar, 14) * 400 + 500,
		0.08, 0.04)}!2)
+ ({RHPF.ar(OnePole.ar(BrownNoise.ar, 0.99),
		LPF.ar(BrownNoise.ar, 20) * 800 + 1000,
		0.09, 0.03)}!2)
* 4
}.play)  // ◀︎◀︎◀︎


//wind
({
	var w1, w2;								//two identical functions, one left, one right
	w1=RLPF.ar(
		WhiteNoise.ar(1), 					//normal level, out level comes later
		LFNoise1.kr(0.5, 1000, 1100) + 20,//filter controlled by global envelope.
												//Beware of low cutoff when using RLPF
		LFNoise1.kr(0.4, 0.45, 0.55),  // 0.55 to 1 varying reciprocal Q
		0.1		//low level, controlled by global envelope
	);
	w2=RLPF.ar(
		WhiteNoise.ar(1),
		LFNoise1.kr(0.5, 1000, 1100) + 20,
		LFNoise1.kr(0.4, 0.45, 0.55),
		0.1
	);
	Out.ar(0,[w1, w2] )
}.play)  // ◀︎◀︎◀︎


// windLightly
({
	var w1, w2;								//two identical functions, one left, one right
	w1=RLPF.ar(
		WhiteNoise.ar(1), 					//normal level, out level comes later
		LFNoise1.kr(0.5, 200, 400),
		                    //filter
												//Beware of low cutoff when using RLPF
		LFNoise1.kr(0.4, 0.45, 0.55),  // 0.55 to 1 varying reciprocal Q
		LFNoise1.kr(0.1, 0.05, 0.05)
	);
	w2=RLPF.ar(
		WhiteNoise.ar(1),
		LFNoise1.kr(0.5, 200, 400),
		LFNoise1.kr(0.4, 0.45, 0.55),
		LFNoise1.kr(0.1, 0.05, 0.05),
	);
	Out.ar(0,[w1, w2] )
}.play)  // ◀︎◀︎◀︎
