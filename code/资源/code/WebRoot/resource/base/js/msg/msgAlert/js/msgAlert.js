(function ($) {
    $.msgAlert = function (config) {
        var defaults, options, msgAlert, popup, header, close, content, footer, overlay;
        defaults = {
            type: '',
            title: '',
            text: '',
            callback: function () {},
            closeTrigger: true,
            escClose: true,
            overlay: true,
            overlayClose: false,
            buttons: [{
                text: '确定',
                callback: function () {
                    $.msgAlert.close();
                    options.callback()
                }
            }]
        };
        options = $.extend(defaults, config);
        msgAlert = $('<div>', {
            'class': 'msgAlert ' + options.type
        }).appendTo('body');
        popup = $('<div>', {
            'class': 'msgAlert_popup'
        }).appendTo(msgAlert);
        if (options.title != '') {
            header = $('<div/>', {
                'class': 'msgAlert_header',
                'html': '<h4>' + options.title + '</h4>'
            }).appendTo(popup)
        }
        if (options.closeTrigger) {
            close = $('<a>', {
                'href': 'javascript:;',
                'class': 'msgAlert_close',
                'click': close
            }).appendTo(header)
        }
        content = $('<div/>', {
            'class': 'msgAlert_content',
            'html': options.text
        }).appendTo(popup);
        footer = $('<div/>', {
            'class': 'msgAlert_footer'
        }).appendTo(msgAlert);
        if (options.overlay) {
            overlay = $('<div/>', {
                'class': 'msgAlert_overlay'
            }).appendTo('body');
            if (options.overlay && options.overlayClose) {
                overlay.bind('click', close)
            }
        }
        if (options.type == 'warning') {
            options.buttons = [{
                text: '确定',
                callback: function () {
                    options.callback(true);
                    $.msgAlert.close()
                }
            },  {
                text: '取消',
                callback: function () {
                	options.callback(false);
                    $.msgAlert.close()
                }
            }]
        }
        if (options.buttons.length > 0) {
            for (key in options.buttons) {
                $('<button>', {
                    'text': options.buttons[key].text
                }).bind('click', options.buttons[key].callback).appendTo(footer)
            }
        }
        msgAlert.appendTo('body');
        msgAlert.find('button:first').focus();
        if (options.escClose) {
            $(document).bind('keyup.msgAlert', function (e) {
                if (e.keyCode == 27) {
                    $.msgAlert.close()
                }
            })
        }
        function close(e) {
            e.preventDefault();
            $.msgAlert.close()
        }
    };
    $.msgAlert.close = function () {
        $('.msgAlert').fadeOut('fast', function () {
            $(this).remove()
        });
        $('.msgAlert_overlay').fadeOut('fast', function () {
            $(this).remove()
        });
        $(document).unbind('keyup.msgAlert')
    }
})(jQuery);
(function(){
var jss = $("script");
for(var i = 0;i<jss.length;i++){
	if(jss[i].src.indexOf("msgAlert.js") > -1){
		var basePath = jss[i].src.match(/http:\/*\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5}\/*\w*\/*/i);
		document.write("<link rel='stylesheet' type='text/css' href='"+basePath+"/resource/base/js/msg/msgAlert/css/msgAlert.css'/>");
	}
}
})();

