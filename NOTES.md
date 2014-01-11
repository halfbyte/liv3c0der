# liv3c0der cheat sheet

## State

    s.init('foo', 0)
    s.foo++

## Effects

### DelayLine

* AE.DelayLine.delayTime.value
* AE.DelayLine.feedback.value
* AE.DelayLine.filterFrequency.value

### ReverbLine

* AE.ReverbLine.mix.value

## Synths

### BassSynth

* AE.BassSynth.flt_f
* AE.BassSynth.flt_a/d/s/r
* AE.BassSynth.flt_env
* AE.BassSynth.flt_Q
* AE.BassSynth.amp_a/d/s/r
* AE.BassSynth.spread
* AE.BassSynth.osc_type

### AcidSynth

* AE.AcidSynth.osc_type
* AE.AcidSynth.decay
* AE.BassSynth.flt_f
* AE.BassSynth.flt_mod
* AE.BassSynth.Q

## Samples

    AE.S['sample_name_] or AE.S.sample_name 

is the sample object that has the following methods to play:

    play: (o, t, l, r=1.0, g=1.0)
    playShot: (o, t, r=1.0, g=1.0)
    playGrain: (o,t,offset, l, r=1.0, g=1.0)

## Graphics

* LC.cls(c) - clears screen
* LC.hsla(h,s,l,[a]) - builds hsla color screen for fillstyle etc.
  * s, l = 100, 50 full intensity
* LC.centerText(c, text)
* c.font = "bold 100px 'Helvetica Neue'"
