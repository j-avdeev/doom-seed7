(function () {
  "use strict";

  function createDoomAudioManager(options) {
    const button = options && options.button ? options.button : null;
    const statusElement = options && options.statusElement ? options.statusElement : null;
    const AudioContextCtor = window.AudioContext || window.webkitAudioContext;
    const supported = typeof AudioContextCtor === "function";
    const minIntervals = {
      pistol: 0.045,
      hit: 0.06,
      death: 0.1,
      hurt: 0.12,
      use: 0.08,
      complete: 0.3,
      gameOver: 0.4
    };
    const lastPlayed = new Map();

    let context = null;
    let masterGain = null;
    let muted = false;
    let unavailableReason = supported ? "" : "WebAudio unavailable";

    function setStatus(message) {
      if (statusElement) statusElement.textContent = message;
    }

    function audioLabel() {
      if (!supported || unavailableReason !== "") return "Audio N/A";
      if (muted) return "Muted";
      if (context && context.state === "running") return "Audio On";
      return "Audio";
    }

    function audioStatusText() {
      if (!supported || unavailableReason !== "") {
        return "Audio: unavailable" + (unavailableReason ? " (" + unavailableReason + ")" : "");
      }
      if (muted) return "Audio: muted";
      if (context && context.state === "running") return "Audio: ready";
      return "Audio: waiting for user interaction";
    }

    function refreshUi() {
      if (button) {
        button.textContent = audioLabel();
        button.disabled = !supported || unavailableReason !== "";
        button.setAttribute("aria-pressed", muted ? "true" : "false");
        button.title = audioStatusText();
      }
      setStatus(audioStatusText());
    }

    function ensureContext() {
      if (!supported || unavailableReason !== "") return null;
      if (context !== null) return context;

      try {
        context = new AudioContextCtor();
        masterGain = context.createGain();
        masterGain.gain.value = muted ? 0 : 0.24;
        masterGain.connect(context.destination);
        if (typeof context.onstatechange !== "undefined") {
          context.onstatechange = refreshUi;
        }
      } catch (error) {
        unavailableReason = error.message || "AudioContext failed";
        context = null;
        masterGain = null;
      }
      refreshUi();
      return context;
    }

    function setMasterVolume() {
      if (!masterGain || !context) return;
      masterGain.gain.cancelScheduledValues(context.currentTime);
      masterGain.gain.setTargetAtTime(muted ? 0 : 0.24, context.currentTime, 0.015);
    }

    function unlockFromUserGesture() {
      const ctx = ensureContext();
      if (!ctx || muted) {
        refreshUi();
        return Promise.resolve(false);
      }
      if (ctx.state === "running") {
        refreshUi();
        return Promise.resolve(true);
      }
      return ctx.resume().then(function () {
        refreshUi();
        return ctx.state === "running";
      }).catch(function () {
        refreshUi();
        return false;
      });
    }

    function makeNoiseBuffer(durationSeconds) {
      const ctx = ensureContext();
      const length = Math.max(1, Math.floor(ctx.sampleRate * durationSeconds));
      const buffer = ctx.createBuffer(1, length, ctx.sampleRate);
      const data = buffer.getChannelData(0);

      for (let index = 0; index < length; index += 1) {
        const fade = 1 - index / length;
        data[index] = (Math.random() * 2 - 1) * fade;
      }
      return buffer;
    }

    function envelope(gain, time, duration, volume) {
      gain.gain.setValueAtTime(0.0001, time);
      gain.gain.linearRampToValueAtTime(volume, time + 0.006);
      gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
    }

    function tone(time, duration, type, startFrequency, endFrequency, volume) {
      const oscillator = context.createOscillator();
      const gain = context.createGain();

      oscillator.type = type;
      oscillator.frequency.setValueAtTime(startFrequency, time);
      if (endFrequency && endFrequency !== startFrequency) {
        oscillator.frequency.exponentialRampToValueAtTime(Math.max(1, endFrequency), time + duration);
      }
      envelope(gain, time, duration, volume);
      oscillator.connect(gain);
      gain.connect(masterGain);
      oscillator.start(time);
      oscillator.stop(time + duration + 0.025);
    }

    function noise(time, duration, volume, filterType, filterFrequency) {
      const source = context.createBufferSource();
      const gain = context.createGain();
      const filter = context.createBiquadFilter();

      source.buffer = makeNoiseBuffer(duration);
      filter.type = filterType || "bandpass";
      filter.frequency.setValueAtTime(filterFrequency || 900, time);
      filter.Q.value = 0.7;
      envelope(gain, time, duration, volume);
      source.connect(filter);
      filter.connect(gain);
      gain.connect(masterGain);
      source.start(time);
      source.stop(time + duration + 0.02);
    }

    function playNow(name) {
      const now = context.currentTime;

      if (name === "pistol") {
        noise(now, 0.065, 0.18, "bandpass", 950);
        tone(now, 0.09, "square", 170, 92, 0.075);
      } else if (name === "hit") {
        tone(now, 0.085, "triangle", 470, 210, 0.11);
      } else if (name === "death") {
        noise(now, 0.14, 0.08, "lowpass", 650);
        tone(now, 0.24, "sawtooth", 180, 58, 0.10);
      } else if (name === "hurt") {
        tone(now, 0.14, "triangle", 185, 96, 0.13);
        noise(now, 0.05, 0.055, "lowpass", 500);
      } else if (name === "use") {
        tone(now, 0.055, "sine", 260, 330, 0.08);
        tone(now + 0.052, 0.06, "sine", 330, 250, 0.055);
      } else if (name === "complete") {
        tone(now, 0.08, "sine", 523, 523, 0.085);
        tone(now + 0.09, 0.08, "sine", 659, 659, 0.085);
        tone(now + 0.18, 0.13, "sine", 784, 784, 0.095);
      } else if (name === "gameOver") {
        tone(now, 0.13, "triangle", 220, 220, 0.10);
        tone(now + 0.13, 0.14, "triangle", 165, 165, 0.095);
        tone(now + 0.28, 0.23, "triangle", 110, 70, 0.10);
      }
    }

    function play(name) {
      const ctx = ensureContext();
      const now = ctx ? ctx.currentTime : 0;
      const minInterval = minIntervals[name] || 0.05;
      const lastTime = lastPlayed.get(name) || -1000;

      if (!ctx || muted) return;
      if (now - lastTime < minInterval) return;
      lastPlayed.set(name, now);

      if (ctx.state !== "running") {
        unlockFromUserGesture().then(function (ready) {
          if (ready && !muted) playNow(name);
        });
        return;
      }
      try {
        playNow(name);
      } catch (error) {
        unavailableReason = error.message || "sound playback failed";
        refreshUi();
      }
    }

    function toggleMuted() {
      muted = !muted;
      ensureContext();
      setMasterVolume();
      if (!muted) unlockFromUserGesture();
      refreshUi();
    }

    refreshUi();

    return {
      play: play,
      toggleMuted: toggleMuted,
      unlockFromUserGesture: unlockFromUserGesture,
      refreshUi: refreshUi,
      isMuted: function () {
        return muted;
      },
      isAvailable: function () {
        return supported && unavailableReason === "";
      }
    };
  }

  window.createDoomAudioManager = createDoomAudioManager;
}());
