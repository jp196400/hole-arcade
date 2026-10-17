// Replaces a previously installed Godot service worker.
// It does not cache. On activate it loads a fresh page and unregisters itself.
self.addEventListener('install', function (event) {
	event.waitUntil(caches.keys().then(function (keys) {
		return Promise.all(keys.map(function (key) {
			return caches.delete(key);
		}));
	}).then(function () {
		return self.skipWaiting();
	}));
});

self.addEventListener('activate', function (event) {
	event.waitUntil(self.clients.claim().then(function () {
		return self.clients.matchAll({ type: 'window' });
	}).then(function (clients) {
		return Promise.all(clients.map(function (client) {
			if (!client.navigate) {
				return null;
			}
			var next = new URL(client.url);
			next.searchParams.set('fresh', String(Date.now()));
			return client.navigate(next.href);
		}));
	}).then(function () {
		return self.registration.unregister();
	}));
});

self.addEventListener('fetch', function (event) {
	event.respondWith(fetch(event.request, { cache: 'reload' }));
});
