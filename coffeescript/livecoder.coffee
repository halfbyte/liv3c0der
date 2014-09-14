window.LC = {}

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
      @skip_load_from_hash = false
      @analyserData = new Uint8Array(16);
      @current_name = 'default'
      if Leap?
        @leapController = new Leap.Controller();

      AE.Instance = @audioEngine = new AE.Engine(@state, @sampleProgress, @samplesFinished, @sampleError)
      AE.Instance.displayMessage = @displayMessage
      AE.Instance.removeMessage = @removeMessage
      $('#progress').addClass('in-progress')
      $('#progress-label').text("Loading Samples")
      @initEditor()
      @initCanvas()
      @updateKeyList()
      
    load_from_hash: =>
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
      return if key == @current_name
      console.log("load", key)
      prefixPos = key.indexOf("gist:");
      if prefixPos != -1
        @load_from_gist(key.substr(prefixPos + 5));
      else
        db.get key, (data) =>
          if data
            @current_name = key
            @editor.setValue(data.code)
            @editor.focus()

    load_from_gist: (url) =>
      fullUrl = "https://gist.githubusercontent.com" + url;
      console.log("load from url", fullUrl);
      $.get fullUrl, {}, (data) =>
        answer = confirm("You're loading in Data from an untrusted source. Please make sure that you're checking the code before executing!");
        if answer
          @editor.setValue(data)
          @editor.gotoLine(1)
          @editor.focus()
          
          @save()
        else
          location.hash = 'default'
        

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
      console.log("SAVE", name)
      db.save({key: name, code: code})
      @updateKeyList()
      
      @current_name = name
      location.hash = name


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
      if e.metaKey || e.ctrlKey
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

      @canvasRunLoop()

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
            requestAnimationFrame(@canvasRunLoop)


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
            

