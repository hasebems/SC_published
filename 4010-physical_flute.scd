//===============================
//   Timbre
//   from this site : https://thormagnusson.gitbooks.io/scoring/content/PartII/chapter11.html
//===============================
(
SynthDef("waveguideFlute", {
    arg pch = 72, ipress = 0.9, ibreath = 0.09,
        ifeedbk1 = 0.4, ifeedbk2 = 0.4,
        amp = 2, vibrato=0.2, gate = 1;
    var kenv1, kenv2, kenvibr, kvibr, sr, cr, block, poly, signalOut, ifqc;
    var aflow1, asum1, asum2, afqc, ax, apoly, asum3, avalue, aflute1;

    sr = SampleRate.ir;
    cr = ControlRate.ir;
    block = cr.reciprocal;
    ifqc = pch.midicps;

    // noise envelope
    kenv1 = EnvGen.kr(Env.new(
        [ 0.0, 1.1, 1.0 ],
        [ 0.06, 0.2 ],
        'linear' )
    );
    // overall envelope
    kenv2 = EnvGen.kr(Env.asr( 0.1, 1, 0.1, 'linear' ),
        gate, doneAction: 2
    );
    // vibrato envelope
    kenvibr = EnvGen.kr(Env.new(
        [ 0.0, 0.0, 1 ],
        [ 0.5, 0.5 ],
        'linear')
    )*vibrato;

    // create air flow and vibrato
    aflow1 = LFClipNoise.ar( sr, kenv1 );
    kvibr = SinOsc.ar( 5, 0, 0.1 * kenvibr );
    asum1 = ( ibreath * aflow1 ) + ( kenv1 * ipress ) + kvibr;

    afqc = ifqc.reciprocal - ( asum1/20000 ) - ( 9/sr ) + ( ifqc/12000000 ) - block;
    aflute1 = LocalIn.ar( 1 );
    asum2 = asum1 + ( aflute1 * ifeedbk1 );

    //ax = DelayL.ar( asum2, ifqc.reciprocal * 0.5, afqc * 0.5 );
    ax = DelayC.ar( asum2, ifqc.reciprocal - block * 0.5, afqc * 0.5 - ( asum1/ifqc/cr ) + 0.001 );
    apoly = ax - ( ax.cubed );
    asum3 = apoly + ( aflute1 * ifeedbk2 );
    avalue = LPF.ar( asum3, 2000 );
    aflute1 = DelayC.ar( avalue, ifqc.reciprocal - block, afqc );

    LocalOut.ar( [ aflute1 ] );
    signalOut = avalue;
    OffsetOut.ar( 0, [ signalOut * kenv2, signalOut * kenv2 ] );
}).add;
)


//===============================
//   MIDI
//===============================
MIDIIn.connectAll;  // (2)
MIDIIn.disconnectAll;

//  begin to play by MIDI
(
var node, currentNote;

~noteOnFunc = {arg src, chan, num, vel;
    if (node.notNil,
        {
            node.set(\ipress, vel/1000 + 0.8, \pch, num);
            currentNote = num;
            "changePitch".postln;
        },
        {
            node = Synth.tail(nil,
                "waveguideFlute",
                [\amp, 1.0, \ipress, vel/1000 + 0.8, \ibreath, 0.00536,
                \ifeedbk1, 0.4, \ifeedbk2, 0.4, \pch, num, \vibrato, 0.2]);
            currentNote = num;
            "noteon".postln;
        }
    );
    [chan,num,vel].postln;
};
MIDIIn.addFuncTo(\noteOn, ~noteOnFunc);

~noteOffFunc = {arg src, chan, num, vel;
    if (node.notNil,
        {
            if ( currentNote == num,
                {
                    node.release;
                    node = nil;
                    "noteoff".postln;
                }
            )
        } 
    );
    [chan,num,vel].postln;
};
MIDIIn.addFuncTo(\noteOff, ~noteOffFunc);
)  // (3)

// cleanup MIDI
(
MIDIIn.removeFuncFrom(\noteOn, ~noteOnFunc);
MIDIIn.removeFuncFrom(\noteOff, ~noteOffFunc);
)
