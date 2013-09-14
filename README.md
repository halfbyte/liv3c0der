## liv3c0der

An experiment to try to build an audiovisual live coding environment running in the browser

Since this was built for the very specific purpose of jamming with other musicians, it is a very opinionated tool at the moment. I'm not sure what it will be evolve into, but here's what it is right now:

* A simple, code based pattern sequencer that has up to 16 steps, shuffle and allows you to express the beat in either declarate
* A set of tools, currently crudely exposed through a global object, that allow for sample playing, synthesizer type stuff and a fixed set of predefined effects
* A fullscreen, initialized 2D canvas that can be drawn on in requestAnimationFrame speed.
* Automatic collection of Samples (for Audio) and Images (for canvas)

Documentation is sparse, please look at the examples.

Currently, the live code contains two methods:

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

### Sample Server

liv3c0der does no longer have any audio assets included. You need to start a seperate compontent to serve assets.

The idea is that hosting samples, especially in high quality, non-lossy-compressed versions on remote servers is possible but not desirable. 

Also this makes using your own samples in liv3c0der really, really easy.

I have a working proof-of-concept written in ruby using sinatra at https://github.com/halfbyte/sample-server.

I would love to turn this into a npm binary or something. Any takers?

#### Protocol

Just serve an index at (this is configurable) http://localhost:4567/index.json that looks like this:

{
  "sample_name": "http://sample-url",
  "sample-name": "..."
}

The only other requirement that you set the "Access-Control-Allow-Origin" header to "*" or wherever you serve liv3c0der, because of CORS.

liv3c0der will then load the index and will try to load all urls specified in the index. You can then access the sample list at AE.S.

### Sound Tools

AudioEngine is both responsible for scheduling the events and a growing collection of more high level building blocks.

This is an almost complete list of the high level bulding blocks, but you probably need to read the source to learn how to use each one.

* AE.NOTES contains the MIDI array of note frequencies, so LC.NOTES[0] gives you the lowest C
* AE.LEnv is an Envelope generator created with linearRamps.
  * Signature is (param,time,length,min, max,attack,decay,sustain,release)
  * a,d,r are expressed as fractions of length
  * sustain as fraction of max

* AE.S is an object containing all loaded samples. See above.
* All samples willl be loaded automatically and can be played as soon as they are completely decoded.
* AE.S['<samplename>'] or AE.S.<samplename> is a sample object that has three public methods:
  * play(outlet, time, length, rate)
  * playGrain(outlet, time, offset, length, rate)
  * playShot(outlet, time, rate, volume)
* AE.DelayLine - a configurable delay line that can be used as an output
  * DelayLine.delayTime
  * DelayLine.filterFrequency
  * DelayLine.feedback
* AE.ReverbLine - a configurable reverb line that can be used as an output
  * ReverbLine.mix - mix ratio between original and reverb signal. This is the AudioPAram

* AE.DEL and AE.REV are shortcuts for the inputs of DelayLine and ReverbLine.

* AE.SpreadSynth (will be renamed!) is a dual oscillator synth with full ENVs for amp and filter
* AE.AcidSynth is a single osc synth with a double filter for enhanced squeakability. It has a more simple envelope.
* AE.SawSynth is a configurable "Super Saw" synth with a large number or Sawtooth oscillators all slightly detuned.
* AE.WubSynth is your one-stop-shop Dubstep synth. You wish. It's just a square wave with a lfo driven lowpass.

* AE.DrumSynth is a single oscillator drum synthesizer capable of rendering convincing synthetic bass drums but also toms and random bleeps.
* AE.SnareSynth is a DrumSynth with filtered white noise on top to generate simple snares
* AE.NoiseHat is a simple noise based hihat/cymbal synth that sounds best with high resonance.

* AE.Instance.tempo can be set to the desired tempo in BPM.
* AE.Instance.groove can be set to any value between 0 and 1 to delay each second step in a pattern by a certain percentage to create a shuffled rythm.

* AE.Tuna. See [here](https://github.com/Dinahmoe/tuna), please let it be Tuna. AE.Tuna is an initialized Tuna instance.

### Canvas Tools

This also needs a way to serve images from the outside. Currently the image list is still hardcoded.

* LC.I.<imagename> is an Image() instance that can be used for context.drawImage
* LC.hsla is a simple utility to not deal with string concatenation when creating colors for the canvas
* LC.cls clears the canvas
* LC.centerText centers a given text on the screen

