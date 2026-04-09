importScripts('/assets/env.js');
importScripts('https://www.gstatic.com/firebasejs/10.5.2/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/10.5.2/firebase-messaging.js');

const runtimeEnv = self.__env || {};
const firebaseConfig = {
  apiKey: runtimeEnv.firebase?.apiKey || '',
  authDomain: runtimeEnv.firebase?.authDomain || '',
  databaseURL: runtimeEnv.firebase?.databaseURL || '',
  projectId: runtimeEnv.firebase?.projectId || '',
  storageBucket: runtimeEnv.firebase?.storageBucket || '',
  messagingSenderId: runtimeEnv.firebase?.messagingSenderId || '',
  appId: runtimeEnv.firebase?.appId || '',
  measurementId: runtimeEnv.firebase?.measurementId || ''
};

if (!firebaseConfig.apiKey) {
  console.warn('[Firebase SW] Firebase config missing in env.js; background messaging disabled.');
} else {
  firebase.initializeApp(firebaseConfig);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
      console.log("📩 Received background message:", payload);
      self.registration.showNotification(payload.notification.title, {
          body: payload.notification.body,
          icon: "/assets/icons/icon-192x192.png"
      });
  });
}
