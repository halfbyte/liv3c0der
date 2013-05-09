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

############### CANVAS HELPERS ###################

LC.clamp = (v, min, max) ->
  Math.min(Math.max(v,min), max)

LC.hsla = (h,s,l,a=1.0) ->
  h = h % 360;
  return "hsla(#{h},#{s}%,#{l}%,#{a})"

LC.cls = (c)->
  c.clearRect(0,0,c.width, c.height)

LC.centerText = (c, text) ->
  c.textBaseline = "middle"

  m = c.measureText(text)
  x = (c.width / 2) - (m.width / 2)
  y = (c.height / 2)
  c.fillText(text, x, y, c.width)


class LeapObserver
  constructor: ->  
    @listeners = []

  reset: ->
    @listeners = []

  traverse: (obj, path) ->
    nextobj = obj[path[0]]
    return null if !nextobj
    nextpath = path.slice(1)
    return nextobj if nextpath.length == 0
    @traverse(nextobj, nextpath)
    
  attach: (obj, attr, framepath, factor, min, max) ->
    @listeners.push({object: obj, attribute: attr, framepath: framepath, factor: factor, min: min, max: max})
    
  frame: (frame) ->
    @lastFrame = frame
    for listener in @listeners
      value = @traverse(frame, listener.framepath)
      continue if not value?
      if listener.min >= 0
        value = Math.abs(value)
      value = LC.clamp(value * listener.factor, listener.min, listener.max)
      listener.object[listener.attribute].value = value
  
    

class ImageList
  imageLocations:
    'badge': 'images/moz-shadow-badge.png'
    'book': 'images/tspa_jumpstart.jpg'
  constructor: ->
    for name, url of @imageLocations
      @[name] = new Image();
      @[name].src = url;

class State
  init: (k,v) =>
    if not @[k]?
      @[k] = v

new Lawnchair {name: 'livecoder', adapter: 'dom'}, (db) ->
  class LC.LiveCoder
    constructor: (editor, canvas, keylist, samplelist) ->
      
      @$el = $(editor)
      @$canvas = $(canvas)
      @$keylist = $(keylist)
      @$samplelist = $(samplelist)
      @drawMethod = null
      @oldDrawMethod = null
      @deactTimeout = null
      @state = new State()
      @analyserData = new Uint8Array(16);
      if Leap?
        @leapController = new Leap.Controller();

      AE.Instance = @audioEngine = new AE.Engine(@state, @sampleProgress, @samplesFinished, @sampleError)
      $('#progress').addClass('in-progress')
      $('#progress-label').text("Loading Samples")
      @initEditor()
      @initCanvas()
      @updateKeyList()
      
    load_from_hash: =>
      console.log("load from hash #{location.hash}")
      if location.hash != ''
        key = location.hash.substr(1)
        @load(key)
      else
        @load('default')

    sampleProgress: (percent) ->
      $('#progress-meter').val(percent)
      console.log("Sample Progress", percent)

    samplesFinished: =>
      console.log("All Samples Loaded")
      $('#progress').removeClass('in-progress');
      @$samplelist.append("<li data-action='hide'>&gt;&gt;&gt;</li>")
      for key in AE.S.names
        @$samplelist.append("<li>#{key}</li>")
    sampleError: (msg) =>
      $('#progress').removeClass('in-progress');
      @displayMessage(msg)

    initEditor: ->
      @editor = ace.edit("editor")
      @editor.setTheme("ace/theme/monokai")
      @editor.getSession().setMode("ace/mode/javascript")
      @editor.container.addEventListener("keydown", @keydown, true)
      @editor.on('focus', @activate)



      @load_from_hash()

      @$samplelist.on 'click', "li[data-action='hide']", (e) =>
        @$samplelist.toggleClass('hidden')
        @editor.focus()

      @$keylist.on 'click', "li[data-action='hide']", (e) =>
        @$keylist.toggleClass('hidden')
        @editor.focus()
      $(window).bind 'hashchange', @load_from_hash
    load: (key) ->
      db.get key, (data) =>
        if data
          @editor.setValue(data.code)
          @editor.focus()

    updateKeyList: ->
      @$keylist.html("<li data-action='hide'>&lt;&lt;&lt;</li>")
      db.keys (keys) =>
        keys.forEach (key) =>
          @$keylist.append("<li data-key='#{key}'><a href='##{key}'>#{key}</a></li>")

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
      # @$el.removeClass('active');

    activate: =>
      @$el.addClass('active');
      clearTimeout(@deactTimeout) if @deactTimeout
      @deactTimeout = setTimeout(@deactivate, 4000)
      return true

    reload: =>
      @save()
      code = @editor.getValue()
      try
        eval(code)
        @oldDrawMethod = @drawMethod if @drawMethod
        @drawMethod = draw if draw
        @audioEngine.setPatternMethod(pattern) if pattern
      catch exception
        console.log(exception, exception.message)

    keydown: (e) =>
      if e.metaKey
        if e.keyCode == 13
          @reload()
        if e.keyCode == 83
          e.preventDefault()
          @save()
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

      if Leap?
        @leapController.on 'animationFrame', @canvasRunLoop
        @leapController.connect()
      else
        @canvasRunLoop()
        
      LC.LO = @leapObserver = new LeapObserver()

      


    canvasRunLoop: (frame) =>
      if Leap?
        @leapObserver.frame(frame)
      if @drawMethod        
        try
          @audioEngine.getAnalyserData(@analyserData)
          @drawMethod(@context, @state, @analyserData, frame)
        catch exception
          @displayMessage(exception.toString() + ": " + exception.message)
          if @oldDrawMethod
            @drawMethod = @oldDrawMethod
            @drawMethod(@context, @state, @analyserData)
      if not Leap?
        (requestAnimationFrame||webkitRequestAnimationFrame||mozRequestAnimationFrame)(@canvasRunLoop)



    displayMessage: (message) =>
      console.log("new Message: ", message)
      if $('.message').length == 0
        $('body').append($("<div class='message'></div>"))
      $('.message').append("<p>#{message}</p>")
      setTimeout(@removeMessage, 5000)

    removeMessage: =>
      if $('.message p').length > 1
        $('.message p:first-child').remove();
      else
        $('.message').remove();
            

