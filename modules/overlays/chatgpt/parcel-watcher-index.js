const {createWrapper} = require('./wrapper');

// NIXPKGS PATCH: upstream chose between the -glibc and -musl prebuilds with
// detect-libc, which reads the first 2048 bytes of /proc/self/exe to find
// PT_INTERP. patchelf moves that string past the end of this 300MB binary, so
// the lookup fails, /usr/bin/ldd does not exist on NixOS, and the last resort
// process.report.getReport() aborts this Electron build with SIGILL. Only the
// -glibc prebuild ships here. Keep this file's byte length <= upstream's: it
// is patched into app.asar in place.
let name = `@parcel/watcher-${process.platform}-${process.arch}`;
if (process.platform === 'linux') {
  name += '-glibc';
}

let binding;
try {
  binding = require(name);
} catch (err) {
  handleError(err);
  try {
    binding = require('./build/Release/watcher.node');
  } catch (err) {
    handleError(err);
    throw new Error(`No prebuild of @parcel/watcher found. Tried ${name}.`);
  }
}

function handleError(err) {
  if (err?.code !== 'MODULE_NOT_FOUND') {
    throw err;
  }
}

const wrapper = createWrapper(binding);
exports.writeSnapshot = wrapper.writeSnapshot;
exports.getEventsSince = wrapper.getEventsSince;
exports.subscribe = wrapper.subscribe;
exports.unsubscribe = wrapper.unsubscribe;
