'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "d2fa952fe57dded89cfca997cb76cb5b",
".git/config": "d69cac459417e46b1112d42008c30aad",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "de6a67249024f8edda70d8b3aed7c4b9",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "f85cd85d509085df8f85cab6bc60f4ba",
".git/logs/refs/heads/gh-pages": "f85cd85d509085df8f85cab6bc60f4ba",
".git/logs/refs/remotes/origin/gh-pages": "22754059aebd35c9ce213c5cb25252df",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/0a/7a85b85b6d767b6dcf0f5624a90002bf6a1df3": "e12954cc11e0842639d953c1321e5ea8",
".git/objects/0e/ee57bec230a439cf1163dc46e964ffafc53395": "3de69faabd3291b760e36927a2599402",
".git/objects/10/b443c5bde86193c4dcc99fd703f982d8e9f96f": "32e9466e3d3e44f735f406cc17e02e81",
".git/objects/18/df2e22394f0336def7790832867bfae8fc9333": "7129eaa8f18b131b3bcee7c8f2d7da04",
".git/objects/1c/06f5376b30eafba383ba05f063be10ebecbbc5": "fe1876385bce23962e4b915459f71257",
".git/objects/1d/e73ac949ca24991aa59801b682ca289d8f127e": "9429beb1cff7a6a3e017ddb40f42558d",
".git/objects/28/cfdef7efeb483e236e2124938730d89af70f51": "2e621121fde8d04b4f4059e8dffee921",
".git/objects/2d/558bb230999418003e5ded89101b269d22cfdd": "9d17aafba8f206e9269e0afce2452805",
".git/objects/2f/0ba2c849077dc90762b8c47c958d60bfb3f05e": "7bd07a762d96d7ef778a661e993f5771",
".git/objects/34/9a034e8103f803bc81671accbcf6fe11ea13e5": "f23c75d8e959be0a21aeeec699ce9f5f",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3d/1a0def595e74344ab599dcb6bdc0f069a5ecc1": "5395f3f84c54ea95f6066e1fbed57634",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/47/437c32cc867bf4369af12de61be3ab4989656b": "025540135fce5c04d6ad1414309fda72",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/53/ca0726c7bf3e044ac4b378a4d5a201f9f939ee": "571cd8b236a0099dee811b4ad95dbeea",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/69/dd618354fa4dade8a26e0fd18f5e87dd079236": "8cc17911af57a5f6dc0b9ee255bb1a93",
".git/objects/6a/9aac3b0e0078591671dc17f6ba06ccaf9ca9f5": "7bc2126e028ac8a5fd72c07961221b71",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/76/dcc8c7fc174ab0e8847007f9966d598b9de88b": "944e50b079b6cc6c9117ed4cd51e1c83",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/80/329d8989521f686841d3f0686ff0134c39e353": "31d6a16be574cb8aef14c858beb534ad",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
".git/objects/8f/e7af5a3e840b75b70e59c3ffda1b58e84a5a1c": "e3695ae5742d7e56a9c696f82745288d",
".git/objects/91/2c24eeb3abf2543876a01fd70610b53a1bcb34": "e77b3c9a3c83f149394e11371bdbb643",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/a1/5b3dffc6f79cf8ba87e3240b83608625839b87": "6c694dd986c1d48a8f3de76290518821",
".git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
".git/objects/ab/2671ed569f0515245c0a318751e7ee21390386": "6530a6adf5015520c3215b6d95f79e1c",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/c1/a994c0d04d52561feb80e9222c32a6d014364e": "651ea95a2629e696b6c1bbd6ed82ae47",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/ca/3ed05fad5e88a2bb08d898f90a50decb1aacc6": "5347209c90b8a81824549bfae22f5252",
".git/objects/cc/c5af595bea9c4484559a06b12f12dde84d2d63": "76c913a51849ca5b6000a3de595dbc3b",
".git/objects/cd/c7bc51577a631bda92b4508106b70388bd0bf7": "272ddc18873f0ed0c3537222a7eb3c0a",
".git/objects/d3/ead23fe016b215e879c0d93dbb67504a470a01": "41b64470d457100933ee6164acda56dd",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d8/c3ef1b9384d6c5a0b9ebb97abb3812d5989e52": "d63952abd54f662d0d0047f82929ef82",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/e6/6b9036c73df710f1b6c6079d7994a9e00ff78d": "bd2b9ebb7d6950b40f2384d063142796",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/ee/4e78a13bf8a3c40499ef19860bf52e0c393034": "23ca810be96b743f6774561e6cf00e2c",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/f7/507554835e09ba850618ee06a99ef6c139cd2b": "89531bf4779c98fa52fb73e3090d8748",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/fd/709f5109adeff63de928799687ed920eaf9067": "4217f01d226632a9c1cb63ca063e6a27",
".git/objects/fe/46470ae21c74da8c491b48cad3b46dc0d6f155": "9acfc5d9a41622c0cd10942767748771",
".git/refs/heads/gh-pages": "1b5f0f432f0b39ad4b19d671f8b36f4f",
".git/refs/remotes/origin/gh-pages": "1b5f0f432f0b39ad4b19d671f8b36f4f",
"apple-touch-icon.png": "8a60b6f3ac7caa7b6dbb9705fb3533e7",
"assets/AssetManifest.bin": "693635b5258fe5f1cda720cf224f158c",
"assets/AssetManifest.bin.json": "69a99f98c8b1fb8111c5fb961769fcd8",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "f1d9fd9864af9238349ba5503956d3bc",
"assets/NOTICES": "436adaff67d9f65b9bce409c228cff48",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon-16x16.png": "c7ce99e069fbc7d118a56ae67d2b8999",
"favicon.ico": "c7d5ffae24d5602d413565d5dea9a525",
"favicon.png": "d3bba6351288b991829ee473ed1cc049",
"favicon.svg": "a9fe5fa2273a05bffcef30e6e0a5d525",
"favicon512.png": "be5a923e7e1ff0837a9c1ae2ef488742",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "6febdc26572534ab046173f22760ee1d",
"Icon-192.png": "59092ecf5b1796cf57191fc4a13d5d41",
"Icon-512.png": "be5a923e7e1ff0837a9c1ae2ef488742",
"Icon-maskable-192.png": "59092ecf5b1796cf57191fc4a13d5d41",
"Icon-maskable-512.png": "09bd1b05a4fbadccb3c0c09001c2deff",
"icons/Icon-192.png": "59092ecf5b1796cf57191fc4a13d5d41",
"icons/Icon-512.png": "be5a923e7e1ff0837a9c1ae2ef488742",
"icons/Icon-maskable-192.png": "59092ecf5b1796cf57191fc4a13d5d41",
"icons/Icon-maskable-512.png": "09bd1b05a4fbadccb3c0c09001c2deff",
"index.html": "f010f33acb874c3e0230aa0770b19696",
"/": "f010f33acb874c3e0230aa0770b19696",
"main.dart.js": "f7310a35053245186193321e39db158f",
"manifest.json": "e8108796c786e31b4db551dec9ee3383",
"version.json": "541e47e60739d5a3677b774b8b68fe89"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
