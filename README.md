## liv3c0der

A try to build an audiovisual live coding environment that's running in the browser

Documentation is sparse, please look at the examples.

Currently, the live code should contain two methods:

draw(canvasContext,state, analyzerData)
* draw will be called within the canvas loop that is based on requestAnimationFrame
* canvasContext is the 2d context of the full screen canvas element (only 2d is supported ATM)
* state is a magical state object you can use to store data that should persist between loop runs
  * state has an init-function that let's you init values if they are not yes existent.
* analyserData is a 16 element float32array of fft data from the sound source. do your thang.

pattern(context, outlet, start_times, step_time, state, data)
* pattern will be called once every time the pattern loops. The pattern is (currently) a 16 step
* pattern with every step matching a 1/16 note.
* *context* is the audioContext
* *outlet* is the audio destination your webaudio objects should ultimately connect to
* *start_times* is an array of start times for the notes in the pattern
* *step_time* is the length of a single step
* *state* is the beforementioned state object (note that the canvas loop and the pattern loop indeed share this object)
* *data* is unused and will most probably contain prefabbed samples etc.


### Sound Tools

* LC.NOTES contains the MIDI array of note frequencies, so LC.NOTES[0] gives you the lowest C
* LC.LEnv is an Envelope generator created with linearRamps.
  * Signature is (param,time,length,min, max,attack,decay,sustain,release)
  * a,d,r are expressed as fractions of length
  * sustain as fraction of max

* LC.S is an object containing all loaded samples. The list is currently hardcoded in livecoder.coffee
* All samples willl be loaded automatically and can be played as soon as they are completely decoded.
* LC.S.<samplename> is a sample object that has two public methods
  * play(outlet, time, length, rate)
  * playGrain(outlet, time, offset, length, rate)
* LC.DelayLine - a configurable delay line that can be used as an output
  * DelayLine.delayTime
  * DelayLine.filterFrequency
  * DelayLine.feedback


### Planned sound tools


* LC.ReverbLine - a configurable reverb line that can be used as an output

