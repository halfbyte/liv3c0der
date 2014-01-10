# liv3c0der cheat sheet

## State

    s.init('foo', 0)
    s.foo++

## Effects

### DelayLine

* LC.DelayLine.delayTime.value
* LC.DelayLine.feedback.value
* LC.DelayLine.filterFrequency.value

### ReverbLine

* LC.ReverbLine.mix.value

## Synths

### BassSynth

* LC.BassSynth.flt_f
* LC.BassSynth.flt_a/d/s/r
* LC.BassSynth.flt_env
* LC.BassSynth.flt_Q
* LC.BassSynth.amp_a/d/s/r
* LC.BassSynth.spread
* LC.BassSynth.osc_type

### AcidSynth

* LC.AcidSynth.osc_type
* LC.AcidSynth.decay
* LC.BassSynth.flt_f
* LC.BassSynth.flt_mod
* LC.BassSynth.Q

## Samples


    play: (o, t, l, r=1.0, g=1.0)
    playShot: (o, t, r=1.0, g=1.0)
    playGrain: (o,t,offset, l, r=1.0, g=1.0)

* amen
* dub_
  * base
  * hhcl
  * clapsnare
* p_
  * klang
  * koki
  * tom
* t_
  * base
  * snare
  * clap
  * hhcl
  * hhop
  * ride
  * crash
* livecoder
* ir_t600 (impulse response) 

## Graphics

* LC.cls(c) - clears screen
* LC.hsla(h,s,l,[a]) - builds hsla color screen for fillstyle etc.
  * s, l = 100, 50 full intensity
* LC.centerText(c, text)
* c.font = "bold 100px 'Helvetica Neue'"

