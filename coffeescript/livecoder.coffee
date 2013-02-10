window.LC = {}
LC.NOTES = [ 16.35,    17.32,    18.35,    19.45,    20.6,     21.83,    23.12,    24.5,     25.96,    27.5,  29.14,    30.87,
           32.7,     34.65,    36.71,    38.89,    41.2,     43.65,    46.25,    49,       51.91,    55,    58.27,    61.74,
           65.41,    69.3,     73.42,    77.78,    82.41,    87.31,    92.5,     98,       103.83,   110,   116.54,   123.47,
           130.81,   138.59,   146.83,   155.56,   164.81,   174.61,   185,      196,      207.65,   220,   233.08,   246.94,
           261.63,   277.18,   293.66,   311.13,   329.63,   349.23,   369.99,   392,      415.3,    440,   466.16,   493.88,
           523.25,   554.37,   587.33,   622.25,   659.26,   698.46,   739.99,   783.99,   830.61,   880,   932.33,   987.77,
           1046.5,   1108.73,  1174.66,  1244.51,  1318.51,  1396.91,  1479.98,  1567.98,  1661.22,  1760,  1864.66,  1975.53,
           2093,     2217.46,  2349.32,  2489.02,  2637.02,  2793.83,  2959.96,  3135.96,  3322.44,  3520,  3729.31,  3951.07,
           4186.01,  4434.92,  4698.64,  4978 ]

LC.LEnv = (p,t,l,min, max,a,d,s,r) ->
  return if s < 0 or s > 1
  p.setValueAtTime(min, t)
  p.linearRampToValueAtTime(max, t + (a*l))
  p.linearRampToValueAtTime(min + ((max - min) * s), t + ((a + d)*l))
  p.setValueAtTime(min + ((max - min) * s), t + l - (l*r))
  p.linearRampToValueAtTime(min, t + l)


class AcidSynth
  constructor: (context) ->
    @context = context
    helposc = @context.createOscillator()
    @SAWTOOTH = helposc.SAWTOOTH
    @SQUARE = helposc.SQUARE
    @osc_type = @SAWTOOTH
    @decay = 0.6;
    @flt_f = 300;
    @flt_mod = 4000;
    @Q = 20;

  play: (destination, time, length, note, volume = 0.2) ->
    gain = @context.createGainNode();
    filter1 = @context.createBiquadFilter();
    filter2 = @context.createBiquadFilter();
    osc = @context.createOscillator();
    osc.type = @osc_type
    osc.frequency.value = LC.NOTES[note]

    LC.LEnv(gain.gain, time, length, 0, volume, 0.01, @decay, 0, 0)
    LC.LEnv(filter1.frequency, time, length, @flt_f, @flt_f + @flt_mod, 0.01, @decay, 0, 0)
    LC.LEnv(filter2.frequency, time, length, @flt_f, @flt_f + @flt_mod, 0.01, @decay, 0, 0)



    filter1.Q.value = @Q
    filter2.Q.value = @Q
    osc.connect(filter1)
    filter1.connect(filter2)
    filter2.connect(gain)
    gain.connect(destination)
    osc.noteOn(time)
    osc.noteOff(time+length)



class BassSynth
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
    @flt_env = 2000;
    @flt_Q = 10;

  play: (destination, time, length, note, volume=0.2) ->
    gain = @context.createGainNode();
    filter = @context.createBiquadFilter();
    osc1 = @context.createOscillator();
    osc2 = @context.createOscillator();
    osc1.type = @osc_type
    osc2.type = @osc_type
    osc1.detune.value = @spread
    osc2.detune.value = @spread * -1
    osc1.frequency.value = LC.NOTES[note]
    osc2.frequency.value = LC.NOTES[note]
    LC.LEnv(gain.gain, time, length, 0, volume, @amp_a, @amp_d, @amp_s, @amp_r)
    LC.LEnv(filter.frequency, time, length, @flt_f, (@flt_f + @flt_env), @flt_a, @flt_d, @flt_s, @flt_r)
    filter.Q.value = @flt_Q;
    osc1.connect(filter)
    osc2.connect(filter)
    filter.connect(gain)
    gain.connect(destination)
    osc1.noteOn(time)
    osc2.noteOn(time)
    osc1.noteOff(time+length)
    osc2.noteOff(time+length)




class Reverb
  constructor: (context) ->
    @context = context
    @destination = context.createGainNode();
    @destination.gain.value = 1.0
    @mixer = context.createGainNode()
    @mixer.gain.value = 0.5

    @convolver = context.createConvolver()
    @convolver.connect(@mixer)
    @convolver.buffer = LC.S.ir_t600.buffer
    @destination.connect(@convolver)
    # public properties
    @mix = @mixer.gain
    
  buffer: (buffer) ->
    if @convolver.buffer != buffer
      @convolver.buffer = buffer

  connect: (dest) ->
    @mixer.connect(dest)
    @destination.connect(dest)
    

class Delay
  constructor: (context) ->
    @context = context
    @destination = context.createGainNode();
    @destination.gain = 1.0

    fbGain = context.createGainNode();
    fbGain.gain.value = 0.6

    fbFilter = context.createBiquadFilter();
    fbFilter.type = fbFilter.HIGHPASS;
    fbFilter.frequency.value = 4000.0;
    fbFilter.Q.value = 2.0;

    delay = context.createDelay(10);
    delay.delayTime.value = 0.6;

    @outGain = context.createGainNode();
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



class ImageList
  imageLocations:
    'badge': 'images/moz-shadow-badge.png'
  constructor: ->
    for name, url of @imageLocations
      @[name] = new Image();
      @[name].src = url;


class SampleList
  sampleLocations:
    'amen': 'audio/amen_low.wav'
    'dub_base': 'audio/dub-base.wav'
    'dub_hhcl': 'audio/dub-hhcl.wav'
    'dub_clapsnare': 'audio/dub-clapsnare.wav'
    'ir_t600': 'audio/t600.wav'

  constructor: (audioContext, completeCallback) ->
    @context = audioContext
    @callback = completeCallback
    for name, url of @sampleLocations
      @[name] = new Sample(audioContext, url, @loadedCallback)
  loadedCallback: () =>
    all_loaded = true
    for name, url of @sampleLocations
      all_loaded &&= @[name].loaded
    if all_loaded
      @callback()

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
    gain = @context.createGainNode();
    gain.gain.value = g
    player.connect(gain)
    gain.connect(o)
    player

  play: (o, t, l, r=1.0, g=1.0) ->
    return unless @loaded
    player = @makeBufferSource(o,r, g)
    player.noteOn(t)
    player.noteOff(t + l)
  playShot: (o, t, r=1.0, g=1.0) ->
    return unless @loaded
    player = @makeBufferSource(o,r, g)
    player.noteOn(t)
  playGrain: (o,t,offset, l, r=1.0, g=1.0) ->
    return unless @loaded
    player = @makeBufferSource(o,r, g)
    player.noteGrainOn(t,offset,l)

class State
  init: (k,v) =>
    if not @[k]?
      @[k] = v

new Lawnchair {name: 'livecoder', adapter: 'dom'}, (db) ->
  class LC.LiveCoder
    constructor: (editor, canvas, keylist) ->
      @$el = $(editor)
      @$canvas = $(canvas)
      @$keylist = $(keylist)
      @drawMethod = null
      @oldDrawMethod = null
      @patternMethod = null
      @oldPatternMethod = null
      @deactTimeout = null
      @state = new State()

      @initEditor()
      @initCanvas()
      @initAudio()
      @updateKeyList()


    initEditor: ->
      @editor = ace.edit("editor")
      @editor.setTheme("ace/theme/monokai")
      @editor.getSession().setMode("ace/mode/javascript")
      @editor.container.addEventListener("keydown", @keydown, true)
      @editor.on('focus', @activate)

      @load('default')

      @$keylist.on 'click', "li[data-action='hide']", (e) =>
        @$keylist.toggleClass('hidden')
        @editor.focus()
      @$keylist.on 'click', 'li[data-key]', (e) =>
        @load($(e.target).data('key'))
    load: (key) ->
      db.get key, (data) =>
        @editor.setValue(data.code)
        @editor.focus()

    updateKeyList: ->
      @$keylist.html("<li data-action='hide'>&lt;&lt;&lt;</li>")
      db.keys (keys) =>
        keys.forEach (key) =>
          @$keylist.append("<li data-key='#{key}'>#{key}</li>")

    save: ->
      code = @editor.getValue()
      group = code.match(/NAME: {0,1}([\w _\-]+)?\n/)
      if group
        name = group[1]
      else
        name = "foobar_#{Math.round(Math.random()*1000)}"
      db.save({key: name, code: code})
      @updateKeyList()


    deactivate: =>
      @$el.removeClass('active');

    activate: =>
      @$el.addClass('active');
      clearTimeout(@deactTimeout) if @deactTimeout
      @deactTimeout = setTimeout(@deactivate, 4000)
      return true

    reload: =>
      code = @editor.getValue()
      try
        eval(code)
        @oldDrawMethod = @drawMethod if @drawMethod
        @drawMethod = draw if draw
        @oldPatternMethod = @patternMethod if @patternMethod
        @patternMethod = pattern if pattern
      catch exception
        console.log(exception)

    keydown: (e) =>
      if e.metaKey
        if e.keyCode == 13
          @reload()
        if e.keyCode == 83
          e.preventDefault()
          @save()
        else
          console.log(e)
      @activate()


    initCanvas: ->
      $(window).bind 'resize', =>
          @$canvas.width(window.innerWidth).height(window.innerHeight)
          @$canvas[0].width = window.innerWidth;@$canvas[0].height = window.innerHeight;
          @context.width = @$canvas.width();
          @context.height = @$canvas.height();

      @context = @$canvas[0].getContext('2d');
      @$canvas[0].width = window.innerWidth;@$canvas[0].height = window.innerHeight;
      @context.width = @$canvas.width();
      @context.height = @$canvas.height();

      @context.font = "bold 200px 'Courier New'";

      LC.I = new ImageList();

      @canvasRunLoop()

    canvasRunLoop: =>
      if @drawMethod
        analyserData = new Uint8Array(16)
        @analyser.getByteFrequencyData(analyserData)
        try
          @drawMethod(@context, @state, analyserData)
        catch exception
          console.log(exception)
          if @oldDrawMethod
            @drawMethod = @oldDrawMethod
            @drawMethod(@context, @state, analyserData)
      requestAnimationFrame(@canvasRunLoop)

    initAudio: ->
      @tempo = 120
      @steps = 16
      @groove = 0;
      @audioContext = new webkitAudioContext()
      LC.S = new SampleList(@audioContext, @postSampleInit)
      @analyser = @audioContext.createAnalyser();
      @analyser.fftSize = 64;
      @analyser.smoothingTimeConstant = 0.5;
      @analyser.minDecibels = -100;
      @analyser.maxDecibels = -40;
      @masterGain = @audioContext.createGainNode()
      @masterGain.gain.value = 0.5
      @masterGain.connect(@audioContext.destination)
      @masterGain.connect(@analyser)

      @masterCompressor = @audioContext.createDynamicsCompressor();
      @masterCompressor.connect(@masterGain)


      @tuna = new Tuna(@audioContext)
      LC.Tuna = @tuna

      LC.DelayLine = new Delay(@audioContext)
      LC.DelayLine.connect(@masterGain)


      LC.BassSynth = new BassSynth(@audioContext)
      LC.AcidSynth = new AcidSynth(@audioContext)



      # set this to whatever will be the official outpur
      @masterOutlet = @masterCompressor
      @nextPatternTime = 0

    postSampleInit: =>
      LC.ReverbLine = new Reverb(@audioContext)
      LC.ReverbLine.connect(@masterGain)
      @audioRunLoop()


    audioRunLoop: =>
      @timePerStep = 60 / (4 * @tempo)

      if @nextPatternTime == 0 or @nextPatternTime - @audioContext.currentTime < 0.4
        @nextPatternTime = @audioContext.currentTime if @nextPatternTime == 0
        if @patternMethod

          stepTimes = ((@nextPatternTime + (@timePerStep * i + (if i%2 == 0 then 0 else @groove * @timePerStep))) for i in [0...@steps])
          try
            @patternMethod(@audioContext, @masterOutlet, stepTimes, @timePerStep, @state)
          catch e
            console.log(e)
            if @oldPatternMethod
              @patternMethod = @oldPatternMethod
              @patternMethod(@audioContext, @masterOutlet, stepTimes, @timePerStep, @state)


        @nextPatternTime += @steps * @timePerStep
      setTimeout(@audioRunLoop, 100)

