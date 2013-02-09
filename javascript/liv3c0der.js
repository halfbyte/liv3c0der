$(function() {
    var deactivate = function(e) {
        $('#editor').removeClass('active');
    };
    var drawMethod = null;
    var oldDrawMethod = null;
    var patternMethod = null;
    var oldPatternMethod = null;
    var timeout = null;
    var activate = function(e) {
        console.log("keypressed")
        $('#editor').addClass('active');
        if(timeout) {
            clearTimeout(timeout);
        }
        timeout = setTimeout(deactivate, 4000);
        return true;
    };
    var reload = function() {
        var code = editor.getValue();
        try {
            eval(code);
            if (drawMethod) oldDrawMethod = drawMethod;
            if (draw) drawMethod = draw;
            if (patternMethod) oldPatternMethod = patternMethod;
            if (pattern) patternMethod = pattern;
        } catch(e) {
            console.log(e);
        }

    }
    var keydown = function(e) {
        if(e.metaKey && e.keyCode == 13) {
            reload();
        }
        activate(e);
    }
    var editor = ace.edit("editor");
    editor.setTheme("ace/theme/monokai");

    editor.getSession().setMode("ace/mode/javascript");
    editor.container.addEventListener("keydown", keydown, true)
    // $(window).keydown(activate);
    editor.on('focus', activate);
    $(window).bind('resize', function() {
        $('#canvas').width(window.innerWidth).height(window.innerHeight);
    })
    var c = $('#canvas')[0].getContext('2d');
    c.width = 1024;
    c.height = 768;
    console.log(c.width, c.height);
    var state = {
        init: function(name, value) {
            if (typeof(this[name]) == 'undefined') this[name] = value;
        }
    };
    var canvasRunLoop = function() {
        if(drawMethod) {
            try {
                drawMethod(c, state);
            } catch(e) {
                console.log(e.lineNumber);
                if (oldDrawMethod) {
                    drawMethod = oldDrawMethod;
                    drawMethod(c, state);
                }
            }
        }
        requestAnimationFrame(canvasRunLoop);
    }
    canvasRunLoop();
    var tempo = 120;

    var steps = 16;
    var timePerPattern = steps / 4 / (tempo/60);
    var timePerStep = timePerPattern / steps;
    var ac =  new webkitAudioContext();
    var masterGain = ac.createGainNode();
    masterGain.gain.value = 0.5;
    masterGain.connect(ac.destination);
    var outlet = masterGain;
    var nextPattern = 0;
    var audioRunLoop = function() {
        if (nextPattern == 0 || (nextPattern - ac.currentTime) < 0.8) {
            if (nextPattern == 0) nextPattern = ac.currentTime;
            if (patternMethod) {
                var notes = [];
                var i,l;
                try {
                    notes = patternMethod(ac, outlet, state, {});
                } catch(e) {
                    patternMethod = oldPatternMethod;
                    notes = patternMethod(ac, outlet, state, {});
                }
                for(i=0,l=notes.length;i<l;i++) {
                    if (notes[i])
                        try {
                            notes[i](i*timePerStep + nextPattern, timePerStep);
                        } catch(e) {
                            console.log(e);
                        }

                }
            }
            nextPattern += timePerPattern;
        }
        setTimeout(audioRunLoop, (timePerPattern * 1000) - 1000);
    }
    audioRunLoop();


});
