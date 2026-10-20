'use strict';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      try {
        if ('caches' in self) {
          const keys = await caches.keys();
          await Promise.all(keys.map(k => caches.delete(k)));
        }
      } catch (e) {}

      try {
        await self.registration.unregister();
      } catch (e) {}

      try {
        const clients = await self.clients.matchAll({ type: 'window' });
        clients.forEach((client) => {
          if (client.url && 'navigate' in client) {
            client.navigate(client.url);
          }
        });
      } catch (e) {}
    })()
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request));
});
