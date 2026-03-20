(function () {
	var cookies = document.cookie.split(';');
	var cleaned = false;
	for (var i = 0; i < cookies.length; i++) {
		var parts = cookies[i].split('=');
		var name = parts[0].trim();
		var value = parts.slice(1).join('=');
		if (value.length > 3000) {
			var domains = ['play.yugiohduel.net', '.play.yugiohduel.net'];
			var paths = ['/'];
			for (var d = 0; d < domains.length; d++) {
				for (var p = 0; p < paths.length; p++) {
					document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=' + paths[p] + ';domain=' + domains[d];
				}
			}
			cleaned = true;
		}
	}
	if (cleaned) {
		alert("You had a cookie which was too big to handle and had to be deleted. If you had cookie settings, they may have been deleted.");
	}
})();
