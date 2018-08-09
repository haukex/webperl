"use strict";

/** ***** WebPerl - http://webperl.zero-g.net *****
 * 
 * Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
 * at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
 * Berlin, Germany, http://www.igb-berlin.de
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as Perl 5 itself: either the GNU General Public
 * License as published by the Free Software Foundation (either version 1,
 * or, at your option, any later version), or the "Artistic License" which
 * comes with Perl 5.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the licenses for details.
 * 
 * You should have received a copy of the licenses along with this program.
 * If not, see http://perldoc.perl.org/index-licence.html
**/

function make_emscr_ide (textarea, callbacks) {
	
	var defaulttext = "use warnings;\nuse 5.028;\nuse WebPerl qw/js/;\n\n";
	var div = $('<div/>').addClass("emide");
	var ide = { elem: div, cleanval: '' };
	
	var tb = $('<div/>').addClass("toolbar").appendTo(div);
	var file_new = $('<button/>',{title:"New File",html:"&#x1F4C4;"}).appendTo(tb);
	var file_upload = $('<button/>',{title:"File from Disk",html:"&#x2B06;"}).appendTo(tb);
	var file_download = $('<button/>',{title:"Download editor contents",html:"&#x2B07;"}).appendTo(tb);
	var file_open = $('<button/>',{title:"Open File",html:"&#x1F4C1;"}).appendTo(tb);
	var file_save = $('<button/>',{title:"Save File",html:"&#x1F4BE;"}).appendTo(tb);
	var file_name = $('<input/>',{title:"File Name",type:"text",size:60}).addClass("code").appendTo(tb);
	//TODO Later: support for deleting files?
	
	var upload_file = $('<input/>',{type:"file"});
	var file_up_form = $('<div/>').append(
			$('<form/>').append( upload_file )  ).appendTo(div);
	file_up_form.hide();
	
	var fbrowser = make_emscr_ide_filebrowser();
	fbrowser.elem.hide();
	fbrowser.elem.appendTo(div);
	
	var resize_frame = $('<div/>').addClass("cm-resize-frame").appendTo(div);
	textarea.replaceWith(div);
	resize_frame.append(textarea);
	
	var statusbar = $('<div/>').addClass("statusbar").appendTo(div);
	
	var cm = CodeMirror.fromTextArea( textarea[0], {
			lineNumbers: true, indentWithTabs: true,
			tabSize: 4, indentUnit: 4  });
	ide.cm = cm;
	/* With thanks to https://codepen.io/sakifargo/pen/KodNyR */
	var fr = resize_frame[0];
	var cm_resize = function() { cm.setSize(fr.clientWidth + 2, fr.clientHeight - 10); };
	cm_resize();
	if (window.ResizeObserver)
		new ResizeObserver(cm_resize).observe(fr);
	else if (window.MutationObserver)
		new MutationObserver(cm_resize).observe(fr, {attributes: true});
	
	ide.isDirty = function () { return cm.getValue()!=ide.cleanval; };
	// returns true if the user chose to abort
	// returns false if the buffer is not dirty or the user chose to continue anyway
	ide.dirtyCheck = function () {
		if (ide.isDirty()) {
			// confirm() returns true if the user clicked "OK", and false otherwise.
			if (confirm("Unsaved changes in editor!\nContinue anyway?"))
				return false;
			else return true; // buffer is dirty and user chose to abort
		}
		else return false;
	};
	
	file_new.click(function () {
		if (ide.dirtyCheck()) return;
		console.debug("IDE: New File");
		file_name.val("");
		ide.cleanval = defaulttext;
		cm.setValue(defaulttext);
		sessionStorage.removeItem('file_mru');
		statusbar.text("New File");
	});
	
	file_upload.click(function () {
		if(!window.FileReader) {
			alert("Sorry, your browser does not support file uploads.");
			return; }
		if (file_up_form.is(":visible")) file_up_form.hide(); else file_up_form.show();
	});
	upload_file.on('change', function (chgEvt) {
		statusbar.text("");
		file_up_form.hide();
		if (ide.dirtyCheck()) return;
		file_name.val("");
		sessionStorage.removeItem('file_mru');
		console.debug("IDE: Reading file from local disk...");
		var reader = new FileReader();
		reader.onload = function(loadEvt) {
			if(loadEvt.target.readyState != 2) return;
			if(loadEvt.target.error) {
				alert('Error while reading file');
				return; }
			console.debug("IDE: File read!");
			statusbar.text("File opened from local disk");
			cm.setValue(loadEvt.target.result);
		};
		reader.readAsText(chgEvt.target.files[0]);
	});
	
	file_download.click(function () {
		var blob = new Blob([cm.getValue()],
			{type: "text/plain;charset=utf-8"});
		var link = document.createElement("a");
		link.download = 'script.pl';
		link.href = URL.createObjectURL(blob);
		link.target = '_blank';
		document.body.appendChild(link);
		link.click();
		document.body.removeChild(link);
	});
	
	file_open.click(function () {
		statusbar.text("");
		if (!fbrowser) return;
		if (fbrowser.isVisible()) {
			file_open.html("&#x1F4C1;");
			fbrowser.cancel();
		}
		else {
			file_open.html("&#x1F4C2;&#x20E0;");
			fbrowser.show(function (file) {
				file_open.html("&#x1F4C1;");
				if (ide.dirtyCheck()) return;
				console.debug("IDE: Opening "+file);
				file_name.val(file);
				var data = FS.readFile(file,{encoding:"utf8"});
				ide.cleanval = data;
				cm.setValue(data);
				sessionStorage.setItem('file_mru',file);
				statusbar.text("Opened "+file);
				console.debug("IDE: Opened "+file);
				if (callbacks && callbacks.open) callbacks.open(file);
			});
		}
	});
	
	file_save.click(function () {
		statusbar.text("");
		var file = file_name.val();
		if (file.length<1) {
			alert("Invalid File Name");
			return; }
		try {
			console.debug("IDE: Trying to save "+file);
			var data = cm.getValue();
			FS.writeFile( file, data );
			/* Note: The user may be saving to some location outside of the IDBFS, in which
			 * case this syncfs call isn't really needed. But it doesn't really hurt either,
			 * so we always do it. */
			FS.syncfs(false, function (err) {
				if(err) { console.error(err); alert("Saving IDBFS failed: "+err); return; }
				statusbar.text("Saved to "+file);
				console.debug("IDE: Saved "+file);
				sessionStorage.setItem('file_mru',file);
				ide.cleanval = data;
				if (callbacks && callbacks.save) callbacks.save(file);
			});
		}
		catch (err) { console.error(err); alert("Save Failed: "+err); }
	});
	
	var mru_file = sessionStorage.getItem('file_mru');
	try {
		if (!mru_file) throw "No MRU file";
		var data = FS.readFile( mru_file, {encoding:"utf8"} );
		ide.cleanval = data;
		cm.setValue(data);
		file_name.val(mru_file);
		console.debug("IDE: Loaded "+mru_file);
		statusbar.text("Opened "+mru_file);
		if (callbacks && callbacks.open) callbacks.open(mru_file);
	}
	catch (e) {
		console.debug("IDE: Loading MRU failed:",e,"- falling back...");
		file_name.val('');
		ide.cleanval = defaulttext;
		cm.setValue(defaulttext);
	}
	
	window.addEventListener("beforeunload", function (evt) {
		if (ide.isDirty()) {
			var dialogText = "Unsaved changes in editor!";
			evt.returnValue = dialogText;
			return dialogText;
		}
	});
	
	return ide;
}

function make_emscr_ide_filebrowser() {
	var fb = {
		elem: $('<div/>').addClass("filebrowser"),
		curpath: (ENV && ENV.HOME) ? ENV.HOME : FS.cwd(),
	};
	fb.update = function () {
		fb.elem.empty();
		$('<div>&#x1F4C2; </div>').addClass("fb-curdir")
			.append(fb.curpath).appendTo(fb.elem);
		var files = FS.readdir(fb.curpath);
		$.each( files.sort(), function (idx,file) {
			if (file=='.') return;
			if (file=='..' && fb.curpath=='/') return;
			var fullfile = FS.joinPath([fb.curpath,file]);
			var stat = FS.stat(fullfile);
			var icon = "&#x1F4DC;";
			var click;
			if (FS.isFile(stat.mode)) {
				icon = "&#x1F4C4;";
				click = function (evt) {
					fb.elem.hide();
					if(fb.callback) fb.callback(fullfile);
					fb.callback = null;
				};
			}
			else if (FS.isDir(stat.mode)) {
				icon = file=='..'?"&#x1F4C1;&#x20D6;":"&#x1F4C1;";
				click = function (evt) {
					fb.curpath = fullfile;
					fb.update();
				};
			}
			else if (FS.isLink(stat.mode)) {
				icon = "&#x1F4C4;&#x20EA;";
			}
			var el = $('<div>'+icon+' </div>').addClass("fb-link")
				.append(file).appendTo(fb.elem);
			if (click) el.click(click);
		});
	};
	fb.show = function (callback) {
		fb.callback = callback;
		fb.elem.show();
		fb.curpath = FS.cwd();
		fb.update();
	};
	fb.cancel = function () {
		fb.elem.hide();
		fb.callback = null;
	}
	fb.isVisible = function () { return fb.elem.is(":visible") }
	return fb;
}
