window.AE = {}

AE.NOTES = [ 16.35,    17.32,    18.35,    19.45,    20.6,     21.83,    23.12,    24.5,     25.96,    27.5,  29.14,    30.87,
           32.7,     34.65,    36.71,    38.89,    41.2,     43.65,    46.25,    49,       51.91,    55,    58.27,    61.74,
           65.41,    69.3,     73.42,    77.78,    82.41,    87.31,    92.5,     98,       103.83,   110,   116.54,   123.47,
           130.81,   138.59,   146.83,   155.56,   164.81,   174.61,   185,      196,      207.65,   220,   233.08,   246.94,
           261.63,   277.18,   293.66,   311.13,   329.63,   349.23,   369.99,   392,      415.3,    440,   466.16,   493.88,
           523.25,   554.37,   587.33,   622.25,   659.26,   698.46,   739.99,   783.99,   830.61,   880,   932.33,   987.77,
           1046.5,   1108.73,  1174.66,  1244.51,  1318.51,  1396.91,  1479.98,  1567.98,  1661.22,  1760,  1864.66,  1975.53,
           2093,     2217.46,  2349.32,  2489.02,  2637.02,  2793.83,  2959.96,  3135.96,  3322.44,  3520,  3729.31,  3951.07,
           4186.01,  4434.92,  4698.64,  4978 ]


AE.LEnv = (p,t,l,min, max,a,d,s,r) ->
  return if s < 0 or s > 1
  p.setValueAtTime(min, t)
  p.linearRampToValueAtTime(max, t + (a*l))
  p.linearRampToValueAtTime(min + ((max - min) * s), t + ((a + d)*l))
  p.setValueAtTime(min + ((max - min) * s), t + l - (l*r))
  p.linearRampToValueAtTime(min, t + l)
  

class NoiseNode
  @makeBuffer: (ac, length = 1) ->
    @buffer = ac.createBuffer(1, 44100 * length, 44100)
    array = @buffer.getChannelData(0);
    for word,i in array
      array[i] = Math.random() * 2 - 1
    @buffer
    
  constructor: (@ac, @buffer) ->
    @ac = ac
    
    unless @buffer
      console.log("Making Buffer")
      @buffer = NoiseNode.makeBuffer(@ac, 1)    
  connect: (dest) =>
    @dest = dest
  start: (time) =>
    @source  = @ac.createBufferSource();
    @source.buffer = @buffer;
    @source.start(time)
    @source.connect(@dest)
  stop: (time) =>
    @source.stop(time)
  
class NoiseHat
  constructor: (@context, @noise) ->
    console.log(@context, @noise)

  play: (output, time, volume=0.1, decay = 20, freq = 6000, Q = 5) ->
    decayTime = time + (0.5 / decay);
    noise = new NoiseNode(@context, @noise)
    filter = @context.createBiquadFilter();
    filter.type = "bandpass";
    filter.frequency.value = freq;
    filter.Q.value = Q;
    amp = @context.createGain();
    noise.connect(filter);
    filter.connect(amp);
    amp.connect(output);
    amp.gain.setValueAtTime(0, time);
    amp.gain.linearRampToValueAtTime(volume, time + 0.001);
    amp.gain.setValueAtTime(volume, time + 0.001);    
    amp.gain.linearRampToValueAtTime(0, decayTime)
    noise.start(time);
    noise.start(decayTime);

class DrumSynth
  constructor: (@context) ->
  
  play: (output, time, volume = 0.5, fDecay = 20, aDecay = 20, start = 200, end = 50) ->
    fDecayTime = time + (1 / fDecay)
    aDecayTime = time + (1 / aDecay)
    sine = @context.createOscillator()
    amp = @context.createGain()
    sine.connect(amp)
    amp.connect(output)
    sine.frequency.setValueAtTime(start, time);
    sine.frequency.exponentialRampToValueAtTime(end, fDecayTime);
    amp.gain.setValueAtTime(0, time);
    amp.gain.linearRampToValueAtTime(volume, time + 0.001);
    amp.gain.linearRampToValueAtTime(0, aDecayTime);
    sine.start(time);
    sine.stop(aDecayTime);

class SnareSynth
  constructor: (@context, @noise) ->
    @drumsyn = new DrumSynth(@context)
    @flt_f = 1000
    @flt_Q = 5
  
  play: (output, time, volume = 0.5, fDecay = 20, aDecay = 20, start = 200, end = 50) ->
    aDecayTime = time + (1 / aDecay)
    amp = @context.createGain()
    amp.connect(output)
    noise = new NoiseNode(@context, @noise)
    filter = @context.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.value = @flt_f;
    filter.Q.value = @flt_Q;
    noise.connect(filter)
    
    amp.gain.setValueAtTime(0, time);
    amp.gain.linearRampToValueAtTime(volume, time + 0.001);
    amp.gain.linearRampToValueAtTime(0, aDecayTime);
    filter.connect(amp)
    noise.start(time)
    noise.stop(aDecayTime)
    @drumsyn.play(output, time, volume, fDecay, aDecay, start, end)    

class WubSynth
  constructor: (@context) ->
    @osc_type = 'square'
    @lfo_type = 'sine'
    @decay = 0.9
    @flt_f = 200
    @flt_decay = 0.8
    @flt_mod = 500
    @flt_lfo_mod = 500
    @lfo_f = 200;
    @flt_Q = 10
  play: (destination, time, length, note, volume = 0.2) ->
    osc = @context.createOscillator()
    lfo = @context.createOscillator()
    filter = @context.createBiquadFilter()
    osc.type = @osc_type
    lfo.type = @lfo_type
    amp = @context.createGain()
    lfoAmp = @context.createGain()
    lfo.connect(lfoAmp)
    lfoAmp.connect(filter.frequency)
    osc.frequency.value = AE.NOTES[note]
    filter.Q.value = @flt_Q
    filter.frequency.setValueAtTime(@flt_f + @flt_mod, time)
    filter.frequency.linearRampToValueAtTime(@flt_f + @flt_mod, time + @flt_decay)
    osc.connect(filter)
    filter.connect(amp)
    amp.connect(destination)
    lfo.frequency.value = @lfo_f
    console.log(lfo.frequency.value);
    lfoAmp.gain.value = @flt_lfo_mod
    console.log(lfoAmp.gain.value);
    amp.gain.setValueAtTime(0, time);
    amp.gain.linearRampToValueAtTime(volume, time + 0.001);
    amp.gain.setValueAtTime(volume, time + length - @decay);
    amp.gain.linearRampToValueAtTime(0, time + length);
    osc.start(time);
    osc.stop(time + length);
    lfo.start(time);
    lfo.stop(time + length);
    
    

class AcidSynth
  constructor: (context) ->
    @context = context
    helposc = @context.createOscillator()
    @osc_type = 'sawtooth';
    @decay = 0.6;
    @flt_f = 300;
    @flt_mod = 4000;
    @flt_Q = 10;

  play: (destination, time, length, note, volume = 0.2) ->
    gain = @context.createGain();
    filter1 = @context.createBiquadFilter();
    filter2 = @context.createBiquadFilter();
    osc = @context.createOscillator();
    osc.type = @osc_type
    osc.frequency.value = AE.NOTES[note]

    AE.LEnv(gain.gain, time, length, 0, volume, 0.01, @decay, 0, 0)
    AE.LEnv(filter1.frequency, time, length, @flt_f, @flt_f + @flt_mod, 0.01, @decay, 0, 0)
    AE.LEnv(filter2.frequency, time, length, @flt_f, @flt_f + @flt_mod, 0.01, @decay, 0, 0)

    filter1.Q.value = @flt_Q
    filter2.Q.value = @flt_Q
    osc.connect(filter1)
    filter1.connect(filter2)
    filter2.connect(gain)
    gain.connect(destination)
    osc.start(time)
    osc.stop(time+length)

class SawSynth
  constructor: (context) ->
    @context = context

    # Params
    @spread = 10;
    @osc_type = 'sawtooth'
    @voices = 5;
    @amp_a = 0.05;
    @amp_d = 0.3;
    @amp_s = 0.8;
    @amp_r = 0.1;

    @flt_a = 0.01;
    @flt_d = 0.1;
    @flt_s = 1.0;
    @flt_r = 0.01;
    @flt_f = 4000;
    @flt_mod = 3000;
    @Q = 0;

  play: (destination, time, length, note, volume=0.1) ->
    gain = @context.createGain();
    filter = @context.createBiquadFilter();
    osc = @context.createOscillator();
    osc.type = 'sawtooth'
    osc.frequency.value = AE.NOTES[note]
    oscs = [osc]
    for i in [0...@voices]
      osc1 = @context.createOscillator()
      osc2 = @context.createOscillator()
      osc1.type = 'sawtooth'
      osc2.type = 'sawtooth'
      osc1.detune.value = @spread * i
      osc2.detune.value = @spread * i * -1
      osc1.frequency.value = AE.NOTES[note]
      osc2.frequency.value = AE.NOTES[note]
      oscs.push(osc1,osc2)

    AE.LEnv(gain.gain, time, length, 0, volume, @amp_a, @amp_d, @amp_s, @amp_r)
    AE.LEnv(filter.frequency, time, length, @flt_f, (@flt_f + @flt_mod), @flt_a, @flt_d, @flt_s, @flt_r)
    filter.Q.value = @Q;
    filter.connect(gain)
    gain.connect(destination)
    for osc in oscs
      osc.connect(filter)
      osc.start(time)
      osc.stop(time + length)


class SpreadSynth
  constructor: (context) ->
    @context = context
    helposc = @context.createOscillator()
    @SAWTOOTH = helposc.SAWTOOTH
    @SINE = helposc.SINE
    @SQUARE = helposc.SQUARE
    @TRIANGLE = helposc.TRIANGLE

    # Params
    @spread = 10;
    @osc_type = @SAWTOOTH;
    @amp_a = 0.01;
    @amp_d = 0.1;
    @amp_s = 0.8;
    @amp_r = 0.1;

    @flt_a = 0.01;
    @flt_d = 0.1;
    @flt_s = 0.8;
    @flt_r = 0.01;
    @flt_f = 500;
    @flt_mod = 2000;
    @flt_Q = 10;

  play: (destination, time, length, note, volume=0.1) ->
    gain = @context.createGain();
    filter = @context.createBiquadFilter();
    osc1 = @context.createOscillator();
    osc2 = @context.createOscillator();
    osc1.type = @osc_type
    osc2.type = @osc_type
    osc1.detune.value = @spread
    osc2.detune.value = @spread * -1
    osc1.frequency.value = AE.NOTES[note]
    osc2.frequency.value = AE.NOTES[note]
    AE.LEnv(gain.gain, time, length, 0, volume, @amp_a, @amp_d, @amp_s, @amp_r)
    AE.LEnv(filter.frequency, time, length, @flt_f, (@flt_f + @flt_mod), @flt_a, @flt_d, @flt_s, @flt_r)
    filter.Q.value = @flt_Q;
    osc1.connect(filter)
    osc2.connect(filter)
    filter.connect(gain)
    gain.connect(destination)
    osc1.start(time)
    osc2.start(time)
    osc1.stop(time+length)
    osc2.stop(time+length)

class Reverb
  constructor: (context, options = {}) ->
    
    @context = context
    @destination = context.createGain();
    @destination.gain.value = 1.0
    @mixer = context.createGain()
    @mixer.gain.value = 0.3
    
    buffer = options.buffer

    if not buffer
      console.log("No buffer given, falling back on synthetic one")
      # code based on https://github.com/mattdiamond/synthjs/
      seconds = options.length or 2;
      sampleRate = context.sampleRate
      length = sampleRate * seconds
      buffer = context.createBuffer(2, length, sampleRate)
      impulseL = buffer.getChannelData(0)
      impulseR = buffer.getChannelData(1)
      decay = options.decay or 5
      for i in [0...length]
        impulseL[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, decay)
        impulseR[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, decay)

    @convolver = context.createConvolver()
    @convolver.connect(@mixer)
    @convolver.buffer = buffer
    @destination.connect(@convolver)
    # public properties
    @mix = @mixer.gain

  buffer: (buffer) ->
    if @convolver.buffer != buffer
      @convolver.buffer = buffer

  connect: (dest) ->
    @mixer.connect(dest)
    @destination.connect(dest)

class AE.LfoFilter
  constructor: (context, options = {}) ->
    @context = context
    @filter = context.createBiquadFilter()
    @lfo = context.createOscillator()
    lfo_amp = context.createGain()
    
    @lfo.connect(lfo_amp)
    lfo_amp.connect(@filter.frequency)
    
    @lfo_gain = lfo_amp.gain
    @lfo_freq = @lfo.frequency 
    
    @frequency = @filter.frequency
    @Q = @filter.Q
        
    @lfo_freq.value = options.lfo_freq or 0.11
    @lfo.type = options.lfo_type or 'sine'
    @lfo_gain.value = options.lfo_gain or 0
    @filter.type = options.type or 'lowpass'
    @frequency = options.frequency or 500
    @Q = options.Q or 5
    @destination = @filter
    
    @lfo.start(0)
    
  connect: (destination) ->
    @filter.connect(destination)
    

    



class Delay
  constructor: (context) ->
    @context = context
    @destination = context.createGain();
    @destination.gain = 1.0

    fbGain = context.createGain();
    fbGain.gain.value = 0.6

    fbFilter = context.createBiquadFilter();
    fbFilter.type = fbFilter.HIGHPASS;
    fbFilter.frequency.value = 4000.0;
    fbFilter.Q.value = 2.0;

    delay = context.createDelay(10);
    delay.delayTime.value = 0.6;

    @outGain = context.createGain();
    @outGain.gain.value = 0.4

    # connect

    @destination.connect(delay)

    delay.connect(@outGain)
    delay.connect(fbFilter)
    fbFilter.connect(fbGain)
    fbGain.connect(delay)

    # public properties
    @feedback = fbGain.gain
    @delayTime = delay.delayTime
    @filterFrequency = fbFilter.frequency
    @output = @outGain.gain

  connect: (dest) ->
    @outGain.connect(dest)
    @destination.connect(dest)


class SampleList

  constructor: (@audioContext, @baseUrl = "http://localhost:4567", @progressCallback = null, @completeCallback = null, @errorCallback) ->
    @callback = completeCallback
    @names = []
    console.log(@callback)
    $.getJSON(@baseUrl, {}, @_listLoaded).fail(@_listError)
  _listError: () =>
    console.log("Failed to Load Sample List");
    @errorCallback('sample list could not be loaded, did you start the server?') if @errorCallback
  _listLoaded: (data) =>
    console.log(data);
    @sampleLocations = data
    @sampleCount = Object.keys(data).length;
    for name, url of data
      @[name] = new Sample(@audioContext, url, @_loadedCallback)
      @names.push(name)
  _loadedCallback: () =>
    loadedCount = 0
    all_loaded = true
    for name, url of @sampleLocations
      if @[name].loaded
        loadedCount += 1
      all_loaded &&= @[name].loaded
    console.log(loadedCount, @sampleCount)
    @progressCallback(Math.round((loadedCount / @sampleCount) * 100.0)) if @progressCallback
    if all_loaded
      @completeCallback("ok") if @completeCallback

class Sample
  constructor: (audioContext, url, loadedCallback) ->
    @context = audioContext
    @url = url
    @loaded = false
    @error = null
    @load()
    @callback = loadedCallback

  load: =>
    @request = new XMLHttpRequest()
    @request.open("GET", @url, true)
    @request.responseType = "arraybuffer"
    @request.onload = @decode
    @request.send()

  decode: =>
    @context.decodeAudioData(@request.response, @onDecode, @onDecodingError)

  onDecode: (buffer) =>
    @buffer = buffer
    @loaded = true
    @callback(@url)

  onDecodingError: (error) =>
    console.log("error decoding", @url, error)
    @error = error

  makeBufferSource: (o,r, g) ->
    player = @context.createBufferSource(@buffer)
    player.buffer = @buffer
    player.playbackRate.value = r
    gain = @context.createGain();
    gain.gain.value = g
    player.connect(gain)
    gain.connect(o)
    player

  play: (o, t, l, r=1.0, g=0.4) ->
    return unless @loaded
    player = @makeBufferSource(o,r, g)
    player.start(t)
    player.stop(t + l)
  playShot: (o, t, r=1.0, g=0.4) ->
    return unless @loaded
    player = @makeBufferSource(o,r, g)
    player.start(t)
  playGrain: (o,t,offset, l, r=1.0, g=0.4) ->
    return unless @loaded
    player = @makeBufferSource(o,r, g)
    player.noteGrainOn(t,offset,l)

class AE.Engine
  constructor: (@state, @sampleProgressCallback = null, @sampleFinishedCallback = null, @sampleErrorCallback = null) ->
    @tempo = 120
    @steps = 16
    @groove = 0;
    @audioContext = new AudioContext()
    console.log("PSI", @postSampleInit)
    console.log("GAD", @getAnalyserData)
    AE.S = new SampleList(@audioContext, "http://localhost:4567/index.json", @sampleProgressCallback, @postSampleInit, @sampleLoadError)
    @analyser = @audioContext.createAnalyser();
    @analyser.fftSize = 64;
    @analyser.smoothingTimeConstant = 0.5;
    @analyser.minDecibels = -100;
    @analyser.maxDecibels = -40;
    @masterGain = @audioContext.createGain()
    @masterGain.gain.value = 0.5
    @masterGain.connect(@audioContext.destination)
    @masterGain.connect(@analyser)

    @masterCompressor = @audioContext.createDynamicsCompressor();
    @masterCompressor.connect(@masterGain)

    @patternMethod = null
    @oldPatternMethod = null
    
    if window.Tuna
      AE.Tuna = new Tuna(@audioContext);
    
    @noiseBuffer = NoiseNode.makeBuffer(@audioContext, 2)

    AE.DelayLine = new Delay(@audioContext)
    AE.DelayLine.connect(@masterGain)
    AE.DEL = AE.DelayLine.destination
    AE.Arp = (notes, t, l, n, fun) ->
      for i in [0...n]
        note = notes[i % notes.length]
        fun(t + i*l, note)
        

    AE.NoiseHat = new NoiseHat(@audioContext, @noiseBuffer)
    AE.DrumSynth = new DrumSynth(@audioContext)
    AE.SnareSynth = new SnareSynth(@audioContext, @noiseBuffer)
    
    AE.SawSynth = new SawSynth(@audioContext)
    AE.SpreadSynth = new SpreadSynth(@audioContext)
    AE.AcidSynth = new AcidSynth(@audioContext)
    AE.WubSynth = new WubSynth(@audioContext)
  
    @masterOutlet = @masterCompressor
    @nextPatternTime = 0
    console.log("AE init done")

  getAnalyserData: (data) =>
    @analyser.getByteFrequencyData(data)
    data

  lateInit: => 
    AE.ReverbLine = new Reverb(@audioContext, {buffer: @reverbBuffer, decay: 5})
    AE.ReverbLine.connect(@masterGain)
    
    dub_delay = new Delay(@audioContext)
    dub_reverb = new Reverb(@audioContext, {decay: 2, length: 5})
    dub_delay.connect(dub_reverb.destination)
    dub_reverb.connect(@masterGain)
    
    AE.DubLine = {delay: dub_delay, reverb: dub_reverb}
    AE.DUB = AE.DubLine.delay.destination
    AE.REV = AE.ReverbLine.destination
    @sampleFinishedCallback() if @sampleFinishedCallback
    @audioRunLoop()

  postSampleInit: =>
    @reverbBuffer = if AE.S.t600? then AE.S.t600.buffer else null
    @lateInit();

  sampleLoadError: (message) =>
    @reverbBuffer = null
    @lateInit()
    @sampleErrorCallback(message) if @sampleErrorCallback?
  
  setPatternMethod: (patternMethod) =>
    @oldPatternMethod = @patternMethod
    @patternMethod = patternMethod
  
  audioRunLoop: =>
    @timePerStep = 60 / (4 * @tempo)

    if @nextPatternTime == 0 or @nextPatternTime - @audioContext.currentTime < 0.4
      @nextPatternTime = @audioContext.currentTime if @nextPatternTime == 0
      if @patternMethod

        stepTimes = ((@nextPatternTime + (@timePerStep * i + (if i%2 == 0 then 0 else @groove * @timePerStep))) for i in [0...@steps])
        try
          @patternMethod(@audioContext, @masterOutlet, stepTimes, @timePerStep, @state)
        catch e
          console.log(e, e.message);
          console.log(e.stack);
          if @oldPatternMethod
            @patternMethod = @oldPatternMethod
            @patternMethod(@audioContext, @masterOutlet, stepTimes, @timePerStep, @state)


      @nextPatternTime += @steps * @timePerStep
    setTimeout(@audioRunLoop, 100)
